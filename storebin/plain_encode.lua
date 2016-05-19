local encode = require "storebin.lib.encode"
local encode_uint = require "storebin.lib.encode_uint"

return function(data, may_be_nil) 
   assert( may_be_nil or data ~= nil )  -- Otherwise confusionly returns nil.
   local ret = ""
   local function write(str) ret = ret .. str end
   encode_uint(write, 0)  -- No definitions.
   encode(write, data)
   return ret
end
