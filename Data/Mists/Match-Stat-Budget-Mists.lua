local _, ns = ...

-- [statToken] = cost of one point in primary-stat points
ns.Data.STAT_BUDGET = {
	SPELL_POWER = 0.86,
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- What one point of each stat costs on an item, in primary-stat points, so a weight
	  multiplies something comparable. A stat not listed here costs 1. Read by
	  Features/Match-Derivations.lua.
	- Mists prices its ratings like its primaries. Since Cataclysm a point of haste, mastery,
	  hit, expertise, crit or Spirit costs an item what a point of Agility does, so none needs a
	  row. Attack power left armor in Cataclysm and MP5 in Mists.
	- Spell Power survives on caster weapons only, where it is the weapon's damage rather than
	  its stat budget. 0.86 is Wrath's price and the number to check against a Bag Scan of a
	  real Mists staff.
	- Keyed by stat token, which no client API looks up, so Validate Data counts the rows only.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
