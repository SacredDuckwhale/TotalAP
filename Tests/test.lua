-- Experimental testing suite

-- TODO: Move global environment to setup / different files based on which parts are being mocked (so they can be called by individual test's SetUp routines)
-- TODO: Move individual tests to other files (to turn them into a test suite that can be run individually)
-- TODO: Tests for locales other than enUS, deDE, ruRU, frFR, zhTW (those that use English by default, until users have complained and provided a better format)

-- Required Lua modules
local luaunit = require("luaunit")


-- Settings
local addonName = "TotalAP"
local locale = "enUS"

local root = "..\\" 
local toc = addonName .. ".toc"


-- Variables
G = {} -- Global environment 
L = {} -- Localization table
T = {} -- Addon table



-- Lua functions
strmatch = string.match


-- WOW API functions
GetAddOnMetadata = function(addon, value)
	
	if addon == addonName then
		return "1.3.1 (r-23)"
	end
	
end

GetLocale = function()

	return locale or "enUS"
	
end


-- WOW API objects
GameTooltip = {}
function GameTooltip:HookScript(triggerEvent, scriptFunction)

end


-- Libary objects
LibStub = function(libraryName)

	LS = {}

	if libraryName == "AceLocale-3.0" then -- AceLocale mockup
	
		function LS:NewLocale(addonName, locale, isDefaultLocale)
		
		L.addonName = {}
			L.addonName.locale = {}
			
			if isDefaultLocale then -- Set new locale to be the default
				L.addonName.activeLocale = locale
			else
				L.addonName.activeLocale = "enUS" -- use English as default locale
			end
			
			return L.addonName.locale
			
		end
		
		function LS:GetLocale(addonName, locale)
			return L.addonName.locale
		end
		
	end
	
	if libraryName == "AceAddon-3.0" then -- AceLocale mockup
		
		function LS:NewAddon(addonName, ...)
		
			local addonObject = {}
		
			local mixins = ...
			
			return addonObject
		end
		
	end
	
	if libraryName == "Masque" then -- Masque mockup
		
		local M = {}
	
		return M
	
	end
	
	if libraryName == "LibSharedMedia-3.0" then -- SharedMedia mockup
		
		local LSM = {}
		
		return LSM
		
	end
	
	return LS

end


-- Read TOC file and load all addon-specific lua and xml files (will extract embeds, but not parse actual XML)
function readTOC(filePath) -- TODO: Split this up into TOC Parser and Lua Loader

	-- Establish load order and assemble list of all addon files (by reading the TOC file)
	local addonFiles = {}

	-- Read TOC file
	print("Opening file: " .. toc .. "\n")
	local file = assert(io.open(root .. toc, "r") or io.open(toc), "Could not open " .. root .. toc)
		
	-- Add files to loading queue
	for line in file:lines() do -- Read line to find .lua files that are to be loaded
		if line ~= "" and not line:match("#") and not line:match("Libs\\" )then -- is a valid file (no comment or empty line) -> Add file to loader
			
			if not line:match("%.xml") then -- .lua file -> add directly
				addonFiles[#addonFiles+1] = line
				print("Adding file: " .. line .. " (position: " .. #addonFiles .. ")")
				
			else -- .xml file -> parse and add files that are included instead
				print("Detected XML file: " .. line)
				
				local xmlFile = assert(io.open(root .. line, "r") or io.open(line), "Could not open " .. line)
				local text = xmlFile:read("*all")
				xmlFile:close()
				
				local pattern = "<Script%sfile=\"(.-)\"/>"
				local folder = line:match("(.+)\\.-%.xml") .. "\\"
				print(folder)
				for embeddedFile in string.gmatch(text, pattern) do
					addonFiles[#addonFiles+1] = folder .. embeddedFile
					print("Adding embedded file: " .. folder .. embeddedFile .. " (position: " .. #addonFiles .. ")")
				end
			end
			
		end
	end	
	print("\nA total of " .. #addonFiles .. " files were added to the loader after parsing the TOC")
	file:close()

	 -- Load addon files in order (simulating the client's behaviour)
	G.addonName = {}

	 for index, fileName in ipairs(addonFiles) do -- Attempt to load file 
		
		print(index, #G.addonName, fileName)
		G.addonName[#G.addonName+1] = loadfile(root .. fileName)(addonName, T)
		
	end
	print("Added " .. #G.addonName .. " files to the (simulated) global environment")

end


-- Read TOC
readTOC(root .. toc)


-- Add tests for individual modules
TestCore = {}
TestGUI = {} -- TODO: This might be impossible
TestControllers = {}
TestUtils = {}

-- Core\Utils\Colours.lua

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
	luaunit.assertEquals(T.Utils.FormatShort(5500, true, "esES"), "5.5K")
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "esES"), "55K")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "esES"), "550K")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "esES"), "5.5 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "esES"), "55 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "esES"), "550 mil.")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "esES"), "5.5 bil.")

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
	luaunit.assertEquals(T.Utils.FormatShort(55000, true, "koKR"), "5.5만의")
	luaunit.assertEquals(T.Utils.FormatShort(550000, true, "koKR"), "55만의")
	luaunit.assertEquals(T.Utils.FormatShort(5500000, true, "koKR"), "550만의")
	luaunit.assertEquals(T.Utils.FormatShort(55000000, true, "koKR"), "5500만의")
	luaunit.assertEquals(T.Utils.FormatShort(550000000, true, "koKR"), "5.5억의")
	luaunit.assertEquals(T.Utils.FormatShort(5500000000, true, "koKR"), "55억의")
	
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



os.exit( luaunit.LuaUnit.run() )