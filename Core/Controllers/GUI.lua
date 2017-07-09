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

--- Designed to handle interaction with the player, react to their input, and adjust program behaviour accordingly
-- @module Controllers

--- GUI.lua.
-- Controls the displays and manages its individual parts according to the user's settings
-- @section GUI


local addonName, TotalAP = ...

if not TotalAP then return end

local function HideGUI()

end

local function ShowGUI()

	-- TODO: Migration from TotalAP.lua (main) to this controller

end


local function HideConfigGUI()

end

local function ShowConfigGUI()

end

-- Show/Hide the AceConfig GUI window (but not the displays used by the addon)
local function ToggleConfigGUI()

end

-- Show/Hide the GUI (all displays EXCEPT the config GUI)
local function ToggleGUI()

	TotalAPAnchorFrame:SetShown(not TotalAPAnchorFrame:IsShown())
	
end

local function UpdateConfigGUI()

end



-- Updates the GUI (by refreshing / re-rendering the active view)
local function UpdateGUI()

	-- Outdated view concept (TODO: Remove once views are working properly with the new one)
	-- if not TotalAP.GUI.GetActiveView() then -- No view exists -> GUI likely not initialised yet
	
		-- TotalAP.Debug("Skipping GUI Update: No view exists (GUI not initialised yet?)")
		-- return false
		
	-- end
	
	-- Update all existing views (TODO: only the active one?)
	
	
	
end

-- TODO: Set this via ConfigUI instead (also, Views need differentiation in its handling)
local function AlignGUI(alignment)

	local validAlignments = { "center", "bottom", "top" }
	for k, v in pairs(validAlignments) do
	
	if alignment == v then -- Update SavedVars and align UI as requested
				TotalArtifactPowerSettings["infoFrame"]["alignment"] = v
				TotalArtifactPowerSettings["specIcons"]["alignment"] = v
				TotalAP.Controllers.UpdateGUI() -- TODO: Unnecessary?
				return true
		end
		
	end
	
	
	TotalAP.Debug("Attempted to align GUI, but the requested alignment does not exist. Valid options are: center (default), bottom, top")
	return false

end

-- Make functions available in the addon namespace
TotalAP.Controllers.ShowGUI = ShowGUI
TotalAP.Controllers.HideGUI = HideGUI
TotalAP.Controllers.ToggleGUI = ToggleGUI
TotalAP.Controllers.UpdateGUI = UpdateGUI
TotalAP.Controllers.ShowConfigGUI = ShowConfigGUI
TotalAP.Controllers.HideConfigGUI = HideConfigGUI
TotalAP.Controllers.ToggleConfigGUI = ToggleConfigGUI
TotalAP.Controllers.UpdateConfigGUI = UpdateConfigGUI
TotalAP.Controllers.AlignGUI = AlignGUI


return TotalAP.Controllers