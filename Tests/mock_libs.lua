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
