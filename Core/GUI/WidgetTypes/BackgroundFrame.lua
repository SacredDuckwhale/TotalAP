  ----------------------------------------------------------------------------------------------------------------------
    -- This program is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.
	
    -- This program is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU General Public License for more details.

    -- You should have received a copy of the GNU General Public License
    -- along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------------------------------------------

local addonName, TotalAP = ...

if not TotalAP then return end


local BackgroundFrame = {}

-- Private variables
local defaultValues = {

	backgroundColour = "#C0C0C0", -- Saved as HEX code (different format from the API, and also it doesn't provide a Get() method for this)
	backgroundAlpha = 1,
	backgroundFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND.BLP",

--	TODO: Edges not supported yet, ditto for tiling (because I couldn't be bothered right now. All Views use simple backgrounds for the time being) -> Create Get/Set methods and voilá
	edgeFile, -- Interface/Tooltips/UI-Tooltip-Border
	edgeSize = 0,
	isTiled = false, -- Stretched otherwise
	tileSize = 0,
	insets = { 0, 0, 0, 0 },

}


-- BackgroundFrame inherits from DisplayFrame
setmetatable(BackgroundFrame, TotalAP.GUI.DisplayFrame) 
TotalAP.GUI.DisplayFrame.__index = function(table, key) TotalAP.Debug("Meta lookup of key " .. key .. " in DisplayFrame") return TotalAP.GUI.DisplayFrame[key] end

--local FrameObject -- TODO: Each class needs their own object reference, as they can't simply inherit the superclass' FrameObject variable (which would only be a pointer and not a new object)

-- Get currently used (NOT necessarily displayed) backdrop colour as HTML-style hex code
local function GetBackgroundColour(self)
	return self.backgroundColour or defaultValues.backgroundColour
end

-- Set background colour (does NOT change the actual colour via API, as that is done while Render()-ing!)
local function SetBackgroundColour(self, hexString)
	self.backgroundColour = hexString or self.backgroundColour
end


local function GetBackgroundAlpha(self)
	return self.backgroundAlpha or defaultValues.backgroundAlpha
end

local function SetBackgroundAlpha(self, newAlphaValue)
	self.backgroundAlpha = newAlphaValue or self.backgroundAlpha
end

local function GetBackgroundFile(self)
	return self.backgroundFile or defaultValues.backgroundFile
end

local function SetBackgroundFile(self, newFile)
	self.backgroundFile = newFile or self.backgroundFile
end

local function GetEdgeFile(self)

end

local function SetEdgeFile(self, newFile)

end

local function GetEdgzeSize(self)

end

local function SetEdgeSize(self, newSize)

end

local function IsTiled(self)

end

local function SetTiled(self, tiledFlag)

end

local function GetTileSize(self)

end

local function SetTileSize(self, newSize)

end

local function GetInsets(self)

end

local function SetInsets(self, insetsArray)

end


-- Updates a background frame to display any changes made to its BackgroundFrame container instance
local function Update(self)

	TotalAP.Debug("Updating frame " .. self:GetName() .. " (type = BackgroundFrame)")

		-- Make sure Frame is created properly (and BackgroundFrame was instantiated at some point)
	if not self.FrameObject then
		TotalAP.Debug("FrameObject not found (called Update() before Render()?) -> aborting..")
		return false
	end
	
	-- Set backdrop of actual Frame
	self:SetBackdrop( { bgFile = self.backgroundFile,  edgeFile = self.edgeFile,  tile = self.isTiled, tileSize = self.tileSize, edgeSize = self.tileSize, insets = self.insets } )
	self:SetBackdropColor( TotalAP.Utils.HexToRGB(self.backgroundColor), self.backgroundAlpha)
	
	-- Show actual Frame if it is required
	if self:IsEnabled() and self.FrameObject and not self:IsShown() then
		self.FrameObject:SetParent(self:GetParent()) -- Set saved parent to actual Frame
		self:Show()
	end

end


-- Enable frame and create actual WOW Frame  (that, unlike the BackgroundFrame container object, can be displayed ingame)
local function Render(self)
	
	TotalAP.Debug("Rendering frame " .. self:GetName() .. " (type = BackgroundFrame)")
	
	-- Make sure Frame is created properly (and BackgroundFrame was instantiated at some point)
	-- if not self.FrameObject then
		-- TotalAP.Debug("FrameObject not found (called Render() before CreateNew()?) -> aborting...")
		-- return false
	-- end
	
	-- Create actual WOW Frame
	if not self.FrameObject then
		self.FrameObject = CreateFrame("Frame", addonName .. self:GetName() or addonName .. "BackgroundFrame" .. self:GetNumInstances(), self:GetParent() or UIParent) -- Reference to the actual WOW frame that will be used for all operations on DisplayFrame objects
	end
	
	self:SetFrameStrata("BACKGROUND")
	
	-- Enable this element as part of the view (so it will be shown during the Update() process)
	self:SetEnabled(true)
	
		-- -- Setting the size
	-- Position and size are saved by the client (or are they? Since this isn't technically a frame, but FrameObject is - TODO)
	
	
	
	--self:Hide()
	--self.parent = parent --TODO: Not necessary, or is it important to save the ORIGINAL parent when it can easily be set via API later?
	--self:SetParent(nil)
	--self:SetParent(self:GetParent()) -- This looks odd, but what it does is set the WOW Frame's parent to the DisplayFrame's saved parent (since no Frame exists, it falls back on the class method and not Frame:GetParent())
	
	-- ... then call Update, because for a background frame, no additional setup needs to be done (as opposed to some other GUI elements)
	self:Update()
	
end


-- Create (and return) a new BackgroundFrame widget
local function CreateNew(self, name, parent)

	local BackgroundFrameObject = {}
	
	setmetatable(BackgroundFrameObject, self)  -- Set newly created object to inherit from BackgroundFrame (as defined here)
	
	--TotalAP.GUI.DisplayFrame.__index = TotalAP.GUI.DisplayFrame
	self.__index = function(table, key) 

		TotalAP.Debug("Meta lookup of key: " .. key .. " in BackgroundFrame")
		if self.FrameObject then return self.FrameObject[key] or self[key] end
		return self[key]  -- DisplayFrame is the actual superclass, but the Frame API calls should be used on a FrameObject instead
	
--return TotalAP.GUI.DisplayFrame.key or self.FrameObject.key  -- DisplayFrame is the actual superclass, but the Frame API calls should be used on a FrameObject instead
	end
	
	-- Create actual WOW Frame (but hide it afterwards, since it'll have to be rendered via GUI controller first to be displayed correctly)
	self.numInstances =  self:GetNumInstances() + 1 -- As this new frame is added to the pool, future frames should not use its number to avoid potential name clashes (even though there is no guarantee this ID is actually used, wasting some makes little difference in comparison)
	
	BackgroundFrameObject:SetName(addonName .. (name or  ("BackgroundFrame" .. self:GetNumInstances())), parent) -- e.g., "TotalAPBackgroundFrame1" if no other name was provided
	BackgroundFrameObject:SetParent(parent)
	
	
	return BackgroundFrameObject
	
end


-- Public methods (interface table -> accessible by the View and GUI Controller)
BackgroundFrame.CreateNew = CreateNew
BackgroundFrame.GetBackgroundColour = GetBackgroundColour
BackgroundFrame.SetBackgroundColour = SetBackgroundColour

-- Make class available in the addon namespace
TotalAP.GUI.BackgroundFrame = BackgroundFrame

return BackgroundFrame