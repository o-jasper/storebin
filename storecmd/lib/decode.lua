
local dehex = require "storecmd.lib.dehex"

local sub, find, match, char = string.sub, string.find, string.match, string.char

local function decode_1(from, readline, final)
   local function f(...) return find(from, ...) end
   local function m(...) return match(from, ...) end

   assert(not f("^[.]"))

   if f("^true[=.]") or f("^true$") then
      return true, sub(from, 5)
   elseif f("^false[=.]") or f("^false$") then
      return false, sub(from, 6)
   elseif f("^nil[=.]") or f("^nil$") then
      return nil, sub(from, 4)
   elseif f("^inf[=.]") or f("^inf") then
      return 1/0, sub(from, 4)
   elseif f("^-inf[=.]") or f("^-inf") then
      return -1/0, sub(from, 5)
   end

   local _,t = f("^tp:([%w_]+)")
   if t then  -- Dont really have a good response.
      return nil, sub(from, t + 1)
   end

   local num, rest = m(final and "^(%-?[%d]*[.]?[%d]+)" or "^%((%-?[%d]*[.]?[%d]+)%)")
   if num then
      --assert(t == #from or ({["."]=true, ["="]=true})[string.sub(from, t,t)],
      --"Looks like number but isnt")
      return tonumber(num), sub(from, #num + (final and 1 or 3))
   end
   local _, t = f("^%-?[%d]+")
   if t then
      return tonumber(sub(from, 1,t)), sub(from, t + 1)
   end

   local _,t = f("^#[%x]+") -- Hexadecimalled string.
   if t then
      return dehex(sub(from, 2, t)), sub(from, t + 1)
   end


   if f("^\"\"") then
      return "", sub(from, 3)
   elseif f("^\"") then  -- Quoted string.
      from = sub(from, 2)
      local ret = {}
      local i = f("\"") --f("[^\\]\"")
      while not i do
         table.insert(ret, from)
         from = readline()
         assert(from, string.format("Couldnt find end of string\n%s\n--%s",
                                    table.concat(ret, "\n"), from))
         --i = f("[^\\]\"") or f("^\"")
         i = f("\"")
      end
      table.insert(ret, sub(from, 1, i - 1))
      return string.gsub(table.concat(ret, "\n"), "\\\"","\""), sub(from, i + 1)
   else
      local _, t = f("^[%w_]+")
      assert(t, string.format("%q %s", from, final))
      return sub(from, 1, t), sub(from, t + 1)
   end
end

local function insert(into, path, value)
   local last = table.remove(path)  -- Note: KNOW about this!
   for _, name in ipairs(path) do
      if type(into[name]) == "table" then
         into = into[name]
      else  -- Create if not exists.
         assert(into[name] == nil)
         into[name] = {}
         into = into[name]
      end
   end
   into[last] = value
end

local function finally_value(line, readline)
   -- Fill the value, expect end of line.
   local value, rem_line = decode_1(line, readline, true)
   if string.match(rem_line, "[ \t]") then  -- List of multiple.
      local list = {value}
      while string.match(rem_line, "[ \t]") do
         value, rem_line = decode_1(line, readline, true)
         table.insert(list, value)
      end
      value = list
   end
   -- Straight value.
   assert(rem_line == "", string.format("%q\n\n%q", rem_line, line))
   return rem_line, value
end

local function decode(readline)
   local empty, ret, last = true, {}, {}
   
   local line = ""
   local function next_line()
      line = readline()
      while line == "" do line = readline() end
   end
   next_line()
   if not line then return nil end

   if sub(line, 1,1) == "=" then line = sub(line, 2) end

   if not line then return ret end
   local path = {}
   
   while true do
      if sub(line, 1,1) == "~" then
         assert(last[#path + 1] ~= nil, string.format("%s %s", #last, #path))
         table.insert(path, last[#path + 1])
         line = sub(line, 2)
      else
         local value, rem_line = decode_1(line, readline)
         table.insert(path, value)
         line = rem_line
         if sub(line, 1,1) == "=" then
            line = sub(line, 2)
            empty = false

            line, value = finally_value(line, readline)
            insert(ret, path, value)

            last = path
            path = {}

            next_line()
            if not line then return ret end
         elseif line == "" or line == "\n" then
            assert(empty, string.format("%s", table.concat(path, ".")))
            assert(#path == 1)
            return path[1]
         elseif sub(line, 1,2) == " " then
            local _, value = finally_value(value, line)
            return value
         else
            assert(sub(line, 1,1) == ".", string.format("%q", line))
            line = sub(line, 2)
         end
      end
   end
end

local function decode_str(str)
   return decode(function()
         if #str > 0 then
            local n = find(str, "\n", 1, true)
            local line = n and sub(str, 1, n - 1) or str
            str = n and sub(str, n + 1) or ""
            assert(not find(line, "\n"))
            return line
         end
   end)
end

return {decode, decode_str}
