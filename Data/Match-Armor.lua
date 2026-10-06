local _, ns = ...

--[[
	What each class actually wears at a given level -- the single input the priority groups
	are derived from, NOT a list of what a class may receive. Every class is already offered
	every armor type at or below its own: a warrior can receive cloth, he is simply last in
	line for it, so the fix for "class X should also be able to get Y" is usually nothing.
	The Class Groups report in the Diagnostic Tools panel prints the whole derived table.

	THE LEVELS BELOW ARE ALSO THE TRAINING LEVELS, and nothing else states them. Features/
	Match-Derivations.lua probes these functions for the level a class first wears a material
	rather than listing the 40s a second time, so an edit here moves both answers together.
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
	-- No level gate, deliberately: death knights start at 55, so one would guard a character that cannot exist.
	DEATHKNIGHT = function()
		return "PLATE"
	end,
}

-- ns.Data.ArmorPriorityFor derives the priority groups by subtracting one weight from another.
ns.Data.ArmorWeight = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }

--[[
	How far below a class's training level an item may require and still be worth sending to it.

	THE TABLE ABOVE IS A GATE ON TWO THINGS AT ONCE and only one of them is about eligibility.
	A hunter trains mail at 40, so on a level 36 mail belt the gate says both "he cannot wear
	this yet" and "he is not who it is for" -- and the second is wrong. Blizzard itemizes the
	35-to-39 mail with Agility and Intellect FOR hunters and shamans, who then watched it go to
	a warrior or a paladin because they were the only heavy-armor classes admitted. Reach makes
	the class eligible and moves its recipient band up to the level it can actually equip the
	item at, instead of dropping it.

	FIVE, BECAUSE AN ITEM GOES STALE. A level 36 belt is a real gift to a hunter about to hit 40
	with no mail at all; a level 20 one is not, and would arrive four tiers out of date. Any item
	further below the training level than this reverts to being ineligible outright.

	ARMOR ONLY. ns.Data.WeaponMinLevel looks like the same gate and is not: druids never train
	polearms in Era or TBC, and that is written as a level 60 they cannot reach. Reaching for it
	would invent candidates for a proficiency that never arrives.
]]
ns.Data.PROFICIENCY_REACH = 5

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

	INVTYPE_HOLDABLE must never be added. Held off-hands look universal but turn on whether a
	class has the off-hand slot free, and adding them here makes an Intellect orb eligible for
	a warrior. They route through the weapon matrix as "HELD", in Data/Match-Weapons.lua.
]]
ns.Data.UniversalEquipLoc = {
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_NECK = true,
	INVTYPE_TRINKET = true,
}
