local serial = require "storebin"
local assert_eq = unpack(require "storebin.test.lib")

local tab = {
   1,2,4, 7.5,{},true,false,nil, sub={q=1,r="ska", 1/0,-1/0}, ska=43,
   bools = { true, true, false, true, false, false },
   string_nil = "nil",
   ["nil"] = -1,
   strings={"one", "two", "three"},
   again={"one", "two", "three"},
   three={"one", "two", "three"},
}

local file = "/tmp/lua_a"
print("---encode---")
serial.file_encode(file, tab)

print("---decode---")
--local tab2 = serial.file_decode(file)

--assert_eq(tab, tab2, "@compress_file")
--assert_eq(tab2, tab, "@compress_file(rev)")


print("--opt version--")
local d4 = serial.compress_encode(tab)
print(d4)

local tab4 = serial.decode(d4)

assert_eq(tab, tab4, nil, "@compress")
assert_eq(tab4, tab, nil, "@compress(rev)")

print("--string version--")
local d3 = serial.plain_encode(tab)
local tab3 = serial.decode(d3)

assert_eq(tab3, tab, nil, "@plain(rev)")
assert_eq(tab, tab3, nil, "@plain")

print(#d3, #d4)
