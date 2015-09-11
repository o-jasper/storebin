local encode_bool_arr = require "storebin.lib.encode_bool_arr"
local encode_list_plain = require "storebin.lib.encode_list_plain"
local encode_uint = require "storebin.lib.encode_uint"

local abs = math.abs

local function encode_list(write, tp, list)
   if tp == 0 then
      encode_list_plain(write, list)
   elseif tp == 5 then
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
            error("BUG bool-lists should be done separately.")
         elseif tp == 6 then  -- TODO really it does fairly little for strings.
            assert(type(el) == "string", tostring(el))
            encode_uint(write, #el)
            write(el)
         else
            error("BUG %d?", tp)
         end
      end
   end
end

return encode_list
