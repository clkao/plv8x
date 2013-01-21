require! <[browserify fs resolve pg]>
plv8x = require \../

argv = require 'optimist' .usage 'Usage: plv8x {OPTIONS}' .wrap 80
.option 'db' do
  desc: 'database connection string'
.option 'list' do
  alias: 'l'
  desc: 'List bundles'
.option 'help' do
  alias: 'h'
  desc: 'Show this message'
.check (argv) ->
  throw '' if argv.help
  if process.argv.length <= 2 then throw 'Specify a parameter.'
.argv


bundle = browserify!

bundle.on 'syntaxError' (err) ->
    console.error(err)
    process.exit(1);


# no prelude
#bundle <<< { prepends: [], files: [] }

<[LiveScript]>.forEach (req) ->
    if  !/^[.\/]/.test req
        try
            res = resolve.sync req, { basedir : process.cwd() }
            return bundle.require res, { target : req }
    bundle.require(req);

src = bundle.bundle!
src.= replace /^var require =/g, 'require ='
#console.log src

bootstrap_code = """
1
"""

setupDatabase = (bootstrap_code) ->
    return with new pg.Client argv.db
        ..connect!
        ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x_json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
        ..query plv8x._mk_func \jseval {str: \text} \text """
function(str) { return eval(str) }
"""
        ..query plv8x._mk_func \jsapply {str: \text, args: \plv8x_json} \plv8x_json """
function (func, args) {
    return eval(func).apply(null, args);
}
"""
        r = ..query 'INSERT INTO "plv8x".code ("name", "code", "load_seq") VALUES($1, $2, $3)' [\LiveScript, src, 0]
        r.on \row -> console.log ...
        r.on \end -> console.log \end; ..end!

q = setupDatabase!
