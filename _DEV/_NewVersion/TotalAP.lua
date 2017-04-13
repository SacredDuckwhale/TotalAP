-- Libraries
local L = LibStub("AceLocale-3.0"):GetLocale("TotalAP"); -- Default locale = enGB (also US), most others are still TODO
local SharedMedia = LibStub("LibSharedMedia-3.0");  -- TODO: Not implemented yet... But "soon" (TM) -> allow styling of bars and font strings
local Masque = LibStub("Masque", true);


-- Shorthands
local aUI = C_ArtifactUI

-- Addon metadata (used for messages, mainly)
local addonName = ...;
local slashCommand = "/ap";
local addonVersion = GetAddOnMetadata(addonName, "Version");

-- Internal vars
local itemEffects, artifacts; -- Loaded from TotalArtifactPowerDB in LoadSettings(), for now
local tempItemLink, tempItemID, currentItemLink, currentItemID, currentItemTexture; -- used for bag scanning and tooltip display
local numItems, inBagsTotalAP, numTraitsAvailable, artifactProgressPercent = 0, 0, 0, 0; -- used for tooltip text

-- TODO: separate functions to return those numbers from the inventoryCache: GetNumInventoryItems, GetNumBankItems, GetInBagsAP, GetInBankAP, GetNumInventoryFish, GetNumBankFish, GetInBagsFishAP, GetInBankFishAP
-- TODO: Remove these variables afterwards

local numTraitsFontString, specIconFontStrings , TotalAP_UnderlightFontString = nil, {}, nil; -- Used for the InfoFrame. TODO: First is obsolete (removed and replaced with numSpecs spec icons?)
--local infoFrameStyle = 0; -- TODO: Indicates the way HUD info will be displayed (used for the InfroFrame -> presets)
local artifactProgressCache, underlightProgressCache = {}, {}; -- Used to calculate offspec (and ULA) artifact progress

