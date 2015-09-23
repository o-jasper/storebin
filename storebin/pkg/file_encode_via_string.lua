return function(encode)
   return function(file, data, may_be_nil) 
      assert( may_be_nil or data ~= nil )  -- Otherwise confusionly returns nil.
      fd:write(encode(data))
      fd:close()
      return true
   end
end
