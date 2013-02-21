class PLX => (@conn) ->
  <[ list purge importBundle deleteBundle mkUserFunc plv8xEval ]>.for-each !(key) ~>
    @[key] = -> exports[key](@conn, ...arguments)
  @eval = @plv8x-eval

exports.new = (db, cb) ->
  conn = connect db
  <- bootstrap conn
  <- conn.query 'select plv8x.boot()'
  plx = new PLX conn
  cb? plx

export function connect(db)
  require! pg
  new pg.Client db
    ..connect!

export function plv8x-eval(conn, code, cb)
  code = "(#code)()" if typeof code is \function
  err, rv <- conn.query "select plv8x.eval($1)", [code]
  throw err if err
  cb? rv

export function define-schema(name, comment, drop, cascade)
  dodrop = if drop => """
    ELSE EXECUTE 'DROP SCHEMA #name #{if cascade => 'CASCADE' else ''};
         CREATE SCHEMA #name';""" else ""

  """
DO $$
BEGIN

    IF NOT EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = '#name'
      )
    THEN
      EXECUTE 'CREATE SCHEMA #name';
    #dodrop
    END IF;

END

$$;

COMMENT ON SCHEMA #name IS '#comment';
  """

export function plv8x-sql(drop=false, cascade=false)
  define-schema(\plv8x 'Out-of-table for loading plv8 modules', drop, cascade) + """

CREATE TABLE IF NOT EXISTS plv8x.code (
    name text,
    code text,
    load_seq int,
    updated timestamp
);
  """

export function bootstrap(conn, drop, cascade, done)
  if typeof drop is \function
    done = drop
    drop = false
  with conn
    (err, res) <- ..query "select version()"
    ..query plv8x-sql drop, cascade
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
      /* translate this from perl using shelljs
      my $dir = `pg_config --sharedir`;
      chomp $dir;
      use File::Glob qw(bsd_glob);
      my @init_files = sort { $b cmp $a } bsd_glob("$dir/contrib/plv8*.sql");
      if (@init_files > 1) {
          warn "==> more than one version of plv8 found: ".join(',',@init_files);
      }
      eval {
          $self->{dbh}->do(scalar read_file($init_files[0]));
      };
      $self->{dbh}->do('rollback') if $self->{dbh}->err;
      */

    if pg_version < \9.2.0
      ..query '''
DO $$ BEGIN
    CREATE FUNCTION plv8x.json_syntax_check(src text) RETURNS boolean AS '
        try { JSON.parse(src); return true; } catch (e) { return false; }
    ' LANGUAGE plv8 IMMUTABLE;
EXCEPTION WHEN OTHERS THEN END; $$;

DO $$ BEGIN
    CREATE DOMAIN plv8x.json AS text CHECK ( plv8x.json_syntax_check(VALUE) );
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x.json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x.json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query _mk_func \plv8x.eval {str: \text} \text """
function(str) {
    return eval(str)
}
"""
    ..query "select plv8x.eval($1)" ['plv8x_jsid = 0']
    ..query _mk_func \plv8x.evalit {str: \text} \text """
function (str) {
    ++plv8x_jsid;
    var id = "plv8x_jsid" + plv8x_jsid;
    var body = id + " = (function() {return (" + str + ");})()";
    var ret = eval(body);
    return id;
}
"""
    ..query _mk_func \plv8x.boot {} \void plv8x-boot plv8x-require
    ..query _mk_func \plv8x.lscompile {str: \text, args: \plv8x.json} \text plv8x-lift "LiveScript", "compile"
    ..query "select plv8x.boot()"
    r = ..query _mk_func \plv8x.apply {str: \text, args: \plv8x.json} \plv8x.json """
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
    if type is \plv8x.json
      "JSON.parse(#pname)"
    else pname

  if lang is \plls and not skip-compile
    lang = \plv8
    [{ compiled }] = plv8.execute do
      'SELECT plv8x.apply($1, $2) AS compiled'
      'LiveScript.compile'
      JSON.stringify [body, { +bare }]
    compiled -= /;$/

  compiled ||= body
  body = "(eval(#compiled))(#args)";
  body = "JSON.stringify(#body)" if ret is \plv8x.json

  return """

SET client_min_messages TO WARNING;
DO \$PLV8X_EOF\$ BEGIN

DROP FUNCTION IF EXISTS #{name} (#params);
EXCEPTION WHEN OTHERS THEN END; \$PLV8X_EOF\$;

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PLV8X__BODY__\$
return #body;
\$PLV8X__BODY__\$ LANGUAGE #lang IMMUTABLE STRICT;
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
  err, bundle <- one.build manifest, {-debug, exclude: <[one pg]>}
  throw err if err

  # XXX
  delete global.key
  cb bundle

export function delete-bundle(conn, name, cb)
  err, res <- conn.query "delete from plv8x.code where name = $1" [name]
  throw err if err
  cb res.rows

export function import-bundle(conn, name, manifest, cb)
  bundle_from = (m, cb) ->
    if m is /\.js$/
      cb (require \fs .readFileSync m, \utf8)
    else
      bundle m, cb
  code <- bundle_from manifest
  console.log code.length
  err, res <- conn.query "select name from plv8x.code where name = $1" [name]
  [q, bind] = if res.rows.length # udpate
    ["update plv8x.code set name = $1, code = $2" [name, code]]
  else
    ["insert into plv8x.code (name, code) values($1, $2)" [name, code]]
  err, res <- conn.query q, bind
  throw err if err
  cb res.rows

export function mk-user-func(conn, spec, source, cb)
  [_, rettype, name, args] = spec.match /^(\w+)?\s*(\w+)\((.*)\)$/ or throw "failed to parse #spec"

  param-obj = {}
  for arg, idx in args.split /\s*,\s*/
    [_, type, param-name] = arg.match /^([\.\w]+)\s*(\w+)?$/ or throw "failed to parse param #arg"
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
    return plv8x_require('#{module}').#{func-name}.apply(null, arguments);
  }
  """

plv8x-require = (name) ->
  ``if (typeof plv8x_global == 'undefined') plv8x_global = {}``
  return plv8x_global[name] if plv8x_global[name]?

  res = plv8.execute "select name, code from plv8x.code", []
  x = {}
  err = ''
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
      return plv8x_global[name] = module if module?
    catch e
      if e isnt /Cannot find module/
        break
      err := e
  plv8.elog WARNING, "failed to load module #name: #err"

module.exports.plv8x-require = plv8x-require
