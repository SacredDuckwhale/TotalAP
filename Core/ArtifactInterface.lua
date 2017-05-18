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


-- [[ ArtifactInterface.lua ]]
-- Utilities and interaction with Blizzard's ArtifactUI (as well as Artifact Knowledge, which is technically the GarrisonUI)
-- Note: Most of these are just thin wrappers / already available somewhere, but API changes will be easier to accomodate if they're all in one place

local addonName, T = ...

-- Shorthands
local aUI = C_ArtifactUI 


-- Artifact Knowledge / Research Notes

-- TODO: Caching required, since AK values are only available when aUI was initialised?


-- Returns information about the currently queued Artifact Research work order status
local function GetResearchNotesShipmentInfo()
   
   local looseShipments = C_Garrison.GetLooseShipments (LE_GARRISON_TYPE_7_0) -- Contains: Nomi's work orders, OH Research/Troops, AK Research Notes
   
   if looseShipments and #looseShipments > 0 then -- Shipments are in progress/available
      
      for i = 1, #looseShipments do -- Find Research Notes
         
         local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemTexture, itemID  = C_Garrison.GetLandingPageShipmentInfoByContainerID (looseShipments [i])
         if name and creationTime and creationTime > 0 and texture == 237446 then -- Shipment is Artifact Research Notes
            
            local elapsedTime = time() - creationTime
            local timeLeft = duration - elapsedTime
            
            return name, timeleftString, timeLeft, elapsedTime, shipmentsReady, shipmentsTotal, itemName
            
         end
         
      end
      
   end
   
end


-- Returns the number of Artifact Research Notes that are ready for pickup
local function GetNumAvailableResearchNotes()

	return select(5, GetResearchNotesShipmentInfo()) or 0

end

local function GetTimeUntilNextResearchNoteIsReady()
	
	return select(2, GetResearchNotesShipmentInfo()) or ""

end


-- Returns the the current AK level (same as used in Blizzard's Forge tooltip)
local function GetArtifactKnowledgeLevel()

	if not aUI then return 0 end
	
	return aUI.GetArtifactKnowledgeLevel()

end

-- Returns the multiplier for the current AK level (same as used in Blizzard's Forge tooltip)
local function GetArtifactKnowledgeMultiplier()

	if not aUI then return 0	end
	
	return aUI.GetArtifactKnowledgeMultiplier()
	
end



-- ArtifactUI interactions

local function GetNumRanksPurchased()

end


local function GetNumRanksPurchasableWithAP(artifactPowerValue)

end

local function GetProgressTowardsNextRank(rank, artifactPowerValue)

end


if not T then return end

-- Public methods
T.ArtifactInterface.GetNumAvailableResearchNotes = GetNumAvailableResearchNotes
T.ArtifactInterface.GetArtifactKnowledgeMultiplier = GetArtifactKnowledgeMultiplier
T.ArtifactInterface.GetArtifactKnowledgeLevel = GetArtifactKnowledgeLevel
T.ArtifactInterface.GetTimeUntilNextResearchNoteIsReady = GetTimeUntilNextResearchNoteIsReady
T.ArtifactInterface.GetNumRanksPurchased = GetNumRanksPurchased
T.ArtifactInterface.GetNumRanksPurchasableWithAP = GetNumRanksPurchasableWithAP
T.ArtifactInterface.GetProgressTowardsNextRank = GetProgressTowardsNextRank

-- Keep this private, since it isn't used anywhere else
-- T.ArtifactInterface.GetResearchNotesShipmentInfo = GetResearchNotesShipmentInfo
-- T.ArtifactInterface.
-- T.ArtifactInterface.
-- T.ArtifactInterface.
-- T.ArtifactInterface.

return T.ArtifactInterface