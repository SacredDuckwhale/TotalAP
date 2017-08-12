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


-- Localized globals
local _G = _G
local cacheVarName = "TotalArtifactPowerCache"

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

	return _G[cacheVarName]
	
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
	
		TotalAP.Debug("Attempted to retrieve cache entry for fqcn = " .. fqcn .. " and spec = " .. specID .. ", but it didn't exist")
		return
		
	end
	
	local entry = GetEntry(fqcn, specID)
	
	if not (entry and key and entry[key] ~= nil) then -- Key is invalid or entry doesn't exist
	
		TotalAP.Debug("Attempted to retrieve cache entry for key = " .. key .. ", but key is invalid or entry doesn't exist")
		return
		
	end
	
	return entry[key]

end

--- Sets the cached value of the respective character and spec for a given key
-- @param fqcn Fully-qualified character name, to be used as the primary key
-- @param specID Specialization ID, to be used as the secondary key
-- @param key The key used to look up values inside of the cache entry
local function SetValue(fqcn, specID, key, value)
	
	if not (fqcn and specID) then -- Parameters given were invalid
	
		TotalAP.Debug("Attempted to set Cache entry, but either fqcn or specID given were invalid")
		return
	
	end

	local cache = GetReference()
	
	if not (cache and cache[fqcn] and cache[fqcn][specID]) then -- Cache entry doesn't exist
	
		TotalAP.Debug("Attempted to set cache entry for fqcn = " .. fqcn .. " and spec = " .. specID .. ", but it didn't exist")
		return
		
	end
	
	local entry = GetEntry(fqcn, specID)
	
	if not (entry and key and entry[key] ~= nil	) then -- Key is invalid or entry doesn't exist
	
		TotalAP.Debug("Attempted to set cache entry for key = " .. key .. ", but key is invalid or entry doesn't exist")
		return
		
	end
	
	entry[key] = value
	
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

