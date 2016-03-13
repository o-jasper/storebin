# Simple tree-to-binary encoder and decoder.
Encodes the types and such aswel too.
`number`, `string`, `table`, `nil`, `boolean` should work entirely.

Metatables are not stored.
(There is some functionality in there but it doesnt seem important enough
for me)

### Install
Do your own thing.. Add to this directory to `package.path` or..

* Add a `~/.lualibs/` directory (if you havent)
* In `~/.init.lua` add `~/.lualibs` to `package.path` (if you havent)

     local home = os.getenv("HOME")
     package.path = package.path ..
         string.format(";%s/.lualibs/?.lua;%s/.lualibs/?/init.lua", home, home)
* `cd ~/.lualibs; ln -s $THISPROJ/storebin`


For storecmd, `cd ~/.lualibs; ln -s $THISPROJ/storecmd` *however* i am not
happy with that code. It was intended to be trees-easily-human readable.

### Usage
`require "storebin"` all these functions are accessible directly via
`require "storebin.encode"` and similar. They're only obtained once accessed.

* `.encode(data)` &rarr; string,

* `.decode(string)` &rarr; data (same as `require "storebin.string"`)

* `.file_encode(file_or_fd, data)` to that file.

* `.file_decode(file_or_fd)`

Those use the defaults, for encoding there are
`.plain_encode` and `.compress_encode` versions.

Suggest other encodes/decoders to follow the same pattern.
The non-file portion of the above is that json does. If you have your own pattern,
you can emulate the above. For this you dont have to provide them all, but it is
better to not-retract once you have added a function ina release.

`require("storebin.via")(encode_and_decode)`  creates the above via
`.encode` and `.decode`.

`require "storebin.via_json"` &rarr; `require("storebin.via")(require "json")`

### How it works
It hinges on variable-size stored unsigned integers. As implemented by
`storebin.lib.encode_uint`. If the last bit is true, then the unsigned integer
continues. Integers stored with it < 128^n take one `n` bytes.
Entry-integer values take more; < 128^n / 8 bytes `i%8` indicates the kind,
see below.

A **entry** it reads in an unsigned integer first.(this is not the top)

`x%8` is the type, and `f==floor(x/8)` indicates other information on the data;

* (`0`) string, `f` is the length.
* (`1`) For unsigned integers: `f` *is* the number read.
* (`2`) Signed; `-f` is the number.
* (`3`) Positive floating points, `f%2 == 0` is whether exponent
  positive/negative. `-+floor(f/2)` is the power-of-two-exponent.
  The value is read as subsequent uint.
* (`4`) Negative floating points. 
* (`5`) Various other items. `f` indicates which one in:

  + If `f%2 == 1` then it is `({true, false, nil, 1/0, -1/0})[1 + floor(f/2)]`

    Floats are not entirely clear enough i.e, `sqrt(-1)` and `1/0` seem to act
    different. When not understood, `-1/0`, at the moment.
  + If `f%2 == 1`  and the `g=floor(f/2)` as index falls outside the above array,
    then `g=5` indicates all the key-values are by boolean arrays, `6` all the
    list-values are, and `7` both by boolean arrays.

    The number of booleans is encoded as the normal unsigned integer encoding.
    After that the booleans encoded left-first, in a whole number of bytes.
  + If `f%2 == 0` it reads out the `floor(f/2)`th definition that is provided
    with the record.

  Note, the `f%2==1` case so far goes up to `(1+7*2)*8=120`, so we filled up
  all possibilities that take one byte. It may be better to bump the
  boolean-arrays up so others can take those three one-byte cases.

* (`6`) Tables *without* metatables. `f` is the length of the key-value table portion.
  then an uint getting the length of list items.
  
  That number of decodes(from the top, typed again) is done getting those elements.
  
  Then `f` time getting the key, and then the value.(from the top, typed again)
      
* (`7`) Tables *with* metatables. Reads up the name; a uint length, and then that
  many bytes, *before* the reading of the (non-`f`) Poorly tested.

The **top** of the `.encode(..)`-ed record is *not* an entry, instead it is an uint
indicating a set of definitions, after that an entry.

#### Compressive measures
Just do some limited measures for compression. Only do measures where programs like
gzip "dont know" how it is structured, and so i can give that a hand.

* **Lists** (done)

* **All-same-types** I basically decided not too.

* **Keys, _then_ values**, doing the keys first and then the values, both
  sorted by key probably increases chance of i.e. gzip "seeing the repetition there".

* **Repetition** repetitions in plain data are indicated by their number.

## TODO

* The float situation `&pm;inf` or `nan` are only recorded insofar i detect them.
  (afaics all finite numbers are good. Also portability wise)

* Speed not a high priority at the moment, but a C version would definitely be
  faster. Also unclear if `lua` "sees through" the `read`/`write` functions
  passed.

  C might also make it more useable for non-lua users.

## Lua Ring

* [lua_Searcher](https://github.com/o-jasper/lua_Searcher) sql formulator including
  search term, and Sqlite bindings.

* [page_html](https://github.com/o-jasper/page_html) provide some methods on an object,
  get a html page.(with js)

* [storebin](https://github.com/o-jasper/storebin) converts trees to binary, same
  interfaces as json package.(plus `file_encode`, `file_decode`)
  
* [PegasusJs](https://github.com/o-jasper/PegasusJs), easily RPCs javascript to
  lua. In pegasus.

* [tox_comms](https://github.com/o-jasper/tox_comms/), lua bindings to Tox and
  bare bot.
