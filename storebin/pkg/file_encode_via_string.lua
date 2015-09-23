return function(encode)
   return function(file, data, may_be_nil) 
      local fd = io.open(file, "w")
      if fd then
         assert( may_be_nil or data ~= nil )  -- Otherwise confusionly returns nil.
         local str = encode(data)
         fd:write(str)
         fd:close()
         return true
      end
   end
end
