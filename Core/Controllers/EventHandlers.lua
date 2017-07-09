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

local isBankOpen, isPlayerUsingVehicle, isPlayerEngagedInCombat, isPetBattleInProgress, hasPlayerLostControl

--- Scans the contents of either the player's inventory, or their bank
-- @param[opt] scanBank Whether or not the bank should be scanned instead of the player's inventory (defaults to false)
local function ScanInventory(scanBank)

	local foundTome = false -- For BoA tomes -> The display must display them before any AP tokens if any were found 
	
	 -- Temporary values that will be overwritten with the next item
	local bag, maxBag, slot, tempItemLink, tempItemID, tempItemTexture
	local isTome, isToken = false, false -- Refers to current item
	
	-- To be saved in the Inventory cache
	local displayItem = {} -- The item that is going to be displayed on the actionButton (after the next call to GUI.Update())
	local numItems, artifactPowerSum = 0, 0 -- These are for the current scan
	local spellDescription, spellID, artifactPowerValue = nil, nil, 0  -- These are for the current item
	
	if scanBank then -- Scan generic bank and set bag IDs 
	
		-- Scan generic bank container once
		--BANK_CONTAINER
		TotalAP.ChatMsg("Scanning generic bank contents")
	
		-- Set bag IDs to only scan bank bags
		bag = NUM_BAG_SLOTS + 1
		maxBag = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
	
	else -- Scan inventory bags
	
		-- Set bag IDs to only scan inventory bags
		bag = BACKPACK_CONTAINER
		maxBag = NUM_BAG_SLOTS
		
		-- TODO: If Tome was found in bank, can't use it but will it be displayed?
	
	end
	
	for bag = bag, maxBag do -- Iterate over this bag's contents
	
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
						artifactPowerSum = artifactPowerSum + artifactPowerValue
						
						TotalAP.Debug("Found AP token: " .. tempItemLink .. " -> numItems = " .. numItems .. ", artifactPowerSum = " .. artifactPowerSum)	
						
					end
				
					if not scanBank and isTome or (isToken and not foundTome) then -- Set this item as the currently displayed one (so that the GUI can use it)
					
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
	
		if scanBank then -- Calculate AP value for bank bags and update bankCache so that other modules can access it)
			
			local bankCache = TotalAP.bankCache
			bankCache.numItems = numItems
			bankCache.inBankAP = artifactPowerSum
	
		else	-- Calculate AP value for inventory bags and update inventory cache so that other modules can access it)
	
			local inventoryCache = TotalAP.inventoryCache
			inventoryCache.foundTome = foundTome
			inventoryCache.displayItem = displayItem
			inventoryCache.numItems = numItems
			inventoryCache.inBagsAP = artifactPowerSum
			
		end
	
end

--- Scan inventory contents and update the addon's inventoryCache accordingly
local function ScanBags()

		ScanInventory(false)
	
end

--- Scan bank contents and update the addon's bankCache accordingly
local function ScanBank()
	
	ScanInventory(true)
	
end

--- Toggle a GUI Update (which is handled by the GUI controller and not the Event controller itself)
local function UpdateGUI()

	TotalAP.Controllers.UpdateGUI()
	
end

--- Scan the currently equipped artifact and update the addon's artifactCache accordingly
local function OnArtifactUpdate()
	
	-- TODO: Is this necessary or will OnInventoryUpdate cover this? Maybe scan artifact data here only instead of having it scanned with every item change (Bag update)?
	
	TotalAP.Debug("OnArtifactUpdate triggered")
	
	-- Re-scan inventory and update all stored values
	ScanBags()
	
	-- Update GUI to display the most current information
	UpdateGUI()
	
end

--- Called when an inventory update finishes
local function OnInventoryUpdate()

	TotalAP.Debug("OnInventoryUpdate triggered")
	
	-- Re-scan inventory and update all stored values
	ScanBags()
	if isBankOpen then -- Update bankCache also (in case items were moved between inventory and bank)
		ScanBank()
	end
	
	-- Update GUI to display the most current information
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when player accesses the bank
local function OnBankOpened()

	TotalAP.Debug("OnBankOpened triggered")
	isBankOpen = true
	
	-- Re-scan bank and update all stored values
	ScanBank()
	
	-- Update GUI to display the most current information
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when player closes the bank
local function OnBankClosed()
	
	TotalAP.Debug("OnBankClosed triggered")
	isBankOpen = true
	
end

--- Called when player switches bags or changes items in the generic bank storage (not inside of bags, though!)
local function OnPlayerBankSlotsChanged()

	TotalAP.Debug("OnPlayerBankSlotsChanged triggered")
	
		-- Re-scan bank and update all stored values
	ScanBank()
	
	-- Update GUI to display the most current information
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when player enters combat
local function OnEnterCombat()

	TotalAP.Debug("OnEnterCombat triggered")
	isPlayerEngagedInCombat = true

	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when player leaves combat
local function OnLeaveCombat()

	TotalAP.Debug("OnLeaveCombat triggered")
	isPlayerEngagedInCombat = false
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when pet battle begins
local function OnPetBattleStart()

	TotalAP.Debug("OnPetBattleStart triggered")
	isPetBattleInProgress = true
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

--- Called when pet battle ends
local function OnPetBattleEnd()

	TotalAP.Debug("OnPetBattleEnd triggered")
	isPetBattleInProgress = false
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

-- Called when unit enters vehicle
local function OnUnitVehicleEnter(...)

	local args = { ... }
	local unit = args[2]
	
	TotalAP.Debug("OnUnitVehicleEnter triggered for unit = " .. tostring(unit))
	isPlayerUsingVehicle = true
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

-- Called when unit exits vehicle
local function OnUnitVehicleExit(...)

	local args = { ... }
	local unit = args[2]
	
	TotalAP.Debug("OnUnitVehicleExit triggered for unit = " .. tostring(unit))
	isPlayerUsingVehicle = false
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

-- Called when player uses flight master taxi services
local function OnPlayerControlLost()

	TotalAP.Debug("OnPlayerControlLost triggered")
	hasPlayerLostControl = true
	
	-- Update GUI to show/hide displays when necessary
	TotalAP.Controllers.UpdateGUI()
	
end

-- Called when player finishes using flight master taxi services
local function OnPlayerControlGained()

	TotalAP.Debug("OnPlayerControlGained triggered")
	hasPlayerLostControl = false

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
	["BANKFRAME_CLOSED"] = OnBankClosed,
	["PLAYERBANKSLOTS_CHANGED"] = OnPlayerBankSlotsChanged, -- generic slots OR bags (not item in bags) have changed
	
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
		TotalAP.Debug("Registered for event = " .. key)
	
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