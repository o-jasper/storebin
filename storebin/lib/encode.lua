--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local floor, abs = math.floor, math.abs

local encode_uint = require "storebin.lib.encode_uint"
local encode_bool_arr = require "storebin.lib.encode_bool_arr"

local floor, ceil, log = math.floor, math.ceil, math.log
local function encode_float(write, data)
   local x = abs(data)
   local sub = ceil(log(x, 2))
   local y = floor(x*2^(63-sub))

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

local function encode_table(write, data)
   local n, got, list_bool = 0, {}, true  -- Figure out what goes in the list.
   for i, el in ipairs(data) do
      got[i] = true
      n = n + 1
      list_bool = list_bool and type(el) == "boolean"
   end

   local keys, values, val_bool = {}, {}, true
   for k,v in pairs(data) do
      if not got[k] and v ~= nil and k ~= nil then
         table.insert(keys, k)
         table.insert(values, v)
         val_bool = val_bool and type(v) == "boolean"
      end
   end
   if getmetatable(data) then  -- Write-in the name.
      -- Put in the name too.
      local name = type(data.metatable_name) == "function" and data:metatable_name() or ""
      assert(type(name) == "string")

      encode_uint(write, 7 + 8*#name)
      write(name)
   end

   local val_bool  = (#keys > 2 and val_bool)  -- No point in doing empty lists.
   local list_bool = (n > 2 and list_bool)
   if val_bool or list_bool then
      encode_uint(write, 5 + 16*(val_bool and list_bool and 7 or val_bool and 5 or 6))
      encode_uint(write, #keys)
   else
      encode_uint(write, 6 + 8*#keys)
   end

   encode_uint(write, n)  -- Feed the list.
   local fun = (list_bool and encode_bool_arr or encode_list)
   fun(write, data)

   encode_list(write, keys)  -- And the key-values.
   local fun = (val_bool and encode_bool_arr or encode_list)
   fun(write, values)
end

local function encode_string(write, data)
   assert(type(data) == "string")
   encode_uint(write, 0 + 8*#data)
   write(data)
end

local function encode_number(write, data)
   if data == 1/0 then  -- Some annoying cases.
      encode_uint(write, 5 + 16*3)
   elseif data == -1/0 or (data~=0 and 2*data == data) or data ~= data then
      encode_uint(write, 5 + 16*4)
   elseif data%1 == 0 then -- Integer
      if data < 0 then
         encode_uint(write, 2 - 8*data)
      else
         encode_uint(write, 1 + 8*data)
      end
   else -- Floats.
      encode_float(write, data)
   end
end

encoders = {
   string = encode_string,
   number = encode_number,
   table = encode_table,
   boolean = function(write, data) encode_uint(write, 5 + 16*(data and 1 or 0)) end,
   ["nil"] = function(write) encode_uint(write, 5 + 16*2) end,
   ["function"] = function(write) error("Can't encode functions") end,
   -- encode_uint(write, 5 + 16*3) end,
   userdata = function(write) encode_uint(write, 5 + 16*4) end,
   thread = function(write) encode_uint(write, 5 + 16*5) end,
}

return encode
