-- Tests that are not yet implemented

--[[ Tests for Core\Cache.lua

Test_Cache_IsCharacterCached = {}
Test_Cache_IsCurrentCharacterCached = {}

Test_Cache_GetArtifactTier = {}
Test_Cache_SetArtifactTier = {}

Test_Cache_GetUnspentAP = {}
Test_Cache_SetUnspentAP = {}

Test_Cache_GetNumTraitsPurchased = {}
Test_Cache_SetNumTraitsPurchased = {}

--]]

--[[ Missing tests - These are not that important, because they are trivial or not used anywhere
	
	Core\Cache.lua:
	
	fqcn parameter (optional) for IgnoreSpec, UnignoreSpec, IsSpecIgnored, IsSpecCached
		Literally just defaults to using TotalAP.Utils.GetFQCN() if it is omitted (=nil), although it could change to use a proper validation in the future)
	
	
	Core\BankCache.lua:
	
	
	
	
	Core\InventoryCache.lua;
	
	
	
	 
--]]

--[[ Tests for Core\BankCache.lua

Test_BankCache_GetBankCache = {}
Test_BankCache_GetNumItems = {}
Test_BankCache_GetInBankAP = {}

Test_BankCache_Validate = {}
Test_BankCache_ValidateKey = {}

--]]

--[[ Tests for Core\InventoryCache.lua

Test_InventoryCache_GetInventoryCache = {}
Test_InventoryCache = {} -- TODO

--]]

-- Tests that are actually implemented
Test_Cache_Validate = {}
do

	local fqcn
	function Test_Cache_Validate:Setup()
		fqcn = TotalAP.Utils.GetFQCN()
	end

	-- Invalid caches should always return false as long as they're not filled with bogus data (in which case it can also be nil depending on how the individual entries validate)
	function Test_Cache_Validate:Test_Invalid()
	
		TotalArtifactPowerCache = {}
		luaunit.assertEquals(TotalAP.Cache.Validate(), false)
	
		TotalArtifactPowerCache = { "Random data", 42, {} }
		luaunit.assertEquals(TotalAP.Cache.Validate(), false)
	
		TotalArtifactPowerCache = { {}, {}, {} }
		luaunit.assertEquals(TotalAP.Cache.Validate(), false)
	
		TotalArtifactPowerCache[fqcn] = { { isIgnored = true }, { isIgnored = false}, { numTraitsPurchased = 42, isIgnored = false, artifactTier = 1234, thisLevelUnspentAP = 100000} } -- artifactTier is invalid = not a valid cache (this is testing for the post-7.3 bug)
		luaunit.assertEquals(TotalAP.Cache.Validate(), false)

		-- Actual example that was not detected
		TotalArtifactPowerCache = {
			["Swimmingly - Outland"] = {
				{
					["thisLevelUnspentAP"] = 12506270,
					["artifactTier"] = 1111,
					["numTraitsPurchased"] = 46,
					["isIgnored"] = false,
				}, -- [1]
				{
					["thisLevelUnspentAP"] = 1375148,
					["artifactTier"] = 2,
					["numTraitsPurchased"] = 43,
					["isIgnored"] = false,
				}, -- [2]
			},
		}
	
		luaunit.assertEquals(TotalAP.Cache.Validate(), false)
		
	end
	
	-- Valid caches should always return true upon validation
	function Test_Cache_Validate:Test_Valid()
	
		TotalArtifactPowerCache = {}
		TotalArtifactPowerCache[fqcn] = { { isIgnored = true }, { isIgnored = false}, { numTraitsPurchased = 42, isIgnored = false, artifactTier = 2, thisLevelUnspentAP = 100000} }
		luaunit.assertEquals(TotalAP.Cache.Validate(), true)
	
	end
	
	
end

