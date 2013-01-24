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
.option 'help' do
  alias: 'h'
  desc: 'Show this message'
.check (argv) ->
  throw '' if argv.help
  if process.argv.length <= 2 then throw 'Specify a parameter.'
.argv

conn = plv8x.connect argv.db
<- plv8x.bootstrap conn
console.log \done

done = -> conn.end!

switch
| argv.purge =>
  plv8x.purge conn, ->
    console.log it
    done!
  console.log \purge
| argv.list =>
  console.log \list
  plv8x.list conn, ->
    console.log it
    done!
| otherwise => console.log \foo; done!
