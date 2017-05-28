


-- [[ FQCN.lua ]]
--	Helper functions dealing with character names, realm names, and keys used in the SavedVars or elsewhere (profiles, ConfigUI, etc.)

local addonName, TotalAP = ...

if not TotalAP then return end

-- Returns fully-qualified character name (yes, I made that up)
-- For example: Cakechart on EU-Outland will return "Cakechart - Outland" (format used by many addons and for various purposes)
local function GetFQCN(characterName, realm)
	
	local characterName = characterName or UnitName("player")
	local realm = realm or GetRealmName()
	local key = format("%s - %s", characterName, realm)	 

	return key
	
end


-- Public methods
TotalAP.Utils.GetFQCN = GetFQCN


return TotalAP.Utils.GetFQCN