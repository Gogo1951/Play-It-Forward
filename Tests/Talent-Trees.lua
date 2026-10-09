--[[
	Class weights summed from talent trees, and the budget that makes every stat count.

	Data/Match-Stats.lua writes each tree as the player levelling it: a stat it builds
	around is worth 2, one that helps it 1, and three trees sum to a class weight of 0 to
	6. The cases below pin the sums worth pinning, then the reason the budget exists --
	a Classic "+1% hit" reads as 1 beside "+10 Strength", and before the conversion hit
	could weigh anything at all and still never decide an item.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load(flavor)
	Stub.flavor = flavor or "Vanilla"
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT)
	Stub.flavor = "Vanilla"
	assert(ok, ns)
	return ns
end

local function contains(list, wanted)
	for _, value in ipairs(list) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function sorted(list)
	local out = {}
	for index, value in ipairs(list) do
		out[index] = value
	end
	table.sort(out)
	return table.concat(out, " ")
end

local function gear(ns, fields)
	local def = Stub.Item({
		name = fields.name or "Test Item",
		quality = 2,
		reqLevel = fields.reqLevel or 20,
		itemLevel = (fields.reqLevel or 20) + 4,
		equipLoc = fields.equipLoc or "INVTYPE_CHEST",
		classID = fields.classID or 4,
		subclassID = fields.subclassID or 1, -- cloth
		bindType = 2,
		stats = fields.stats,
	})
	return assert(ns.Scanner:Describe(def.link), "fixture did not describe")
end

--------------------------------------------------------------------------------
-- The sums
--------------------------------------------------------------------------------

test("a stat every tree builds on sums to the top of the scale", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.ROGUE.AGILITY, 6, "rogue agility")
	equal(weights.HUNTER.AGILITY, 6, "hunter agility")
	equal(weights.WARRIOR.STRENGTH, 6, "warrior strength, protection levelling on it too")
	equal(weights.MAGE.INTELLECT, 6, "mage intellect")
end)

test("no class sums past six on any stat", function()
	local ns = load()
	for class, weights in pairs(ns.Data.STAT_WEIGHTS) do
		for stat, points in pairs(weights) do
			check(points <= 6, ("%s %s is %d"):format(class, stat, points))
		end
	end
end)

--[[
	Attack Power used to sit at 6 beside the Agility it is worth half of. Useful to every
	melee tree, it is 3 for all three physical classes, so a plain Attack Power ring is
	still all of theirs and level proximity picks.
]]
test("attack power is useful to every melee tree, never main", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	for _, class in ipairs({ "WARRIOR", "ROGUE", "HUNTER" }) do
		equal(weights[class].ATTACK_POWER, 3, class .. " attack power")
		equal(weights[class].CRIT, 3, class .. " crit")
		equal(weights[class].HIT, 3, class .. " hit")
	end
end)

test("a feral druid builds on strength and on feral attack power, and nobody else does", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.DRUID.STRENGTH, 2, "druid strength")
	equal(weights.DRUID.FERAL_AP, 2, "druid feral attack power")
	for class, classWeights in pairs(weights) do
		if class ~= "DRUID" then
			equal(classWeights.FERAL_AP, nil, class .. " has no feral attack power")
		end
	end
end)

-- Nobody levels on Defense; defensive gear is sharded, not mailed.
test("defensive stats are weighted for nobody", function()
	local ns = load()
	for class, weights in pairs(ns.Data.STAT_WEIGHTS) do
		for _, stat in ipairs({ "DEFENSE", "DODGE", "PARRY", "BLOCK" }) do
			equal(weights[stat], nil, class .. " " .. stat)
		end
	end
end)

test("priests carry two healing trees to everybody else's one", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.PRIEST.HEALING, 4, "priest healing")
	for _, class in ipairs({ "PALADIN", "SHAMAN", "DRUID" }) do
		equal(weights[class].HEALING, 2, class .. " healing")
	end
	equal(weights.MAGE.HEALING, nil, "a mage heals nothing")
end)

-- Derived, never listed: a tree takes the better of its damage and healing points.
test("spell power is the better of damage and healing per tree", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.PRIEST.SPELL_POWER, 6, "priest: two healing trees and a shadow one")
	equal(weights.PALADIN.SPELL_POWER, 3, "paladin: holy heals, protection helps on damage")
	equal(weights.SHAMAN.SPELL_POWER, 4, "shaman: elemental and restoration")
	equal(weights.WARRIOR.SPELL_POWER, nil, "a warrior none")
end)

--------------------------------------------------------------------------------
-- The budget
--------------------------------------------------------------------------------

test("classic percentages are converted, tbc ratings are not", function()
	local classic = load("Vanilla")
	equal(classic.Data.StatPoints("CRIT", 1), 14, "1% crit on Era")
	equal(classic.Data.StatPoints("STRENGTH", 10), 10, "a primary stat is itself")
	equal(classic.Data.StatPoints("ATTACK_POWER", 20), 10, "attack power is half a primary")

	local tbc = load("TBC")
	equal(tbc.Data.StatPoints("CRIT", 14), 14, "14 crit rating on TBC")
end)

