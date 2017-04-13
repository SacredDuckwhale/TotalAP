133755 ULA
221474 Throw Back

-- [[ TESTING: Fixes or features that require further testing]] --
		When changing specs, but no artifact is available (red font) , it will use this invalid artifact for all calculations
		when changing specs, but not having the new artifact available (=old one equipped, but red), infoframe and specicons don't update initially, on mouseover they do but only to the equipped artifact's (wrong spec) data!
		-- when changing specs to one without an artifact (in inventory/able to be auto-equipped), the old artifact remains equipped (but red/greyed out) -> button continues to show -> AP will be used for weapon regardless. working as intended?
	L98 -> 100 shows only bars (should show nothing)
		When in a vehicle but leaving combat, the panel is shown (should be hidden?) = bombardment quests etc.
		Billions of AP will break the scanning unless localised properly in Utils\Format.lua (only works for deDE and enUS so far, as translations for "billion"/"million" are missing - and even those are untested for billions, since more AK levels would be required to reach those amounts => revisit later)

		
-- [[ BUGS: Fix this ASAP ]] --

if AK items exist, num is set to 1 (should be updated automatically later, but what about tooltip when hovering over AP items? Will it display "1 item in bag"?)
If /ap combat is enabled, it doesn't rescan in combat - change that?
If /ap combat is enabled, update on command
	When spam-using AP items on a never-used offspec with unspent AP (1.5mil) the buttons stop working, both spec icons and action button were affected? Right-clicking NOP button refreshed it and showed a different item when it started to work again (no error though)
Notice if AK items have been used ([!] in red -> Tooltip text: to indicate that display will be accurate until no more items are in the inventory -> hide once inBagsAP = 0)
change spec -> 21 levels on changing spec that is actually at 36 traits already. fixed itself by entering/leaving combat (cause: saved var cache is set to 0,0 ? only happens if respec immediately after logging in)
Being attacked while changing specs -> data updated to 0? (does this happen when /ap combat is involved, too?) updated properly after leaving combat
	Artifact Research notes being used while still snapshotted AP items are in inventory will mess up calculations (show warning popup/reset on all items used, as this problem is tricky due to spellids being used)
		AK Research Notes -> applies higher value, when in reality the items in the player's inventory are snapshotted (Ak always applied to spells, instead of at the time of obtaining the item)
		Workaround: Tooltip scanning (requires localisation!), or show at least a note indicating that the cached amount is inaccurate (and why)
	ULA fishing artifact screws up everything
		underlight angler replaces current artifact
		spell overlay effect lights up when fishing artifact can be leveled up, but in reality regular AP items can't be used on it
	When AP items are used, sometimes (when?) there is a split second where Ap in bags is subtracted, but unspentAP not updated yet -> jump in percentages
	GLow effect is triggered when in bags + unspent updates and is close to level up (98%?) most likely due to being over 100% temporarily
	AP Research Note in inventory -> Sets progress text to 1%?
	Game Tooltip:SetText error (LUA) on login? - > possibly unrelated to addon
	When research notes are in the player's inventory, percentage (spec icon text) is too low before getting too high (ignoring items, then adding AK instead of snapshotting?)
	Addon doesn't pick up "Crystalline Demonic Eye" (archaeology quest reward) (spell desc = artifact weapon, not artifact power- > is not filtered by script) -> Give AP as item effect desc instead of spell desc (wowhead has them)? isn't part of the itemEffects DB, yet it grants AP
	Sometimes a "black" artifact window opens when logging in -> is this actually caused by the addon?
	
