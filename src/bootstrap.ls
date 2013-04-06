{_mk_func, plv8x-boot, plv8x-require, plv8x-lift} = require \..
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
    ..query _mk_func \plv8x.boot {} \void plv8x-boot plv8x-require
    ..query _mk_func \plv8x.eval {str: \text} \text _eval
    ..query _mk_func \plv8x.apply {str: \text, args: \plv8x.json} \plv8x.json _apply
    r = ..query "select plv8x.boot()"
    r.on \end done

_eval = (str) -> eval str

_apply = (func, args) ->
  func = "(function() {return (#func);})()"
  eval func .apply null args
