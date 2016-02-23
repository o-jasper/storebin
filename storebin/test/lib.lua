local function assert_eq(a, b, k, nameit, not_top)
   assert(not not_top or k ~= nil)
   if type(a) ~= type(b) then
      error(string.format("(%s;%s)%s ~= %s, (%s %s)%s",
                          k,type(k), a,b, type(a), type(b), nameit))
   end
   if type(a) == "table" then
      for k,v in pairs(a) do
         assert(k ~= nil)
         assert_eq(v, b[k], k, nameit, true)
      end
   else
      assert(a == b, string.format("%s ~= %s%s", a,b, nameit))
   end
end

local rand = math.random

local function rand_nice_str(stat)
   local choose = "abcdefghijklmnopqrstuvwxyz_01234567890"
   local i = rand(27)
   local x = string.sub(choose, i,i)
   for _ = 1,rand(stat.strl or 10) do
      local i = rand(#choose)
      x = x .. string.sub(choose, i,i)
   end
   return x
end

local function rand_str(stat)
   if stat.nice then return rand_nice_str(stat) end
   local x = ""
   for _ = 1,rand(stat.strl or 10) do x = x .. string.char(rand(256)-1) end
   return x
end

local long_repeat

local function randval(stat)
   local r = rand(7) - 1
   if r == 0 then
      x = rand(stat.min or -10.0, stat.max or 10.0)
   elseif r == 1 or r == 2 then
      x = rand(stat.mini or -256, stat.maxi or 267)
   elseif r == 3 then
      x = rand_str(stat)
   elseif r == 4 then
      x = nil
   elseif r == 5 then  -- set of long repeated things.
      if not long_repeat then
         long_repeat = {}
         for _ = 1, (stat.repeat_cnt or 4) do table.insert(long_repeat, rand_str(stat)) end
      end
      x = long_repeat[rand(#long_repeat)]
   else
      local r = rand(4)
      x = (r==1 and 1/0) or (r==2 and -1/0) or r==3
      if type(x) == "boolean" and stat.no_boolean then x= "no boolean" end
   end
   return x
end

local function gen_tree(top, d, stat)
   stat = stat or {}
   top = (top == nil) or top
   local ret, n = {}, 0
   for _ = 1, top and l or (rand(stat.l or 6) - 1) do
      local x
      if not d or d > 0 and rand() < (stat.p or 0.4) then
         local m
         x, m = gen_tree(false, (d  or 6) - 1, stat)
         n = n + m
      elseif rand() < (stat.p_unif or 0.2) then  -- Generate some uniform stuff.
         local r = rand(6)
         x = {}
         for _ = 1,rand(stat.l or 6) do
            local y
            if r == 1 then  -- Positive integers.
               y = rand(stat.maxui or 1000)
            elseif r == 2 then  -- neg..
               y = -rand(stat.maxui or 1000)
            elseif r == 3 then  -- both..
               y = rand(stat.mini or -256, stat.maxi or 267)
            elseif r == 4 then -- Floats
               y = rand(stat.min or -10.0, stat.max or 10.0)
            elseif r == 5 then -- Booleans
               if stat.no_boolean then
                  y = math.random()
               else
                  y = (rand(2) == 1)
               end
            elseif r == 6 then
               y = rand_str(stat)
            end
            table.insert(x, y)
         end
      else
         x = randval(stat)
         n = n + 1
      end  -- TODO
      if rand() < (stat.pk or 0.5) then
         local k = stat.string_key and rand_str(stat) or randval(stat)
         ret[k == nil and "stumpening" or k] = x
      else
         table.insert(ret, x)
      end
   end
   return ret, n
end

return { assert_eq, gen_tree }
