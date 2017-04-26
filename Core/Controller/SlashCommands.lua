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


-- SlashCommands.lua
-- Handling of slash commands (duh)

local addonName, TotalAP = ...

if not TotalAP then return end


-- TODO: Localised versions (especially for non-Latin characters) - they would be optional, of course
local slashCommand = "totalap"
local slashCommandAlias = "ap"

-- AceLocale localisation table -> used for console output
local L = LibStub("AceLocale-3.0"):GetLocale("TotalAP", false); -- Localization table

-- TODO: Use AceDB for this
local settings = TotalAP.DBHandler.GetDB()


-- Match commands to locale table keys (the actual strings are NOT used, except to look up the correct translation)
-- TODO: Slash commands themselves aren't localised yet. Maybe they could be?
local slashCommands = {
	
	["counter"] = "Toggle display of the item counter",
	["progress"] = "Toggle spell overlay notification (glow effect) when new traits are available",
	["glow"] = "Toggle spell overlay notification (glow effect) when new traits are available",
	["buttontext"] = "Toggle short summary of the tooltip information as an additional display next to the action button",
	
	["hide"] = "Toggle all displays (will override the individual display's settings)",
	["button"] = "Toggle button visibility (tooltip visibility is unaffected)",
	["bars"] = "Toggle bar display for artifact power progress",
	["tooltip"] = "Toggle tooltip display for artifact power items",
	["icons"] = "Toggle icon and text display for artifact power progress",
	
	["loginmsg"] = "Toggle login message on load",
	["combat"] = "Toggle visibility in combat",
	["reset"] =  "Load default settings (will overwrite any changes made)",
	["debug"] = "Toggle debug mode (not particularly useful as long as everything is working as expected)",
	
}

