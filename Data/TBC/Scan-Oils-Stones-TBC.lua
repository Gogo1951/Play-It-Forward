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
	{ 20744, 1, 5, "SPELL_DAMAGE" }, -- Minor Wizard Oil
	{ 20746, 1, 30, "SPELL_DAMAGE" }, -- Lesser Wizard Oil
	{ 20750, 1, 40, "SPELL_DAMAGE" }, -- Wizard Oil
	{ 20749, 1, 45, "SPELL_DAMAGE" }, -- Brilliant Wizard Oil
	{ 22522, 1, 58, "SPELL_DAMAGE" }, -- Superior Wizard Oil

	-- Mana Oils
	{ 20745, 1, 20, "MANA" }, -- Minor Mana Oil
	{ 20747, 1, 40, "MANA" }, -- Lesser Mana Oil
	{ 20748, 1, 45, "MANA" }, -- Brilliant Mana Oil
	{ 22521, 1, 52, "MANA" }, -- Superior Mana Oil
}

--[[
How We Got the Data

Last Validated
	2026-10-20, TBC Anniversary 2.5.6.70006

Notes
	- The oils, sharpening stones and weightstones any class can put on a weapon, taken from
	  Thanks for the Buff's BUFF_WINDOW_WEAPON_ITEMS for this client
	  (TFTB/Data/TBC/Buff-Window-Spells-TBC.lua), with quality, required level and binding
	  read from ItemSparse.
	- enhances is who the item helps, and it decides who can receive it through
	  ns.Data.CONSUMABLE_CLASSES in Data/Data.lua, so there is no per-item class list. MELEE
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
	- The Burning Crusade adds the Fel and Adamantite stones and the Superior oils. Held out:
	  Scourgebane (30696) and Bloodboil Poison (31535) bind on pickup and need no level; the
	  Blessed and Righteous Weapon Coatings (34538, 34539) only work on the Isle of Quel'Danas
	  and need level 70, which nobody outgrows.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSparse?build=2.5.6.69795
	https://wago.tools/db2/Item?build=2.5.6.70006
	https://wago.tools/db2/ItemSparse?build=2.5.6.70006

QuestieDB
	None.
]]
