local encode = require "storebin.lib.encode"

return function(data, may_be_nil) 
   assert( may_be_nil or data ~= nil )  -- Otherwise confusionly returns nil.
   local ret = ""
   encode(function(str) ret = ret .. str end, data)
   return ret
end
