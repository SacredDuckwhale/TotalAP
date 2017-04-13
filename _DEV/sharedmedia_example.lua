-- LIBRARIES
local smed = LibStub("LibSharedMedia-3.0")

	local texture = smed:Fetch("statusbar", db.texture)
	
	locText:SetFont(smed:Fetch("font", db.font), db.fontsize, db.outline and "OUTLINE" or nil)