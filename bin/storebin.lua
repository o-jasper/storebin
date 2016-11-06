#!/usr/bin/lua

-- Encodes and prints stdout storebin-encoded files

local function p(x, prep)
   if type(x) == "table" then
      for k,v in pairs(x) do
         p(v, prep .. "/" .. k)
      end
   else         
      print(prep .. ":" .. type(x) .. ": " .. tostring(x))
   end
end

local storebin = require "storebin"

if ({d=true, decode=true})[arg[1]] then
   for i = 2, #arg do
      p(storebin.file_decode(arg[i]), "")
   end
   if #arg == 1 then
      p(storebin.file_decode("/dev/stdin"), "")
   end
elseif ({e=true, encode=true})[arg[1]] then
   for i = 2, #arg do
      io.write(storebin.file_encode(arg[i]), "")
   end
elseif ({el=true, encode_lua=true})[arg[1]] then
   for i = 2, #arg do
      local got = loadstring("return " .. arg[i], nil, nil, {})()
      io.write(storebin.encode(got))
   end
end
