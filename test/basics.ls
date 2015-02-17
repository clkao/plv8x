should = (require \chai).should!

expect = (require \chai).expect
var plx, plv8x, conString
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString := process.env.TESTDB ? "tcp://localhost/#{ process.env.TESTDBNAME }"
    console.log conString
    plv8x := require \..
    plv8x.should.be.ok
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    done!
  .. 'eval', (done) ->
    <- plx.query "select plv8x.eval('plus_one = function(a) { return a + 1 }')"
    rows <- plx.query "select plv8x.apply($1, $2) as ret" [\plus_one, JSON.stringify [42]]
    expect rows.0.ret .to.equal 43
    done!
  .. 'evalit', (done) ->
    rows <- plx.query "select plv8x.apply($1, $2) as ret" ['function(a) { return a + 1}', JSON.stringify [42]]
    expect rows.0.ret .to.equal 43
    done!
  .. 'purge', (done) ->
    <- plx.purge
    <- plv8x.new conString
    res <- plx.list
    expect [name for {name} in res] .to.be.deep.equal <[plv8x]>
    done!
  .. 'import', (done) ->
    <- plx.import-bundle \LiveScript, './node_modules/LiveScript/package.json'
    res <- plx.list
    expect [name for {name} in res] .to.be.deep.equal <[plv8x LiveScript]>
    done!
  .. 'import existing', (done) ->
    <- plx.import-bundle \LiveScript, './node_modules/LiveScript/package.json'
    res <- plx.list
    expect [name for {name} in res] .to.be.deep.equal <[plv8x LiveScript]>
    done!
  .. 'plv8x_require', (done) ->
    err, res <- plx.conn.query "select plv8x.eval($1) as ret", ["plv8x_require('LiveScript').VERSION"]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.equal \1.2.0
    done!
  .. 'lscompile', (done) ->
    plx.conn.query plv8x._mk_func \plv8x.lscompile {str: \text, args: \plv8x.json} \text plv8x.plv8x-lift "LiveScript", "compile"
    err, res <- plx.conn.query "select plv8x.lscompile($1, $2) as ret", ["-> 42", JSON.stringify {+bare}]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect (eval ret)! .to.equal 42
    done!
  .. 'mk-user-func', (done) ->
    <- plx.mk-user-func "text lsgo(text, plv8x.json)", ':-> plv8x_require "LiveScript" .compile ...'
    err, res <- plx.conn.query "select lsgo($1, $2) as ret", ["-> 42", JSON.stringify {+bare}]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect (eval ret)! .to.equal 42
    done!
  .. 'mk-user-func with dash-separated source', (done) ->
    <- plx.mk-user-func "plv8x.json patch_json(json, json[])", "fast-json-patch:apply"
    it.body.should.match /return plv8x.require\('fast-json-patch'\).apply.apply\(this, arguments\)/
    done!
  .. 'required object persistency', (done) ->
    err, res <- plx.conn.query """select plv8x.eval('plv8x_require("LiveScript").xxx = 123')"""
    expect(err).to.be.a('null');
    err, res <- plx.conn.query """select plv8x.eval('plv8x_require("LiveScript").xxx') as ret"""
    expect err .to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.equal 123
    done!
  .. 'required object persistency', (done) ->
    err, res <- plx.conn.query """select plv8x.json_eval('{"a": 1}'::json, '@b=2; @') as ret"""
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.be.deep.equal a: 1, b: 2
    done!
