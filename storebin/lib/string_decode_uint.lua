-- NOTE: this one is basically superfluous.
-- Also, it does not advance the string.

return function(str)
   local x, f, c, i = 0, 1, 128, 1
   while c >= 128 do
      c = string.byte(str, i)
      x = x + f*(c%128)
      f = f*128
      i = i + 1
   end
   return x, i
end
