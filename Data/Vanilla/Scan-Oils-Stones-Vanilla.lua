local _, ns = ...

if ns.IS_DISCOVERY then
	return
end

-- { itemId, quality, useLevel, enhances }
ns.Data.OILS_AND_STONES = {
	-- Sharpening Stones
	{ 2863, 1, 5, "MELEE" }, -- Coarse Sharpening Stone
	{ 2871, 1, 15, "MELEE" }, -- Heavy Sharpening Stone
	{ 7964, 1, 25, "MELEE" }, -- Solid Sharpening Stone
	{ 12404, 1, 35, "MELEE" }, -- Dense Sharpening Stone
	{ 18262, 2, 50, "MELEE" }, -- Elemental Sharpening Stone

	-- Weightstones
	{ 3240, 1, 5, "MELEE" }, -- Coarse Weightstone
	{ 3241, 1, 15, "MELEE" }, -- Heavy Weightstone
	{ 7965, 1, 25, "MELEE" }, -- Solid Weightstone
	{ 12643, 1, 35, "MELEE" }, -- Dense Weightstone

	-- Wizard Oils
	{ 20744, 1, 5, "SPELL_DAMAGE" }, -- Minor Wizard Oil
	{ 20746, 1, 30, "SPELL_DAMAGE" }, -- Lesser Wizard Oil
	{ 20750, 1, 40, "SPELL_DAMAGE" }, -- Wizard Oil
	{ 20749, 1, 45, "SPELL_DAMAGE" }, -- Brilliant Wizard Oil

	-- Mana Oils
	{ 20745, 1, 20, "MANA" }, -- Minor Mana Oil
	{ 20747, 1, 40, "MANA" }, -- Lesser Mana Oil
	{ 20748, 1, 45, "MANA" }, -- Brilliant Mana Oil
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Classic Era 1.15.9.70576

Notes
	- The oils, sharpening stones and weightstones any class can put on a weapon, taken from
	  Thanks for the Buff's BUFF_WINDOW_WEAPON_ITEMS for this client
	  (TFTB/Data/Vanilla/Buff-Window-Spells-Vanilla.lua), with quality, required level and binding
	  read from ItemSparse.
	- enhances is who the item helps, and it decides who can receive it through
	  ns.Data.CONSUMABLE_CLASSES in this folder's Match-Classes file, so there is no per-item class list. MELEE
	  for the stones; SPELL_DAMAGE for the wizard oils; MANA for the mana oils, which restore
	  mana and, from Brilliant up, add healing.
	- A sharpening stone only takes a bladed weapon and a weightstone only a blunt one. Every
	  MELEE class carries both kinds of weapon, so both go to all of them.
	- Held out by hand:
	  - Rough Sharpening Stone (2862) and Rough Weightstone (3239) need only level 1, so their
	    recipient band tops out below ns.Data.MIN_RECIPIENT_LEVEL and they would reach nobody.
	  - Consecrated Sharpening Stone (23122) and Blessed Wizard Oil (23123) bind on pickup,
	    and a bound item cannot be mailed.
	  - Fishing lures: they go on a fishing pole, need no level, and are nobody's upgrade.
	  - Shadow Oil (3824) and Frost Oil (3829) only add a chance on hit to proc a bolt or a
	    slow. No stat says who wants one, so the matcher would be guessing.
	  - 211845 Blackfathom Sharpening Stone and 211848 Blackfathom Mana Oil are in the Classic
	    Era tables but are Season of Discovery's, which QuestieDB's Classic items don't hold.
	    They belong in Data/Discovery/, never here.
	- Rechecked against this client's tables at 1.15.9.70576 by name (sharpening stones,
	  weightstones, wizard and mana oils). Besides the items held out above, only 6213 Test
	  Sharpening Stone, an internal item, and 22600 Craftsman's Writ - Dense Weightstone, a
	  quest token rather than a stone, turn up.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSparse?build=1.15.9.70576
	https://wago.tools/db2/Item?build=1.15.9.70576

QuestieDB
	https://raw.githubusercontent.com/Questie/QuestieDB/master/data/Classic/classicItemDB.lua
]]
