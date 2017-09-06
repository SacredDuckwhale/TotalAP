-- Full testing suite (work in progress) -> Mainly focuses on non-GUI unit tests
-- TODO: Move global environment to setup / different files based on which parts are being mocked (so they can be called by individual test's SetUp routines)
-- TODO: Tests for locales other than enUS, deDE, ruRU, frFR, zhTW (those that use English by default, until users have complained and provided a better format)





-- Testing suites
require("Core\\test_cache")
require("Core\\Utils\\test_colours")
require("Core\\Utils\\test_format")
require("Core\\Utils\\test_fqcn")


-- Settings
locale = "enUS"
region = "EU"
realm = "Outland"



function TotalAP.Debug(msg)
	print("DEBUG: " .. msg)
end

-- Run all tests that have been queued
local exitCode = luaunit.LuaUnit.run("--output", "TAP")

return function() return exitCode end