 --[[ TotalAP - Artifact Power tracking addon for World of Warcraft: Legion
 
	-- LICENSE (short version):
	
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
--]]


-- [[ DB.lua ]]
-- Interface for the addon's static database (= all files stored in the \DB\ folder)

-- TODO: Let AceDB handle TotalArtifactPowerSettings (formerly handled by DBHandler, which is now DB.lua and acts as an interface for TotalAP.DB (formerly TotalArtifactsPowerDB)), and repurpose the DBHandler for the "actual" DB (itemEffects and such), also split into DBHandler and CacheHandler (in Core\Controllers?)

local addonName, TotalAP = ...

if not TotalAP then return end

-- Returns a reference to the top-level DB object
local function GetReference()

	return TotalAP.DB
	
end


---- Artifact weapons DB

-- Returns a reference to the artifact weapons DB object
local function GetArtifactWeapons()

	local db = GetReference()
	return db["artifacts"]

end

-- TODO Unused, for now?
-- local function GetArtifactWeaponsForClass(classID)
-- end

-- Returns the item ID of the artifact weapon for the given class and spec
local function GetArtifactItemID(classID, specID)

	local db = GetArtifactWeapons()
	
	if not (classID and specID and db[classID] and db[classID][specID] and db[classID][specID]["itemID"]) then -- Invalid parameters
	
		TotalAP.Debug("Attempted to retrieve artifact weapon ID, but the class or spec IDs were invalid")
		return false
		
	end

	return db[classID][specID]["itemID"]
	
end	

---- Artifact items (tokens) DB // TODO: Actually, itemEffectsDB would be a more fitting name... but it serves as DB for the items themselves

-- Returns a reference to the item effects DB (spell effects)
local function GetItemEffects()
	
	local db = GetReference()
	return db["itemEffects"]
	
end

-- Returns the item spell effect ID for a given itemID
local function GetItemEffectID(itemID)

	local itemEffects = GetItemEffects()
	
	if not (itemID and itemEffects[itemID]) then
	
		TotalAP.Debug("Attempted to retrieve item effect for an invalid itemID")
		return false
	end
	
	return itemEffects[itemID]

end

---- ULA items DB (TODO)



-- Public methods
TotalAP.DB.GetArtifactItemID = GetArtifactItemID
TotalAP.DB.GetItemEffectID = GetItemEffectID

-- Keep these private, unless they're needed elsewhere
-- TotalAP.DB.GetReference = GetReference
-- TotalAP.DB.GetArtifactWeapons = GetArtifactWeapons
-- TotalAP.DB.
-- TotalAP.DB.
-- TotalAP.DB.


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
													inset = 1,
													
													alignment = "center", -- TODO: Provide option via GUI (AceConfig)
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
													showMiniBar = true,
													alignment = "center", -- TODO: Provide option via GUI (AceConfig)
													
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



-- Removes all specs from the ignored specs list for a given character (defaults to currently used character if none is given)
local function UnignoreAllSpecs(fqcn)
	
	if not TotalArtifactPowerCache then return end -- Skip unignore if cache isn't initialised or this is called before the addon loads
	
	-- TODO: DRY
	local characterName, realm
	
	if fqcn then 
		characterName, realm = fqcn:match("(%.+)%s-%s(%.)+")
	end
	
	if not characterName or not realm then -- Use currently active character
		
		characterName = UnitName("player")
		realm = GetRealmName()
		
	end
		 
	local key = format("%s - %s", characterName, realm)	 
	
	for i = 1, GetNumSpecializations() do -- Remove spec from "ignore list" (more precisely, remove "marked as ignored" flag for all cached specs of the active character)
	
		if TotalArtifactPowerCache[key] and TotalArtifactPowerCache[key][i] then TotalArtifactPowerCache[key][i]["isIgnored"] = false end
	
	end
	
end

-- TODO: Unignore only one (current) spec

local function SaveDB()
end

TotalAP.DBHandler.GetDB = GetDB
TotalAP.DBHandler.RestoreDefaults = RestoreDefaults
TotalAP.DBHandler.GetDefaults = GetDefaults
TotalAP.DBHandler.UnignoreAllSpecs = UnignoreAllSpecs

return TotalAP.DBHandler

