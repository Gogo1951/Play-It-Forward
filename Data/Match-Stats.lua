local _, ns = ...

--[[
	Written per talent tree and summed into per-class tables below. A class with no entry for a
	stat scores zero on it.

	THE RECIPIENT'S SPEC IS UNKNOWABLE, so every tree is read as the player levelling it. A
	protection warrior levels on Strength like the other two; nobody levels on Defense, and
	defensive gear gets sharded rather than mailed. Defense, dodge, parry, block and resistances
	are parsed and reported but weighted for nobody.

	THE ONE EXCEPTION is healing, which keeps its trees as healers: otherwise +Healing gear has no
	owner at all. Priests have two healing trees to everybody else's one, so healing gear
	leans priest, and Data/Match-Rules.lua makes cloth healing gear theirs outright.

	THE POINTS. Per tree, a stat it builds around is main (2) and a stat that helps it is useful
	(1). Three trees make a class weight of 0 to 6: Agility is main in all three rogue trees and
	sums to 6, Attack Power useful in all three sums to 3.

	THE RULE: useful means the tree gears for it, never that it merely benefits. Every class
	likes Stamina, which is why weighting it for all of them would say nothing about who an item
	is for. A binned suffix is a parse failure, not this rule.

	SPELL_POWER IS DERIVED, never listed. It is the unified "damage and healing" line, so a tree
	takes the better of its SPELL_DAMAGE and HEALING points for it.

	THE SCALE. A number means nothing on its own: Matcher buckets on claim >= bestClaim *
	CLASS_SHARE, putting the line at 2.1 against a 6.

	  6   every tree builds on it
	  4   two trees build on it (shaman and druid Intellect)
	  3   ABOVE the line: enters the top bucket, level proximity decides
	  2   BELOW the line: admitted and offered, never outranks a 6
	  1   admitted, effectively last

	The gap between 2 and 3 is one point and it is categorical: at 2 a warrior is a fallback on
	an Agility ring, at 3 he takes it off the rogue whenever he is a level closer. Tests/ pins
	the scale to CLASS_SHARE so an edit that crosses the line fails loudly. Two sums the trees
	would otherwise reach are held at 2 for exactly that reason; each says so where it sits.

	RAW TOOLTIP NUMBERS ARE NOT COMPARABLE, so nothing here is multiplied by one directly: "+1%
	hit" reads as 1 beside "+10 Strength". ns.Data.STAT_BUDGET, in each flavor folder, converts
	every stat to what it costs on an item first.
]]
local MAIN, USEFUL = 2, 1

local MELEE = { "ATTACK_POWER", "CRIT", "HIT" }

