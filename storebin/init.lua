return {  -- Note have policy of explicit `require`s now..
   __constant = true,
   encode = require "storebin.encode",
   plain_encode = require "storebin.plain_encode"
   compress_encode = require "storebin.compress_encode"
   file_encode = require "storebin.file_encode"
   file_plain_encode = require "storebin.file_plain_encode"
   file_compress_encode = require "storebin.file_compress_encode"
   file_decode = require "storebin.file_decode"
}
