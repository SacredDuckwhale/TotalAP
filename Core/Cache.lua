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

--- 
-- @module Core

--- Cache.lua.
-- Provides an interface for the addon's progress cache (stored via SavedVars).
-- @section Cache


local addonName, TotalAP = ...

if not TotalAP then return end


--- Returns the base structure for an "empty" cache entry.
-- It contains values for a spec that hasn't been scanned yet, where all values are nil except "isIgnored" (which is FALSE)
-- This is so that specs that haven't been cached yet can be detected, but won't cause errors when their cache entries are being accessed
-- @return A newly-created table with predefined keys and the setting for "ignore spec" disabled
-- @usage GetDefaults() -> { ["numTraitsPurchased"] = nil, ["thisLevelUnspentAP"] = nil, ["artifactTier"] = nil, ["isIgnored"] = false }
local function GetDefaults() -- TODO Is this even necessary? Surely the ignore methods could check for nil instead

	local defaultValues = {
			["numTraitsPurchased"] = nil,
			["thisLevelUnspentAP"] = nil,
			["artifactTier"] = nil,
			["isIgnored"] = false,
		}

		return defaultValues
		
end

--- Returns a reference to the underlying SavedVars (cache) object
-- @return A reference to the cache database table itself
local function GetReference() -- TODO: AceDB can handle this

	return TotalArtifactPowerCache
	
end

