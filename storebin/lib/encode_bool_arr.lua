local char = string.char

local function encode_bool_arr(write, list)
   assert(type(list[1]) == "boolean")
   local x, f = list[1] and 1 or 0, 2
   for i = 2, #list do
      if (i-1)%8 == 0 then
         write(char(x))
         x, f = 0, 1
      end
      if list[i] then
         x = x + f
      end
      f = 2*f
   end
   write(char(x))
end

return encode_bool_arr
