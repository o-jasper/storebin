local assert_eq, gen_tree = unpack(require "storebin.test.lib")

local encode = require "storebin.plain_encode"
local decode = require "storebin.decode"
local opt_encode = require "storebin.compress_encode"

local seed = tonumber(arg[1])
if not seed then
   local x = os.clock()
   while x < 1000 do x = x * 10 end  -- Crude but whatevs/
   seed = os.time() + math.floor(x)
end
print("Seed:", seed)
math.randomseed(seed)

for i = 1, tonumber(arg[2]) or 20 do
   local t, n = gen_tree(true,6, {mini=10000, maxi=10002})
   print("Run", i, n)
   
   local d1 = encode(t)
   local t1 = decode(d1)
   assert_eq(t1, t, " @plain")
   assert_eq(t, t1, " @plain(rev)")

--   local d2 = opt_encode(t)
--   local t2 = decode(d2)
--   assert_eq(t2, t)
--   assert_eq(t, t2)
--   -- This being essentially noise, not much chance of winning.
--   if #d1 ~= #d2 then print("", #d1, #d2) end
end
