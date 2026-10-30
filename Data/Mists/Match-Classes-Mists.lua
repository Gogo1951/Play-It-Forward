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
		"MONK",
	},
	Horde = {
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
		"MONK",
	},
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

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- FACTION_CLASSES: the classes each faction can roll on this client. /who and the mailbox
	  are both same-faction, so a class the player's own side cannot roll is unreachable however
	  well an item suits it. Features/Match-Engine.lua offers items only to the player's faction
	  row, or to every class either faction rolls until the faction is known. Both factions roll
	  all eleven classes here.
	- CONSUMABLE_CLASSES: who a consumable goes to, by what it restores, the stat a scroll buffs,
	  or who an oil or stone enhances a weapon for. Read by Features/Match-Engine.lua.
	- Hunters run on focus here, so MANA_USERS leaves them out, and monks are in for the
	  Mistweaver. Pet food is a hunter's alone; stones and melee oils go to the classes that
	  fight with their weapon, wizard oils to spell-damage casters, mana oils to anybody with
	  mana.
	- Strength is plate's alone since Cataclysm, so it goes to warriors, paladins and death
	  knights, and Agility to the leather and mail melee, shamans and monks included.
	- Validate Data counts the rows only.
	- Checked against CharBaseInfo at 5.5.4.70631: both factions roll all eleven classes.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/CharBaseInfo?build=5.5.4.70631
	https://wago.tools/db2/ChrRaces?build=5.5.4.70631
	https://wago.tools/db2/ChrClasses?build=5.5.4.70631

QuestieDB
	None.
]]
