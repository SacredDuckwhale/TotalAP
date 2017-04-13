-- [[ NEW FEATURES: Likely have to wait until a new version is being worked on (so as to not mess with things too much that have already been tested & found stable) ]] --
	Popup OR frame displaying notes on how to use the addon, /commands, what's new, etc + option to disable
	Custom display strings: format/filter strings to display AP info for spec: {progressPercent} - {numTraits} {knowledgeLevel} - etc.? 
	Add GUI to configure settings (rather than just slash commands
	Notify when RESEARCH_ARTIFACT_HISTORY_READY event fired = new AK levels are available. While it doesn't help with the items already obtained, it might prevent the player from farming more AP without utilizing the new AK level (add "!" icon or sth?)
	
	
-- [[ EXTENSION: Existing features that can likely be extended without requiring too much testing ]] --
	Allow changing of specs via keybind (rotating as opposed to picking numbers, as they aren't available (2/4 spec classes...) before logging in?) : 1 -> 2 -> 3 (-> 4) -> 1 (etc)
	Allow drag & drop of button to action bar -> create macro? (use any AP items) or keybind
	/ap <translation> and not just the English text
	Use function for more natural translation where variables are embedded (does that work with curseforge?)
	Maybe change non-Masque/default style to look somewhat better?) Hide border or something?
	Tooltip: Add percentage of single AP items ? (like, +5% for this item, total 55% = 60% if you use / obtain it?)
	Add percentage as text outside (above) the button, with an option to disable and perhaps style? Also add offspec info, AP bar, AK research indicator. AP distribution (artifact, bags, total?). Keybinds to change spec?
	Profiles/global vs char settings so positio/size can be changed for all characters
	Global settings for position and size	-> 	Have addon manage actionButtonSize, position, etc instead of WOW's layout cache (as the settings will be lost if the user logs in without the addon enabled)
	Shift-RightClick should toggle the glow effect? -> Add more modifiers and actions:  alt/shift/ctrl modifiers, keybindings? ALT-LeftClick => resize, ALT-RightClick => lock/unlock, SHIFT/RightClick => Settings / display help?
	Verbose setting isn't implemented. It really should (e.g., when the glow effect is toggled via Shift-Rightclick)
	Add number of usable AP items (alternatively, number of the SAME item) to the bottom-right or something? (compare to New Openables - perhaps as an option)
	Have the button show only for certain spec or specs (via settings -> ignore spec X, prioritise spec Y?) -> Display progress and level up notifications for offspec (ALL specs, or selected, via options/slash command)
	Add tooltip text to indicate the button can be moved and resized, plus an option to enable/disable
	Allow user to resize the spec icon?
		
		
-- [[ DEVELOPMENT: Debugging/optimisation features that aren't important to the user, but may make it easier to develop the addon further ]] --
	Add debug levels, so only specific features can be debugged: E.g., 1 = button, 2 = infoframe, 3 = specicons, etc... (ascending for each new version) -> bitmask, so 1, 2 and 3 could be debugged automatically (0x1110 etc)
		Split into modules: TotalAP_Banked, TotalAP_UnderlightAngler, TotalAP?


	