should = (require \chai).should!

expect = (require \chai).expect
var plx, plv8x, conString
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString := "tcp://localhost/#{ process.env.TESTDBNAME }"
    plv8x := require \..
    plv8x.should.be.ok
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    done!
  .. 'poly-func', (done) ->
    <- plx.mk-user-func "plv8x.json polyelement(anyelement)", ':-> it'
    err, res <- plx.conn.query """
      select polyelement(names) as ret
      FROM (values (1,'{"foo": 1}'::json), (2, '{"bar": 2}'::json)) as names(id, content)
    """
    expect(err).to.be.a('null');
    expect res.rows .to.be.deep.equal [
       * ret: id: 1, content: foo: 1
       * ret: id: 2, content: bar: 2
    ]
    done!
  .. 'poly-func-array', (done) ->
    <- plx.mk-user-func "plv8x.json polyarray(anyarray)", ':-> it'
    err, res <- plx.conn.query """
      select polyarray(array_agg(_)) as ret from
      (select * from (values (1,'{"foo": 1}'::json), (2, '{"bar": 2}'::json)) as names(id, content)) _
    """
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.be.deep.equal [
       * id: 1, content: foo: 1
       * id: 2, content: bar: 2
    ]
    done!
