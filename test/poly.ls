should = (require \chai).should!

expect = (require \chai).expect
var plx, plv8x, conString, pg_version
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString := process.env.TESTDB ? "tcp://localhost/#{ process.env.TESTDBNAME }"
    plv8x := require \..
    plv8x.should.be.ok
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    rows <- plx.query "select version()"
    [, pg_version] := rows.0.version.match /^PostgreSQL ([\d\.]+)/
    done!
  .. 'poly-func', (done) ->
    if pg_version < \9.2.0
      it.skip 'skipped for < 9.2', ->
      return done!

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
    if pg_version < \9.2.0
      it.skip 'skipped for < 9.2', ->
      return done!
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
