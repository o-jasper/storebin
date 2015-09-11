
local fun_encode_bool_arr = require "storebin.lib.encode_bool_arr"
local fun_decode_bool_arr = require "storebin.lib.decode_bool_arr"

local function encode_bool_arr(...)
   local str = ""
   fun_encode_bool_arr(function(c) str = str .. c end, ...)
   return str
end
local function decode_bool_arr(str, cnt)
   local i = 0
   local function read(n) 
      local ret = str.sub(str, i, i + n)
      i = i + n
      return ret
   end
   return fun_decode_bool_arr(read, cnt, {})
end

local rnd_bool, N = {}, tonumber(arg[0]) or 256
for i = 1, N do
   table.insert(rnd_bool, math.random(2) == 1)
end

local assert_eq = unpack(require "storebin.test.lib")

for n = 1, N do
   local data = encode_bool_arr(rnd_bool, n)
   assert(type(data) == "string")
   assert_eq(decode_bool_arr(data, n), rnd_bool, " left is result")
end
