local _, ns = ...

-- Weapon subclassID (from GetItemInfoInstant) -> our weapon key.
ns.Data.WeaponSubclass = {
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

-- Column order for the matrix below and nothing else, not the matcher's class list, which faction and flavor filter.
ns.Data.WeaponClassOrder = {
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

--[[
	How many of a class's three talent trees build around each weapon type.

	  3 = every spec wants it   (priest + 1H mace, hunter + bow)
	  2 = two of three          (paladin + 1H sword: holy and prot)
	  1 = one spec only         (paladin + 2H sword: ret)
	  0 = no proficiency, or proficient but no spec ever uses it

	Eligibility is derived from this, so there is no second matrix to keep in sync: 0 means the
	class cannot receive the type at all. Group = 4 - count, so a 3-spec weapon is group 1, its
	natural home, exactly as native armor is.

	EACH ROW'S TEN VALUES ARE ns.Data.WeaponClassOrder ABOVE, IN THAT ORDER. Count a column
	against that array and nothing else. Do not add a padded legend here: StyLua normalizes the
	rows but leaves the padding alone, so the two drift and the legend names the wrong columns.
]]
ns.Data.WeaponSpecs = {
	["1H_SWORD"] = { 2, 2, 1, 2, 0, 0, 1, 1, 0, 1 },
	["2H_SWORD"] = { 1, 1, 1, 0, 0, 0, 0, 0, 0, 3 },
	["1H_MACE"] = { 2, 2, 0, 1, 3, 3, 0, 0, 3, 1 },
	["2H_MACE"] = { 1, 1, 0, 0, 0, 1, 0, 0, 2, 3 },
	["1H_AXE"] = { 2, 2, 1, 0, 0, 3, 0, 0, 0, 1 },
	["2H_AXE"] = { 1, 1, 1, 0, 0, 1, 0, 0, 0, 3 },
	["DAGGER"] = { 1, 0, 1, 3, 3, 2, 3, 3, 3, 0 },
	["FIST"] = { 2, 0, 1, 2, 0, 2, 0, 0, 2, 0 },
	["POLEARM"] = { 1, 1, 1, 0, 0, 0, 0, 0, 2, 3 }, -- druid gated to 60+ below
	["STAFF"] = { 1, 0, 1, 0, 3, 2, 3, 3, 3, 0 },
	["BOW"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["GUN"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["CROSSBOW"] = { 3, 0, 3, 3, 0, 0, 0, 0, 0, 0 },
	["THROWN"] = { 3, 0, 0, 3, 0, 0, 0, 0, 0, 0 },
	["WAND"] = { 0, 0, 0, 0, 3, 0, 3, 3, 0, 0 },
	["SHIELD"] = { 1, 2, 0, 0, 0, 2, 0, 0, 0, 0 }, -- armor subclass 6
	["HELD"] = { 0, 1, 0, 0, 3, 1, 3, 3, 2, 0 },
}

--[[
	Proficiencies that do not exist from level 1: below the listed level the class cannot
	receive that type at all, whatever the spec count says. The gate reads the ITEM's required
	level, not the recipient's, which is self-correcting -- a druid only becomes a candidate
	for polearms requiring 60 or above, by which point they have the proficiency.
]]
ns.Data.WeaponMinLevel = {
	DRUID = { POLEARM = 60 }, -- druids don't train polearms until TBC
}

-- Derived into priority groups and weapon keys by Features/Match-Derivations.lua.
