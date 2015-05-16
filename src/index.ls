class PLX
  (@conn) ->
    @eval = @plv8x-eval
    @ap = @plv8x-apply

  bootstrap: (...args) ->
    require \./bootstrap .apply @, args

  end: -> @conn.end!

  query: (...args) ->
    cb = args.pop!
    err, {rows}? <- @conn.query ...args
    throw err if err
    cb? rows

  plv8x-eval: (code, cb) ->
    code = "(#code)()" if typeof code is \function
    @query "select plv8x.eval($1) as ret", [code], -> cb it?0?ret

  plv8x-apply: (code, args, cb) ->
    code = "(#code)()" if typeof code is \function
    args = JSON.stringify args if typeof args isnt \string
    @query "select plv8x.apply($1, $2) as ret", [code, args], -> cb it?0?ret

  list: (cb) ->
    @query "select name, length(code) as length from plv8x.code", cb

  purge: (cb) ->
    @query "delete from plv8x.code", cb

  delete-bundle: (name, cb) ->
    @query "delete from plv8x.code where name = $1" [name], -> cb it.rows

  _bundle: (name, manifest, cb) ->
    require! <[browserify]>
    exclude = <[one browserify pg plv8x pgrest express optimist uax11]>

    if name is \pgrest
      # XXX temporary solution till we get proper manifest exclusion going
      exclude ++= <[express cors gzippo connect-csv]>

    b = browserify {+ignoreMissing, standalone: name}
    for module in exclude => b.exclude module
    b.require manifest - /\package\.json$/, {+entry}

    err, buf <- b.bundle
    console.log err if err
    cb buf

  import-bundle: (name, manifest, cb) ->
    bundle_from = (name, m, cb) ~>
      @_bundle name, m, cb
    {mtime} = require 'fs' .statSync manifest
    rows <~ @query "select updated from plv8x.code where name = $1" [name]
    if rows.length
      return cb! if rows.0.updated and rows.0.updated >= mtime
    code <~ bundle_from name, manifest
    [q, bind] = if rows.length # udpate
      ["update plv8x.code set code = $2, updated = $3 where name = $1" [name, code, mtime]]
    else
      ["insert into plv8x.code (name, code, updated) values($1, $2, $3)" [name, code, mtime]]
    @query q, bind, cb

  import-funcs: (name, pkg, bootstrap, cb) ->
    funcs = for funcname, f of pkg when \function is typeof f and f.$plv8x and f.$bootstrap is bootstrap => let funcname, f
      (done) ~> @mk-user-func "#funcname#{f.$plv8x}" "#name:#funcname", -> done!
    require! async
    <- async.waterfall funcs
    cb!

  import-bundle-funcs: (name, manifest, body) ->
    pkg = try require (manifest - /package\.json$/)
    unless pkg
      return @import-bundle name, manifest, (cb) ~>
        cb <~ body
        return cb!

    <~ @import-funcs name, pkg, true
    <~ @import-bundle name, manifest
    cb <~ body
    <~ @import-funcs name, pkg, void
    cb!

  mk-user-func: (spec, source, cb) ->
    [_, rettype, name, args, rettype-after] = spec.match //^
      (?:([\.\w]+) \s+)? (\w+) \( (.*) \) (?:\s*:\s*([\.\s\w\[\]]+))?
    $// or throw "failed to parse #spec"

    rettype ?= rettype-after

    param-obj = {}
    if args
      for arg, idx in args.split /\s*,\s*/
        [_, type, param-name] = arg.match /^([\.\w\[\]]+)\s*(\w+)?$/ or throw "failed to parse param #arg"
        param-name ?= "__#{idx}"
        param-obj[param-name] = type

    [_, pkg, expression] = source.match /^([\w-]*):([\S\s]*)$/ or throw "failed to parse source #source"

    body = if pkg
      boot = true
      plv8x-lift pkg, expression
    else
      xpression-to-body expression
    <~ @query _mk_func name, param-obj, rettype, body, {boot, +cascade}

    cb { rettype, name, param-obj, body }


