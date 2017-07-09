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

	TotalAP.Debug("EventHandlers -> OnInventoryUpdate triggered")

	
	-- Re-scan inventory and update all stored values
	local foundTome = false -- For BoA tomes -> The display must display them before any AP tokens if any were found 
	
	 -- Temporary values that will be overwritten with the next item
	local bag, slot, tempItemLink, tempItemID, tempItemTexture
	local isTome, isToken = false, false -- Refers to current item
	
	-- To be saved in the Inventory cache
	local displayItem = {} -- The item that is going to be displayed on the actionButton (after the next call to GUI.Update())
	local numItems, inBagsAP = 0, 0 -- These are for the current scan
	local spellDescription, spellID, artifactPowerValue -- These are for the current item
	
	for bag = 0, NUM_BAG_SLOTS do -- Iterate over this bag's contents
	
		for slot = 1, GetContainerNumSlots(bag) do -- Compare items in the current bag with DB entries to detect AP tokens
	
			tempItemLink = GetContainerItemLink(bag, slot)

			if tempItemLink and tempItemLink:match("item:%d") then -- Is a valid item
			
					tempItemID = GetItemInfoInstant(tempItemLink)
					
					isTome = TotalAP.DB.IsResearchTome(tempItemID)
					isToken = TotalAP.DB.IsArtifactPowerToken(tempItemID)

					-- TODO: Move this to DB\ResearchTomes or something, and access via helper function (similar to artifacts)
					if isTome then -- AK Tome is available for use -> Display button regardless of current AP tokens
					
						TotalAP.Debug("Found Artifact Research tome -> Displaying it instead of potential AP items")
						foundTome = true
						
					end
					
					if isToken then -- Found token -> Use it in calculations

						numItems = numItems + 1
						
						-- Extract AP amount (after AK) from the description
						spellID = TotalAP.DB.GetItemSpellEffect(tempItemID)
						spellDescription = GetSpellDescription(spellID) -- Always contains the AP number, as only AP tokens are in the LUT 
						
						artifactPowerValue = TotalAP.Scanner.ParseSpellDesc(spellDescription) -- Scans spell description and extracts AP amount based on locale (as they use slightly different formats to display the numbers)

						inBagsAP = inBagsAP + tonumber(artifactPowerValue)

					end
				
					if isTome or (isToken and not foundTome) then -- Set this item as the currently displayed one (so that the GUI can use it)
					
						displayItem.ID = tempItemID
						displayItem.link = tempItemLink
						displayItem.texture = GetItemIcon(displayItem.ID)
						displayItem.isToken = isToken
						displayItem.isTome = isTome
						displayItem.artifactPowerValue = artifactPowerValue
						
					end
					
				end
					
		end
	
	end
	
	
	-- Update inventory cache (stored in addon table so that other modules can access it)
	local inventoryCache = TotalAP.inventoryCache
	inventoryCache.foundTome = foundTome
	inventoryCache.displayItem = displayItem
	inventoryCache.numItems = numItems
	inventoryCache.inBagsAP = InBagsAP
	
	
	-- Update GUI to display the most current information
	TotalAP.Controllers.UpdateGUI()
	
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
-- Called when player uses flight master taxi services
local function OnPlayerControlLost()

	TotalAP.Debug("OnPlayerControlLost triggered")
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

-- Called when player finishes using flight master taxi services
local function OnPlayerControlGained()

	TotalAP.Debug("OnPlayerControlGained triggered")

	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
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
	["PLAYER_CONTROL_LOST"] = OnPlayerControlLost,
	["PLAYER_CONTROL_GAINED"] = OnPlayerControlGained,
	
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