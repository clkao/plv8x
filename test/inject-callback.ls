should = (require \chai).should!

expect = (require \chai).expect
var plx, conString
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
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
  .. 'test data (return type after signature)', (done) ->
    <- plx.mk-user-func "uax_full(text):text", 'uax11:_<-'
    err, {rows}? <- plx.conn.query "select uax_full($1) as ret", ["http://github.com/clkao/plv8x"]
    expect(err).to.be.a('null');
    expect(rows.0.ret).to.equal('ｈｔｔｐ：／／ｇｉｔｈｕｂ．ｃｏｍ／ｃｌｋａｏ／ｐｌｖ８ｘ')
    done!
  .. 'test data (return type before signature)', (done) ->
    <- plx.mk-user-func "text uax_full(text)", 'uax11:_<-'
    err, {rows}? <- plx.conn.query "select uax_full($1) as ret", ["http://github.com/clkao/plv8x"]
    expect(err).to.be.a('null');
    expect(rows.0.ret).to.equal('ｈｔｔｐ：／／ｇｉｔｈｕｂ．ｃｏｍ／ｃｌｋａｏ／ｐｌｖ８ｘ')
    done!