Test_Cache_ValidateChar = {}
do
	-- If no parameter is given, nil should be returned 
	function Test_Cache_ValidateChar:Test_NoParameter()
	
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(nil), nil)
	
	end
	
	-- If an invalid parameter is given, nil should be returned as well
	function Test_Cache_ValidateChar:Test_InvalidParameter()
		
		-- Invalid parameters should return nil
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(nil), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(""), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar("Hi"), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(42), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar(function() end), nil)
		
		-- Empty or invalid tables should return nil or false (nil if they're not a valid char entry, and have #T = 0 instead of <num of cached specs> which would always be >= 1; false otherwise as they COULD be a spec entry and need to be checked)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( {} ), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( { "Some data"} ), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( { {}, {}, {} } ), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( { { numTraitsPurchased = 42 } } ), false)
		
		-- Actual example that was not detected
		local T = {
			{	
				["thisLevelUnspentAP"] = 12506270,
				["artifactTier"] = 1111, -- Not allowed
				["numTraitsPurchased"] = 46,
				["isIgnored"] = false,
			}, -- [1]
			{
				["thisLevelUnspentAP"] = 1375148,
				["artifactTier"] = 2,
				["numTraitsPurchased"] = 43,
				["isIgnored"] = false,
			}, -- [2]
		}
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( { T } ), false)
	
	
	end
	
	-- Valid tables should return true. They MUST contain the required fields (all those that have a default value), too!
	function Test_Cache_ValidateChar:Test_ValidParameter()

		local S = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
	
		local T1 = {
			S,
			S,
			S
		}
		local T2 = {
			{ numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1 }, -- missing IsIgnored -> should be added on Initialise(), but still return false while validating
			{ numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1513, isIgnored = false }, -- invalid artifact tier -> should be dropped on Initialise(), but still return false while validating
			S,
			S
		}
		local T3 = {
			S
		}
		local T4 = {
			S,
			S,
			S,
			S,
		}
		local T5 = {
			S,
			S
		}
	
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( T1 ), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( T2 ), false) -- It's a valid parameter, but not a complete cache entry because a required value is missing
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( T3 ), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( T4 ), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateChar( T5 ), true)
		
	end
	
end

Test_Cache_ValidateSpec = {}
do
	-- No parameters are given -> return nil
	function Test_Cache_ValidateSpec:Test_NoParameters()
	
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(), nil)
		
	end
	
	-- Invalid parameters are given -> return nil as well
	function Test_Cache_ValidateSpec:Test_InvalidParameters()
	
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(nil), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec( {} ), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec("Hey"), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(42), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(false), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(function() end), nil)
	
	end
	
	-- Parameter is a valid table, but may or may not contain invalid entries -> Return boolean value indicating whether or not it's a valid cache entry
	function Test_Cache_ValidateSpec:Test_ValidParameters()
	
		local S
		local function Reset() -- Reset entry to a valid state (so that invalid entries can be detected individually)
			S = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		end
		
		-- 1st round: Table is valid
		Reset()
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), true)
		
		-- 2nd round: Table is valid, but contains invalid entries -> return false
		S.randomKey = "Hey"
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		Reset()
		S.randomKey = nil
		S.numTraitsPurchased = "Hello, good sir. How can I help you?"
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		Reset()
		S.numTraitsPurchased = false
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		Reset()
		S.artifactTier = 668
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		Reset()
		
		-- Actual example that was not detected
		S =	{
					["thisLevelUnspentAP"] = 12506270,
					["artifactTier"] = 42, -- Just no!
					["numTraitsPurchased"] = 46,
					["isIgnored"] = false,
				} -- [1]
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		
		-- 3rd round: Table is valid and doesn't contain invalid entries, but some default values are missing -> return false
		S.numTraitsPurchased = 28
		S.isIgnored = nil
		luaunit.assertEquals(TotalAP.Cache.ValidateSpec(S), false)
		
	end
	
end

Test_Cache_ValidateEntry = {}
do
	-- If no parameters are given (both are invalid), nil should be returned
	function Test_Cache_ValidateEntry:Test_NoParameters()
		
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry(), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry(nil), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry(nil, nil), nil)
		
	end
	
	-- If one parameter is omitted or invalid (nil), nil should be returned
	function Test_Cache_ValidateEntry:Test_OneParameter()
		
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry(nil, "value"), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("key"), nil)
		
	end
	
	-- If the first parameter is omitted or not a valid key, nil should be returned
	function Test_Cache_ValidateEntry:Test_InvalidKey()

		luaunit.assertEquals(TotalAP.Cache.ValidateEntry(nil, 42), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("key", 42), nil)
		
	end
	
	-- If the second parameter is omitted or invalid (nil), nil should be returned as well
	function Test_Cache_ValidateEntry:Test_InvalidValue()
		
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("key"), nil)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("key", nil), nil)
		
	end
	
	-- If a valid key is given, the value should be checked and validated -> return boolean value indicating whether or not the given value is valid
	function Test_Cache_ValidateEntry:Test_TwoValidParameters()
	
		-- 1st round: correct values
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("thisLevelUnspentAP", 100), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("numTraitsPurchased", 54), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", 1), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", 2), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", true), true)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", false), true)
		
		-- 2nd round: invalid values
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("thisLevelUnspentAP", false), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("numTraitsPurchased", "Hello"), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", function(test) return test end), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", nil), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", 668), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("artifactTier", 1533), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", nil), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", "Hi"), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", function() end), false)
		luaunit.assertEquals(TotalAP.Cache.ValidateEntry("isIgnored", {}), false)
		
	end
	
