-- Experimental test

-- Required Lua modules
local luaunit = require("luaunit")

-- Settings
local addonName = "TotalAP"

local root = "..\\" 
local toc = addonName .. ".toc"

-- Global environment 
G = {}

-- Localizatuon table
L = {}

-- Variables

-- Lua functions
strmatch = string.match

-- WOW API functions
GetAddOnMetadata = function(addon, value)
	
	if addon == addonName then
		return "1.3.1 (r-23)"
	end
	
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

-- Addon table
T = {}


-- Read TOC file and load all addon-specific lua and xml files (will extract embeds, but not parse actual XML)
function readTOC(filePath)

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

os.exit( luaunit.LuaUnit.run() )