local function with(list, ...)
	local out = { ... }
	for _, stat in ipairs(list) do
		out[#out + 1] = stat
	end
	return out
end

ns.Data.TALENT_TREES = {
	WARRIOR = {
		Arms = { main = { "STRENGTH" }, useful = with(MELEE, "AGILITY") },
		Fury = { main = { "STRENGTH" }, useful = with(MELEE, "AGILITY") },
		Protection = { main = { "STRENGTH" }, useful = MELEE },
	},
	--[[
		Strength is one Attack Power to a rogue against an Agility's one plus crit, so it is useful
		to two trees and no more. A third would put him at 3, in contention for every Strength ring.
	]]
	ROGUE = {
		Assassination = { main = { "AGILITY" }, useful = with(MELEE, "STRENGTH") },
		Combat = { main = { "AGILITY" }, useful = with(MELEE, "STRENGTH") },
		Subtlety = { main = { "AGILITY" }, useful = MELEE },
	},
	--[[
		Generic Attack Power counts toward ranged in Classic, so it is useful beside the ranged kind.
		Intellect for the two mana-hungry trees only, held at 2: a 3 would put a hunter in
		contention for every Intellect cloak a mage wants.
	]]
	HUNTER = {
		BeastMastery = { main = { "AGILITY" }, useful = with(MELEE, "RANGED_AP", "INTELLECT") },
		Marksmanship = { main = { "AGILITY" }, useful = with(MELEE, "RANGED_AP", "INTELLECT") },
		Survival = { main = { "AGILITY" }, useful = with(MELEE, "RANGED_AP") },
	},
	PALADIN = {
		Holy = { main = { "INTELLECT", "HEALING" }, useful = { "MP5", "SPELL_CRIT" } },
		Protection = { main = { "STRENGTH" }, useful = { "ATTACK_POWER", "SPELL_DAMAGE", "HOLY" } },
		Retribution = { main = { "STRENGTH" }, useful = with(MELEE, "AGILITY") },
	},
	--[[
		SPIRIT STAYS AT 2, though Shadow levels on Spirit Tap and would make it 3. At 3 a priest
		enters contention for "of the Boar", Strength and Spirit, on a ring or a cloak, and takes it
		off the warrior on level proximity with the Strength half dead on him.
	]]
	PRIEST = {
		Discipline = { main = { "INTELLECT", "HEALING" }, useful = { "SPIRIT", "MP5", "SPELL_CRIT", "HOLY" } },
		Holy = { main = { "INTELLECT", "HEALING" }, useful = { "SPIRIT", "MP5", "SPELL_CRIT", "HOLY" } },
		Shadow = { main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" }, useful = { "SPELL_HIT" } },
	},
	SHAMAN = {
		Elemental = {
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "MP5", "NATURE" },
		},
		Enhancement = { main = { "STRENGTH" }, useful = with(MELEE, "AGILITY") },
		Restoration = { main = { "INTELLECT", "HEALING" }, useful = { "MP5", "SPELL_CRIT" } },
	},
	MAGE = {
		Arcane = { main = { "INTELLECT", "SPELL_DAMAGE" }, useful = { "SPELL_CRIT", "SPELL_HIT", "ARCANE" } },
		Fire = { main = { "INTELLECT", "SPELL_DAMAGE", "FIRE" }, useful = { "SPELL_CRIT", "SPELL_HIT" } },
		Frost = { main = { "INTELLECT", "SPELL_DAMAGE", "FROST" }, useful = { "SPELL_CRIT", "SPELL_HIT" } },
	},
	--[[
		STAMINA STAYS AT 2, useful to the two trees that tap hardest. Life Tap is the only thing that
		converts Stamina into throughput, but it sits on most items in the game: at 3 a warlock
		enters contention for Agility and Strength rolls he can use half of and takes them off
		rogues and warriors on level proximity.
	]]
	WARLOCK = {
		Affliction = { main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" }, useful = { "SPELL_HIT", "STAMINA" } },
		Demonology = { main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" }, useful = { "SPELL_HIT", "STAMINA" } },
		Destruction = {
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_HIT", "SPELL_CRIT", "FIRE" },
		},
	},
	-- One feral tree covers cat and bear, levelled as cat: Strength and Agility are both main.
	DRUID = {
		Balance = {
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "ARCANE", "NATURE" },
		},
		Feral = { main = { "STRENGTH", "AGILITY", "FERAL_AP" }, useful = MELEE },
		Restoration = { main = { "INTELLECT", "HEALING" }, useful = { "SPIRIT", "MP5", "SPELL_CRIT" } },
	},
	DEATHKNIGHT = {
		Blood = { main = { "STRENGTH" }, useful = MELEE },
		Frost = { main = { "STRENGTH" }, useful = MELEE },
		Unholy = { main = { "STRENGTH" }, useful = MELEE },
	},
}

--[[
	DELIBERATELY EMPTY, and putting a stat here is a trap: a weight landing on every class means
	every class scores something on every item. Stamina at 0.5 for all gives a mage 2.5 on an
	agility cloak, none of it from the agility, and compresses the deliberate 3:1 rogue-to-druid
	Agility gap to roughly 2:1. Anything added here is a tiebreaker only; SpecScore excludes it.
]]
ns.Data.UNIVERSAL_WEIGHTS = {}

ns.Data.STAT_WEIGHTS = {}

-- A stat listed as both main and useful in one tree counts once, as main.
local function treePoints(tree)
	local points = {}
	for _, stat in ipairs(tree.useful or {}) do
		points[stat] = USEFUL
	end
	for _, stat in ipairs(tree.main or {}) do
		points[stat] = MAIN
	end
	points.SPELL_POWER = math.max(points.SPELL_DAMAGE or 0, points.HEALING or 0)
	return points
end

for class, trees in pairs(ns.Data.TALENT_TREES) do
	local weights = {}
	for _, tree in pairs(trees) do
		for stat, points in pairs(treePoints(tree)) do
			if points > 0 then
				weights[stat] = (weights[stat] or 0) + points
			end
		end
	end
	ns.Data.STAT_WEIGHTS[class] = weights
end

for _, weights in pairs(ns.Data.STAT_WEIGHTS) do
	for stat, value in pairs(ns.Data.UNIVERSAL_WEIGHTS or {}) do
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

-- The share of the best class's claim another must reach to compete. See THE SCALE at the top.
ns.Data.CLASS_SHARE = 0.35

--[[
	A best score below this sends an item to the vendor pile. Deliberately near the floor: the
	job is to catch an item nobody scores at all, and a higher bar bins real low-level gear.
]]
ns.Data.LEFTOVER_THRESHOLD = 1.0