end

Test_Cache_Initialise = {}
do
	-- If no saved (Cache) variable exist or anything saved in the Cache variable is invalid, it should be rebuilt from scratch (resulting in a valid, but "empty" cache for the currently logged in character). Ditto if not all specs are cached
	local fqcn, spec
	local R
	
	-- Run Cache initialisation routine and test suite immediately afterwards (all preparations need to be complete before this is called)
	local function RunTest()
	
		-- Run the initialisation routine proper
		TotalAP.Cache.Initialise()
		luaunit.assertEquals(TotalArtifactPowerCache, R)
--		dump(TotalArtifactPowerCache); dump(R)
	end
	
	function Test_Cache_Initialise:Setup()
	
		-- Make settings and some repeatedly-used data available to all tests
		fqcn = T.Utils.GetFQCN()
		spec = GetSpecialization()
		TotalAP.Settings.Initialise()
		
		-- Simulate first startup, where saved variables don't exist
		TotalArtifactPowerCache = nil
		R = {} -- Reset Result table
		
	end

	-- Cache wasn't initialised yet -> Create empty cache and add an entry for the currently logged in character (consisting of default values for all available specs)
	function Test_Cache_Initialise:Test_NoData()

		-- This is how a default entry should look (for the time being)
		local Entry = {
			["numTraitsPurchased"] = nil,
			["thisLevelUnspentAP"] = nil,
			["artifactTier"] = nil,
			["isIgnored"] = false
		}
		TotalArtifactPowerCache = nil -- unset
		R[fqcn] = { Entry, Entry, Entry}
		
		RunTest()
		-- Cache should be empty, but valid at this point (only consisting of default values for all specs)
		
		-- If for some reason the cache was only partially initialised, it should still result in the same table
		TotalArtifactPowerCache = {}
		RunTest()
		
		TotalArtifactPowerCache = { [fqcn] = {} }
		RunTest()
		
		TotalArtifactPowerCache = {}
		RunTest()
		
		
	end

	-- Existing cache has entries for invalid specs -> Not sure how this could even happen, but if it somehow did, those entries should just be dropped entirely
	function Test_Cache_Initialise:Test_InvalidSpecEntry()
	
		-- Create empty cache
		TotalAP.Cache.Initialise()
		R = TotalArtifactPowerCache
	
		-- Fill in some valid data
		TotalArtifactPowerCache[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		R[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		
		-- ... and this invalid entry
		TotalArtifactPowerCache[fqcn][7] = { "Some", "random", "data"} -- No class has more than 4 specs, so this is going to be wrong
		TotalArtifactPowerCache[fqcn][8] = { "Some", "other", "data"}
		
		RunTest()
		-- Cache should look exactly like before, minus the invalid spec tables
		
	end
	
	-- Existing cache has entries for invalid (obsolete) keys -> Remove the now-unused keys and drop the referenced table
	function Test_Cache_Initialise:Test_InvalidKey()
	
		-- Create empty cache
		TotalAP.Cache.Initialise()
			
		-- Fill in some valid data
		TotalArtifactPowerCache[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true } -- the other specs aren't valid here, but this will be rectified during Initialise()
		local Entry = { isIgnored = false }
		R[fqcn] = { Entry, Entry, Entry } -- this is just to store the default values for all specs (may be overwritten, but is required)
		R[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true } -- overwrite the current spec only (the other specs remain uninitialised, but valid)
		
		-- ... and add a bunch of invalid keys
		TotalArtifactPowerCache[fqcn][spec]["invalidKey"] = 42
		TotalArtifactPowerCache[fqcn][spec]["obsoleteKey"] = "BBQ"
		
		RunTest()
		-- Cache should look exactly like before, minus the invalid spec tables
	
	end
	
	-- Cache exists, but has some invalid data in it -> Replace invalid data with default values (if setting has any) or remove the entry altogether to maintain cache integrity (join valid cache entries with defaults)
	function Test_Cache_Initialise:Test_InvalidData1()
		
		-- Mess up a cache entry to test if it will be fixed automatically
		local function MessUpEntry(key)
			TotalArtifactPowerCache[fqcn][spec][key] = "Hello Kitty!" -- Moist certainly not a valid entry for any number-based entry, nor for boolean values :P
		end
		
		-- Mess up all the entries to test if they will be fixed automatically
		local function MessUpAllTheThings()
			local keys = { "numTraitsPurchased", "thisLevelUnspentAP", "artifactTier", "isIgnored"}
			
			for _, key in ipairs(keys) do -- Mess up stuff, badly
				MessUpEntry(key)
			end
		end
		
		-- Create empty cache
		TotalAP.Cache.Initialise()
		
		-- Set some arbitrary, but valid data
		TotalArtifactPowerCache[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		local Entry = { isIgnored = false }
		R[fqcn] = { Entry, Entry, Entry }
		R[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		
		RunTest()
		-- Cache is valid here
		
		-- Mess up all existing entries
		MessUpAllTheThings()

		-- Cache became corrupted -> is no longer valid
		R[fqcn][spec] = Entry
		
		RunTest()
		-- Cache should contain either default values or pre-existing, valid data only at this point, with invalid data having been dropped entirely
		
end
	
	function Test_Cache_Initialise:Test_InvalidData2()
	
		-- Create empty cache
		TotalAP.Cache.Initialise()
		
		local Entry = { isIgnored = false }
		
		R = {}
		R[fqcn] = { Entry, Entry, Entry }
		TotalArtifactPowerCache[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 42, isIgnored = true } -- invalid artifact tier -> must be detected!
		R[fqcn][spec] = { numTraitsPurchased = 28, thisLevelUnspentAP = 100, isIgnored = true }
		
		RunTest()
		
		-- Cache should have dropped the invalid entry
		
	end
	
	function Test_Cache_Initialise:Test_InvalidData3()
		
		-- Create empty cache
		TotalAP.Cache.Initialise()

		R = {}
		TotalArtifactPowerCache = {
			[fqcn] = {
				{
					["thisLevelUnspentAP"] = 12506270,
					["artifactTier"] = 1111, -- Just no!
					["numTraitsPurchased"] = 46,
					["isIgnored"] = false,
				}, -- [1]
				{
					["thisLevelUnspentAP"] = 1375148,
					["artifactTier"] = 2,
					["numTraitsPurchased"] = 43,
					["isIgnored"] = false,
				}, -- [2]
				{
					["thisLevelUnspentAP"] = 1375148,
					["artifactTier"] = 2,
					["numTraitsPurchased"] = 43,
					["isIgnored"] = false,
				}, -- [3]
			}
		}
		R = {
			[fqcn] = {
				{
					["thisLevelUnspentAP"] = 12506270,
					["numTraitsPurchased"] = 46,
					["isIgnored"] = false,
				}, -- [1]
				{
					["thisLevelUnspentAP"] = 1375148,
					["artifactTier"] = 2,
					["numTraitsPurchased"] = 43,
					["isIgnored"] = false,
				}, -- [2]
				{
					["thisLevelUnspentAP"] = 1375148,
					["artifactTier"] = 2,
					["numTraitsPurchased"] = 43,
					["isIgnored"] = false,
				}, -- [3]
			}
		}

		RunTest()
	
		-- Invalid artifactTier entry should be removed
	
	end

	-- Cache exists, but some of the crucial data (those settings which have a default value) is missing -> Add the missing settings with their default values while leaving the rest unchanged
	function Test_Cache_Initialise:Test_IncompleteData()

		-- Create empty cache
		TotalAP.Cache.Initialise()
		
		-- Add entries with missing defaults (for specs 2 and 3)
		TotalArtifactPowerCache[fqcn] = { { isIgnored = true }, {}, {} }
		R[fqcn] = { { isIgnored=true }, { isIgnored = false }, { isIgnored = false} }

		RunTest()
		-- Missing default values should now be added
		
	end
	
	-- Cache integrity is maintained -> Do nothing (as cache should be functioning normally in every situation)
	function Test_Cache_Initialise:Test_CompleteAndValidData()

		-- Create empty cache
		TotalAP.Cache.Initialise()
		
		local S1 =  { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 1, isIgnored = true }
		TotalArtifactPowerCache[fqcn] = { S1, S1, S1 }
		R[fqcn] = { S1, S1, S1 }
		
		RunTest()
		
		local S2 =  { numTraitsPurchased = 28, thisLevelUnspentAP = 100, artifactTier = 2, isIgnored = true }
		TotalArtifactPowerCache[fqcn] = { S2, S2, S2 }
		R[fqcn] = { S2, S2, S2 }
		
		RunTest()
		-- Nothing should have changed, really
	
	end
	
end



Test_Cache_IsSpecCached = {}
do

	local fqcn, spec
	function Test_Cache_IsSpecCached:Setup()
		fqcn = TotalAP.Utils.GetFQCN()
		spec = GetSpecialization()
	end
	
	-- If the cache wasn't initialised yet, it should always return false (as the spec is not cached either, obviously)
	function Test_Cache_IsSpecCached:Test_EmptyCache()
		
		TotalArtifactPowerCache = nil
		luaunit.assertEquals(TotalAP.Cache.IsSpecCached(spec), false)
	
	end
	
	-- If the cache exists, it should always return the IsIgnored value for the given spec
	function Test_Cache_IsSpecCached:Test_ValidCache()
	
		-- Add some arbitrary but valid data
		TotalArtifactPowerCache = { [fqcn] = { { isIgnored = false }, { isIgnored = true }, { isIgnored = false, numTraitsPurchased = 10, thisLevelUnspentAP = 1000, artifactTier = 2 } } }
		luaunit.assertEquals(TotalAP.Cache.IsSpecCached(1), false)
		luaunit.assertEquals(TotalAP.Cache.IsSpecCached(2), false)
		luaunit.assertEquals(TotalAP.Cache.IsSpecCached(3), true)
	
	end
	
end

Test_Cache_IsCurrentSpecCached = {}
do

	-- Since this is just an alias, it should always return the same as the more generic IsSpecCached(<current spec no>)
	function Test_Cache_IsCurrentSpecCached:Test_Alias()

		-- Create empty cache
		TotalAP.Cache.Initialise()
		
		-- Add some arbitrary but valid data
		local entries =  { { isIgnored = false, numTraitsPurchased = 10, thisLevelUnspentAP = 100, artifactTier = 2}, {}, { isIgnored = true}, "hi", 42,  function() end } -- some random entries: two are valid, one is cached and valid
		
		local fqcn = TotalAP.Utils.GetFQCN()
		local spec = GetSpecialization()
		for k, v in pairs(entries) do -- fill spec entry with data and test if it is cached/valid
		
			TotalArtifactPowerCache[fqcn][spec] = v
			luaunit.assertEquals(TotalAP.Cache.IsSpecCached(spec), TotalAP.Cache.IsCurrentSpecCached())

		end
		
		-- This is just an alias of IsSpecCached(GetSpecialization()) and should return the same as IsSpecCached()
			luaunit.assertEquals(TotalAP.Cache.IsSpecCached(GetSpecialization()), TotalAP.Cache.IsCurrentSpecCached())
		
	end
	
end


Test_Cache_IsSpecIgnored = {}
do
	
	local fqcn, spec
	function Test_Cache_IsSpecIgnored:Setup()
		
		TotalArtifactPowerCache = nil -- Reset cache
		TotalAP.Cache.Initialise() -- Create empty but valid cache
		fqcn = TotalAP.Utils.GetFQCN()
		spec = GetSpecialization()
		
	end

	-- If the cache entry is invalid, return nil
	function Test_Cache_IsSpecIgnored:Test_InvalidEntry()
	
		TotalArtifactPowerCache = nil
		-- Cache is not even initialised here
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), nil)
		
	end
	
	-- If no parameters are given, use current spec
	function Test_Cache_IsSpecIgnored:Test_NoParameters()
		
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(), false) -- default value is always false, and the cache has been initialised with it
		
	end
	
	-- If invalid parameters are given, return default value (= false)
	function Test_Cache_IsSpecIgnored:Test_InvalidParameters()
	
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored( {} ), nil) -- While this value is not saved/cached, it would be the initial value for any new entry
	
	end
	
	-- If the entry is valid and a valid integer parameter is given, return whether or not the spec is being ignored
	function Test_Cache_IsSpecIgnored:Test_ValidParameters()
	
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), false)
		TotalArtifactPowerCache[fqcn][spec]["isIgnored"] = true
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), true)
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(2), false)
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(3), false)
	
	end
	
