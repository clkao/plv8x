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
  .. 'purge', (done) ->
    <- plv8x.purge conn
    done!
  .. 'import', (done) ->
    <- plv8x.import-bundle conn, \LiveScript, './node_modules/LiveScript/package.json'
    <- plv8x.import-bundle conn, \plv8x, './package.json'
    <- plv8x.import-bundle conn, \sequelize, './sequelize.js'
    done!
  .. 'plv8x_require', (done) ->
    err, res <- conn.query """select plv8x_eval(lscompile($1, '{"bare": true}')) as ret""", ["""
    ``console`` = { log: -> plv8.elog(WARNING, ...arguments) }
    ``setTimeout`` = -> it!
    {STRING, TEXT, DATE, BOOLEAN, INTEGER}:Sequelize = plv8x_require "sequelize"
    sql = new Sequelize null, null, null do
        dialect: "plv8"

    SystemModel = do
        field: { type: STRING, +primaryKey }
        value: STRING
        last_update: DATE

    System = sql.define 'System' SystemModel, { +freezeTableName }

    do
        (entry) <- System.find('socialtext-schema-version').success
        console.log entry
    "wtf"
    """]
    expect(err).to.be.a('null');
    {ret} = res.rows.0
    expect ret .to.equal \1.1.1
    done!
