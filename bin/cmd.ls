require! <[browserify fs resolve pg]>

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
#console.log src

bootstrap_code = """
1
"""

setupDatabase = (bootstrap_code) ->
    return with new pg.Client argv.db
        ..connect!
#        ..query bootstrap
#        ..query "select plv8x_bootstrap()");
        r = ..query 'INSERT INTO "plv8x".code ("name", "code", "load_seq") VALUES($1, $2, $3)' [\LiveScript, src, 0]
        r.on \row -> console.log ...
        r.on \end -> console.log \end; ..end!

q = setupDatabase!
