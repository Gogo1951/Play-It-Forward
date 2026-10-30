local _, ns = ...

-- { itemId, quality, useLevel, buffs }
ns.Data.SCROLLS = {
	-- Strength
	{ 2289, 1, 15, "STRENGTH" }, -- Scroll of Strength II
	{ 4426, 1, 30, "STRENGTH" }, -- Scroll of Strength III
	{ 10310, 1, 40, "STRENGTH" }, -- Scroll of Strength IV
	{ 27503, 1, 50, "STRENGTH" }, -- Scroll of Strength V
	{ 33462, 1, 60, "STRENGTH" }, -- Scroll of Strength VI
	{ 43465, 1, 70, "STRENGTH" }, -- Scroll of Strength VII
	{ 43466, 1, 80, "STRENGTH" }, -- Scroll of Strength VIII
	{ 63304, 1, 80, "STRENGTH" }, -- Scroll of Strength IX

	-- Agility
	{ 1477, 1, 15, "AGILITY" }, -- Scroll of Agility II
	{ 4425, 1, 30, "AGILITY" }, -- Scroll of Agility III
	{ 10309, 1, 40, "AGILITY" }, -- Scroll of Agility IV
	{ 27498, 1, 50, "AGILITY" }, -- Scroll of Agility V
	{ 33457, 1, 60, "AGILITY" }, -- Scroll of Agility VI
	{ 43463, 1, 70, "AGILITY" }, -- Scroll of Agility VII
	{ 43464, 1, 80, "AGILITY" }, -- Scroll of Agility VIII
	{ 63303, 1, 80, "AGILITY" }, -- Scroll of Agility IX

	-- Stamina
	{ 1711, 1, 15, "STAMINA" }, -- Scroll of Stamina II
	{ 4422, 1, 30, "STAMINA" }, -- Scroll of Stamina III
	{ 10307, 1, 40, "STAMINA" }, -- Scroll of Stamina IV
	{ 27502, 1, 50, "STAMINA" }, -- Scroll of Stamina V
	{ 33461, 1, 60, "STAMINA" }, -- Scroll of Stamina VI
	{ 37093, 1, 70, "STAMINA" }, -- Scroll of Stamina VII
	{ 37094, 1, 80, "STAMINA" }, -- Scroll of Stamina VIII
	{ 63306, 1, 80, "STAMINA" }, -- Scroll of Stamina IX

	-- Intellect
	{ 2290, 1, 15, "INTELLECT" }, -- Scroll of Intellect II
	{ 4419, 1, 30, "INTELLECT" }, -- Scroll of Intellect III
	{ 10308, 1, 40, "INTELLECT" }, -- Scroll of Intellect IV
	{ 27499, 1, 50, "INTELLECT" }, -- Scroll of Intellect V
	{ 33458, 1, 60, "INTELLECT" }, -- Scroll of Intellect VI
	{ 37091, 1, 70, "INTELLECT" }, -- Scroll of Intellect VII
	{ 37092, 1, 80, "INTELLECT" }, -- Scroll of Intellect VIII
	{ 63305, 1, 80, "INTELLECT" }, -- Scroll of Intellect IX

	-- Spirit
	{ 1712, 1, 15, "SPIRIT" }, -- Scroll of Spirit II
	{ 4424, 1, 30, "SPIRIT" }, -- Scroll of Spirit III
	{ 10306, 1, 40, "SPIRIT" }, -- Scroll of Spirit IV
	{ 27501, 1, 50, "SPIRIT" }, -- Scroll of Spirit V
	{ 33460, 1, 60, "SPIRIT" }, -- Scroll of Spirit VI
	{ 37097, 1, 70, "SPIRIT" }, -- Scroll of Spirit VII
	{ 37098, 1, 80, "SPIRIT" }, -- Scroll of Spirit VIII
	{ 63307, 1, 80, "SPIRIT" }, -- Scroll of Spirit IX

	-- Protection
	{ 1478, 1, 15, "ARMOR" }, -- Scroll of Protection II
	{ 4421, 1, 30, "ARMOR" }, -- Scroll of Protection III
	{ 10305, 1, 40, "ARMOR" }, -- Scroll of Protection IV
	{ 27500, 1, 50, "ARMOR" }, -- Scroll of Protection V
	{ 33459, 1, 60, "ARMOR" }, -- Scroll of Protection VI
	{ 43467, 1, 70, "ARMOR" }, -- Scroll of Protection VII
	{ 43468, 1, 80, "ARMOR" }, -- Scroll of Protection VIII
	{ 63308, 1, 80, "ARMOR" }, -- Scroll of Protection IX
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- The six stat scroll lines: Strength, Agility, Stamina, Intellect, Spirit and Protection.
	  Every rank of each line the client has, one row per rank, except the rank I scrolls held
	  out below. Other scrolls are out: the ones that teach, teleport, deal damage or imbue a
	  weapon are one class's business, or nobody's once read.
	- buffs is the stat the scroll raises, with Protection's armor as ARMOR. It decides who can
	  receive the scroll through ns.Data.CONSUMABLE_CLASSES in this folder's Match-Classes
	  file, so there is no per-item class list. Each counts as a Battle or Guardian Elixir on
	  this client, which the add-on does not track.
	- 1181 Scroll of Spirit and 3013 Scroll of Protection are held out by hand. Both need only
	  level 1, so their recipient band tops out below ns.Data.MIN_RECIPIENT_LEVEL and they
	  would reach nobody.
	- This client lowers every rank's level from TBC's: rank I needs 1, II 15, III 30, IV 40 and
	  V 50. So 954 Scroll of Strength, 955 Scroll of Intellect, 1180 Scroll of Stamina and 3012
	  Scroll of Agility are held out here for the same reason as the two above, and useLevel is
	  this client's, not the TBC copy's.
	- Hand-picked from the maintainer's Wowhead list and a Validate Data run of it, not from a
	  query.
	- Checked against this client's tables at 5.5.4.70631. Ranks VI to IX of all six lines
	  were missing and were added, awaiting the next Validate Data run: each drops or is an
	  Inscription recipe, per QuestieDB and the tables.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	The maintainer's Wowhead item listing of scrolls. URL not recorded.

wago.tools
	https://wago.tools/db2/ItemSparse?build=5.5.4.70631
	https://wago.tools/db2/SpellEffect?build=5.5.4.70631

QuestieDB
	https://raw.githubusercontent.com/Questie/QuestieDB/master/data/MoP/mopItemDB.lua
]]
