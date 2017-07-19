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

local addonName, TotalAP = ...
if not TotalAP then return end


-- Localized globals
local _G = _G -- Required to get parent frame references from their names


-- Private variables
local ProgressBar = {}

--- Default values that are applied to newly created frames automatically
local defaultValues = {

	-- General settings (applied to all bars)
	texture = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp",
	width = 100,
	height = 16,

	-- Empty bar (background)
	colour = "#FAFAFA",
	alpha = 0.2,
	
	-- UnspentBar (AP applied to artifact but not used)
	UnspentBar = {
	
		enabled = true,
		width = 0,
		alpha = 1,
		colour = "#3296FA",
		
	},
	
	-- InBagsBar (AP in the player's inventory)
	InBagsBar = {
	
		enabled = true,
		width = 0,
		alpha = 1,
		colour = "#325FFA",
	
	},
	
	-- InBankBar (AP in the player's bank)
	InBankBar = {
		
		enabled = true,
		width = 0,
		alpha = 1,
		colour = "#325F5F",
		
	},
	
	-- MiniBar (small "carry" display)
	MiniBar = {
	
		enabled = true,
		width = 0,
		height = 2,
		alpha = 1,
		colour = "#EFE5B0",
	
	}
	
}


-- ProgressBar inherits from DisplayFrame
setmetatable(ProgressBar, TotalAP.GUI.DisplayFrame) 

	
	
		return
	end
	
end



-- @param self Reference to the caller


end

--- Applies all the contained information to the underlying FrameObject to display them ingame
-- @param self Reference to the caller
local function Render(self)
	
	local FrameObject = self:GetFrameObject()
	
	-- Make sure Frame is created properly (and ProgressBar was instantiated at some point)
	if not FrameObject then
		TotalAP.Debug("FrameObject not found (called Render() before CreateNew()?) -> aborting...")
		return
	end
	
	local isEnabled = self:GetEnabled()
	if isEnabled then -- Display Frame and apply changes where necessary
	
		-- Set backdrop
		FrameObject:SetBackdrop( { bgFile = self:GetBackdropFile(),  edgeFile = self:GetEdgeFile(),  tile = self:IsTiled(), tileSize = self:GetTileSize(), edgeSize = self:GetEdgeSize(), insets = self:GetInsets() } )
		local r, g, b = TotalAP.Utils.HexToRGB(self:GetBackdropColour())
		FrameObject:SetBackdropColor(r/255, g/255, b/255, self:GetBackdropAlpha())
		
		-- Reposition 
		if self:GetParent() ~= "UIParent" then -- Position relatively to its parent and the given settings to have it align automatically
		
			FrameObject:ClearAllPoints()
			local posX, posY = unpack(self:GetRelativePosition())

			FrameObject:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", posX, posY)
			
		else -- Is top level frame and mustn't be reset, as its position is stored in WOW's Layout Cache
			
			local numPoints = FrameObject:GetNumPoints()
			if numPoints == 0 then -- Frame isn't anchored anywhere and therefore invisible (can happen after errors occur somehow?)
				FrameObject:SetPoint("CENTER", UIParent, "CENTER")
			end
			
		end
		
	end
	
end


--- Create (and return) a new ProgressBar widget
-- @param self Reference to the caller
-- @param[opt] name Name of the contained FrameObject; defaults to TotalAPProgressBarN (where N is the number of instances) if omitted
-- @param[opt] parent Name of the parent frame; defaults to "UIParent" if omitted
-- @return ProgressBarObject representing the frame's container
local function CreateNew(self, name, parent)

	local ProgressBarObject = {
		FrameObject = {} -- holds the actual WOW Frame object (userdata) that is unique to each instance of this class
	}
	
	setmetatable(ProgressBarObject, self)  -- Set newly created object to inherit from ProgressBar (template, as defined here)
	self.__index = function(table, key) 

		TotalAP.Debug("CreateNew -> Meta lookup of key: " .. key .. " in ProgressBar")
		if self[key] then -- Key exists in ProgressBar class (or DisplayFrame) -> Use it (no need to look anything up, really)
		
			return self[key]  -- DisplayFrame is the actual superclass, but the Frame API calls should be used on a FrameObject instead
			
		end

	end
	
	-- Create actual WOW Frame (will be invisible, as backdrop etc. will only be applied when rendering, which happens later)
	name = addonName .. (name or (self:GetName() or "ProgressBar" .. self:GetNumInstances()))  -- e.g., "TotalAPProgressBar1" if no other name was provided
	parent = (parent and (addonName .. parent)) or parent or "UIParent"
	TotalAP.Debug("CreateNew -> Creating frame with name = " .. name .. ", parent = " .. parent) 
	
	ProgressBarObject:SetName(name)
	ProgressBarObject:SetParent(parent)
	ProgressBarObject.FrameObject = CreateFrame("Frame", name, _G[parent] or UIParent) 
	ProgressBarObject.FrameObject:SetFrameStrata("BACKGROUND") 
		
	self.numInstances =  self:GetNumInstances() + 1 -- As this new frame is added to the pool, future frames should not use its number to avoid potential name clashes (even though there is no guarantee this ID is actually used, wasting some makes little difference)

	return ProgressBarObject
	
end


-- Public methods (interface table -> accessible by the View and GUI Controller)
ProgressBar.CreateNew = CreateNew
ProgressBar.Render = Render

-- Make class available in the addon namespace
TotalAP.GUI.ProgressBar = ProgressBar

return ProgressBar