--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local floor, abs, char = math.floor, math.abs, string.char

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

local not_key = { ["nil"]=true, ["function"]=true, userdata=true, thread=true }

local function figure_tp_list(list)
   -- Figure if list has simple single type.
   -- 0         per-item-type.
   -- 1, 2, 3   pos, neg, both, integers
   -- 4         floats (both positive and negative)
   -- 5         booleans
   -- 6         string
   local inttp = {[1]=true, [2]=true, [3]=true}

   local tp = nil
   for _, el in ipairs(list) do
      if type(el) == "number" then
         if el == 1/0 or el == -1/0 or (el~=0 and 2*el == el) or el ~= el then
            return 0 -- Dont do these.
         elseif el == 0 then
            tp = tp or 1  -- Any integer or float type will do.
            if not (inttp[tp] or tp ==4) then return 0 end
         elseif el % 1 == 0 then  -- Positive integer.
            local h = (el >= 0) and 1 or 2
            tp = tp or h
            if not inttp[tp] then  -- Non integers, ditch.
               return 0
            elseif tp ~= h then  -- Also seen other sign.
               tp = 3
            end
         else  -- Float.
            tp = tp or 4
            if tp ~= 4 then return 0 end  -- Float or ditch.
         end
      else
         local h = ({boolean=5, string=6})[type(el) or 0] or 0
         if h == 0 then return 0 end
         tp = tp or h
         if tp ~= h then return 0 end
      end
   end
   return tp or 0
end

local function encode_bool_arr(write, list)
   assert(type(list[1]) == "boolean")
   local x, f = list[1] and 1 or 0, 2
   for i = 2, #list do
      if (i-1)%8 == 0 then
         print(x)
         write(char(x))
         x, f = 0, 1
      end
      if list[i] then
         x = x + f
      end
      f = 2*f
   end
   write(char(x))
end

local function encode_list(write, tp, list)
   assert(tp == figure_tp_list(list))
   if tp == 5 then
      encode_bool_arr(write, list)
   else
      for _, el in ipairs(list) do
         if tp == 1 then
            assert(type(el) == "number" and el % 1 == 0 and el >= 0)
            encode_uint(write, el)
         elseif tp == 2 then
            assert(type(el) == "number" and el % 1 == 0 and el <= 0)
            encode_uint(write, -el)
         elseif tp == 3 then
            assert(type(el) == "number" and el % 1 == 0, el)
            encode_uint(write, (el<0 and 1 or 0) + 2*abs(el))
         elseif tp == 4 then
            assert(type(el) == "number") 
            local x = abs(el)
            local sub = submerge(x)
            local y = floor(x*2^(63-sub))
            encode_uint(write, (sub < 1 and 1 or 0) + 2*abs(sub))
            encode_uint(write, (el < 0 and 1 or 0) + 2*y)
         elseif tp == 5 then
            error("BUG")
         elseif tp == 6 then
            assert(type(el) == "string", tostring(el))
            encode_uint(write, #el)
            write(el)
         else-- Untyped.
            encode(write, el)
         end
      end
   end
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

      local keys, values = {}, {}
      for k,v in pairs(data) do
         if not (not_key[k] or got[k]) and v ~= nil and k ~= nil then
            table.insert(keys, k)
            table.insert(values, v)
         end
      end
      local tp_keys, tp_values = figure_tp_list(keys), figure_tp_list(values)
      if getmetatable(data) then
         encode_uint(write, 7 + 8*tp_keys + 64*tp_values + 512*#keys)
         -- Put in the name too.
         local name = type(data.metatable_name) == "function" and data:metatable_name() or ""
         assert(type(name) == "string")
         encode_uint(write, #name)
         write(name)
      else
         encode_uint(write, 6 + 8*tp_keys + 64*tp_values + 512*#keys)
      end
      local tp_list = figure_tp_list(data)
      encode_uint(write, tp_list + 8*n)  -- Feed the list.
      encode_list(write, tp_list, data)

      encode_list(write, tp_keys,   keys)
      encode_list(write, tp_values, values)
   end,

   boolean = function(write, data) encode_uint(write, 5 + 16*(data and 1 or 0)) end,

   ["nil"] = function(write) encode_uint(write, 5 + 16*2) end,
   
   ["function"] = function(write) encode_uint(write, 5 + 16*3) end,

   userdata = function(write) encode_uint(write, 5 + 16*4) end,

   thread = function(write) encode_uint(write, 5 + 16*5) end,
}

local function pub_encode(write, data, without_deflist)
   -- This encoder does not do definitions.
   if not without_deflist then encode_uint(write, 0) end
   encode(write, data)
end

return pub_encode
