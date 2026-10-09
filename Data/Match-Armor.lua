local _, ns = ...

-- ns.Data.ArmorPriorityFor derives the priority groups by subtracting one weight from another.
ns.Data.ARMOR_WEIGHT = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }

--[[
	How far below a class's training level an item may require and still be worth sending to it.

	THE FLAVOR FOLDER'S NATIVE_ARMOR IS A GATE ON TWO THINGS AT ONCE and only one of them is about
	eligibility.
	A hunter trains mail at 40, so on a level 36 mail belt the gate says both "he cannot wear
	this yet" and "he is not who it is for" -- and the second is wrong. Blizzard itemizes the
	35-to-39 mail with Agility and Intellect FOR hunters and shamans, who then watched it go to
	a warrior or a paladin because they were the only heavy-armor classes admitted. Reach makes
	the class eligible and moves its recipient band up to the level it can actually equip the
	item at, instead of dropping it.

	FIVE, BECAUSE AN ITEM GOES STALE. A level 36 belt is a real gift to a hunter about to hit 40
	with no mail at all; a level 20 one is not, and would arrive four tiers out of date. Any item
	further below the training level than this reverts to being ineligible outright.

	ARMOR ONLY. A weapon type is either in a class's column of the flavor folder's WEAPON_SPECS or it
	never is, so there is no weapon training level to reach for.
]]
ns.Data.PROFICIENCY_REACH = 5

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
