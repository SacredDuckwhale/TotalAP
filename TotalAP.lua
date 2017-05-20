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


-- TotalAP.lua (AKA main, core, what have you ...)
-- Sets up the addon, db, libraries etc. - basic startup stuff (TODO: Does much more currently, but migration/refactoring is in progress ;)

local itemEffects; -- loaded on init from separate (script-generated) file: DB\ItemEffects.lua

-- Libraries: If they fail to load, TotalAP shouldn't load either
local AceAddon = LibStub("AceAddon-3.0"):NewAddon("TotalAP", "AceConsole-3.0"); -- AceAddon object -> local because it's not really needed elsewhere
local L = LibStub("AceLocale-3.0"):GetLocale("TotalAP", false); -- Localization table; default locale is enGB (=enUS). false to show an error if locale not found (via AceLocale)
local SharedMedia = LibStub("LibSharedMedia-3.0");  -- TODO: Not implemented yet... But "soon" (TM) -> allow styling of bars and font strings (I'm really just waiting until the config/options are done properly for this -> AceConfig)
local Masque = LibStub("Masque", true); -- optional (will use default client style if not found)


-- Shorthands: Those don't do anything except save me work :P
local aUI = C_ArtifactUI


-- Addon metadata (used for messages/output, primarily)
local addonName, T = ...;
TotalAP = T -- Global container for modularised functions and library instance objects -> contains the addonTable to exchange information between modules



local addonVersion = GetAddOnMetadata(addonName, "Version");

-- Internal vars - TODO: Move these to the appropriate modules
local itemEffects, artifacts; -- Loaded from TotalArtifactPowerDB in LoadSettings(), for now
local tempItemLink, tempItemID, currentItemLink, currentItemID, currentItemTexture, currentItemAP; -- used for bag scanning and tooltip display
local numItems, inBagsTotalAP, numTraitsAvailable, artifactProgressPercent = 0, 0, 0, 0; -- used for tooltip text
local foundKnowledgeTome -- buttonText (TODO -> workaround for display inconsistencies)
local numTraitsFontString, specIconFontStrings = nil, {}; -- Used for the InfoFrame

-- One-time checks (per login... not stored otherwise)
local allSpecsIgnoredWarningGiven = false 

local artifactProgressCache = {} -- Used to calculate offspec artifact progress

local maxArtifactTraits = 999; -- TODO: Temporary (before 7.2) - allow it to be set manually (to ignore specs above 35 or 54) - In 7.2 this might be entirely useless as AP will continue to increase exponentially at those levels and beyond - 7.2 TODO: Change to option and allow the user to manually set it (feature request to ignore "inefficient" specs)


--local TotalAPFrame, TotalAPInfoFrame, TotalAPButton, TotalAPSpec1IconButton, TotalAPSpec2conButton, TotalAPSpec3IconButton, TotalAPSpec4IconButton; -- UI elements/frames
local settings, cache = {}, {}; -- will be loaded from savedVars later


local defaultSettings = TotalAP.DBHandler.GetDefaults() -- TODO: remove (crutch while in migration)

-- Calculate the total number of purchaseable traits (using AP from both the equipped artifact and from AP tokens in the player's inventory)
local function GetNumAvailableTraits()
	
	if not aUI or not HasArtifactEquipped() then
		TotalAP.Debug("Called GetNumAvailableTraits, but the artifact UI is unavailable... Is an artifact equipped?");
		return 0;
	end
	
	-- TODO: 
	-- function MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, artifactXP, artifactTier)
	-- local numPoints = 0;
	-- local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
	-- while artifactXP >= xpForNextPoint and xpForNextPoint > 0 do
		-- artifactXP = artifactXP - xpForNextPoint;

		-- pointsSpent = pointsSpent + 1;
		-- numPoints = numPoints + 1;

		-- xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
	-- end
	-- return numPoints, artifactXP, xpForNextPoint;
-- end
		
	local thisLevelUnspentAP, numTraitsPurchased, _, _, _, _, _, _, tier = select(5, aUI.GetEquippedArtifactInfo());	
	--local tier = aUI.GetArtifactTier() or 2; -- Assuming 2 as per usual (see other calls and comments for GetArtifactTier) - only defaults to this when artifact is not available/opened?
	local numTraitsAvailable = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(numTraitsPurchased, thisLevelUnspentAP + inBagsTotalAP, tier); -- This is how many times the weapon can be leveled up with AP from bags AND already used (but not spent) AP from this level
	TotalAP.Debug(format("Called GetNumAvailableTraits -> %s new traits available!", numTraitsAvailable or 0));
	
	return numTraitsAvailable or 0;
end

-- Calculate progress towards next artifact trait (for the equipped artifact). TODO: Function GetArtifactProgressData -> unspentAP, numAvailableTraits, progressPercent
local function GetArtifactProgressPercent()
		
		--if not considerBags then considerBags = true; -- Only ignore bags if explicitly told so (i.e., for cache operations, chiefly)
		
		if not aUI or not HasArtifactEquipped() then
			TotalAP.Debug("Called GetArtifactProgressPercent, but the artifact UI is unavailable (is an artifact equipped?)...");
			return 0;
		end
	
		local thisLevelUnspentAP, numTraitsPurchased, _, _, _, _, _, _, tier  = select(5, aUI.GetEquippedArtifactInfo());	
		--local tier = aUI.GetArtifactTier() or 2; -- TODO: Assume 2 for 7.2 yatta yatta (new traits after <1h of playtime so everybody should have them) in case caching failes (aUi not available). Problematic for lower level offspecs (<35 traits) as they are actually "tier 1"
		local nextLevelRequiredAP = aUI.GetCostForPointAtRank(numTraitsPurchased, tier); 
		
		--if considerBags then -- TODO: This is ugly. I can do better, oh great one!
		local percentageOfCurrentLevelUp = (thisLevelUnspentAP + inBagsTotalAP) / nextLevelRequiredAP*100;
		TotalAP.Debug(format("Called GetArtifactProgressPercent -> Progress is: %s%% towards next trait!", percentageOfCurrentLevelUp or 0)); -- TODO: > 100% becomes inaccurate due to only using cost for THIS level, not next etc?
		return percentageOfCurrentLevelUp or 0;
	--	else 
		--	return thisLevelUnspentAP, nextLevelRequiredAP;
	--	end

end

-- Load default settings (will overwrite SavedVars)
local function RestoreDefaultSettings()

	TotalAP.DBHandler.RestoreDefaults() -- TODO: remove

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
	
--	return true;
	
	local masterTable, targetTable = defaultSettings, settings;
	
	-- Check default settings (= always up-to-date) against SavedVars, and add missing keys from the defaults. TODO: This leaves some remnants of deprecated options, also it would be easier with Ace
	TotalAP.Utils.CompareTables(masterTable, targetTable, targetTable, nil);
	

	return true;
	
end

-- Load saved vars and DB files, attempt to verify SavedVars
local function LoadSettings()
	
	-- Load item spell effects & spec artifact list from global (shared) DB
	itemEffects = TotalArtifactPowerDB["itemEffects"]; -- This isn't strictly necessary, as the DB is in the global namespace. However, it's better to not litter the code with direct references in case of future changes - also, they are static so loading them once (on startup) should suffice
	artifacts = TotalArtifactPowerDB["artifacts"]; -- Ditto
	
	-- Check & verify default settings before loading them
	settings = TotalArtifactPowerSettings;
	if not settings then 	-- Load default settings
		RestoreDefaultSettings(); 
	else -- check for types and proper values 
		if not VerifySettings() then
			TotalAP.ChatMsg(L["Settings couldn't be verified... Default values have been loaded."]);
		else
			TotalAP.Debug("SavedVars verified (and loaded) successfully.");
		end
	end
	
	-- Load cached AP progress if is has been saved before (will be updated as soon as the spec is enabled again)
	cache = TotalArtifactPowerCache;
	if type(cache) ~= "table" then
		cache = {};
	end
	
end

-- Check for artifact power tokens in the player's bags 
 local function CheckBags()
 
	local bag, slot;
	numItems, inBagsTotalAP, currentItemAP = 0, 0, 0; -- Each scan has to reset the (global) counter used by the tooltip and update handlers
	foundKnowledgeTome = false -- AK tomes will later overwrite the AP progress in some displays, but not prevent it from being saved and used for others (tooltip display/bars)
	
	-- Check all the items in bag against AP token LUT (via their respective spell effect = itemEffectsDB)to find matches
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			tempItemLink = GetContainerItemLink(bag, slot);

			if tempItemLink and tempItemLink:match("item:%d")  then
					tempItemID = GetItemInfoInstant(tempItemLink);
					local spellID = itemEffects[tempItemID];
				
				-- TODO: Move this to DB\ResearchTomes or something, and access via helper function (similar to artifacts)
				if tempItemID == 139390 		-- Artifact Research Notes (max. AK 25) TODO: obsolete? Seem to be replaced by the AK 50 version entirely
					or tempItemID == 146745	-- Artifact Research Notes (max. AK 50)
					or tempItemID == 147860 	-- Empowered Elven Tome (7.2)
					or tempItemID == 144433	--  Artifact Research Compendium: Volume I
					or tempItemID == 144434	-- Artifact Research Compendium: Volumes I & II
					or tempItemID == 144431	-- Artifact Research Compendium: Volumes I-III
					or tempItemID == 144395	-- Artifact Research Synopsis
					or tempItemID == 147852	-- Artifact Research Compendium: Volumes I-V
					or tempItemID == 147856	-- Artifact Research Compendium: Volumes I-IX
					or tempItemID == 147855	-- Artifact Research Compendium: Volumes I-VIII
					or tempItemID == 144435	-- Artifact Research Compendium: Volumes I-IV
					or tempItemID == 147853	-- Artifact Research Compendium: Volumes I-VI
					or tempItemID == 147854	-- Artifact Research Compendium: Volumes I-VII
					or tempItemID == 141335	-- Lost Research Notes (TODO: Is this even ingame? -> Part of the obsolete Mage quest "Hidden History", perhaps?)
				then -- Artifact Research items available for use
					TotalAP.Debug("Found Artifact Research items in inventory -> Displaying them instead of AP items");
				
					currentItemLink = tempItemLink;
					currentItemID = tempItemID;
					currentItemTexture = GetItemIcon(currentItemID);
				
					TotalAP.Debug(format("Set currentItemTexture to %s", currentItemTexture));
					foundKnowledgeTome = true
					--numItems = 1; -- TODO: This is technically wrong! But it will update to the correct amount once research notes have been used, anyway (and is used by other displays at times, which might not be the best practice...)
					--currentItemAP = 0 -- to overwrite the last item's amount (would be displayed as the research tome's AP value instead, which is misleading --  TODO: Proper handling of tomes -> resume scan but flag for display only (so that the tooltip info remains correct)
					--return true; -- Stop scanning and display this item instead
				end
				
				if spellID then	-- Found AP token :D	
					numItems = numItems + 1
					
					-- Extract AP amount (after AK) from the description
					local spellDescription = GetSpellDescription(spellID); -- Always contains the AP number, as only AP tokens are in the LUT 
					
					local n = TotalAP.Scanner.ParseSpellDesc(spellDescription) -- Scans spell description and extracts AP amount based on locale (as they use slightly different formats to display the numbers)

					inBagsTotalAP = inBagsTotalAP + tonumber(n);
					
					-- AK Tomes should override button display/button text
					if not foundKnowledgeTome then -- Set button to current AP item
						currentItemAP = n;
						
						-- Store current AP item in globals (to display in button, use via keybind, etc.)
						currentItemLink = tempItemLink;
						currentItemID = tempItemID;
						currentItemTexture = GetItemIcon(currentItemID);
						
						TotalAP.Debug(format("Set currentItemTexture to %s", currentItemTexture));
						
						TotalAP.Debug(format("Found item: %s (%d) with texture %d",	currentItemLink, currentItemID, currentItemTexture)); 
					end
					
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
	if not button or InCombatLockdown() then
		TotalAP.Debug("Called FlashActionButton, but button is nil or combat lockdown is active. Abort, abort!");
		return false
	else
		if showGlowEffect then
			
			ActionButton_ShowOverlayGlow(button);
			--local bx, by = button.overlay:GetSize()
			--TotalAP.Debug("Flashing action button -> overlay size is " .. bx .. " " .. by)
			-- if showAnts then
				-- button.overlay.ants:Show();
			-- else
				-- button.overlay.ants:Hide(); -- TODO: SetShow?
			-- end
			
		else
			ActionButton_HideOverlayGlow(button);
			-- if button.overlay ~= nil then
				-- ActionButton_OverlayGlowAnimOutFinished(button.overlay.animOut)
			-- end
		end
	end
end	

-- Registers button with Masque
local function MasqueRegister(button, subGroup) 

		 if Masque then
		 
			 local group = Masque:Group(L["TotalAP - Artifact Power Tracker"], subGroup); 
			 group:AddButton(button);
			 TotalAP.Debug(format("Added button %s to Masque group %s.", button:GetName(), subGroup));
			 
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
		 TotalAP.Debug(format("Updated Masque skin for group: %s", subGroup));
	end
end

-- Check whether the equipped weapon is the active spec's actual artifact weapon
local function HasCorrectSpecArtifactEquipped()
	
	local _, _, classID = UnitClass("player"); -- 1 to 12
	local specID = GetSpecialization(); -- 1 to 4

	-- Check all artifacts for this spec
	TotalAP.Debug(format("Checking artifacts for class %d, spec %d", classID, specID));
	
	local specArtifacts = artifacts[classID][specID];
	
	-- Test for all artifacts that this spec can equip
	for k, v in pairs(specArtifacts) do
		local itemID = v[1]; -- TODO: Why did I want canOccupyOffhandSlot again? Seems useless now, remove it from DB\Artifacts.lua?
	
		-- Cancel if just one is missing
		if not IsEquippedItem(itemID) then
			TotalAP.Debug(format("Expected to find artifact weapon %s, but it isn't equipped", GetItemInfo(itemID) or "<none>"));
			return false 
		end
		
	end
	
	-- All checks passed -> Looks like the equipped weapon is in fact the class' artifact weapon 
	return true;
	
end

-- TODO: Desc and bugfix for unavailable artifacts (red font -> scan tooltip?)
local function UpdateArtifactProgressCache()

	local characterName = UnitName("player");
	local realm = GetRealmName();
	local key = format("%s - %s", characterName, realm);
	
	-- Create new entry for characters that weren't cached before
	if cache[key] == nil then
		cache[key] =  {};
	end
	
local numSpecs = GetNumSpecializations();

	for i = 1, numSpecs do

		if not HasCorrectSpecArtifactEquipped() then -- also covers non-artifact weapons
			TotalAP.Debug("Attempted to cache artifact data, but the equipped weapon isn't the spec's artifact weapon");
			
		elseif i == GetSpecialization() then -- Only update cache for the current spec
				-- TODO: On login, this will be cached but not displays (since both is part of this function -> remove caching and call it before updating displays. That's better style, anyway)
				
			 -- Update cached values for the formerly active specs (which are now inactive); TODO: Scan all artifacts in real time instead? Can be done via socketing functions and data from DB\Artifacts after checking if they are available
			 artifactProgressCache[i] = {
				["thisLevelUnspentAP"] =  select(5, aUI.GetEquippedArtifactInfo()) or 0, 
				["numTraitsPurchased"] = select(6, aUI.GetEquippedArtifactInfo()) or 0, -- 0 -> artifact UI not loaded yet? TODO (first login = lua error, but couldn't reproduce)
				["artifactTier"] = select(13, aUI.GetEquippedArtifactInfo()) or 2, --  Assume 2 (for 7.2) as a default until it is cached next, if it hasn't been cached before, as most people are going to have the empowered traits unlocked ASAP
				["isIgnored"] = TotalArtifactPowerCache[key][i]["isIgnored"] or false, -- All specs are enabled by default (until they're disabled manually)
			};
			
			TotalAP.Debug(format("Updated artifactProgressCache for spec %d: %s traits purchased - %s unspent AP already applied - artifact tier = %d", i, artifactProgressCache[i]["numTraitsPurchased"], artifactProgressCache[i]["thisLevelUnspentAP"], artifactProgressCache[i]["artifactTier"]));

				-- Update the character's AP cache (to make sure the displayed info is no longer outdated... if it was loaded from savedVars earlier)
			--	specCache = artifactProgressCache;
				cache[key][i] = artifactProgressCache[i];
				TotalAP.Debug(format("Updated cached spec %d for character: %s - %s", i, characterName, realm));
				TotalArtifactPowerCache = cache;

		else -- For inactive specs, check if cached data exists (might be outdated, but it's better than nothing... right?)
			
			if cache[key][i] ~= nil then -- TODO: {} != nil => will break if edited manually (important later for the reset/clear cache option)
		
			-- TODO: Ugly 7.2 temporary fix for offspec artifacts that have been cached in 7.1.5 (=without artifactTier being saved)
				if cache[key][i]["artifactTier"] == nil or cache[key][i]["artifactTier"] == 0 then
					cache[key][i]["artifactTier"] = 2; -- TODO: Assuming tier 2 in 7.2 since that is what most active people will realistically have after the <1h opening quest chain - only matters if caching isn't updated. Will be updated ASAP and should be (and stay) correct afterwards
					TotalAP.Debug("Overrode artifactTier with 2 as it wasn't saved yet for the cached spec. This is a temporary 7.2 fix :(")
				end
				
				artifactProgressCache[i] = cache[key][i];
				TotalAP.Debug(format("Cached data exists from a previous session: spec = %i - traits = %i - AP = %i, tier = %i", i, cache[key][i]["numTraitsPurchased"], cache[key][i]["thisLevelUnspentAP"]), cache[key][i]["artifactTier"]);
			else  -- Initialise empty cache (for specs that have never been used) -> Necessary to allow them to be ignored/unignored without breaking everything
					TotalAP.Debug(format("No cached data exists for spec %d!", i));
		--		cache[key][i] = {}; -- TODO: This is pretty useless, except that it indicates which specs have been recognized but not yet scanned? - ACTUALLY it 
				
			
			
			
				-- cache[key][i] = {
					-- ["thisLevelUnspentAP"] =  0, -- TODO: Maybe use 100 (default AP) if artifact has been unlocked? Shouldn't really matter, though 
					-- ["numTraitsPurchased"] = 1, -- Rank 0 would break the API functions
					-- ["artifactTier"] = 1, --  Assume 1, because it hasn't been equipped and it won't change anything
					-- ["isIgnored"] = false, -- All specs are enabled by default (until they're disabled manually)
				-- } -- TODO: InitialiseCache(specNo) function

			end
		
	end
   end
   
end


-- TODO: Helper function
local function GetSpecDisplayOrder()

	local displayOrder = {}
	local order = 1 -- 0 is used to indicate ignored displays
	
	for i = 1, GetNumSpecializations() do 
	
		if artifactProgressCache[i] ~= nil and artifactProgressCache[i]["isIgnored"] then -- ignored spec -> order is 0 (hidden)
			displayOrder[i] = 0
		else -- proceed with the order as if there were no hidden displays
			displayOrder[i] = order
			order = order + 1
		end
	
	end

	return displayOrder
	
end

-- Update currently active specIcon, as well as the progress bar % fontStrings
local function UpdateSpecIcons()

	if IsEquippedItem(133755) then return end -- TODO: UpdateEverything? Also, why just spec icons but not the rest?
	
	local numSpecs = GetNumSpecializations();
	local numIgnoredSpecs = TotalAP.DBHandler.GetNumIgnoredSpecs()
	local displayOrder = GetSpecDisplayOrder() -- TODO: DRY
	
	
	
	
	if numSpecs == numIgnoredSpecs then
		TotalAP.Debug("Hiding spec icons because all currently specs are being ignored")
		TotalAPSpecIconsBackgroundFrame:Hide()
		return
	end
	
	-- Align background for spec icons
	local inset, border = settings.specIcons.inset or 1, settings.specIcons.border or 1; -- TODO
	TotalAPSpecIconsBackgroundFrame:SetSize(settings.specIcons.size + 2 * border + 2* inset, (numSpecs - numIgnoredSpecs) * (settings.specIcons.size + 2 * border + 2 * inset) + border);
	TotalAPSpecIconsBackgroundFrame:ClearAllPoints();
	
	
-- Reposition spec icons themselves
	local reservedInfoFrameWidth = 0;
	if settings.infoFrame.enabled then	
		reservedInfoFrameWidth = TotalAPInfoFrame:GetWidth() + 5;	-- In case it is hidden, the spec icons need to be moved to the left (or there'd be a gap between the button and the icons, which looks weird) -- TODO: 5 = spacing? (settings)
	end 
	
	local reservedButtonWidth = 0;
	 if settings.actionButton.enabled then	 -- No longer reposition displays to the left unless button is actually disabled entirely, since the button can be hidden temporarily without being set to invisible (if no items are in the player's inventory/the active spec is set to being ignored)
			if TotalAPButton:GetWidth() > TotalAPButtonFontString:GetWidth() then -- Use actual button width
			reservedButtonWidth = TotalAPButton:GetWidth()
		else -- Use button width + size of the right part of the buttonText's display (this is the only part that overlaps with the infoFrame otherwise)
			reservedButtonWidth = TotalAPButton:GetWidth() + (TotalAPButtonFontString:GetWidth() - TotalAPButton:GetWidth()) / 2  + 5  -- TODO: 5 = spacing? (settings)
		end	
	end
		
	TotalAPSpecIconsBackgroundFrame:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", reservedButtonWidth + reservedInfoFrameWidth, math.abs( max(settings.actionButton.maxResize, (numSpecs - numIgnoredSpecs)  * (settings.specIcons.size + 2 * border + 2 * inset) + border) -  TotalAPSpecIconsBackgroundFrame:GetHeight()) / 2);
	TotalAPSpecIconsBackgroundFrame:SetBackdropColor(0/255, 0/255, 0/255, 0.25); -- TODO
	
	for i = 1, numSpecs do

		-- Hide button if spec is being ignored
		if artifactProgressCache[i] ~= nil and artifactProgressCache[i]["isIgnored"] then  -- Hide obsolete indicator (obsolete because the current spec is being ignored)
		
		TotalAP.Debug("Hiding spec icon button for spec " .. i .. " because the spec is set to being ignored")
			TotalAPSpecIconButtons[i]:Hide();
			TotalAPSpecHighlightFrames[i]:Hide()
				
		else
		
			TotalAPSpecHighlightFrames[i]:Show()
			TotalAPSpecIconButtons[i]:Show()
			
		end 
	
	   -- TODO: When pushed, the border still shows? Weird behaviour, and it looks ugly (but is gone while using Masque...)
	   --TotalAPSpecIconButtons[i].NormalTexture(nil)
	  
		-- TODO: BG for text and settings for font/size/alignment/sharedmedia
		TotalAPSpecHighlightFrames[i]:SetSize(settings.specIcons.size + 2 * inset, settings.specIcons.size + 2 * inset); -- TODO 4x or 2x?
		TotalAPSpecHighlightFrames[i]:ClearAllPoints();
		TotalAPSpecHighlightFrames[i]:SetPoint("TOPLEFT", TotalAPSpecIconsBackgroundFrame, "TOPLEFT", border, - (border + (displayOrder[i] - 1) * (settings.specIcons.size + 3 * inset + border)));
	  
		-- Reposition spec icons
		TotalAPSpecIconButtons[i]:SetSize(settings.specIcons.size, settings.specIcons.size); -- TODO: settings.specIconSize. Also, 16 is too small for this?
		TotalAPSpecIconButtons[i]:ClearAllPoints();
		--TotalAPSpecIconButtons[i]:SetFrameStrata("HIGH");
		TotalAPSpecIconButtons[i]:SetPoint("TOPLEFT", TotalAPSpecHighlightFrames[i], "TOPLEFT", math.abs( TotalAPSpecHighlightFrames[i]:GetWidth() - settings.specIcons.size ) / 2, - math.abs( TotalAPSpecHighlightFrames[i]:GetHeight() - TotalAPSpecIconButtons[i]:GetHeight() ) / 2 );
    



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
		
		-- TODO: DRY
		if v["thisLevelUnspentAP"] and v["numTraitsPurchased"] then -- spec has been scanned, not just  ignored (so actual data exists) 
				
			
		
			TotalAP.Debug(format("Updating spec icons for spec %i from cached data"), i);
			-- Calculate available traits and progress using the cached data
			local numTraitsAvailable = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(v["numTraitsPurchased"],  v["thisLevelUnspentAP"] + inBagsTotalAP, v["artifactTier"]);
			local nextLevelRequiredAP = aUI.GetCostForPointAtRank(v["numTraitsPurchased"], v["artifactTier"]); 
			local percentageOfCurrentLevelUp = (v["thisLevelUnspentAP"]  + inBagsTotalAP) / nextLevelRequiredAP*100;
			
			TotalAP.Debug(format("Calculated progress using cached data for spec %s: %d traits available - %d%% towards next trait using AP from bags", k, numTraitsAvailable, percentageOfCurrentLevelUp)); -- TODO: > 100% becomes inaccurate due to only using cost for THIS level, not next etc?
		
		local fontStringText = "---"; -- TODO: For specs where no artifact data was available only
			-- TODO: Identical names, local vs addon namespace -> this is confusing, change it
			if numTraitsAvailable > 0  then
				fontStringText = format("x%d", numTraitsAvailable);
			else
				fontStringText = format("%d%%", percentageOfCurrentLevelUp);
			end
			
			TotalAPSpecIconButtons[i]:SetSize(settings.specIcons.size, settings.specIcons.size);
			-- Well, I guess they need to be reskinned = updated if Masque is used
		   MasqueUpdate(TotalAPSpecIconButtons[i], "specIcons");
		   
			
				if numTraitsAvailable > 0 and settings.specIcons.showGlowEffect and v["numTraitsPurchased"] < maxArtifactTraits then -- Text and glow effect are independent of each other; combining them bugs out one or the other (apparently :P)
					
					-- -- TODO: Confusing, comment and naming conventions.
					-- local ol = TotalAPSpecIconButtons[k].overlay;
					-- local ox, oy, ax, ay, bx, by = 0, 0, 0, 0, 0, 0;
					
					-- if ol ~= nil then
						-- ox, oy = TotalAPSpecIconButtons[k].overlay:GetSize();
						-- ax, ay = TotalAPSpecIconButtons[k].overlay.ants:GetSize();
						-- bx, by = TotalAPSpecIconButtons[k]:GetSize();
					
					
						-- if ( (ax / bx) >= 1.19 and (ay / by) >= 1.19) or ( (ox / bx) >= 1.4 and (oy / by) >= 1.4 ) then  -- ants bigger than overlay = bugged animation. They ought to be INSIDE the overlay, not outside
							
							-- TotalAP.Debug("Resetting spec icon overlay glow effect due to mismatching dimensions of button and overlay/ants");
							-- TotalAP.Debug(format("Overlay: %d %d - Ants: %d %d - Button: %d %d", ox, oy, ax, ay, bx, by));
							
							-- TotalAPSpecIconButtons[k].overlay:SetSize(bx * 1.4, by * 1.4);
							-- TotalAPSpecIconButtons[k].overlay.ants:SetSize(bx * 1.19, by * 1.19);
							
							-- ox, oy = TotalAPSpecIconButtons[k].overlay:GetSize();
							-- ax, ay = TotalAPSpecIconButtons[k].overlay.ants:GetSize();
							-- TotalAP.Debug(format("Changed to: Overlay: %d %d - Ants: %d %d - Button: %d %d", ox, oy, ax, ay, bx, by));
							-- FlashActionButton(TotalAPSpecIconButtons[k], false); -- turn off to re-set and make sure it displays at the proper size 
						-- end
					-- end
					TotalAP.Debug("Enabling spec icon glow effect for spec = " .. k)
					
					
					local overlay = TotalAPSpecIconButtons[k].overlay; -- Will be nil if overlay was never enabled before
					if overlay ~= nil then -- Check overlay size, should be 1.4 * parentSize basically or it will look bugged
						local w, h = overlay:GetSize();
						local bw, bh = overlay:GetParent():GetSize(); -- This is the button itself
						
						if math.floor(w) > math.floor(bw) * 1.4 or math.floor(h) > math.floor(bh) * 1.4 then
							TotalAP.Debug(format("Spell overlay is too big (%d x %d but should be %d x %d), needs to be refreshed", w, h, bw * 1.4, bh * 1.4));
						--	overlay:SetSize(bw * 1.4, bh * 1.4);
					--	ActionButton_HideOverlayGlow(TotalAPSpecIconButtons[k]);
							--FlashActionButton(TotalAPSpecIconButtons[k], false);
							--FlashActionButton(TotalAPSpecIconButtons[k], false);
							--overlay:SetSize(bw * 1.4, bh * 1.4);
							-- overlay:Hide();
							-- overlay.ants:Hide();
							-- if k == GetSpecialization() then 
								-- ActionButton_OverlayGlowAnimOutFinished(overlay.animOut) -- The animation is still visible otherwise; this flags it as unused and will prompt a new one to be created (with the proper dimensions) when the button is flashed again - which is below
							-- end
							
						--	TotalAP.Debug("Spell overlay animation finished and hidden -> will be re-enabled immediately (without a visible clue, hopefully)");
							
							--ActionButton_HideOverlayGlow(TotalAPSpecIconButtons[k]);
							--TotalAPSpecIconButtons[k].overlay = nil; -- Delete overlay to have the client create a new one with proper size the next time it is enabled
						else
							--FlashActionButton(TotalAPSpecIconButtons[k], true);
							TotalAP.Debug("Overlay size is now proportionate, no refresh necessary");
						end
					end
					
					-- local w, h = TotalAPSpecIconButtons[k]:GetSize();
					-- if math.floor(w) * > settings.specIcons.size * 1.4 or math.floor(h) > settings.specIcons.size * 1.4 then -- floor is necessary due to floating point precision inaccuracies vs. integer in settings
						-- TotalAP.Debug("Re-enabling glow effect due to bugged spell overlay size")
						-- TotalAP.Debug(format("Button dimensions are %i x %i but should be %i x %i", w, h, settings.specIcons.size, settings.specIcons.size))
						-- FlashActionButton(TotalAPSpecIconButtons[k], false);
					-- end
					
					FlashActionButton(TotalAPSpecIconButtons[k], true);
				else
					FlashActionButton(TotalAPSpecIconButtons[k], false);
				end
			
			-- Make sure the text display is moving accordingly to the frames (or it will detach and look buggy)
			if v["numTraitsPurchased"] < maxArtifactTraits then
				specIconFontStrings[k]:SetText(fontStringText);
			else
				specIconFontStrings[k]:SetText("---"); -- TODO: MAX? Empty? Anything else?
			end
			
			specIconFontStrings[k]:ClearAllPoints();
			specIconFontStrings[k]:SetPoint("TOPLEFT", TotalAPSpecHighlightFrames[k], "TOPRIGHT", settings.specIcons.border + 5,  settings.specIcons.border - math.abs(TotalAPSpecHighlightFrames[k]:GetHeight() - specIconFontStrings[k]:GetHeight()) / 2);
			TotalAP.Debug(format("Updating fontString for spec icon %d: %s", k, fontStringText));

		end
			
	end
  
  --TotalAP.Debug(format("Expected fontString width: %.0f, wrapped width: %.0f, InfoFrame width: %.0f, texture width: %.0f", numTraitsFontString:GetStringWidth(), numTraitsFontString:GetWrappedWidth(), TotalAPInfoFrame:GetWidth(), TotalAPInfoFrame.texture:GetWidth()));

	
	-- numTraitsFontString:SetPoint("BOTTOMLEFT", TotalAPInfoFrame, "TOPLEFT", - TotalAPButton:GetWidth() - 5 + (TotalAPButton:GetWidth() - numTraitsFontString:GetStringWidth())/2,  10); -- Center text if possible (not too big -> bigger than the button)


   -- Hide if any of the anchor frames aren't visible. TODO: depending on settings/infoFrameStyle ? Create hide/show function that handles all the checks and hides individual parts accordingly
	
	 

		if settings.specIcons.enabled then
			TotalAPSpecIconsBackgroundFrame:Show();
		else
			TotalAPSpecIconsBackgroundFrame:Hide();
		end
   end

 end

-- Update InfoFrame -> contains AP bar/progress displays
local function UpdateInfoFrame()
	
	-- if IsEquippedItem(133755) then return end -- TODO: This should be unnecessary after HasCorrectSpecArtifactEquipped() checks the equipped weapon
	
	-- Display bars for cached specs only (not cached -> invisible/hidden)
	local numIgnoredSpecs = TotalAP.DBHandler.GetNumIgnoredSpecs()
	
	
	
	-- TODO: Whoops. I made a mess - got to clean it up later
	for k, v in pairs(artifactProgressCache) do -- Display InfoFrame
			-- Intial pass to allow the InfoFrame to be sized correctly (size depends on number of ignored specs)
		if artifactProgressCache[k]["isIgnored"] then -- Hide progress bars for this particular spec
			TotalAP.Debug("Hiding bar display for spec " .. k .. " because it is set to being ignored")
			
			-- ... and move existing progress bars to align properly with the now-smaller InfoFrame height
			--numIgnoredSpecs = numIgnoredSpecs + 1 -- TODO: DBHandler or something so I can skip all this nonsense?
			TotalAPProgressBars[k]:Hide()
			TotalAPUnspentBars[k]:Hide()
			TotalAPInBagsBars[k]:Hide()
		else
		
			TotalAPProgressBars[k]:Show()
			TotalAPUnspentBars[k]:Show()
			TotalAPInBagsBars[k]:Show()
		
		end
	
	end
	
	-- Align info frame so that it always stays next to the action button (particularly important during resize and scaling operations)
	local border, inset = settings.infoFrame.border or 1, settings.infoFrame.inset or 1; -- TODO
	TotalAPInfoFrame:SetSize(100 + 2 * border + 2 * inset, 2 * border + (settings.infoFrame.barHeight + 2 * inset + border) * (GetNumSpecializations() - numIgnoredSpecs)); -- info frame height = info frame border + (spec icon height + spec icon spacing) * numSpecs. TODO: arbitrary width/height (scaling) vs 
	--arbitrary width/height (scaling) vs fixed, settings?
	
		-- Move bars to the left, but only if action button is actually disabled (and not hidden temporarily from not having any AP items in the player's inventory)
	local reservedButtonWidth = 0;
	if settings.actionButton.enabled then -- TODO: DRY / GUI -> GetReservedButtonWidth (only for DefaultView?)
		if TotalAPButton:GetWidth() > TotalAPButtonFontString:GetWidth() then -- Use button width
			reservedButtonWidth = TotalAPButton:GetWidth()
		else -- Use button width + size of the right part of the buttonText's display
			reservedButtonWidth = TotalAPButton:GetWidth() + (TotalAPButtonFontString:GetWidth() - TotalAPButton:GetWidth()) / 2  + 5  -- TODO: 5 = spacing? (settings)
		end
		
	end
	
	TotalAPInfoFrame:ClearAllPoints(); 
	TotalAPInfoFrame:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", reservedButtonWidth,  math.abs(TotalAPInfoFrame:GetHeight() - settings.actionButton.maxResize) / 2); 
	
		--  Only show when settings allow it
	if settings.infoFrame.enabled and not ( numIgnoredSpecs == GetNumSpecializations() ) then TotalAPInfoFrame:Show();
	else TotalAPInfoFrame:Hide(); end
	 
	
	
	local displayOrder = GetSpecDisplayOrder() -- TODO: Only necessary if numIgnoredSpecs > 0 (and it should only be called once -> local to addon scope instead)
	
	
	
	for k, v in pairs(artifactProgressCache) do -- Display progress bars
	
		if v["thisLevelUnspentAP"] and v["numTraitsPurchased"] then -- spec hasn't been scanned, but possibly ignored (so no actual data exists) 
			
		
	
			local percentageUnspentAP = min(100, math.floor(v["thisLevelUnspentAP"] / aUI.GetCostForPointAtRank(v["numTraitsPurchased"], v["artifactTier"]) * 100)); -- cap at 100 or bar will overflow
			local percentageInBagsAP = min(math.floor(inBagsTotalAP / aUI.GetCostForPointAtRank(v["numTraitsPurchased"], v["artifactTier"]) * 100), 100 - percentageUnspentAP); -- AP from bags should fill up the bar, but not overflow it
			TotalAP.Debug(format("Updating percentage for bar display... spec %d: unspentAP = %s, inBags = %s" , k, percentageUnspentAP, percentageInBagsAP));
			
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
			TotalAPProgressBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset, - ( (2 * displayOrder[k] - 1)  * inset + displayOrder[k] * border + (displayOrder[k] - 1)  * settings.infoFrame.barHeight))
			
	--TotalAP.ChatMsg(k .. ", " .. displayOrder[k])
	--TempTAPDisplayOrder = displayOrder
			
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
			TotalAPUnspentBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset, - ( (2 * displayOrder[k] - 1)  * inset + displayOrder[k] * border + (displayOrder[k] - 1) * settings.infoFrame.barHeight));
			
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
			TotalAPInBagsBars[k]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPLEFT", 1 + inset + TotalAPUnspentBars[k]:GetWidth(), - ( (2 * displayOrder[k] - 1)  * inset + displayOrder[k] * border + (displayOrder[k] - 1) * settings.infoFrame.barHeight))

			-- If artifact is maxed, replace overlay bars with a white one to indicate that fact
			if v["numTraitsPurchased"] >= maxArtifactTraits then
				TotalAPUnspentBars[k]:SetSize(100, settings.infoFrame.barHeight); -- maximize bar to take up all the available space
				TotalAPUnspentBars[k].texture:SetVertexColor(239/255, 229/255, 176/255, 1); -- turns it white; TODO: settings.infoFrame.progressBar.maxRed etc to allow setting a custom colour for maxed artifacts (later on)
				TotalAPInBagsBars[k].texture:SetVertexColor(settings.infoFrame.progressBar.red/255, settings.infoFrame.progressBar.green/255, settings.infoFrame.progressBar.blue/255, 0); -- turns it invisible (alpha = 0%)
			end
			
		end
		
	end
	

	
	--TotalAPInfoFrame:SetPoint("TOPLEFT", TotalAPButton, "TOPRIGHT", 5,  (TotalAPInfoFrame:GetHeight() - TotalAPButton:GetHeight()) / 2); 
	
	--TotalAPInfoFrame:SetPoint("LEFT", TotalAPButton, "RIGHT", 5, 0); 
	--TotalAPInfoFrame:SetPoint("BOTTOMRIGHT", TotalAPButton, 2 * TotalAPButton:GetWidth() + 5, 0);

	
	-- TODO: Show AP amount as well as any other tooltip information, all optional via settings

	

	

end

-- Updates the action button whenever necessary to re-scan for AP items
-- TODO: This is quite messy, due to the button being the only and primary component in early addon versions (that was then change to be just one of many)
local function UpdateActionButton()

	-- Hide button if artifact is already maxed (TODO: 7.1 only?)
	if artifactProgressCache[GetSpecialization()] ~= nil and artifactProgressCache[GetSpecialization()]["numTraitsPurchased"] >= maxArtifactTraits and not InCombatLockdown() then
		TotalAP.Debug("Hiding action button due to maxed out artifact weapon");
		TotalAPButton:Hide();
		return
	end

	-- Hide button if spec is being ignored
	if artifactProgressCache[GetSpecialization()] ~= nil and artifactProgressCache[GetSpecialization()]["isIgnored"] then
		TotalAP.Debug("Hiding action button because the current spec is set to being ignored")
		TotalAPButton:Hide();
		return
	end
	
	-- Also only show button if AP items were found, an artifact weapon is equipped in the first place, settings allow it, addons aren't locked from the player being in combat, and the artifact UI is available
	if (numItems > 0 or foundKnowledgeTome) and TotalAPButton and not InCombatLockdown() and settings.actionButton.enabled and currentItemID and aUI and HasCorrectSpecArtifactEquipped() then
	--and (HasArtifactEquipped()  and not IsEquippedItem(133755)) then  -- TODO: Proper support for the Underlight Angler artifact (rare fish instead of AP items)
		
		currentItemTexture = GetItemIcon(currentItemID) or "";
		TotalAPButton.icon:SetTexture(currentItemTexture);
		TotalAP.Debug(format("Set currentItemTexture to %s", currentItemTexture));
	
		local itemName = GetItemInfo(currentItemLink) or "";
		if itemName == "" then -- item isn't cached yet -> skip update until the next BAG_UPDATE_DELAYED (should only happen after a fresh login, when for some reason there are two subsequent BUD events)
			TotalAP.Debug("itemName not cached yet. Skipping this update...");
			return false;
		end

		TotalAP.Debug(format("Current item bound to action button: %s = % s", itemName, currentItemLink));
		
		TotalAPButton:SetAttribute("type", "item");
		TotalAPButton:SetAttribute("item", itemName);
		
		TotalAP.Debug(format("Changed item bound to action button to: %s = % s", itemName, currentItemLink));
		
		MasqueUpdate(TotalAPButton, "itemUseButton");
		
		
	
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
		if settings.actionButton.showGlowEffect and numTraitsAvailable > 0 or
			-- TODO: DRY - once all AK items are working properly, this should be refactored along with the tooltip check
			currentItemID == 139390		-- Artifact Research Notes (max. AK 25)
			or currentItemID == 146745	-- Artifact Research Notes (max. AK 50)
			or currentItemID == 147860 	-- Empowered Elven Tome (7.2)
			or currentItemID == 144433	--  Artifact Research Compendium: Volume I
			or currentItemID == 144434	-- Artifact Research Compendium: Volumes I & II
			or currentItemID == 144431	-- Artifact Research Compendium: Volumes I-III
			or currentItemID == 144395	-- Artifact Research Synopsis
			or currentItemID == 147852	-- Artifact Research Compendium: Volumes I-V
			or currentItemID == 147856	-- Artifact Research Compendium: Volumes I-IX
			or currentItemID == 147855	-- Artifact Research Compendium: Volumes I-VIII
			or currentItemID == 144435	-- Artifact Research Compendium: Volumes I-IV
			or currentItemID == 147853	-- Artifact Research Compendium: Volumes I-VI
			or currentItemID == 147854	-- Artifact Research Compendium: Volumes I-VII
			or currentItemID == 141335	-- Lost Research Notes (TODO: Is this even ingame? -> Part of the obsolete Mage quest "Hidden History", perhaps?)
			then -- research notes -> always flash regardless of current progress
			FlashActionButton(TotalAPButton, true);
			TotalAP.Debug("Activating button glow effect while processing UpdateActionButton...");
		else
			FlashActionButton(TotalAPButton, false);
			TotalAP.Debug("Deactivating button glow effect while processing UpdateActionButton...");
		end
		
		-- Add current item's AP value as text (if enabled)
		if settings.actionButton.showText and not foundKnowledgeTome then
		--if settings.actionButton.showText and inBagsTotalAP > 0 and currentItemAP > 0 then
			
			if numItems > 1 then -- Display total AP in bags
				TotalAPButtonFontString:SetText(TotalAP.Utils.FormatShort(currentItemAP, true) .. "\n(" .. TotalAP.Utils.FormatShort(inBagsTotalAP, true) .. ")") -- TODO: More options/HUD setup - planned once advanced config is implemented via AceConfig
			else
				TotalAPButtonFontString:SetText(TotalAP.Utils.FormatShort(currentItemAP, true))
			end
				
		else
			TotalAPButtonFontString:SetText("")
		end
		
		-- Reposition button (and attached frames) AFTER updating their contents, so that the size will be corrected
		TotalAPButtonFontString:ClearAllPoints()
		TotalAPButtonFontString:SetPoint("TOPLEFT", TotalAPButton, "BOTTOMLEFT", math.ceil(TotalAPButton:GetWidth() - (TotalAPButtonFontString:GetWidth())) / 2 , -5) -- TODO: hardcoded border and spacing (padding on the inside, via settings later), ditto for spacing -5
			
		TotalAPButton:ClearAllPoints();
		TotalAPButton:SetPoint("BOTTOMLEFT", TotalAPAnchorFrame, "TOPLEFT", 0, math.abs(settings.actionButton.maxResize + TotalAPButtonFontString:GetHeight() + 5 - TotalAPButton:GetHeight()) / 2); -- TODO: 3 = distance should not be hardcoded -> save for advanced HUD config (later)
	
			
		
		-- Show after everything is done, so the spell overlay doesn't "flicker" visibly
		TotalAPButton:Show();
	else
		TotalAPButton:Hide();
		TotalAP.Debug("Hiding action button after processing UpdateActionButton");
	end
end	

-- Update anchor frame -> Decide whether to hide or show it, mainly, based on general criteria that doesn't affect the other components
local function UpdateAnchorFrame()
	
		if UnitLevel("player") < 98 then 
			TotalAP.Debug("Hiding display because character level is too low for Legion content (and artifact weapons)");
			TotalAPAnchorFrame:Hide(); 
		end
		
		if not settings.enabled then
			TotalAP.Debug("Hiding display, because it was disabled manually (regardless of individual component's visibility)")
			TotalAPAnchorFrame:Hide(); 
		end
end

-- Update ALL the info! It should still be possible to only update individual parts (for later options/features), hence the separation here
local function UpdateEverything()
	
	if InCombatLockdown() then -- Frames can't be shown, hidden, or modified -> events are not a reliable way to detect this
		TotalAP.Debug("Skipping update due to  combat lockdown");
		return;
	end
	
	if ( TotalAP.DBHandler.GetNumIgnoredSpecs() == GetNumSpecializations() ) and not allSpecsIgnoredWarningGiven then -- Print warning and instructions on how to reset ignored specs... just in case -- TODO: use verbose setting for optional warnings/notices like this?
	
		TotalAP.ChatMsg(format(L["All specs are set to being ignored for this character. Type %s unignore to reset them if this is unintended."], "/" .. TotalAP.Controllers.GetSlashCommandAlias()))
		allSpecsIgnoredWarningGiven = true -- TODO: Lame, but whatever
	
	end
	
	-- Proceed as usual
		UpdateArtifactProgressCache();
	
		UpdateAnchorFrame();
		UpdateActionButton();
	
	
		UpdateInfoFrame();
		UpdateSpecIcons();

end

-- TODO: Temp crutch for the migration process
TotalAP.Controllers.UpdateGUI = UpdateEverything


-- Initialise spec icons and active/inactive spec indicators
local function CreateSpecIcons()
	
	-- Create spec icons for all of the classes specs (min 2  => Demon Hunter, max 4 => Druid)
	local numSpecs = GetNumSpecializations(); -- TODO: dual spec -> GetNumSpecGroups? Should be obsolete in Legion
	TotalAP.Debug(format("Available specs: %d, specGroups: %d", numSpecs, GetNumSpecGroups()));

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
		
		--TotalAP.Debug(format("Created specIcon for spec %d: %s ", i, specName));
		
		TotalAPSpecIconButtons[i] = CreateFrame("Button", "TotalAPSpecIconButton" .. i, TotalAPSpecHighlightFrames[i], "ActionButtonTemplate", "SecureActionButtonTemplate");
		TotalAPSpecIconButtons[i]:SetFrameStrata("MEDIUM"); -- I don't like this, but Masque screws with the regular parent -> child draw order somehow
		
		specIconFontStrings[i] = TotalAPSpecIconButtons[i]:CreateFontString("TotalAPSpecIconFontString" .. i, "OVERLAY", "GameFontNormal"); -- TODO: What frame as parent? There isn't really one other than the respective icon?
		
		TotalAPSpecIconButtons[i]:SetScript("OnClick", function(self, button) -- When clicked, change spec accordingly to the button's icon

			-- Hide border etc again (for some reason it will show if a button is clicked, until the next update that disables them). Masque obviously doesn't like this at all.
			if not Masque then TotalAPSpecIconButtons[i]:SetNormalTexture(nil); end
		
			-- Change spec as per the player's selection (if it isn't active already)
			if GetSpecialization() ~= i then
			
				-- Dismount if not flying (wouldn't want to kill the player, now would we?) / SHOULD also cancel shapeshifts of any kind, at least out of combat -- TODO: Setting to allow forced dismount even if flying/Test with chakras and other "weird" shapeshifts
				if (IsMounted() or GetShapeshiftForm() > 0) and not (IsFlying() or InCombatLockdown() or UnitAffectingCombat("player")) then
					Dismount()
					CancelShapeshiftForm() -- TODO: Protected -> may cause issues if called in combat? (Not sure if InCombatLockdown is enough to detect this reliably)
				end
				
				TotalAP.Debug(format("Current spec: %s - Changing spec to: %d (%s)", GetSpecialization(), i, specName)); -- not in combat etc
				SetSpecialization(i);
			end
	end);
		
		TotalAPSpecIconButtons[i]:SetScript("OnEnter", TotalAP.GUI.Tooltips.ShowSpecIconTooltip)
		
		TotalAPSpecIconButtons[i]:SetScript("OnLeave", TotalAP.GUI.Tooltips.HideSpecIconTooltip)
		
		-- TODO: Button script handlers in separate file
	   TotalAPSpecIconButtons[i]:SetScript("OnMouseUp", function(self, button) -- right clicked ->
			
			--print("Clicked SpecIcon button " .. i .. " with " .. button)
			 if button ~= "RightButton" then return end

			 -- Add spec to ignored specs (actually, it is flagged as "ignored" for the current character only)
			 local characterName = UnitName("player")
			 local realm = GetRealmName()
			 local key = format("%s - %s", characterName, realm)

			 
			local cache = TotalArtifactPowerCache -- TODO: This can be removed later (as cache is available in the addon itself) -> Needs better handling as cache won't always be updated properly? (DBHandler -> CacheHandler)
			 -- It is safe to assume that the key exists, as the cache has been updated at least once (when logging in) = tables have been created
			 if cache[key][i] and cache[key][i]["isIgnored"] then  -- Spec is already being ignored
				TotalAP.Debug("Attempting to ignore spec, but spec " .. i .. " is already ignored for character " .. key)
				return
			 end
			 
			 TotalAP.ChatMsg(format(L["Ignoring spec %d for character %s"], i, key))
			 TotalAP.ChatMsg(format(L["Type %s to reset all currently ignored specs for this character"], "/" .. TotalAP.Controllers.GetSlashCommandAlias() .. " unignore")) -- TODO: Only show this once?

			 -- Specs might not have been initialised (if they haven't been switched to, ever)
			if not cache[key][i] then cache[key][i] = { isIgnored = true }  -- TODO: InitialiseCache(specNo) function
			else
				cache[key][i]["isIgnored"] = true
			end
			 
			 UpdateEverything() -- TODO
			 
		  end
	   )
 
		
		
		-- TODO: Ordering so that main spec (active) is first? Hmm. Maybe an option to consider only some specs / set a main spec?
		
	-- TODO: What for chars below lv10? They don't have any spec.	  	if spec then -- no spec => nil (below lv10 -> shouldn't matter, as no artifact weapon equipped means everything will be hidden regardless of the player's spec)
	--local spec = GetSpecialization();
	--	local classDisplayName, classTag, classID = UnitClass("player");
		
		-- Set textures (only needs to be done once, as specs are generally static)
		local _, specName, _, specIcon, _, specRole = GetSpecializationInfo(i);
		TotalAPSpecIconButtons[i].icon:SetTexture(specIcon);
		TotalAP.Debug(format("Setting specIcon texture for spec %d (%s): |T%s:%d|t", i, specIcon,  specIcon, settings.specIconSize));
		
		-- register, enable etc TODO

		-- TODO: Only show buttons, enable click features etc. for specs that actually exist
		-- TODO: Align properly, 2-3-4 specs = center vertically

		
		--TotalAPSpecIconButtons[i]:SetFrameStrata("MEDIUM");
		--TotalAPSpecIconButtons[i]:SetClampedToScreen(true);
	
		--TotalAPSpecIconButtons[i]:ClearAllPoints();
	--	TotalAPSpecIconButtons[i]:SetPoint("TOPLEFT", TotalAPInfoFrame, "TOPRIGHT", 5, 0 - (i-1) * (settings.specIconSize + 2)); -- TODO: consider settings.specIconSize to calculate position and spacing dynamically, also depnding on number of specs to center them vertically: size*numspecs = totalSize; infoframeSize
		--TotalAP.Debug(format("specIconButton %d -> SetPoint to %d, %d", i, 5, 0 - (i-1) * (settings.specIconSize + 2)));
		
		--TotalAPSpecIconButtons[i]:Show();
		
		-- TODO: Should they be draggable? If so, background frame, highlights, icons? Which?
		
			-- Hide default button template's visual peculiarities - I wanted just want a spec icon that can be pushed (to change specs) and styled (via Masque)
		
		-- Remove ugly borders. Masque will yell if I do this, though .(
		if not Masque then -- TODO: Some part of the border must still be there, as it glitches the spell overlay ? (ants texture perhaps?)
			TotalAPSpecIconButtons[i].Border:Hide();
		  --TotalAPSpecIconButtons[i]:SetBorder(nil);
			TotalAPSpecIconButtons[i]:SetPushedTexture(nil); 
		   --TotalAPSpecIconButtons[i].NormalTexture:Hide();
			TotalAPSpecIconButtons[i]:SetNormalTexture(nil); 
		end
		
		TotalAPSpecIconButtons[i]:SetSize(settings.specIcons.size, settings.specIcons.size); -- Set initial size here to make sure the glow effects will be applied correctly. TODO: For now it doesn't matter since the size never changes, but the option would prompt an update if specIcons.size was changed later on
		
		MasqueRegister(TotalAPSpecIconButtons[i], "specIcons"); -- Register with Masque AFTER the initial setup, or it won't update without calling MasqueUpdate => looks odd
	end
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

		-- Tooltip script handlers
		TotalAPProgressBars[i]:SetScript("OnEnter", TotalAP.GUI.Tooltips.ShowArtifactKnowledgeTooltip)
		--function(self, button) TotalAP.ChatMsg(self:GetName() .. " " .. button) end)
		
		TotalAPProgressBars[i]:SetScript("OnLeave", TotalAP.GUI.Tooltips.HideArtifactKnowledgeTooltip)
		
	end
	
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
	
	-- TotalAPInfoFrame:SetScript("OnDragStart", function(self)
		
		-- TotalAP.Debug("TotalAPInfoFrame is being dragged")
		
		-- if self:IsMovable()
			-- then
				-- self:StartMoving();
				-- self.isMoving = true;
			-- end
	-- end);
	
	-- TotalAPInfoFrame:SetScript("OnUpdate", function(self)
		-- if self.IsMoving then
		--	self.texture:SetAllPoints(self);
			-- UpdateInfoFrame(); -- to make sure the info is placed correctly at all times
		-- end
	-- end);
	
	-- TotalAPInfoFrame:SetScript("OnDragStop", function(self)
		
		-- self:StopMovingOrSizing();
		-- local point, relPoint, x, y = self:GetPoint();
		-- TotalAP.Debug(format("TotalAPInfoFrame received drag with coords %s %d %d", point, x, y));
		-- self.isMoving = false;
		-- UpdateInfoFrame(); -- TODO: For testing purposes only--self:Hide();

	-- end);
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
			FlashActionButton(TotalAPButton, false); 
			UpdateEverything();
			-- TODO: Updates should be done by event frame, not button... but alas
		end)
	
end

-- Initialise action button (serves as anchor for the other frames and buttons)
local function CreateActionButton()
	
	if not TotalAPButton then -- if button already exists, this was called before -> Skip initialisation
		
		TotalAPButton = CreateFrame("Button", "TotalAPButton", TotalAPAnchorFrame, "ActionButtonTemplate, SecureActionButtonTemplate");
		TotalAPButton:SetFrameStrata("MEDIUM");
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
		TotalAP.Debug(format("Set currentItemTexture to %s", currentItemTexture));
		
		TotalAP.Debug(format("Created button with currentItemTexture = %s (currentItemID = %d)", currentItemTexture, currentItemID));
		

		-- [[ Action handlers ]] --
		TotalAPButton:SetScript("OnEnter", function(self)  -- (to show the tooltip on mouseover)
		
			if currentItemID then
			
				GameTooltip:SetOwner(TotalAPButton, "ANCHOR_RIGHT");
				GameTooltip:SetHyperlink(currentItemLink);
				TotalAP.Debug(format("OnEnter -> mouse entered TotalAPButton... Displaying tooltip for currentItemID = %s.", currentItemID));
				
				local itemName = GetItemInfo(currentItemLink) or "<none>";
				TotalAP.Debug(format("Current item bound to action button: %s = % s", itemName, currentItemLink));
				TotalAP.Debug(format("Attributes: type = %s, item = %s", self:GetAttribute("type") or "<none>", self:GetAttribute("item") or "<none>"));
			
			else  TotalAP.Debug("OnEnter  -> mouse entered TotalAPButton... but currentItemID is nil so a tooltip can't be displayed!"); end
			
			TotalAP.Debug(format("Button size is width = %d, height = %d, settings.actionButtonSize = %d", self:GetWidth(), self:GetHeight(), settings.actionButtonSize or 0));
			
		end);
		
		TotalAPButton:SetScript("OnLeave", function(self)  -- (to hide the tooltip afterwards)
			GameTooltip:Hide();
		end);
			
		TotalAPButton:SetScript("OnHide", function(self) -- (to hide the tooltip when leaving the button)
			TotalAP.Debug("Button is being hidden. Disabled click functionality...");
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

		
		--- Will display the currently mapped item's AP amount (if enabled) later
		TotalAPButtonFontString = TotalAPButton:CreateFontString("TotalAPButtonFontString", "OVERLAY", "GameFontNormal");
		--TotalAPButtonFontString:SetTextColor(0x00/255,0xCC/255,0x80/255,1) -- TODO. via settings
		
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
			
			TotalAP.Debug(format("MasterFrame is moving, width = %d, height = %d", self:GetWidth(), self:GetHeight()));
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

			if InCombatLockdown() then -- Prevent taint by accidentally trying to hide/show button or even glow effects
				return
			end
		
			if event == "BAG_UPDATE_DELAYED" then  -- inventory has changed -> recheck bags for AP items and update button display

				TotalAP.Debug("Scanning bags and updating action button after BAG_UPDATE_DELAYED...");
				CheckBags();
				UpdateEverything();
				
			elseif event == "PLAYER_REGEN_DISABLED" or event == "PET_BATTLE_OPENING_START" or (event == "UNIT_ENTERED_VEHICLE" and unit == "player") then -- Hide button while AP items can't be used
				
				TotalAP.Debug("Player entered combat, vehicle, or pet battle... Hiding button!");
				if event ~= "PLAYER_REGEN_DISABLED" or settings.hideInCombat and not InCombatLockdown() then -- always hide in vehicle/pet battle, regardless of settings
					self:Hide();
				end
				UpdateEverything();
				self:UnregisterEvent("BAG_UPDATE_DELAYED");
				
			elseif not UnitInVehicle("player") and event == "PLAYER_REGEN_ENABLED" or event == "PET_BATTLE_CLOSE" or (event == "UNIT_EXITED_VEHICLE" and unit == "player") then -- Show button once they are usable again
			
				--if numItems > 0 and not InCombatLockdown() and settings.showActionButton then 
				TotalAP.Debug("Player left combat , vehicle, or pet battle... Updating action button!");
				if not InCombatLockdown() then
					self:Show(); 
				else
					TotalAP.Debug("Not showing AnchorFrame to prevent taint, as UI is still in combat lockdown")
				end
				
				--TotalAP.Debug("Player left combat , vehicle, or pet battle... Showing button!");
				-- end
				TotalAP.Debug("Scanning bags and updating action button after combat/pet battle/vehicle status ended...");
				CheckBags();	-- TODO: Fixes the issue with WQ / world bosses that complete, but lock the player in combat for a longer period -> needs to be tested with AP reward WQ at a world boss still, but it should suffice
				UpdateEverything();
				
				self:RegisterEvent("BAG_UPDATE_DELAYED");
					
			elseif event == "ARTIFACT_XP_UPDATE" or event == "ARTIFACT_UPDATE" then -- Recalculate tooltip display and update button when AP items are used or new traits purchased
				
				TotalAP.Debug("Updating action button after ARTIFACT_UPDATE or ARTIFACT_XP_UPDATE...");
				CheckBags();
				UpdateEverything();
				
	
		end
	end);
end

	-- Register all relevant events required to update the button -> addon starts working from here on
local function RegisterUpdateEvents()

		
		-- PLAYER_LEAVE_COMBAT
		TotalAPAnchorFrame:RegisterEvent("BAG_UPDATE_DELAYED"); -- Possible inventory change -> Re-scan bags
		TotalAPAnchorFrame:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Player entered combat -> Hide button
		TotalAPAnchorFrame:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Player left combat -> Show button
		TotalAPAnchorFrame:RegisterEvent("PET_BATTLE_OPENING_START"); -- Player entered pet battle -> Hide button
		TotalAPAnchorFrame:RegisterEvent("PET_BATTLE_CLOSE"); -- Player left pet battle -> Show button
		TotalAPAnchorFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
		TotalAPAnchorFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
		TotalAPAnchorFrame:RegisterEvent("ARTIFACT_XP_UPDATE"); -- gained AP
		TotalAPAnchorFrame:RegisterEvent("ARTIFACT_UPDATE"); -- new trait learned?

		-- TODO: Only one event handler frame (and perhaps one UpdateEverything method) that updates all the indicators as well as the action button? (tricky if events like dragging are only given to the button by WOW?)
end

	
-- Display tooltip when hovering over an AP item
-- TODO: Secure hook (if possible) to avoid taint? Haven't seen any issues but it could become one later
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
					self:AddLine(format("\n" .. L["%s Artifact Power in bags (%d items)"], TotalAP.Utils.FormatShort(inBagsTotalAP, true), numItems), 230/255, 204/255, 128/255);
				else
					self:AddLine(format("\n" .. L["%s Artifact Power in bags"], TotalAP.Utils.FormatShort(inBagsTotalAP, true)) , 230/255, 204/255, 128/255);
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

 
-- Standard methods (via AceAddon) -> They use the local object and not the shared container variable (which are for the modularised functions in other lua files)
-- TODO: Use AceConfig to create slash commands automatically for simplicity?
function AceAddon:OnInitialize() -- Called on ADDON_LOADED
	
	LoadSettings();  -- from saved vars
	CreateAnchorFrame(); -- anchor for all other frames -> needs to be loaded before PLAYER_LOGIN to have the game save its position and size -- TODO: move to GUI/AceGUI

	CreateActionButton() -- Ditto, as its size is being saved by the client
	
	-- TODO: via AceGUI?
	-- TODO: Allow custom views to be loaded instead of (or in addition to) the default one, and toggling of views, respectively
	-- TotalAP.GUI.CreateView("DefaultView") -- Create view/layout that will later be rendered (shown) and updated
	-- TotalAP.GUI.SetActiveView("DefaultView") -- Enable default view (TODO: Obsolete? Should be done by default)
	--TotalAP.Controllers.ShowGUI() -- Display whichever view is currently active (TODO: Views aren't fully implemented yet :| -- This is always the default view, for now)
	
	-- Register slash commands
	self:RegisterChatCommand(TotalAP.Controllers.GetSlashCommand(), TotalAP.Controllers.SlashCommandHandler)
	self:RegisterChatCommand(TotalAP.Controllers.GetSlashCommandAlias(), TotalAP.Controllers.SlashCommandHandler_UsedAlias) -- alias is /ap instead of /totalap - with the latter providing a fallback mechanism in case some other addon chose to use /ap as well or for lazy people (like me)
	
	-- Add keybinds to Blizzard's KeybindUI
	TotalAP.Controllers.RegisterKeybinds()
end

function AceAddon:OnEnable()	-- Called on PLAYER_LOGIN or ADDON_LOADED (if addon is loaded-on-demand)
	
	local clientVersion, clientBuild = GetBuildInfo(); 
			
			-- Those could be created earlier, BUT: Talent info isn't available sooner, and those frames are anchored to the AnchorFrame anyway -> Initial position doesn't matter as it is updated automatically (TODO: TALENT or SPEC info?)
			
			CreateInfoFrame();
			CreateSpecIcons(); 
			
			if settings.showLoginMessage then TotalAP.ChatMsg(format(L["%s %s for WOW %s loaded!"], addonName, addonVersion, clientVersion)); end
			
			TotalAP.Debug(format("Registering button update events", event));
			RegisterUpdateEvents();
			
end

function AceAddon:OnDisable()
	
	-- Shed a tear because the addon was disabled ;'(
	
end