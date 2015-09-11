--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local floor, byte, char = math.floor, string.byte, string.char

local decode_uint = require "storebin.lib.decode_uint"

local function decode_positive_float(read, top)
   local y = decode_uint(read)
   local sub = ((top%2 == 0) and 1 or -1) * floor(top/2)
   return y*2^(sub-63)
end

local function decode_bool_arr(read, cnt, ret)
   local i, data = 1, read(floor(cnt/8) + 1)
   while true do
      local b = assert(byte(data, i))
      for _ = 1,8 do
         table.insert(ret, b%2 == 1)
         b = floor(b/2)
         i = i + 1
         if i > cnt then return ret end
      end
   end
end

local decode

local function decode_list(read, cnt, meta_fun, deflist)
   local ret = {}
   for _ = 1,cnt do table.insert(ret, decode(read, meta_fun, deflist)) end
   return ret
end

local function decode_table(read, keys_cnt, meta_fun, deflist, listbool, valbool)
   local list_cnt = decode_uint(read)
   local ret = listbool and decode_bool_arr(read, list_cnt, {}) or
      decode_list(read, list_cnt, meta_fun, deflist)

   local keys   = decode_list(read, keys_cnt, meta_fun, deflist)
   local values = valbool and decode_bool_arr(read, keys_cnt, {}) or
      decode_list(read, keys_cnt, meta_fun, deflist)

   for i, k in ipairs(keys) do ret[k] = values[i] end

   return ret
end

local function copy(x)
   if type(x) == "table" then
      local ret = {}
      for k,v in pairs(x) do ret[copy(k)] = copy(v) end
      return ret
   else
      assert(type(x) ~= "function")
      return x
   end
end

decode = function(read, meta_fun, deflist)
   assert(deflist)
   local top = decode_uint(read)
   local sel, pass = top % 8, floor(top/8)
   if sel == 0 then -- String.
      return read(pass)
   elseif sel == 1 then -- Positive integer.
      return pass
   elseif sel == 2 then -- Negative integer.
      return -1 * pass
   elseif sel == 3 then
      return decode_positive_float(read, pass)
   elseif sel == 4 then -- Negative float.
      return -1 * decode_positive_float(read, pass)
   elseif sel == 5 then -- Boolean, nil, other.
      if pass%2 == 1 then  -- Read out a defintion.
         return copy(deflist[floor(pass/2)])
      else
         local sk = floor(pass/2)
         if sk == 7 then
            return decode_table(read, decode_uint(read), meta_fun, deflist, false,true)
         elseif sk == 6 then
            return decode_table(read, decode_uint(read), meta_fun, deflist, true, false)
         elseif pass == 5 then
            return decode_table(read, decode_uint(read), meta_fun, deflist, true,true)
         else
            return ({false, true, nil, 1/0, -1/0})[1 + sk]
         end
      end
   elseif sel == 6 then
      return decode_table(read, pass, meta_fun, deflist)
   elseif sel == 7 then -- Apply meta fun.
      local name = read(pass)
      local ret = decode(read, meta_fun, deflist)
      return meta_fun[key] and meta_fun[key](ret) or ret
   end
end

local function pub_decode(read, meta_fun, deflist)
   if not deflist then  -- Then we still need to read the deflist.
      deflist = {}
      local def_cnt = decode_uint(read)
      for i = 1, def_cnt do  -- Get out definitions.
         table.insert(deflist, decode(read, meta_fun or {}, deflist))
      end
   end
   return decode(read, meta_fun or {}, deflist)
end

return pub_decode
