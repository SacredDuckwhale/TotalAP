 --[[ TotalAP - Artifact Power tracking addon for World of Warcraft: Legion
 
	-- LICENSE (short version):
	
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
--]]


--- 
-- @module Core

--- SavedVars.lua.
-- Provides an interface for the addon's settings database (i.e., all settings stored in the SavedVariables\TotalAP.lua file)
-- @section SavedVars


local addonname, TotalAP = ...

if not TotalAP then return end

local validators = {
	
	debugMode = function(value)
			return type(value) == "boolean"
		end,
	
	
	
	["infoFrame"] = {
		["border"] = {
			["defaultValue"] = 1,
			["IsValid"] = function(value)
				return type(value) == "number" and value >= 1
			end,
		},
		["progressBar"] = {
			["alpha"] = {
				["defaultValue"] = 0.2,
				["IsValid"] = function(value)
					return type(value) == "number" and value > 0 and value <= 1
				end,
			}
		}
	}
	
}

--- Dynamic name lookup (read) - from the Lua manual
-- @param f The dynamic field name (string) that should be looked up
-- @param[opt] t The table that the field should be set in (defaults to _G)
-- @usage getfield("some.field", defaultSettings) -> value of defaultSettings["some"]["field"]
-- @usage getfield("some.field") -> value of _G["some"]["field"]
function getfield (f, t)
      local v = t or _G    -- start with the table of globals
      for w in string.gfind(f, "[%w_]+") do
        v = v[w]
      end
      return v
    end

--- Dynamic name lookup (write) - from the Lua manual
-- @param f The dynamic field name (string) that should be looked up
-- @param v The value that the field should be set to
-- @param[opt] t The table the field should be looked up in (defaults to _G)
function setfield (f, v, t)
	local t = t or _G -- start with the table of globals
      for w, d in string.gfind(f, "([%w_]+)(.?)") do
        if d == "." then      -- not last field?
          t[w] = t[w] or {}   -- create table if absent
          t = t[w]            -- get the table
        else                  -- last field
          t[w] = v            -- do the assignment
        end
      end
    end


	
-- SavedVars defaults (to check against, and load if corrupted/rendered invalid by version updates)
local defaultSettings =	{	
		-- General options
		
		-- controls what output will be printed in the chat frame
		debugMode = false,
		verbose = true,
		showLoginMessage = true,
		enabled = true,		-- This controls the entire display, but NOT the individual parts (which will be hidden, but their settings won't be overridden)
		hideInCombat = true,
		numberFormat = GetLocale(),
		
	--	showNumItems = true, -- TODO: Deprecated
		--showProgressReport = true, -- TODO: Deprecated
		
		--showActionButton = true, -- TODO: Toggles everything. That should be changed
		
		--showButtonGlowEffect = true, -- TODO: actionButton
		
		actionButton = {
			enabled = true,
			showGlowEffect = true,
			minResize = 20,
			maxResize = 100,
			showText = true
		},

		-- Display options for the spec icons
		specIcons = {
			enabled = true,
			showGlowEffect = true,
			size = 18,
			border = 1,
			inset = 1,
			
			alignment = "center", -- TODO: Provide option via GUI (AceConfig)
		},
		
		-- Controls what information is displayed in the tooltip
		tooltip = {
			enabled = true, 
			showProgressReport = true,
			showNumItems = true
		},
		
		-- Display options for the bar displays
		infoFrame = {
			enabled = true,
			barTexture = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar.blp", -- Default texture. TODO. SharedMedia
			barHeight = 16,
			border = 1,
			inset = 1,
			showMiniBar = true,
			alignment = "center", -- TODO: Provide option via GUI (AceConfig)
			
			progressBar = {
				red = 250,
				green = 250,
				blue = 250,
				alpha = 0.2
			},
			
			unspentBar = {
				red = 50,
				green = 150,
				blue = 250,
				alpha = 1
			},
			
			inBagsBar = {
				red = 50,
				green = 95,
				blue = 150,
				alpha = 1
			}
		}
		
	}

--- Retrieve the saved variables table containing all of the addon's settings
-- @return Reference to the settings table
local function GetReference()
	
	return TotalArtifactPowerSettings
	
end

--- Returns the default settings for first startup or manual/automatic resets during validation at a later point in time
-- @return Table containing the default values for all settings
local function GetDefaults()

	return defaultSettings
	
end

--- Resets a given field in the settings to its default value
-- @param path The field name (string) to the setting
-- @usage ResetValue("tooltip.enabled") -> Sets the saved vars entry for tooltip.enabled to its default value
local function ResetValue(path)

	local settings = GetReference()
	
	-- TODO: Invalid field(path)?
	
	local oldValue = getfield(path, settings)
	local defaultValue = getfield(path, defaultSettings)
	local setfield(path, defaultValue, settings)
	
	return 
	
	-- Experimental stuff - TODO: Delete it later
	if type(path) == "string" then
	
		local matches = path:gmatch("(.+)%.")
		
		print("#matches = " .. #matches)
		local currentNode = defaultSettings
		
		for index, key in ipairs(matches) do --  Traverse default settings to follow the given path of keys (as far as it exists)
			
			print("Key: " .. key .. " (index: " .. index)
			currentNode = currentNode.key
			if currentNode == nil then -- Invalid key -> Stop traversion
				
				return
				
			end
			
		end
		
		-- If this point is reached, the key must be a valid one -> Set it to its default value
		
	
	end

	local keys = { ... }
	local n = #keys
	
	if n > 0 then -- check if all given keys are strings, and exist in the defaults table
		
		for i=1, n-2 do --
		
			
		
		end
		
		
	end

	if settings.key ~= nil and defaultValues.key ~= nil then -- Replace key with its default value
		
		if type(defaultValues.key == "table") then -- copy table, don't pass a reference
			settings.key = defaultValues.key
		end
	end
	
end

--- Reset all settings to their default values
local function RestoreDefaults()

	TotalArtifactPowerSettings = defaultSettings

end

--- Validate all settings and reset those that weren't found to be corret to their default values (while printing a debug message)
local function Validate()

	-- for all keys in settings -> IsValidValue(key)
	
	-- Validate entries
	
	-- Add missing entries
	
	-- Delete unused (deprecated) entries
	
end

local function IsValidKey(field)

end

local function IsValidValue(field, value)

end

local function GetDefaultValue(field)

end


local function IsDefaultValue(field, value)

end

--- Get value of a given field from the addon's settings
-- @param field String representing the field that is to be returned
-- @returns Value of said field if it exists; nil otherwise
local function GetValue(field)

	return getfield(field, GetReference())

end

-- @param field String representing the field that is to be returned
-- @param[opt] value Value that the field is to be set to (uses that field's defaultValue if none was given)
-- @return true if the value was valid and could be set; nil otherwise
local function SetValue(field, value)

	-- Validate before setting it
	
	-- Print debug msg if value was invalid and could not be set
	
end


TotalAP.Settings.
TotalAP.Settings.
TotalAP.Settings.
TotalAP.Settings.
TotalAP.Settings.
TotalAP.Settings.

return TotalAP.Settings