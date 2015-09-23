return setmetatable({}, { __index = require("storebin.pkg.gen_init")("storejson") })
