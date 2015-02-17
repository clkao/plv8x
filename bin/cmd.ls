``#!/usr/bin/env node``
require! <[fs resolve pg pretty-bytes]>
plv8x = require \../

argv = require 'optimist' .usage 'Usage: plv8x {OPTIONS}' .wrap 80
.option 'db' do
  alias: 'd'
  desc: 'database connection string'
.option 'list' do
  alias: 'l'
  desc: 'List bundles'
.option 'purge' do
  desc: 'Purge bundles'
.option 'import' do
  alias: 'i'
  desc: 'Import bundles'
.option 'delete' do
  desc: 'Delete bundles'
.option 'inject' do
  alias: <[ fn f ]>
  desc: 'Define plv8 function from bundles or string'
.option 'query' do
  alias: 'c'
  desc: 'Execute query'
.option 'eval' do
  alias: 'e'
  desc: 'Eval the given expression in plv8x context'
.option 'eval-ls' do
  alias: 'E'
  desc: 'Eval the given LiveScript expression in plv8x context'
.option 'require' do
  alias: 'r'
  desc: 'Require the given file and eval in plv8x context'
.option 'json' do
  alias: 'j'
  desc: 'Use JSON for output'
.option 'yaml' do
  alias: 'y'
  desc: 'Use YAML for output (requires libyaml module)'
.option 'help' do
  alias: 'h'
  desc: 'Show this message'
.check (argv) ->
  throw '' if argv.help
  if process.argv.length <= 2 then throw 'Specify a parameter.'
.argv

conString = argv.db or process.env['PLV8XCONN'] or process.env['PLV8XDB'] or process.env.TESTDBNAME
unless conString
  console.log "ERROR: Please set the PLV8XDB environment variable, or pass in a connection string to -d"
  process.exit!
plx <- plv8x.new conString

done = (output) ->
  if output
    if argv.json
      output = JSON.stringify output
    else if argv.yaml
      YAML = require \js-yaml
      output = YAML.dump output
    console.log output
  plx.end!

switch
| argv.import =>
  [name, manifest=require.resolve("#name/package.json")] = argv.import.split \:
  plx.import-bundle name, manifest, -> done!
| argv.delete =>
  plx.delete-bundle argv.delete, -> done!
| argv.inject =>
  [spec, source] = argv.inject.split /\s*=\s*/
  plx.mk-user-func spec, source, ->
    console.log \ok spec
    done!
| argv.purge =>
  plx.purge ->
    console.log it
    done!
| argv.list =>
  plx.list (res) ->
    unless argv.json
      res = ["#name: #{pretty-bytes length}" for {name, length} in res].join '\n'
    done res
| argv.query =>
  plx.query argv.query, done
| argv.eval =>
  code = plv8x.xpression-to-body argv.eval
  plx.eval "(#code)()", done
| argv.'eval-ls' =>
  code = plv8x.xpression-to-body "~>#{ argv.'eval-ls' }"
  plx.eval "(#code)()", done
| argv.require =>
  code = fs.readFileSync argv.require, \utf8
  code = plv8x.compile-livescript code if argv.require is /\.ls$/
  plx.eval code, done
| otherwise => console.log "Unknown command: #{argv._.0}"; done!
