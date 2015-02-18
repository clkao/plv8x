should = (require \chai).should!

expect = (require \chai).expect
var plx, conString
describe 'user package', -> ``it``
  .. 'loaded successfully.', (done) ->
    conString := process.env.TESTDB ? "tcp://localhost/#{ process.env.TESTDBNAME }"
    plv8x = require \..
    plv8x.should.be.ok
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    done!
  .. 'import', (done) ->
    <- plx.import-bundle \uax11, './node_modules/uax11/package.json'
    done!
  .. 'eval', (done) ->
    res <- plx.eval 'require("uax11").toFullwidth("hi")'
    expect(res).to.equal('ｈｉ')
    done!
  .. 'import user package', (done) ->
    <- plx.import-bundle \dummy1, './test/user-package/dummy1.js'
    done!
  .. 'user package works', (done) ->
    res <- plx.eval 'require("dummy1")("hi")'
    expect(res).to.equal('hi')
    done!
  .. 'import user package that requires root package', (done) ->
    <- plx.import-bundle \dummy2, './test/user-package/dummy2.js'
    done!
  .. 'user package works', (done) ->
    res <- plx.eval 'require("dummy2").xpressionToBody("1")'
    expect(res).to.equal('(function(){return 1})')
    done!
  .. 'eval', (done) ->
    res <- plx.eval 'require("uax11").toFullwidth("hi")'
    console.log res
    expect(res).to.equal('ｈｉ')
    done!