local function enhex(arr, sz)
   local ret, sz = "", sz or #arr
   for i = 1, sz do
      local el = string.byte(arr, i)
      local x, y = 1 + el%16, 1 + math.floor(el/16)
      ret = ret .. string.sub("0123456789ABCDEF", y,y) .. string.sub("0123456789ABCDEF", x,x)
   end
   return ret
end

return enhex
