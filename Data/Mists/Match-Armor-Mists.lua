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
	MONK = { { 1, "LEATHER" } },
}

-- [armor type] = weight
ns.Data.ARMOR_WEIGHT = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }

-- [equipLoc] = true
ns.Data.UNIVERSAL_EQUIP_LOC = {
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_NECK = true,
	INVTYPE_TRINKET = true,
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- ARMOR_SUBCLASS turns the armor subclass the client reports for an item into its material.
	  Features/Match-Engine.lua and Features/Match-Derivations.lua read it.
	- Subclass 0 Miscellaneous (rings, necks, trinkets, cloaks, held off-hands) has no row: it
	  is decided by equip slot, so stats alone pick its recipient. 6 Shield maps to SHIELD,
	  which goes through WEAPON_SPECS in Match-Weapons rather than the armor ranking.
	- 7 Libram, 8 Idol, 9 Totem and 11 Relic have no row. Relics have no material, so
	  RELIC_SUBCLASS in Match-Weapons sends each through WEAPON_SPECS, where no class on this
	  client can equip one.
	- NATIVE_ARMOR is what each class wears from a level on: steps of from level and armor,
	  ascending, the last step at or below a level winning (ns.Data.NativeArmorAt). It is not a
	  list of what a class may receive. Every class is offered every armor at or below its own,
	  last in line for it, so "class X should also get Y" usually needs no change. The Class
	  Groups report in the Diagnostic Tools panel prints the whole derived table.
	- The levels are also the training levels, and nothing else states them.
	  Features/Match-Derivations.lua probes this table for the first level a class wears a
	  material rather than listing the 40s a second time, so an edit here moves both answers.
	- DEATHKNIGHT is plate with no level gate: a death knight starts above every level a gate
	  would guard. MONK wears leather from level 1.
	- ARMOR_WEIGHT ranks the materials. ns.Data.ArmorPriorityFor derives the priority groups by
	  subtracting one weight from another.
	- UNIVERSAL_EQUIP_LOC lists the equip slots any class can use whatever its armor material,
	  where stats alone decide.
	- INVTYPE_HOLDABLE must never be added there. Held off-hands look universal but turn on
	  whether a class has the off-hand slot free, and adding them makes an Intellect orb
	  eligible for a warrior. They route through the weapon matrix as HELD, in WEAPON_SPECS in
	  Match-Weapons.
	- Hand-set by the author as matching policy, not pulled from game data. Validate Data counts
	  the rows only, since no client API looks up a material.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
