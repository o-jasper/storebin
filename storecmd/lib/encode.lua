local encoders = {}

local function encode(write, data, inpos)
   encoders[type(data) or "nil"](write, data, inpos or { cnt=0 })
end

local function encode_str(data, inpos)
   local str = ""
   encode(function(w) str = str .. w end, data, inpos)
   return str
end

local function just_write(write, x, inpos)
   if inpos.last then write(inpos.last .. "=") end
   write(tostring(x))
end
local function echo_type(write, x, inpos)
   if inpos.last then write(inpos.last .. "=") end
   write("tp:" .. type(x))
end

local enhex = require "storecmd.lib.enhex"

encoders = {
   string = function(write, str, inpos)
      if inpos.last then write(inpos.last .. "=") end
      if string.find(str, "^[%s%w%p]+$") then  -- Fine and dandy string.
         if str == "true" or str=="false" or        -- Looks like boolean. 
            string.find(str, "^tp:") or             -- .. like reduced-to-type
            string.find(str, "^[%d]*[.]?[%d]+$") or -- .. number
            string.find(str, "[%s%p]") or           -- .. confusing marks.
            str == "<below>" or str == "<list>"     -- Refers on.
         then  -- Then use the string notation.
            write("\"" .. string.gsub(str, "\"", "'") .. "\"")
         else
            write(str)
         end
      else  -- Not-fine, to hex.
         write("#" .. enhex(str))
      end
   end,

   table = function(write, tab, inpos)
      local done, n, said_where = {}, 0, false
      local function say_where()
         if said_where then
            for _ = 1, inpos.cnt do write("~") end
         elseif inpos.str then
            said_where = true
            write(string.sub(inpos.str, 2))
         end
      end

      for i,v in ipairs(tab) do
         if type(v) ~= "table" then
            if n == 0 then
               say_where()
               write("=")
            end
            encode(write, v)
            done[i] = true
         else
            write("<below>")
         end
         write(" ")
         n = n + 1
      end
      if n == 1 then write("<list>\n")
      elseif n > 0 then write("\n") end
      for k,v in pairs(tab) do
         if not done[k] then
            if type(v) ~= "table" then
               say_where()
               write(".")
            end
            local ek = encode_str(k)
            encode(write, v,
                   { cnt=inpos.cnt + 1, last=ek, 
                     str = (inpos.str or "") .. "." .. ek, no_tab=true })
            if type(v) ~= "table" then
               write("\n")
            end
         end
      end
   end,

   number = just_write, boolean = just_write, ["nil"] = just_write,
   ["function"] = echo_type, userdata = echo_type, thread = echo_type,
}

return {encode, encode_str}
