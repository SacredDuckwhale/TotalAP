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

-- Core\DBHandler.lua
-- Interface for the addon's DB (SavedVars) -- TODO: Let AceDB handle this, and repurpose the DBHandler for the "actual" DB (itemEffects and such), also split into DBHandler and CacheHandler (in Core\Controllers?)

local addonName, TotalAP = ...

if not TotalAP then return end

-- SavedVars defaults (to check against, and load if corrupted/rendered invalid by version updates)
-- TODO: Use AceDB for this
-- TODO: Doesn't belong here. Maybe put it in Core\DefaultSettings.lua? - or not. AceDB will handle it soon enough
local defaultSettings =	{	
												-- General options
												
												-- controls what output will be printed in the chat frame
												debugMode = false,
												verbose = true,
												showLoginMessage = true,
												enabled = true,		-- This controls the entire display, but NOT the individual parts (which will be hidden, but their settings won't be overridden)
												hideInCombat = true,
												
											--	showNumItems = true, -- TODO: Deprecated
												--showProgressReport = true, -- TODO: Deprecated
												
												--showActionButton = true, -- TODO: Toggles everything. That should be changed
												
												--showButtonGlowEffect = true, -- TODO: actionButton
												
												actionButton = {
													enabled = true,
													showGlowEffect = true,
													minResize = 20,
													maxResize = 100,
													showText = true
												},

												-- Display options for the spec icons
												specIcons = {
													enabled = true,
													showGlowEffect = true,
													size = 18,
													border = 1,
													inset = 1
												},
												
												-- Controls what information is displayed in the tooltip
												tooltip = {
													enabled = true, 
													showProgressReport = true,
													showNumItems = true
												},
												
												-- Display options for the bar displays
												infoFrame = {
													enabled = true,
													barTexture = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp", -- Default texture. TODO. SharedMedia
													barHeight = 16,
													border = 1,
													inset = 1,
													
													progressBar = {
														red = 250,
														green = 250,
														blue = 250,
														alpha = 0.2
													},
													
													unspentBar = {
														red = 50,
														green = 150,
														blue = 250,
														alpha = 1
													},
													
													inBagsBar = {
														red = 50,
														green = 95,
														blue = 150,
														alpha = 1
													}
												}
												
											};



-- Returns a reference to the currently used SavedVars (DB) object
local function GetDB()
	-- TODO: LoadAddonMetadata("TotalAP", "SavedVars") ?
	-- TODO: provide interface for AceDB via this handler
	
	return TotalArtifactPowerSettings
end

-- TODO: Remove/crutch for migration or actually useful later?
local function GetDefaults()
	return defaultSettings
end

local function RestoreDefaults()
	TotalArtifactPowerSettings = defaultSettings;
	--settings = TotalArtifactPowerSettings;
end

-- Returns the number of ignored specs for a given character (defaults to currently used character if none is given)
local function GetNumIgnoredSpecs(fqCharName)
	
	local characterName, realm
	
	if fqCharName then 
		characterName, realm = fqCharName:match("(%.+)%s-%s(%.)+")
	end
	
	if not characterName or not realm then -- Use currently active character
		
		characterName = UnitName("player")
		realm = GetRealmName()
		
	end
		 
	key = format("%s - %s", characterName, realm)	 
	--TotalAP.Debug("Counting ignored specs for character " .. key)
	
	local numIgnoredSpecs = 0
	
	for i = 1, GetNumSpecializations() do
	
		if TotalArtifactPowerCache[key] and TotalArtifactPowerCache[key][i]["isIgnored"] then
			
			--TotalAP.Debug("Spec " .. i .. " was found to be ignored")
			numIgnoredSpecs = numIgnoredSpecs + 1
			
		end
		
	end
	
	return numIgnoredSpecs
	
end

-- Removes all specs from the ignored specs list for a given character (defaults to currently used character if none is given)
local function UnignoreAllSpecs(fqCharName)
	
	-- TODO: DRY
	local characterName, realm
	
	if fqCharName then 
		characterName, realm = fqCharName:match("(%.+)%s-%s(%.)+")
	end
	
	if not characterName or not realm then -- Use currently active character
		
		characterName = UnitName("player")
		realm = GetRealmName()
		
	end
		 
	key = format("%s - %s", characterName, realm)	 
	
	for i = 1, GetNumSpecializations() do -- Remove spec from "ignore list" (more precisely, remove "marked as ignored" flag)
	
		if TotalArtifactPowerCache[key] then TotalArtifactPowerCache[key][i]["isIgnored"] = false end
	
	end
	
end

-- TODO: Unignore only one (current) spec

local function SaveDB()
end

TotalAP.DBHandler.GetDB = GetDB
TotalAP.DBHandler.RestoreDefaults = RestoreDefaults
TotalAP.DBHandler.GetDefaults = GetDefaults
TotalAP.DBHandler.GetNumIgnoredSpecs = GetNumIgnoredSpecs
TotalAP.DBHandler.UnignoreAllSpecs = UnignoreAllSpecs

return TotalAP.DBHandler

