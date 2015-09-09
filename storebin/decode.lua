local decode = require "storebin.lib.decode"

local sub = string.sub

return function(str, ...)
   local function read(n)
      local ret = sub(str, 1, n)
      str = sub(str, n + 1)
      return ret
   end
   return decode(read, ...)
end
