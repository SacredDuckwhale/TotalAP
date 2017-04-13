-- [[ Artifact weapon list ]] --

-- LUT for each spec's artifact, so that it can be verified by the addon
-- Format: [classID] = { [specID] = { itemID, IsOffhandWeapon (meaning, slot = 17 instead of 16) } } 

-- Note that IsOffhandWeapon should be considered more like "CanOccupyOffhandSlot" or even "IsPrimaryArtifact" for some specs... it's not exclusive, at least not in all cases
-- The "false" entries could also be removed (and later checked for nil instead), but I don't like that as it leaves the DB somewhat incomplete
local artifactsByClass = {

	{ -- 1 	Warrior 	WARRIOR
		{ -- 1	Arms
			{ 128910, false }  -- Strom'kar, the Warbreaker 
		},
		
		{ -- 2	Fury
			{ 128908, true } , -- Odyn's Fury
			{ 134553, true } -- Helya's Wrath 
		},
		
		{ -- 3	Protection
			{ 128288, false }, --  Scaleshard
			{ 128289, true } -- Scale of the Earth-Warder 
		}
	},
	
	{ -- 2 	Paladin 	PALADIN
		{ -- 1	Holy
			{ 128823, false } -- The Silver Hand 
		},
		
		{ -- 2	Protection
			{ 128866, true }, -- Truthguard
			{ 128867, false } -- Oathseeker
		},
		
		{ -- 3	Retribution
			{ 120978, false } -- Ashbringer
		}
	},
	
	{ -- 3 	Hunter 	HUNTER
		{ -- 1	Beast Mastery
			{ 128861, false } -- Titanstrike
		},
		
		{ -- 2	Marksmanship
			{ 128826, false } -- Thas'dorah, Legacy of the Windrunners
		},
		
		{ -- 3	Survival
			{ 128808, false } -- Talonstrike
		}
	},
	
	{ -- 4 	Rogue 	ROGUE
		{ -- 1	Assassination
			{ 128870, false }, -- Anguish
			{ 128869, true } -- Sorrow
		},
		
		{ -- 2	Outlaw
			{ 128872, false }, -- Fate
			{ 134552, true } -- Fortune
		},
		
		{ -- 3	Subtletly
			{ 128476, false }, -- Gorefang
			{ 128479, true } -- Akaari's Will
		}
	},
	
	{ -- 5 	Priest 	PRIEST
		{ -- 1	Discipline
			{ 128868, false } -- Light's Wrath
		},
		
		{ -- 2	Holy
			{ 128825, false } -- T'uure, Beacon of the Naaru 
		},
		
		{ -- 3	Shadow
			{ 128827, false }, -- Xal'atath, Blade of the Black Empire 
			{ 133958, true } -- Secrets of the Void 
		}
	},
	
	{ -- 6 	Death Knight 	DEATHKNIGHT
		{ -- 1	Blood
			{128402, false } -- Maw of the Damned
		},
		
		{ -- 2	Frost
			{ 128292, false }, -- Frostreaper
			{ 128293, true } -- Icebringer
		},
		
		{ -- 3	Unholy
			{ 128403, false } -- Apocalypse
		}
	},
	
	{ -- 7 	Shaman 	SHAMAN
		{ -- 1	Elemental
			{ 128935, false }, -- The Fist of Ra-den
			{ 128936, true } -- The Highkeeper's Ward
		},
		
		{ -- 2	Enhancement
			{ 128819, false }, -- Doomhammer
			{ 128873, true } -- Fury of the Stonemother
		},
		
		{ -- 3	Restoration
			{ 128911, false }, -- Sharas'dal, Scepter of Tides 
			{ 128934, true } -- Shield of the Sea Queen 
		}
	},
	
	{ -- 8 	Mage 	MAGE
		{ -- 1	Arcane
			{ 127857, false } -- Aluneth
		},
		
		{ -- 2	Fire
			{ 128820, false }, -- Felo'melorn
			{ 133959, true } -- Heart of the Phoenix
		},
		
		{ -- 3	Frost
			{ 128862, false } -- Ebonchill
		}
	},
	
	{ -- 9 	Warlock 	WARLOCK
		{ -- 1	Affliction
			{ 128942, false } -- Ulthalesh, the Deadwind Harvester 
		},
		
		{ -- 2	Demonology
			{ 128943, true }, -- Skull of the Man'ari
			{ 137246, false } -- Spine of Thal'kiel 
		},
		
		{ -- 3	Destruction
			{ 128941, false } -- Scepter of Sargeras
		}
	},
	
	{ -- 10 	Monk 	MONK
		{ -- 1	Brewmaster
			{ 128938, false } -- Fu Zan, the Wanderer's Companion
		},
		
		{ -- 2	Mistweaver
			{ 128937, false } -- Sheilun, Staff of the Mists (
		},
		
		{ -- 3	Windwalker
			{ 128940, false }, -- Al'burq
			{ 133948, true } -- Alra'ed
		}
	},

	{ -- 11 	Druid 	DRUID
		{ -- 1	Balance
			{ 128858, false } -- Scythe of Elune
		},
		
		{ -- 2	Feral
			{ 128860, false }, -- Fangs of Ashamane (MH)
			{ 128859, true } -- Fangs of Ashamane (OH)
		},
		
		{ -- 3	Guardian
			{ 128821, false }, -- Claws of Ursoc (MH)
			{ 128822, true } -- Claws of Ursoc (OH)
		},
		
		{ -- 4	Restoration
			{ 128306, false } -- G'Hanir, the Mother Tree 
		}
	},
	
	{ -- 12 	Demon Hunter 	DEMONHUNTER
		{ -- 1	Havoc
			{ 127829, false }, -- Verus
			{ 127830, true } -- Muramas
		},
		
		{ -- 2	Vengeance
			{ 128832, false }, -- Aldrachi Warblades (MH)
			{ 128831, true } -- Aldrachi Warblades (OH)
		}
	},
};

-- Populate DB
TotalArtifactPowerDB["artifacts"] = artifactsByClass;

-- Use IDs with API_GetClassInfo(1 .. GetNumClass() ): classDisplayName, classTag, classID = GetClassInfo(index)
-- Class ID 	Class Name 	englishClass
-- By accessing artifactsByClass(classID), only the relevant artifacts are returned, which can then be checked against the active spec's ID (1 = first entry, etc.)
-- Important: Since some specs have two different artifacts (and Fury warriors, for example, can wield them in either main- OR offhand), ALL entries should be checked -> one would have IsOffhandWeapon = true, the other = false

