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

-- GUI\Views\TabbedView.lua
-- Display template (test)


local addonName, TotalAP = ...

if not TotalAP then return end


local TabbedView = {}

local function CreateNew(self)

	local TabbedViewObject = {}

	setmetatable(TabbedViewObject, self) -- The new object inherits from this class
	self.__index = TotalAP.GUI.View -- ... and this class inherits from the generic View template
	
	-- Assemble individual parts to build a complete view
	
	local AnchorFrame = TotalAP.GUI.BackgroundFrame:CreateNew("AnchorFrame")
	AnchorFrame:SetBackdropColour("#9CCCF8")
	AnchorFrame:EnableMouse()
	-- Scripts for dragging
	
	local ItemUseButton = TotalAP.GUI.ItemUseButton:CreateNew("ItemUseButton", AnchorFrame)
	ItemUseButton:SetParent()
	ItemUseButton:EnableMouse()
	-- onClick, dragging etc. (functionality)
	
	local ProgressBarBackgroundFrame  TotalAP.GUI.BackgroundFrame:CreateNew("ProgressBarBackgroundFrame", AnchorFrame)
	ProgressBarBackgroundFrame:SetBackdropColour("#666666")
	
	local ActiveSpecIconBackgroundFrame = TotalAP.GUI.BackgroundFrame:CreateNew("ActiveSpecIconBackgroundFrame", ProgressBarBackgroundFrame)
	ActiveSpecIconBackgroundFrame:SetBackdropColour(ProgressBarBackgroundFrame:GetBackdropColour())
	
	local SpecIcon1 =  TotalAP.GUI.SpecIcon:CreateNew("SpecIcon1", AnchorFrame) -- Unused spec icons will be hidden during calls to Update()
	-- Set icon, border etc. -> during Update or Render?
	
	local SpecIcon2 =  TotalAP.GUI.SpecIcon:CreateNew("SpecIcon2", AnchorFrame) 
	
	local SpecIcon3 =  TotalAP.GUI.SpecIcon:CreateNew("SpecIcon3", AnchorFrame) 
	
	local SpecIcon4 =  TotalAP.GUI.SpecIcon:CreateNew("SpecIcon4", AnchorFrame) 
	
	TabbedViewObject.elementsList = { 	-- This is the actual view, which consists of individual DisplayFrame objects and their properties
	
		[1] = AnchorFrame,
		[2] = ItemUseButton,
		[3] = ProgressBarBackgroundFrame,
		[4] = ActiveSpecIconBackgroundFrame,
		[5] = SpecIcon1,
		[6] = SpecIcon2,
		[7] = SpecIcon3,
		[8] = SpecIcon4,

	}
	
	return TabbedViewObject
	
end


-- Public methods
TabbedView.CreateNew = CreateNew


-- Make class available in the addon namespace
TotalAP.GUI.TabbedView = TabbedView


return TabbedView