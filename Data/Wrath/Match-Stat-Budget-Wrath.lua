local _, ns = ...

--[[
	What one point of each stat costs on an item, in primary-stat points, so a weight multiplies
	something comparable. A stat not listed here costs 1. Ratings cost about a point of primary
	stat each, and 3.0 folded healing, spell damage and the schools into Spell Power.
]]
ns.Data.STAT_BUDGET = {
	ATTACK_POWER = 0.5,
	RANGED_AP = 0.4,
	FERAL_AP = 0.4,
	SPELL_POWER = 0.86,
	MP5 = 2.5,
}
