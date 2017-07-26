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

--- 
-- @module GUI

--- DefaultView.lua.
-- The classic TotalAP GUI as it was used in earlier versions
-- @section GUI


local addonName, TotalAP = ...
if not TotalAP then return end


local DefaultView = {}

--- Creates a new ViewObject
-- @param self Reference to the caller
-- @return A representation of the View (ViewObject)
local function CreateNew(self)
	
	local ViewObject = {}

	setmetatable(ViewObject, self) -- The new object inherits from this class
	self.__index = TotalAP.GUI.View -- ... and this class inherits from the generic View template
	
	-- TODO: Get those from the settings, so that they can be changed in the options GUI (under tab: Views -> DefaultView, along with enabling/disabling/repositioning individual display components)
	-- Stuff that needs to be moved to AceConfig settings
	
	local hSpace, vSpace = 3, 5 -- space between display elements
	
	local barWidth, barHeight, barInset = 100, 18, 1
	
	local minButtonSize, maxButtonSize = 20, 60 -- TODO: smaller than 60 looks odd, 80 before? should be 4x size of the bars at most, and 1x at the least to cover all specs
	local defaultButtonSize = 40 -- TODO: Layout Cache or via settings?
	
	local buttonTextTemplate = "GameFontNormal"
	
	local specIconSize = 18
	local specIconBorderWidth = 1
	local specIconTextWidth = 40
	
	local specIconTextTemplate = "GameFontNormal"
	
	local stateIconWidth, stateIconHeight = (maxButtonSize - 3 * vSpace) / 4, barHeight + barInset
	
	local sliderHeight = 20
		
	-- End stuff that needs to be moved to AceConfig settings
	
	-- Locals that are required to update individual view elements
	local settings = TotalAP.Settings.GetReference()
	
	
	-- Anchor frame: Parent of all displays and buttons (used to toggle the entire addon, as well as move its displays)
	local AnchorFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_AnchorFrame")
	local AnchorFrame = AnchorFrameContainer:GetFrameObject()
	do -- AnchorFrame
	
		-- Layout and visuals
		AnchorFrame:SetFrameStrata("BACKGROUND")
		AnchorFrameContainer:SetBackdropColour("#D0D0D0")
		AnchorFrameContainer:SetBackdropAlpha(0)
		AnchorFrame:SetSize(maxButtonSize + hSpace + barWidth + hSpace + specIconSize + 2 * specIconBorderWidth + hSpace + specIconTextWidth, barHeight + vSpace + maxButtonSize + vSpace + sliderHeight) -- TODO: Update dynamically (script handlers?) to account for variable number of specs
		
		-- Player interaction
		AnchorFrame:SetMovable(true) 
		AnchorFrame:EnableMouse(true)
		AnchorFrame:RegisterForDrag("LeftButton")
		
		AnchorFrameContainer.Update = function(self)
		
			hideFrame = false
			-- Hide when:
			hideFrame = (hideFrame
			or UnitLevel("player") < 98 -- Player is too low level for Legion content (Artifact Quest)
			or not settings.enabled -- Display as a whole is being manually hidden (regardless of individual component's visibility)
			or settings.hideInCombat and TotalAP.EventHandlers.states.isPlayerEngagedInCombat -- Player is engaged in combat
			or TotalAP.EventHandlers.states.isPlayerUsingVehicle -- Player is using a vehicle
			or TotalAP.EventHandlers.states.isPetBattleInProgress -- Player is participating in a pet battle
			or hasPlayerLostControl -- Player is using a Flight Master or stuck in film sequences, animations etc. 
			)
			
			self:SetEnabled(not hideFrame)
			
			if hideFrame then return end
		
		end
		
		-- Script handlers	
		AnchorFrame:SetScript("OnMouseDown", function(self) -- Show background if user pressed drag modifier to indicate the display can be dragged
			
			if IsAltKeyDown() then -- Make background visible
				
				AnchorFrameContainer:SetBackdropAlpha(0.5)
				AnchorFrameContainer:Render()
				
			end
		
		end)
		
		AnchorFrame:SetScript("OnMouseUp", function(self) -- Hide background

			AnchorFrameContainer:SetBackdropAlpha(0)
			AnchorFrameContainer:Render()
		
		end)
		
		AnchorFrame:SetScript("OnDragStart", function(self) -- Dragging moves the entire display (ALT + Click)
			
			if self:IsMovable() and IsAltKeyDown() then -- Move display
				self:StartMoving()

				AnchorFrameContainer:SetBackdropAlpha(0.5) -- TODO: Make transparent while moving, invisible afterwards (so users can see the edges)
				AnchorFrameContainer:Render()
				
			end
			
			self.isMoving = true
		
		end)
		
		AnchorFrame:SetScript("OnDragStop", function(self) -- Stopping to drag leaves the display at its new location
			
			self:StopMovingOrSizing()
			self.isMoving = false
			
			AnchorFrameContainer:SetBackdropAlpha(0)
			AnchorFrameContainer:Render()
			
		end)
		
	end
	
	-- Event state icons: Indicate state of events that affect the ability to use AP items (TODO: Settings to show/hide and style these)
	local CombatStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_CombatStateIcon", "_DefaultView_AnchorFrame")
	local CombatStateIcon = CombatStateIconContainer:GetFrameObject()
	do -- CombatStateIcon
		
		-- Layout and visuals
		CombatStateIconContainer:SetRelativePosition(0, 0)
		CombatStateIconContainer:SetBackdropColour("#EC3413")
		
		CombatStateIcon:SetSize(stateIconWidth, stateIconHeight)
		
		-- Player interaction
		CombatStateIconContainer.Update = function(self)
		
			if TotalAP.eventStates.isPlayerEngagedInCombat then -- Indicate combat is currently in progress
				
				self:SetBackdropAlpha(1)
			
			else
			
				self:SetBackdropAlpha(0.25)
			
			end
		
		end
		
	end
	
	local PetBattleStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_PetBattleStateIcon", "_DefaultView_AnchorFrame")
	local PetBattleStateIcon = PetBattleStateIconContainer:GetFrameObject()
	do -- PetBattleStateIcon
		
		-- Layout and visuals
		PetBattleStateIconContainer:SetRelativePosition(stateIconWidth + vSpace, 0)
		PetBattleStateIconContainer:SetBackdropColour("#F05238")
		
		PetBattleStateIcon:SetSize(stateIconWidth, stateIconHeight)
		
	end
	
	local VehicleStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_VehicleStateIcon", "_DefaultView_AnchorFrame")
	local VehicleStateIcon = VehicleStateIconContainer:GetFrameObject()
	do -- VehicleStateIcon
		
		-- Layout and visuals
		VehicleStateIconContainer:SetRelativePosition(2 * (stateIconWidth + vSpace), 0)
		VehicleStateIconContainer:SetBackdropColour("#F3725D")
		
		VehicleStateIcon:SetSize(stateIconWidth, stateIconHeight)
		
	end
	
	local PlayerControlStateIconContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_PlayerControlStateIcon", "_DefaultView_AnchorFrame")
	local PlayerControlStateIcon = PlayerControlStateIconContainer:GetFrameObject()
	do -- PlayerControlStateIcon
	
		-- Layout and visuals
		PlayerControlStateIconContainer:SetRelativePosition(3 * (stateIconWidth + vSpace), 0)
		PlayerControlStateIconContainer:SetBackdropColour("#F69282")
		
		PlayerControlStateIcon:SetSize(stateIconWidth, stateIconHeight)
	
	end
	
	local UnderlightAnglerFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_UnderlightAnglerFrame", "_DefaultView_AnchorFrame")
	local UnderlightAnglerFrame = UnderlightAnglerFrameContainer:GetFrameObject()
	do -- UnderlightAnglerFrame
	
		-- Layout and visuals
		UnderlightAnglerFrameContainer:SetBackdropColour("#9CCCF8")
		UnderlightAnglerFrameContainer:SetRelativePosition(barInset + 4 * (stateIconWidth + vSpace), -barInset)
		
		UnderlightAnglerFrame:SetSize(barWidth, barHeight)
		
	end
	
	local ActionButtonFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_ActionButtonFrameContainer", "_DefaultView_AnchorFrame")
	local ActionButtonFrame = ActionButtonFrameContainer:GetFrameObject()
	do -- ActionButtonFrame
	
		-- Layout and visuals
		ActionButtonFrameContainer:SetBackdropColour("#123456")
		ActionButtonFrameContainer:SetBackdropAlpha(0)
		ActionButtonFrameContainer:SetRelativePosition(0, - ( barHeight + barInset + hSpace ))
		
		ActionButtonFrame:SetSize(maxButtonSize, maxButtonSize)
		
	end
	
	local ActionButtonContainer = TotalAP.GUI.ItemUseButton:CreateNew("_DefaultView_ActionButton", "_DefaultView_ActionButtonFrameContainer")
	local ActionButton = ActionButtonContainer:GetFrameObject()
	do -- ActionButton
		
		-- Layout and visuals
		ActionButton:SetSize(defaultButtonSize, defaultButtonSize)
		ActionButton:SetMinResize(minButtonSize, minButtonSize) -- Let's not go there and make it TINY, shall we?
		ActionButton:SetMaxResize(maxButtonSize, maxButtonSize) -- ... but no one likes a stretched, giant button either)
		
		-- Player interaction
		ActionButton:EnableMouse(true) -- for resizing and dragging the display
		ActionButton:SetMovable(true) -- for dragging the AnchorFrame
		ActionButton:SetResizable(true)
		ActionButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		ActionButton:RegisterForDrag("LeftButton") -- left button = resize or reposition
		
		ActionButtonContainer.Update = function(self)
		
			local spec = GetSpecialization()
			local fqcn = TotalAP.Utils.GetFQCN() -- TODO: DRY -> use higher scope?
		
			local hideButton = false
			
			-- Hide when:
			hideButton = (hideButton
			or not settings.actionButton.enabled -- Button is disabled via settings
			or not (TotalAP.inventoryCache.numItems > 0)  -- No AP items (or Research Tomes) in inventory
			or not TotalAP.inventoryCache.displayItem.ID -- No item set to button (usually happens on load only)
			or (TotalAP.artifactCache[fqcn][spec] and TotalAP.artifactCache[fqcn][spec]["isIgnored"]) -- Current spec is being ignored
			or (TotalAP.artifactCache[fqcn][spec] and TotalAP.artifactCache[fqcn][spec]["artifactTier"] == "1" and TotalAP.artifactCache[fqcn][spec]["numTraitsPurchased"] == 54) -- Artifact weapon is maxed (54 traits and tier 1)
			or not TotalAP.ArtifactInterface.HasCorrectSpecArtifactEquipped() -- Current weapon is not the correct artifact, which means AP can't be used anyway
			-- TODO: Underlight Angler -> Show when fish is in inventory
			) and not TotalAP.inventoryCache.foundTome -- BUT: Don't hide if Research Tome exists, regardless of the other conditions being met 
			
			self:SetEnabled(not hideButton)
			if hideButton then return end -- Update is finished, as ActionButton won't be shown
	
			
			local flashButton = false
			
			-- Flash when:
			flashButton = (flashButton
			or TotalAP.ArtifactInterface.GetNumAvailableTraits() > 0	-- Current spec has at least one available trait
			or (TotalAP.inventoryCache.foundTome and TotalAP.DB.IsResearchTome(TotalAP.inventoryCache.displayItem.ID))  -- Current item is Research Tome that can be used (level 110, not maxed AK depending on item (TODO)?)
			) and settings.actionButton.showGlowEffect -- BUT: Only flash if glow effect is enabled for the action button

			-- Set current item to button
			ActionButton.icon:SetTexture(TotalAP.inventoryCache.displayItem.texture)
			local itemName = GetItemInfo(TotalAP.inventoryCache.displayItem.link) or ""
			if itemName ~= "" then -- Item is cached and can be used (this can fail upon logging in, in which case the item must be set with the next update instead)
			
				ActionButton:SetAttribute("type", "item")
				ActionButton:SetAttribute("item", itemName)
			end
			
			-- Transfer cooldown animation to the button (would otherwise remain static when items are used, which feels artificial)
			local start, duration, enabled = GetItemCooldown(TotalAP.inventoryCache.displayItem.ID)
			if duration > 0 then -- Has visible cooldown that should be displayed on the button (mirroring the item itself if observed in the player's inventory)
					ActionButton.cooldown:SetCooldown(start, duration)
			end
			
			-- Display tooltip when mouse hovers over the action button
			if ActionButton:IsMouseOver() then 
				GameTooltip:SetHyperlink(TotalAP.inventoryCache.displayItem.link)
			end
			
			
			-- Masque Update (TODO)
		
			if not InCombatLockdown() then -- Flash action button (TODO: Un-taint this if necessary after GUI rework by copying the code)
				
				-- TODO: Check for persisting taint issues
			
				if flashButton and not self.isMoving then -- Re-flash to show glow effect properly if button's size changed (and it isn't currently being resized) -- TODO: Maybe this should be done while rendering instead
					
					self:ToggleFlashing()
					
				end
				
				self:SetFlashing(flashButton)
				
			end
			
			-- Resize and reposition
			local w, h = ActionButton:GetWidth(), ActionButton:GetHeight()
			if w > h then ActionButton:SetWidth(h) else ActionButton:SetHeight(w) end -- Keep aspect ratio square (1:1)
			
			local dx, dy = (ActionButtonFrame:GetWidth() - ActionButton:GetWidth()) / 2, (ActionButtonFrame:GetHeight() - ActionButton:GetHeight()) / 2 -- deltas to reposition button in the centre of the surrounding ActionButtonFrame
			ActionButtonContainer:SetRelativePosition(max(0, dx), - dy)

		end
		
		-- Script handlers
		ActionButton:SetScript("OnMouseDown", function(self) -- Show background if user pressed drag modifier to indicate the display can be dragged
			
			if IsAltKeyDown() then -- Make background visible
				
				AnchorFrameContainer:SetBackdropAlpha(0.5)
				AnchorFrameContainer:Render()
				
			end
			
			if IsShiftKeyDown() then -- Make ActionButton background visible
		
				ActionButtonFrameContainer:SetBackdropAlpha(0.5)
				ActionButtonFrameContainer:Render()
		
			end
		
		end)
		
		ActionButton:SetScript("OnMouseUp", function(self) -- Hide background

			ActionButtonFrameContainer:SetBackdropAlpha(0)
			ActionButtonFrameContainer:Render()
			
		end)
		
		ActionButton:SetScript("OnEnter", function(self)  -- (to show the tooltip on mouseover)
		
			if TotalAP.inventoryCache.displayItem.ID then -- An item is assigned to the button and can be displayed in the tooltip
			
				GameTooltip:SetOwner(ActionButton, "ANCHOR_RIGHT");
				GameTooltip:SetHyperlink(TotalAP.inventoryCache.displayItem.link)
				
			end
			
		end)
		
		ActionButton:SetScript("OnLeave", function(self)  -- (to hide the tooltip afterwards)
		
			GameTooltip:Hide()
			
		end)
			
		ActionButton:SetScript("OnHide", function(self) -- (to clear the set item when hiding the button)
			
			self:SetAttribute("type", nil)
			self:SetAttribute("item", nil)
			
		end)
	
		ActionButton:SetScript("OnDragStart", function(self) -- (to allow dragging the button, and also to resize it)
		
			if self:IsMovable() and IsAltKeyDown() then -- Alt -> Move display
			
				AnchorFrame.isMoving = true
				AnchorFrame:StartMoving() 
		
			elseif self:IsResizable() and IsShiftKeyDown() then -- Shift -> Resize button
			
				self:StartSizing()
				
				-- Show background frame (max size) while dragging
				ActionButtonFrameContainer:SetBackdropAlpha(0.5)
				ActionButtonFrameContainer:Render()
				
			end
				
			self.isMoving = true
	
		end)
		
		ActionButton:SetScript("OnUpdate", function(self) -- (to update the button skin and proportions while being resized)
			
			if self.isMoving then -- Update graphics to make sure the border/glow effect etc. is re-applied correctly (especially when resizing)
				
		
				ActionButtonContainer:Update()
				ActionButtonContainer:Render()
				
			end
		end)
		
		ActionButton:SetScript("OnDragStop", function(self) -- (to update the button skin and stop it from being moved after dragging has ended)

			self:StopMovingOrSizing()
			AnchorFrame:StopMovingOrSizing()
			AnchorFrame.isMoving = false
			self.isMoving = false
			
			-- Hide background frame once more
			ActionButtonFrameContainer:SetBackdropAlpha(0)
			ActionButtonFrameContainer:Render()
			
			AnchorFrameContainer:SetBackdropAlpha(0)
			AnchorFrameContainer:Render()
			
			ActionButtonContainer:Update()
			ActionButtonContainer:Render()
				
		end)

		
	end
	
	local ActionButtonTextContainer = TotalAP.GUI.TextDisplay:CreateNew("_DefaultView_ActionButtonText", "_DefaultView_ActionButtonFrameContainer", buttonTextTemplate)
	local ActionButtonText = ActionButtonTextContainer:GetFrameObject()
	do -- ActionButtonTextContainer
	
		-- Layout and visuals
		ActionButtonTextContainer:SetAnchorPoint("TOPLEFT")
		ActionButtonTextContainer:SetTargetAnchorPoint("BOTTOMLEFT")
		ActionButtonTextContainer:SetTextAlignment("center")
		ActionButtonTextContainer.Update = function(self) -- TODO: More options to change the displayed text format - planned once advanced config is implemented via AceConfig
		
			local offset = max(hSpace, (maxButtonSize - ActionButton:GetHeight()) / 2 - hSpace) -- Keep at least hSpace pixels between the two elements
			ActionButtonTextContainer:SetRelativePosition(0, - hSpace + offset)
		
			local text = ""
			
			if settings.actionButton.showText and not TotalAP.inventoryCache.foundTome and TotalAP.inventoryCache.numItems > 0 then -- Display current item's AP value as text (if enabled)

				if TotalAP.inventoryCache.numItems > 1 then -- Display total AP in bags
			
					if settings.scanBank and TotalAP.bankCache.numItems > 0 and TotalAP.bankCache.inBankAP > 0 then -- Also include banked AP
				
						text = TotalAP.Utils.FormatShort(TotalAP.inventoryCache.displayItem.artifactPowerValue, true, settings.numberFormat) .. "\n(" .. TotalAP.Utils.FormatShort(TotalAP.inventoryCache.inBagsAP, true, settings.numberFormat) .. ")\n[" .. TotalAP.Utils.FormatShort(TotalAP.bankCache.inBankAP, true, settings.numberFormat) .. "]" -- e.g., 75m\n(300m)\n[25m] = display current, inBags, and banked AP
						
					else -- Only display current item and inventory AP
			
						text = TotalAP.Utils.FormatShort(TotalAP.inventoryCache.displayItem.artifactPowerValue, true, settings.numberFormat) .. "\n(" .. TotalAP.Utils.FormatShort(TotalAP.inventoryCache.inBagsAP, true, settings.numberFormat) .. ")" -- e.g., 75m\n(300m)
					 
					 end
					 
				else -- Only display the current item's AP, as well as banked AP if it was saved (i.e., omit inventory AP) - TODO: This seems messy, and should likely be reworked to be more straight-forward / remove duplicate code
		
					if settings.scanBank and TotalAP.bankCache.numItems > 0 and TotalAP.bankCache.inBankAP > 0 then -- Also include banked AP
						
						text = TotalAP.Utils.FormatShort(TotalAP.inventoryCache.displayItem.artifactPowerValue, true, settings.numberFormat) .. ")\n[" .. TotalAP.Utils.FormatShort(TotalAP.bankCache.inBankAP, true, settings.numberFormat) .. "]"
					
					else
					
						text = TotalAP.Utils.FormatShort(TotalAP.inventoryCache.displayItem.artifactPowerValue, true, settings.numberFormat)
						
					end
					
				end
					
			end
			
			self:SetText(text)
			
		end
		
		-- Script handlers
		ActionButton:HookScript("OnDragStop", function(self) -- Required to reposition the button text while the button is being dragged
		
			ActionButtonTextContainer:Update()
			ActionButtonTextContainer:Render()
		
		end)
		
	end
	
	local SpecIcon1FrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_SpecIcon1Container", "_DefaultView_AnchorFrame")
	local SpecIcon1Frame = SpecIcon1FrameContainer:GetFrameObject()
	local SpecIcon2FrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_SpecIcon2Container", "_DefaultView_AnchorFrame")
	local SpecIcon2Frame = SpecIcon2FrameContainer:GetFrameObject()
	local SpecIcon3FrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_SpecIcon3Container", "_DefaultView_AnchorFrame")
	local SpecIcon3Frame = SpecIcon3FrameContainer:GetFrameObject()
	local SpecIcon4FrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_SpecIcon4Container", "_DefaultView_AnchorFrame")
	local SpecIcon4Frame = SpecIcon4FrameContainer:GetFrameObject()
	do -- SpecIconFrames
	
		-- Layout and visuals
		SpecIcon1FrameContainer:SetBackdropColour("#654321")
		SpecIcon2FrameContainer:SetBackdropColour("#654321")
		SpecIcon3FrameContainer:SetBackdropColour("#654321")
		SpecIcon4FrameContainer:SetBackdropColour("#654321")
		SpecIcon1FrameContainer:SetRelativePosition(maxButtonSize + vSpace + barWidth + vSpace, - ( barHeight + barInset + hSpace + 0 * (specIconSize + specIconBorderWidth + hSpace)))
		SpecIcon2FrameContainer:SetRelativePosition(maxButtonSize + vSpace + barWidth + vSpace, - ( barHeight + barInset + hSpace + 1 * (specIconSize + specIconBorderWidth + hSpace)))
		SpecIcon3FrameContainer:SetRelativePosition(maxButtonSize + vSpace + barWidth + vSpace, - ( barHeight + barInset + hSpace + 2 * (specIconSize + specIconBorderWidth + hSpace)))
		SpecIcon4FrameContainer:SetRelativePosition(maxButtonSize + vSpace + barWidth + vSpace, - ( barHeight + barInset + hSpace + 3 * (specIconSize + specIconBorderWidth + hSpace)))
		SpecIcon1Frame:SetSize(specIconSize + 2 * specIconBorderWidth, specIconSize + 2 * specIconBorderWidth)
		SpecIcon2Frame:SetSize(specIconSize + 2 * specIconBorderWidth, specIconSize + 2 * specIconBorderWidth)
		SpecIcon3Frame:SetSize(specIconSize + 2 * specIconBorderWidth, specIconSize + 2 * specIconBorderWidth)
		SpecIcon4Frame:SetSize(specIconSize + 2 * specIconBorderWidth, specIconSize + 2 * specIconBorderWidth)
		
		-- Player interaction
		SpecIcon1FrameContainer:SetAssignedSpec(1)
		SpecIcon2FrameContainer:SetAssignedSpec(2)
		SpecIcon3FrameContainer:SetAssignedSpec(3)
		SpecIcon4FrameContainer:SetAssignedSpec(4)
		
	end
	
	local SpecIcon1Container = TotalAP.GUI.SpecIcon:CreateNew("_DefaultView_SpecIcon1", "_DefaultView_SpecIcon1Container")
	local SpecIcon1 = SpecIcon1Container:GetFrameObject()
	local SpecIcon2Container = TotalAP.GUI.SpecIcon:CreateNew("_DefaultView_SpecIcon2", "_DefaultView_SpecIcon2Container")
	local SpecIcon2 = SpecIcon2Container:GetFrameObject()
	local SpecIcon3Container = TotalAP.GUI.SpecIcon:CreateNew("_DefaultView_SpecIcon3", "_DefaultView_SpecIcon3Container")
	local SpecIcon3 = SpecIcon3Container:GetFrameObject()
	local SpecIcon4Container = TotalAP.GUI.SpecIcon:CreateNew("_DefaultView_SpecIcon4", "_DefaultView_SpecIcon4Container")
	local SpecIcon4 = SpecIcon4Container:GetFrameObject()
	do -- SpecIcons
		
		-- Layout and visuals
		SpecIcon1Container:SetRelativePosition(specIconBorderWidth, -specIconBorderWidth)
		SpecIcon2Container:SetRelativePosition(specIconBorderWidth, -specIconBorderWidth)
		SpecIcon3Container:SetRelativePosition(specIconBorderWidth, -specIconBorderWidth)
		SpecIcon4Container:SetRelativePosition(specIconBorderWidth, -specIconBorderWidth)
		SpecIcon1:SetSize(specIconSize, specIconSize)
		SpecIcon2:SetSize(specIconSize, specIconSize)
		SpecIcon3:SetSize(specIconSize, specIconSize)
		SpecIcon4:SetSize(specIconSize, specIconSize)
		
		-- Player interaction
		SpecIcon1Container:SetAssignedSpec(1)
		SpecIcon2Container:SetAssignedSpec(2)
		SpecIcon3Container:SetAssignedSpec(3)
		SpecIcon4Container:SetAssignedSpec(4)
		
		-- Script handlers
		
	end
	
	local SpecIcon1TextContainer = TotalAP.GUI.TextDisplay:CreateNew("_DefaultView_SpecIcon1Text", "_DefaultView_SpecIcon1Container", specIconTextTemplate)
	local SpecIcon1Text = SpecIcon1TextContainer:GetFrameObject()
	local SpecIcon2TextContainer = TotalAP.GUI.TextDisplay:CreateNew("_DefaultView_SpecIcon2Text", "_DefaultView_SpecIcon2Container", specIconTextTemplate)
	local SpecIcon2Text = SpecIcon2TextContainer:GetFrameObject()
	local SpecIcon3TextContainer = TotalAP.GUI.TextDisplay:CreateNew("_DefaultView_SpecIcon3Text", "_DefaultView_SpecIcon3Container", specIconTextTemplate)
	local SpecIcon3Text = SpecIcon3TextContainer:GetFrameObject()
	local SpecIcon4TextContainer = TotalAP.GUI.TextDisplay:CreateNew("_DefaultView_SpecIcon4Text", "_DefaultView_SpecIcon4Container", specIconTextTemplate)
	local SpecIcon4Text = SpecIcon4TextContainer:GetFrameObject()
	do -- SpecIconsText
	
		-- Layout and visuals
		SpecIcon1TextContainer:SetRelativePosition(vSpace, -(SpecIcon1Frame:GetHeight() - SpecIcon1Text:GetHeight()) / 2)
		SpecIcon1TextContainer:SetAnchorPoint("TOPLEFT")
		SpecIcon1TextContainer:SetTargetAnchorPoint("TOPRIGHT")
		SpecIcon1TextContainer:SetVerticalAlignment("center")
		
		SpecIcon2TextContainer:SetRelativePosition(vSpace, -(SpecIcon2Frame:GetHeight() - SpecIcon2Text:GetHeight()) / 2)
		SpecIcon2TextContainer:SetAnchorPoint("TOPLEFT")
		SpecIcon2TextContainer:SetTargetAnchorPoint("TOPRIGHT")
		SpecIcon2TextContainer:SetVerticalAlignment("center")
		
		SpecIcon3TextContainer:SetRelativePosition(vSpace, -(SpecIcon3Frame:GetHeight() - SpecIcon3Text:GetHeight()) / 2)
		SpecIcon3TextContainer:SetAnchorPoint("TOPLEFT")
		SpecIcon3TextContainer:SetTargetAnchorPoint("TOPRIGHT")
		SpecIcon3TextContainer:SetVerticalAlignment("center")
		
		SpecIcon4TextContainer:SetRelativePosition(vSpace, -(SpecIcon4Frame:GetHeight() - SpecIcon4Text:GetHeight()) / 2)
		SpecIcon4TextContainer:SetAnchorPoint("TOPLEFT")
		SpecIcon4TextContainer:SetTargetAnchorPoint("TOPRIGHT")
		SpecIcon4TextContainer:SetVerticalAlignment("center")
		
	end
	
	
	local ProgressBarsFrameContainer = TotalAP.GUI.BackgroundFrame:CreateNew("_DefaultView_ProgressBarsFrame", "_DefaultView_AnchorFrame")
	local ProgressBarsFrame = ProgressBarsFrameContainer:GetFrameObject()
	 
	do -- ProgressBarsFrame
	 
		-- Layout and visuals
		ProgressBarsFrameContainer:SetBackdropColour("#000000")
		ProgressBarsFrameContainer:SetRelativePosition(maxButtonSize + vSpace, - ( barHeight + barInset + hSpace))
		ProgressBarsFrame:SetSize(barWidth, 4 * (barHeight + hSpace))
		
	 end
	
	local ProgressBar1Container = TotalAP.GUI.ProgressBar:CreateNew("_DefaultView_ProgressBar1", "_DefaultView_ProgressBarsFrame")
	local ProgressBar1 = ProgressBar1Container:GetFrameObject()
	local ProgressBar2Container = TotalAP.GUI.ProgressBar:CreateNew("_DefaultView_ProgressBar2", "_DefaultView_ProgressBarsFrame")
	local ProgressBar2 = ProgressBar2Container:GetFrameObject()
	local ProgressBar3Container = TotalAP.GUI.ProgressBar:CreateNew("_DefaultView_ProgressBar3", "_DefaultView_ProgressBarsFrame")
	local ProgressBar3 = ProgressBar3Container:GetFrameObject()
	local ProgressBar4Container = TotalAP.GUI.ProgressBar:CreateNew("_DefaultView_ProgressBar4", "_DefaultView_ProgressBarsFrame")
	local ProgressBar4 = ProgressBar4Container:GetFrameObject()
	
	do -- ProgressBars
	
		-- Layout and visuals
		ProgressBar1Container:SetRelativePosition(barInset, - barInset - 0 * (barHeight + hSpace))
		ProgressBar2Container:SetRelativePosition(barInset, - barInset - 1 * (barHeight + hSpace))
		ProgressBar3Container:SetRelativePosition(barInset, - barInset - 2 * (barHeight + hSpace))
		ProgressBar4Container:SetRelativePosition(barInset, - barInset - 3 * (barHeight + hSpace))
		
		-- Player interaction
		ProgressBar1Container:SetAssignedSpec(1)
		ProgressBar2Container:SetAssignedSpec(2)
		ProgressBar3Container:SetAssignedSpec(3)
		ProgressBar4Container:SetAssignedSpec(4)

	end
	
	ViewObject.elementsList = { 	-- This is the actual view, which consists of individual DisplayFrame objects and their properties
	
		AnchorFrameContainer,
		CombatStateIconContainer,
		PetBattleStateIconContainer,
		VehicleStateIconContainer,
		PlayerControlStateIconContainer,
		UnderlightAnglerFrameContainer,
		ActionButtonFrameContainer,
		ActionButtonContainer,
		ActionButtonTextContainer,
		ProgressBarsFrameContainer,
		ProgressBar1Container,
		ProgressBar2Container,
		ProgressBar3Container,
		ProgressBar4Container,
		SpecIcon1FrameContainer,
		SpecIcon1Container,
		SpecIcon2FrameContainer,
		SpecIcon2Container,
		SpecIcon3FrameContainer,
		SpecIcon3Container,
		SpecIcon4FrameContainer,
		SpecIcon4Container,
		SpecIcon1TextContainer,
		SpecIcon2TextContainer,
		SpecIcon3TextContainer,
		SpecIcon4TextContainer,
	}
	
	return ViewObject
	
end

DefaultView.CreateNew = CreateNew

TotalAP.GUI.DefaultView = DefaultView

return DefaultView