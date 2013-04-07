plv8x
======

[![Build Status](https://travis-ci.org/clkao/plv8x?branch=master)](https://travis-ci.org/clkao/plv8x)

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

    plv8x --db tcp://localhost/test -l
    [INFO] console - plv8x: 491425 bytes

Now try:

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


Actually it was LiveScript: (please send pullreqs for coffeescript support!)

    test=# select '{"foo": [1,2,3]}'::json |> '@foo.1 * 5';
     ?column?
    ----------
     10


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

# License

MIT
