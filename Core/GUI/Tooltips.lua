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


--- GUI\Tooltips.lua
-- @module GUI

---	Tooltips.lua.
--	Dynamic tooltip text functions that can be hooked to the appropriate events by the GUI controller
-- @section Tooltips


local addonName, TotalAP = ...

if not TotalAP then return end

-- AceLocale localization table
local L = TotalAP.L


--- This is the mouseover-tooltip for progress bars, based on Blizzard's ForgeDisplay (icon to the top-left of the ArtifactFrame)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
-- @param[opt] hide Whether or not the tooltip will be hidden. Defaults to false
local function ArtifactKnowledgeTooltipFunction(self, button, hide)

	local specID = tonumber((self:GetName()):match("(%d+)$")) -- Derive spec from frame's name, as they're numbered accordingly -> e.g., TotalAPProgressBar1 for spec = 1

	local fqcn = TotalAP.Utils.GetFQCN() -- Fully-qualified character name -> e.g., "Cakechart - Outland". No parameter = use currently logged in character
	
	-- Retrieve this spec's artifact name from the DB
	local _, _, classID = UnitClass("player"); -- 1 to 12
	local itemID = TotalAP.DB.GetArtifactItemID(classID, specID) -- index 1 => Pick first (lowest item ID) match -> should be mainhand weapon (but probably doesn't matter, because MH + OH are created from just one item when equipped)
	local artifactName = GetItemInfo(itemID)  --  since the spec has been cached the item name should be available already... otherweise, the first line won't show until the tooltip is displayed again and the server sent the item's name
	--Note: This is NOT the individual weapon's name if it consists of mainhand / offhand, but the "general item"'s name that they turn into when not equipped (e.g., "Warswords of the Valarjar")
	
	-- Load cached values
	local numTraitsPurchased = TotalAP.Cache.GetValue(fqcn, specID, "numTraitsPurchased")
	local inBagsTotalAP = TotalAP.inBagsTotalAP
	local maxAvailableAP = TotalAP.Cache.GetValue(fqcn, specID, "thisLevelUnspentAP") + inBagsTotalAP
	local tier = TotalAP.Cache.GetValue(fqcn, specID, "artifactTier")
	
	-- Calculate progress from cached values
	local maxAttainableRank = numTraitsPurchased + TotalAP.ArtifactInterface.GetNumRanksPurchasableWithAP(numTraitsPurchased, maxAvailableAP, tier) 
	local progressPercent = TotalAP.ArtifactInterface.GetProgressTowardsNextRank(numTraitsPurchased, maxAvailableAP, tier)
	local knowledgeLevel = TotalAP.ArtifactInterface.GetArtifactKnowledgeLevel() 
	
	-- Calculate shipment data (for Artifact Research Notes)
	local shipmentsReady = TotalAP.ArtifactInterface.GetNumAvailableResearchNotes()
	local shipmentsTotal = 2 -- Could use the same interface (maxShipments is returned by the API), but no more than 2 can actually be queued anyway... so, whatever
	local timeLeft, timeLeftString = TotalAP.ArtifactInterface.GetTimeUntilNextResearchNoteIsReady()

	  GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	  
    if artifactName then
		GameTooltip:AddLine(format("%s", artifactName), 230/255, 204/255, 128/255)
	end
      
	  -- TODO: Split into two tooltips -> this => ProgressBarTooltip and AK Tooltip for separate research bar/indicator (not yet implemented)
    if numTraitsPurchased > 0 then
		GameTooltip:AddLine(format(L["Total Ranks Purchased: %d"],  numTraitsPurchased), 1, 1, 1)
	end
	
     if progressPercent > 0 and maxAttainableRank > numTraitsPurchased then
		GameTooltip:AddLine(format(L["%.2f%% towards Rank %d"],  progressPercent, maxAttainableRank + 1))
	end
     
	 GameTooltip:AddLine("\n" .. format(L["Artifact Knowledge Level: %d"], knowledgeLevel), 1, 1, 1)
     GameTooltip:AddLine(format(L["Shipments ready for pickup: %d/%d"], shipmentsReady, shipmentsTotal))
	
	if timeLeft and timeLeftString then
		GameTooltip:AddLine(format(L["Next in: %s"],  timeLeftString))
	end
	
	if hide then
		GameTooltip:Hide()
	else
		GameTooltip:Show()
	end
	
end

--- Show artifact knowledge tooltip (alias for ArtifactKnowledgeTooltipFunction with hide = false)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
local function ShowArtifactKnowledgeTooltip(self, button)

	ArtifactKnowledgeTooltipFunction(self, button)

end

--- Hide artifact knowledge tooltip (alias for ArtifactKnowledgeTooltipFunction with hide = true)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
local function HideArtifactKnowledgeTooltip(self, button)

	ArtifactKnowledgeTooltipFunction(self, button, true)

end


--- Tooltip that is displayed on mouseover for the spec icons (used to activate/ignore specs)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
-- @param[opt] hide Whether or not the tooltip will be hidden. Defaults to false
local function SpecIconTooltipFunction(self, button, hide)  
	
	local specID = tonumber((self:GetName()):match("(%d)$")) -- e.g., TotalAPSpecIconButton1 for spec = 1
	
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	
	local _, specName = GetSpecializationInfo(specID)
	GameTooltip:SetText(format(L["Specialization: %s"], specName), nil, nil, nil, nil, true)
	
	if specID == GetSpecialization() then 
		GameTooltip:AddLine(L["This spec is currently active"], 0/255, 255/255, 0/255);
	else
		GameTooltip:AddLine(L["Click to activate"],  0/255, 255/255, 0/255);
	end	
	
	-- TODO: Colours could be set via Config (once it is implemented) ?
	--GameTooltip:AddLine(L["Right-click to ignore this spec"],  204/255, 85/255, 0/255);
	--GameTooltip:AddLine(L["Right-click to ignore this spec"],  0/255, 114/255, 202/255);
	--GameTooltip:AddLine(L["Right-click to ignore this spec"],  202/255, 0/255, 5/255);
	GameTooltip:AddLine(L["Right-click to ignore this spec"],  255/255, 32/255, 32/255) -- This is RED_FONT_COLOR_CODE from FrameXML
		
	
	if hide then
		GameTooltip:Hide()
	else
		GameTooltip:Show()
	end
	
end

--- Show spec icon tooltip (alias for SpecIconTooltipFunction with hide = false)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
local function ShowSpecIconTooltip(self, button)

	SpecIconTooltipFunction(self, button)

end

--- Show spec icon tooltip (alias for SpecIconTooltipFunction with hide = true)
-- @param self The frame the tooltip will be attached to
-- @param button The button that has been used to toggle the triggering event (Note: This isn't actually relevant here)
local function HideSpecIconTooltip(self, button)

	SpecIconTooltipFunction(self, button, true)

end


TotalAP.GUI.Tooltips = {
	ShowSpecIconTooltip = ShowSpecIconTooltip,
	HideSpecIconTooltip = HideSpecIconTooltip,
	ShowArtifactKnowledgeTooltip = ShowArtifactKnowledgeTooltip,
	HideArtifactKnowledgeTooltip = HideArtifactKnowledgeTooltip,
}


return TotalAP.GUI.Tooltips