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


---	Consists of various utilities that make working with things easier across all other modules
-- @module Utils

--- Format.lua.
-- Utilities for number formatting and parsing
-- @section Format


local addonName, T = ...


 --- Format number as short textual representation
 -- Adheres to international standards for orders of magnitude ('k' for thousands, 'm' for millions, etc.)
 -- @param value The number (value) to be formatted
 -- @param[opt] format Whether or not the formatting should be applied directly. Will return the original value alongside a format string that can be used with string.format(...) otherwise
 -- @return The formatted output if the 'format' parameter was given; a format string otherwise
 -- @return[opt] The number this formatted string can be applied to in order to obtain the same textual representation; nil if the 'format' parameter wasn't given
 -- @usage FormatShort(15365, true) -> "15.3k"
 -- @usage FormatShort(15365) -> { "%.1fk", 15.365 }
 local function FormatShort(value,format) 
 
	if type(value) == "number" then
	
		local fmt
		if value >= 1000000000 or value <= -1000000000 then
			fmt = "%.1fb"
			value = value / 1000000000
		elseif value >= 10000000 or value <= -10000000 then
			fmt = "%.1fm"
			value = value / 1000000
		elseif value >= 1000000 or value <= -1000000 then
			fmt = "%.2fm"
			value = value / 1000000
		elseif value >= 100000 or value <= -100000 then
			fmt = "%.0fk"
			value = value / 1000
		elseif value >= 10000 or value <= -10000 then
			fmt = "%.1fk"
			value = value / 1000
		else
			fmt = "%d"
			value = math.floor(value + 0.5)
		end
		
		if format then
			fmt = fmt:format(value)
			
			local r, f, u = fmt:match("^(%d+)%.([1-9]?)0+([k|m|b])") -- to remove trailing 0 (e.g., 4.00 m => 4m, 13.0k => 13k
         
			if r and u then
				if f and tonumber(f) then
					return r .. "." .. f .. u
				end
            return r .. u
         end
			return fmt	
		end
		
		return fmt, value
		
	else -- Only numbers are supported
		return	
	end
	
end


if not T then return end
T.Utils.FormatShort = FormatShort

return FormatShort