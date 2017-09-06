-- Tests for Core\Utils\Format.lua
TestFormat = {}

-- Since value is nil, it should not format anything (and return nothing, which implicitly means "returns nil")
function TestFormat:testNoParameters() 
	luaunit.assertEquals(T.Utils.FormatShort(), nil)
end

-- Given a single numeric value, it should return the formatString and ready-to-insert value (this is identical to format = false and locale = legacy/default)
function TestFormat:testOneParameter()
	
	-- If given a value that isn't a number, it should also implicitly "return nil"
	luaunit.assertEquals(T.Utils.FormatShort("Long time no siege!"), nil)
	
	local actualResultsTable, str, num = {}, "", 0
	
	-- Multiple valid return values -> need to check both for each test (use this function as a shortcut)
	local function compareResults(value, expectedResultsTable)
		
		str, num = T.Utils.FormatShort(value)
		actualResultsTable = { str, num }
		luaunit.assertEquals(actualResultsTable,  expectedResultsTable )
		
	end
	
	compareResults( 0.5, { "%d", 1 })
	compareResults(5.5,  { "%d", 6 })
	compareResults(55,  { "%d", 55 })
	compareResults(550,  { "%d", 550 })
	compareResults(5500,  { "%d", 5500 })
	compareResults(55000,  { "%.1fk", 55 })
	compareResults(550000,  { "%.0fk", 550 })
	compareResults(5500000,  { "%.2fm", 5.5 })
	compareResults(55000000,  { "%.1fm", 55 })
	compareResults(550000000,  { "%.1fm", 550 })
	compareResults(5500000000,  { "%.1fb", 5.5 })
	
end

-- Given two valid parameters, the formatting should be applied directly
function TestFormat:testTwoParameters()

	-- If the second parameter is false, it is treated as if none was given -> covered by testOneValidParameter already
	
	-- If it evaluates to true, the formatting is directly applied to the number (and the legacy format will be used)
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true), "5500")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true), "55k")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true), "550k")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true), "5.5m")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true), "55m")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true), "550m")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true), "5.5b")
	
end

-- Given three parameters, the given locale should be used to determine the number format that will then be applied
function TestFormat:testThreeParameters_enUS()

	-- enUS (different from legacy, but only barely)
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "enUS"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "enUS"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "enUS"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "enUS"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "enUS"), "5.5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "enUS"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "enUS"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "enUS"), "5.5M")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "enUS"), "55M")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "enUS"), "550M")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "enUS"), "5.5B")
	
end

function TestFormat:testThreeParameters_deDE()

	-- deDE
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "deDE"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "deDE"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "deDE"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "deDE"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "deDE"), "5,5 Tsd.")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "deDE"), "55 Tsd.")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "deDE"), "550 Tsd.")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "deDE"), "5,5 Mio.")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "deDE"), "55 Mio.")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "deDE"), "550 Mio.")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "deDE"), "5,5 Mrd.")

end

function TestFormat:testThreeParameters_frFR()
	
	-- frFR
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "frFR"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "frFR"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "frFR"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "frFR"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "frFR"), "5,5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "frFR"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "frFR"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "frFR"), "5,5M")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "frFR"), "55M")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "frFR"), "550M")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "frFR"), "5,5B")
	
end

function TestFormat:testThreeParameters_ruRU()
	
	-- ruRU
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "ruRU"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "ruRU"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "ruRU"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "ruRU"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "ruRU"), "5.5к")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "ruRU"), "55к")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "ruRU"), "550к")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "ruRU"), "5.5 млн")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "ruRU"), "55 млн")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "ruRU"), "550 млн")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "ruRU"), "5.5 млрд")

end

function TestFormat:testThreeParameters_zhTW()

	-- zhTW
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "zhTW"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "zhTW"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "zhTW"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "zhTW"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "zhTW"), "5.5千")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "zhTW"), "5.5萬")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "zhTW"), "55萬")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "zhTW"), "550萬")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "zhTW"), "5500萬")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "zhTW"), "5.5億")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "zhTW"), "55億")
	
end

function TestFormat:testThreeParameters_esES()
	
	-- esES
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "esES"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "esES"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "esES"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "esES"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "esES"), "5,5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "esES"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "esES"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "esES"), "5,5 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "esES"), "55 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "esES"), "550 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "esES"), "5,5 bil.")

end

function TestFormat:testThreeParameters_esMX()

	-- esMX
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "esMX"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "esMX"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "esMX"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "esMX"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "esMX"), "5.5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "esMX"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "esMX"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "esMX"), "5.5 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "esMX"), "55 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "esMX"), "550 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "esMX"), "5.5 bil.")

end

function TestFormat:testThreeParameters_itIT()

	-- itIT
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "itIT"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "itIT"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "itIT"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "itIT"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "itIT"), "5,5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "itIT"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "itIT"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "itIT"), "5,5M")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "itIT"), "55M")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "itIT"), "550M")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "itIT"), "5,5B")
	
end

function TestFormat:testThreeParameters_zhCN()

	-- zhCN
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "zhCN"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "zhCN"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "zhCN"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "zhCN"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "zhCN"), "5500")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "zhCN"), "5.5万")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "zhCN"), "55万")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "zhCN"), "550万")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "zhCN"), "5500万")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "zhCN"), "5.5亿")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "zhCN"), "55亿")
	
end

function TestFormat:testThreeParameters_koKR()

	-- koKR
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "koKR"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "koKR"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "koKR"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "koKR"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "koKR"), "5500")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "koKR"), "5.5만")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "koKR"), "55만")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "koKR"), "550만")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "koKR"), "5500만")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "koKR"), "5.5억")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "koKR"), "55억")
	
end

function TestFormat:testThreeParameters_ptBR()

	-- ptBR
	luaunit.assertEquals(T.Utils.FormatShort(0.5, true, "ptBR"), "1")
	luaunit.assertEquals(T.Utils.FormatShort(5.5, true, "ptBR"), "6")
	luaunit.assertEquals(T.Utils.FormatShort(55, true, "ptBR"), "55")
	luaunit.assertEquals(T.Utils.FormatShort(550, true, "ptBR"), "550")
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "ptBR"), "5.5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "ptBR"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "ptBR"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "ptBR"), "5.5M")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "ptBR"), "55M")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "ptBR"), "550M")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "ptBR"), "5.5B")
	
end
