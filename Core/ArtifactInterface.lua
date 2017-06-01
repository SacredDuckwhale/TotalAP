--[[ TotalAP - Artifact Power tracking addon for World of Warcraft: Legion
 
	-- LICENSE (short version):
	
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
--]]


--- 
-- @module Core

--- ArtifactInterface.lua.
-- Provides utilities and manages interaction with Blizzard's ArtifactUI (as well as Artifact Knowledge/Research Notes, which are accessed via GarrisonUI)
-- @section ArtifactInterface


-- Note: Most of these are just thin wrappers / already available elsewhere, but API changes will be easier to maintain if they're all in one place

local addonName, T = ...

if not T then return end


-- Shorthands
local aUI = C_ArtifactUI 


-- Returns information about the currently queued Artifact Research work order status
local function GetResearchNotesShipmentInfo()
   
   local looseShipments = C_Garrison.GetLooseShipments (LE_GARRISON_TYPE_7_0) -- Contains: Nomi's work orders, OH Research/Troops, AK Research Notes
   
   if looseShipments and #looseShipments > 0 then -- Shipments are in progress/available
      
      for i = 1, #looseShipments do -- Find Research Notes
         
         local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemTexture, itemID  = C_Garrison.GetLandingPageShipmentInfoByContainerID (looseShipments [i])
       --  if name and creationTime and creationTime > 0 and texture == 237446 then -- Shipment is Artifact Research Notes
        if name and texture == 237446 then -- Shipment is Artifact Research Notes
               
			local elapsedTime, timeLeft = 0, 0 -- in case it's waiting to be picked up already
			if creationTime then -- Research in progress (not finished) -> Calculate time until it is finished
				elapsedTime = time() - creationTime
				timeLeft = duration - elapsedTime
			 end  
        
            return name, timeleftString, timeLeft, elapsedTime, shipmentsReady, shipmentsTotal, itemName
            
         end
         
      end
      
   end
   
end

-- Returns the number of Artifact Research Notes that are ready for pickup
local function GetNumAvailableResearchNotes()

	return select(5, GetResearchNotesShipmentInfo()) or 0

end

-- Returns the time (integer timestamp, String) until the next Artifact Research Notes are ready to be picked up
local function GetTimeUntilNextResearchNoteIsReady()
	
	local timeLeftString, timeLeft = select(2, GetResearchNotesShipmentInfo())
	
	return timeLeft, timeLeftString

end

-- Returns the the current AK level (same as used in Blizzard's Forge tooltip)
local function GetArtifactKnowledgeLevel()

	local name, amount, texturePath, earnedThisWeek, weeklyMax, totalMax, isDiscovered, quality = GetCurrencyInfo(1171) -- Hidden currency -> always available (unlike the crappy ArtifactUI :| )

	return amount
	--return aUI.GetArtifactKnowledgeLevel() -- Only available when ArtifactFrame is shown... -> not ideal, as it would have to be cached

end

-- Returns the multiplier for the current AK level (same as used in Blizzard's Forge tooltip)
-- TODO: Only works if ArtifactFrame is currently open -> needs caching before it can be used
-- local function GetArtifactKnowledgeMultiplier()

	-- if not aUI then return 0	end
	
	-- return aUI.GetArtifactKnowledgeMultiplier()
	
-- end


-- Returns the number of traits that can be purchased with any given artifact power value for the given rank
local function GetNumRanksPurchasableWithAP(rank, artifactPowerValue, tier)

	-- The MainMenuBar function returns multiple values, but they aren't needed here. It might be practical, but it is also confusing
	return select(1, MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(rank, artifactPowerValue, tier))
	
end

-- Returns progress towards the next trait (after considering all available "level ups")
local function GetProgressTowardsNextRank(rank, artifactPowerValue, tier)

	local numPoints, artifactXP, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(rank, artifactPowerValue, tier)
	
	local maxAttainableRank, leftoverAP = rank + numPoints, artifactXP
	local percentage = (leftoverAP / xpForNextPoint) * 100
	
	return percentage

end


-- Public methods
T.ArtifactInterface.GetNumAvailableResearchNotes = GetNumAvailableResearchNotes
--T.ArtifactInterface.GetArtifactKnowledgeMultiplier = GetArtifactKnowledgeMultiplier
T.ArtifactInterface.GetArtifactKnowledgeLevel = GetArtifactKnowledgeLevel
T.ArtifactInterface.GetTimeUntilNextResearchNoteIsReady = GetTimeUntilNextResearchNoteIsReady
--T.ArtifactInterface.GetNumRanksPurchased = GetNumRanksPurchased
T.ArtifactInterface.GetNumRanksPurchasableWithAP = GetNumRanksPurchasableWithAP
T.ArtifactInterface.GetProgressTowardsNextRank = GetProgressTowardsNextRank


-- Keep this private, since it isn't used anywhere else
-- T.ArtifactInterface.GetResearchNotesShipmentInfo = GetResearchNotesShipmentInfo
-- T.ArtifactInterface.
-- T.ArtifactInterface.
-- T.ArtifactInterface.
-- T.ArtifactInterface.


return T.ArtifactInterface