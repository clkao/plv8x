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
    CREATE DOMAIN pgrest_json AS text CHECK ( json_syntax_check(VALUE) );
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      ..query '''
DO $$ BEGIN
    CREATE DOMAIN pgrest_json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x_json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    ..query _mk_func \jseval {str: \text} \text """
function(str) { return eval(str) }
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
    if type is \pgrest_json
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
  body = "JSON.stringify((eval(#compiled))(#args));";

  return """

SET client_min_messages TO WARNING;
DO \$PGREST_EOF\$ BEGIN

DROP FUNCTION IF EXISTS #{name} (#params);
DROP FUNCTION IF EXISTS #{name} (#{
  for p in params
    if p is /pgrest_json/ then \json else p
});

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PGREST_#name\$
return #body
\$PGREST_#name\$ LANGUAGE #lang IMMUTABLE STRICT;

EXCEPTION WHEN OTHERS THEN END; \$PGREST_EOF\$;

  """
