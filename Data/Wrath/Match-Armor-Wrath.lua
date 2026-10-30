local _, ns = ...

-- [armorSubclassID] = armor type
ns.Data.ARMOR_SUBCLASS = {
	[1] = "CLOTH",
	[2] = "LEATHER",
	[3] = "MAIL",
	[4] = "PLATE",
	[6] = "SHIELD",
	-- [0] = Miscellaneous (rings/necks/trinkets) -> universal, handled by equipLoc
}

-- [classToken] = { { from level, armor worn }, ... }, ascending
ns.Data.NATIVE_ARMOR = {
	WARRIOR = { { 1, "MAIL" }, { 40, "PLATE" } },
	PALADIN = { { 1, "MAIL" }, { 40, "PLATE" } },
	HUNTER = { { 1, "LEATHER" }, { 40, "MAIL" } },
	ROGUE = { { 1, "LEATHER" } },
	PRIEST = { { 1, "CLOTH" } },
	SHAMAN = { { 1, "LEATHER" }, { 40, "MAIL" } },
	MAGE = { { 1, "CLOTH" } },
	WARLOCK = { { 1, "CLOTH" } },
	DRUID = { { 1, "LEATHER" } },
	DEATHKNIGHT = { { 1, "PLATE" } },
}

-- ns.Data.ArmorPriorityFor derives the priority groups by subtracting one weight from another.
ns.Data.ARMOR_WEIGHT = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }

--[[
	Equip slots any class can use regardless of armor material: stats alone decide them.

	INVTYPE_HOLDABLE must never be added. Held off-hands look universal but turn on whether a
	class has the off-hand slot free, and adding them here makes an Intellect orb eligible for
	a warrior. They route through the weapon matrix as "HELD", in the flavor folder's WEAPON_SPECS.
]]
ns.Data.UNIVERSAL_EQUIP_LOC = {
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_NECK = true,
	INVTYPE_TRINKET = true,
}
