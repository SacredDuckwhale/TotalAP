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

-- [[ Cache.lua ]]
-- Interface for the addon's progress cache (stored via SavedVars) -- TODO: Can AceDB handle this, or should it be restricted to settings only?

local addonName, TotalAP = ...

if not TotalAP then return end


-- Return "empty" entry / default values for a spec that hasn't been scanned yet (values are nil, so that specs that haven't been cached yet can be detected but it doesn't break the API/addon)
local function GetDefaults()

	local defaultValues = {
			["numTraitsPurchased"] = nil,
			["thisLevelUnspentAP"] = nil,
			["artifactTier"] = nil,
			["isIgnored"] = false,
		}

		return defaultValues
		
end

-- Returns a reference to the currently used SavedVars (cache) object
local function GetReference()
	-- TODO: LoadAddonMetadata("TotalAP", "SavedVars") ?
	-- TODO: provide interface for AceDB via this handler ?
	
	return TotalArtifactPowerCache
	
end

-- Returns the entire cache entry for a given character and spec
local function GetEntry(fqcn, specID)

	local cache = GetReference()

	if not (cache and fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to retrieve Cache entry, but either fqcn or specID given were invalid (or the cache doesn't even exist)")
		return
	
	end
	
	return cache[fqcn][specID] 
	
end


-- Add a new entry for the respective character (key => char - realm) spec. Will us values given via defaults table
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
		
	end
	
	if not cache[fqcn][specID] then -- Create new spec entry, while adding either the given default values or the base defaults set above
		
		cache[fqcn][specID] = defaults
		
	end
	
end

-- Updates an existing entry for the respective character and spec with the given values
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

-- Returns the cached value of the respective character and spec for a given key
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
	
	if not (entry and key and entry[key]) then -- Key is invalid or entry doesn't exist
	
		TotalAP.Debug("Attempted to retrieve cache entry for key = " .. key .. ", but key is invalid or entry doesn't exist")
		return
		
	end
	
	return entry[key]

end

-- Returns the number of ignored specs for a given character (defaults to currently used character if none is given)
local function GetNumIgnoredSpecs(fqcn) -- TODO: Move to Cache
	
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


-- Public methods
TotalAP.Cache.NewEntry = NewEntry
TotalAP.Cache.UpdateEntry = UpdateEntry
TotalAP.Cache.GetValue = GetValue
TotalAP.Cache.GetNumIgnoredSpecs = GetNumIgnoredSpecs


-- Keep these private
-- TotalAP.Cache.GetReference = GetReference
-- TotalAP.Cache.GetDefaults = GetDefaults
-- TotalAP.Cache.GetEntry = GetEntry


return TotalAP.Cache