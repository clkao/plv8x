plv8x
======

[![Build Status](https://travis-ci.org/clkao/plv8x.png?branch=master)](https://travis-ci.org/clkao/plv8x)

plv8x helps you manage functions and packages in plv8, postgresql's javascript
procedural language support.

# Install plv8js

Note: Requires postgresql 9.1 or later.  9.0 will be supported soon.

```
# for older distros: sudo add-apt-repository ppa:martinkl/ppa
sudo apt-get install libv8-dev

sudo easy_install pgxnclient
sudo pgxn install plv8
```

If you have trouble installing plv8 on MacOSX, try the fork that includes unmerged patches for build fixes here: https://github.com/clkao/plv8js

# Install plv8x

    % git clone git://github.com/clkao/plv8x.git; cd plv8x
    % npm i -g .

# Quick start

Enable plv8x for your database:

    % createdb test
    % plv8x -d test -l
    plv8x: 491425 bytes

Now create some test data with json columns: (example table from [Postgres 9.3 feature highlight: JSON operators](http://michael.otacoo.com/postgresql-2/postgres-9-3-feature-highlight-json-operators/))

    % psql test
    test=# CREATE TABLE aa (a int, b json);
    CREATE TABLE
    test=# INSERT INTO aa VALUES (1, '{"f1":1,"f2":true,"f3":"Hi I''m \"Daisy\""}');
    INSERT 0 1
    test=# INSERT INTO aa VALUES (2, '{"f1":{"f11":11,"f12":12},"f2":2}');
    INSERT 0 1
    test=# INSERT INTO aa VALUES (3, '{"f1":[1,"Robert \"M\"",true],"f2":[2,"Kevin \"K\"",false]}');
    INSERT 0 1

Instead of `b->'f1'`, we use `b~>'this.f1'`, which means bind `b` as `this` and evaluate the right hand side (`this.f1`):

    test=# SELECT b~>'this.f1' AS f1, b~>'this.f3' AS f3 FROM aa WHERE a = 1;
     f1 |         f3         
    ----+--------------------
     1  | "Hi I'm \"Daisy\""

If you like coffee, `@` works too:

    test=# SELECT b~>'@f1' AS f1, b~>'@f3' AS f3 FROM aa WHERE a = 1;
     f1 |         f3         
    ----+--------------------
     1  | "Hi I'm \"Daisy\""

For multiple keys, you can of course do `b~>'@f1'~>'@f12'`, but single expression will do:

    test=# SELECT b~>'@f1'~>'@f12' as f12_long, b~>'@f1.f12' AS f12 FROM aa WHERE a = 2;
     f12_long | f12 
    ----------+-----
     12       | 12

Ditto for arrays:

    postgres=# SELECT b~>'@f1[0]' as f1_0 FROM aa WHERE a = 3;
    f1_0
    ------
    1

Unary `~>` for just evaluating the expression:

    test=# SELECT ~>'[1 to 10]' AS f1
               f1           
    ------------------------
     [1,2,3,4,5,6,7,8,9,10]

`~>` is actually a shorthand for `|> '~>...'`.  Using raw `|>` for plain
old javascript:

    test=# select '{"foo": [1,2,3]}'::json |> 'function() { return this.foo[1] }';
     ?column?
    ----------
     2

Expression works too:

    test=# select '{"foo": [1,2,3]}'::json |> 'return this.foo[1]';
     ?column?
    ----------
     2

CoffeeScript:

    test=# select '{"foo": [1,2,3]}'::json |> '@foo[1]';
     ?column?
    ----------
     2

```<|``` is ```|>``` reversed:

    test=# select '@foo.1 * 5' <| '{"foo": [1,2,3]}'::json
     ?column?
    ----------
     10

```|>``` as unary operator:

    test=# select |> '~> plv8x.require "LiveScript" .compile "-> \Hello" {+bare}';
                   ?column?
    --------------------------------------
     "(function(){\n  return Hello;\n});"

# Importing nodejs modules and creating user functions

Let's try reusing some existing npm modules:

    % plv8x -d test --import qs:./node_modules/qs/package.json 
    % psql test

    # parse a query string
    test=# select ~>'require("qs").parse("foo=bar&baz=1")' as qs;
               qs            
    -------------------------
     {"foo":"bar","baz":"1"}

    # actually use the parsed query string as json
    test=# select qs~>'@foo' as foo from  (select ~>'require("qs").parse("foo=bar&baz=1")' as qs) a;
      foo  
    -------
     "bar"

    # create a user function from qs so we don't have to require it:
    % plv8x -d test --fn 'plv8x.json parse_qs(text)=qs:parse'
    ok plv8x.json parse_qs(text)
    # Now parse_qs is a postgresql function:
    test=# select parse_qs('foo=bar&baz=1') as qs;
               qs            
    -------------------------
     {"foo":"bar","baz":"1"}

# Calling conventions for user functions

We support both synchronous and async functions, as well as bare functions defined in
`module.exports`.

By default, the first two arguments to an async (back-call) function is taken
to be `error` and `result` respectively:

    % plv8x -d test --fn 'text fn(text)=pkg:'           # out = pkg(x)
    % plv8x -d test --fn 'text fn(text)=pkg:method'     # out = pkg.method(in)
    % plv8x -d test --fn 'text fn(text)=pkg:<-'         # pkg(x, cb(err, out))
    % plv8x -d test --fn 'text fn(text)=pkg:<-method'   # pkg.method(x, cb(err, out))

Using an underscore, one can specify exactly which async callback parameter
to expect from the lifted function:

    % plv8x -d test --fn 'text fn(text)=pkg:<-'         # pkg(x, cb(err, out))
    % plv8x -d test --fn 'text fn(text)=pkg:_<-'        # pkg(x, cb(out))
    % plv8x -d test --fn 'text fn(text)=pkg:,_<-'       # pkg(x, cb(_0, out))
    % plv8x -d test --fn 'text fn(text)=pkg:,,_<-'      # pkg(x, cb(_0, _1, out))

# License

MIT
