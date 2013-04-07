{_mk_func} = require \..
{plv8x-sql} = require \./sql

module.exports = (drop, cascade, done) ->
  if typeof drop is \function
    done = drop
    drop = false

  rows <~ @query "select version()"
  @conn
    ..query plv8x-sql drop, cascade

    [_, pg_version] = rows.0.version.match /^PostgreSQL ([\d\.]+)/
    if pg_version >= \9.1.0
      ..query '''
DO $$ BEGIN
    CREATE EXTENSION IF NOT EXISTS plv8;
EXCEPTION WHEN OTHERS THEN END; $$;
DO $$ BEGIN
    CREATE EXTENSION IF NOT EXISTS plls;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      /* translate this from perl using shelljs
      my $dir = `pg_config --sharedir`;
      chomp $dir;
      use File::Glob qw(bsd_glob);
      my @init_files = sort { $b cmp $a } bsd_glob("$dir/contrib/plv8*.sql");
      if (@init_files > 1) {
          warn "==> more than one version of plv8 found: ".join(',',@init_files);
      }
      eval {
          $self->{dbh}->do(scalar read_file($init_files[0]));
      };
      $self->{dbh}->do('rollback') if $self->{dbh}->err;
      */

    if pg_version < \9.2.0
      ..query '''
DO $$ BEGIN
    CREATE FUNCTION plv8x.json_syntax_check(src text) RETURNS boolean AS '
        try { JSON.parse(src); return true; } catch (e) { return false; }
    ' LANGUAGE plv8 IMMUTABLE;
EXCEPTION WHEN OTHERS THEN END; $$;

DO $$ BEGIN
    CREATE DOMAIN plv8x.json AS text CHECK ( plv8x.json_syntax_check(VALUE) );
EXCEPTION WHEN OTHERS THEN END; $$;
'''
    else
      ..query '''
DO $$ BEGIN
    CREATE DOMAIN plv8x.json AS json;
EXCEPTION WHEN OTHERS THEN END; $$;
'''
  @conn
    ..query _mk_func \plv8x.boot {} \void _boot
    ..query _mk_func \plv8x.eval {str: \text} \text _eval
    ..query _mk_func \plv8x.apply {str: \text, args: \plv8x.json} \plv8x.json _apply
    ..query _mk_func \plv8x.json_eval {code: \text} \plv8x.json (code) ->
      JSON.stringify eval("(function(){return #code})").apply(this)
    ..query _mk_func \plv8x.json_eval {data: \plv8x.json, code: \text} \plv8x.json (data, code) ->
      JSON.stringify eval("(function(){return #code})").apply(JSON.parse data)
    ..query _mk_func \plv8x.json_eval {code: \text, data: \plv8x.json} \plv8x.json (code, data) ->
      JSON.stringify eval("(function(){return #code})").apply(JSON.parse data)
    ..query '''
DROP OPERATOR IF EXISTS |> (NONE, text); CREATE OPERATOR |> (
    RIGHTARG = text,
    PROCEDURE = plv8x.json_eval
);
DROP OPERATOR IF EXISTS |> (plv8x.json, text); CREATE OPERATOR |> (
    LEFTARG = plv8x.json,
    RIGHTARG = text,
    COMMUTATOR = <|,
    PROCEDURE = plv8x.json_eval
);
DROP OPERATOR IF EXISTS <| (text, plv8x.json); CREATE OPERATOR <| (
    LEFTARG = text,
    RIGHTARG = plv8x.json,
    COMMUTATOR = |>,
    PROCEDURE = plv8x.json_eval
);
'''
    r = ..query "select plv8x.boot()"
    r.on \end done

_eval = (str) -> eval str

_apply = (func, args) ->
  func = "(function() {return (#func);})()"
  eval func .apply null args

_require = (name) ->
  return plv8x.global[name] if plv8x.global[name]?

  res = plv8.execute "select name, code from plv8x.code", []
  x = {}
  err = ''
  for {code,name:bundle} in res
    try
      loader = """
(function() {
    var module = {exports: {}};
    #code;
    return module.exports.require;
})()
"""
      req = eval loader
      module = req name
      return plv8x.global[name] = module if module?
    catch e
      if e isnt /Cannot find module/
        break
      err := e
  plv8.elog WARNING, "failed to load module #name: #err"

_boot =
  """
  function() {
    if (typeof plv8x == 'undefined')
      plv8x = {
        global: {},
        require: #{_require.toString!replace /(['\\])/g, '\$1'}
      };
      plv8x_require = plv8x.require
  }
  """

