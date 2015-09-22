
local sub = string.sub

local function decode_1(from, readline, final)
   local function f(...) return string.find(from, ...) end

   if f("^true[=.]") or f("^true$") then
      return true, sub(from, 5)
   elseif f("^false[=.]") or f("^false$") then
      return false, sub(from, 6)
   elseif f("^nil[=.]") or f("^nil$") then
      return nil, sub(from, 4)
   end

   local _,t = f("^tp:([%w_]+)")
   if t then  -- Dont really have a good response.
      return nil, sub(from, t)
   end

   local _,t = f(final and "^[%d]*[.]?[%d]+" or "^%([%d]*[.]?[%d]+%)")
   if not t then
      _, t = f("^[%d]+")
   end
   if t then
      --assert(t == #from or ({["."]=true, ["="]=true})[string.sub(from, t,t)],
      --"Looks like number but isnt")
      return tonumber(sub(from, 1,t)), sub(from, t + 1)
   end

   if f("^\"") then  -- Quoted string.
      if sub(from, 1,3) == "\"\"" then
         return "", sub(from, 3)
      else
         from = sub(from, 2)
         local ret = {}
         local i = f("[^\\]\"")
         while not i do
            table.insert(ret, from)
            from = readline()
            assert(from, "Couldnt find end of string")
            i = f("[^\\]\"")
         end
         table.insert(ret, sub(from, 1, i))
         return table.concat(ret, "\n"), sub(from, i + 2)
      end
   else
      local _, t = f("^[%w_]+")
      assert(t, from)
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
   local value, rem_line = decode_1(line, readline)
   if string.match(rem_line, "[ \t]") then  -- List of multiple.
      local list = {value}
      while string.match(rem_line, "[ \t]") do
         value, rem_line = decode_1(line, readline, true)
         table.insert(list, value)
      end
      assert(rem_line == "")
      value = list
   else  -- Straight value.
      assert(rem_line == "")
   end
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
            assert(empty)
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
            local n = string.find(str, "\n", 1, true)
            local line = n and sub(str, 1, n - 1) or str
            str = n and sub(str, n + 1) or ""
            assert(not string.find(line, "\n"))
            return line
         end
   end)
end

return {decode, decode_str}
