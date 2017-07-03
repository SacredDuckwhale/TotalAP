-- Full testing suite (work in progress) -> Mainly focuses on non-GUI unit tests
-- TODO: Move global environment to setup / different files based on which parts are being mocked (so they can be called by individual test's SetUp routines)
-- TODO: Tests for locales other than enUS, deDE, ruRU, frFR, zhTW (those that use English by default, until users have complained and provided a better format)


-- Required Lua modules
luaunit = require("luaunit") -- stored in global so that testing suites can access it directly

-- Mock environment
require("mock_wowapi")
require("mock_libs")
require("mock_luaenv")

-- Testing suites
require("Core\\Utils\\test_colours")
require("Core\\Utils\\test_format")
require("Core\\Utils\\test_fqcn")


-- Settings
addonName = "TotalAP"
locale = "enUS"
realm = "Outland"

local root = "..\\"  -- path from tests subfolder to addon root dir
local toc = addonName .. ".toc"


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

-- Run all tests that have been queued
os.exit( luaunit.LuaUnit.run() )