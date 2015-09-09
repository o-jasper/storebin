local byte = string.byte

return function(read)
   local x, f, c = 0, 1, 128
   while c >= 128 do
      c = byte(read(1))
      x = x + f*(c%128)
      f = f*128
   end
   return x
end
