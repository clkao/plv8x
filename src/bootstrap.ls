{plv8x-sql, _mk_func, plv8x-boot, plv8x-require, plv8x-lift} = require \..

module.exports = (drop, cascade, done) ->
  if typeof drop is \function
    done = drop
    drop = false

  with @conn
    rows <~ @query "select version()"
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
    ..query _mk_func \plv8x.eval {str: \text} \text """
function(str) {
    return eval(str)
}
"""
    ..query "select plv8x.eval($1)" ['plv8x_jsid = 0']
    ..query _mk_func \plv8x.evalit {str: \text} \text """
function (str) {
    ++plv8x_jsid;
    var id = "plv8x_jsid" + plv8x_jsid;
    var body = id + " = (function() {return (" + str + ");})()";
    var ret = eval(body);
    return id;
}
"""
    ..query _mk_func \plv8x.boot {} \void plv8x-boot plv8x-require
    ..query _mk_func \plv8x.lscompile {str: \text, args: \plv8x.json} \text plv8x-lift "LiveScript", "compile"
    ..query "select plv8x.boot()"
    r = ..query _mk_func \plv8x.apply {str: \text, args: \plv8x.json} \plv8x.json """
function (func, args) {
    return eval(func).apply(null, args);
}
"""
    r.on \end done


