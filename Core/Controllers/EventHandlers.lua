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

--- Designed to handle interaction with the player, react to their input, and adjust program behaviour accordingly
-- @module Controllers

--- EventHandlers.lua.
-- Provides a simple interface to toggle specific categories of event triggers and react to them according to the addon's needs. Only events that are caused by some player action are covered here.
-- @section GUI


local addonName, TotalAP = ...
if not TotalAP then return end


-- Actual event handlers

local function UpdateGUI()

	TotalAP.ChatMsg("UpdateGUI triggered")

end

local function OnArtifactUpdate()
	TotalAP.ChatMsg("OnArtifactUpdate triggered")
end

-- Re-scan the contents of the player's inventory
local function OnInventoryUpdate()

	TotalAP.ChatMsg("OnInventoryUpdate triggered")

end

-- Re-cache contents of the player's bank
local function OnBankOpened()

	TotalAP.ChatMsg("OnBankOpened triggered")

end

local function OnEnterCombat()

	TotalAP.ChatMsg("OnEnterCombat triggered")

end

local function OnLeaveCombat()

	TotalAP.ChatMsg("OnLeaveCombat triggered")

end

local function OnPetBattleStart()
	TotalAP.ChatMsg("OnPetBattleStart triggered")
end

local function OnPetBattleEnd()
	TotalAP.ChatMsg("OnPetBattleEnd triggered")
end

local function OnUnitVehicleEnter(...)

	local args = { ... }
	local unit = args[3]
	
	TotalAP.ChatMsg("OnUnitVehicleEnter triggered")
	TotalAP.ChatMsg("unit = " .. unit)
	
end

local function OnUnitVehicleExit(...)

	local args = { ... }
	local unit = args[3]
	
	TotalAP.ChatMsg("OnUnitVehicleExit triggered")
	TotalAP.ChatMsg("unit = " .. unit)
	
end

-- List of event listeners that the addon uses and their respective handler functions
local eventList = {

	-- Re-scan and update GUI
	["ARTIFACT_XP"] = OnArtifactUpdate,
	["ARTIFACT_UPDATE"] = OnArtifactUpdate,
	["BAG_UPDATE_DELAYED"] = OnInventoryUpdate,
	
	-- Scan bank contents
	["BANKFRAME_OPENED"] = OnBankOpened,
	
	-- Toggle GUI and start/stop scanning or updating
	["PLAYER_REGEN_DISABLED"] = OnEnterCombat,
	["PLAYER_REGEN_ENABLED"] = OnLeaveCombat,
	["PET_BATTLE_OPENING_START"] = OnPetBattleStart,
	["PET_BATTLE_CLOSE"] = OnPetBattleEnd,
	["UNIT_ENTERED_VEHICLE"] = OnUnitVehicleEnter,
	["UNIT_EXITED_VEHICLE"] = OnUnitVehicleExit,
	
}

-- Register listeners for all relevant events
local function RegisterAllEvents()
	
	for key, eventHandler in pairs(eventList) do -- Register this handler for the respective event (via AceEvent-3.0)
	
		TotalAP.Addon:RegisterEvent(key, eventHandler)
		TotalAP.ChatMsg("Registered for event = " .. key)
	
	end
	
end

-- Unregister listeners for all relevant events
local function UnregisterAllEvents()
end

-- Unregister listeners for all combat-related events (they stop the addon from updating to prevent taint issues)
local function UnregisterCombatEvents()
end

-- Unregister listeners for all update-relevant events (GUI need to be updated)
local function UnregisterUpdateEvents()
end

-- Make functions available in the addon namespace
TotalAP.EventHandlers.UnregisterAllEvents = UnregisterAllEvents
TotalAP.EventHandlers.RegisterAllEvents = RegisterAllEvents
TotalAP.EventHandlers.UnregisterCombatEvents = UnregisterCombatEvents
TotalAP.EventHandlers.RegisterCombatEvents = RegisterCombatEvents
TotalAP.EventHandlers.UnregisterUpdateEvents = UnregisterUpdateEvents
TotalAP.EventHandlers.RegisterUpdateEvents = RegisterUpdateEvents


return TotalAP.EventHandlers