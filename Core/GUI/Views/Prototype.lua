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

-- GUI\Views.lua
-- Handling of display templates (views) that will be used by the GUI controller to show/hide frames as required


local addonName, TotalAP = ...

if not TotalAP then return end

local View = {}


-- Private variables (and default values that will be inherited)
local isActiveView = false
local name = "PrototypeView"
local elementsList = {} -- No elements in this view, for obvious reasons


-- Prototype constructor -> will be overwritten by derived classes
local function CreateNew(self, name)

	-- Nothing because a) prototype and b) only preset views are supported yet, but not entirely custom ones (TODO) :P
	return
	
end

-- Returns the name of this view
local function GetName(self)

	return self.name

end

-- Sets the name of this view (empty String if none is given)
local function SetName(self, name)
	
	self.name = name or ""
	return

end

-- Return whether or not this view is currently the active view (only one can be active at any given time)
local function IsActiveView(self)
	
	return self.isActiveView
	
end

-- Set a given view to be the active one
local function SetActiveView(self)
	
	TotalAP.Debug("Setting active view: " .. self:GetName())
	self.isActiveView = true
	
end

-- Renders all the elements that are part of the view, according to their attributes (this creates the GUI and displays it if the view is active)
local function Render(self)

	-- Render (and display),enabled elements that are part of the view
	for index, Element in ipairs(elementsList) do 
		
		TotalAP.Debug("Rendering view element " .. index .. ": " .. Element:GetName() or "<unnamed>") -- Element:GetName() will look up the attached FrameObject and return the WOW Frame's name
		if Element:IsEnabled() then 
			Element:Render()
		end
		
	end
	
end

-- Update the existing (and already rendered!) view to display correct information (won't do anything if view isn't active either)
local function Update(self)

	-- Update,enabled elements that are part of the view
	for index, Element in ipairs(elementsList) do
		
		TotalAP.Debug("Updating view element " .. index .. ": " .. Element:GetName() or "<unnamed>") -- Element:GetName() will look up the attached FrameObject and return the WOW Frame's name
		if Element:IsEnabled() then 
			Element:Update()
		end
		
	end
end

-- Get the number of elements that make up this view (Only enabled elements count)
local function GetNumElements(self)

	local n = 0
	
	-- Count elements that are part of this view
	for i in pairs(elementsList) do 
		if elementsList[i] ~= nil and elementsList[i]:IsEnabled() then -- This element exists, and is enabled
			n = n + 1
		end
	end

	return n

end


-- Public methods
View.CreateNew = CreateNew
View.IsActiveView = IsActiveView
View.SetActiveView = SetActiveView
View.GetName = GetName
View.SetName = SetName
View.Render = Render
View.Update = Update
View.GetNumElements = GetNumElements

-- Make class available in the addon namespace
TotalAP.GUI.View = View

return View

