local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

-- { itemId, quality, useLevel, buffs }
ns.Data.SCROLLS = {
	-- Strength
	{ 954, 1, 10, "STRENGTH" }, -- Scroll of Strength
	{ 2289, 1, 25, "STRENGTH" }, -- Scroll of Strength II
	{ 4426, 1, 40, "STRENGTH" }, -- Scroll of Strength III
	{ 10310, 1, 55, "STRENGTH" }, -- Scroll of Strength IV

	-- Agility
	{ 3012, 1, 10, "AGILITY" }, -- Scroll of Agility
	{ 1477, 1, 25, "AGILITY" }, -- Scroll of Agility II
	{ 4425, 1, 40, "AGILITY" }, -- Scroll of Agility III
	{ 10309, 1, 55, "AGILITY" }, -- Scroll of Agility IV

	-- Stamina
	{ 1180, 1, 5, "STAMINA" }, -- Scroll of Stamina
	{ 1711, 1, 20, "STAMINA" }, -- Scroll of Stamina II
	{ 4422, 1, 35, "STAMINA" }, -- Scroll of Stamina III
	{ 10307, 1, 50, "STAMINA" }, -- Scroll of Stamina IV

	-- Intellect
	{ 955, 1, 5, "INTELLECT" }, -- Scroll of Intellect
	{ 2290, 1, 20, "INTELLECT" }, -- Scroll of Intellect II
	{ 4419, 1, 35, "INTELLECT" }, -- Scroll of Intellect III
	{ 10308, 1, 50, "INTELLECT" }, -- Scroll of Intellect IV

	-- Spirit
	{ 1712, 1, 15, "SPIRIT" }, -- Scroll of Spirit II
	{ 4424, 1, 30, "SPIRIT" }, -- Scroll of Spirit III
	{ 10306, 1, 45, "SPIRIT" }, -- Scroll of Spirit IV

	-- Protection
	{ 1478, 1, 15, "ARMOR" }, -- Scroll of Protection II
	{ 4421, 1, 30, "ARMOR" }, -- Scroll of Protection III
	{ 10305, 1, 45, "ARMOR" }, -- Scroll of Protection IV
}

--[[
How We Got the Data

Last Validated
	Never. Copied from Data/Vanilla/.

Notes
	- The six stat scroll lines: Strength, Agility, Stamina, Intellect, Spirit and Protection.
	  Every rank of each line the client has, one row per rank. Other scrolls are out: the ones
	  that teach, teleport, deal damage or imbue a weapon are one class's business, or nobody's
	  once read.
	- buffs is the stat the scroll raises, with Protection's armor as ARMOR. It decides who can
	  receive the scroll through ns.Data.CONSUMABLE_CLASSES in Data/Data.lua, so there is no
	  per-item class list.
	- 1181 Scroll of Spirit, 3013 Scroll of Protection are held out by hand. Both need only level 1, so their recipient band tops
	  out below ns.Data.MIN_RECIPIENT_LEVEL and they would reach nobody.
	- Hand-picked from the maintainer's Wowhead list and a Validate Data run of it, not from a
	  query.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	The maintainer's Wowhead item listing of scrolls. URL not recorded.

wago.tools
	None.
]]
