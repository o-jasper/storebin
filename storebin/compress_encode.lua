--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local floor, abs = math.floor, math.abs
local char = string.char

--local decode_uint = require "storebin.lib.string_decode_uint"

local encodefun = require "storebin.lib.encode"
local encodefun_uint = require "storebin.lib.encode_uint"

local function encode_uint(x)
   local ret = ""
   encodefun_uint(function(str) ret = ret .. str end, x)
   return ret
end

local function encode(data)
   local ret = ""
   encodefun(function(str) ret = ret .. str end, data)
   return ret
end

local function tick_def(self, ed)
   assert(type(ed) == "string")
   local got = self.defs[ed]
   if got then
      got[1] = got[1] + 1
   else
      got = {1, ed}
      self.defs[ed] = got
      table.insert(self.defs_ordered, got)
   end
   return got
end

-- Go through all the leaves. Firstly; all the leaves are just lua data.
local function by_leaves(self, input_data)
   if type(input_data) == "table" then
      local data = {}
      for k,v in pairs(input_data) do data[k] = v end

      -- TODO use figure_tp.. kindah tricky, because that loses usage of identified patterns..
      local ret, not_data = {nil, {}}, {}
      for i,v in ipairs(data) do
         table.insert(ret[2], by_leaves(self, v))
         not_data[i] = true
      end

      for k,v in pairs(data) do
         if not not_data[k] then
            local ed_k = encode(k)
            tick_def(self, ed_k)
            ret[ed_k] = by_leaves(self, v)
         end
      end

      for k,v in pairs(ret) do
         assert(k == 2 or type(k)=="string", string.format("%s, %s", k, v))
         assert(type(v) == "string" or type(v) == "table", string.format("%s, %s", k, v))
      end
      for _,v in ipairs(ret[2]) do
         assert(type(v) == "string" or type(v) == "table", string.format("%s, %s", k, v))
      end
      return ret
   else
      local ed = encode(input_data)
      tick_def(self, ed)
      return ed
   end
end

local function encode_use_def(n)
   return encode_uint(5 + 8 + 16*n)
end

local function apply_compressions(self, data)
   if type(data) == "table" then
      local no_tables, ret_kv, ret_list = true, {}, {}
      for i,v in ipairs(data[2]) do   -- Do list portion.
         no_tables = no_tables and type(v) ~= "table"
         table.insert(ret_list, apply_compressions(self, v))
      end
      data[2] = nil
      
      for k,v in pairs(data) do  -- Key-value portion.
         no_tables = no_tables and type(v) ~= "table"
         local def_k = self.defs[k]
         if def_k and def_k[4] then def_k[3] = true end
         
         ret_kv[def_k and def_k[4] and encode_use_def(def_k[4]) or k] =
            apply_compressions(self, v)
      end
      
      if no_tables then  -- All leaves are compressed, return result.
         local kv_list = {}
         for k,v in pairs(ret_kv) do
            assert(type(k) == "string" and type(v) == "string")
            table.insert(kv_list, {k,v})
         end
         table.sort(kv_list, function(a,b) return a[1] > b[1] end)

         local keys_ret = {}
         for _, kv in ipairs(kv_list)  do table.insert(keys_ret, kv[1]) end
         local values_ret = {}
         for _, kv in ipairs(kv_list) do table.insert(values_ret, kv[2]) end

         for _,v in pairs(ret_list) do assert(type(v) == "string") end

         -- TODO key-value portion identifying?
         local ret_str = encode_uint(6 + 8*#kv_list) .. encode_uint(#ret_list) ..
            table.concat(ret_list) .. table.concat(keys_ret) .. table.concat(values_ret)
         --tick_def(self, ret_str)
         return ret_str
      else  -- Need more steps.
         ret_kv[2] = ret_list
         return ret_kv
      end
   else
      assert(type(data) == "string")
      local def = self.defs[data]
      if def and def[4] then def[3] = true end
      return def and def[4] and encode_use_def(def[4]) or data
   end
end

local function replace_smaller(self, encode_c, remove_n)
   local i = 1
   while i <= #self.defs_ordered do
      local cur, ned = self.defs_ordered[i], encode_c(i)
      if #cur[2] > #ned + 1 then  -- Replace if shorter.(+1 to make it a bit harder)
         cur[4] = i
         i = i + 1
      elseif i > remove_n then  -- remove_n indicates which may already be d.
         assert(not cur[3])
         -- Not shorter, cut it out. (also lowers the indices on everything after.
         self.defs[cur[1]] = nil
         table.remove(self.defs_ordered, i)
      else
         i = i + 1
      end
   end
end

local function pub_encode(data)
   local self = {defs = {}, defs_ordered = {} }
   local data = by_leaves(self, data)
   -- Now data leaves are all strings encoded, defs contains counts.
   table.sort(self.defs_ordered, function(a,b) return a[1] > b[1] end)
   replace_smaller(self, encode_use_def, 0)
   local n = #self.defs_ordered

   -- Compress leaves, then when all table entries are data, compress those.
   while type(data) == "table" do
      data = apply_compressions(self, data)
      replace_smaller(self, encode_use_def, n)
      n = #self.defs_ordered
   end

   local ret_defs = {}  -- TODO stumped by magic self-inserting strings..
   for i, el in ipairs(self.defs_ordered) do
      assert(type(el[2]) == "string")
      table.insert(ret_defs, el[2])
   end
   return encode_uint(#ret_defs) .. table.concat(ret_defs) .. data, self
end

return pub_encode
