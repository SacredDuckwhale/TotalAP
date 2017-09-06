-- Add test suites to luaunit queue
require("Core\\test_cache")
require("Core\\Utils\\test_colours")
require("Core\\Utils\\test_format")
require("Core\\Utils\\test_fqcn")


-- Settings (TODO: Move to WBT/mock environment setup)
locale = "enUS"
region = "EU"
realm = "Outland"


-- Overwrite addon functions (for testing purposes only)
function TotalAP.Debug(msg)
	print("DEBUG: " .. msg)
end

-- Run all tests that have been queued
local exitCode = luaunit.LuaUnit.run("--output", "TAP")
return function() return exitCode end