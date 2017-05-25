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

local addonName,  TotalAP = ...

if not TotalAP then return end

-- Translate HTML colour codes to RGB values (as used by the WOW API)
local function HexToRGB(hexString)

	local r, g, b = hexString:match("^#(%x%x)(%x%x)(%x%x)$")
	return tonumber("0x" .. r) or 0, tonumber("0x" .. g) or 0, tonumber("0x" .. b or 0)
	
end

-- Translate RGB values to HTML colour code
local function RGBToHex(r, g, b)

	local hexString = string.format("#%02x%02x%02x", r or 0, g or 0, b or 0)
	return hexString
	
end


TotalAP.Utils.HexToRGB = HexToRGB
TotalAP.Utils.RGBToHex = RGBToHex


local R = {
	HexToRGB,
	RGBToHex,
}

return R