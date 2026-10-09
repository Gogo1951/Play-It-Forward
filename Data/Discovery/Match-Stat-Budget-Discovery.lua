local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

--[[
	What one point of each stat costs on an item, in primary-stat points, so a weight multiplies
	something comparable. Data/Match-Stats.lua says who wants a stat; this says how much of the
	item it is. A stat not listed here costs 1.

	CLASSIC WRITES PERCENTAGES. "Improves your chance to hit by 1%" reads as 1, and that 1% costs
	an item about what ten Strength does. Without the conversion a hit weight of 3 adds 3 beside
	the 60 its Strength brings, and hit never decides anything.

	Approximate by design: the job is "is this a lot of the item or a little", never a sim.
]]
ns.Data.STAT_BUDGET = {
	ATTACK_POWER = 0.5,
	RANGED_AP = 0.4,
	FERAL_AP = 0.4,

	SPELL_POWER = 0.86,
	SPELL_DAMAGE = 0.86,
	HEALING = 0.45,
	-- One school is part of a spellbook, so it costs less than damage to all of them.
	ARCANE = 0.7,
	FIRE = 0.7,
	FROST = 0.7,
	NATURE = 0.7,
	SHADOW = 0.7,
	HOLY = 0.7,
	MP5 = 2.5,

	-- Per 1%.
	HIT = 10,
	CRIT = 14,
	SPELL_HIT = 8,
	SPELL_CRIT = 14,
}
