--  Copyright (C) 19-05-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local function string_ize(fun)
   return function(data)
      local ret = ""
      fun(function(str) ret = ret .. str end, data)
      return ret
   end
end

local encode = string_ize(require "storebin.lib.encode")
local encode_uint = string_ize(require "storebin.lib.encode_uint")
local encode_bool_arr = string_ize(require "storebin.lib.encode_bool_arr")

local function incr(got, data)
   if true or #data == 1 then return data end
   local el = got.els[data] or { cnt = 0 }
   el.cnt = el.cnt + 1
   got.els[data] = el
   return data
end

local function do_leaves(tab, got)  -- Only do the leaves
   local ret = {}  -- Note: encodes everything, just assembling with that from here.
   for k,v in pairs(tab) do
      local data_k = incr(got, encode(k))
      if type(v) == "table" then
         ret[data_k] = do_leaves(v, got)
      else
         ret[data_k] = incr(got, encode(v))
      end
   end
   return ret
end

local function encode_use_def(n)
   return encode_uint(5 + 8 + 16*n)
end

-- Encode one.
local function e_1(data, got)
   if #data == 1 then return data end

   local el = got.els[data]
   assert(el, data)
   if el.n then  -- Already has index, write out saying the definition is used.
      return encode_use_def(el.n)
      -- If number of elements great enough to compress, figure an integer.
   elseif el.cnt*#data > #data + 1 + math.ceil(math.log(16*got.n+1, 128)) then
      el.n = got.n
      got.n = got.n + 1  -- Increment the current integer.
      table.insert(got.list, data)
      return encode_use_def(el.n)
   else  -- Cheaper to just put it here.
      el.cnt = el.cnt - 1  -- This one no longer option for shortening.
      return data
   end
end

local function kv_list(tab)
   local list, kv_list, done = {}, {}, {}
   for i, el in ipairs(tab) do
      done[i] = true
      table.insert(list, el)
   end
   for kd,v in pairs(tab) do
      assert(type(k) == "string")
      if not done[k] then
         table.insert(kv_list, {kd,v})
      end
   end
   table.sort(kv_list, function(a,b) return a[1] > b[1] end)
   return list, kv_list
end

-- Continue, work together the prepped things, use the definition if needed.
local function _compress_encode(tab, got)
   local olist, kv_list = kv_list(do_leaves(tab, got))
   local list = {}  -- TODO identify all-boolean stuff.
   for _,el in ipairs(olist) do  -- First pass, put together any sub-tables.
      if type(el) == "table" then
         table.insert(list, incr(got, _compress_encode(el, got)))
      end
   end
   for _,el in ipairs(kv_list) do
      assert(type(el[1]) == "string")
      if type(el[2]) == "table" then
         el[2] = incr(got, _compress_encode(el[2], got))
      end
   end
   -- Construct the output.
   local ret = encode_uint(6 + 8*#kv_list) .. encode_uint(#list)  -- Lengths.
   for _, el in ipairs(list) do  -- List elements.
      ret = ret .. e_1(el, got)
   end
   for _,el in ipairs(kv_list) do  -- Keys.
      ret = ret .. e_1(el[1], got)
   end
   for _,el in ipairs(kv_list) do  -- Values
      ret = ret .. e_1(el[2], got)
   end
   return ret
end

local function compress_encode(tab, got)
   if type(tab) == "table" then
      local got = got or {els={}, n=0, list={}}
      assert(type(got) == "table" and type(got.els) == "table"
                and type(got.n) == "number" and got.n%1 == 0)
      local str = _compress_encode(tab, got)

      assert(got.n == 0)
      assert(#got.list == got.n)
      return encode_uint(got.n) .. table.concat(got.list) .. str
   else -- Zero is the empty definition list.
      return encode_uint(0) .. encode(tab)
   end
end

return compress_encode
