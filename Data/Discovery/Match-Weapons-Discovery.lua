local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

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
