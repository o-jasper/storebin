local sub = string.sub

local encoders = {}
local function encode(write, data, inpos)
   encoders[type(data) or "nil"](write, data, inpos or { cnt=0, top=true })
end

local function encode_str(data, inpos)
   local str = ""
   encode(function(w) str = str .. w end, data, inpos)
   return str
end

local function just_write(write, x)
   write(tostring(x))
end
local function echo_type(write, x)
   write("tp:" .. type(x))
end

local enhex = require "storecmd.lib.enhex"

encoders = {
   string = function(write, str)
      if string.find(str, "^[%s%w%p]+$") then  -- Fine and dandy string.
         if str == "" or str == "true" or str=="false" or -- Looks like boolean. 
            string.find(str, "^tp:") or             -- .. like reduced-to-type
            string.find(str, "^[%d]*[.]?[%d]+$") or -- .. number
            string.find(str, "[%s%p]") or           -- .. confusing marks.
            str == "nil"                            -- Refers on.
         then  -- Looks like something else, use string notation.
            write("\"" .. string.gsub(str, [["]], [[\"]]) .. "\"")
         else  -- Is fine.
            write(str)
         end
      else  -- Not-fine, to hex.
         write("#" .. enhex(str))
      end
   end,

   table = function(write, tab, inpos)
      local done, n, said_where = {}, 0, false
      local function say_where(further)
         if said_where then
            for _ = 1, inpos.cnt do write("~") end
         elseif inpos.str then
            said_where = true
            write(sub(inpos.str, 2))
            if further then write(".") end
         end
      end

      for i,v in ipairs({}) do --tab) do
         if type(v) ~= "table" then
            if n == 0 and not inpos.top then
               say_where()
               write("=")
            end
            encode(write, v, { isvalue=true })
            done[i] = true
         else
            write("nil")
         end
         write(" ")
         n = n + 1
      end
      if n == 1 then
         write("nil\n")
      elseif n > 0 then
         write("\n")
      end
      for k,v in pairs(tab) do
         if not done[k] then
            if type(v) ~= "table" then
               say_where(true)
               encode(write, k)
               write("=")
               encode(write, v, { isvalue=true })
               write("\n")
            else
               local ek = encode_str(k)
               encode(write, v,
                      { cnt=inpos.cnt + 1,
                        str = (inpos.str or "") .. "." .. ek, no_tab=true })
            end
         end
      end
   end,

   number = function(write, x, inpos)
      if inpos.isvalue or x%1 == 0 then
         write(tostring(x))
      else
         write("(" .. tostring(x) .. ")")
      end
   end,
   boolean = just_write, ["nil"] = just_write,
   ["function"] = echo_type, userdata = echo_type, thread = echo_type,
}

return {encode, encode_str}