<[ bootstrap plv8xEval importBundle list purge deleteBundle mkUserFunc ]>.for-each !(key) ~>
    exports[key] = (conn, ...rest) ->
      console.error 'deprecated api, use PLX instead'
      plx = new PLX conn
      plx[key] ...rest

exports.new = (db, config, cb) ->
  if \function is typeof config
    cb = config
    config = {}
  # db can aslo be an object, mostly for connceting with local socket
  db = "tcp://localhost/#db" if \string is typeof db && db.indexOf('/') < 0
  pg = require \pg .native

  conn = new pg.Client db
    ..connect!
  plx = new PLX conn

  plx.register-json-type = (oid) ->
    pg.types.setTypeParser oid, 'text', JSON.parse.bind JSON

  if config.client
    return plx.query 'select plv8x.boot()' -> cb? plx

  <- plx.bootstrap
  <- plx.query 'select plv8x.boot()'
  <- plx.import-bundle \plv8x require.resolve \../package.json
  cb? plx

export function connect(db)
  require! pg
  new pg.Client db
    ..connect!

export function xpression-to-body(code)
  clivescript = if plv8? then plv8x.compile-livescript else compile-livescript
  ccoffee = if plv8? then plv8x.compile-coffeescript else compile-coffeescript
  cls = -> "(function () {return #{clivescript it} })()"
  match code
  | /^\s*->/     => cls code
  | /^\s*~>/     => cls code.replace /~>/ \->
  | /^\s*\=\>/   => ccoffee code.replace /\=\>/ \->
  | /^function/  => "(#code)"
  | /^\s*@/      => cls "-> #code"
  | /^\s*&/      => cls "-> #code"
  | /\breturn[(\s]/ => "(function(){#code})"
  | otherwise       => "(function(){return #code})"

export function compile-livescript(expression)
  require \livescript .compile expression, {+bare} .replace /;$/, ''

export function compile-coffeescript(expression)
  cs = require \CoffeeScript
  throw "CoffeeScript not found, use plv8x --import CoffeeScript:/path/to/extras/cofee-script.js to enable it" unless cs
  cs.compile expression, {+bare} .replace /;$/, ''

export function _mk_func (
  name, param-obj, ret, body, {lang = \plv8, skip-compile, cascade, boot} = {}
)
  params = []
  args = for pname, type of param-obj
    params.push "#pname #type"
    if type is \plv8x.json
      "JSON.parse(#pname)"
    else pname

  if lang is \plls and not skip-compile
    lang = \plv8
    compiled = compile-livescript body

  compiled ||= body
  body = "(eval(#compiled))(#args)";
  body = "JSON.stringify(#body)" if ret is \plv8x.json
  boot = if boot
    "if (typeof plv8x == 'undefined') plv8.execute('select plv8x.boot()', []);"
  else ''

  return """

SET client_min_messages TO WARNING;
DO \$PLV8X_EOF\$ BEGIN

DROP FUNCTION IF EXISTS #{name} (#params) #{if cascade => 'CASCADE' else ''};
EXCEPTION WHEN OTHERS THEN END; \$PLV8X_EOF\$;

CREATE FUNCTION #name (#params) RETURNS #ret AS \$PLV8X__BODY__\$
#boot;
return #body;
\$PLV8X__BODY__\$ LANGUAGE #lang IMMUTABLE STRICT;
  """

export function plv8x-lift(module, func-name)
  if [_, capture, method]? = func-name.match /^([\s,_]*)<-([-\w]+)?$/
    capture ||= "err, _"
    backcall = true
  else
    method = func-name

  fcall = if method => ".#method" else ''
  if backcall
    compile-livescript """
    ->
      var $$rv
      f = (plv8x.require '#{module}') #{fcall}
      args = [].slice.call(arguments).concat (#{capture}) ->
        $$rv := _
      f ...args
      $$rv
    """
  else
    compile-livescript "-> plv8x.require '#{module}' #fcall ..."

sql = require \./sql
export util = sql{define-schema}
