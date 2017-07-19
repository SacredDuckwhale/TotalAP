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
-- @module GUI

--- DefaultView.lua.
-- The classic TotalAP GUI as it was used in earlier versions
-- @section GUI


local addonName, TotalAP = ...
if not TotalAP then return end


local DefaultView = {}

--- Creates a new ViewObject
-- @param self Reference to the caller
-- @return A representation of the View (ViewObject)
local function CreateNew(self)
	
	local ViewObject = {}

	setmetatable(ViewObject, self) -- The new object inherits from this class
	self.__index = TotalAP.GUI.View -- ... and this class inherits from the generic View template
	
	-- TODO: Get those from the settings, so that they can be changed in the options GUI (under tab: Views -> DefaultView, along with enabling/disabling/repositioning individual display components)
	do -- Stuff that needs to be moved to AceConfig settings
	
		local hSpace, vSpace = 2, 5 -- space between display elements
		
		local barWidth, barHeight, barInset = 100, 18, 1
		
		local maxButtonSize = 80
		local buttonSize = 40 -- TODO: Layout Cache or via settings?
		
		local specIconSize = 18
		local specIconBorderWidth = 1
		local specIconTextWidth = 40
		
		local stateIconWidth, stateIconHeight = (maxButtonSize - 3 * vSpace) / 4, barHeight + barInset
		
		local sliderHeight = 20
		
	end -- End stuff that needs to be moved to AceConfig settings
	
	
	-- Anchor frame: Parent of all displays and buttons (used to toggle the entire addon, as well as move its displays)
	local AnchorFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_AnchorFrame")
	local AnchorFrame = AnchorFrameContainer:GetFrameObject()
	do -- AnchorFrame
	
		-- Layout and visuals
		AnchorFrame:SetFrameStrata("BACKGROUND")
		AnchorFrameContainer:SetBackdropColour("#D0D0D0")
		AnchorFrameContainer:SetBackdropAlpha(0.5)
		AnchorFrame:SetSize(maxButtonSize + hSpace + barWidth + hSpace + specIconSize + 2 * specIconBorderWidth + hSpace + specIconTextWidth, barHeight + vSpace + maxButtonSize + vSpace + sliderHeight) -- TODO: Update dynamically (script handlers?) to account for variable number of specs
		
		-- Player interaction
		AnchorFrame:SetMovable(true) 
		AnchorFrame:EnableMouse(true)
		AnchorFrame:RegisterForDrag("LeftButton")
		
		-- Script handlers
		AnchorFrame:SetScript("OnDragStart", function(self) -- Dragging moves the entire display (ALT + Click)
			
			if self:IsMovable() and IsAltKeyDown() then -- Move display
				self:StartMoving()
				AnchorFrameContainer:SetBackdropColour("#D0D0D0")
				AnchorFrameContainer:SetBackdropAlpha(1)
				AnchorFrameContainer:Render()
				
			end
			
			self.isMoving = true
		
		end)
		
		AnchorFrame:SetScript("OnDragStop", function(self) -- Stopping to drag leaves the display at its new location
			
			self:StopMovingOrSizing()
			self.isMoving = false
			
			AnchorFrameContainer:SetBackdropColour("#D0D0D0")
			AnchorFrameContainer:SetBackdropAlpha(0.5)
			AnchorFrameContainer:Render()
			
		end)
		
	end
	
	-- Event state icons: Indicate state of events that affect the ability to use AP items (TODO: Settings to show/hide and style these)
	local CombatStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_CombatStateIcon", "_DefaultView_AnchorFrame")
	local CombatStateIcon = CombatStateIconContainer:GetFrameObject()
	do -- CombatStateIcon
		
		-- Layout and visuals
		CombatStateIconContainer:SetRelativePosition(0, 0)
		CombatStateIconContainer:SetBackdropColour("#EC3413")
		
		CombatStateIcon:SetSize(stateIconSize, stateIconSize)
		
	end
	
	local PetBattleStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_PetBattleStateIcon", "_DefaultView_AnchorFrame")
	local PetBattleStateIcon = PetBattleStateIconContainer:GetFrameObject()
	do -- PetBattleStateIcon
		
		-- Layout and visuals
		PetBattleStateIconContainer:SetRelativePosition(stateIconSize + hSpace, 0)
		PetBattleStateIconContainer:SetBackdropColour("#F05238")
		
		PetBattleStateIcon:SetSize(stateIconSize, stateIconSize)
		
	end
	
	local VehicleStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_VehicleStateIcon", "_DefaultView_AnchorFrame")
	local VehicleStateIcon = VehicleStateIconContainer:GetFrameObject()
	do -- VehicleStateIcon
		
		-- Layout and visuals
		VehicleStateIconContainer:SetRelativePosition(2 * (stateIconSize + hSpace), 0)
		VehicleStateIconContainer:SetBackdropColour("#F3725D")
		
		VehicleStateIcon:SetSize(stateIconSize, stateIconSize)
		
	end
	
	local PlayerControlStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_PlayerControlStateIcon", "_DefaultView_AnchorFrame")
	local PlayerControlStateIcon = PlayerControlStateIconContainer:GetFrameObject()
	do -- PlayerControlStateIcon
	
		-- Layout and visuals
		PlayerControlStateIconContainer:SetRelativePosition(3 * (stateIconSize + hSpace), 0)
		PlayerControlStateIconContainer:SetBackdropColour("#F69282")
		
		PlayerControlStateIcon:SetSize(stateIconSize, stateIconSize)
	
	end
	
	local UnderlightAnglerFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_UnderlightAnglerFrame", "_DefaultView_AnchorFrame")
	local UnderlightAnglerFrame = UnderlightAnglerFrameContainer:GetFrameObject()
	do -- UnderlightAnglerFrame
	
		-- Layout and visuals
		UnderlightAnglerFrameContainer:SetBackdropColour("#9CCCF8")
		UnderlightAnglerFrameContainer:SetRelativePosition(barInset + 4 * (stateIconSize + hSpace), -barInset)
		
		UnderlightAnglerFrame:SetSize(barWidth, barHeight)
		
		
	end
	
	
	ViewObject.elementsList = { 	-- This is the actual view, which consists of individual DisplayFrame objects and their properties
	
		AnchorFrameContainer,
		CombatStateIconContainer,
		PetBattleStateIconContainer,
		VehicleStateIconContainer,
		PlayerControlStateIconContainer,
		UnderlightAnglerFrameContainer,
		
	}
	
	return ViewObject
	
end

DefaultView.CreateNew = CreateNew

TotalAP.GUI.DefaultView = DefaultView

return DefaultView