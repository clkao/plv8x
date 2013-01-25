should = (require \chai).should!

expect = (require \chai).expect
var plv8x, conn
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString = "tcp://localhost/#{ process.env.TESTDBNAME }"
    console.log conString
    plv8x := require \..
    plv8x.should.be.ok
    conn := plv8x.connect conString
    conn.should.be.ok
    done!
  .. 'bootstrap', (done) ->
    <- plv8x.bootstrap conn
    1.should.be.ok
    done!
  .. 'eval', (done) ->
    err, res <- conn.query "select jseval('plus_one = function(a) { return a + 1 }')"
    expect(err).to.be.a('null');
    err, res <- conn.query "select jsapply($1, $2)" [\plus_one, JSON.stringify [42]]
    expect err .to.be.a('null');
    expect res.rows.0.jsapply .to.equal(\43)
    done!
  .. 'evalit', (done) ->
    err, res <- conn.query "select jsevalit('function(a) { return a + 1 }') as ret"
    expect(err).to.be.a('null');
    func = res.rows.0.ret
    err, res <- conn.query "select jseval($1) as ret", ["typeof #func"]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.equal \function
    err, res <- conn.query "select jsapply($1, $2)" [func, JSON.stringify [42]]
    expect err .to.be.a('null');
    expect res.rows.0.jsapply .to.equal \43
    done!
  .. 'ls', (done) ->
    manifest = './node_modules/LiveScript/package.json'
    ls <- plv8x.bundle manifest
    # get require entrance for onejs bundles
    err, res <- conn.query "select jsevalit($1) as ret", ["""
(function() {
    var module = {exports: {}};
    #ls;
    return module.exports.require;
})()
    """]
    expect(err).to.be.a \null
    req = res.rows.0.ret
    err, res <- conn.query "select jsapply($1, $2) as ret", [req, '["LiveScript"]']
    expect err .to.be.a \null
    ret = JSON.parse res.rows.0.ret
    expect ret .to.deep.equal { VERSION: '1.1.1' }
    done!
  .. 'purge', (done) ->
    <- plv8x.purge conn
    done!
  .. 'import', (done) ->
    <- plv8x.import-bundle conn, \LiveScript, './node_modules/LiveScript/package.json'
    console.log it
    done!
  .. 'plv8x_require', (done) ->
    err, res <- conn.query "select jseval($1) as ret", ["require('LiveScript').VERSION"]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.equal \1.1.1
    done!