-- Actual handling of slash commands (TODO: Not fully migrated yet -> most won't work until it is done)
local slashHandlers = {

	["counter"] = function() -- Toggle counter display in tooltip

		if not settings.tooltip.showNumItems then
			TotalAP.ChatMsg(L["Item counter enabled."])
		else
			TotalAP.ChatMsg(L["Item counter disabled."]);
		end
		
		settings.tooltip.showNumItems = not settings.tooltip.showNumItems;
	
	end,
	
	["progress"] = function() -- Enable progress report in tooltip
	
		if not settings.tooltip.showProgressReport then
			TotalAP.ChatMsg(L["Progress report enabled."]);
		else
			TotalAP.ChatMsg(L["Progress report disabled."]);
		end
		
		settings.tooltip.showProgressReport = not settings.tooltip.showProgressReport;
	end,
	
	["glow"] = function() -- Toggle button spell overlay effect -> Notification when new traits are available
		
		if not settings.actionButton.showGlowEffect then
			settings.actionButton.showGlowEffect = true; 
			TotalAP.ChatMsg(L["Button glow effect enabled."]);
		else
			settings.actionButton.showGlowEffect = false;
			TotalAP.ChatMsg(L["Button glow effect disabled."]);
		end
		
		if not settings.specIcons.showGlowEffect then
			settings.specIcons.showGlowEffect = true; 
			TotalAP.ChatMsg(L["Spec icons glow effect enabled."]);
		else
			settings.specIcons.showGlowEffect = false;
			TotalAP.ChatMsg(L["Spec icons glow effect disabled."]);
		end
		
	end,
	
	["buttontext"] = function() -- Toggle an additional display of the (originally tooltip-only) current item's AP value / total AP in bags
		
		if settings.actionButton.showText then
			TotalAP.ChatMsg(L["Action button text disabled."]);
		else
			TotalAP.ChatMsg(L["Action button text enabled."]);
		end
		
	settings.actionButton.showText = not settings.actionButton.showText;

	end,
	
	["hide"] = function()  -- Toggle all displays
		
	
		if settings.enabled then
			TotalAP.ChatMsg(L["All displays are now being hidden."])
		else
			TotalAP.ChatMsg(L["All displays are now being shown."])
		end
		
		TotalAP_ToggleAllDisplays()

	end,
	
	["button"] = function() -- Toggle button visibility (tooltip functionality remains)
				

		TotalAP_ToggleActionButton();
		
	end,
	
	["tooltip"] = function() -- Toggle tooltip additions for AP items
	
		TotalAP.ToggleTooltipDisplay();

	end,
	
	["bars"] = function() -- Toggle infoFrame (bar display)


		TotalAP_ToggleBarDisplay();	
		
	end,
	
	["icons"] = function() -- Toggle spec icons

		TotalAP_ToggleSpecIcons();	

	end,
	
	["loginmsg"] = function() -- Toggle notification when loading/logging in (effective on next login)
		
		if settings.showLoginMessage then
			TotalAP.ChatMsg(L["Login message is now hidden."]);
		else
			TotalAP.ChatMsg(L["Login message is now shown."]);
		end
		
	settings.showLoginMessage = not settings.showLoginMessage;
	
	end,
	
	["combat"] =  function() -- Toggle automatic hiding of the display while player is in combat (also: vehicle/pet battle but those can't be turned off here)
		if settings.hideInCombat then
			TotalAP.ChatMsg(L["Display will now remain visible in combat."]);
		else
			TotalAP.ChatMsg(L["Display will now be hidden in combat."]);
		end
		
	settings.hideInCombat = not settings.hideInCombat;

	end,
	
	["reset"] =  function() -- Load default values for all settings

		TotalAP.DBHandler.RestoreDefaults()
		--RestoreDefaultSettings();
		TotalAP.ChatMsg(L["Default settings loaded."]);
		
		TotalAPAnchorFrame:ClearAllPoints();
		TotalAPAnchorFrame:SetPoint("CENTER", UIParent, "CENTER");

	end,
	
	["debug"] = function() -- Toggle debug mode (for debugging/testing purposes only -> undocumented)
				
		if settings.debugMode then
			TotalAP.ChatMsg(L["Debug mode disabled."]);
		else
			TotalAP.ChatMsg(L["Debug mode enabled."]);
		end
		
		settings.debugMode = not settings.debugMode;
	end,


-- TODO: Debugging/undocumented commands should be separate
	-- elseif command == "anchor" then -- Show anchor frame
		-- --TotalAPAnchorFrame:SetShown(TotalAPAnchorFrame:IsShown());
		-- TotalAPAnchorFrame:SetBackdrop(
			-- {
				-- bgFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Background.blp",
												-- -- edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												-- -- tile = true, tileSize = 16, edgeSize = 16, 
													-- -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
			-- }
		-- ); 
	-- [[ For testing and debugging purposes only]] --
		-- elseif command == "load" then -- Load settings manually (including verification of SavedVars)  (for debugging purposes only)-> undocumented 	
		-- LoadSettings();

	-- end,
	
	
	-- elseif command == "flash" then --  Add spell overlay to action button (for debugging/testing purposes only -> undocumented)
	
		-- FlashActionButton(TotalAPButton, true);
		-- for i = 0, GetNumSpecializations() do
			-- FlashActionButton(TotalAPSpecIconButtons[i], true);
		-- end

	-- elseif command == "unflash" then -- Remove spell overlay from all buttons (for debugging/testing purposes only -> undocumented)
	
		-- FlashActionButton(TotalAPButton, false);
		-- for i = 0, GetNumSpecializations() do
				-- FlashActionButton(TotalAPSpecIconButtons[i], false);
		-- end
}


local function GetSlashCommand()
	return slashCommand
end

local function GetSlashCommandAlias()
	return slashCommandAlias
end

-- Prints a list of all available slash commands to the DEFAULT_CHAT_FRAME (using the addon-specific print methods with colour-coding)
local function PrintSlashCommands()

		-- TODO: Could use AceConsole:print(f) for this, but... meh. It would have to format the output manually to adhere to the addon's standards (as set in Core\ChatMsg), and who has time for that?
		TotalAP.ChatMsg(L["[List of available commands]"]);
		for cmd in pairs(slashCommands) do -- print description saved in localisation table - TODO: Order could be set via index/ipairs if it matters?
			TotalAP.ChatMsg(cmd .. " - " .. L[slashCommands[cmd]])
		end
end


-- Handles console input (slash commands)
-- TODO: Only one argument is supported currently (use AceConsole:GetArgs to parse them more easily)
local function SlashCommandHandler(input)

	-- Preprocessing of user input
	-- input = string.lower(input);
	-- local command, param = input:match("^(%S*)%s*(.-)$");
	
	local AceAddon = LibStub("AceAddon-3.0"):GetAddon("TotalAP") -- should be loaded by the main chunk earlier, otherwise it will error out
	local command = AceAddon:GetArgs(input)
	
	-- Lists all available commands as chat output
	-- TODO: Better way to list all available commands, especially as functionality is extended (GUI?)
	for validCommand in pairs(slashCommands) do
		if command == validCommand then -- Execute individual handler function for this slash command
			local slashHandlerFunction = slashHandlers[command]
			TotalAP.Debug("Recognized slash command: " .. command .. " - executing handler function..." )
			slashHandlerFunction()
			return -- to skip the "help" being displayed
		end
	end
	
	-- Display help / list of commands
	PrintSlashCommands()
	
	-- Always update displays to make sure any changes will be displayed immediately (if possible/not locked)
	TotalAP.GUI.UpdateView()
end


-- Make functions available in the addon namespace
TotalAP.Controller.GetSlashCommand = GetSlashCommand
TotalAP.Controller.GetSlashCommandAlias = GetSlashCommandAlias
TotalAP.Controller.PrintSlashCommands = PrintSlashCommands
TotalAP.Controller.SlashCommandHandler = SlashCommandHandler

return TotalAP.Controller
