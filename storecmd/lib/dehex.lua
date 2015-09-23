
local sub, find, char = string.sub, string.find, string.char

local function dehex(hex)
   local ret = ""
   for i = 1, #hex, 2 do
      local a, b = sub(hex, i,i), sub(hex, i+1,i+1)
      local code = find("0123456789ABCDEF", a) - 1 + 16*(find("0123456789ABCDEF", b) - 1)
      ret = ret .. char(code)
   end
   return ret
end

return dehex
