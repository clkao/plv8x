0.5.2 / 2013-07-10
==================
  * Restore pg 9.1 support
  * Update to use node-pg 2.1

0.5.1 / 2013-07-05
==================
  * add primary key to plv8x.code name
  * ignore pgrest and express when bundling

0.5.0 / 2013-06-22
==================
  * Update to use node-pg 2.0
  * Properly handle json return type, no more manual parse required

0.4.4 / 2013-06-21
==================
  * Fix -f with injected code that uses LiveScript primtives like $import
  * More reliable mk_func with existing functions being used in views
  * Allow specifying -f return type with a trailing colon
  * Fix -f functions without args

0.4.3 / 2013-05-08
==================
  * Restore support for PostgreSQL 9.0

0.4.2 / 2013-04-24
==================
  * Support injecting functions with callback callconv
  * Support injecting functions exported as root object

0.4.1 / 2013-04-24
==================
  * Fix importing module-name-with-dash (@selenamarie)

0.4.0 / 2013-04-21
==================
  * More helpful error message when --db is missing

0.3.4 / 2013-04-14
==================

  * Add -d alias for --db
  * Add -r and -e for eval in plv8x context
  * Add -c for executing queries
  * Add --json for json output
