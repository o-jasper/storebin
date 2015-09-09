local compress_encode = require "storebin.compress_encode"

return function(file, data, may_be_nil) 
   assert( may_be_nil or data ~= nil )  -- Otherwise confusionly returns nil.
   local fd = io.open(file, "w")
   if fd then
      local str = compress_encode(data)
      fd:write(str)
      fd:close()
      return true
   end
end
