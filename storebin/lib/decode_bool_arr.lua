local floor, byte = math.floor, string.byte

local function decode_bool_arr(read, cnt, ret)
   local i, data = 1, read(floor(cnt/8) + 1)
   while true do
      local b = byte(data, floor(i/8) + 1)
      for _ = 1,8 do
         table.insert(ret, b%2 == 1)
         b = floor(b/2)
         i = i + 1
         if i > cnt then return ret end
      end
   end
end

return decode_bool_arr
