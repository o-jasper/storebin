local encode

local function encode_list_plain(write, list)
   encode = encode or require "storebin.lib.encode"
   for _, el in ipairs(list) do encode(write, el) end
end

return encode_list_plain
