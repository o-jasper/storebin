local n = 256

return function(decode)
   return function(file) 
      local fd = io.open(file)
      if fd then
         local ret, got = "", fd:read(n)
         while #got == n do
            ret = ret .. got
            got = fd:read(n)
         end
         ret = ret .. got
         return ndecode(ret), true
      end
   end
end
