local _, ns = ...

--[[
	What each class actually wears at a given level.

	READ THIS BEFORE ADDING A CLASS TO A ROW. This is not a list of what a class is allowed
	to receive. It is the single input the priority groups are derived from, and every
	class is already offered every armor type at or below its own: a warrior is a valid
	recipient of cloth, he is simply last in line for it.

	  reqLevel 60   WARRIOR  plate g1, mail g2, leather g3, cloth g4
	                ROGUE    leather g1, cloth g2

	So the fix for "class X should also be able to get Y" is usually nothing. The Class
	Groups report in the Diagnostic Tools panel prints the whole derived table.

	Deriving rather than listing keeps the pre-40 and post-40 layouts from drifting apart.
]]
ns.Data.NativeArmor = {
	PRIEST = function()
		return "CLOTH"
	end,
	MAGE = function()
		return "CLOTH"
	end,
	WARLOCK = function()
		return "CLOTH"
	end,
	ROGUE = function()
		return "LEATHER"
	end,
	DRUID = function()
		return "LEATHER"
	end,
	HUNTER = function(lvl)
		return lvl >= 40 and "MAIL" or "LEATHER"
	end,
	SHAMAN = function(lvl)
		return lvl >= 40 and "MAIL" or "LEATHER"
	end,
	WARRIOR = function(lvl)
		return lvl >= 40 and "PLATE" or "MAIL"
	end,
	PALADIN = function(lvl)
		return lvl >= 40 and "PLATE" or "MAIL"
	end,
	--[[
		No level gate, deliberately. Death knights start at 55 and the recipient pool is
		built from /who alone, so gating here guards against a character that cannot exist.
	]]
	DEATHKNIGHT = function()
		return "PLATE"
	end,
}

-- Exported: ns.Data.ArmorPriorityFor derives the priority groups by subtracting one from another.
ns.Data.ArmorWeight = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }

-- Armor subclassID (from GetItemInfoInstant) -> armor type token.
ns.Data.ArmorSubclass = {
	[1] = "CLOTH",
	[2] = "LEATHER",
	[3] = "MAIL",
	[4] = "PLATE",
	[6] = "SHIELD",
	-- [0] = Miscellaneous (rings/necks/trinkets) -> universal, handled by equipLoc
}

--[[
	Equip slots any class can use regardless of armor material: stats alone decide them.

	INVTYPE_HOLDABLE must never be added here. Held off-hands look universal but turn on
	whether a class has the off-hand slot free, which is slot competition rather than armor
	material, and adding them here makes an Intellect orb eligible for a warrior. They
	route through the weapon matrix as "HELD" instead, in Data/Weapon-Priority.lua.
]]
ns.Data.UniversalEquipLoc = {
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_NECK = true,
	INVTYPE_TRINKET = true,
}
