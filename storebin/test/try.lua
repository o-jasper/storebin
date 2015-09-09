local serial = require "storebin"
local assert_eq = unpack(require "storebin.test.lib")

local tab = {1,2,4, 7.5,{},true,false,nil, sub={q=1,r="ska", 1/0,-1/0}, ska=43}

local file = "/tmp/lua_a"
print("---encode---")
serial.file_encode(file, tab)

print("---decode---")
local tab2 = serial.file_decode(file)

assert_eq(tab, tab2)
assert_eq(tab2, tab)

print("--string version--")
local d3 = serial.plain_encode(tab)
local tab3 = serial.decode(d3)

assert_eq(tab, tab3)
assert_eq(tab3, tab)

print("--opt version--")
local d4 = serial.compress_encode(tab)
print(d4)

local tab4 = serial.decode(d4)

assert_eq(tab, tab4)
assert_eq(tab4, tab)

print(#d3, #d4)
