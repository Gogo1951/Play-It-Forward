local _, ns = ...

if ns.IS_DISCOVERY then
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

--[[
How We Got the Data

Last Validated
	2026-10-09, Classic Era 1.15.9.70003

Notes
	- ARMOR_SUBCLASS turns the armor subclass the client reports for an item into its material.
	  ns.Data.ARMOR_WEIGHT in Data/Match-Armor.lua ranks the materials, and
	  Features/Match-Engine.lua and Features/Match-Derivations.lua read both.
	- Subclass 0 Miscellaneous (rings, necks, trinkets, cloaks, held off-hands) has no row: it
	  is decided by equip slot, so stats alone pick its recipient. 6 Shield maps to SHIELD,
	  which goes through WEAPON_SPECS in Match-Weapons rather than the armor ranking.
	- 7 Libram, 8 Idol and 9 Totem have no row. Relics have no material, so RELIC_SUBCLASS in
	  Match-Weapons sends each through WEAPON_SPECS to the one class that can equip it.
	- NATIVE_ARMOR is what each class wears from a level on: steps of from level and armor,
	  ascending, the last step at or below a level winning (ns.Data.NativeArmorAt). It is not a
	  list of what a class may receive. Every class is offered every armor at or below its own,
	  last in line for it, so "class X should also get Y" usually needs no change. The Class
	  Groups report in the Diagnostic Tools panel prints the whole derived table.
	- The levels are also the training levels, and nothing else states them.
	  Features/Match-Derivations.lua probes this table for the first level a class wears a
	  material rather than listing the 40s a second time, so an edit here moves both answers.
	- DEATHKNIGHT is plate with no level gate: a death knight starts above every level a gate
	  would guard.
	- Hand-set by the author as matching policy, not pulled from game data. Validate Data counts
	  the rows only, since no client API looks up a material.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSubClass?build=1.15.9.70003
]]
