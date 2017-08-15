-- WOW UI functions
CreateFrame = function(frameType, frameName, parentFrameReference, inheritsFrame, id)

	local Frame = { -- TODO: Would prefer to use actual UI code, but can't find it? :| Libs should work regardless... but still
		frameType = frameType,
		frameName = frameName,
		parentFrame = parentFrameReference,
		inheritsFrame = inheritsFrame,
		id = id
	}
	
	function Frame:RegisterEvent(eventName)
	
	end
	
	function Frame:SetScript(event)

	end

	return Frame

end



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

GetCurrentRegion = function()

	local regions = { US = 1, KR = 2, EU = 3, TW = 4, CN = 5 } -- Reverse LUT
	return regions[region or "EU"]
	
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
