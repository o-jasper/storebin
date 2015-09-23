return function(name)
   local sb = require(name)

   assert( sb.encode == require(name .. ".encode") )
   assert( sb.decode == require(name .. ".decode") )

   assert( sb.file_encode == require(name .. ".file_encode") )
   assert( sb.file_decode == require(name .. ".file_decode") )
end
