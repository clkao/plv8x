require! <[browserify fs resolve pg]>
plv8x = require \../

argv = require 'optimist' .usage 'Usage: plv8x {OPTIONS}' .wrap 80
.option 'db' do
  desc: 'database connection string'
.option 'list' do
  alias: 'l'
  desc: 'List bundles'
.option 'purge' do
  desc: 'Purge bundles'
.option 'import' do
  desc: 'Import bundles'
.option 'delete' do
  desc: 'Delete bundles'
.option 'inject' do
  desc: 'Inject plv8 function from bundles or string'
.option 'help' do
  alias: 'h'
  desc: 'Show this message'
.check (argv) ->
  throw '' if argv.help
  if process.argv.length <= 2 then throw 'Specify a parameter.'
.argv

conn = plv8x.connect argv.db
<- plv8x.bootstrap conn

done = -> conn.end!

switch
| argv.import =>
  plv8x.import-bundle conn, ...argv.import.split(\:), ->
    done!
  console.log \purge
| argv.delete =>
  plv8x.delete-bundle conn, argv.delete, ->
    done!
| argv.inject =>
  [spec, source] = argv.inject.split \=
  plv8x.mk-user-func conn, spec, source, ->
    console.log it
    done!
| argv.purge =>
  plv8x.purge conn, ->
    console.log it
    done!
  console.log \purge
| argv.list =>
  plv8x.list conn, (res) ->
    for {name, code} in res
      console.log "#name: #{code.length} bytes"
    done!
| otherwise => console.log \foo; done!
