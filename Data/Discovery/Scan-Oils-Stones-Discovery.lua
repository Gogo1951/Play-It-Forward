local _, ns = ...

if not ns.IS_DISCOVERY then
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
	Not yet: built 2026-10-19 from wago.tools tables, awaiting a Validate Data run in game.

Notes
	- The oils, sharpening stones and weightstones any class can put on a weapon, taken from
	  Thanks for the Buff's BUFF_WINDOW_WEAPON_ITEMS for this client
	  (TFTB/Data/Discovery/Buff-Window-Spells-Discovery.lua), with quality, required level and binding
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
	- Season of Discovery adds nothing here. Held out: Blackfathom Mana Oil (211848) only
	  works inside Blackfathom Deeps, and the matcher cannot tell who is going there;
	  Enchanted Repellent (233996) was cut by hand until somebody checks in game what it
	  does and who it helps; Blackfathom Sharpening Stone (211845) and the Weapon Cleaning
	  Cloth (221362) need no level; the
	  season's own Blessed Wizard Oil (238234), Consecrated Sharpening Stone (238241) and
	  Weighted Consecrated Sharpening Stone (237810) bind on pickup.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/ItemSparse?build=1.15.9.70003
	https://wago.tools/db2/ItemEffect?build=1.15.9.70003
	https://wago.tools/db2/Spell?build=1.15.9.70003
]]
