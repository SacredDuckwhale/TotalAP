----------------------------------------------------------------------------------------------------------------------
    -- This program is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.
	
    -- This program is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU General Public License for more details.

    -- You should have received a copy of the GNU General Public License
    -- along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------------------------------------------

local addonName, T = ...


-- Compares two tables, and replaces mismatching entries in t2 with those from t1 (with t2 and t2 being used recursively, while targetTable remains the original table reference)
-- targetTable will have mismatching entries replaced by those from t1[lastTableKey]
-- TODO: Well, this is kind of confusing, isn't it? I'm sure it could be optimised somewhat, if only for readability
local function CompareTables(t1, t2, targetTable, lastTableKey)
   
   if not lastTableKey then lastTableKey = "<none>" end
   
   if type(t1) == "table" and type(t2) == "table" then
      for k, v in pairs(t1) do
    --     print("checking key, value pair:")
      --   print(k, v)
         if type(v) == "table" then
            -- lastTableKey = k
            CompareTables(v, t2[k], targetTable, k)
         else
        --    print("comparing values:")
        --    print(v, t2[k])
            if type(v) == type(t2[k]) then
           --    print("v eq t2[k]")
            else
           --    print("v not eq t2[k]")
               t2[k] = v
            end
         end
         
      end
      
   else
 --     print("comparing values:")
   --   print(t1, t2)
      if type(t1) == type(t2) then
     --    print("t1 eq t2")
      else
      --   print("t1 not eq t2")
     --    print("lastTableKey: " ..lastTableKey)
         targetTable[lastTableKey] = t1
      end
      
   end
   
end


if not T then return end
T.Utils.CompareTables = CompareTables

return CompareTables