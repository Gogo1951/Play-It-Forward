local _, ns = ...

-- [weaponSubclassID] = weapon key
ns.Data.WEAPON_SUBCLASS = {
	[0] = "1H_AXE", -- Blizzard splits 1H/2H by inv slot, not subclass
	[1] = "2H_AXE",
	[2] = "BOW",
	[3] = "GUN",
	[4] = "1H_MACE",
	[5] = "2H_MACE",
	[6] = "POLEARM",
	[7] = "1H_SWORD",
	[8] = "2H_SWORD",
	[10] = "STAFF",
	[13] = "FIST",
	[15] = "DAGGER",
	[16] = "THROWN",
	[18] = "CROSSBOW",
	[19] = "WAND",
}

-- [armorSubclassID] = weapon key, for relics
ns.Data.RELIC_SUBCLASS = {
	[7] = "LIBRAM",
	[8] = "IDOL",
	[9] = "TOTEM",
}

-- The column order of every WEAPON_SPECS row
ns.Data.WEAPON_CLASS_ORDER = {
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
}

-- [weaponKey] = { trees using it per class, in WEAPON_CLASS_ORDER }
ns.Data.WEAPON_SPECS = {
	["1H_SWORD"] = { 2, 2, 1, 2, 0, 0, 1, 1, 0, 1 },
	["2H_SWORD"] = { 1, 1, 1, 0, 0, 0, 0, 0, 0, 3 },
	["1H_MACE"] = { 2, 2, 0, 1, 3, 3, 0, 0, 3, 1 },
	["2H_MACE"] = { 1, 1, 0, 0, 0, 1, 0, 0, 2, 3 },
	["1H_AXE"] = { 2, 2, 1, 0, 0, 3, 0, 0, 0, 1 },
	["2H_AXE"] = { 1, 1, 1, 0, 0, 1, 0, 0, 0, 3 },
	["DAGGER"] = { 1, 0, 1, 3, 3, 2, 3, 3, 3, 0 },
	["FIST"] = { 2, 0, 1, 2, 0, 2, 0, 0, 2, 0 },
	["POLEARM"] = { 1, 1, 1, 0, 0, 0, 0, 0, 0, 3 },
	["STAFF"] = { 1, 0, 1, 0, 3, 2, 3, 3, 3, 0 },
	["BOW"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["GUN"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["CROSSBOW"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["THROWN"] = { 3, 0, 0, 3, 0, 0, 0, 0, 0, 0 },
	["WAND"] = { 0, 0, 0, 0, 3, 0, 3, 3, 0, 0 },
	["SHIELD"] = { 1, 2, 0, 0, 0, 2, 0, 0, 0, 0 }, -- armor subclass 6
	["HELD"] = { 0, 1, 0, 0, 3, 1, 3, 3, 2, 0 },
	["LIBRAM"] = { 0, 3, 0, 0, 0, 0, 0, 0, 0, 0 },
	["IDOL"] = { 0, 0, 0, 0, 0, 0, 0, 0, 3, 0 },
	["TOTEM"] = { 0, 0, 0, 0, 0, 3, 0, 0, 0, 0 },
}

--[[
How We Got the Data

Last Validated
	2026-10-09, TBC Anniversary 2.5.6.69795

Notes
	- WEAPON_SUBCLASS turns the weapon subclass the client reports for an item into the add-on's
	  weapon key. Features/Match-Derivations.lua reads it in ns.Data.WeaponKey, then settles one-
	  or two-handed from the item's equip slot (ns.Data.ResolveHandedness).
	- Weapon subclasses with no row reach no class: 9, 11 and 12 (obsolete and exotic, a handful
	  of internal items), 14 Miscellaneous, 17 Spear and 20 Fishing Pole. No talent spec builds
	  around them, so they have no key here and no WEAPON_SPECS row.
	- RELIC_SUBCLASS gives the relic armor subclasses (7 Libram, 8 Idol, 9 Totem) a weapon key,
	  so ns.Data.WeaponKey sends relics through WEAPON_SPECS the way it sends shields and held
	  off-hands. Each relic row names the one class that can equip it: a libram the paladin, an
	  idol the druid, a totem the shaman. Without them a relic went to whoever its stats suited,
	  a Stamina idol to a warlock. Added after this client's last Validate Data run.
	- WEAPON_CLASS_ORDER is the column order of every WEAPON_SPECS row and nothing else. Which
	  classes the matcher offers an item to is FACTION_CLASSES, in Match-Classes; the
	  DEATHKNIGHT column keeps every row the same width on every flavor.
	- WEAPON_SPECS says how many of a class's three talent trees build around each weapon key: 3
	  every spec wants it (priest and one-handed mace, hunter and bow), 2 two of three (paladin
	  and one-handed sword: holy and protection), 1 one spec only (paladin and two-handed sword:
	  retribution), 0 no proficiency, or proficient but no spec uses it.
	- Eligibility comes from the same count, so there is no second table to keep in step: 0
	  means the class cannot receive the weapon at all. The priority group is 4 minus the count,
	  so a weapon every spec wants is group 1, its natural home, as native armor is. Read by
	  ns.Data.WeaponPriorityFor in Features/Match-Derivations.lua.
	- Each row's ten values follow WEAPON_CLASS_ORDER. Count a column against that list only:
	  StyLua normalizes the rows but not a padded legend, so the two would drift.
	- SHIELD (armor subclass 6) and HELD (held off-hand items) are rows here because they
	  compete for a hand rather than a material (ns.Data.UsesWeaponMatrix).
	- Druids never train polearms on this client, so their POLEARM column is 0.
	- Hand-set by the author as matching policy, not pulled from game data. Validate Data counts
	  the rows only, since no client API looks up a weapon key.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSubClass?build=2.5.6.69795
]]
