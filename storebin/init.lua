local Public = { __constant = true }

for k in pairs{encode=true, plain_encode=true, compress_encode=true,
               decode=true,
               file_encode=true, file_plain_encode=true, file_compress_encode=true,
               file_decode = true } do
   Public[k] = require("storebin." .. k)
end

return Public
-- setmetatable({}, { __index = require("storebin.pkg.gen_init")("storebin") })