-- SavedVars defaults (to check against, and load if corrupted/rendered invalid by version updates)
local defaultSettings =	{	
												-- General options
												
												-- controls what output will be printed in the chat frame
												debugMode = false,
												verbose = true,
												showLoginMessage = true,
														
											--	showNumItems = true, -- TODO: Deprecated
												--showProgressReport = true, -- TODO: Deprecated
												
												--showActionButton = true, -- TODO: Toggles everything. That should be changed
												
												--showButtonGlowEffect = true, -- TODO: actionButton
												
												actionButton = {
													enabled = true,
													showGlowEffect = true,
													minResize = 20,
													maxResize = 100,
												},

												-- Display options for the spec icons
												specIcons = {
													enabled = true,
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

--local TotalAPFrame, TotalAPInfoFrame, TotalAPButton, TotalAPSpec1IconButton, TotalAPSpec2conButton, TotalAPSpec3IconButton, TotalAPSpec4IconButton; -- UI elements/frames
local settings; -- savedVars
local inventoryItemCache; -- Stores data for all AP items and fish to correctly calculate progress from their snapshotted values (as spells scale with AK, but items are snapshotted when they are obtained)


-- Print debug messages (if enabled))(duh)
local function Debug(msg)
	if settings.debugMode then
		print(format("|c000072CA" .. "%s-Debug: " .. "|c00E6CC80%s", addonName, msg)); 
	end
end
		
-- Print regular addon messages (if enabled)
local function ChatMsg(msg)
	if settings.verbose then
		print(format("|c00CC5500" .. "%s: " .. "|c00E6CC80%s", addonName, msg)); -- TODO: Use addonName?
	end
end

 -- Format number as short (15365 = 15.3k etc.) -> All credit goes to Google and whoever wrote it on wowinterface (I think?). I did NOT reinvent the wheel
 local function Short(value,format) 
	if type(value) == "number" then
		local fmt
		if value >= 1000000000 or value <= -1000000000 then
			fmt = "%.1fb"
			value = value / 1000000000
		elseif value >= 10000000 or value <= -10000000 then
			fmt = "%.1fm"
			value = value / 1000000
		elseif value >= 1000000 or value <= -1000000 then
			fmt = "%.2fm"
			value = value / 1000000
		elseif value >= 100000 or value <= -100000 then
			fmt = "%.0fk"
			value = value / 1000
		elseif value >= 10000 or value <= -10000 then
			fmt = "%.1fk"
			value = value / 1000
		else
			fmt = "%d"
			value = math.floor(value + 0.5)
		end
		if format then
			return fmt:format(value)
		end
		return fmt, value
	else
		local fmt_a, fmt_b
		local a, b = value:match("^(%d+)/(%d+)$")
		if a then
			a, b = tonumber(a), tonumber(b)
			if a >= 1000000000 or a <= -1000000000 then
				fmt_a = "%.1fb"
				a = a / 1000000000
			elseif a >= 10000000 or a <= -10000000 then
				fmt_a = "%.1fm"
				a = a / 1000000
			elseif a >= 1000000 or a <= -1000000 then
				fmt_a = "%.2fm"
				a = a / 1000000
			elseif a >= 100000 or a <= -100000 then
				fmt_a = "%.0fk"
				a = a / 1000
			elseif a >= 10000 or a <= -10000 then
				fmt_a = "%.1fk"
				a = a / 1000
			end
			if b >= 1000000000 or b <= -1000000000 then
				fmt_b = "%.1fb"
				b = b / 1000000000
			elseif b >= 10000000 or b <= -10000000 then
				fmt_b = "%.1fm"
				b = b / 1000000
			elseif b >= 1000000 or b <= -1000000 then
				fmt_b = "%.2fm"
				b = b / 1000000
			elseif b >= 100000 or b <= -100000 then
				fmt_b = "%.0fk"
				b = b / 1000
			elseif b >= 10000 or b <= -10000 then
				fmt_b = "%.1fk"
				b = b / 1000
			end
			local fmt = ("%s/%s"):format(fmt_a, fmt_b)
			if format then
				return fmt:format(a, b)
			end
			return fmt, a, b
		else
			return value
		end
	end
end

-- Calculate the total number of purchaseable traits (using AP from both the equipped artifact and from AP tokens in the player's inventory)
local function GetNumAvailableTraits()
	
	if not aUI or not HasArtifactEquipped() then
		Debug("Called GetNumAvailableTraits, but the artifact UI is unavailable... Is an artifact equipped?");
		return 0;
	end
		
	local thisLevelUnspentAP, numTraitsPurchased = select(5, aUI.GetEquippedArtifactInfo());	
	local numTraitsAvailable = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(numTraitsPurchased, thisLevelUnspentAP + inBagsTotalAP); -- This is how many times the weapon can be leveled up with AP from bags AND already used (but not spent) AP from this level
	Debug(format("Called GetNumAvailableTraits -> %s new traits available!", numTraitsAvailable or 0));
	
	return numTraitsAvailable or 0;
end

-- Calculate progress towards next artifact trait (for the equipped artifact). TODO: Function GetArtifactProgressData -> unspentAP, numAvailableTraits, progressPercent
local function GetArtifactProgressPercent()
		
		--if not considerBags then considerBags = true; -- Only ignore bags if explicitly told so (i.e., for cache operations, chiefly)
		
		if not aUI or not HasArtifactEquipped() then
			Debug("Called GetArtifactProgressPercent, but the artifact UI is unavailable (is an artifact equipped?)...");
			return 0;
		end
	
		local thisLevelUnspentAP, numTraitsPurchased = select(5, aUI.GetEquippedArtifactInfo());	
		local nextLevelRequiredAP = aUI.GetCostForPointAtRank(numTraitsPurchased); 
		
		--if considerBags then -- TODO: This is ugly. I can do better, oh great one!
		local percentageOfCurrentLevelUp = (thisLevelUnspentAP + inBagsTotalAP) / nextLevelRequiredAP*100;
		Debug(format("Called GetArtifactProgressPercent -> Progress is: %s%% towards next trait!", percentageOfCurrentLevelUp or 0)); -- TODO: > 100% becomes inaccurate due to only using cost for THIS level, not next etc?
		return percentageOfCurrentLevelUp or 0;
	--	else 
		--	return thisLevelUnspentAP, nextLevelRequiredAP;
	--	end

end

-- Extract an item's name from its item link
local function GetItemNameFromLink(itemLink)
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, itemName = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return itemName or "";
end


-- Compares two tables, and replaces mismatching entries in t2 with those from t1 (with t2 and t2 being used recursively, while targetTable remains the original table reference)
-- targetTable will have mismatching entries replaced by those from t1[lastTableKey]
local function CompareTables(t1, t2, targetTable, lastTableKey)
   
   if not lastTableKey then lastTableKey = "<none>" end
   
   if type(t1) == "table" and type(t2) == "table" then
      for k, v in pairs(t1) do
         print("checking key, value pair:")
         print(k, v)
         if type(v) == "table" then
            -- lastTableKey = k
            CompareTables(v, t2[k], targetTable, k)
         else
            print("comparing values:")
            print(v, t2[k])
            if type(v) == type(t2[k]) then
               print("v eq t2[k]")
            else
               print("v not eq t2[k]")
               t2[k] = v
            end
         end
         
      end
      
   else
      print("comparing values:")
      print(t1, t2)
      if type(t1) == type(t2) then
         print("t1 eq t2")
      else
         print("t1 not eq t2")
         print("lastTableKey: " ..lastTableKey)
         targetTable[lastTableKey] = t1
      end
      
   end
   
end


-- Load default settings (will overwrite SavedVars)
local function RestoreDefaultSettings()

	TotalArtifactPowerSettings = defaultSettings;
	settings = TotalArtifactPowerSettings;
end

-- Verify saved variables and reset them in case something was corrupted/tampered with/accidentally screwed up while updating (using recursion)
-- TODO: Doesn't remove outdated SavedVars (minor waste of disk space, not a high priority issue I guess) as it checks the master table against savedvars but not the other way around
local function VerifySettings()
	
	settings = TotalArtifactPowerSettings;
	
	-- TODO: Optimise this, and add checks for 1.2 savedVars (bars etc)
	
	if settings == nil or not type(settings) == "table" then
		RestoreDefaultSettings();
		return false;
	end
	
	-- TODO: Actual verification routine here
--	return true;
	
	local masterTable, targetTable = defaultSettings, settings;
	
	CompareTables(masterTable, targetTable, targetTable, nil);
	-- Check default settings (= always up-to-date) against SavedVars

	return true;
	
end


-- Load saved vars and DB files, attempt to verify SavedVars
local function LoadSettings()
	
	-- Load item spell effects & spec artifact list from global (shared) DB
	itemEffects = TotalArtifactPowerDB["itemEffects"]; -- This isn't strictly necessary, as the DB is in the global namespace. However, it's better to not litter the code with direct references in case of future changes
	artifacts = TotalArtifactPowerDB["artifacts"]; -- Ditto
	underlightFish = TotalArtifactPowerDB["underlightFish"];
	
	-- Load previous inventory cache (if it was saved before)
	inventoryItemCache = TotalArtifactPowerCache or {};
	-- TODO: Bank
	
	-- Check & verify default settings before loading them
	settings = TotalArtifactPowerSettings;
	if not settings then 	-- Load default settings
		RestoreDefaultSettings(); 
	else -- check for types and proper values 
		if not VerifySettings() then
			ChatMsg(L["Settings couldn't be verified... Default values have been loaded."]);
		else
			Debug("SavedVars verified (and loaded) successfully.");
		end
	end

end



--TODO: functions GetNumBankItems, GetInBankAP, GetNumBankFish, GetInBankFishAP


local function GetNumInventoryItems()
	local numInventoryItems = 0;
	
	for k, v in pairs(inventoryItemCache) do
		if v ~= nil and not v["isFish"] then -- Skip empty slots and fish
			numInventoryItems = numInventoryItems + 1;
		end
	end
	
	return numInventoryItems;
end

local function GetInBagsAP()
	local inBagsAP = 0;
	
	for k, v in pairs(inventoryItemCache) do
		if v ~= nil and not v["isFish"] then -- Skip empty slots and fish
			inBagsAP = inBagsAP + v["amountAP"];
		end
	end
	
	return inBagsAP;
end

local function GetNumInventoryFish()
	local numInventoryFish = 0;
	
	for k, v in pairs(inventoryItemCache) do
		if v ~= nil and v["isFish"] then -- Skip empty slots and fish
			numInventoryFish = numInventoryFish + 1;
		end
	end
	
	return numInventoryFish;
end

local function GetInbagsFishAP()
	local inBagsFishAP = 0;
		for k, v in pairs(inventoryItemCache) do
		if v ~= nil and v["isFish"] then -- Skip empty slots and fish
			inBagsFishAP = inBagsFishAP + v["amountAP"];
		end
	end
	return inBagsFishAP;
end

-- Check for artifact power tokens in the player's bags 
 local function CheckBags()
 
	local bag, slot;
	numItems, inBagsTotalAP = 0, 0; -- Each scan has to reset the (global) counter used by the tooltip and update handlers
	
	-- Check all the items in bag against AP token LUT (via their respective spell effect = itemEffectsDB)to find matches
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			tempItemLink = GetContainerItemLink(bag, slot);

			if tempItemLink and tempItemLink:match("item:%d")  then
					tempItemID = GetItemInfoInstant(tempItemLink);
					local spellID = itemEffects[tempItemID];
				
				if tempItemID == 139390 then -- Artifact Research Note available for use; TODO: 7.1.5 catchup tokens?
					Debug("Found Artifact Research Notes in inventory -> Displaying them instead of AP items");
				
					currentItemLink = tempItemLink;
					currentItemID = tempItemID;
					currentItemTexture = GetItemIcon(currentItemID);
				
					Debug(format("Set currentItemTexture to %s", currentItemTexture));
					numItems = 1; -- will update to the correct amount once research notes have been used, anyway
					return true; -- Stop scanning and display this item instead
				end
				
				if IsEquippedItem(133755) and underlightFish[tempItemID] then -- Set current item to fish
					currentItemLink = tempItemLink;
					currentItemID = tempItemID;
					currentItemTexture = GetItemIcon(currentItemID);
				end
				
				-- TODO: Is this necessary? If ULA is equipped, shouldn't 
				if not IsEquippedItem(133755) and spellID then	-- Found AP token :D	
					numItems = numItems + 1
					
					-- Extract AP amount (after AK) from the description
					--TODO: BUG when applying AK -> spell description already updated, but items are actually snapshotted
					local spellDescription = GetSpellDescription(spellID); -- Always contains the AP number, as only AP tokens are in the LUT 
					local m = spellDescription:match("%s?(%d+%,?%.?%s?%d*)%s?");  -- Match pattern: <optional space><number | number separated by comma, point, or space> <optional space> (Should work for all locales due to BreakUpLargeNumbers being used in the UI)		
					m = string.gsub(string.gsub(m, "%,", ""), "%.", ""); -- Remove commas and points (to convert the value to an actual number)

				inBagsTotalAP = inBagsTotalAP + tonumber(m);
				
				-- Store current AP item in globals (to display in button, use via keybind, etc.)
				currentItemLink = tempItemLink;
				currentItemID = tempItemID;
				currentItemTexture = GetItemIcon(currentItemID);
				
				Debug(format("Set currentItemTexture to %s", currentItemTexture));
				
				Debug(format("Found item: %s (%d) with texture %d",	currentItemLink, currentItemID, currentItemTexture)); 
				end
			end
		end
	end
end


-- Toggle spell overlay (glow effect) on an action button
local function FlashActionButton(button, showGlowEffect, showAnts)
	
	if showGlowEffect == nil then showGlowEffect = true; end -- Default = enable glow if no arg was passed
	if showAnts == nil then showAnts = false; end -- Default = Disable ants (moving animation) on glow effect if no arg was passed
	
	-- TODO: Hide ants?
	if not button then
		Debug("Called FlashActionButton, but actionButton is nil. Abort, abort!");
		return false
	else
		if showGlowEffect then
			ActionButton_ShowOverlayGlow(button);
			
			-- if showAnts then
				-- button.overlay.ants:Show();
			-- else
				-- button.overlay.ants:Hide(); -- TODO: SetShow?
			-- end
			
		else
			ActionButton_HideOverlayGlow(button);
		end
	end
end	


-- Registers button with Masque
local function MasqueRegister(button, subGroup) 

		 if Masque then
		 
			 local group = Masque:Group(L["TotalAP - Artifact Power Tracker"], subGroup); 
			 group:AddButton(button);
			 Debug(format("Added button %s to Masque group %s.", button:GetName(), subGroup));
			 
		 end
end

-- Updates the style (by re-skinning) if using Masque, and keep button proportions so that it remains square
local function MasqueUpdate(button, subGroup)

	-- Keep button size proportional (looks weird if it isn't square, after all)
	local w, h = button:GetWidth(), button:GetHeight();
	if w > h then button:SetWidth(h) else button:SetHeight(w); end;

	 if Masque then
		 local group = Masque:Group(L["TotalAP - Artifact Power Tracker"], subGroup);
		 group:ReSkin();
		 Debug(format("Updated Masque skin for group: %s", subGroup));
	end
end


-- Check whether the equipped weapon is the active spec's actual artifact weapon
local function HasCorrectSpecArtifactEquipped()
	
	local _, _, classID = UnitClass("player"); -- 1 to 12
	local specID = GetSpecialization(); -- 1 to 4

	-- Check all artifacts for this spec
	Debug(format("Checking artifacts for class %d, spec %d", classID, specID));
	
	local specArtifacts = artifacts[classID][specID];
	
	-- Test for all artifacts that this spec can equip
	for k, v in pairs(specArtifacts) do
		local itemID = v[1]; -- TODO: Why did I want canOccupyOffhandSlot again? Seems useless now, remove it from DB\Artifacts.lua?
	
		-- Cancel if just one is missing
		if not IsEquippedItem(itemID) then
			Debug(format("Expected to find artifact weapon %s, but it isn't equipped", GetItemInfo(itemID) or "<none>"));
			return false 
		end
		
	end
	
	-- All checks passed -> Looks like the equipped weapon is in fact the class' artifact weapon 
	return true;
	
end


-- Update inventory cache (for AP items and ULA fish) 
local function UpdateInventoryCache()
	
	-- (Re)scan bags to see if a new item has been added, or a cached one removed
	--  { bag, slot, itemID, knowledgeLevel, amountAP, isFish }

		local bag, slot;
--numItems, inBagsTotalAP = 0, 0; -- Each scan has to reset the (global) counter used by the tooltip and update handlers
	
	-- Check all the items in bag and save them if they haven't been cached before
	for bag = 0, NUM_BAG_SLOTS do
	
		for slot = 1, GetContainerNumSlots(bag) do
			
			-- TODO: Cache current inventory and compare it with last saved cache values (to detect disruptions?)
			local currentCacheItem = inventoryItemCache[bag .. " " .. slot]; -- Caution: Can (and will) be nil if an item hasn't been cached yet for that slot
			
			local itemLink = GetContainerItemLink(bag, slot);
			if itemLink and itemLink:match("item:%d") then
				local itemID = GetItemInfoInstant(itemLink);
Debug("Testing item: " .. itemLink)
			end
				
				local currentKnowledgeLevel = aUI.GetArtifactKnowledgeLevel;
				
				local amountAP = 0; -- In case it's not an AP item (not that it matters, as it won't be cached otherwise)
				
				local spellID = itemEffects[itemID] or underlightFish[itemID];
				if spellID then	-- Found AP token :D	
					local spellDescription = GetSpellDescription(spellID); -- Always contains the AP number, as only AP tokens are in the LUT 
					local m = spellDescription:match("%s?(%d+%,?%.?%s?%d*)%s?");  -- Match pattern: <optional space><number | number separated by comma, point, or space> <optional space> (Should work for all locales due to BreakUpLargeNumbers being used in the UI)		
					amountAP = tonumber(string.gsub(string.gsub(m, "%,", ""), "%.", "")); -- Remove commas and points (to convert the value to an actual number)
Debug("Found match with spellID: " .. spellID)
				end
				
				local isFish = underlightFish[itemID] or true; -- if not in DB: nil or true -> false
				
				local currentItemEntry =  { ["itemID"] = itemID, ["knowledgeLevel"] = currentKnowledgeLevel, ["amountAP"] = amountAP, ["isFish"] = isFish }; 
					if itemID then Debug(format("Testing item: itemID %d, knowledgeLevel %d, amountAP %d, isFish %s", currentItemEntry["itemID"], currentItemEntry["knowledgeLevel"], currentItemEntry["amountAP"], tostring(currentItemEntry["isFish"]))); end
				if not currentCacheItem and itemID then -- Add item to cache
					inventoryItemCache[bag .. " " .. slot] = currentItemEntry;
Debug(format("Adding item to cache: itemID %d, knowledgeLevel %d, amountAP %d, isFish %s", currentItemEntry["itemID"], currentItemEntry["knowledgeLevel"], currentItemEntry["amountAP"], tostring(currentItemEntry["isFish"])));
				elseif itemID then -- Update cache item
					if inventoryItemCache[bag " " .. slot]["itemID"] ==  currentItemEntry["itemID"]  and inventoryItemCache[bag " " .. slot]["knowledgeLevel"] ==  currentItemEntry["knowledgeLevel"] and inventoryItemCache[bag " " .. slot]["amountAP"]  ==  currentItemEntry["amountAP"]  and inventoryItemCache[bag " " .. slot]["isFish"] ==  currentItemEntry["isFish"] then -- cached item hasn't changed TODO: Separate TableComparison function, this is for testing purposes only...
						Debug(format("Cached AP item in bag %d, slot %d found. No update is necessary. Cached data: item %d - AK %d - amountAP %d - isFish %s", bag, slot, itemID, currentKnowledgeLevel, amountAP, tostring(isFish)));
					else -- Something's different, possibly have to update cache now
						local cachedItemID, snapshotKnowledgeLevel, snapshotAP, cachedFishStatus = inventoryItemCache[bag .. " " .. slot]; -- This is what counts, even if the current level is already higher
						if cachedItemID ~= itemID then
							Debug("ItemID has changed!")
						end
						
						if snapshotKnowledgeLevel ~= currentKnowledgeLevel then
							Debug("Artifact knowledge level has changed!");
						end
						
						if snapshotAP ~= amountAP then
							Debug("AP amount has changed!");
						end
						
						if cachedFishStatus ~= isFish then
							Debug("Fish status has changed!");
						end


						Debug(format("Updating inventoryItemCache for bag %d, slot %d: Added item %d - AK %d - amountAP %d - isFish %s", bag, slot, cachedItemID, snapshotKnowledgeLevel, snapshotAP, tostring(isFish)));
					--	inventoryItemCache[bag " " .. slot] == { itemID,  }; 
					end
				else -- -- itemID is nil if bag slot was empty -> remove cache entry
				--	Debug(format("Clearing cache entry for bag %d, slot %d", bag, slot));
					inventoryItemCache[bag .. " " .. slot] = nil;
				end
				
			end
			
		end	
		
	end		
		
				-- -- Get current artifact knowledge level
			
			-- if tempItemLink and tempItemLink:match("item:%d")  then
				-- tempItemID = GetItemInfoInstant(tempItemLink);

					-- local spellID = itemEffects[tempItemID];
				
				-- if tempItemID == 139390 then -- Artifact Research Note available for use; TODO: 7.1.5 catchup tokens?
					-- Debug("Found Artifact Research Notes in inventory -> Displaying them instead of AP items");
				
					-- currentItemLink = tempItemLink;
					-- currentItemID = tempItemID;
					-- currentItemTexture = GetItemIcon(currentItemID);
				
					-- Debug(format("Set currentItemTexture to %s", currentItemTexture));
					-- numItems = 1; -- will update to the correct amount once research notes have been used, anyway
					-- return true; -- Stop scanning and display this item instead
				-- end
				
				-- if spellID then	-- Found AP token :D	
					-- numItems = numItems + 1
					
					-- -- Extract AP amount (after AK) from the description
					-- --TODO: BUG when applying AK -> spell description already updated, but items are actually snapshotted
					-- local spellDescription = GetSpellDescription(spellID); -- Always contains the AP number, as only AP tokens are in the LUT 
					-- local m = spellDescription:match("%s?(%d+%,?%.?%s?%d*)%s?");  -- Match pattern: <optional space><number | number separated by comma, point, or space> <optional space> (Should work for all locales due to BreakUpLargeNumbers being used in the UI)		
					-- m = string.gsub(string.gsub(m, "%,", ""), "%.", ""); -- Remove commas and points (to convert the value to an actual number)

				-- inBagsTotalAP = inBagsTotalAP + tonumber(m);
				
				-- -- Store current AP item in globals (to display in button, use via keybind, etc.)
				-- currentItemLink = tempItemLink;
				-- currentItemID = tempItemID;
				-- currentItemTexture = GetItemIcon(currentItemID);
				
				-- Debug(format("Set currentItemTexture to %s", currentItemTexture));
				
				-- Debug(format("Found item: %s (%d) with texture %d",	currentItemLink, currentItemID, currentItemTexture)); 
				-- end
			-- end
		-- end
	-- end
-- end

-- Update the cached progress for the currently equipped artifact
local function UpdateArtifactProgressCache()

local numSpecs = GetNumSpecializations();

	for i = 1, numSpecs do

		if not HasCorrectSpecArtifactEquipped() then -- also covers non-artifact weapons
			Debug("Attempted to cache artifact data, but the equipped artifact isn't the spec's artifact weapon");
			
		elseif IsEquippedItem(133755) then -- Update cache for ULA "spec" entry only
			
			underlightAnglerProgressCache["thisLevelUnspentAP"] = select(5, aUI.GetEquippedArtifactInfo()) or 0;
			underlightAnglerProgressCache["numTraitsPurchasedAP"] = select(6, aUI.GetEquippedArtifactInfo()) or 0;
			
			Debug(format("Updated artifactProgressCache for underlightAngler: %s traits purchased - %s unspent AP used already", underlightAnglerProgressCache["numTraitsPurchased"], underlightAnglerProgressCache["thisLevelUnspentAP"]));
			
		elseif i == GetSpecialization() then -- Only change cache for the current spec
				-- TODO: On login, this will be cached but not displays (since both is part of this function -> remove caching and call it before updating displays. That's better style, anyway)
				-- TODO function UpdateCache (to call before the other updates in UpdateEverything etc)
			 -- Update cached values for the formerly active specs (which are now inactive); TODO: Scan all artifacts in real time instead?
			 artifactProgressCache[i] = {
				["thisLevelUnspentAP"] =  select(5, aUI.GetEquippedArtifactInfo()) or 0, 
				["numTraitsPurchased"] = select(6, aUI.GetEquippedArtifactInfo()) or 0, -- 0 -> artifact UI not loaded yet? TODO (first login = lua error, but couldn't reproduce)
				-- ["numAvailableTraits"] = numTraitsAvailable,
				-- ["artifactProgressPercent"] = GetArtifactProgressPercent(false)
			};
			
			Debug(format("Updated artifactProgressCache for spec %d: %s traits purchased - %s unspent AP used already", i, artifactProgressCache[i]["numTraitsPurchased"], artifactProgressCache[i]["thisLevelUnspentAP"]));
		end
	end
 end
   

-- Update currently active specIcon, as well as the progress bar % fontStrings
local function UpdateSpecIcons()

	local numSpecs = GetNumSpecializations();
	
	-- Align background for spec icons (to the right of the InfoFrame)
	local inset, border = settings.specIcons.inset or 1, settings.specIcons.border or 1; -- TODO
	TotalAPSpecIconsBackgroundFrame:SetSize(settings.specIcons.size + 2 * border + 2* inset, numSpecs * (settings.specIcons.size + 2 * border + 2 * inset) + border);
	TotalAPSpecIconsBackgroundFrame:ClearAllPoints();

	local infoFrameWidth = 0;
	if TotalAPInfoFrame:IsShown() then	infoFrameWidth = TotalAPInfoFrame:GetWidth();	end -- In case it is hidden, the spec icons need to be moved to the left
		
	local reservedButtonWidth, reservedInfoFrameWidth = 0, 0;
	if TotalAPButton:IsShown() then
		reservedButtonWidth = TotalAPButton:GetWidth() + 5;
	end
	if TotalAPInfoFrame:IsShown() then
		reservedInfoFrameWidth = TotalAPInfoFrame:GetWidth() + 5;
	end
		
	TotalAPSpecIconsBackgroundFrame:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", reservedButtonWidth + reservedInfoFrameWidth, math.abs( max(settings.actionButton.maxResize, numSpecs * (settings.specIcons.size + 2 * border + 2 * inset) + border) -  TotalAPSpecIconsBackgroundFrame:GetHeight()) / 2);
--		TotalAPSpecIconsBackgroundFrame:SetPoint("TOPLEFT", TotalAPButton, "TOPRIGHT", 5 + infoFrameWidth + 5 - math.abs(TotalAPSpecIconsBackgroundFrame:GetWidth() - settings.specIcons.size) / 2, math.abs( TotalAPButton:GetHeight() -  TotalAPSpecIconsBackgroundFrame:GetHeight()) / 2);
	TotalAPSpecIconsBackgroundFrame:SetBackdropColor(0/255, 0/255, 0/255, 0.25); -- TODO
	
	for i = 1, numSpecs do

	   -- TODO: When pushed, the border still shows? Weird behaviour, and it looks ugly (but is gone while using Masque...)
	   --TotalAPSpecIconButtons[i].NormalTexture(nil)
	  
		-- TODO: BG for text and settings for font/size/alignment/sharedmedia
		TotalAPSpecHighlightFrames[i]:SetSize(settings.specIcons.size + 2 * inset, settings.specIcons.size + 2 * inset); -- TODO 4x or 2x?
		TotalAPSpecHighlightFrames[i]:ClearAllPoints();
		TotalAPSpecHighlightFrames[i]:SetPoint("TOPLEFT", TotalAPSpecIconsBackgroundFrame, "TOPLEFT", border, - (border + (i - 1) * (settings.specIcons.size + 3 * inset + border)));
	  
		-- Reposition spec icons
		TotalAPSpecIconButtons[i]:SetSize(settings.specIcons.size, settings.specIcons.size); -- TODO: settings.specIconSize. Also, 16 is too small for this?
		TotalAPSpecIconButtons[i]:ClearAllPoints();
		--TotalAPSpecIconButtons[i]:SetFrameStrata("HIGH");
		TotalAPSpecIconButtons[i]:SetPoint("TOPLEFT", TotalAPSpecHighlightFrames[i], "TOPLEFT", math.abs( TotalAPSpecHighlightFrames[i]:GetWidth() - settings.specIcons.size ) / 2, - math.abs( TotalAPSpecHighlightFrames[i]:GetHeight() - TotalAPSpecIconButtons[i]:GetHeight() ) / 2 );
      -- Hide default button template's visual peculiarities - I wanted just want a spec icon that can be pushed (to change specs) and styled (via Masque)
		
		-- Remove ugly borders. Masque will yell if I do this, though .(
		if not Masque then -- TODO: Some part of the border must still be there, as it glitches the spell overlay ? (ants texture perhaps?)
			TotalAPSpecIconButtons[i].Border:Hide();
		  --TotalAPSpecIconButtons[i]:SetBorder(nil);
			TotalAPSpecIconButtons[i]:SetPushedTexture(nil); 
		   --TotalAPSpecIconButtons[i].NormalTexture:Hide();
			TotalAPSpecIconButtons[i]:SetNormalTexture(nil); 
		end

		--	TotalAPSpecHighlightFrames[i]:SetPoint("BOTTOMRIGHT", TotalAPSpecIconButtons[i], "BOTTOMRIGHT", activeSpecIconBorderWidth, -activeSpecIconBorderWidth);
		-- TotalAPActiveSpecBackgroundFrame.texture = TotalAPActiveSpecBackgroundFrame:CreateTexture("bgTexture");
		--  TotalAPActiveSpecBackgroundFrame.texture:SetTexture(255/255, 128/255, 0/255, 1);


	if i == GetSpecialization() then
		TotalAPSpecHighlightFrames[i]:SetBackdropColor(255/255, 128/255, 0/255, 1); -- TODO: This isn't even working? Find a better backdrop texture, perhaps?
	else
		TotalAPSpecHighlightFrames[i]:SetBackdropColor(0/255, 0/255, 0/255, 0.75); -- TODO: Settings
	end
	   --(numSpecs * (specIconSize + 2 * inset) - TotalAPInfoFrame:GetHeight())/2 - (i-1) * (specIconSize + 2) + 2); -- TODO: consider settings.specIconSize to calculate position and spacing<<<!! dynamically
	   -- TODO: function UpdateSpecIconPosition or something to avoid duplicate code?
		
   
   -- TODO: Progress bar (background of percentage text?)) - but not here, silly. Belongs to UpdateInfoFrame
   
	-- Update font strings to display the latest info
	for k, v in pairs(artifactProgressCache) do
	
		-- Calculate available traits and progress using the cached data
		local numTraitsAvailable = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(v["numTraitsPurchased"],  v["thisLevelUnspentAP"] + inBagsTotalAP);
		local nextLevelRequiredAP = aUI.GetCostForPointAtRank(v["numTraitsPurchased"]); 
		local percentageOfCurrentLevelUp = (v["thisLevelUnspentAP"]  + inBagsTotalAP) / nextLevelRequiredAP*100;
		
		Debug(format("Calculated progress using cached data for spec %s: %d traits available - %d%% towards next trait using AP from bags", k, numTraitsAvailable, percentageOfCurrentLevelUp)); -- TODO: > 100% becomes inaccurate due to only using cost for THIS level, not next etc?
	
	local fontStringText = "---"; -- TODO: For specs where no artifact data was available only
		-- TODO: Identical names, local vs addon namespace -> this is confusing, change it
		if numTraitsAvailable > 0 then
			fontStringText = format("x%d", numTraitsAvailable);
			FlashActionButton(TotalAPSpecIconButtons[k], true);
		else
			fontStringText = format("%d%%", percentageOfCurrentLevelUp);
			FlashActionButton(TotalAPSpecIconButtons[k], false);
		end
		
		-- Make sure the text display is moving accordingly to the frames (or it will detach and look buggy)
		specIconFontStrings[k]:SetText(fontStringText);
		specIconFontStrings[k]:ClearAllPoints();
		specIconFontStrings[k]:SetPoint("TOPLEFT", TotalAPSpecHighlightFrames[k], "TOPRIGHT", settings.specIcons.border + 5,  settings.specIcons.border - math.abs(TotalAPSpecHighlightFrames[k]:GetHeight() - specIconFontStrings[k]:GetHeight()) / 2);
		Debug(format("Updating fontString for spec icon %d: %s", k, fontStringText));

	end
  

  --Debug(format("Expected fontString width: %.0f, wrapped width: %.0f, InfoFrame width: %.0f, texture width: %.0f", numTraitsFontString:GetStringWidth(), numTraitsFontString:GetWrappedWidth(), TotalAPInfoFrame:GetWidth(), TotalAPInfoFrame.texture:GetWidth()));

	
	-- numTraitsFontString:SetPoint("BOTTOMLEFT", TotalAPInfoFrame, "TOPLEFT", - TotalAPButton:GetWidth() - 5 + (TotalAPButton:GetWidth() - numTraitsFontString:GetStringWidth())/2,  10); -- Center text if possible (not too big -> bigger than the button)


   -- Hide if any of the anchor frames aren't visible. TODO: depending on settings/infoFrameStyle ? Create hide/show function that handles all the checks and hides individual parts accordingly
	
	 
	   -- Well, I guess they need to be reskinned = updated if Masque is used
	   MasqueUpdate(TotalAPSpecIconButtons[i], "specIcons");
	   

	   
   end
   
   	-- Underlight Angler equipped -> Show separate specIcon (with unique symbol)
	if IsEquippedItem(133755)  then
		
		-- Calculate available traits and progress using the cached data. TODO: Duplicate code :(
		local numTraitsAvailable = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(underlightProgressCache["numTraitsPurchased"],  underlightProgressCache["thisLevelUnspentAP"] + GetInBagsFishAP());
		local percentageOfCurrentLevelUp = (underlightProgressCache["thisLevelUnspentAP"]  + GetInBagsFishAP()) / aUI.GetCostForPointAtRank(underlightProgressCache["numTraitsPurchased"]) * 100; -- TODO: Bank
		
		Debug(format("Calculated progress using cached data for underlightAngler: %d traits available - %d%% towards next trait using AP from bags", k, numTraitsAvailable, percentageOfCurrentLevelUp)); -- TODO: > 100% becomes inaccurate due to only using cost for THIS level, not next etc?
	
		local fontStringText = "---"; -- TODO: For specs where no artifact data was available only
			-- TODO: Identical names, local vs addon namespace -> this is confusing, change it
		if numTraitsAvailable > 0 then
			fontStringText = format("x%d", numTraitsAvailable);
			FlashActionButton(TotalAP_UnderlightIconButton, true);
		else
			fontStringText = format("%d%%", percentageOfCurrentLevelUp);
			FlashActionButton(TotalAP_UnderlightIconButton, false);
		end
		
		-- Make sure the text display is moving accordingly to the frames (or it will detach and look buggy)
		TotalAP_UnderlightFontString:SetText(fontStringText);
		TotalAP_UnderlightFontString:ClearAllPoints();
		TotalAP_UnderlightFontString:SetPoint("TOPLEFT", TotalAP_UnderlightHighlightFrame, "TOPRIGHT", settings.specIcons.border + 5,  settings.specIcons.border - math.abs(TotalAP_UnderlightHighlightFrame:GetHeight() - TotalAP_UnderlightFontString:GetHeight()) / 2);
		Debug(format("Updating fontString for underlight icon: %s", fontStringText));

		TotalAP_UnderlightIconButton:Show();
		MasqueUpdate(TotalAP_UnderlightIconButton, "specIcons");
	else
		TotalAP_UnderlightIconButton:Hide();
	end 
  
	if settings.specIcons.enabled then
		TotalAPSpecIconsBackgroundFrame:Show();
	else
		TotalAPSpecIconsBackgroundFrame:Hide();
	end
	
end

-- Update InfoFrame -> contains AP bar/progress displays
local function UpdateInfoFrame()
	
	-- Display bars for cached specs only (not cached -> invisible/hidden)
	for k, v in pairs(artifactProgressCache) do
	
		local percentageUnspentAP = min(100, math.floor(v["thisLevelUnspentAP"] / aUI.GetCostForPointAtRank(v["numTraitsPurchased"]) * 100)); -- cap at 100 or bar will overflow
		local percentageInBagsAP = min(math.floor(inBagsTotalAP / aUI.GetCostForPointAtRank(v["numTraitsPurchased"]) * 100), 100 - percentageUnspentAP); -- AP from bags should fill up the bar, but not overflow it
		Debug(format("Updating percentage for bar display... spec %d: unspentAP = %s, inBags = %s" , k, percentageUnspentAP, percentageInBagsAP));
		
		local inset, border = settings.infoFrame.inset or 1, settings.infoFrame.border or 1; -- TODO

		-- TODO: Default textures seem to require scaling? (or not... tested a couple, but not all of them)
		-- TODO. Allow selection of these alongside potential SharedMedia ones (if they aren't included already)
		local defaultTextures = { 
																				   
																				   "Interface\\CHARACTERFRAME\\BarFill.blp",
																				   "Interface\\CHARACTERFRAME\\BarHighlight.blp",
																				   "Interface\\CHARACTERFRAME\\UI-BarFill-Simple.blp",
																				   "Interface\\Glues\\LoadingBar\\Loading-BarFill.blp",
																				   "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp",
																				   "Interface\\RAIDFRAME\\Raid-Bar-Hp-Bg.blp",
																				   "Interface\\RAIDFRAME\\Raid-Bar-Hp-Fill.blp",
																				   "Interface\\RAIDFRAME\\Raid-Bar-Resource-Background.blp",
																				   "Interface\\RAIDFRAME\\Raid-Bar-Resource-Fill.blp",
																				   "Interface\\TARGETINGFRAME\\BarFill2.blp",
																				   "Interface\\TARGETINGFRAME\\UI-StatusBar.blp",
																				   "Interface\\TARGETINGFRAME\\UI-TargetingFrame-BarFill.blp",
																				   "Interface\\TUTORIALFRAME\\UI-TutorialFrame-BreathBar.blp", -- FatigueBar also
																				   "Interface\\UNITPOWERBARALT\\Amber_Horizontal_Bgnd.blp",
																				   "Interface\\UNITPOWERBARALT\\Amber-Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\BrewingStorm_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Darkmoon_Horizontal_Bgnd.blp",
																				   
																				   "Interface\\UNITPOWERBARALT\\Darkmoon_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\DeathwingBlood_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Druid_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Party_Horizontal_Bgnd.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Party_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Player_Horizontal_Bgnd.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Player_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Target_Horizontal_Bgnd.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1Target_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic1_Horizontal_Bgnd.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic2_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\Generic3_Horizontal_Fill.blp",
																				   "Interface\\UNITPOWERBARALT\\StoneGuardJade_HorizontalFill.blp", -- also Cobalt, Amethyst, Jasper
																				   -- 32 textures
																				}
																	
		local barTexture = settings.infoFrame.barTexture or "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp";
		-- TODO: SharedMedia:Fetch("statusbar", settings.infoFrame.barTexture) or "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp"; -- TODO: Test default texture?

   --TotalAPProgressBars[i].texture:SetTexCoord(1/3, 1/3, 2/3, 2/3, 1/3, 1/3, 2/3, 2/3); -- TODO: Only necessary for some (which?) textures from the default interface, not SharedMedia ones?

   -- TODO: Update bars/position when button is resized or moved

		-- Empty Bar -> Displayed when artifact is cached, but the bars for unspent/inBagsAP don't cover everything (background)
		if not TotalAPProgressBars[k].texture then   
			TotalAPProgressBars[k].texture = TotalAPProgressBars[k]:CreateTexture();
		end
		
		TotalAPProgressBars[k].texture:SetAllPoints(TotalAPProgressBars[k]);
		TotalAPProgressBars[k].texture:SetTexture(barTexture);
		TotalAPProgressBars[k].texture:SetVertexColor(settings.infoFrame.progressBar.red/255, settings.infoFrame.progressBar.green/255, settings.infoFrame.progressBar.blue/255, settings.infoFrame.progressBar.alpha);
		TotalAPProgressBars[k]:SetSize(100, settings.infoFrame.barHeight); -- TODO: Variable height! Should be adjustable independent from specIcons (and resizable via shift/drag, while specIcons center automatically)
		TotalAPProgressBars[k]:ClearAllPoints();
		TotalAPProgressBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset, - ( (2 * k - 1)  * inset + k * border + (k - 1) * settings.infoFrame.barHeight));
		
		-- Bar 1 -> Displays AP used on artifact but not yet spent on any traits
		if not TotalAPUnspentBars[k].texture then   
			TotalAPUnspentBars[k].texture = TotalAPUnspentBars[k]:CreateTexture();
		end
		 
		TotalAPUnspentBars[k].texture:SetAllPoints(TotalAPUnspentBars[k]);
		TotalAPUnspentBars[k].texture:SetTexture(barTexture);
		if percentageUnspentAP > 0 then 
			TotalAPUnspentBars[k].texture:SetVertexColor(settings.infoFrame.unspentBar.red/255, settings.infoFrame.unspentBar.green/255, settings.infoFrame.unspentBar.blue/255, settings.infoFrame.unspentBar.alpha);  -- TODO: colors variable (settings -> color picker)
		else
			TotalAPUnspentBars[k].texture:SetVertexColor(0, 0, 0, 0); -- Hide vertexes to avoid graphics glitch
		end
		
		TotalAPUnspentBars[k]:SetSize(percentageUnspentAP, settings.infoFrame.barHeight);
		TotalAPUnspentBars[k]:ClearAllPoints();
		TotalAPUnspentBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset, - ( (2 * k - 1)  * inset + k * border + (k - 1) * settings.infoFrame.barHeight)) ;
		
		-- Bar 2 -> Displays AP available in bags
		-- TODO: Better naming of these things, TotalAP_InBagsBar? TotalAP.InBagsBar? inBagsBar?  etc
		if not TotalAPInBagsBars[k].texture  then   
		  TotalAPInBagsBars[k].texture = TotalAPInBagsBars[k]:CreateTexture();
		end
																				   
		TotalAPInBagsBars[k].texture:SetAllPoints(TotalAPInBagsBars[k]);
		TotalAPInBagsBars[k].texture:SetTexture(barTexture);
		
		if percentageInBagsAP > 0 then 
			TotalAPInBagsBars[k].texture:SetVertexColor(settings.infoFrame.inBagsBar.red/255, settings.infoFrame.inBagsBar.green/255, settings.infoFrame.inBagsBar.blue/255, settings.infoFrame.inBagsBar.alpha);
		else
			TotalAPInBagsBars[k].texture:SetVertexColor(0, 0, 0, 0); -- Hide vertexes to avoid graphics glitch
		end
		
		TotalAPInBagsBars[k]:SetSize(percentageInBagsAP, settings.infoFrame.barHeight);
		TotalAPInBagsBars[k]:ClearAllPoints();
		TotalAPInBagsBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset + TotalAPUnspentBars[k]:GetWidth(), - ( (2 * k - 1)  * inset + k * border + (k - 1) * settings.infoFrame.barHeight));

	end

	-- Align info frame so that it always stays next to the action button (particularly important during resize and scaling operations)
	local border, inset = settings.infoFrame.border or 1, settings.infoFrame.inset or 1; -- TODO
	TotalAPInfoFrame:SetSize(100 + 2 * border + 2 * inset, 2 * border + (settings.infoFrame.barHeight + 2 * inset + border) * GetNumSpecializations()); -- info frame height = info frame border + (spec icon height + spec icon spacing) * numSpecs. TODO: arbitrary width/height (scaling) vs 
	--arbitrary width/height (scaling) vs fixed, settings?

	TotalAPInfoFrame:ClearAllPoints(); 
	
	local reservedButtonWidth = 0;
	if TotalAPButton:IsShown() then 
		reservedButtonWidth = TotalAPButton:GetWidth() + 5; -- TODO: 5 = spacing? (settings)
	end
	--TotalAPInfoFrame:SetPoint("TOPLEFT", TotalAPButton, "TOPRIGHT", 5,  (TotalAPInfoFrame:GetHeight() - TotalAPButton:GetHeight()) / 2); 
		TotalAPInfoFrame:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", reservedButtonWidth,  math.abs(TotalAPInfoFrame:GetHeight() - settings.actionButton.maxResize) / 2); 
	
	--TotalAPInfoFrame:SetPoint("LEFT", TotalAPButton, "RIGHT", 5, 0); 
	--TotalAPInfoFrame:SetPoint("BOTTOMRIGHT", TotalAPButton, 2 * TotalAPButton:GetWidth() + 5, 0);

	
	-- TODO: Show AP amount as well as any other tooltip information, optional via settings

	-- Underlight Angler detected -> Show separate AP bar (TODO: Hide the others?)
	 if IsEquippedItem(133755) then -- TODO. Duplicate code... Got to find a more elegant way?
		-- TotalAP_UnderlightProgressBar
		-- TotalAP_UnderlightUnspentBar
		-- TotalAP_UnderlightInBagsBar
		
		local percentageUnspentAP = min(100, math.floor(underlightProgressCache["thisLevelUnspentAP"] / aUI.GetCostForPointAtRank(underlightProgressCache["numTraitsPurchased"]) * 100)); -- cap at 100 or bar will overflow
		local percentageInBagsAP = min(math.floor(GetInBagsFishAP / aUI.GetCostForPointAtRank(underlightProgressCache["numTraitsPurchased"]) * 100), 100 - percentageUnspentAP); -- AP from bags should fill up the bar, but not overflow it
		Debug(format("Updating percentage for bar display... underlight: unspentAP = %s, inBags = %s" , percentageUnspentAP, percentageInBagsAP));
		
		local inset, border = settings.infoFrame.inset or 1, settings.infoFrame.border or 1; -- TODO						
		local barTexture = settings.infoFrame.barTexture or "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp";

		-- Empty Bar -> Displayed when artifact is cached, but the bars for unspent/inBagsAP don't cover everything (background)
		if not TotalAP_UnderlightProgressBar.texture then   
			TotalAP_UnderlightProgressBar.texture = TotalAP_UnderlightProgressBar:CreateTexture();
		end
		
		TotalAP_UnderlightProgressBar.texture:SetAllPoints(TotalAP_UnderlightProgressBar);
		TotalAP_UnderlightProgressBar.texture:SetTexture(barTexture);
		TotalAP_UnderlightProgressBar.texture:SetVertexColor(settings.infoFrame.progressBar.red/255, settings.infoFrame.progressBar.green/255, settings.infoFrame.progressBar.blue/255, settings.infoFrame.progressBar.alpha);
		TotalAP_UnderlightProgressBar:SetSize(100, settings.infoFrame.barHeight); -- TODO: Variable height! Should be adjustable independent from specIcons (and resizable via shift/drag, while specIcons center automatically)
		TotalAP_UnderlightProgressBar:ClearAllPoints();
		TotalAP_UnderlightProgressBar:SetPoint("TOPLEFT", TotalAPInfoFrame, "BOTTOMLEFT", 1 + inset, - ( 5 + border + 2 *  inset )); -- TODO: 5 = spacing (settings)
		
		-- Bar 1 -> Displays AP used on artifact but not yet spent on any traits
		if not TotalAP_UnderlightUnspentBar.texture then   
			TotalAP_UnderlightUnspentBar.texture = TotalAP_UnderlightUnspentBar:CreateTexture();
		end
		 
		TotalAP_UnderlightUnspentBar.texture:SetAllPoints(TotalAP_UnderlightUnspentBar);
		TotalAP_UnderlightUnspentBar.texture:SetTexture(barTexture);
		if percentageUnspentAP > 0 then 
			TotalAP_UnderlightUnspentBar.texture:SetVertexColor(settings.infoFrame.unspentBar.red/255, settings.infoFrame.unspentBar.green/255, settings.infoFrame.unspentBar.blue/255, settings.infoFrame.unspentBar.alpha);  -- TODO: colors variable (settings -> color picker)
		else
			TotalAP_UnderlightUnspentBar.texture:SetVertexColor(0, 0, 0, 0); -- Hide vertexes to avoid graphics glitch
		end
		
		TotalAP_UnderlightUnspentBar:SetSize(percentageUnspentAP, settings.infoFrame.barHeight);
		TotalAP_UnderlightUnspentBar:ClearAllPoints();
		TotalAP_UnderlightUnspentBar:SetPoint("TOPLEFT", TotalAPInfoFrame, "BOTTOMLEFT", 1 + inset, - ( 5 + border + 2 *  inset )) ;
		
		-- Bar 2 -> Displays AP available in bags
		-- TODO: Better naming of these things, TotalAP_InBagsBar? TotalAP.InBagsBar? inBagsBar?  etc
		if not TotalAP_UnderlightInBagsBar.texture  then   
		  TotalAP_UnderlightInBagsBar.texture = TotalAP_UnderlightInBagsBar:CreateTexture();
		end
																				   
		TotalAP_UnderlightInBagsBar.texture:SetAllPoints(TotalAP_UnderlightInBagsBar);
		TotalAP_UnderlightInBagsBar.texture:SetTexture(barTexture);
		
		if percentageInBagsAP > 0 then 
			TotalAP_UnderlightInBagsBar.texture:SetVertexColor(settings.infoFrame.inBagsBar.red/255, settings.infoFrame.inBagsBar.green/255, settings.infoFrame.inBagsBar.blue/255, settings.infoFrame.inBagsBar.alpha);
		else
			TotalAP_UnderlightInBagsBar.texture:SetVertexColor(0, 0, 0, 0); -- Hide vertexes to avoid graphics glitch
		end
		
		TotalAP_UnderlightInBagsBar:SetSize(percentageInBagsAP, settings.infoFrame.barHeight);
		TotalAP_UnderlightInBagsBar:ClearAllPoints();
		TotalAP_UnderlightInBagsBar:SetPoint("TOPLEFT", TotalAPInfoFrame, "BOTTOMLEFT", 1 + inset + TotalAP_UnderlightUnspentBar:GetWidth(), - ( 5 + border + 2 *  inset ));
 -- TODO: height/width formulae can be reused... 
 
 
	 end 
	
		
	--  Only show when settings allow it
	if settings.infoFrame.enabled then TotalAPInfoFrame:Show();
	else TotalAPInfoFrame:Hide(); end
	 
end

-- Updates the action button whenever necessary to re-scan for AP items
local function UpdateActionButton()

	-- Also only show button if AP items were found, an artifact weapon is equipped in the first place, settings allow it, addons aren't locked from the player being in combat, and the artifact UI is available
	if (GetNumInventoryItems() > 0 or GetNumInventoryFish() > 0) and not InCombatLockdown() and settings.actionButton.enabled and currentItemID and aUI and (HasCorrectSpecArtifactEquipped() or IsEquippedItem(133755)) then
	
		currentItemTexture = GetItemIcon(currentItemID) or "";
		TotalAPButton.icon:SetTexture(currentItemTexture);
		Debug(format("Set currentItemTexture to %s", currentItemTexture));
	
		local itemName = GetItemInfo(currentItemLink) or "";
		if itemName == "" then -- item isn't cached yet -> skip update until the next BAG_UPDATE_DELAYED (should only happen after a fresh login, when for some reason there are two subsequent BUD events)
			Debug("itemName not cached yet. Skipping this update...");
			return false;
		end

		Debug(format("Current item bound to action button: %s = % s", itemName, currentItemLink));
		
		TotalAPButton:SetAttribute("type", "item");
		TotalAPButton:SetAttribute("item", itemName);
		
		Debug(format("Update changed item bound to action button: %s = % s", itemName, currentItemLink));
		
		MasqueUpdate(TotalAPButton, "itemUseButton");
		
		
		TotalAPButton:ClearAllPoints();
	--	TotalAPButton:SetPoint("TOPLEFT", TotalAPAnchorFrame, "TOPLEFT", 0, - math.abs(TotalAPButton:GetHeight() - TotalAPAnchorFrame:GetHeight()) / 2);
		TotalAPButton:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", 0, math.abs(settings.actionButton.maxResize - TotalAPButton:GetHeight()) / 2);
		
		
		-- Transfer cooldown animation to the button (would otherwise remain static when items are used, which feels artificial)
		local start, duration, enabled = GetItemCooldown(currentItemID)
		if duration > 0 then
				TotalAPButton.cooldown:SetCooldown(start, duration)
		end
	
		-- Display tooltip when mouse hovers over the action button
		if TotalAPButton:IsMouseOver() then 
			GameTooltip:SetHyperlink(currentItemLink);
		end
		
		-- Update available traits and trigger spell overlay effect if necessary
		numTraitsAvailable = GetNumAvailableTraits(); 
		if settings.actionButton.showGlowEffect and numTraitsAvailable > 0 or currentItemID == 139390 then -- research notes -> always flash regardless of current progress
			FlashActionButton(TotalAPButton, true);
			Debug("Activating button glow effect while processing UpdateActionButton...");
		else
			FlashActionButton(TotalAPButton, false);
			Debug("Deactivating button glow effect while processing UpdateActionButton...");
		end
		
		-- Show after everything is done, so the spell overlay doesn't "flicker" visibly
		TotalAPButton:Show();
	else
		TotalAPButton:Hide();
		Debug("Hiding action button after processing UpdateActionButton");
	end

	-- -- Underlight Angler detected -> Replace AP items with fish for useButton and spell overlay criteria
	-- if IsEquippedItem(133755) and GetNumInventoryFish() > 0 and not InCombatLockdown() and settings.actionButton.enabled and aUI then 
		
	-- else
		
	-- end
	
end	

-- Update anchor frame -> Decide whether to hide or show it, mainly
local function UpdateAnchorFrame()
	-- TODO. Right now, this is done via OnScript event handlers in CreateAnchorFrame, which might not be the best way
end

-- Update ALL the info! It should still be possible to only update individual parts, hence the separation here
local function UpdateEverything()
	
		UpdateAnchorFrame();
		UpdateActionButton();
		UpdateInventoryCache();
		UpdateArtifactProgressCache();
		UpdateInfoFrame();
		UpdateSpecIcons();
		
		--TotalAPAnchorFrame:Show();	
	--else -- Don't update the cache etc, or it might screw things up
	--	TotalAPAnchorFrame:Hide();
--	end	
end


-- Initialise spec icons and active/inactive spec indicators
local function CreateSpecIcons()
	
	-- Create spec icons for all of the classes specs (min 2  => Demon Hunter, max 4 => Druid)
	local numSpecs = GetNumSpecializations(); -- TODO: dual spec -> GetNumSpecGroups? Should be obsolete in Legion
	Debug(format("Available specs: %d, specGroups: %d", numSpecs, GetNumSpecGroups()));

	-- Create background for the spec icons and their active/inactive highlight frames
	TotalAPSpecIconsBackgroundFrame = CreateFrame("Frame", "TotalAPSpecIconsBackgroundFrame", TotalAPAnchorFrame);
	--TotalAPSpecIconsBackgroundFrame:SetClampedToScreen(true);
	TotalAPSpecIconsBackgroundFrame:SetFrameStrata("BACKGROUND");
	TotalAPSpecIconsBackgroundFrame:SetBackdrop(
		{
			bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND.BLP", 
				-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
				 tile = true, tileSize = 18, edgeSize = 18, 
				--insets = { left = 1, right = 1, top = 1, bottom = 1 }
		}
	);
	
	
	
	-- Create active/inactive spec highlight frames
	TotalAPSpecIconButtons, TotalAPSpecHighlightFrames = {}, {};
	for i = 1, numSpecs do
		
		local _, specName = GetSpecializationInfo(i);
		
			TotalAPSpecHighlightFrames[i] = CreateFrame("Frame", "TotalAPSpec" .. i .. "HighlightFrame", TotalAPSpecIconsBackgroundFrame); -- TODO: Rename var, and frame
		--	TotalAPSpecHighlightFrames[i]:SetClampedToScreen(true);
		--TotalAPSpecHighlightFrames[i]:SetFrameStrata("BACKGROUND");
			
			TotalAPSpecHighlightFrames[i]:SetBackdrop(
				{
					bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND.BLP", 
				-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
				 tile = true, tileSize = 18, edgeSize = 18, 
				--insets = { left = 1, right = 1, top = 1, bottom = 1 }
				}
			);
		
		--Debug(format("Created specIcon for spec %d: %s ", i, specName));
		
		TotalAPSpecIconButtons[i] = CreateFrame("Button", "TotalAPSpecIconButton" .. i, TotalAPSpecHighlightFrames[i], "ActionButtonTemplate", "SecureActionButtonTemplate");
		TotalAPSpecIconButtons[i]:SetFrameStrata("MEDIUM"); -- I don't like this, but Masque screws with the regular parent -> child draw order somehow
		
		specIconFontStrings[i] = TotalAPSpecIconButtons[i]:CreateFontString("TotalAPSpecIconFontString" .. i, "OVERLAY", "GameFontNormal"); -- TODO: What frame as parent? There isn't really one other than the respective icon?
		
		TotalAPSpecIconButtons[i]:SetScript("OnClick", function(self, button) -- When clicked, change spec accordingly to the button's icon

			-- Hide border etc again (for some reason it will show if a button is clicked, until the next update that disables them). Masque obviously doesn't like this at all.
			if not Masque then TotalAPSpecIconButtons[i]:SetNormalTexture(nil); end
		
			-- Change spec as per the player's selection (if it isn't active already)
			if GetSpecialization() ~= i then
				Debug(format("Current spec: %s - Changing spec to: %d (%s)", GetSpecialization(), i, specName)); -- not in combat etc
				SetSpecialization(i);
			end
	end);
		
		TotalAPSpecIconButtons[i]:SetScript("OnEnter", function(self, button) -- On mouseover, show message that spec can be changed by clicking (unless it's the currently active spec)
		
			-- Show tooltip "Click to change spec" or sth. TODO
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
				local _, specName = GetSpecializationInfo(i);
				GameTooltip:SetText(format(L["Specialization: %s"], specName), nil, nil, nil, nil, true);
				if i == GetSpecialization() then 
					GameTooltip:AddLine(L["This spec is currently active"], 0/255, 255/255, 0/255);
				else
					GameTooltip:AddLine(L["Click to activate"],  0/255, 255/255, 0/255);
				end	
				GameTooltip:Show();
		end)
		
		TotalAPSpecIconButtons[i]:SetScript("OnLeave", function(self, button)
			GameTooltip:Hide();
		end);
		
		-- TODO: Ordering so that main spec (active) is first? Hmm. Maybe an option to consider only some specs / set a main spec?
		
	-- TODO: What for chars below lv10? They don't have any spec.	  	if spec then -- no spec => nil (below lv10 -> shouldn't matter, as no artifact weapon equipped means everything will be hidden regardless of the player's spec)
	--local spec = GetSpecialization();
	--	local classDisplayName, classTag, classID = UnitClass("player");
		
		-- Set textures (only needs to be done once, as specs are generally static)
		local _, specName, _, specIcon, _, specRole = GetSpecializationInfo(i);
		TotalAPSpecIconButtons[i].icon:SetTexture(specIcon);
		Debug(format("Setting specIcon texture for spec %d (%s): |T%s:%d|t", i, specIcon,  specIcon, settings.specIconSize));
		
		-- register, enable etc TODO

		-- TODO: Only show buttons, enable click features etc. for specs that actually exist
		-- TODO: Align properly, 2-3-4 specs = center vertically

		
		--TotalAPSpecIconButtons[i]:SetFrameStrata("MEDIUM");
		--TotalAPSpecIconButtons[i]:SetClampedToScreen(true);
	
		--TotalAPSpecIconButtons[i]:ClearAllPoints();
	--	TotalAPSpecIconButtons[i]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPRIGHT", 5, 0 - (i-1) * (settings.specIconSize + 2)); -- TODO: consider settings.specIconSize to calculate position and spacing dynamically, also depnding on number of specs to center them vertically: size*numspecs = totalSize; infoframeSize
		--Debug(format("specIconButton %d -> SetPoint to %d, %d", i, 5, 0 - (i-1) * (settings.specIconSize + 2)));
		
		--TotalAPSpecIconButtons[i]:Show();
		
		-- TODO: Should they be draggable? If so, background frame, highlights, icons? Which?
		
		
		
		MasqueRegister(TotalAPSpecIconButtons[i], "specIcons");
		

	end

	TotalAP_UnderlightHighlightFrame = CreateFrame("Frame", "TotalAP_UnderlightHighlightFrame", TotalAPSpecIconsBackgroundFrame); 
	TotalAP_UnderlightHighlightFrame:SetBackdrop(
		{
			bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND.BLP", 
		-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		 tile = true, tileSize = 18, edgeSize = 18, 
		-- insets = { left = 1, right = 1, top = 1, bottom = 1 }
		}
	);
		
	TotalAP_UnderlightIconButton = CreateFrame("Button", "TotalAP_UnderlightIconButton", TotalAP_UnderlightHighlightFrame, "ActionButtonTemplate", "SecureActionButtonTemplate");
	TotalAP_UnderlightIconButton:SetFrameStrata("MEDIUM"); -- I don't like this, but Masque screws with the regular parent -> child draw order somehow
	
	TotalAP_UnderlightFontString = TotalAP_UnderlightIconButton:CreateFontString("TotalAP_UnderlightFontString", "OVERLAY", "GameFontNormal"); -- TODO: What frame as parent? There isn't really one other than the respective icon?
	
	TotalAP_UnderlightIconButton:SetScript("OnClick", function(self, button) -- When clicked, change spec accordingly to the button's icon

	-- Hide border etc again (for some reason it will show if a button is clicked, until the next update that disables them). Masque obviously doesn't like this at all.
	if not Masque then TotalAP_UnderlightIconButton:SetNormalTexture(nil); end

	-- TODO: Equip/unequip artifact or some other useful functionality? (might be a PROTECTED function though)

	end);
		
	TotalAP_UnderlightIconButton:SetScript("OnEnter", function(self, button) -- On mouseover, show message that spec can be changed by clicking (unless it's the currently active spec)
	
		-- TODO: Show tooltip "Click to change spec" or sth. 
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
		
		--	GameTooltip:SetText(format(L["Underlight Angler"]), nil, nil, nil, nil, true);
			if  IsEquippedItem(133755) then 
				GameTooltip:AddLine(L["This artifact is currently equipped"], 0/255, 255/255, 0/255);
		--	else
				--GameTooltip:AddLine(L["Click to equip"],  0/255, 255/255, 0/255);
			end	
			GameTooltip:Show();
	end)
		
		TotalAP_UnderlightIconButton:SetScript("OnLeave", function(self, button)
			GameTooltip:Hide();
		end);

		TotalAP_UnderlightIconButton.icon:SetTexture("Interface\\Icons\\inv_misc_2h_draenorfishingpole_b_01");

		MasqueRegister(TotalAP_UnderlightIconButton, "specIcons");
		
end

-- Initialise info frame (attached to the action button)
local function CreateInfoFrame()
	
	-- Create anchored container frame for the bar display
	TotalAPInfoFrame = CreateFrame("Frame", "TotalAPInfoFrame", TotalAPAnchorFrame);
	--TotalAPInfoFrame:SetFrameStrata("BACKGROUND");
--	TotalAPInfoFrame:SetClampedToScreen(true);

	-- Create progress bars for all available specs
	local numSpecs = GetNumSpecializations(); 
	TotalAPProgressBars, TotalAPUnspentBars, TotalAPInBagsBars = {}, {}, {};
	for i = 1, numSpecs do -- Create bar frames
	
		-- Empty bar texture
		TotalAPProgressBars[i] = CreateFrame("Frame", "TotalAPProgressBar" .. i, TotalAPInfoFrame);
		-- leftmost part: AP used on artifact
		TotalAPUnspentBars[i] = CreateFrame("Frame", "TotalAPUnspentBar" .. i, TotalAPProgressBars[i]);

		-- AP in bags 
		TotalAPInBagsBars[i] = CreateFrame("Frame", "TotalAPInBagsBar" .. i, TotalAPProgressBars[i]);

	end
	
	TotalAP_UnderlightProgressBar = CreateFrame("Frame", "TotalAP_UnderlightProgressBar", TotalAPInfoFrame);
	TotalAP_UnderlightUnspentBar = CreateFrame("Frame", "TotalAP_UnderlightUnspentBar", TotalAPInfoFrame);
	TotalAP_UnderlightInBagsBar = CreateFrame("Frame", "TotalAP_UnderlightInBagsBar", TotalAPInfoFrame);
	
	
	TotalAPInfoFrame:SetBackdrop(
		{
			bgFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Background.blp",
												-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												-- tile = true, tileSize = 16, edgeSize = 16, 
												-- insets = { left = 4, right = 4, top = 4, bottom = 4 }
		}
	);
	--TotalAPInfoFrame.texture = TotalAPInfoFrame:CreateTexture();
	--TotalAPInfoFrame.texture:SetAllPoints(TotalAPInfoFrame);
	--TotalAPInfoFrame.texture:SetTexture("Interface\\CHATFRAME\\CHATFRAMEBACKGROUND.BLP", true);				
	--TotalAPInfoFrame:SetBackdropColor(0, 0, 0, 30);
	TotalAPInfoFrame:SetBackdropBorderColor(255, 255, 255, 1); -- TODO: Not working?
	
	-- Enable mouse interaction: ALT+RightClick = Drag and change position
	TotalAPInfoFrame:EnableMouse(true);
	TotalAPInfoFrame:SetMovable(true);
	TotalAPInfoFrame:RegisterForDrag("LeftButton"); -- TODO: Remove this, if it is anchored to the button?
	

	-- TODO: Duplicate code for dragging the three main frames?
		TotalAPInfoFrame:SetScript("OnDragStart", function(self) -- (to allow dragging the button, and also to resize it)
		
		if self:IsMovable() and IsAltKeyDown() then TotalAPAnchorFrame:StartMoving(); -- Alt -> Move button
		elseif self:IsResizable() and IsShiftKeyDown() then self:StartSizing(); end -- Shift -> Resize button
			
		self.isMoving = true;
	
		end);
		
		TotalAPInfoFrame:SetScript("OnUpdate", function(self) -- (to update the button skin and proportions while being resized)
			
			if self.isMoving then
				UpdateEverything();
			end
		end)
		
		TotalAPInfoFrame:SetScript("OnDragStop", function(self) -- (to update the button skin and stop it from being moved after dragging has ended) -- TODO: OnDraagStop vs OnReceivedDrag?
			
			self:StopMovingOrSizing();
			TotalAPAnchorFrame:StopMovingOrSizing();
			self.isMoving = false;
		
			-- Reset glow effect in case the button's size changed (will stick to the old size otherwise, which looks buggy), but only if it is displayed (or it will flash briefly before being deactivated during the UpdateActionButton phase)
			FlashActionButton(TotalAPButton, false);  -- TODO: Not here, is it even necessary after the anchor frame change?
			UpdateEverything();
			-- TODO: Updates should be done by event frame, not button... but alas
		end)
	
end

-- Initialise action button (serves as anchor for the other frames and buttons)
local function CreateActionButton()
	
	if not TotalAPButton then -- if button already exists, this was called before -> Skip initialisation
		
		TotalAPButton = CreateFrame("Button", "TotalAPButton", TotalAPAnchorFrame, "ActionButtonTemplate, SecureActionButtonTemplate");
		TotalAPButton:SetFrameStrata("HIGH");
		TotalAPButton:SetClampedToScreen(true);
		
		-- TotalAPButton:SetSize(settings.actionButtonSize, settings.actionButtonSize); 
		--TotalAPButton:SetPoint("CENTER");

		TotalAPButton:SetMovable(true);
		TotalAPButton:EnableMouse(true)
		TotalAPButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		TotalAPButton:RegisterForDrag("LeftButton"); -- left button = resize or reposition

		TotalAPButton:SetResizable(true);
		TotalAPButton:SetMinResize(settings.actionButton.minResize, settings.actionButton.minResize); -- Let's not go there and make it TINY, shall we?
		TotalAPButton:SetMaxResize(settings.actionButton.maxResize, settings.actionButton.maxResize); -- ... but no one likes a stretched, giant button either)
		
		currentItemTexture = GetItemIcon(currentItemID) or "";
		TotalAPButton.icon:SetTexture(currentItemTexture);
		Debug(format("Set currentItemTexture to %s", currentItemTexture));
		
		Debug(format("Created button with currentItemTexture = %s (currentItemID = %d)", currentItemTexture, currentItemID));
		

		-- [[ Action handlers ]] --
		TotalAPButton:SetScript("OnEnter", function(self)  -- (to show the tooltip on mouseover)
		
			if currentItemID then
			
				GameTooltip:SetOwner(TotalAPButton, "ANCHOR_RIGHT");
				GameTooltip:SetHyperlink(currentItemLink);
			--	Debug(format("OnEnter -> mouse entered TotalAPButton... Displaying tooltip for currentItemID = %s.", currentItemID));
				
				local itemName = GetItemInfo(currentItemLink) or "<none>";
				Debug(format("Current item bound to action button: %s = % s", itemName, currentItemLink));
			--	Debug(format("Attributes: type = %s, item = %s", self:GetAttribute("type") or "<none>", self:GetAttribute("item") or "<none>"));
			
			else Debug("OnEnter  -> mouse entered TotalAPButton... but currentItemID is nil so a tooltip can't be displayed!"); end
			
			Debug(format("Button size is width = %d, height = %d, settings.actionButtonSize = %d", self:GetWidth(), self:GetHeight(), settings.actionButtonSize or 0));
			
		end);
		
		TotalAPButton:SetScript("OnLeave", function(self)  -- (to hide the tooltip afterwards)
			GameTooltip:Hide();
		end);
			
		TotalAPButton:SetScript("OnHide", function(self) -- (to hide the tooltip when leaving the button)
			Debug("Button is being hidden. Disabled click functionality...");
			self:SetAttribute("type", nil);
			self:SetAttribute("item", nil);
		end);
	
		TotalAPButton:SetScript("OnDragStart", function(self) -- (to allow dragging the button, and also to resize it)
		
		if self:IsMovable() and IsAltKeyDown() then TotalAPAnchorFrame:StartMoving(); -- Alt -> Move button
		elseif self:IsResizable() and IsShiftKeyDown() then self:StartSizing(); end -- Shift -> Resize button
			
		self.isMoving = true;
	
		end);
		
		TotalAPButton:SetScript("OnUpdate", function(self) -- (to update the button skin and proportions while being resized)
			
			if self.isMoving then
				UpdateEverything();
			end
		end)
		
		TotalAPButton:SetScript("OnDragStop", function(self) -- (to update the button skin and stop it from being moved after dragging has ended) -- TODO: OnDraagStop vs OnReceivedDrag?
			
			self:StopMovingOrSizing();
			TotalAPAnchorFrame:StopMovingOrSizing();
			self.isMoving = false;
		
			-- Reset glow effect in case the button's size changed (will stick to the old size otherwise, which looks buggy), but only if it is displayed (or it will flash briefly before being deactivated during the UpdateActionButton phase)
			FlashActionButton(TotalAPButton, false); 
			UpdateEverything();
			-- TODO: Updates should be done by event frame, not button... but alas
		end)

		-- Register action button with Masque to allow it being skinned
		MasqueRegister(TotalAPButton, "itemUseButton");
	end	
end

-- Anchor for the individual frames (invisible and created before all others)
local function CreateAnchorFrame()
	
		TotalAPAnchorFrame = CreateFrame("Frame", "TotalAPAnchorFrame", UIParent);
		TotalAPAnchorFrame:SetFrameStrata("BACKGROUND");
		--TotalAPAnchorFrame:SetClampedToScreen(true);
		
		-- TotalAPButton:SetSize(settings.actionButtonSize, settings.actionButtonSize); 
		TotalAPAnchorFrame:SetPoint("CENTER");
		
		-- TotalAPAnchorFrame:SetBackdrop(
		-- {
			-- bgFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Background.blp",
												-- -- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												-- -- tile = true, tileSize = 16, edgeSize = 16, 
												-- -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
		-- }
	-- ); -- No one needs to see it. If they do -> debug command /ap anchor
	
	
		--TotalAPAnchorFrame:SetBackdropBorderColor(0, 50, 150, 1); -- TODO: Not working?
		TotalAPAnchorFrame:SetSize(220, 15); -- Doesn't really matter unless there is an option to show and move it manually. ...There isn't any right now.

		TotalAPAnchorFrame:SetMovable(true);
		TotalAPAnchorFrame:EnableMouse(true)
		--TotalAPAnchorFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		TotalAPAnchorFrame:RegisterForDrag("LeftButton"); -- left button = resize or reposition
	
		TotalAPAnchorFrame:SetScript("OnDragStart", function(self) -- (to allow dragging the button, and also to resize it)
		
		if self:IsMovable() and IsAltKeyDown() then self:StartMoving(); -- Alt -> Move button
		elseif self:IsResizable() and IsShiftKeyDown() then self:StartSizing(); end -- Shift -> Resize button
			
		self.isMoving = true;
	
		end);
		
		TotalAPAnchorFrame:SetScript("OnUpdate", function(self) -- (to update the button skin and proportions while being resized)
			
			if self.isMoving then
			
			Debug(format("MasterFrame is moving, width = %d, height = %d", self:GetWidth(), self:GetHeight()));
			UpdateEverything();
			end
		end)
		
		TotalAPAnchorFrame:SetScript("OnDragStop", function(self) -- (to update the button skin and stop it from being moved after dragging has ended) -- TODO: OnDraagStop vs OnReceivedDrag?
			
			self:StopMovingOrSizing();
			self.isMoving = false;
		
			-- Reset glow effect in case the button's size changed (will stick to the old size otherwise, which looks buggy), but only if it is displayed (or it will flash briefly before being deactivated during the UpdateActionButton phase)
		--	FlashActionButton(TotalAPButton, false); 
			UpdateEverything();
			-- TODO: Updates should be done by event frame, not button... but alas
		end)
	
		--TotalAPAnchorFrame:Hide();
	
		TotalAPAnchorFrame:SetScript("OnEvent", function(self, event, unit) --  (to update and show/hide the button when entering or leaving combat/pet battles)

		-- TODO: Check for player_equip_changed event also ? (spec changed, eq/uneq artifact etc without triggering any of the other events.. is this actually possible?)
		
			if event == "BAG_UPDATE_DELAYED" then  -- inventory has changed -> recheck bags for AP items and update button display

				Debug("Scanning bags and updating action button after BAG_UPDATE_DELAYED...");
				CheckBags();
				UpdateEverything();
				-- TODO: Updates should be done by event frame, not button... but alas
				
			elseif event == "PLAYER_REGEN_DISABLED" or event == "PET_BATTLE_OPENING_START" or (event == "UNIT_ENTERED_VEHICLE" and unit == "player") then -- Hide button while AP items can't be used
				
				Debug("Player entered combat, vehicle, or pet battle... Hiding button!");
				self:Hide();
				UpdateEverything();
				self:UnregisterEvent("BAG_UPDATE_DELAYED");
				
			elseif event == "PLAYER_REGEN_ENABLED" or event == "PET_BATTLE_CLOSE" or (event == "UNIT_EXITED_VEHICLE" and unit == "player") then -- Show button once they are usable again
			
				--if numItems > 0 and not InCombatLockdown() and settings.showActionButton then 
				Debug("Player left combat , vehicle, or pet battle... Updating action button!");
				self:Show(); 
					--Debug("Player left combat , vehicle, or pet battle... Showing button!");
				-- end
				
				UpdateEverything();
				
				self:RegisterEvent("BAG_UPDATE_DELAYED");
					
			elseif event == "ARTIFACT_XP_UPDATE" or event == "ARTIFACT_UPDATE" then -- Recalculate tooltip display and update button when AP items are used or new traits purchased
				
				Debug("Updating action button after ARTIFACT_UPDATE or ARTIFACT_XP_UPDATE...");
				UpdateEverything();
				
	
		end
	end);
end


	-- Register all relevant events required to update the button
local function RegisterUpdateEvents()

		-- PLAYER_LEAVE_COMBAT, PLAYER_EQUIP_CHANGED
		TotalAPAnchorFrame:RegisterEvent("BAG_UPDATE_DELAYED"); -- Possible inventory change -> Re-scan bags
		TotalAPAnchorFrame:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Player entered combat -> Hide button
		TotalAPAnchorFrame:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Player left combat -> Show button
		TotalAPAnchorFrame:RegisterEvent("PET_BATTLE_OPENING_START"); -- Player entered pet battle -> Hide button
		TotalAPAnchorFrame:RegisterEvent("PET_BATTLE_CLOSE"); -- Player left pet battle -> Show button
		TotalAPAnchorFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
		TotalAPAnchorFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
		TotalAPAnchorFrame:RegisterEvent("ARTIFACT_XP_UPDATE"); -- gained AP
		TotalAPAnchorFrame:RegisterEvent("ARTIFACT_UPDATE"); -- new trait learned? Apparently this is only fired by addons, and therefore unreliable?

		-- TODO: Only one event handler frame (and perhaps one UpdateEverything method) that updates all the indicators as well as the action button? (tricky if events like dragging are only given to the button by WOW?)
end


-- Toggle action button via keybind or slash command
function TotalAP_ToggleActionButton()
	
		if settings.actionButton.enabled then
			ChatMsg(L["Action button is now hidden."]);
		else
			ChatMsg(L["Action button is now shown."]);
		end
	
	settings.actionButton.enabled = not settings.actionButton.enabled;
	
	UpdateEverything(); -- TODO: Hide other frames as well?
end

-- Toggle the spec icons (and text) via keybind or slash command
function TotalAP_ToggleSpecIcons()
	
	if settings.specIcons.enabled then
			ChatMsg(L["Icons are now hidden."] );
	else
			ChatMsg(L["Icons are now shown."] );
	end
	
	settings.specIcons.enabled = not settings.specIcons.enabled;
	
	UpdateEverything();
end

-- Toggle the InfoFrame (bar display) via keybind or slash command
function TotalAP_ToggleBarDisplay()
		
	if settings.infoFrame.enabled then
		ChatMsg(L["Bar display is now hidden."]);
	else
		ChatMsg(L["Bar display is now shown."]);
	end
	
	settings.infoFrame.enabled = not settings.infoFrame.enabled;
	
	UpdateEverything();
end

-- Toggle the tooltip display via keybind or slash command
-- TODO: Show/hide tooltip when toggling this? Which way feels most intuititive?
function TotalAP_ToggleTooltipDisplay()
		if settings.tooltip.enabled then
			ChatMsg(L["Tooltip display is now hidden."]);
		else
			ChatMsg(L["Tooltip display is now shown."]);
		end
		
	settings.tooltip.enabled = not settings.tooltip.enabled;
	
	UpdateEverything();
end


-- Slash command handling
-- TODO: Switch / LUT 
local function SlashCommandHandler(msg)

	-- Preprocessing of user input
	msg = string.lower(msg);
	local command, param = msg:match("^(%S*)%s*(.-)$");
	
	if command == "counter" then -- Toggle counter display in tooltip
	
		if not settings.tooltip.showNumItems then ChatMsg(L["Item counter enabled."]);
		else ChatMsg(L["Item counter disabled."]);
		end
		
		settings.tooltip.showNumItems = not settings.tooltip.showNumItems;
	
	elseif command == "progress" then -- Enable progress report in tooltip
	
		if not settings.tooltip.showProgressReport then ChatMsg(L["Progress report enabled."]);
		else ChatMsg(L["Progress report disabled."]);
		end
		
		settings.tooltip.showProgressReport = not settings.tooltip.showProgressReport;
	
	elseif command == "glow" then -- Toggle button spell overlay effect -> Notification when new traits are available
		
		if not settings.actionButton.showGlowEffect then
			settings.actionButton.showGlowEffect = true; 
			ChatMsg(L["Button glow effect enabled."]);
		else
			settings.actionButton.showGlowEffect = false;
			ChatMsg(L["Button glow effect disabled."]);
		end
		
		UpdateEverything();
		
	elseif command == "button" then -- Toggle button visibility (tooltip functionality remains)

		TotalAP.ToggleActionButton();
		
	elseif command == "bars" then -- Toggle infoFrame (bar display)

		TotalAP.ToggleBarDisplay();	
		
	elseif command == "tooltip" then
	
		TotalAP.ToggleTooltipDisplay();
	
	elseif command == "icons" then
	
		TotalAP.ToggleSpecIcons();	

	elseif command == "loginmsg" then -- Toggle notification when loading/logging in (effective after next login, obviously)
		
		if settings.showLoginMessage then
			ChatMsg(L["Login message is now hidden."]);
		else
			ChatMsg(L["Login message is now shown."]);
		end
		
	settings.showLoginMessage = not settings.showLoginMessage;
	
	-- [[ Undocumented - For testing and debugging purposes only]] --
	
	elseif command == "flash" then --  Add spell overlay to action button (for debugging/testing purposes only -> undocumented)
	
		FlashActionButton(TotalAPButton, true);
		for i = 0, GetNumSpecializations() do
			FlashActionButton(TotalAPSpecIconButtons[i], true);
		end
		
	
	elseif command == "unflash" then -- Remove spell overlay from all buttons (for debugging/testing purposes only -> undocumented)
	
		FlashActionButton(TotalAPButton, false);
		for i = 0, GetNumSpecializations() do
			FlashActionButton(TotalAPSpecIconButtons[i], false);
		end
		
	elseif command == "reset" then -- Load default values for all settings
		
		RestoreDefaultSettings();
		ChatMsg(L["Default settings loaded."]);
		
		TotalAPAnchorFrame:ClearAllPoints();
		TotalAPAnchorFrame:SetPoint("CENTER", UIParent, "CENTER");
		
		UpdateEverything();
		
	elseif command == "anchor" then -- Show anchor frame
	
		--TotalAPAnchorFrame:SetShown(TotalAPAnchorFrame:IsShown());
		TotalAPAnchorFrame:SetBackdrop(
			{
				bgFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Background.blp",
												-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												-- tile = true, tileSize = 16, edgeSize = 16, 
													-- insets = { left = 4, right = 4, top = 4, bottom = 4 }
			}
		); 
		
		
	elseif command == "debug" then -- Toggle debug mode (for debugging/testing purposes only -> undocumented)
	
		if settings.debugMode then
			ChatMsg(L["Debug mode disabled."]);
		else
			ChatMsg(L["Debug mode enabled."]);
		end
		
		settings.debugMode = not settings.debugMode;
		
	elseif command == "load" then -- Load settings manually (including verification of SavedVars)  (for debugging purposes only)-> undocumented 	
		LoadSettings();
		UpdateEverything();
		Debug("Reloaded settings from SavedVars");

	else -- Display help / list of commands
		
		ChatMsg(L["[List of available commands]"]);
		ChatMsg(slashCommand .. " counter - " .. L["Toggle display of the item counter"]);
		ChatMsg(slashCommand .. " progress - " .. L["Toggle display of the progress report"]);
		ChatMsg(slashCommand .. " glow - " .. L["Toggle spell overlay notification (glow effect) when new traits are available"]);
		ChatMsg(slashCommand .. " button - " .. L["Toggle button visibility (tooltip visibility is unaffected)"]);
		
		ChatMsg(slashCommand .. " bars - " .. L["Toggle bar display for artifact power progress"]);
		ChatMsg(slashCommand .. " tooltip - " .. L["Toggle tooltip display for artifact power items"]);
		ChatMsg(slashCommand .. " icons - " .. L["Toggle icon and text display for artifact power progress"]);
		
		ChatMsg(slashCommand .. " loginmsg - " .. L["Toggle login message on load"]);
		ChatMsg(slashCommand .. " reset - " .. L["Load default settings (will overwrite any changes made)"]);
		ChatMsg(slashCommand .. " debug - " .. L["Toggle debug mode (not particularly useful as long as everything is working as expected)"]); -- TODO: Should this be displayed in the first place?
	
	end
end


-- Display tooltip when hovering over an AP item
GameTooltip:HookScript('OnTooltipSetItem', function(self)
	
	local _, tempItemLink = self:GetItem();
	if type(tempItemLink) == "string" then

		tempItemID = GetItemInfoInstant(tempItemLink);
		
		if itemEffects[tempItemID] then -- Only display tooltip addition for AP tokens
			
			local artifactID, _, artifactName = C_ArtifactUI.GetEquippedArtifactInfo();
			
			if artifactID and artifactName and settings.tooltip.enabled then
				-- Display spec and artifact info in tooltip
				local spec = GetSpecialization();
				if spec then
					local _, specName, _, specIcon, _, specRole = GetSpecializationInfo(spec);
					local classDisplayName, classTag, classID = UnitClass("player");
					
					if specIcon then
						self:AddLine(format('\n|T%s:%d|t [%s]', specIcon,  settings.specIconSize, artifactName), 230/255, 204/255, 128/255); -- TODO: Colour green/red or something if it's the offspec? Can use classTag or ID for this
					end
				end
		
		
				-- Display AP summary
				if numItems > 1 and settings.tooltip.showNumItems then
					self:AddLine(format(L["\n%s Artifact Power in bags (%d items)"], Short(inBagsTotalAP, true), numItems), 230/255, 204/255, 128/255);
				else
					self:AddLine(format(L["\n%s Artifact Power in bags"], Short(inBagsTotalAP, true)) , 230/255, 204/255, 128/255);
				end
			
				-- Calculate progress towards next trait
				if HasArtifactEquipped() and settings.tooltip.showProgressReport then
						
						-- Recalculate progress percentage and number of available traits before actually showing the tooltip
						numTraitsAvailable = GetNumAvailableTraits(); 
						artifactProgressPercent = GetArtifactProgressPercent();
							
						-- Display progress in tooltip
						if numTraitsAvailable > 1 then -- several new traits are available
							self:AddLine(format(L["%d new traits available - Use AP now to level up!"], numTraitsAvailable), 0/255, 255/255, 0/255);
						elseif numTraitsAvailable > 0 then -- exactly one new is trait available
							self:AddLine(format(L["New trait available - Use AP now to level up!"]), 0/255, 255/255, 0/255);
						else -- No traits available - too bad :(
							self:AddLine(format(L["Progress towards next trait: %d%%"], artifactProgressPercent));
						end
				end
			end
			
		self:Show();
		
		end
	end
end);


 -- One-time execution on load -> Piece everything together
 do
	LoadSettings();  -- from saved vars
	
	local f = CreateFrame("Frame", "TotalAPStartupEventFrame");

	f:RegisterEvent("ADDON_LOADED");
	f:RegisterEvent("PLAYER_LOGIN");
	f:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	f:SetScript("OnEvent", function(self, event, ...) -- This frame is for initial event handling only
	
		local loadedAddonName = ...;
	
		if event == "ADDON_LOADED" and loadedAddonName == addonName then -- addon has been loaded, savedVars are available -> Create frames before PLAYER_LOGIN to have the game save their position automatically
		
			LoadSettings();
			CreateAnchorFrame(); -- anchor for all other frames -> needs to be loaded before PLAYER_LOGIN to have the game save its position and size
			
				
			
		elseif event == "PLAYER_LOGIN" then -- Frames have been created, everything is ready for use -> Display login message (if enabled)
		
			local clientVersion, clientBuild = GetBuildInfo(); 
			if settings.showLoginMessage then ChatMsg(format(L["%s %s for WOW %s loaded!"], addonName, addonVersion, clientVersion)); end
			CreateActionButton();
		-- talent info isn't available sooner, and those frames are anchored to the button anyway -> initial position doesn't matter
			CreateInfoFrame();
			CreateSpecIcons(); 
		
		elseif event == "PLAYER_ENTERING_WORLD" then -- Register for events required to update
		
			Debug(format("Registering button update events...", event));
			RegisterUpdateEvents();

		end
	end);
	
	-- Add slash command to global command list
	SLASH_TOTALAP1, SLASH_TOTALAP2 = "/totalap", slashCommand;
	SlashCmdList["TOTALAP"] = SlashCommandHandler;
	
	-- Add keybinds to Blizzard's KeybindUI
	BINDING_HEADER_TOTALAP = L["TotalAP - Artifact Power Tracker"];
	_G["BINDING_NAME_CLICK TotalAPButton:LeftButtonUp"] = L["Use Next AP Token"];
	_G["BINDING_NAME_TOTALAPBUTTONTOGGLE"] = L["Show/Hide Button"];
	_G["BINDING_NAME_TOTALAPTOOLTIPTOGGLE"] = L["Show/Hide Tooltip Info"];
	_G["BINDING_NAME_TOTALAPBARDISPLAYTOGGLE"] = L["Show/Hide Bar Display"];
	_G["BINDING_NAME_TOTALAPICONSTOGGLE"] = L["Show/Hide Icons"];
end