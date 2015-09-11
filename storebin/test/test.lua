local assert_eq, gen_tree = unpack(require "storebin.test.lib")

local decode = require "storebin.decode"
local plain_encode = require "storebin.plain_encode"
local compress_encode = require "storebin.compress_encode"

-- local json = require "json"

local encdecs = {
   { encode=plain_encode,    decode=decode,      name="plain" },
   { encode=compress_encode, decode=decode,      name="compress" },
--   { encode=json.encode,     decode=json.decode, name="json" },
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

print("#  For each one between brackets")
print("# N [plainencode_time decode_time length]")

for i = 1, tonumber(arg[2]) or 20 do
   local tab, n = gen_tree(true,6, {mini=10000, maxi=10002, string_key=true, nice=true})
   
   local ret = {n}
   for _, el in ipairs(encdecs) do
      local pt = clock()
      local data = el.encode(tab)
      local dt = clock()
      local a_tab = el.decode(data)
      local ft = clock()
      table.insert(ret, dt - dt)
      table.insert(ret, ft - dt)
      table.insert(ret, #data)
      assert_eq(a_tab, tab,   nil, " @" .. el.name .. "(after-before)\n" .. data)
      assert_eq(tab,   a_tab, nil, " @" .. el.name .. "(before-after)\n" .. data)
   end
   print(unpack(ret))
end
