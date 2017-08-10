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

UnitName = function(unit)

	if unit == "player" then
		
		return "Duckwhale"
		
	end	

end

UnitClass = function(unit)

	if unit == "player" then
		
		local classDisplayName, class, classID = "Rogue", "ROGUE", 4
		return classDisplayName, class, classID
		
	end	

end

UnitRace = function(unit)

	if unit == "player" then
		
		local raceName, raceId = "Human", "Human"
		return raceName, raceId 
		
	end	

end

UnitFactionGroup = function(unit)

	if unit == "player" then
	
		englishFaction, localizedFaction = "Alliance", "Alliance"
		return englishFaction, localizedFaction
		
	end	

end

GetNumSpecializations = function()

	return 3
	
end

GetSpecialization = function()

	return 1
	
end

-- WOW API objects
GameTooltip = {}
function GameTooltip:HookScript(triggerEvent, scriptFunction)

end
