#!/usr/bin/env lsc -cj
author:
  name: ['Chia-liang Kao']
  email: 'clkao@clkao.org'
name: 'plv8x'
description: 'loading modules for plv8'
version: '0.0.1'
main: \lib/index.js
bin:
  plv8x: 'bin/cmd.js'
repository:
  type: 'git'
  url: 'git://github.com/clkao/plv8x.git'
scripts:
  test: 'env PATH="./node_modules/.bin:$PATH" mocha'
  prepublish: """
    env PATH="./node_modules/.bin:$PATH" lsc -cj package.ls &&
    lsc -bc bin &&
    lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  optimist: \0.3.x
  pg: \0.11.x
  resolve: \0.2.x
  one: 'git://github.com/azer/onejs.git'
devDependencies:
  mocha: \*
  chai: \*
  LiveScript: \1.1.1
optionalDependencies: {}