end

Test_Cache_IsCurrentSpecIgnored = {}
do
	-- This pretty much just returns whatever IsSpecIgnored(GetSpecialization()) does at all times (it's kind of pointless to test this unless the functionality changes significantly)
	function Test_Cache_IsCurrentSpecIgnored:Test_Alias()
		
		TotalArtifactPowerCache = { [TotalAP.Utils.GetFQCN()] = { [GetSpecialization()] = { isIgnored = true} } }
		luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(GetSpecialization()), TotalAP.Cache.IsCurrentSpecIgnored())
		
	end
	
end

Test_Cache_IgnoreSpec = {}
do

	function Test_Cache_IgnoreSpec:Setup()
	
		TotalArtifactPowerCache = nil
		TotalAP.Cache.Initialise() -- all specs are now NOT ignored
	
	end
		
	-- If no parameters were given, the cache should not be altered in any way
	function Test_Cache_IgnoreSpec:Test_NoParameters()
		
		local function TestUnchanged(cache)
			
			TotalArtifactPowerCache = cache -- save to compare states (below)
			for i=1, GetNumSpecializations() do
				TotalAP.Cache.IgnoreSpec(i)
			end
			
			-- Cache still should be the same (that is, unchanged)
			luaunit.assertEquals(TotalArtifactPowerCache, cache)
		
		end
		
		-- Cache is nil
		TestUnchanged()
		
		-- Cache is <empty table>
		TestUnchanged( {} )
		
		-- Cache is <some valid cache>
		local fqcn = TotalAP.Utils.GetFQCN()
		local C = {}
		C[fqcn] = { { isIgnored = true }, { isIgnored = false}, { numTraitsPurchased = 42, isIgnored = false, artifactTier = 2, thisLevelUnspentAP = 100000} }
	
		TestUnchanged( C )
		
	end
	
	-- Invalid parameters should behave similar to no parameters -> don't alter cache
	function Test_Cache_IgnoreSpec:Test_InvalidParameter()
		
		local params = { {}, "Hey", 42, "",  function() end, true, false }
		
		local C
		for key, param in pairs(params) do -- Test parameter -> Since all are invalid, the cache should not be changed
		
			C = TotalArtifactPowerCache
			luaunit.assertEquals(TotalAP.Cache.IgnoreSpec(param))
			luaunit.assertEquals(TotalArtifactPowerCache, C) -- should be unchanged still
		
		end
		
	end
	
	-- Valid parameters should set the spec to ignored but not affect anything else
	function Test_Cache_IgnoreSpec:Test_ValidParameter()
		
		for spec=1, GetNumSpecializations() do -- Test parameter -> Since all are valid, the cache should reflect the changes
		
			C = TotalArtifactPowerCache
			luaunit.assertEquals(TotalAP.Cache.IgnoreSpec(spec))
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), true) -- should always be correct as the test ran prior to this
		
		end
		
	end
	