--- Returns the entire cache entry for a given character and spec
-- @param fqcn Fully-qualified character name, to be used as the key
-- @param specID Specialization ID, to be used as the secondary key
-- @return The table representing the cache entry if one exists; nil otherwise
-- @usage GetEntry("Duckwhale - Outland", 1) ->  { ["numTraitsPurchased"] = 15, ["thisLevelUnspentAP"] = 235000, ["artifactTier"] = 1, ["isIgnored"] = false }
local function GetEntry(fqcn, specID)

	local cache = GetReference()

	if not (cache and fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to retrieve Cache entry, but either fqcn or specID given were invalid (or the cache doesn't even exist)")
		return
	
	end
	
	return cache[fqcn][specID] 
	
end

--- Add a new cache entry for the respective character/spec, and optionally sets it to predefined values (uses empty "default" entry if none was given)
-- @param fqcn Fully-qualified character name, to be used as the primary key
-- @param specID Specialization ID, to be used as the secondary key
-- @param[opt] defaults A table containing default entries that should be used
-- @return The newly-created entry (as a table) if creation was successful; nil otherwise
-- @usage NewEntry("Duckwhale - Outland", 2) ->  { ["numTraitsPurchased"] = nil, ["thisLevelUnspentAP"] = nil, ["artifactTier"] = nil, ["isIgnored"] = false }
local function NewEntry(fqcn, specID, defaults)
	
	local cache = GetReference() -- using API so name changes will carry over to this function
	
	if not (cache and fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to create new Cache entry, but either fqcn or specID given were invalid (or the cache doesn't exist)")
		return
		
	end
	
	if not defaults then -- Set default values for new and never-before used artifacts -> Should at least work with the API, and will be updated with the proper values anyway
		
		TotalAP.Debug("Creating new Cache entry with default values, because none were given")
		
		defaults = GetDefaults()
		
	end
	
	

	if not cache[fqcn] then -- Create new entry, without adding spec data
	
		cache[fqcn] = {}
		cache[fqcn]["bankedAP"] = 0
		
	end
	
	if not cache[fqcn][specID] then -- Create new spec entry, while adding either the given default values or the base defaults set above
		
		cache[fqcn][specID] = defaults
		
	end
	
	return cache[fqcn][specID]
	
end

--- Updates an existing entry for the respective character and spec with the given values
-- @param fqcn Fully qualified character name, to be used as the primary key
-- @param specID Specialization ID, to be used as the secondary key
-- @param updateValues A table representing the new entry, to replace any existing entry with
-- @return true if the update was successful; nil otherwise
-- @usage UpdateEntry("Duckwhale - Outland", 3, { ["numTraitsPurchased"] = 15, ["thisLevelUnspentAP"] = 235000, ["artifactTier"] = 1, ["isIgnored"] = false }  -> true
local function UpdateEntry(fqcn, specID, updateValues)

	local cache = GetReference()

	if not (fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to update Cache entry, but either fqcn or specID given were invalid")
		return
	
	end
	
	if not (cache and cache[fqcn] and cache[fqcn][specID]) then -- Cache entry doesn't exist
	
		TotalAP.Debug("Attempted to update cache entry for fqcn = " .. fqcn .. " and spec = " .. specID .. ", but it didn't exist (or the cache isn't initialised yet)")
		return
		
	end
	
	-- Update cache entry (TODO: only if given values were correct?)
	if not updateValues then return false end
	
	cache[fqcn][specID] = updateValues
	return true
end

--- Returns the cached value of the respective character and spec for a given key
-- @param fqcn Fully-qualified character name, to be used as the primary key
-- @param specID Specialization ID, to be used as the secondary key
-- @param key The key used to look up values inside of the cache entry
-- @usage GetValue("Duckwhale - Outland", 3, "numTraitsPurchased") -> 15
local function GetValue(fqcn, specID, key)

	if not (fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to retrieve Cache entry, but either fqcn or specID given were invalid")
		return
	
	end

	local cache = GetReference()
	
	if not (cache and cache[fqcn] and cache[fqcn][specID]) then -- Cache entry doesn't exist
	
		TotalAP.Debug("Attempted to update cache entry for fqcn = " .. fqcn .. " and spec = " .. specID .. ", but it didn't exist")
		return
		
	end
	
	local entry = GetEntry(fqcn, specID)
	
	if not (entry ~= nil and key and entry[key]) then -- Key is invalid or entry doesn't exist
	
		TotalAP.Debug("Attempted to retrieve cache entry for key = " .. key .. ", but key is invalid or entry doesn't exist")
		return
		
	end
	
	return entry[key]

end

local function SetValue(fqcn, specID, key, value)

end

local function IgnoreSpec(fqcn, spec)

end

--- Returns the amount of banked AP that was saved between sessions
-- @param[opt] fqcn The fully-qualified character name (defaults to currently logged in character if omitted)
local function GetBankCache(fqcn)

	local cache = GetReference()

	if not fqcn then -- Use logged in character name/realm
		fqcn = TotalAP.Utils.GetFQCN()
	end
	
	if not (cache and cache[fqcn] and cache[fqcn]["bankCache"]) then -- Entry does not exist -> Abort
		
		TotalAP.Debug("Attempted to retrieve bankCache for cache entry with key = " .. tostring(fqcn))
		return
		
	end

	return cache[fqcn]["bankCache"]
	
end

--- Update the bankCache from saved variables if one has been stored in a previous session
-- @param[opt] fqcn The fully-qualified character name (defaults to currently logged in character if omitted)
local function UpdateBankCache(fqcn)

	local cache = GetReference()

	if not fqcn then -- Use logged in character name/realm
		fqcn = TotalAP.Utils.GetFQCN()
	end
	
	if not (cache and cache[fqcn]) then -- Abort, abort!
	
		TotalAP.Debug("Failed to update bankCache for key = " .. tostring(fqcn))
		return
		
	end
	
	cache[fqcn]["bankCache"] = TotalAP.bankCache

end

--- Update the saved variables from artifactCache for the current session. Should only be called after said cache was updated to prevent overwriting the saved cache with an empty one
-- @param[opt] fqcn The fully-qualified character name (defaults to currently logged in character if omitted)
-- @param[opt] specNo The spec number that is to be updated (defaults to current spec if omitted)
local function UpdateArtifactCache(fqcn, specNo)

	local cache = GetReference()

	if not fqcn then -- Use logged in character name/realm
		fqcn = TotalAP.Utils.GetFQCN()
	end
	
	if not specNo then -- Use current spec
		specNo = GetSpecialization()
	end

	if not (cache and cache[fqcn] and cache[fqcn][specNo] and TotalAP.artifactCache and TotalAP.artifactCache[fqcn] and TotalAP.artifactCache[fqcn][specNo]) then -- Abort, abort!
	
		TotalAP.Debug("Failed to update artifactCache for key = " .. tostring(fqcn) .. ", specNo = " .. tostring(specNo))
		return
		
	end
	-- TODO: If cache entry doesn't exist, create it?
	cache[fqcn][specNo] = TotalAP.artifactCache[fqcn][specNo] -- Only update the requested spec and leave the others intact

end

--- Returns the number of ignored specs for a given character (defaults to currently used character if none is given)
-- @param[opt] fqcn Fully qualified character name, to be used as the primary key
-- @return Number of ignored specs; 0 if none are cached
local function GetNumIgnoredSpecs(fqcn)
	
	if not fqcn then -- Use currently logged in character
		fqcn = TotalAP.Utils.GetFQCN() 
	end
	
	TotalAP.Debug("Counting ignored specs for character " .. fqcn)
	
	local numIgnoredSpecs = 0
	
	for i = 1, GetNumSpecializations() do -- Test if this spec is currently set to being ignored
	
		local isSpecIgnored = GetValue(fqcn, i, "isIgnored")
		
		if isSpecIgnored then
			
			TotalAP.Debug("Spec " .. i .. " was found to be ignored")
			numIgnoredSpecs = numIgnoredSpecs + 1
			
		end
		
	end
	
	return numIgnoredSpecs
	
end

--- Removes all specs from the ignored specs list for a given character (defaults to currently used character if none is given)
-- @param[opt] fqcn  Fully-qualified character name that will have their specs "IsIgnored" setting reset
-- TODO: This doesn't belong here
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


-- Public methods
TotalAP.Cache.NewEntry = NewEntry
TotalAP.Cache.GetEntry = GetEntry
TotalAP.Cache.UpdateEntry = UpdateEntry
TotalAP.Cache.GetValue = GetValue
TotalAP.Cache.GetBankCache = GetBankCache
TotalAP.Cache.UpdateBankCache = UpdateBankCache
TotalAP.Cache.GetNumIgnoredSpecs = GetNumIgnoredSpecs
TotalAP.Cache.UnignoreAllSpecs = UnignoreAllSpecs
TotalAP.Cache.UpdateArtifactCache = UpdateArtifactCache

-- Keep these private
-- TotalAP.Cache.GetReference = GetReference
-- TotalAP.Cache.GetDefaults = GetDefaults
-- TotalAP.Cache.GetEntry = GetEntry


return TotalAP.Cache