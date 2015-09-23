
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
      -- NOTE: bit pita function.
      local function find_i()
         local j = f("\"")
         while j do
            local init_j = j
            local nope
            assert(sub(from, j,j) =="\"")
            while not nope do
               -- Escaped and exscaper not escaped.
               if sub(from, j-1, j-1) == "\\" then
                  nope = (sub(from, j-2, j-2) ~= "\\")
               else
                  return init_j
               end
               j = j - 2
            end
            j = f("\"", init_j + 1)
         end
      end
      local i = find_i()
      while not i do
         table.insert(ret, from)
         from = readline()
         assert(from, string.format("Couldnt find end of string\n%s\n--%s",
                                    table.concat(ret, "\n"), from))
         i = find_i()
      end
      table.insert(ret, sub(from, 1, i - 1))
      local str = table.concat(ret, "\n")
      local str = string.gsub(string.gsub(str, "\\\"","\""), "\\\\", "\\")
      return str, sub(from, i + 1)
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
   assert(rem_line == "", string.format("%q\n\n%q\n\n%s", rem_line, line, value))
   return rem_line, value
end

local function decode(readline, how, ret)
   local empty, last = true, {}
   ret = ret or {}
   
   local line = ""
   local function next_line()
      line = readline()
      while line == "" do line = readline() end
   end
   next_line()
   if not line then return nil end

   local path = {}
   local permissive = how
   
   local function next_n(name)
      return find(line, permissive and ("^[%s]*" .. name .. "[%s]*") or ("^" .. name))
   end
   while true do
      local n = next_n("~")
      if n then
         assert(last[#path + 1] ~= nil, string.format("%s %s", #last, #path))
         table.insert(path, last[#path + 1])
         line = sub(line, n + 1)
      else
         local value, rem_line = decode_1(line, readline)
         table.insert(path, value)
         line = rem_line
         local n = next_n("=")
         if n then
            line = sub(line, n + 1)
            empty = false

            line, value = finally_value(line, readline)
            insert(ret, path, value)

            last = path
            path = {}

            next_line()
            if not line then return ret end
         elseif find(line, "^[%s]+") then
            assert(empty)
            local _, value = finally_value(value, line)
            return value
         elseif line == "" then
            assert(empty, string.format("%s", table.concat(path, ".")))
            assert(#path == 1)
            return path[1]
         else
            local n = next_n(".")
            assert(n, string.format("%q", line))
            line = sub(line, n + 1)
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
