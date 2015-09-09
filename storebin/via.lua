local function ret(enc_dec)
   local function index(self, key)
      local allowed = {
         encode=true, plain_encode=true, compress_encode=true,
         decode=true, 
         file_encode=true, file_plain_encode=true, file_compress_encode=true,
         file_decode = true,
      }
      local got
      if allowed[key] and enc_dec[key] then
         got = enc_dec[key] -- Access directly
      else  -- Add the function.
         local m = string.match(key, "^file_([%w_]+_encode)$")
         if m then
            local usefun = enc_dec[m] or enc_dec.encode
            got = function(file, ...)
               local fd = io.open(file, "w")
               if fd then
                  local read1, whole = fd:read(), {}
                  while read1 do
                     table.insert(whole, read1)
                     read1 = fd:read()
                  end
                  fd:close()
                  fd:write(usefun(table.concat(whole), ...))
                  return true
               end
            end
         elseif key == "file_decode" then
            local usefun = enc_dec.decode
            got = function(file, ...)
               local fd = io.open(file)
               if fd then
                  local ret = usefun(fd:read(), ...)
                  fd:close()
                  return ret, true
               end
            end
         else
            error(string.format("Does not exist, or not accessibly without direct `require` (%s)(%s)", key, type(key)))
         end
         rawset(self, key, got)
         return got
      end
   end
   return setmetatable({}. { __index = index })
end

return ret
