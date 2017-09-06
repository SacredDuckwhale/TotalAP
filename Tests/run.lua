-- Full testing suite (work in progress) -> Mainly focuses on non-GUI unit tests
-- TODO: Move global environment to setup / different files based on which parts are being mocked (so they can be called by individual test's SetUp routines)
-- TODO: Tests for locales other than enUS, deDE, ruRU, frFR, zhTW (those that use English by default, until users have complained and provided a better format)


-- Required Lua modules
luaunit = require("luaunit") -- stored in global so that testing suites can access it directly

-- Required WBT modules
local TOC = require("Utils/TOC")

-- TODO: Move elsewhere?
local inspect = require('inspect')
function dump(value)

	print(inspect(value))

end


-- Testing suites
require("Core\\test_cache")
require("Core\\Utils\\test_colours")
require("Core\\Utils\\test_format")
require("Core\\Utils\\test_fqcn")


-- Settings
addonName = "TotalAP"
locale = "enUS"
region = "EU"
realm = "Outland"

local args = { ... } -- Pass project path from WBT
local path = args[1]

local root = "..\\"  -- path from tests subfolder to addon root dir
local toc = addonName .. ".toc"

-- Read TOC file and 
TOC:Read((path and path .. "/") or root, toc)

function TotalAP.Debug(msg)
	print("DEBUG: " .. msg)
end

-- Run all tests that have been queued
local exitCode = luaunit.LuaUnit.run()

return function() return exitCode end