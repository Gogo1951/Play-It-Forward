local _, ns = ...

-- [faction] = the class tokens that faction can roll
ns.Data.FACTION_CLASSES = {
	Alliance = {
		"WARRIOR",
		"PALADIN",
		"HUNTER",
		"ROGUE",
		"PRIEST",
		"SHAMAN",
		"MAGE",
		"WARLOCK",
		"DRUID",
		"DEATHKNIGHT",
	},
	Horde = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" },
}

local MANA_USERS = { "MAGE", "PRIEST", "WARLOCK", "PALADIN", "SHAMAN", "DRUID", "MONK" }

-- [what it restores, buffs or enhances] = "ALL", or the class tokens it goes to
ns.Data.CONSUMABLE_CLASSES = {
	HEALTH = "ALL",
	MANA = MANA_USERS,
	BOTH = MANA_USERS,
	STRENGTH = { "WARRIOR", "PALADIN", "DEATHKNIGHT" },
	AGILITY = { "ROGUE", "HUNTER", "SHAMAN", "DRUID", "MONK" },
	STAMINA = "ALL",
	INTELLECT = MANA_USERS,
	SPIRIT = { "PRIEST", "DRUID", "SHAMAN", "PALADIN", "MONK" },
	ARMOR = "ALL",
	PET = { "HUNTER" },
	MELEE = { "WARRIOR", "ROGUE", "PALADIN", "SHAMAN", "DEATHKNIGHT", "MONK" },
	SPELL_DAMAGE = { "MAGE", "WARLOCK", "PRIEST", "SHAMAN", "DRUID" },
}
