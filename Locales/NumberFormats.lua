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
	-- leading/trailing spaces are only for zhCN/zhTW and koKR and SHOULD work now
	-- unitsTable is only relevant for locales that use them in their number formats (koKR), but the order is important because the plural terms need to be checked first for some locales that use similar wordings (e.g., mil millones > millones to make sure billions are matched and not millions)
	-- TODO: Unable to test ruRU, zhCN, zhTW locales, as well as properly test the "billions" parts (until more AK is available)
	-- TODO: Differences between zhTW and zhCN?
	local LocaleNumberFormats = {
		
		-- enUS: English (United States)
		["enUS"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["million"] = 1000000,
				},
				[2] = {
					["millions"] = 1000000,
				},
				[3] = {
					["billion"] =  1000000000,
				},
				[4] = {
					["billions"] = 1000000000,
				}
			},
		},
		
		-- deDE: German (Germany)
		["deDE"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ",",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["Millionen"] = 1000000,
				},
				[2] = {
					["Million"] = 1000000,
				},
				[3] = {
					["Milliarden"] = 1000000000,
				},
				[4] = {
					["Milliarde"] = 1000000000,
				},
			},
		},
		 
		-- esES: Spanish (Spain)
		["esES"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
					[1] = {
						["millón"] = 1000000
					},
					[2] = {
						["mil millones"] =  1000000000
					},
					[3] = {
						["millones"] = 1000000
					},
			},
		},
	
		-- frFR: French (France)
		["frFR"] = {	
			["thousandsSeparator"] = " ",
			["decimalSeparator"] = ",",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["million"] = 1000000,
				},
				[2] = {
					["milliard"] = 1000000000,
				},
			},
		},
	
		-- itIT: Italian (Italy)
		["itIT"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ",",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["milioni"] = 1000000,
				},
				[2] = {
					["milione"] = 1000000,
				},
				[3] = {
					["milardi"] =  1000000000,
				},
				[4] = {
					["miliardo"] = 1000000000,
				}
			},
		},
	
		-- koKR: Korean (Korea)
		-- Special format: <text><whitespace><integer number><unit multiplier><whitespace><text>
		["koKR"] = {	
			["thousandsSeparator"] = ",",  -- not actually used 
			["decimalSeparator"] = ".", -- not actually used
			["leadingSpace"] = " ",
			["trailingSpace"] = "",
			["unitsTable"] = {
				[1] = {
					["만의"] = 10000,
				},
				[2] = {
					["억의"] = 100000000,
				},
				[3] = {
					["조의"] = 1000000000000,
				},
			},
		},
	
		-- ptBR: Portuguese (Brazil)
		["ptBR"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["milhões"] = 1000000,
				},
				[2] = {
					["milhão"] = 1000000,
				},
				[3] = {
					["bilhões"] = 1000000000,
				},
				[4] = {
					["bilhão"] = 1000000000,
				},
			},
		},
	
		-- ruRU: Russian (Russia) 
		["ruRU"] = {	
			["thousandsSeparator"] = " ",
			["decimalSeparator"] = ".",
			["million"] = "Миллионов", -- TODO
			["millions"] = "Миллионов", -- TODO
			["billion"] = "Миллиард", -- TODO
			["billions"] = "Миллиарды", -- TODO
			["leadingSpace"] = " ",
			["trailingSpace"] = " ",
			["unitsTable"] = {
				[1] = {
					["млрд"] = 1000000000,
				},
				[2] = {
					["млн"] =  1000000,
				},
			},
		},
	
		-- zhCN: Chinese (Simplified, PRC)
		["zhCN"] = {	
			["thousandsSeparator"] = ",",
			["decimalSeparator"] = ".",
			["million"] = "百万", -- TODO
			["millions"] = "百万", -- TODO
			["billion"] = "十亿", -- TODO
			["billions"] = "数十亿", -- TODO
			["leadingSpace"] = "",
			["trailingSpace"] = "",
		},
		
		-- zhTW: Chinese (Traditional, Taiwan)
		["zhTW"] = {	
			["thousandsSeparator"] = ".",
			["decimalSeparator"] = ".",
			["million"] = "百萬", -- TODO
			["millions"] = "百萬", -- TODO
			["billion"] = "十億", -- TODO
			["billions"] = "數十億", -- TODO
			["leadingSpace"] = "",
			["trailingSpace"] = "",
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
