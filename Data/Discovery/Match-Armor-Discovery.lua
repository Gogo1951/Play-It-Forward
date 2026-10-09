local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

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