--- Update the saved variables from bankCache for the current session. Should only be called after said cache was updated to prevent overwriting the saved cache with an empty one
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

	if not (cache and cache[fqcn] and TotalAP.artifactCache and TotalAP.artifactCache[fqcn] and TotalAP.artifactCache[fqcn][specNo]) then -- Abort, abort!

		TotalAP.Debug("Failed to update artifactCache for key = " .. tostring(fqcn) .. ", specNo = " .. tostring(specNo))
		return
		
	end
	
	if not cache[fqcn][specNo] then cache[fqcn][specNo] = {} end -- in case no entry exists for this spec (as they can't be initialised before spec info is loaded)
	cache[fqcn][specNo] = TotalAP.artifactCache[fqcn][specNo] -- Only update the requested spec and leave the others intact

end


--- Returns the number of ignored specs for a given character
-- @param[opt] fqcn Fully qualified character name, to be used as the primary key (defaults to currently used character if none is given)
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

--- Returns whether or not a spec is being ignored for a given character
-- @param[opt] fqcn Fully qualified character name, to be used as the primary key (defaults to currently used character if none is given)
-- @param[opt] specNo Spec number (defaults to current spec if omitted)
-- @return Whether or not the spec is set to being ignored
local function IsSpecIgnored(fqcn, specNo)

	fqcn = fqcn or TotalAP.Utils.GetFQCN() 
	specNo = specNo or GetSpecialization()
	
	local defaults = GetDefaults()
	return GetValue(fqcn, specNo, "isIgnored") or defaults["isIgnored"]
	
end

--- Returns whether or not the currently active spec is being ignored for the logged-in character
-- @return Whether or not the current spec is set to being ignored
local function IsCurrentSpecIgnored()

	return IsSpecIgnored(nil, GetSpecialization())

end

--- Ignores a spec for the given character
-- @param[opt] fqcn Fully qualified character name, to be used as the primary key (defaults to currently used character if none is given)
-- @param[opt] specNo Spec number (defaults to current spec if omitted)
local function IgnoreSpec(fqcn, specNo)

	fqcn = fqcn or TotalAP.Utils.GetFQCN() 
	specNo = specNo or GetSpecialization()
	
	SetValue(fqcn, specNo, "isIgnored", true)

end

--- Unignores a spec for the given character
-- @param[opt] fqcn Fully qualified character name, to be used as the primary key (defaults to currently used character if none is given)
-- @param[opt] specNo Spec number (defaults to current spec if omitted)
local function UnignoreSpec(fqcn, specNo)

	fqcn = fqcn or TotalAP.Utils.GetFQCN() 
	specNo = specNo or GetSpecialization()
	
	SetValue(fqcn, specNo, "isIgnored", false)

end

--- Removes all specs from the ignored specs list for a given character
-- @param[opt] fqcn Fully-qualified character name (defaults to currently used character if none is given)
local function UnignoreAllSpecs(fqcn)
	
	fqcn = fqcn or TotalAP.Utils.GetFQCN() 
	
	for i = 1, GetNumSpecializations() do -- Remove spec from "ignore list" (more precisely, remove "marked as ignored" flag for all cached specs of the active character)
	
		SetValue(fqcn, i, "isIgnored", false)
	
	end
	
end

-- Validator functions (TODO: Duplicate code/DRY)
local function IsBoolean(value)
	return type(value) == "boolean"
end	

local function IsNumber(value)
	return type(value) == "number"
end	

-- LUT for validator functions
local validators = {
	
	["isIgnored"] = IsBoolean,
	["artifactTier"] = IsNumber,
	["thisLevelUnspentAP"] = IsNumber,
	["numTraitsPurchased"] = IsNumber,

}

--- Validate a particular cache entry's data (by key)
-- @param key The key to validate
-- @param value The value to check
-- @return Whether or not the given value is a valid entry for the given key; nil if either parameter is omitted or invalid
local function ValidateEntry(key, value)
	
	if key ~= nil and value ~= nil then -- Both parameters were given -> validation can be run
		local v = validators[key]
		
		if v ~= nil then -- key is valid at least -> check if value is valid also
--			TotalAP.Debug("ValidateEntry -> Validation ran for key = " .. tostring(key) .. " and returned v = " .. tostring(v(value)))
			return v(value)
		end
		
--		TotalAP.Debug("ValidateEntry -> Validation failed for key = " .. tostring(key) .. " because the key is invalid")

	else -- At least one parameter was missing/invalid -> return false if key was valid, and nil otherwise
		
		if key ~= nil and validators[key] then -- Key is valid, but value isn't -> return false instead of the usual nil
--			TotalAP.Debug("ValidateEntry -> Validation failed for key = " .. tostring(key) .. " because the assigned value is invalid")
			return false
		end
		
	end
	
end

--- Validate a particular spec entry's data (table contents)
-- @param t The table containing the spec's cache entry (TODO: The spec number)
-- @return Whether or not the given table (TODO: spec)  represents a valid entry; nil if it is omitted or an invalid type/empty table
local function ValidateSpec(t)

	-- Invalid parameter -> returns nil
	if not (t and type(t) == "table") then
		--TotalAP.Debug("ValidateSpec -> Validation failed because parameter was not a table")
		return
	end

	local numKeys, isValidKey = 0
	-- Check table contents
	for key, value in pairs(t) do -- Validate the keys
	
		numKeys = numKeys + 1
		isValidKey = ValidateEntry(key, value)
		if not isValidKey then -- At least one key is invalid
--			TotalAP.Debug("ValidateSpec -> Failed to validate entry for key: " .. key)
			return false
		end
	
	end

	if numKeys and numKeys > 0 then -- Table is valid and contained no invalid keys -> return true, but only if all required keys exist (default values)
	
		local defaults = GetDefaults()
		for key, value in pairs(defaults) do -- Check if all default values exist and are valid
		
			if t[key] == nil then -- Default value is missing -> This won't fly, as they are required to guarantee functionality
--				TotalAP.Debug("ValidateSpec -> Missing required key that has a default value: " .. key)
				return false
			end
		
		end
	
		return true -- No errors were found

	else -- Table is empty -> return nil
		
	--	TotalAP.Debug("ValidateSpec -> Validation failed because parameter was empty table")
		return -- TODO: Obsolete to write this out here?
		
	end

end

--- Validates all specs for a given character
-- @param t The table representing the cache entry for a character
-- @return Whether or not the entry is a valid character entry; nil if it doesn't exist or the given parameter isn't a valid entry
local function ValidateChar(t)

	-- Invalid parameter -> returns nil
	if not (t and type(t) == "table") then
		--TotalAP.Debug("ValidateChar -> Validation failed because parameter was not a table")
		return
	end
	
		local numKeys, isValidSpecEntry = 0
	-- Check table contents
	for spec, entry in pairs(t) do -- Validate the keys
	
		numKeys = numKeys + 1
		isValidSpecEntry = ValidateSpec(entry)
		if not isValidSpecEntry then
			--TotalAP.Debug("ValidateChar -> Failed to validate spec: " .. spec)
			return false
		end -- At least one spec entry is invalid
	
	end
	
	if numKeys and numKeys > 0 then -- Table is valid (not empty) and contained no invalid entries -> return true
	
		return true -- No errors were found
		
	end

end

--- Returns the number of valid spec entries currently saved in the cache (helper function)
-- @return Number of specs that are cached and validated successfully
local function GetNumEntries()

	local numEntries = 0
	local cache = GetReference()
	for k, v in pairs(cache) do -- count entries
	
		if ValidateChar(k) then numEntries = numEntries + 1 end
		
	end

	return numEntries
	
end

--- Validate all entries in the saved cache
-- @return Whether or not the cache is valid
local function Validate()
	
	local cache = GetReference()
	if not cache or not (GetNumEntries() > 0) then -- Cache doesn't exist at all -> needs to be initialised with default values
		return false
	end
	
	for key, entry in pairs(cache) do -- Validate entry for this character
		ValidateChar(key) -- will return on failure
	end
	
	return true -- only occurs on successful validation
	
end

-- Initialises the addon's cache and fills it with data stored in the saved variables (run at startup)
local function Initialise()

	local fqcn = TotalAP.Utils.GetFQCN()
	local cache = GetReference()
	local defaults = GetDefaults()
	
	-- Restore banked AP from saved vars if possible
	local bankCache = TotalAP.Cache.GetBankCache(fqcn)
	if bankCache then -- bankCache was saved on a previous session and can be restored
	
		TotalAP.bankCache = bankCache
		
	end
	
	-- Initialise caches
	local fqcn = TotalAP.Utils.GetFQCN()
	TotalAP.artifactCache[fqcn] = {}
	
	if not cache then -- Saved vars cache doesn't exist -> rebuild it
		_G[cacheVarName] = {}
--		_G[cacheVarName][fqcn] = {}
		cache = _G[cacheVarName]
--		return -- No data exists for this character -> Abort (and keep dummy entry created above in local cache, to be saved on the next update)

	end -- cache exists, but may not contain the required entries
	
	if not cache[fqcn] then -- Entry for this char doesn't exist -> create it
			
		cache[fqcn] = {}
		
		for spec=1, GetNumSpecializations() do -- create empty table for this spec and add default values
			cache[fqcn][spec] = {}
			for key, value in pairs(defaults) do -- add default value so that the newly created cache entry is valid
				cache[fqcn][spec][key] = value
			end
			
		end
		
	else -- Cache exists for this character -> Check if entries are valid // TODO. Validate existing entries
	
	end
	
	-- Validate cache
	local isCacheValid = Validate()
	if not isCacheValid then -- something isn't right and needs to be fixed
	
		TotalAP.Debug("Validaton of cache failed on Initialise() -> checking entries to find which parts are causing issues")
		for fqcn, charEntry in pairs(cache) do -- Validate entries and drop invalid ones in the process

			local isEntryValid = ValidateChar(charEntry)
			if not isEntryValid then -- Something in this entry isn't right -> fix it or drop the invalid entries
			
				if isEntryValid ~= nil then -- Entry is valid, but something inside it isn't -> continue to find out where the issue is
			
					TotalAP.Debug("Validation of cached char entry failed for fqcn = " .. fqcn .. " -> attempting to fix it")
					for spec, specEntry in pairs(charEntry) do -- Validate entries and drop invalid ones
					
						local isSpecEntryValid = ValidateSpec(specEntry)
						if not isSpecEntryValid then -- Something isn't right -> fix or drop it
							
							if isSpecEntryValid ~= nil then -- Spec entry is valid, but some entries aren't -> validate its entries
							
								TotalAP.Debug("Validation of cached spec data failed for spec = " .. spec .. " -> attempting to fix it")
								for key, value in pairs(specEntry) do -- Validate keys and drop invalid ones
								
									local isKeyValid = ValidateEntry(key, value)
									if not isKeyValid then -- Something isn't right -> drop key entirely or replace with default value
									
										TotalAP.Debug("Validation of cached entry failed for key = " .. tostring(key) .. ", value = " .. tostring(value))
										if not defaults[key] then -- Key isn't required and can safely be dropped
											
											TotalAP.Debug("No default value exists for this key -> Dropping it")
											specEntry[key] = nil -- "unset"
											
										else -- Key is necessary for proper functioning -> replace it with default value
										
											TotalAP.Debug("Loading default value to replace the invalid data")
											specEntry[key] = defaults[key]
										
										end
									
									end
								
								end
								
							else -- Spec entry itself is messed up and should be reset to the default values (= an empty, but valid entry for this spec)
							
								TotalAP.Debug("Validation of cached spec data failed for spec = " .. spec .. " -> rebuilding it from scratch")
								charEntry[spec] = {} -- "reset"
								for k, v in pairs(defaults) do -- Add default value to rebuilt spec entry
								
									charEntry[spec][k] = v
								
								end
								
							end
							
						end
					
					end
				
				else -- The entire entry is invalid and should be dropped
				
					TotalAP.Debug("Validation of cached char entry failed for fqcn = " .. fqcn .. " -> dropping it")
					cache[fqcn] = nil
				
				end
			
			end
			
		end
	
	else
	
		TotalAP.Debug("Validation of cache was successful without manually fixing invalid entries")
	
	end	
			
	-- Read existing entries from saved vars and overwrite the dummy entries for those (but leave them for those that have no data)
	for spec, entry in pairs(cache[fqcn]) do -- At least some data exists -> merge saved data into local cache

		-- TODO: Validation and stuff... maybe
		TotalAP.artifactCache[fqcn][spec] = entry

	end
	
	-- End result: Local artifactCache is up-to-date, and savedVars are initialised (will be updated via UpdateArtifactCache method)
	
end

--- Returns whether or not the cache entry for a given character and spec is invalid, i.e. can't be used
-- @param[opt] fqcn
-- @param[opt spec
-- @returns Whether the cache entry is empty/invalid]
local function IsSpecCached(fqcn, spec)

	local cache = TotalAP.artifactCache
	local fqcn = (fqcn and type(fqcn) == "string") and fqcn or TotalAP.Utils.GetFQCN() -- TODO: validators for fqcn, spec no. etc that can be reused?
	local spec = (spec and type(spec) == "number" and spec > 0 and spec <= 4) and spec or GetSpecialization()
	
	local isInvalid = true
	
	isInvalid = isInvalid and
	-- TODO: Turn this into an actual validation routine (build array similar to aceDB validation )
	(not cache -- Cache isn't even initialised
	or not cache[fqcn] -- Cache has no entry for this character
	or not cache[fqcn][spec] -- Cache has no entry for this character's spec
	or not cache[fqcn][spec]["artifactTier"] -- artifact tier wasn't cached for this spec
	or not type(cache[fqcn][spec]["artifactTier"]) == "number" -- artifact tier is invalid for this spec
	or not (cache[fqcn][spec]["isIgnored"] ~= nil) -- no information about whether or not the spec is being ignored
	or not type(cache[fqcn][spec]["isIgnored"]) == "boolean"
	or not cache[fqcn][spec]["numTraitsPurchased"]
	or not type(cache[fqcn][spec]["numTraitsPurchased"]) == "number"
	or not cache[fqcn][spec]["thisLevelUnspentAP"]
	or not type(cache[fqcn][spec]["thisLevelUnspentAP"]) == "number"
	)
	
	return not isInvalid
	
end

-- Public methods
TotalAP.Cache.NewEntry = NewEntry
TotalAP.Cache.GetEntry = GetEntry
TotalAP.Cache.UpdateEntry = UpdateEntry
TotalAP.Cache.GetValue = GetValue
TotalAP.Cache.SetValue = SetValue
TotalAP.Cache.GetBankCache = GetBankCache
TotalAP.Cache.UpdateBankCache = UpdateBankCache
TotalAP.Cache.GetNumIgnoredSpecs = GetNumIgnoredSpecs
TotalAP.Cache.UnignoreAllSpecs = UnignoreAllSpecs
TotalAP.Cache.IsSpecIgnored = IsSpecIgnored
TotalAP.Cache.IsCurrentSpecIgnored = IsCurrentSpecIgnored
TotalAP.Cache.IgnoreSpec = IgnoreSpec
TotalAP.Cache.UnignoreSpec = UnignoreSpec
TotalAP.Cache.UpdateArtifactCache = UpdateArtifactCache
TotalAP.Cache.Initialise = Initialise
TotalAP.Cache.IsSpecCached = IsSpecCached
TotalAP.Cache.Validate = Validate
TotalAP.Cache.ValidateChar = ValidateChar
TotalAP.Cache.ValidateSpec = ValidateSpec
TotalAP.Cache.ValidateEntry = ValidateEntry


-- Keep these private
-- TotalAP.Cache.GetReference = GetReference
-- TotalAP.Cache.GetDefaults = GetDefaults
-- TotalAP.Cache.GetEntry = GetEntry


return TotalAP.Cache