--[[
	THE REASON FOR THE BUDGET. Read raw, the 1 of "+1% hit" was a sixteenth of this item
	and the warlock took it as a bare Stamina roll. Converted, the hit is more than half of
	it, so the melee classes it was written for use most of it and he uses less than half.
]]
test("a stamina and hit roll is not a warlock's stamina item", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Ring of Precision",
		equipLoc = "INVTYPE_FINGER",
		subclassID = 0,
		stats = { ITEM_MOD_STAMINA_SHORT = 8, ITEM_MOD_HIT_RATING_SHORT = 1 },
	}))

	check(not contains(verdict.contenders, "WARLOCK"), "no warlock in contention")
	check(contains(verdict.contenders, "ROGUE"), "the rogue competes for it")
	check(contains(verdict.admitted, "WARLOCK"), "and the warlock is still a fallback")
end)

--[[
	Mana regeneration is the healer's half of a caster roll. Four MP5 costs an item ten
	points beside six Intellect, so a mage uses well under half of it.
]]
test("intellect and mp5 cloth leans to the healers", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Robe of Meditation",
		stats = { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_MANA_REGENERATION_SHORT = 4 },
	}))

	check(contains(verdict.contenders, "PRIEST"), "the priest uses all of it")
	check(not contains(verdict.contenders, "MAGE"), "the mage does not compete")
	check(contains(verdict.admitted, "MAGE"), "but can still receive it")
end)

--------------------------------------------------------------------------------
-- Healing gear
--------------------------------------------------------------------------------

test("cloth healing gear is the priest's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Robe of Healing",
		stats = { ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18 },
	}))

	equal(sorted(verdict.contenders), "PRIEST", "the priest leads alone")
	check(contains(verdict.admitted, "DRUID"), "a druid is still a fallback")
end)

test("leather healing gear is not handed to a priest", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Jerkin of Healing",
		subclassID = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18 },
	}))

	check(contains(verdict.contenders, "DRUID"), "the druid competes for leather")
end)

test("a healing cloak is any healer's, though cloaks are cloth", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Cloak of Healing",
		equipLoc = "INVTYPE_CLOAK",
		stats = { ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18 },
	}))

	check(contains(verdict.contenders, "PRIEST"), "the priest competes")
	check(contains(verdict.contenders, "DRUID"), "and so does the druid")
end)

--------------------------------------------------------------------------------
-- Feral attack power
--------------------------------------------------------------------------------

test("form-only attack power parses as feral, not as plain attack power", function()
	local ns = load()
	local stats = ns.Tooltip:StatsFromLines({
		"Item Name",
		"Equip: Increases attack power by 140 in Cat, Bear, Dire Bear, and Moonkin forms only.",
	})

	equal(stats.FERAL_AP, 140, "feral attack power")
	equal(stats.ATTACK_POWER, nil, "and not the rogue's kind")
end)

test("a feral staff goes to the druid", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, {
		name = "Staff of the Wild",
		equipLoc = "INVTYPE_2HWEAPON",
		classID = 2,
		subclassID = 10,
		stats = { ITEM_MOD_FERAL_ATTACK_POWER_SHORT = 60, ITEM_MOD_STRENGTH_SHORT = 6 },
	}))

	equal(verdict.best, "DRUID", "the druid uses all of it")
end)

--------------------------------------------------------------------------------
-- Weapons by expansion
--------------------------------------------------------------------------------

test("classic weapon training holds on era and tbc", function()
	for _, flavor in ipairs({ "Vanilla", "TBC", "Camelot" }) do
		local ns = load(flavor)
		equal(ns.Data.WeaponPriorityFor("1H_AXE", "ROGUE"), nil, flavor .. ": no rogue axes")
		equal(ns.Data.WeaponPriorityFor("POLEARM", "DRUID"), nil, flavor .. ": no druid polearms")
		check(ns.Data.WeaponPriorityFor("BOW", "WARRIOR") ~= nil, flavor .. ": a warrior carries a bow")
	end
end)

test("wrath gives rogues axes and druids polearms", function()
	local ns = load("Wrath")
	equal(ns.Data.WeaponPriorityFor("1H_AXE", "ROGUE"), 3, "one rogue tree")
	equal(ns.Data.WeaponPriorityFor("POLEARM", "DRUID"), 3, "one druid tree")
	check(ns.Data.WeaponPriorityFor("BOW", "WARRIOR") ~= nil, "the ranged slot is still there")
end)

test("mists takes the ranged slot away from warriors and rogues", function()
	local ns = load("Mists")
	for _, key in ipairs({ "BOW", "GUN", "CROSSBOW", "THROWN" }) do
		equal(ns.Data.WeaponPriorityFor(key, "WARRIOR"), nil, "warrior " .. key)
		equal(ns.Data.WeaponPriorityFor(key, "ROGUE"), nil, "rogue " .. key)
	end
	check(ns.Data.WeaponPriorityFor("BOW", "HUNTER") ~= nil, "the hunter keeps his bow")
	equal(ns.Data.WeaponPriorityFor("1H_AXE", "ROGUE"), 3, "and Wrath's changes still hold")
end)
