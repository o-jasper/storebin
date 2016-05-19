arg = arg or {}  -- (for the `alt_require.lua` test)

local assert_eq, gen_tree = unpack(require "storebin.test.lib")

local decode = require "storebin.decode"
local plain_encode = require "storebin.plain_encode"
local compress_encode = require "storebin.compress_encode"

-- NOTE: json disabled because it can only do lists or tables, not both at the
--   same time. The random generator doesn't do that.
-- local json = require "json"

local encdecs = {
   { encode=plain_encode,    decode=decode,      name="plain" },
   { encode=compress_encode, decode=decode,      name="compress" },
--   { encode=json.encode,     decode=json.decode, name="json" },

   { encode=require "storecmd.encode", decode= require "storecmd.decode", name="cmd" },
}

local seed = tonumber(arg[1])
if not seed then
   local x = os.clock()
   while x < 1000 do x = x * 10 end  -- Crude but whatevs/
   seed = os.time() + math.floor(x)
end
print("# Seed:", seed)
math.randomseed(seed)

local function clock()
   return math.floor(os.clock()*1e9 + 0.5)
end

print("#  For each one between brackets (times in nanoseconds)")
print("# i N [plainencode_time decode_time length]")
local list = {}
for _, el in ipairs(encdecs) do table.insert(list, el.name) end
print("# between brackets after each other " .. table.concat(list, ", "))

for i = 1, tonumber(arg[2]) or 20 do
   local tab, n = gen_tree(true,6, {mini=10000, maxi=10002})-- string_key=true, nice=true})
   local ret = {i, n}
   for _, el in ipairs(encdecs) do
      local pt = clock()
      local data = el.encode(tab)
      local et = clock() - pt
      if arg[3] == el.name then
         local n = 0
         for k,v in pairs(tab) do n = n + 1 print("*", k,v) end
         if n == 0 then print("<empty table>") end
         print("---")
         print(data)
         print("---")
      end
      local dt = clock()
      local a_tab = el.decode(data)
      local ft = clock()
      table.insert(ret, et)
      table.insert(ret, ft - dt)
      table.insert(ret, #data)
      assert_eq(a_tab, tab,   nil, " @" .. el.name .. "(after-before)\n" .. data)
      assert_eq(tab,   a_tab, nil, " @" .. el.name .. "(before-after)\n" .. data)
   end
   print(unpack(ret))
end
