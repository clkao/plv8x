#!/usr/bin/env lsc -cj
author:
  name: ['Chia-liang Kao']
  email: 'clkao@clkao.org'
name: 'plv8x'
description: 'Use JavaScript expressions and modules in PostgreSQL plv8'
version: '0.5.5'
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
    env PATH="./node_modules/.bin:$PATH" lsc -bc bin &&
    env PATH="./node_modules/.bin:$PATH" lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  async: \0.2.x
  optimist: \0.3.x
  pg: \2.1.x
  resolve: \0.3.x
  one: \2.5.x
  tmp: '0.0.x'
  LiveScript: \1.1.1
#  'coffee-script': \*
  'js-yaml': \*
devDependencies:
  mocha: \*
  chai: \*
  sequelize: 'git://github.com/clkao/sequelize.git'
  uax11: \0.0.2
optionalDependencies: {}
