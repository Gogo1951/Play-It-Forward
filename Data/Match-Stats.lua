local _, ns = ...

--[[
	Written as the spec is given, stat -> { CLASS = points }, and inverted into per-class
	tables below. A class with no entry for a stat scores zero on it.

	DELIBERATELY UNWEIGHTED: crit, hit, defense, mp5 and resistances -- parsed and reported, never contributing.

	THE RULE: a stat is weighted for the classes that build on it, never for everyone who merely
	benefits. Every class likes Stamina, which is why weighting it for all of them would say
	nothing about who an item is for. A binned suffix is a parse failure, not this rule.

	THE SCALE. Points run on a 6 scale and a number means nothing on its own: Matcher buckets
	on claim >= bestClaim * CLASS_SHARE, putting the line at 2.1.

	  6   primary    the class's own stat, every spec builds on it
	  4   major      a second archetype genuinely competes for it (paladin Intellect)
	  3   competes   ABOVE the line: enters the top bucket, level proximity decides
	  2   secondary  BELOW the line: admitted and offered, never outranks a primary
	  1   marginal   admitted, effectively last

	The gap between 2 and 3 is one point and it is categorical: at 2 a warrior is a fallback on
	an Agility ring, at 3 he takes it off the rogue whenever he is a level closer. Tests/ pins
	the scale to CLASS_SHARE so an edit that crosses the line fails loudly.
]]
local PRIMARY = {
	-- Hunters carry Intellect because they spend mana in Classic.
	STRENGTH = { WARRIOR = 6, DEATHKNIGHT = 6, PALADIN = 4, ROGUE = 2, SHAMAN = 2 },
	AGILITY = { ROGUE = 6, HUNTER = 6, SHAMAN = 2, DRUID = 2, WARRIOR = 2, PALADIN = 2 },
	INTELLECT = { MAGE = 6, WARLOCK = 6, PRIEST = 6, SHAMAN = 4, DRUID = 4, PALADIN = 2, HUNTER = 2 },
	--[[
		Priest and druid only: their talents convert Spirit into output, not downtime. Never
		above 2 -- a 3 crosses into the top bucket and takes Intellect cloth off casters.
	]]
	SPIRIT = { PRIEST = 2, DRUID = 1 },
	--[[
		Warlock only: Life Tap is the only thing that converts Stamina into throughput.

		SECONDARY, NOT COMPETES. Stamina sits on most items in the game, so at 3 a warlock
		enters contention for Agility and Strength rolls he can use half of and takes them off
		rogues and warriors on level proximity. At 2 he stays under the boundary.
	]]
	STAMINA = { WARLOCK = 2 },
	--[[
		Half a primary per point by the game's own conversion, but kept at 6 for the classes
		whose primary it effectively is, so a plain Attack Power item still reads as theirs.
	]]
	ATTACK_POWER = { ROGUE = 6, HUNTER = 6, WARRIOR = 6, DEATHKNIGHT = 6, PALADIN = 4, DRUID = 2, SHAMAN = 2 },
	-- Hunter only: nothing else scales off ranged attack power.
	RANGED_AP = { HUNTER = 6 },
}

-- 3.0 folded +healing, +spell damage and the per-school bonuses into one stat.
local CASTER_WRATH = {
	SPELL_POWER = { MAGE = 6, WARLOCK = 6, PRIEST = 6, DRUID = 4, SHAMAN = 4, PALADIN = 2 },
}

--[[
	Vanilla and early TBC split the caster stats. SPELL_POWER is the unified "damage and
	healing done by magical spells" line, which already exists on Era items, so it keeps the
	same ranking here as in the Wrath table.
]]
local CASTER_PREWRATH = {
	SPELL_POWER = { MAGE = 6, WARLOCK = 6, PRIEST = 6, DRUID = 4, SHAMAN = 4, PALADIN = 2 },
	HEALING = { PRIEST = 4, PALADIN = 2, DRUID = 2, SHAMAN = 2 },
	SPELL_DAMAGE = { MAGE = 6, WARLOCK = 6, PRIEST = 2, SHAMAN = 2, DRUID = 2 },
	--[[
		A single school only applies to part of a spellbook, so these stay at the marginal tier
		on purpose: a school roll routes to the class that casts it without ever outranking a
		real spell power item.
	]]
	ARCANE = { MAGE = 2, DRUID = 2 },
	FIRE = { MAGE = 2, WARLOCK = 2 },
	FROST = { MAGE = 2 },
	NATURE = { SHAMAN = 2, DRUID = 2 },
	SHADOW = { WARLOCK = 4, PRIEST = 2 },
	HOLY = { PALADIN = 2, PRIEST = 2 },
}

--[[
	DELIBERATELY EMPTY, and putting a stat here is a trap: a weight landing on every class means
	every class scores something on every item. Stamina at 0.5 for all gives a mage 2.5 on an
	agility cloak, none of it from the agility, and compresses the deliberate 3:1 rogue-to-druid
	Agility gap to roughly 2:1. Anything added here is a tiebreaker only; SpecScore excludes it.
]]
ns.Data.UniversalWeights = {}

ns.Data.StatWeights = {}

local function apply(block)
	for stat, byClass in pairs(block) do
		for class, points in pairs(byClass) do
			ns.Data.StatWeights[class] = ns.Data.StatWeights[class] or {}
			ns.Data.StatWeights[class][stat] = points
		end
	end
end

apply(PRIMARY)
apply(ns.isWrathOrLater and CASTER_WRATH or CASTER_PREWRATH)

for _, weights in pairs(ns.Data.StatWeights) do
	for stat, value in pairs(ns.Data.UniversalWeights or {}) do
		weights[stat] = weights[stat] or value
	end
end

-- Keeps a statless weapon out of the leftover pile: itemLevel * WEAPON_BASELINE for any eligible class.
ns.Data.WEAPON_BASELINE = 0.15

--[[
	How much of an item a class must use to count as one of the classes it is for rather than a
	fallback. Compared with Matcher:Coverage, and STRICTLY GREATER: a class using exactly half
	is demoted.

	Scoring alone cannot express "you have to use most of it" because it sums -- on "of the
	Gorilla" a paladin's 16 Strength plus 8 Intellect ties a warrior's 24, and the warrior takes
	it on proximity with half the item dead on him. Half is the bar because Classic's two-stat
	suffixes are near-even splits: one of the pair is 0.5, both is 1.0.
]]
ns.Data.COVERAGE_MAJORITY = 0.5

-- Reduced to the set of ranked stats by ns.Data.ScoreableStats, in Features/Match-Derivations.lua.

-- The share of the best class's claim another must reach to compete. See THE SCALE at the top.
ns.Data.CLASS_SHARE = 0.35

--[[
	A best score below this sends an item to the vendor pile. Deliberately near the floor: the
	job is to catch an item nobody scores at all, and a higher bar bins real low-level gear.
]]
ns.Data.LEFTOVER_THRESHOLD = 1.0
