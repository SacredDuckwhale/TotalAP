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

--- Contains various layouts for displaying the addon's data and providing interactive UI elements to access its functionality
-- @module Views

--- Prototype.lua.
-- An abstract parent class that allows each view to inherit general functionality and structure from it.
-- @section GUI

local addonName, TotalAP = ...
if not TotalAP then return end


-- Private variables (default values that will be inherited)
local name = "PrototypeView"
local elementsList = {} -- No elements in this view, for obvious reasons

local View = {}

--- Prototype constructor. This will be overwritten by derived classes and should not be called directly
local function CreateNew()

	-- Nothing because a) prototype and b) only preset views are supported yet, but not entirely custom ones (TODO) :P
	return
	
end

--- Returns the name of this view
-- @param self Reference to the ViewObject representing the View
-- @return name Name of the view
local function GetName(self)

	return self.name

end

--- Sets the name of this view
-- @param self Reference to the ViewObject representing the View
-- @param[opt] name Name that will be set for this ViewObject; Defaults to "" (empty String) if none is given
local function SetName(self, name)
	
	self.name = name or ""

end

--- Renders all the elements that are part of the view, according to their attribute. This displays the GUI if the view is active, but doesn't show anything otherwise
-- @param self Reference to the ViewObject representing the View
local function Render(self)

	-- if self:GetName()  ~= TotalAP.Controllers.GetActiveView() then return end

	-- Render (and display),enabled elements that are part of the view
	for index, Element in ipairs(elementsList) do 
		
		TotalAP.Debug("Rendering view element " .. index .. ": " .. Element:GetName() or "<unnamed>") -- Element:GetName() will look up the attached FrameObject and return the WOW Frame's name
		if Element:IsEnabled() then 
			Element:Render()
		end
		
	end
	
end

--- Updates the existing (and already rendered = created) view to display correct information (won't do anything if view isn't active either)
-- @param self Reference to the ViewObject representing the View
local function Update(self)

	-- Update,enabled elements that are part of the view
	for index, Element in ipairs(elementsList) do
		
		TotalAP.Debug("Updating view element " .. index .. ": " .. Element:GetName() or "<unnamed>") -- Element:GetName() will look up the attached FrameObject and return the WOW Frame's name
		if Element:IsEnabled() then 
			Element:Update()
		end
		
	end
end

--- Get the number of elements that make up this view (Only enabled elements count)
-- @param self Reference to the ViewObject representing the View
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
View.GetName = GetName
View.SetName = SetName
View.Render = Render
View.Update = Update
View.GetNumElements = GetNumElements


TotalAP.GUI.View = View

return View