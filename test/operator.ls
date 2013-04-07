should = (require \chai).should!

expect = (require \chai).expect
var plx
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString = "tcp://localhost/#{ process.env.TESTDBNAME }"
    plv8x = require \..
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    done!
  .. 'eval', (done) ->
    rows <- plx.query "select |> '1' as ret"
    expect JSON.parse rows.0.ret .to.equal(1)
    done!
  .. 'eval', (done) ->
    rows <- plx.query "select $1 |> $2 as ret", [ JSON.stringify({ hello: [2, 3, 4] }), 'this.hello[1]' ]
    expect JSON.parse rows.0.ret .to.equal(3)
    done!
