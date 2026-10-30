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
	[11] = "RELIC",
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
	"MONK",
}

-- [weaponKey] = { trees using it per class, in WEAPON_CLASS_ORDER }
ns.Data.WEAPON_SPECS = {
	["1H_SWORD"] = { 2, 2, 0, 2, 0, 0, 1, 1, 0, 1, 3 },
	["2H_SWORD"] = { 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0 },
	["1H_MACE"] = { 2, 2, 0, 1, 3, 3, 0, 0, 3, 1, 3 },
	["2H_MACE"] = { 1, 1, 0, 0, 0, 1, 0, 0, 2, 3, 0 },
	["1H_AXE"] = { 2, 2, 0, 1, 0, 3, 0, 0, 0, 1, 3 },
	["2H_AXE"] = { 1, 1, 0, 0, 0, 1, 0, 0, 0, 3, 0 },
	["DAGGER"] = { 1, 0, 0, 3, 3, 2, 3, 3, 3, 0, 0 },
	["FIST"] = { 2, 0, 0, 2, 0, 2, 0, 0, 2, 0, 3 },
	["POLEARM"] = { 1, 1, 0, 0, 0, 0, 0, 0, 1, 3, 2 },
	["STAFF"] = { 1, 0, 0, 0, 3, 2, 3, 3, 3, 0, 3 },
	["BOW"] = { 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0 },
	["GUN"] = { 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0 },
	["CROSSBOW"] = { 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0 },
	["THROWN"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	["WAND"] = { 0, 0, 0, 0, 3, 0, 3, 3, 0, 0, 0 },
	["SHIELD"] = { 1, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0 }, -- armor subclass 6
	["HELD"] = { 0, 1, 0, 0, 3, 1, 3, 3, 2, 0, 1 },
	["LIBRAM"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	["IDOL"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	["TOTEM"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	["RELIC"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- WEAPON_SUBCLASS turns the weapon subclass the client reports for an item into the add-on's
	  weapon key. Features/Match-Derivations.lua reads it in ns.Data.WeaponKey, then settles one-
	  or two-handed from the item's equip slot (ns.Data.ResolveHandedness).
	- Weapon subclasses with no row reach no class: 9, 11 and 12 (obsolete and exotic, a handful
	  of internal items), 14 Miscellaneous, 17 Spear and 20 Fishing Pole. No talent spec builds
	  around them, so they have no key here and no WEAPON_SPECS row.
	- RELIC_SUBCLASS gives the relic armor subclasses (7 Libram, 8 Idol, 9 Totem, 11 Relic) a
	  weapon key, so ns.Data.WeaponKey sends relics through WEAPON_SPECS the way it sends
	  shields and held off-hands. Relics left the game in Mists, so the subclasses stay mapped,
	  a libram still in a bag must not fall through to the armor path, and their WEAPON_SPECS
	  rows are empty: nobody can equip one. Subclass 11 is the generic relic a few 5.5.4 BoE
	  items still carry, with no slot to go in.
	- WEAPON_CLASS_ORDER is the column order of every WEAPON_SPECS row and nothing else. Which
	  classes the matcher offers an item to is FACTION_CLASSES, in Match-Classes.
	- WEAPON_SPECS says how many of a class's three talent trees build around each weapon key
	  (four for a druid): 3 every spec wants it, 2 two specs, 1 one spec only, 0 no
	  proficiency, or proficient but no spec uses it.
	- Eligibility comes from the same count, so there is no second table to keep in step: 0
	  means the class cannot receive the weapon at all. The priority group is 4 minus the count,
	  so a weapon every spec wants is group 1, its natural home, as native armor is. Read by
	  ns.Data.WeaponPriorityFor in Features/Match-Derivations.lua.
	- Each row's eleven values follow WEAPON_CLASS_ORDER. Count a column against that list only:
	  StyLua normalizes the rows but not a padded legend, so the two would drift.
	- SHIELD (armor subclass 6) and HELD (held off-hand items) are rows here because they
	  compete for a hand rather than a material (ns.Data.UsesWeaponMatrix).
	- Mists took the ranged slot away. A hunter fights with a bow, gun or crossbow alone and
	  holds no melee weapon at all, and a warrior or rogue no longer carries one to pull with.
	  Thrown weapons are gone.
	- A monk trains fists, one-hand axes, maces and swords, polearms and staves; Brewmaster and
	  Windwalker take the polearm, and a Mistweaver the held off-hand beside a one-hander.
	- Hand-set by the author as matching policy, not pulled from game data. Validate Data counts
	  the rows only, since no client API looks up a weapon key.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
