-- WOW API functions
GetAddOnMetadata = function(addon, value)
	
	if addon == addonName then
		return "1.3.1 (r-23)"
	end
	
end

GetLocale = function()

	return locale or "enUS"
	
end

GetRealmName = function()

	return realm or "Outland"

end


-- WOW API objects
GameTooltip = {}
function GameTooltip:HookScript(triggerEvent, scriptFunction)

end
