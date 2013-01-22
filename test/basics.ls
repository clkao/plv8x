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
