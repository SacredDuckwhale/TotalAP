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


local DisplayFrame = {}

-- Private variables (state table -> inacessible outside of this class)
local defaultValues = {
	
	isEnabled = true,
--	FrameObject = {}, -- This should be overwritten by the instanced classes to replace it with an actual WOW Frame object
	numInstances = 0,
	Parent = "UIParent",
	name = "",
	
}

-- Uninitialised values should be looked up in defaultValues
local mt = {}
setmetatable(DisplayFrame, mt)
mt.__index = function(table, key)
	
	TotalAP.Debug("-- DisplayFrame -> Meta lookup for key = " .. key .. " in defaultValues")
	return defaultValues[key]
	
end

-- local isEnabled -- NOT the same as shown, for which an API exist. Disabled = Display not part of the view, which is independent of the actual frame's visibility status (although disabled elements aren't supposed to be rendered = shown)
-- local FrameObject = {}
-- local numInstances = 0
-- local parent -- Saved in case the Frame is disabled
-- local name -- will be used for the Frame's name, but also applies to the DisplayFrame object


-- local isEnabled -- NOT the same as shown, for which an API exist. Disabled = Display not part of the view, which is independent of the actual frame's visibility status (although disabled elements aren't supposed to be rendered = shown)
-- local FrameObject = {}
-- local numInstances = 0
-- local parent -- Saved in case the Frame is disabled
-- local name -- will be used for the Frame's name, but also applies to the DisplayFrame object

-- Get enabled status for this object
local function GetEnabled(self)
	return self.isEnabled
end

-- Toggle enabled status for this object
local function SetEnabled(self, enabledStatus)
	self.isEnabled = enabledStatus
end

-- Alias for SetEnabled(true)
local function Enable(self)
	self.isEnabled = true
end

-- Alias for SetEnabled(false)
local function Disable(self)
	self.isEnabled = false
end

-- Return the number of instantiations so far (NOT the active number of instances, which is irrelevant for naming purposes)
local function GetNumInstances(self)
	return self.numInstances
end

-- Returns the parent frame for currently displayed frames, or the one that will be applied to the FrameObject when it is being rendered
local function GetParent(self)

	if self.FrameObject.GetParent then return self.FrameObject:GetParent() end
	
	return self.Parent

end

-- Set the parent that should be applied to the FrameObject when it is being rendered
local function SetParent(self, newParent)

	self.Parent = newParent or UIParent -- Will not be applied to the FrameObject until it is actually rendered as part of the View

end

-- Set the DisplayFrame's name (that will also be used to identify the actual WOW Frame when it is being rendered)
local function SetName(self, newName)

	self.name = newName

end

--- Get the DisplayFrame's name (which is also the name of the actual WOW Frame, if it has been created)
local function GetName(self)
	
	if self.FrameObject.GetName then return self.FrameObject:GetName() end
	
	return self.name

end

--- Prototype render method. Must be overwritten by derived classes to be useful, as rendering is different for each frame type
local function Render()

	TotalAP.Debug("Tried to render prototype DisplayFrame -> Something's not quite right...")
	return
	
end

-- Prototype constructor. Must be overwritten by derived classes to be useful, as instantiation is different for each frame type
local function CreateNew()

	TotalAP.Debug("Tried to create new instance of prototype DisplayFrame - Something's not quite right!")
	return
	
end

--- Returns the contained WOW Frame object
-- @param self Reference to the caller
-- @return A reference to the Frame object
local function GetFrameObject(self)
	
	return self.FrameObject
	
end


-- Public methods (interface table)
DisplayFrame.CreateNew = CreateNew
DisplayFrame.GetEnabled = GetEnabled
DisplayFrame.SetEnabled = SetEnabled
DisplayFrame.Enable = Enable
DisplayFrame.Disable = Disable
DisplayFrame.Render = Render
DisplayFrame.GetNumInstances = GetNumInstances
DisplayFrame.GetParent = GetParent
DisplayFrame.SetParent = SetParent
DisplayFrame.SetName = SetName
DisplayFrame.GetName = GetName
DisplayFrame.GetFrameObject = GetFrameObject


TotalAP.GUI.DisplayFrame = DisplayFrame

return DisplayFrame