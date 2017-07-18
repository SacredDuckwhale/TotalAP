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
local SpecIcon = {}

--- Default values that are applied to newly created frames automatically
local defaultValues = {



}


-- SpecIcon inherits from DisplayFrame
setmetatable(SpecIcon, TotalAP.GUI.DisplayFrame) 
TotalAP.GUI.DisplayFrame.__index = function(table, key)

	-- Don't look up FrameObjects, as they're unique to each instance and can't be shared
	if key == "FrameObject" then return end
	
	TotalAP.Debug("SpecIcon -> Meta lookup of key " .. key .. " in DisplayFrame")
	
	if TotalAP.GUI.DisplayFrame[key] ~= nil then
		TotalAP.Debug("Key " .. key .. " was found in DisplayFrame, using it")
		return TotalAP.GUI.DisplayFrame[key]
	else
		TotalAP.Debug("- Key " .. key .. " wasn't found in DisplayFrame, using the FrameObject instead")
		return --table.FrameObject[key]
	end
	
end


--- Applies all the contained information to the underlying FrameObject to display them ingame
-- @param self Reference to the caller
local function Render(self)
	
	local FrameObject = self:GetFrameObject()
	
	-- Make sure Frame is created properly (and SpecIcon was instantiated at some point)
	if not FrameObject then
		TotalAP.Debug("FrameObject not found (called Render() before CreateNew()?) -> aborting...")
		return
	end
	
	local isEnabled = self:GetEnabled()
	if isEnabled then -- Display Frame and apply changes where necessary
	
		-- Set icon
		
		-- Set border

		-- Masque update (if required)
		
		-- Apply or remove glow effect
		
		
		-- Reposition 
		if self:GetParent() ~= "UIParent" then -- Position relatively to its parent and the given settings to have it align automatically
		
			FrameObject:ClearAllPoints()
			local posX, posY = unpack(self:GetRelativePosition())

			FrameObject:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", posX, posY)
			
		else -- Is top level frame and mustn't be reset, as its position is stored in WOW's Layout Cache
		
		end
		
	end
	
end


--- Create (and return) a new SpecIcon widget
-- @param self Reference to the caller
-- @param[opt] name Name of the contained FrameObject; defaults to TotalAPSpecIconN (where N is the number of instances) if omitted
-- @param[opt] parent Name of the parent frame; defaults to "UIParent" if omitted
-- @return SpecIconObject representing the frame's container
local function CreateNew(self, name, parent)

	local SpecIconObject = {
		FrameObject = {} -- holds the actual WOW Frame object (userdata) that is unique to each instance of this class
	}
	
	setmetatable(SpecIconObject, self)  -- Set newly created object to inherit from SpecIcon (template, as defined here)
	self.__index = function(table, key) 

		TotalAP.Debug("CreateNew -> Meta lookup of key: " .. key .. " in SpecIcon")
		if self[key] then -- Key exists in SpecIcon class (or DisplayFrame) -> Use it (no need to look anything up, really)
		
			return self[key]  -- DisplayFrame is the actual superclass, but the Frame API calls should be used on a FrameObject instead
			
		else -- Key will have to be looked up in the WOW Frame object
		
			TotalAP.Debug("Key " .. key .. " not found in SpecIcon or DisplayFrame, checking for FrameObject now")
			
			if table.FrameObject and table.FrameObject[key] then -- This SpecIcon has a valid FrameObject being stored -> Use it
			
				TotalAP.ChatMsg("CreateNew -> " .. key .. " will be looked up in FrameObject")
				return table.FrameObject[key]
				
			end
			
		end

	end
	
	-- Create actual WOW Frame (will be invisible, as backdrop etc. will only be applied when rendering, which happens later)
	name = addonName .. (name or (self:GetName() or "SpecIcon" .. self:GetNumInstances()))  -- e.g., "TotalAPSpecIcon1" if no other name was provided
	parent = (parent and (addonName .. parent)) or parent or "UIParent"
	TotalAP.Debug("CreateNew -> Creating frame with name = " .. name .. ", parent = " .. parent) 
	
	SpecIconObject:SetName(name)
	SpecIconObject:SetParent(parent)
	SpecIconObject.FrameObject = CreateFrame("Button", name, _G[parent] or UIParent, "ActionButtonTemplate, SecureActionButtonTemplate") 
	SpecIconObject.FrameObject:SetFrameStrata("MEDIUM") 
		
	self.numInstances =  self:GetNumInstances() + 1 -- As this new frame is added to the pool, future frames should not use its number to avoid potential name clashes (even though there is no guarantee this ID is actually used, wasting some makes little difference)

	return SpecIconObject
	
end


-- Public methods (interface table -> accessible by the View and GUI Controller)
SpecIcon.CreateNew = CreateNew
SpecIcon.Render = Render

-- Make class available in the addon namespace
TotalAP.GUI.SpecIcon = SpecIcon

return SpecIcon
