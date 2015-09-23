local sub, find = string.sub, string.find

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
      local function f(...) return find(str, ...) end
      if str == "" then
         write("\"\"")
      elseif f("^[%s%w%p]+$") then     -- Fine and dandy string.
         if str == "true" or str=="false" or          -- Looks like boolean.
            f("^tp:") or               -- .. like reduced-to-type
            f("^[%d]*[.]?[%d]+$") or   -- .. number
            f("[%s%p]") or             -- .. confusing marks.
            str == "nil" or not f("^[%a]")  -- Refers on.
         then  -- Looks like something else, use string notation.
            write("\"")
            write(string.gsub(string.gsub(str, "\\", "\\\\"), "\"", "\\\""))
            write("\"")
         else  -- Is fine.
            assert(#str > 0)
            write(str)
         end
      else  -- Not-fine, to hex.
         write("#" .. enhex(str))
      end
   end,

   table = function(write, tab, inpos)
      local said_where = false
      local function say_where(further)
         said_where = false  -- TODO override
         if said_where then  -- TODO can be more greedy than this..
            for _ = 1, inpos.cnt do write("~") end
         elseif inpos.str then
            said_where = true
            write(sub(inpos.str, 2))
            if further then write(".") end
         end
      end

      local n, m, done = 0, 0, {}
      for i,v in ipairs(tab) do
         if type(v) ~= "table" then
            m = m + 1
         end
         n = n + 1
      end
      if m > n/2 then
         for i,v in ipairs(tab) do
            if n == 0 and not inpos.top then
               say_where()
               write("=")
            end
            if type(v) ~= "table" then
               encode(write, v, { isvalue=true })
               done[i] = true
            else
               write("nil")
            end
            write(" ")
         end
      else
         n = 0
      end
      if n == 1 then
         write("nil\n")
      elseif n > 0 then
         write("\n")
      end
      local m = 0
      for k,v in pairs(tab) do
         if not done[k] then
            m = m + 1
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
                        str = (inpos.str or "") .. "." .. ek })
            end
         end
      end
      if m + n == 0 then  -- Completely empty.. Set something nil to indicate existence.
         say_where(true)
         encode(write, "e")
         write("=")
         encode(write, nil, { isvalue=true })
         write("\n")
      end
   end,

   number = function(write, x, inpos)
      if x == 1/0 then
         write("inf")
      elseif x == -1/0 or (x~=0 and 2*x == x) or x ~= x then
         write("-inf")
      elseif inpos.isvalue or x%1 == 0 then
         write(tostring(x))
      else
         write("(" .. tostring(x) .. ")")
      end
   end,
   boolean = just_write, ["nil"] = just_write,
   ["function"] = echo_type, userdata = echo_type, thread = echo_type,
}

return {encode, encode_str}