end

Test_Cache_UnignoreSpec = {}
do

	function Test_Cache_UnignoreSpec:Setup()
	
		TotalArtifactPowerCache = nil
		TotalAP.Cache.Initialise() -- all specs are now NOT ignored
	
	end

	-- If no parameters were given, the cache should not be altered in any way
	function Test_Cache_UnignoreSpec:Test_NoParameters()
		
		local function TestUnchanged(cache)
			
			TotalArtifactPowerCache = cache -- save to compare states (below)
			for i=1, GetNumSpecializations() do
				TotalAP.Cache.IgnoreSpec(i)
			end
			
			-- Cache still should be the same (that is, unchanged)
			luaunit.assertEquals(TotalArtifactPowerCache, cache)
		
		end
		
		-- Cache is nil
		TestUnchanged()
		
		-- Cache is <empty table>
		TestUnchanged( {} )
		
		-- Cache is <some valid cache>
		local fqcn = TotalAP.Utils.GetFQCN()
		local C = {}
		C[fqcn] = { { isIgnored = true }, { isIgnored = false}, { numTraitsPurchased = 42, isIgnored = false, artifactTier = 2, thisLevelUnspentAP = 100000} }
	
		TestUnchanged( C )
		
	end
	
	-- Invalid parameters should behave similar to no parameters -> don't alter cache
	function Test_Cache_UnignoreSpec:Test_InvalidParameter()
		
		local params = { {}, "Hey", 42, "",  function() end, true, false }
		
		local C
		for key, param in pairs(params) do -- Test parameter -> Since all are invalid, the cache should not be changed
		
			C = TotalArtifactPowerCache
			luaunit.assertEquals(TotalAP.Cache.IgnoreSpec(param))
			luaunit.assertEquals(TotalArtifactPowerCache, C) -- should be unchanged still
		
		end
		
	end

		-- Valid parameters should set the spec to nit ignored but not affect anything else
	function Test_Cache_UnignoreSpec:Test_ValidParameter()
		
		for spec=1, GetNumSpecializations() do -- Test parameter -> Since all are valid, the cache should reflect the changes
		
			-- Set them to ignored beforehand
			TotalAP.Cache.UnignoreSpec(spec)
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), false) -- kind of redundant as this was tested before
			
			-- And now set it to "not ignored"
			C = TotalArtifactPowerCache
			luaunit.assertEquals(TotalAP.Cache.UnignoreSpec(spec))
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), false) -- should always be correct as the test ran prior to this
		
		end
		
	end
	