-- [[ BEHAVIOUR: Working as intended. But maybe it wasn't thought through well enough ]] -- 
Rework tooltip text format to be consistent with the ingame format (1.3 million instead of 1.30m = int standard), for other locales as well - maybe an option (later) to toggle between those or other formats
Add option to "grey out" button instead of hiding (to provide visual continuity - simply display the last item used)
	Localise number formats for the tooltip output (uses EN format, but could easily be changed iin Util\Format)
	Locale tables with CONSTANTS instead of actual tex
	Add notes from TOC and /ap options text to localization files
	Verbose setting has no effect currently -> should prevent ChatMsg from being displayed?
	Display % of AP used/total/in bags as text on bars (optional ofc) -> details on mouseover/tooltip
	Keybinds for individual parts -> no /ap hide for all of them? Would come in handy
	Combat toggle "annoying" - hide during group content
	54 traits -> still shows percentage (might not be as important after 7.2)
	Allow using the "useItem" keybind while button is hidden. Right now it's kind of counterintuitive, HOWEVER the itemuse API is PROTECTED so items can't be used directly. Possible workaround: Make button invisible (hide texture only)?
	CheckBags only scans inventory (not bank. TODO? Obv. only if bank is open - items wouldn't be usable but they will count towards the progress at least)
		Scan Banks, in case people are storing AP before the next patch (class rebalancing occurs)
	Frame strata - button before flight map?
	Leftclick + Dragging will flash the button, even though the frame isn't draggable (minor inconsistency)	
	"Empty" frames will be shown on characters without an artifact weapon (< lv 98?)	
	Boon of the Hoarder (BOA) isn't being ignored. It should, shouldn't it?	
		Option to allow item to be used in combat/frame to be shown
	using items in combat (manually/NOP) will make the button unusable temporarily (same issue as WQ): fix -> rescan after combat ended
	Position resets if addon is re-enabled (due to being handled by the client) -> global/local profiles would fix this, but could cause issues similar to those in APU?
	if /ap combat is toggled while already in combat, it won't show/hide until the next update
	Bar display updates look "chopped" -> better animation would be great
	Instead of hiding it based on level, hiding based on whether or not an artifact is equipped or available maybe? (tricky, since it could theoretically be in the bank etc. after level 98)
	Fr number format (1 000 000,00) breaks the addon, or do they in fact use the EN number format (for AP items, anyway)? Test test test... RU format? etc
	
	License -> MIT to GPL?
	
	
-- [[ IMPROVEMENTS: Best practices, performance tweaks, optimisation, code review ]]--
	-- TODO: Better way to list all available commands, especially as functionality is extended (GUI?)
		TODO: Functions to extract AP amounts based on locale/AK levels (outsource, also)
		GetArtifactPowerFromItem(itemID)
		GetSpellDescriptionFromItem(itemID)
		or something?
	Add tooltip indicator if a spec artifact wasn't found while scanning ("click to change spec BUT artifact not found", implying caching won't work - if it is placed in the bank, for example)
	Add screenshots (with pointers/arrows) to CF description
	Display AK (as bar?) , possibly above the others? Optional ofc - AK: X/MAX (25/25 or 25/50 in 7.2)
	Display inBagsAP as short text below button?
	Tooltip over progress text: current artifact level?
	Add option to delete a spec's cached data (can be done manually via saved vars/LUA run commands)
	blacklist spec from cache, button etc.
	Add check if artifact is unavailable -> visual indicator (red/greyed out etc icons and bars?)
	Update notification as frame7popup A la Skada
	Lock spec / button manually to avoid accidentally spending AP on diminishing returns (35+ traits vs offspec)
	Display keybind as text on button (optional)
	SPec icons: Tooltip text to indicate whether spec artifact is available for equipping/caching (=in inventory, red/green font)
	"X AP in bags (Y item/Z % of current spec?)" - tooltip text
	Show mini bar on top of actual bar for next level even if the current one is 100%?
	Documentation of features (icons, clicks, dragging, tooltips etc)
	Bar display interaction (mouseover = show some info? maybe bank/bags/unspent percentages)
	Presets for display style infoFrameStyle = 0, default and others
	Replace fontString text displays with http://wowprogramming.com/docs/widgets/FontString/SetFormattedText (memory usage?)
	Verification of saved vars: needs to be tested (unit test), and so far I don't like all the manual if checks... (bad style)
	Modularisation before things get out of hand (already it has begun) -> MSV/UI-logic-data/svars
	GetArtifactProgressPercent() and GetNumAvailableTraits are somewhat identical, surely they can be merged to GetArtifactProgress() -> returns both values
	Code cleanup, refactoring, duplicate and obsolete code removal
	Use GitHub for commits, and curseforge/issues?
	- If all AP items are used, but level up is available, the tooltip will display it but there is no button to remind the user. Maybe grey out/make button unusable but keep the glow effect to draw attention to the fact they should visit the forge? (mouseover quest reward or OH mission reward, for example, will display "0 AP in bags - new trait available", which feels odd)
	Artifact Research Notes -> spell overlay if available (implemented already. But it requires more to avoid inaccurate values)
	-- Calculate the artifact progress towards the next trait (TODO: the next trait relatively, not just absolutely = one)
	Slash command list: Add tabs & formatting - like SavedInstances	
	TODO: Change Short function to be simpler and strip .0 from "15.0k" (example)
	 TODO: Combine GetItemNameFromLink into one extraction function with arg2 = extract what (and lib?)
	Option to only grey out/make unusable the button and not hide it entirely
	-- Add icon for equipped weapons (2x icons, size adjustable) to indicate the equipped/cached artifact?
	with multiple level ups show a separate bar (full for the first trait, partial for the current level up) insteadof just one full bar?
	option to display unspent AP or inBags only instead of unspent+inBags in fontString text?
	Add keybinds to switch specs?
	
-- [[ UNCONFIRMED: Test this and see if it can be reproduced / re-tested / may need some consideration ]] --
	The cooldown seems to lag a bit behind NewOpenables/inventory? Maybe update more frequently?
	When the glow effect was enabled and the button is hidden, then shown, it willl still flash briefly (until the next update). Perhaps flash control should be done BEFORE showing it (in UpdateActionButton)
	loginmsg not working? or is it? at least the command doesn't exist?
	If multiple traits are available when changing specs, does the numTraitsAvailable update correctly? I think so, as UpdateActionButton calls it every time the button is displayed
	Masque group descriptions (also: localised)
	Mouse over button & update = tooltip is hidden. Rather update it, but keep it visible?
	rethink positioning of elements when some are hidden
	Click/shift click and drag interaction with frames (hide? lock?)
	Hide button keybind -> hide anchor instead (no point in hiding the button?)
	test if using items works while the vendor screen is open (NO has that bug)
	function TotalAP:Toggle vs TotalAP.toggle - and does it work without declaring global in itemEffects? That part needs reviewing, too
	when all items are used up and the button is hidden, the inBagsAP bar is still shown (and in the wrong place, too)
	pet battle -> frame not updated/shown after leaving? (event detection - also not hidden when entering PB??)
	Frame Strata: specIcons overlay pet battle (but should be hidden, anyway)
	login -> frame visible, update -> it's gone, then change belt -> lua error (nil for unspentAP??)
	At 99% progresspercent, the button glows but a trait isn't available yet? (perhaps rounding error by blizz UI?)
	Background frame is redrawn on update -> flickering (partly solved. It still is shown when the rest is hidden temporarily, after using FM whistle?)
	when using AP items, the font String text decreases ?? (not updated progress count?)
	Possibly: After initial login/sometimes ?? the icon won't glow even though it should, until at some point it does (after updating)
	-- Font color might be hard to read? (white instead of artifact/grey)
	- Somehow the button became unusable (nothing happened, no item being used) after looting, but fixed itself after using one item manually. Possibly deactivated on accident? -< type and item = "<none>" even though the AP item was found & texture displayed - after being disabled during combat
		- Flash button when used? (without levelup being available)
		Recheck/rescan after ARTIFACT_XP_UPDATE (additionally to BAG_UPDATE_DELAYED so after using all items and gaining a new trait (but not learning it, the button will stop glowing until the next trait is available? If this is intended... For now, it will keep glowing as long as at least one trait is available) also after learning a trait!!
			use curse packager or other program/script to automate creating revisions and changelogs
	-- TODO: Only display tooltip info when the tooltip is from hovering over TotalAPButton (rather than ANY item/tooltip in the game)?
	-- TODO: Ignore Boon of the Companion (no AK benefit, use on alts instead since it's BOA)

	-- Colour coding for chat messages. TODO: Use predefined constants instead? But they don't look as pretty :( - colour constants built-in or as a lib?
local function GetColour(colour, msg)
	local hexTable = {
		["MSG_NORMAL"] = "FFFFFF",
		["MSG_PROGRESS"] = "CC5500",
		["MSG_NOTE"] = "ECEC0F",
		["MSG_CONFIRM"] = "20FF20",
		["MSG_DEBUG"] = "20FF20",
		["MSG_ERROR"] = "FF1A1A",
		["REPGAIN"] = "8179EB", -- test
		["ARTIFACT"] = "E6CC80", 
	}
	
	
	if hexTable[colour] and msg then return "|c00" .. hexTable[colour] .. msg;
	else return msg; -- Default chat colour
	end
end

	
-- function()
    -- local currentPower, pointsSpent = select(5, C_ArtifactUI.GetEquippedArtifactInfo())
    -- local powerNeeded = select(3, MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, currentPower))
    -- return format('%d%%', currentPower / powerNeeded * 100);
-- end
	-- -- TODO: config option to enable masque support (~bison)? Any disadvantage to simply enabling it by default? I doubt it...

-- TODO: Resize/reskin without masque looks odd because of the border texture if size is too small / too big
		-- TODO: Rename addon to something more fitting? TotalArtifactPower? TotalAP - Artifact Power Tracker? CC_ArtifactPower (lame)?
-- Initialise container frame (only called once after ADDON_LOAD fired)

-- Dummy function -> work in progress
-- TODO: Progress towards next trait: X% (X% without bags/already used)
-- TODO: Show percent of current Trait when multiple are available: "2 traits available + progress"

end
	-- TODO: show glow effect only if NEW trait is available (just once, after reaching the lvUp amount and then stop?) right now it glows when new trait is purchasable, but not when items in bag should be used. OR maybe make it a setting? glowWhenNewTrait vs glowWhenTraitAvailable (trigger vs state)

-- TODO: Keybind = can use AP items even if button is hidden. Also, slashCMD to hide via savedvars

-- TODO: Optimize order of functions for load order
	Button controls:
		Click: Use AP item
		Alt+Drag & Drop = Move button
		Shift + Drag/Drop = Resize button
		
	
	Button will be hidden if:
	- it is set to be hidden (via slash command)
	- no artifact weapon is equipped (the spell would fail anyway)
	- player is engaged in combat or pet battle
	- the current spec is set to be ignored (TODO)
	
Tooltip is faded out on BagUpdate -> Show again (with new values)
Recheck for glow effect after looting item, not NEXT item AFTER lv up has been reached

-- TODO: What do we need this DB for? itemEffects are separate, and settings is used for... settings. Maybe use it to track AP tokens obtained/used/at which AK level, etc? (future verson, new feature)
	if TotalArtifactPowerDB == nil then TotalArtifactPowerDB = {}; end -- Create empty DB table. TODO: Check savedVars for validity (type == ...) etc?
	db = TotalArtifactPowerDB;

Icon style via masque (spec icon)

- Debug/verbosity levels
- Select spec to use AP on, with option to ignore/override (for the session, entirely). Confirmation box to me sure, or an obvious visual warning in the tooltip/frame
- Hide button when entering vehicle

function()
    local currentPower, pointsSpent = select(5, C_ArtifactUI.GetEquippedArtifactInfo())
    local powerNeeded = select(3, MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, currentPower))
    return format('%d%%', currentPower / powerNeeded * 100);
end


-- Initialise container frame (only called once after ADDON_LOAD fired)
local function CreateContainerFrame()
	if not TotalAPFrame then -- Create new button, restore settings etc.
		
			-- Create container frame
			Debug("Button creation requested. Starting by creating the container frame (TotalAPFrame)...")
			
			TotalAPFrame = CreateFrame("Frame", "TotalAPFrame", UIParent);
			TotalAPFrame:SetFrameStrata("LOW");
			TotalAPFrame:SetClampedToScreen(true);
			TotalAPFrame:SetSize(200, 100); -- TODO: relative value or slashcmd/setting for this?
			TotalAPFrame:SetPoint("CENTER");
			TotalAPFrame:SetMovable(true);
			TotalAPFrame:EnableMouse(true)
			
		--TotalAPFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			TotalAPFrame:RegisterForDrag("LeftButton");
			TotalAPFrame:SetScript("OnDragStart", function(TotalAPFrame)
				Debug("TotalAPFrame is being dragged")
				if TotalAPFrame:IsMovable() then
					TotalAPFrame:StartMoving();
				end
				
				-- TODO: Resize if ALT is held while dragging
			end);
			
			-- Frame scripts (to make it interactive)
			TotalAPFrame:SetScript("OnReceiveDrag", function(TotalAPFrame)
				
				TotalAPFrame:StopMovingOrSizing()
				local point, relPoint, x, y = TotalAPFrame:GetPoint()
				Debug(format("TotalAPFrame received drag with coords %s %s %d %d", point, relPoint or "nil", x, y));
				TotalAPFrame:Hide()
			end)
			
			TotalAPFrame:SetScript("OnEnter", function(TotalAPFrame)
					Debug("OnEnter -> mouse entered TotalAPFrame area, ")
			--GameTooltip:SetOwner(TotalAPFrame, "ANCHOR_RIGHT")
			--GameTooltip:SetHyperlink(itemLink)
		end)
		
			TotalAPFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }});
												
			TotalAPFrame:SetBackdropColor(0, 0, 0, 30);
			TotalAPFrame:SetBackdropBorderColor(0, 0, 0, 0);
			TotalAPFrame:Show();
			
			
			-- TODO: Keybindings - toggle frame, ignore for spec, ignore for session, spec/session
			-- TODO: Frame info - AP progress bar, num traits, eqArtifact/spec
	end
end