should = (require \chai).should!

expect = (require \chai).expect
var plx, conString
describe 'db', -> ``it``
  .. 'loaded successfully.', (done) ->
    # Load home page
    conString := process.env.TESTDB ? "tcp://localhost/#{ process.env.TESTDBNAME }"
    console.log conString
    plv8x = require \..
    plv8x.should.be.ok
    _plx <- plv8x.new conString
    plx := _plx
    plx.should.be.ok
    done!
  .. 'import', (done) ->
    <- plx.import-bundle \sequelize, './node_modules/sequelize/package.json'
    done!
  .. 'test data', (done) ->
    err, res <- plx.conn.query """
    DROP TABLE IF EXISTS plv8x_test;
    CREATE TABLE plv8x_test (
        field text not null,
        value text not null,
        last_update timestamp
    );
    INSERT INTO plv8x_test (field, value, last_update) values('plv8x_version', '0.0.1', NOW());
    """
    expect(err).to.be.a('null');
    done!
  .. 'sequelize test', (done) ->
    <- plx.eval helpers
    compiled <- plx.ap (-> plv8x.require("LiveScript").compile), ["""
    {STRING, TEXT, DATE, BOOLEAN, INTEGER}:Sequelize = plv8x_require "sequelize"
    sql = new Sequelize null, null, null { dialect: "plv8", -logging }

    SystemModel = do
        field: { type: STRING, +primaryKey }
        value: STRING
        last_update: DATE

    System = sql.define 'plv8x_test' SystemModel, { +freezeTableName }

    rv = null
    do
        (entry) <- System.find('plv8x_version').on "success"
        rv := entry

    pgprocess.next!

    rv
    """, {+bare}]
    ret <- plx.eval compiled
    expect ret?field .to.equal "plv8x_version"
    expect ret?value .to.equal "0.0.1"
    done!

function helpers()
    serial = 0
    deferred = []
    ``console`` = { log: -> args = [WARNING].concat [a for a in arguments]; plv8.elog.apply(null, args) }
    ``setTimeout`` = (fn, ms=0) -> deferred.push [fn, ms + (serial++ * 0.001)]
    ``pgprocess`` = do
        nextTick: (fn) -> setTimeout fn
        next: ->
            doit = (-> return unless deferred.length; deferred.shift!0!; doit!)
            doit!
    null