end

Test_Cache_UnignoreAllSpecs = {}
do
	
	-- The cache should not be altered, but all specs should be reset to not being ignored (the default value)
	function Test_Cache_UnignoreAllSpecs:Test_NoParameters()
	
		-- The manual way: Ignore all specs, then unignore them, and make sure it worked properly

		TotalAP.Cache.Initialise() -- All specs are now NOT ignored
		local C -- used for the more elegant test (below)
	
		for spec=1, GetNumSpecializations() do -- Test all specs individually
	
			TotalAP.Cache.IgnoreSpec(spec)
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), true)
			
			-- All specs are now being ignored
			
			TotalAP.Cache.UnignoreSpec(spec)
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), false)
			C = TotalArtifactPowerCache -- storing the state of the cache after manually unignoring all specs (for comparison, below)
			
			-- All specs are now reset
			
			TotalAP.Cache.IgnoreSpec(spec)
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), true) -- redundant, I guess
			
		end
		
		-- Use the second method to see if the results are identical to the first (stored in the temporary Cache, C)
		TotalAP.Cache.UnignoreAllSpecs()
		
		-- All specs should now be unignored
		for spec=1, GetNumSpecializations() do -- Test all specs individually
	
			luaunit.assertEquals(TotalAP.Cache.IsSpecIgnored(spec), false) -- redundant, I guess
	
		end
	
		-- More elegant: Make sure this function behaves exactly the same as running IgnoreSpec on all specs by comparing the results
		
		-- Easily proven by comparing the state of the cache after each operation
		luaunit.assertEquals(TotalArtifactPowerCache, C)
		
	end
	
end

Test_Cache_GetNumIgnoredSpecs = {}
do

	-- While the API currently supports using the FQCN parameter, it's not really used anywhere
	function Test_Cache_GetNumIgnoredSpecs:Test_NoParameters()
		
		-- Cache hasn't been initialised -> 0 specs are ignored
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 0)	
		
		-- Initialise empty cache (no specs are ignored)
		TotalAP.Cache.Initialise()
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 0)
		
		-- Set some random specs to ignored
		TotalAP.Cache.IgnoreSpec(1)
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 1)
		
		TotalAP.Cache.IgnoreSpec(2)
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 2)
		
		TotalAP.Cache.IgnoreSpec(3)
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 3)
		
		TotalAP.Cache.UnignoreAllSpecs()
		luaunit.assertEquals(TotalAP.Cache.GetNumIgnoredSpecs(), 0)
		
	end
	
end



