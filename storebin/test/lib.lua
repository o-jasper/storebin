local function assert_eq(a, b, k, nameit)
   assert(type(a) == type(b),
          string.format("(%s;%s)%s ~= %s, (%s %s)%s",
                        k,type(k), a,b, type(a), type(b), nameit))
   if type(a) == "table" then
      for k,v in pairs(a) do
         assert_eq(v, b[k], k, nameit)
      end
   else
      assert(a == b, string.format("%s ~= %s%s", a,b, nameit))
   end
end

local rand = math.random

local function randval(stat)
   local r = rand(6) - 1
   if r == 0 then
      x = rand(stat.min or -10.0, stat.max or 10.0)
   elseif r == 1 or r == 2 then
      x = rand(stat.mini or -256, stat.maxi or 267)
   elseif r == 3 then
      x = ""
      for _ = 1,rand(stat.strl or 10) do x = x .. string.char(rand(256)-1) end
   elseif r == 4 then
      x = nil
   else
      local r = rand(4)
      x = (r==1 and 1/0) or (r==2 and -1/0) or r==3
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
               y = (rand(2) == 1)
            elseif r == 6 then
               y = ""
               for _ = 1,rand(stat.strl or 10) do y = y .. string.char(rand(256)-1) end
            end
            table.insert(x, y)
         end
      else
         x = randval(stat)
         n = n + 1
      end
      if rand() < (stat.pk or 0.5) then
         local k = randval(stat)
         ret[k == nil and "stumpening" or k] = x
      else
         table.insert(ret, x)
      end
   end
   return ret, n
end

return { assert_eq, gen_tree }
