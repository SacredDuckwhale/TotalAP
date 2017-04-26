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


-- Create a GUI (view) to display the information according to the view settings
local function CreateView()

	-- Create frames and store them in addon table (for later use)
	
	-- Make GUI interactive (by attaching event handling as specified in GUI\Interaction.lua)

end


-- Display the currently active view (this is NOT an update, but an initialisation routine)
local function RenderView()

end


-- Update the existing (and already rendered!) view to display correct information
local function UpdateView()

end




TotalAP.GUI.CreateView = CreateView
TotalAP.GUI.UpdateView = UpdateView -- TODO: All views?


return TotalAP.GUI