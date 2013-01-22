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
  conn = plv8x.connect argv.db
  <- plv8x.bootstrap conn
  console.log \done
  conn.end!

q = setupDatabase!
