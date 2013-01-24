require! <[fs pg]>

export function connect(db)
  with new pg.Client db
    ..connect!

export function bootstrap(conn, done)
  with conn
    (err, res) <- ..query "select version()"
    #->[0][0] =~ m/
    [_, pg_version] = res.rows.0.version.match /^PostgreSQL ([\d\.]+)/
    console.log pg_version
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
    ..query _mk_func \jseval {str: \text} \text """
function(str) {
    return eval(str)
}
"""
    ..query "select jseval($1)" ['plv8x_jsid = 0']
    ..query _mk_func \jsevalit {str: \text} \text """
function (str) {
    ++plv8x_jsid;
    var id = "plv8x_jsid" + plv8x_jsid;
    var body = id + " = (function() {return (" + str + ");})()";
    var ret = eval(body);
    return id;
}
"""
    ..query fs.readFileSync 'plv8x.sql' \utf8
    r = ..query _mk_func \jsapply {str: \text, args: \plv8x_json} \plv8x_json """
function (func, args) {
    return eval(func).apply(null, args);
}
"""
#    r = ..query 'INSERT INTO "plv8x".code ("name", "code", "load_seq") VALUES($1, $2, $3)' [\LiveScript, src, 0]
#    r.on \row -> console.log ...
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
      'SELECT jsapply($1, $2) AS compiled'
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

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PLV8X_#name\$
return #body;
\$PLV8X_#name\$ LANGUAGE #lang IMMUTABLE STRICT;

EXCEPTION WHEN OTHERS THEN END; \$PLV8X_EOF\$;

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

export function import-bundle(conn, name, manifest, cb)
  code <- bundle manifest
  err, res <- conn.query "select name from plv8x.code where name = $1", [name]
  console.log res.rows
  [q, bind] = if res.rows.length # udpate
    ["update plv8x.code set name = $1, code = $2" [name, code]]
  else
    ["insert into plv8x.code (name, code) values($1, $2)" [name, code]]
  err, res <- conn.query q, bind
  throw err if err
  cb res.rows

