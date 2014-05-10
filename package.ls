#!/usr/bin/env lsc -cj
author:
  name: ['Chia-liang Kao']
  email: 'clkao@clkao.org'
name: 'plv8x'
description: 'Use JavaScript expressions and modules in PostgreSQL plv8'
version: '0.6.5'
keywords: <[postgres pg database plv8]>
main: \lib/index.js
bin:
  plv8x: 'bin/cmd.js'
repository:
  type: 'git'
  url: 'git://github.com/clkao/plv8x.git'
scripts:
  test: '
    ln -sf ../../../bundled_modules/util node_modules/sequelize/node_modules/ &&
    ln -sf ../../../bundled_modules/events node_modules/sequelize/node_modules/ &&
    env PATH="./node_modules/.bin:$PATH" mocha'
  prepublish: """
    env PATH="./node_modules/.bin:$PATH" lsc -cj package.ls &&
    env PATH="./node_modules/.bin:$PATH" lsc -bpc bin/cmd.ls > bin/cmd.js &&
    env PATH="./node_modules/.bin:$PATH" lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  async: \0.2.x
  optimist: \0.6.x
  pg: \2.8.x
  resolve: \0.6.x
  browserify: '^3.46.1'
  'stream-buffers': '^0.2.5'
  tmp: '0.0.x'
  LiveScript: \1.2.0
#  'coffee-script': \*
  'js-yaml': \3.0.x
devDependencies:
  mocha: \*
  chai: \*
  uax11: \0.0.2
optionalDependencies: {}
