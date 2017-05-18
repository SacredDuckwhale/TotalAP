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

-- Init.lua
-- Build table structure for modules to rely on no matter when they are loaded or used
-- Build table structure for modules to rely on

local addonName, T = ...

if not T then return end


-- TODO: DB\Init -> rename from global var TotalArtifactPowerDB and put this here (right now, both parts are separate but they could easily be combined)

T.version = GetAddOnMetadata("TotalAP", "Version")

-- Core modules
T.ArtifactInterface = {}
T.Scanner = {}
T.DBHandler = {} 

-- Controllers & Input handling
T.Controllers = {}

-- User Interface & Views
T.GUI = {}
T.GUI.frameCounter = 0 -- Used for automatically naming new frames if no specific name was provided, i.e., TotalAPAnonymousFrame<No> -> TotalAPAnonymousFrame1 (avoiding name clashes)

-- Utility and helper functions
T.Utils = {}


-- Global functions (TODO: Move to separate file if there will be more?)
-- TODO: Custom colour codes (in Utils) -> not added yet
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


T.Debug = Debug
T.ChatMsg = ChatMsg

return T