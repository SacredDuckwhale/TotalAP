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
	
	isEnabled,
	FrameObject,
	numInstances = 0,
	Parent,
	name,
	
}
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
	return self.isEnabled -- If it hasn't been set yet, will return nil (which evaluates to false anyway)
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
	
	return self.numInstances or defaultValues.numInstances

end

-- Returns the parent frame for currently displayed frames, or the one that will be applied to the FrameObject when it is being rendered
local function GetParent(self)

	if self.FrameObject then return self.FrameObject:GetParent() end
	
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

-- Get the DisplayFrame's name (which is also the name of the actual WOW Frame, if it has been rendered)
local function GetName(self)
	
	if self.FrameObject then return self.FrameObject:GetName() end
	
	return self.name or defaultValues.name

end

-- Prototype only -> Must be overwritten by derived classes to be actually useful (since the DummyFrame isn't part of any views and shouldn't be rendered, nor is it useful to instantiate and render a generic DisplayFrame)
local function Render(self)

	TotalAP.Debug("Tried to render prototype DisplayFrame -> Something's not quite right...")
	return false
	
end

-- Prototype -> Is supposed to be overwritten (and then update each element's display according to the data and GUI widget types it uses)
local function Update(self)

	TotalAP.Debug("Tried to update prototype DisplayFrame -> Something's not quite right...")
	return false
	
end

-- Prototype constructor (This isn't actually needed, but giving a debug-error when instantiation is attempted should be fine)
local function CreateNew(self, name, parent)

	TotalAP.Debug("Tried to create new instance of prototype DisplayFrame - Something's not quite right!")
	return false

	-- local DisplayFrameObject = {}
	
	-- self.FrameObject = CreateFrame("Frame", addonName .. name or addonName .. "DisplayFrame" .. self.numInstances, parent or UIParent) -- Reference to the actual WOW frame that will be used for all operations on DisplayFrame objects
	
	-- setmetatable(DisplayFrameObject, self)  -- Set newly created object to inherit from DisplayFrame (as defined here)
	-- self.__index = self.FrameObject -- DisplayFrame in turn inherits from Frame, so that Frame API calls can be used on its FrameObject (and the custom operations act on DisplayFrame instead)
	
	-- self.numInstances =  numInstances + 1 -- As this new frame is added to the pool, future frames should not use its number to avoid potential name clashes (even though there is no guarantee this ID is actually used, wasting some makes little difference)
	
	-- return DisplayFrameObject
	
end


-- Public methods (interface table)
DisplayFrame.CreateNew = CreateNew
DisplayFrame.GetEnabled = GetEnabled
DisplayFrame.SetEnabled = SetEnabled
DisplayFrame.Enable = Enable
DisplayFrame.Disable = Disable
DisplayFrame.Render = Render
DisplayFrame.Update = Update
DisplayFrame.GetNumInstances = GetNumInstances
DisplayFrame.GetParent = GetParent
DisplayFrame.SetParent = SetParent
DisplayFrame.SetName = SetName
DisplayFrame.GetName = GetName


-- Make class available in the addon namespace
TotalAP.GUI.DisplayFrame = DisplayFrame

return DisplayFrame