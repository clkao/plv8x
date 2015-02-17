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
  async: '^0.9.0'
  optimist: \0.6.x
  pg: '^4.2.0'
  'pg-native': '^1.8.0'
  resolve: \0.6.x
  one: \2.5.x
  tmp: '0.0.x'
  LiveScript: \1.2.0
  'pretty-bytes': '^1.0.3'
#  'coffee-script': \*
  'js-yaml': \3.0.x
devDependencies:
  mocha: '^2.1.0'
  chai: '^2.0.0'
  sequelize: 'git://github.com/clkao/sequelize.git'
  uax11: \0.0.2
optionalDependencies: {}
