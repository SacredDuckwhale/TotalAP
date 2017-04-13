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


--	[[ ChatMsg.lua ]]
--	Output formatting for chat messages 


local addonName, T = ...


-- Print debug messages (if enabled)
local function Debug(msg)
	if TotalArtifactPowerSettings.debugMode then
		print(format("|c000072CA" .. "%s-Debug: " .. "|c00E6CC80%s", addonName, msg)); 
	end
end

	
-- Print regular addon messages (if enabled)
local function ChatMsg(msg)
	if TotalArtifactPowerSettings.verbose then
		print(format("|c00CC5500" .. "%s: " .. "|c00E6CC80%s", addonName, msg)); 
	end
end


if not T then return end

T.Debug = Debug
T.ChatMsg = ChatMsg

local R = {
	Debug,
	ChatMsg
}

return R