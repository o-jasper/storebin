local char = string.char

local function figure_tp_list(list)
   -- Figure if list has simple single type.
   -- 0         per-item-type.
   -- 1, 2, 3   pos, neg, both, integers
   -- 4         floats (both positive and negative)
   -- 5         booleans
   -- 6         string
   local inttp = {[1]=true, [2]=true, [3]=true}

   local tp = nil
   for _, el in ipairs(list) do
      if type(el) == "number" then
         if el == 1/0 or el == -1/0 or (el~=0 and 2*el == el) or el ~= el then
            return 0 -- Dont do these.
         elseif el == 0 then
            tp = tp or 1  -- Any integer or float type will do.
            if not (inttp[tp] or tp ==4) then return 0 end
         elseif el % 1 == 0 then  -- Positive integer.
            local h = (el >= 0) and 1 or 2
            tp = tp or h
            if not inttp[tp] then  -- Non integers, ditch.
               return 0
            elseif tp ~= h then  -- Also seen other sign.
               tp = 3
            end
         else  -- Float.
            tp = tp or 4
            if tp ~= 4 then return 0 end  -- Float or ditch.
         end
      else
         local h = ({boolean=5, string=6})[type(el) or 0] or 0
         if h == 0 then return 0 end
         tp = tp or h
         if tp ~= h then return 0 end
      end
   end
   if tp == 6 then
      -- Find a non-occuring character..
      local have, n = {}, 0
      for _, el in ipairs(list) do
         n = n + (#el > 15 and 1 or 0)  -- These take two bytes.
         for i = 1,#el do have[string.sub(el, i,i)] = true end
      end
      local i = 0
      while have[char(i)] and i <256 do i = i + 1 end
      if i < 256 then
         return 6 + 8*i
      else
         return 0
      end
   end
   return tp or 0
end

return figure_tp_list
