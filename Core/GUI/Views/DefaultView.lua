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
	local hSpace, vSpace = 5, 5 -- space between display elements
	local barWidth, barHeight = 100, 18
	local maxButtonSize = 100
	local specIconSize = 16
	local specIconBorderWidth = 1
	local specIconTextWidth = 40
	local stateIconsSize = 20
	local sliderHeight = 20
	
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
	
	
	ViewObject.elementsList = { 	-- This is the actual view, which consists of individual DisplayFrame objects and their properties
	
		AnchorFrameContainer,

	}
	
	return ViewObject
	
end

DefaultView.CreateNew = CreateNew

TotalAP.GUI.DefaultView = DefaultView

return DefaultView