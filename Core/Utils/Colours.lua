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

-- These are the default colours from FrameXML

-- NORMAL_FONT_COLOR_CODE		= "|cffffd200";
-- HIGHLIGHT_FONT_COLOR_CODE	= "|cffffffff";
-- RED_FONT_COLOR_CODE			= "|cffff2020";
-- GREEN_FONT_COLOR_CODE		= "|cff20ff20";
-- GRAY_FONT_COLOR_CODE		= "|cff808080";
-- YELLOW_FONT_COLOR_CODE		= "|cffffff00";
-- LIGHTYELLOW_FONT_COLOR_CODE	= "|cffffff9a";
-- ORANGE_FONT_COLOR_CODE		= "|cffff7f3f";
-- ACHIEVEMENT_COLOR_CODE		= "|cffffff00";
-- BATTLENET_FONT_COLOR_CODE	= "|cff82c5ff";
-- DISABLED_FONT_COLOR_CODE	= "|cff7f7f7f";
-- FONT_COLOR_CODE_CLOSE		= "|r";

-- NORMAL_FONT_COLOR			= CreateColor(1.0, 0.82, 0.0);
-- HIGHLIGHT_FONT_COLOR		= CreateColor(1.0, 1.0, 1.0);
-- RED_FONT_COLOR				= CreateColor(1.0, 0.1, 0.1);
-- DIM_RED_FONT_COLOR			= CreateColor(0.8, 0.1, 0.1);
-- GREEN_FONT_COLOR			= CreateColor(0.1, 1.0, 0.1);
-- GRAY_FONT_COLOR				= CreateColor(0.5, 0.5, 0.5);
-- YELLOW_FONT_COLOR			= CreateColor(1.0, 1.0, 0.0);
-- LIGHTYELLOW_FONT_COLOR		= CreateColor(1.0, 1.0, 0.6);
-- ORANGE_FONT_COLOR			= CreateColor(1.0, 0.5, 0.25);
-- PASSIVE_SPELL_FONT_COLOR	= CreateColor(0.77, 0.64, 0.0);
-- BATTLENET_FONT_COLOR 		= CreateColor(0.510, 0.773, 1.0);
-- TRANSMOGRIFY_FONT_COLOR		= CreateColor(1, 0.5, 1);

	-- Colour coding for chat messages. TODO: Use predefined constants instead? But they don't look as pretty :( - colour constants built-in or as a lib?
-- local function GetColour(colour, msg)
	-- local hexTable = {
		-- ["MSG_NORMAL"] = "FFFFFF",
		-- ["MSG_PROGRESS"] = "CC5500",
		-- ["MSG_NOTE"] = "ECEC0F",
		-- ["MSG_CONFIRM"] = "20FF20",
		-- ["MSG_DEBUG"] = "20FF20",
		-- ["MSG_ERROR"] = "FF1A1A",
		-- ["REPGAIN"] = "8179EB", -- test
		-- ["ARTIFACT"] = "E6CC80", 
	-- }
	
	
	-- if hexTable[colour] and msg then return "|c00" .. hexTable[colour] .. msg;
	-- else return msg; -- Default chat colour
	-- end
-- end

---	Consists of various utilities that make working with things easier across all other modules
-- @module Utils


--- Colours.lua.
-- Utilities for dealing with and translating between different ways of representing colours
-- @section Colours


local addonName,  TotalAP = ...

if not TotalAP then return end

--- Translates HTML colour codes to RGB values
-- @param hexString A string representing a colour code in hexadecimal/HTML notation (the leading '#' symbol is optional)
-- @return Red value; 0 if invalid string was given
-- @return Green value; 0 if invalid string was given
-- @return Blue value; 0 if invalid string was given
-- @usage HexToRGB("#FFFEFD") -> { 255, 254, 253 }
local function HexToRGB(hexString)

	local r, g, b = hexString:match("^#?(%x%x)(%x%x)(%x%x)$")
	return tonumber("0x" .. r) or 0, tonumber("0x" .. g) or 0, tonumber("0x" .. b or 0)
	
end

--- Translates RGB values to HTML colour codes
-- @param r Red value
-- @param g Green value
-- @param b Blue value
-- @param[opt] addPrefix Whether or not to prefix the result with a '#' symbol (as used in HTML notation)
-- @return The hexadecimal/HTML representation of the colour
-- @usage RGBToHex(0, 255, 1) -> "00FF01"
-- @usage RGBToHex(0, 255, 1, true) -> "#00FF01"
local function RGBToHex(r, g, b, addPrefix)

	local fmt
	
	if not addPrefix then fmt = "%02x%02x%02x"
	else fmt = "#%02x%02x%02x" end

	local hexString = string.format(fmt, r or 0, g or 0, b or 0)
	return hexString
	
end


TotalAP.Utils.HexToRGB = HexToRGB
TotalAP.Utils.RGBToHex = RGBToHex


local R = {
	HexToRGB,
	RGBToHex,
}

return R