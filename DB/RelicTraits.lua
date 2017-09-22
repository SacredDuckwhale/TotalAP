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


local traitsByClass = {

	{ -- 1 	Warrior 	WARRIOR
		{ -- 1	Arms
			 216274, -- Many Will Fall (with Fervor of Battle taken)
			 209492, -- Precise Strikes
			 209494, -- Exploit the Weakness
		},
		
		{ -- 2	Fury
			200860, -- Unrivaled Strength
			200849, -- Wrath and Fury
			200861, -- Raging Berserker
		},
		
		{ -- 3	Protection
			238077, -- Bastion of the Aspects
			188635, -- Vrykul Shield Training
			203225, -- Dragon Skin
		}
	},
	
	{ -- 2 	Paladin 	PALADIN
		{ -- 1	Holy
			200315, -- Shock Treatment
			200294, -- Deliver the Light
			200482, -- Second Sunrise
		},
		
		{ -- 2	Protection
			209220, -- Unflinching Defense
			213570, -- Righteous Crusader
			211912, -- Faith's Armor
		},
		
		{ -- 3	Retribution
			186945, -- Wrath of the Ashbringer
			186927, -- Deliver the Justice
			238062, -- Righteous Verdict
		}
	},
	
	{ -- 3 	Hunter 	HUNTER
		{ -- 1	Beast Mastery
			197162, -- Jaws of Thunder (Dire Frenzy Build - raiding)
			197080, -- Pack Leader
			238051, -- Slithering Serpents
		},
		
		{ -- 2	Marksmanship
			238052, -- Unerring Arrows
			190457, -- Windrunner's Guidance
			190520, -- Precision
		},
		
		{ -- 3	Survival
			203566, -- Sharpened Fang (single target)
			203673, -- Hellcarver (multi target)
			238053, -- Jaws of the Mongoose
			203669, -- Fluffy, Go
		}
	},
	
	{ -- 4 	Rogue 	ROGUE
		{ -- 1	Assassination
			192349, -- Master Assassin
			192318, -- Master Alchemist
			192310, -- Toxic Blades
		},
		
		{ -- 2	Outlaw
			202514, -- Fate's Thirst
			202907, -- Fortune's Boon
			202524, -- Fatebringer
		},
		
		{ -- 3	Subtletly
			197234, -- Gutripper
			197239, -- Energetic Stabbing
			238068, -- Weak Point
		}
	},
	
	{ -- 5 	Priest 	PRIEST
		{ -- 1	Discipline
			197708, -- Confession
			197715, -- The Edge of Dark and Light
			197729, -- Shield of Faith
		},
		
		{ -- 2	Holy
			196358, -- Say Your Prayers
			196430, -- Words of Healing
			196489, -- Power of the Naaru
			196434, -- Holy Guidance			
		},
		
		{ -- 3	Shadow
			238065, -- Fiending Dark
			194002, -- Creeping Shadows 
			193644, -- To the Pain 
		}
	},
	
	{ -- 6 	Death Knight 	DEATHKNIGHT
		{ -- 1	Blood
			238042, -- Carrion Feast
			192457, -- Veinrender 
			192514, -- Dance of Darkness
		},
		
		{ -- 2	Frost
			189080, -- Cold as Ice (All traits AoE)
			189086, -- Blast Radius 
			189164, -- Dead of Winter
		},
		
		{ -- 3	Unholy
			191485, -- Plaguebearer
			191488, -- The Darkest Crusade 
			191419, -- Deadliest Coil
		}
	},
	
	{ -- 7 	Shaman 	SHAMAN
		{ -- 1	Elemental
			238069, -- Elemental Destabilization
			191504, -- Lava Imbued 
			191740, -- Firestorm
		},
		
		{ -- 2	Enhancement
			198292, -- Wind Strikes
			198247, -- Wind Surge 
			198349, -- Gathering of the Maelstrom
			198236, -- Forged in Lava
		},
		
		{ -- 3	Restoration
			207088, -- Tidal Chains (Dungeons)
			207285, -- Queen Ascendant
			207092, -- Buffeting Waves 
		}
	},
	
	{ -- 8 	Mage 	MAGE
		{ -- 1	Arcane
			187276, -- Ethereal Sensitivity
			187321, -- Aegwynn's Wrath 
			187258, -- Blasting Rod
		},
		
		{ -- 2	Fire
			194314, -- Everburning Consumption
			194312, -- Burning Gaze 
			194239, -- Pyroclasmic Paranoia
		},
		
		{ -- 3	Frost
			195322, -- Let It Go
			238056, -- Obsidian Lance 
			195345, -- Frozen Veins
		}
	},
	
	{ -- 9 	Warlock 	WARLOCK
		{ -- 1	Affliction
			199158, -- Perdition
			199163, -- Shadowy Incantations 
			195345, -- Winnowing
		},
		
		{ -- 2	Demonology
			211119, -- Infernal Furnace
			211106, -- The Doom of Azeroth 
			211099, -- Maw of Shadows
		},
		
		{ -- 3	Destruction
			196432, -- Burning Hunger
			196227, -- Residual Flames 
			196217, -- Chaotic Instability
		}
	},
	
	{ -- 10 	Monk 	MONK
		{ -- 1	Brewmaster
			213116, -- Face Palm
			227683, -- Hot Blooded 
			213047, -- Potent Kick
		},
		
		{ -- 2	Mistweaver
			199485, -- Essence of the Mists
			199372, -- Extended Healing 
			199380, -- Infusion of Life
		},
		
		{ -- 3	Windwalker
			195291, -- Fists of the Wind
			195263, -- Rising Winds 
			195243, -- Inner Peace
		}
	},

	{ -- 11 	Druid 	DRUID
		{ -- 1	Balance
			202445, -- Falling Star (All traits AoE)
			202386, -- Twilight Glow 
			202466, -- Sunfire Burns
		},
		
		{ -- 2	Feral
			210593, -- Tear the Flesh
			210579, -- Ashamane's Energy 
			210571, -- Feral Power
		},
		
		{ -- 3	Guardian
			200409, -- Jagged Claws (All traits AoE)
			200440, -- Vicious Bites 
			208762, -- Mauler
		},
		
		{ -- 4	Restoration
			186396, -- Persistence
			189772, -- Knowledge of the Ancients 
			186320, -- Grovewalker 
		}
	},
	
	{ -- 12 	Demon Hunter 	DEMONHUNTER
		{ -- 1	Havoc
			201455, -- Critical Chaos
			201460, -- Unleashed Demons 
			201454, -- Contained Fury
		},
		
		{ -- 2	Vengeance
			212817, -- Fiery Demise
			212816, -- Embrace the Pain
			238046, -- Lingering Ordeal
		}
	},
}


TotalAP.DB.RelicTraits = traitsByClass

return TotalAP.DB.RelicTraits