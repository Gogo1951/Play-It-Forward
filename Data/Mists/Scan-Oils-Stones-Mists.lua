local _, ns = ...

-- { itemId, quality, useLevel, enhances }
ns.Data.OILS_AND_STONES = {
	-- Sharpening Stones
	{ 2863, 1, 5, "MELEE" }, -- Coarse Sharpening Stone
	{ 2871, 1, 15, "MELEE" }, -- Heavy Sharpening Stone
	{ 7964, 1, 25, "MELEE" }, -- Solid Sharpening Stone
	{ 12404, 1, 35, "MELEE" }, -- Dense Sharpening Stone
	{ 18262, 2, 50, "MELEE" }, -- Elemental Sharpening Stone
	{ 23528, 1, 50, "MELEE" }, -- Fel Sharpening Stone
	{ 23529, 2, 60, "MELEE" }, -- Adamantite Sharpening Stone

	-- Weightstones
	{ 3240, 1, 5, "MELEE" }, -- Coarse Weightstone
	{ 3241, 1, 15, "MELEE" }, -- Heavy Weightstone
	{ 7965, 1, 25, "MELEE" }, -- Solid Weightstone
	{ 12643, 1, 35, "MELEE" }, -- Dense Weightstone
	{ 28420, 1, 50, "MELEE" }, -- Fel Weightstone
	{ 28421, 2, 60, "MELEE" }, -- Adamantite Weightstone

	-- Wizard Oils
	{ 20744, 1, 5, "INTELLECT" }, -- Minor Wizard Oil
	{ 20746, 1, 30, "INTELLECT" }, -- Lesser Wizard Oil
	{ 20750, 1, 40, "INTELLECT" }, -- Wizard Oil
	{ 20749, 1, 45, "INTELLECT" }, -- Brilliant Wizard Oil
	{ 22522, 1, 58, "INTELLECT" }, -- Superior Wizard Oil

	-- Mana Oils
	{ 20745, 1, 20, "SPIRIT" }, -- Minor Mana Oil
	{ 20747, 1, 40, "SPIRIT" }, -- Lesser Mana Oil
	{ 20748, 1, 45, "SPIRIT" }, -- Brilliant Mana Oil
	{ 22521, 1, 52, "SPIRIT" }, -- Superior Mana Oil
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- The oils, sharpening stones and weightstones any class can put on a weapon, taken from
	  Thanks for the Buff's BUFF_WINDOW_WEAPON_ITEMS for this client
	  (TFTB/Data/TBC/Buff-Window-Spells-TBC.lua), with quality, required level and binding
	  read from ItemSparse.
	- enhances is who the item helps, from what this client's use text says it adds, and it
	  decides who can receive it through ns.Data.CONSUMABLE_CLASSES in this folder's
	  Match-Classes file, so there is no per-item class list. MELEE for the stones, which add
	  weapon damage or critical strike. On this client the wizard oils add Intellect, so they
	  are INTELLECT, and the mana oils add Spirit (Brilliant Mana Oil Intellect and Spirit), so
	  they are SPIRIT. The TBC copy's SPELL_DAMAGE and MANA were corrected from this client's
	  use text (5.5.4.70631).
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
	- The Burning Crusade adds the Fel and Adamantite stones and the Superior oils. Held out:
	  Scourgebane (30696) and Bloodboil Poison (31535) bind on pickup and need no level; the
	  Blessed and Righteous Weapon Coatings (34538, 34539) only work on the Isle of Quel'Danas
	  and need level 70, which nobody outgrows.
	- Checked against this client's tables at 5.5.4.70631 by name. Besides the items held out
	  above, 6213 Test Sharpening Stone (internal), 22600 Craftsman's Writ - Dense Weightstone
	  (a quest token) and 36899 Exceptional Mana Oil turn up. The last is held out as likely
	  unobtainable: QuestieDB lists no source for it and no spell creates it.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSparse?build=5.5.4.70631
	https://wago.tools/db2/Item?build=5.5.4.70631
	https://wago.tools/db2/ItemEffect?build=5.5.4.70631

QuestieDB
	https://raw.githubusercontent.com/Questie/QuestieDB/master/data/MoP/mopItemDB.lua
]]
