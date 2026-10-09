local _, ns = ...

if ns.IS_DISCOVERY then
	return
end

-- [faction] = the class tokens that faction can roll
ns.Data.FACTION_CLASSES = {
	Alliance = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "DRUID" },
	Horde = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
}

--[[
How We Got the Data

Last Validated
	2026-10-09, Classic Era 1.15.9.70003

Notes
	- The classes each faction can roll on this client. /who and the mailbox are both
	  same-faction, so a class the player's own side cannot roll is unreachable however well an
	  item suits it. Features/Match-Engine.lua offers items only to the player's faction row,
	  or to every class either faction rolls until the faction is known.
	- Shaman is Horde only and Paladin Alliance only.
	- No death knights: this client has none to roll.
	- Checked against the playable race and class pairs in CharBaseInfo, with each race's faction
	  from ChrRaces. Validate Data counts the rows only.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/CharBaseInfo?build=1.15.9.70003
	https://wago.tools/db2/ChrRaces?build=1.15.9.70003
	https://wago.tools/db2/ChrClasses?build=1.15.9.70003
]]
