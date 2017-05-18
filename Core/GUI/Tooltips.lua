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


-- [[ Tooltips.lua ]]
-- Dynamic tooltip text functions that can be hooked to the appropriate events by the GUI controller

local addonName, TotalAP = ...

if not TotalAP then return end

local L = LibStub("AceLocale-3.0"):GetLocale("TotalAP", false)

-- This is the mouseover-tooltip for progress bars, based on Blizzard's ForgeDisplay (icon to the top-left of the ArtifactFrame)
local function ArtifactKnowledgeTooltipFunction(self, button, hide)
--	TotalAP.ChatMsg(self:GetName())
	local artifactName = "ARTIFACT_NAME"
	local numRanksPurchased = 0
	local knowledgeLevel = 0
	--TotalArtifactPowerCache["Bearlin - Outland"][i]["numTraitsPurchased"]
	
	local shipmentsReady = TotalAP.ArtifactInterface.GetNumAvailableResearchNotes()
	local shipmentsTotal = 2 -- Could use the interface, but no more than 2 can actually be queued anyway
	local timeLeftString = TotalAP.ArtifactInterface.GetTimeUntilNextResearchNoteIsReady()
	--local name, timeLeftString, timeLeft, elapsedTime, shipmentsReady, shipmentsTotal, itemName = TotalAP.ArtifactInterface.GetResearchNotesShipmentInfo() 
	
	  GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      -- GameTooltip:SetText("Specialization: " .. specName)
      GameTooltip:AddLine(format("%s", artifactName), 230/255, 204/255, 128/255)
      
	  -- if AK not cached then don't display tooltip? Or display AK only / no progress for weapon
      -- TODO: Locale table (format %s)
      GameTooltip:AddLine("Total Ranks Purchased: " ..  numRanksPurchased, 1, 1, 1)
      GameTooltip:AddLine("Progress: X% (towards rank X)") 
      GameTooltip:AddLine("\nArtifact Knowledge Level: " .. knowledgeLevel, 1, 1, 1)
      GameTooltip:AddLine("Queued: " .. shipmentsReady .. "/" .. shipmentsTotal)
      GameTooltip:AddLine("Next: " .. timeLeftString)
	
	if hide then
		GameTooltip:Hide()
	else
		GameTooltip:Show()
	end
	
end

local function ShowArtifactKnowledgeTooltip(self, button)

	ArtifactKnowledgeTooltipFunction(self, button)

end

local function HideArtifactKnowledgeTooltip(self, button)

	ArtifactKnowledgeTooltipFunction(self, button, true)

end



-- Displayed on mouseover for the spec icons (used to activate/ignore specs)
local function SpecIconTooltipFunction(self, button, hide)
	
	local specNo = (self:GetName()):match("(%d)$") -- e.g., TotalAPSpecIconButton1 for spec = 1
	
	 -- On mouseover, show message that spec can be changed by clicking (unless it's the currently active spec)
	
	-- Show tooltip "Click to change spec" or sth. TODO
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
	
	local _, specName = GetSpecializationInfo(specNo);
	GameTooltip:SetText(format(L["Specialization: %s"], specName), nil, nil, nil, nil, true);
	
	if i == GetSpecialization() then 
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


local function ShowSpecIconTooltip(self, button)

	SpecIconTooltipFunction(self, button)

end

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