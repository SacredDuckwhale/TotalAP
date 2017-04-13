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

local addonName, T = ...

	-- Format styles used by the client for different locales (in the spell descriptions of AP "Empowering" spells)
	-- Separators as usual, million/billion are used to detect numbers that are displayed like "1.5 million" = 1500000 = 1,5000,000 etc. as those are sometimes abbreviated by the client
	-- TODO: Unable to test ruRU, zhCN, zhTW locales, as well as properly test the "billions" parts (until more AK is available)
	local LocaleNumberFormats = {
		
		-- enUS: English (United States)
		["enUS"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["million"] = "million",
			["millions"] = "millions",
			["billion"] = "billion",
			["billions"] = "billions"
		},
		
		-- deDE: German (Germany)
		["deDE"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ",",
			["million"] = "Million",
			["millions"] = "Millionen",
			["billion"] = "Milliarde",
			["billions"] = "Milliarden"
		},
		 
		-- esES: Spanish (Spain)
		["esES"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ",",
			["million"] = "millón", -- TODO
			["millions"] = "millones", -- TODO
			["billion"] = "mil millones", -- TODO
			["billions"] = "miles de millones" -- TODO
		},
	
		-- frFR: French (France
		["frFR"] = {	
			["thousandsSeparator"] = " ",
			["decimalSeparator"] = ",",
			["million"] = "million", -- TODO
			["millions"] = "des millions", -- TODO
			["billion"] = "milliard", -- TODO
			["billions"] = "des milliards" -- TODO
		},
	
		-- itIT: Italian (Italy)
		["itIT"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ",",
			["million"] = "milione", -- TODO
			["millions"] = "milioni", -- TODO
			["billion"] = "miliardo", -- TODO
			["billions"] = "miliardi" -- TODO
		},
	
		-- koKR: Korean (Korea)
		["koKR"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["million"] = "백만", -- TODO
			["millions"] = "수백만", -- TODO
			["billion"] = "십억", -- TODO
			["billions"] = "수십억" -- TODO
		},
	
		-- ptBR: Portuguese (Brazil)
		["ptBR"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ".",
			["million"] = "milhão", -- TODO
			["millions"] = "milhões", -- TODO
			["billion"] = "bilhão", -- TODO
			["billions"] = "bilhões" -- TODO
		},
	
		-- ruRU: Russian (Russia) - UI AddOn
		["ruRU"] = {	
			["thousandsSeparator"] = " ",
			["decimalSeparator"] = ",",
			["million"] = "Миллионов", -- TODO
			["millions"] = "Миллионов", -- TODO
			["billion"] = "Миллиард", -- TODO
			["billions"] = "Миллиарды" -- TODO
		},
	
		-- zhCN: Chinese (Simplified, PRC)
		["zhCN"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["million"] = "百万", -- TODO
			["millions"] = "百万", -- TODO
			["billion"] = "十亿", -- TODO
			["billions"] = "数十亿" -- TODO
		},
		
		-- zhTW: Chinese (Traditional, Taiwan)
		["zhTW"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ".",
			["million"] = "百萬", -- TODO
			["millions"] = "百萬", -- TODO
			["billion"] = "十億", -- TODO
			["billions"] = "數十億" -- TODO
		}
	}

	 -- enGB: English (United Kingdom) - enGB clients return enUS
	LocaleNumberFormats["enGB"] = LocaleNumberFormats["enUS"] -- Not sure if necessary, but it's better to be safe than sorry (in case enGB is indexed which seems unlikely due to the enGB client returning enUS via GetLocale())
	-- enMX: Spanish (Mexico) - should use similar format to Spanish (Spain)
	LocaleNumberFormats["esMX"] = LocaleNumberFormats["esES"]
	
	
	-- Returns number format for nonstandard locales (ease of use)
	-- Will return a single key if given its index, or the entire localisation table by default
	local function GetLocaleNumberFormat(locale, key)
		
		if not locale then
			locale = GetLocale()
		end
		
		if not key then
			return LocaleNumberFormats[locale]
		end
		
		return LocaleNumberFormats[locale][key]
	end
	
	
	-- Make functions available in the addon's namespace  (T is the addonTable)
if not T then return end
T.GetLocaleNumberFormat = GetLocaleNumberFormat
