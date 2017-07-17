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

local function CreateNew(self)
	
	local ViewObject = {}

	setmetatable(ViewObject, self) -- The new object inherits from this class
	self.__index = TotalAP.GUI.View -- ... and this class inherits from the generic View template
	
	-- TODO...
	
	return ViewObject
	
end

TotalAP.Views.DefaultView = DefaultView

return DefaultView