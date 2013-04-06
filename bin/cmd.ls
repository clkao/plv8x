``#!/usr/bin/env node``
require! <[fs resolve pg]>
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

plx <- plv8x.new argv.db

done = -> plx.end!

switch
| argv.import =>
  plx.import-bundle ...argv.import.split(\:), ->
    done!
| argv.delete =>
  plx.delete-bundle argv.delete, ->
    done!
| argv.inject =>
  [spec, source] = argv.inject.split \=
  plx.mk-user-func spec, source, ->
    console.log \ok spec
    done!
| argv.purge =>
  plx.purge ->
    console.log it
    done!
| argv.list =>
  plx.list (res) ->
    for {name, length} in res
      console.log "#name: #{length} bytes"
    done!
| otherwise => console.log "Unknown command: #{argv._.0}"; done!
