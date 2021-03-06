-- Tests for Core\Scanner.lua

local locales = { -- Add/remove entry to enable/disable tests for this locale
	"enUS",
	"deDE",
	"frFR",
	"itIT",
	"esES",
	"esMX",
--	"ptBR",
	"ruRU",
	"koKR",
	"zhTW",
	"zhCN"
}

local descriptions = { -- Taken from wowhead; should be accurate except for the number format (they don't use the same one as the WOW client)
	["enUS"] = "Use: Grants %s Artifact Power to your currently equipped Artifact.",
	["ruRU"] = "Использование: Добавляет используемому в данный момент артефакту %s ед. силы артефакта.",
	["frFR"] = "Utilise: Confère %s point de puissance à l’arme prodigieuse que vous maniez.",
	["esES"] = "Uso: Otorga %s p. de poder de artefacto al artefacto que lleves equipado.",
	["esMX"] = "Uso: Otorga %s p. de poder de artefacto al artefacto que lleves equipado.", -- identical to esES
	["itIT"] = "Usa: Fornisce %s Potere Artefatto all'Artefatto attualmente equipaggiato.",
	["ptBR"] = "Uso: Concede %s de Poder do Artefato ao artefato equipado.",
	["deDE"] = "Benutzen: Gewährt Eurem derzeit ausgerüsteten Artefakt %s Artefaktmacht.",
	["koKR"] = "사용 효과: 현재 장착한 유물에 %s의 유물력을 부여합니다.", 
	["zhCN"] = "使用: 将%s点神器能量注入到你当前装备的神器之中。",
	["zhTW"] = "使用: 将%s点神器能量注入到你当前装备的神器之中。", -- identical to zhCN... although I don't know if this is right? They don't have a zhTW version at wowhead
}

local formats = { -- Some random numbers that should represent all the formats (taken from game tooltip texts of the same item at different AK levels) -> AK0, AK13, AK28, AK36, AK49, AK51 for Otherworldly Trophy, and AK43, AK51, AK55 for Heart of Zin-Ashari to hopefully cover everything
-- TODO: zhCN, zhTW, koKR I cannot test, as I don't have a way to use those locales in the EU client. But they seem to be working so far?
	["enUS"] = {
		[75] = "75",
		[1400] = "1,400",
		[127550] = "127,550",
		[1000000] = "1 million",
		[97800000] = "97.8 million",
		[165000000] = "165 million",
		[1000000000] = "1 billion",
		[8800000000] = "8.8 billion",
		[25200000000] = "25.2 billion",
	},
	["ruRU"] = {
		[75] = "75",
		[1400] = "1 400",
		[127550] = "127 550",
		[1000000] = "1 млн",
		[97800000] = "97,8 млн",
		[165000000] = "165 млн",
		[1000000000] = "1 млрд",
		[8800000000] = "8,8 млрд",
		[25200000000] = "25,2 млрд",
	},
	["esMX"] = {
		[75] = "75",
		[1400] = "1,400",
		[127550] = "127,550",
		[1000000] = "1 millón",
		[97800000] = "97.8 millones",
		[165000000] = "165 millones",
		[1000000000] = "1 mil millones",
		[8800000000] = "8.8 mil millones",
		[25200000000] = "25.2 mil millones",
	},
	["esES"] = {
		[75] = "75",
		[1400] = "1 400",
		[127550] = "127 550",
		[1000000] = "1 millón",
		[97800000] = "97,8 millones",
		[165000000] = "165 millones",
		[1000000000] = "1 mil millones",
		[8800000000] = "8,8 mil millones",
		[25200000000] = "25,2 mil millones",
	},
	["ptBR"] = {
		[75] = "75",
		[1400] = "1.400",
		[127550] = "127.550",
		[1000000] = "1 milhão",
		[97800000] = "97.8 milhões",
		[165000000] = "165 milhões",
		[1000000000] = "1 bilhão",
		[8800000000] = "8.8 bilhões",
		[25200000000] = "25.2 bilhões",
	},
	["frFR"] = {
		[75] = "75",
		[1400] = "1 400",
		[127550] = "127 550",
		[1000000] = "1 million",
		[97800000] = "97,8 millions",
		[165000000] = "165 millions",
		[1000000000] = "1 milliard",
		[8800000000] = "8,8 milliards",
		[25200000000] = "25,2 milliards",
	},
	["deDE"] = {
		[75] = "75",
		[1400] = "1.400",
		[127550] = "127.550",
		[1000000] = "1 Million",
		[97800000] = "97,8 Millionen",
		[165000000] = "165 Millionen",
		[1000000000] = "1 Milliarde",
		[8800000000] = "8,8 Milliarden",
		[25200000000] = "25,2 Milliarden",
	},
	["koKR"] = {
		[75] = "75",
		[1400] = "1400",
		[130000] = "13만",
		[1100000] = "110만",
		[97880000] = "9788만",
		[200000000] = "2억",
		[1100000000] = "11억",
		[8800000000] = "88억",
		[25200000000] = "252억",
	},
	["zhTW"] = {
		[75] = "75",
		[1400] = "1400",
		[130000] = "13萬",
		[1100000] = "110萬",
		[97880000] = "9788萬",
		[200000000] = "2億",
		[1100000000] = "11億",
		[8800000000] = "88億",
		[25200000000] = "252億",
	},
	["zhCN"] = {
		[75] = "75",
		[1400] = "1400",
		[130000] = "13万",
		[1100000] = "110万",
		[97880000] = "9788万",
		[200000000] = "2亿",
		[1100000000] = "11亿",
		[8800000000] = "88亿",
		[25200000000] = "252亿",
	},
	["itIT"] = {
		[75] = "75",
		[1400] = "1.400",
		[127550] = "127.550",
		[1000000] = "1 milione",
		[97800000] = "97,8 milioni",
		[165000000] = "165 milioni",
		[1000000000] = "1 miliardo",
		[8800000000] = "8,8 milardi",
		[25200000000] = "25,2 milardi",
	},

}


Test_Scanner_ParseSpellDesc = {}
for i, locale in pairs(locales) do -- Queue tests for this locale

	Test_Scanner_ParseSpellDesc["Test_" .. locale] = function()
	
		local localisedTooltipText = descriptions[locale]
		local localisedFormats = formats[locale]
		
		for expectedValue, testValue in pairs(localisedFormats) do -- Test whether or not the tooltip text using this value can be parsed correctly
--			print("Testing " .. locale .. " for expectedValue = " .. expectedValue)
			local spellDesc = string.format(localisedTooltipText, testValue) -- Insert this value into the tooltip text to simulate the actual item's tooltip
			local scannedValue = tonumber(TotalAP.Scanner.ParseSpellDesc(spellDesc, locale))
--			print("scannedValue is " .. scannedValue)
			luaunit.assertEquals(scannedValue, expectedValue)

		end
		
	end
	
end