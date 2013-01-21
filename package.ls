#!/usr/bin/env lsc -cj
author:
  name: ['Chia-liang Kao']
  email: 'clkao@clkao.org'
name: 'plv8x'
description: 'loading modules for plv8'
version: '0.0.1'
bin:
  plv8x: 'bin/cmd.js'
repository:
  type: 'git'
  url: 'git://github.com/clkao/plv8x.git'
scripts:
  prepublish: """
    env PATH="./node_modules/.bin:$PATH" lsc -cj package.ls &&
    lsc -bc bin &&
    lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  browserify: \1.17.x
  optimist: \0.3.x
  pg: \0.11.x
  resolve: \0.2.x
peerDependencies:
  LiveScript: \1.1.x
optionalDependencies: {}
