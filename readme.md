*NOTE: not quite ready..*

# Simple encoder and decoder.
Encodes the types and such aswel too.
`number`, `string`, `table`, `nil`, `boolean` should work entirely.

Metatables are not stored, but you can use `:metatable_name()` to deposit a
name for it, then later, decoding, you can, the name can cause a function to run with
the name and input table as argument.

That way, perhaps userdata, thread, functions can be re-added by
the provided function.

### Install
* Add a `~/.lualibs/` directory (if you havent)
* In `~/.init.lua` add `~/.lualibs` to `package.path` (if you havent)

     local home = os.getenv("HOME")
     package.path = package.path ..
         string.format(";%s/.lualibs/?.lua;%s/.lualibs/?/init.lua", home, home)
* `cd ~/.lualibs; ln -s $THISPROJ/storebin`

### Usage
`require "storebin"` all these functions are accessible directly via
`require "storebin.encode"` and similar. They're only obtained once accessed.

* `.encode(data)` &rarr; string,

* `.decode(string)` &rarr; data (same as `require "storebin.string"`)

* `.file_encode(file_or_fd, data)` to that file.

* `.file_decode(file_or_fd)`

Those use the defaults, for encoding there are
`.plain_encode` and `.compress_encode` versions.

Suggest othe encodes/decoders to follow the same pattern.
The non-file portion of the above is that json does. If you have your own pattern,
you can emulate the above. For this you dont have to provide them all, but it is
better to not-retract once you have added a function ina release.


`require("storebin.via")(encode_and_decode)`  creates the above via
`.encode` and `.decode`.

`require "storebin.via_json"` &rarr; `require("storebin.via")(require "json")`

### How it works
It hinges on variable-size stored unsigned integers.

Each item, it reads in an unsigned integer first.

`x%8` is the type, and `f==floor(x/8)` indicates other information on the data;

* (`0`) string, `f` is the length.
* (`1`) For unsigned integers: `f` *is* the number read.
* (`2`) Signed; `-f` is the number.
* (`3`) Positive floating points, `f%2 == 0` is whether exponent
  positive/negative. `-+floor(f/2)` is the power-of-two-exponent.
  The value is read as subsequent uint.
* (`4`) Negative floating points. 
* (`5`) Various other items. `f` indicates which one in `{true, false, nil, 1/0, -1/0}`

  Floats are not entirely clear enough i.e, `sqrt(-1)` and `1/0` seem to act
  different. When not understood, `-1/0`, at the mooment.
* (`6`) Tables *without* metatables. `f` is the length of the key-value table portion.
  then an uint getting the length of list items.
  
  That number of decodes(from the top, typed again) is done getting those elements.
  
  Then `f` time getting the key, and then the value.(from the top, typed again)
      
* (`7`) Tables *with* metatables. Reads up the name; a uint length, and then that
  many bytes, *before* the reading of the (non-`f`)

The end of the unsigned indicators is indicated because the last bit is always `1`
if it has not yet ended.(this could easily be changed)

When a number `<128` it takes up one byte, and `<16384` only two.
In encodings-including-the-type this means integers `<16` take one byte. `<2048` two.
Same for the length indicating part of strings and tables.

#### Compressive measures
Just do some limited measures for compression. Only do measures where programs like
gzip "dont know" how it is structured, and so i can give that a hand.

* **Lists** (done)

* **All-same-types** in lists, keys, and values are implemented.
  TODO is compressive version does not actually do this yet.

* **Keys, _then_ values**, doing the keys first and then the values, both
  sorted by key probably increases chance of i.e. gzip "seeing the repetition there".

* **Repetition** repetitions in plain data are indicated by their number.

## TODO

* The float situation `&pm;inf` or `nan` are only recorded insofar i detect them.
  (afaics all finite numbers are good. Also portability wise)

* Better testing, profiling. (`via.lua` entirely untested.)

* Speed not a high priority at the moment, but a C version would definitely be
  faster. Also unclear if `lua` "sees through" the `read`/`write` functions
  passed.

  C might also make it more useable for non-lua users.

* Compressive version should use subsequent-same-types.
