local function index(self, key)
   local allowed = {
      encode=true, plain_encode=true, compress_encode=true,
      decode=true, 
      file_encode=true, file_plain_encode=true, file_compress_encode=true,
      file_decode = true,
   }
   if allowed[key] then
      local got = require("storebin." .. key)
      -- Stumpletron 2000
      assert(type(got) ~= "string", string.format("Dont expect type %s(%s)", type(got), got))
      rawset(self, key, got)
      return got
   else
      error(string.format("Does not exist, or not accessibly without direct `require` (%s)(%s)", key, type(key)))
   end
end

return setmetatable({}, { __index = index })
