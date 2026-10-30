local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

-- [faction] = the class tokens that faction can roll
ns.Data.FACTION_CLASSES = {
	Alliance = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "DRUID" },
	Horde = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
}

local MANA_USERS = { "MAGE", "PRIEST", "WARLOCK", "PALADIN", "SHAMAN", "DRUID", "HUNTER" }

-- [what it restores, buffs or enhances] = "ALL", or the class tokens it goes to
ns.Data.CONSUMABLE_CLASSES = {
	HEALTH = "ALL",
	MANA = MANA_USERS,
	BOTH = MANA_USERS,
	STRENGTH = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID", "DEATHKNIGHT" },
	AGILITY = { "ROGUE", "HUNTER", "WARRIOR", "DRUID" },
	STAMINA = "ALL",
	INTELLECT = MANA_USERS,
	SPIRIT = { "PRIEST", "MAGE", "DRUID", "SHAMAN", "PALADIN" },
	ARMOR = "ALL",
	PET = { "HUNTER" },
	MELEE = { "WARRIOR", "ROGUE", "PALADIN", "SHAMAN", "DEATHKNIGHT" },
	SPELL_DAMAGE = { "MAGE", "WARLOCK", "PRIEST", "SHAMAN", "DRUID" },
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Season of Discovery 1.15.9.70576

Notes
	- CONSUMABLE_CLASSES: who a consumable goes to, by what it restores, the stat a scroll buffs, or who an oil or stone enhances a weapon for. Hunters have mana here; pet food is a hunter's alone; stones and melee oils go to the classes that fight with their weapon, wizard oils to spell-damage casters, mana oils to anybody with mana.
	- The classes each faction can roll on this client. /who and the mailbox are both
	  same-faction, so a class the player's own side cannot roll is unreachable however well an
	  item suits it. Features/Match-Engine.lua offers items only to the player's faction row,
	  or to every class either faction rolls until the faction is known.
	- Shaman is Horde only and Paladin Alliance only.
	- No death knights: this client has none to roll.
	- Checked against the playable race and class pairs in CharBaseInfo, with each race's faction
	  from ChrRaces. Validate Data counts the rows only.
	- Rechecked against CharBaseInfo at 1.15.9.70576: the season rolls the same classes as
	  Classic Era.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/CharBaseInfo?build=1.15.9.70576
	https://wago.tools/db2/ChrRaces?build=1.15.9.70576
	https://wago.tools/db2/ChrClasses?build=1.15.9.70576

QuestieDB
	None.
]]
