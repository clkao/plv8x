#!/usr/bin/env lsc -cj
author:
  name: ['Chia-liang Kao']
  email: 'clkao@clkao.org'
name: 'plv8x'
description: 'Use JavaScript expressions and modules in PostgreSQL plv8'
version: '0.3.1'
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
    lsc -bc bin &&
    lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  optimist: \0.3.x
  pg: \1.0.x
  resolve: \0.3.x
  one: '1.8.2'
  LiveScript: \1.1.1
  'coffee-script': \*
devDependencies:
  mocha: \*
  chai: \*
  sequelize: 'git://github.com/clkao/sequelize.git'
optionalDependencies: {}
