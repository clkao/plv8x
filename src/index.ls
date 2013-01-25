export function connect(db)
  require! pg
  with new pg.Client db
    ..connect!

export function bootstrap(conn, done)
  with conn
    (err, res) <- ..query "select version()"
    #->[0][0] =~ m/
    [_, pg_version] = res.rows.0.version.match /^PostgreSQL ([\d\.]+)/
    if pg_version >= \9.1.0
      ..query '''
DO $$ BEGIN
    CREATE EXTENSION IF NOT EXISTS plv8;
EXCEPTION WHEN OTHERS THEN END; $$;
DO $$ BEGIN
    CREATE EXTENSION IF NOT EXISTS plls;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      # load with sql

    if pg_version < \9.2.0
      ..query '''
DO $$ BEGIN
    CREATE FUNCTION json_syntax_check(src text) RETURNS boolean AS '
        try { JSON.parse(src); return true; } catch (e) { return false; }
    ' LANGUAGE plv8 IMMUTABLE;
EXCEPTION WHEN OTHERS THEN END; $$;

DO $$ BEGIN
    CREATE DOMAIN plv8x_json AS text CHECK ( json_syntax_check(VALUE) );
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x_json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x_json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query _mk_func \plv8x_eval {str: \text} \text """
function(str) {
    return eval(str)
}
"""
    ..query "select plv8x_eval($1)" ['plv8x_jsid = 0']
    ..query _mk_func \plv8x_evalit {str: \text} \text """
function (str) {
    ++plv8x_jsid;
    var id = "plv8x_jsid" + plv8x_jsid;
    var body = id + " = (function() {return (" + str + ");})()";
    var ret = eval(body);
    return id;
}
"""
    ..query _mk_func \plv8x_boot {} \void plv8x-boot plv8x-require
    ..query _mk_func \lscompile {str: \text, args: \plv8x_json} \text plv8x-lift "LiveScript", "compile"
    ..query require(\fs)readFileSync 'plv8x.sql' \utf8
    ..query "select plv8x_boot()"
    r = ..query _mk_func \plv8x_apply {str: \text, args: \plv8x_json} \plv8x_json """
function (func, args) {
    return eval(func).apply(null, args);
}
"""
    r.on \end done

export function _mk_func (
  name, param-obj, ret, body, lang = \plv8, skip-compile
)
  params = []
  args = for pname, type of param-obj
    params.push "#pname #type"
    if type is \plv8x_json
      "JSON.parse(#pname)"
    else pname

  if lang is \plls and not skip-compile
    lang = \plv8
    [{ compiled }] = plv8.execute do
      'SELECT plv8x_apply($1, $2) AS compiled'
      'LiveScript.compile'
      JSON.stringify [body, { +bare }]
    compiled -= /;$/

  compiled ||= body
  body = "(eval(#compiled))(#args)";
  body = "JSON.stringify(#body)" if ret is \plv8x_json

  return """

SET client_min_messages TO WARNING;
DO \$PLV8X_EOF\$ BEGIN

DROP FUNCTION IF EXISTS #{name} (#params);
DROP FUNCTION IF EXISTS #{name} (#{
  for p in params
    if p is /plv8x_json/ then \json else p
});
EXCEPTION WHEN OTHERS THEN END; \$PLV8X_EOF\$;

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PLV8X_#name\$
return #body;
\$PLV8X_#name\$ LANGUAGE #lang IMMUTABLE STRICT;
  """


export function list(conn, cb)
  (err, res) <- conn.query "select * from plv8x.code"
  cb res.rows

export function purge(conn, cb)
  (err, res) <- conn.query "delete from plv8x.code"
  cb res.rows

export function bundle(manifest, cb)
  require! one
  one.quiet true
  err, bundle <- one.build manifest, {-debug}
  throw err if err

  # XXX
  delete global.key
  cb bundle

export function delete-bundle(conn, name, cb)
  err, res <- conn.query "delete from plv8x.code where name = $1" [name]
  throw err if err
  cb res.rows

export function import-bundle(conn, name, manifest, cb)
  code <- bundle manifest
  err, res <- conn.query "select name from plv8x.code where name = $1" [name]
  [q, bind] = if res.rows.length # udpate
    ["update plv8x.code set name = $1, code = $2" [name, code]]
  else
    ["insert into plv8x.code (name, code) values($1, $2)" [name, code]]
  err, res <- conn.query q, bind
  throw err if err
  cb res.rows

export function mk-user-func(conn, spec, source, cb)
  #conn.query
  [_, rettype, name, args] = spec.match /^(\w+)?\s*(\w+)\((.*)\)$/ or throw "failed to parse #spec"

  param-obj = {}
  for arg, idx in args.split /\s*,\s*/
    console.log arg
    [_, type, param-name] = arg.match /^(\w+)\s*(\w+)?$/ or throw "failed to parse param #arg"
    param-name ?= "__#{idx}"
    param-obj[param-name] = type

  [_, pkg, expression] = source.match /^(\w*):(.*)$/ or throw "failed to parse source #source"

  body = if pkg
    plv8x-lift pkg, expression
  else if expression.match /^function/
    expression
  else
    (require \LiveScript .compile expression, {+bare}) - /;$/

  err, res <- conn.query _mk_func name, param-obj, rettype, body
  throw err if err
  console.log res

  cb { rettype, name, param-obj, body }

export function plv8x-boot(body)
  """
  function() { plv8x_require = #{body.toString!replace /(['\\])/g, '\$1'} }
  """

export function plv8x-lift(module, func-name)
  body = plv8x-require
  """
  function() {
    plv8x_require = #{body.toString!replace /(['\\])/g, '\$1'};
    plv8.elog(WARNING, "apply", arguments);
    return plv8x_require('#{module}').#{func-name}.apply(null, arguments);
  }
  """

plv8x-require = (name) ->
  res = plv8.execute "select name, code from plv8x.code", []
  x = {}
  for {code,name:bundle} in res
    try
      loader = """
(function() {
    var module = {exports: {}};
    #code;
    return module.exports.require;
})()
"""
      req = eval loader
      module = req name
      return module if module?
    catch
  plv8.elog WARNING, "failed to load module #name"

module.exports.plv8x-require = plv8x-require
