--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local floor, abs = math.floor, math.abs

local encode_uint = require "storebin.lib.encode_uint"

local function submerge(x)
   return math.ceil(math.log(x)/math.log(2))
end

local function encode_float(write, data)
   local x = abs(data)
   local sub = submerge(x)
   local y = floor(x*2^(63-sub))

--   assert(abs(sub) >= 0, string.format("%s, %s, %s, %s %s",
--                                       data, data == 1/0, data == -1/0, 2*data == data,
--                                       data == data))
   encode_uint(write, (data < 0 and 4 or 3) + 8*(sub < 1 and 1 or 0) + 16*abs(sub))
   encode_uint(write, y)
end

-- 0 string
-- 1 integer - positive
-- 2 integer - negative
-- 3 float - positive
-- 4 float - negative
-- 6 table - without metatable.
-- 7 table - with metatable `:name_it` is to name the metatable.

local encoders = {}

local function encode(write, data)
   encoders[type(data) or "nil"](write, data)
end

local function encode_list(write, list)
   for _, el in ipairs(list) do encode(write, el) end
end

encoders = {
   string = function(write, data)
      assert(type(data) == "string")
      encode_uint(write, 0 + 8*#data)
      write(data)
   end,

   number = function(write, data)
      if data == 1/0 then
         encode_uint(write, 5 + 16*3)
      elseif data == -1/0 or (data~=0 and 2*data == data) or data ~= data then
         encode_uint(write, 5 + 16*4)
      elseif data%1 == 0 then -- Integer
         if data < 0 then
            encode_uint(write, 2 - 8*data)
         else
            encode_uint(write, 1 + 8*data)
         end
      elseif data then
         encode_float(write, data)
      end
   end,

   table = function(write, data)
      local n, got = 0, {}  -- Figure out what goes in the list.
      for i in ipairs(data) do
         got[i] = true
         n = n + 1
      end

      local keys, values, all_bool = {}, {}, true
      for k,v in pairs(data) do
         if not got[k] and v ~= nil and k ~= nil then
            table.insert(keys, k)
            table.insert(values, v)
            all_bool = all_bool and type(v) == "bool"
         end
      end
      if getmetatable(data) then  -- Write-in the name.
         -- Put in the name too.
         local name = type(data.metatable_name) == "function" and data:metatable_name() or ""
         assert(type(name) == "string")

         encode_uint(write, 7 + 8*#name)
         write(name)
      end

      encode_uint(write, 6 + 8*#keys)

      encode_uint(write, n)  -- Feed the list.
      encode_list(write, data)

      encode_list(write, keys)
      encode_list(write, values)
   end,

   boolean = function(write, data) encode_uint(write, 5 + 16*(data and 1 or 0)) end,

   ["nil"] = function(write) encode_uint(write, 5 + 16*2) end,
   
   ["function"] = function(write) encode_uint(write, 5 + 16*3) end,

   userdata = function(write) encode_uint(write, 5 + 16*4) end,

   thread = function(write) encode_uint(write, 5 + 16*5) end,
}

return encode
