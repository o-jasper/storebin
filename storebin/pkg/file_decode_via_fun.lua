return function(decode)
   return function(file) 
      local fd = io.open(file)
      if fd then
         local ret = decode(function(n) return fd:read(n) end)
         fd:close()
         return ret, true
      end
   end
end
