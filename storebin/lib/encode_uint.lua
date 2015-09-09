--  Copyright (C) 09-09-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local char, floor = string.char, math.floor

return function(write, x)
   while x >= 128 do
      write(char(x%128 + 128))
      x = floor(x/128)
   end
   write(char(x))
end
