--[[
	Who wants which stat, and what that does to where an item goes.

	Spirit used to score nothing for anybody. That was a deliberate choice and it had a
	consequence the author wanted changed: "of the Whale", Stamina and Spirit, scored
	zero for every class in the game and went to the vendor pile, when a levelling
	priest would have worn it.

	Weighting it moves more than the score. Matcher:Coverage measures a class against
	every stat some class ranks, so making Spirit rank at all changes the denominator on
	every item carrying it -- that is the half of this change worth pinning, because it
	decides who competes rather than merely who scores.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	A cloth chest carrying whatever stats a case is about, built through
	Scanner:Describe rather than by hand.

	Describe is the add-on's own path from a link to a scored record, so the fixture
	normalizes stats exactly the way a real bag scan does. The first version of this
	helper copied three ITEM_MOD_* keys across itself and silently dropped every other
	one, which turned an Agility-and-Stamina roll into a pure Stamina item and made a
	case about melee gear quietly test nothing of the sort.
]]
local function cloth(ns, stats, name)
	local def = Stub.Item({
		name = name or "Test Robe",
		reqLevel = 20,
		itemLevel = 20,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1, -- CLOTH
		stats = stats,
	})
	return assert(ns.Scanner:Describe(def.link), "fixture did not describe")
end

local function contains(list, wanted)
	for _, value in ipairs(list) do
		if value == wanted then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- The weights themselves
--------------------------------------------------------------------------------

test("priests rank spirit, and rank it above druids", function()
	local ns = load()
	local weights = ns.Data.StatWeights

	equal(weights.PRIEST.SPIRIT, 2, "priest spirit weight")
	equal(weights.DRUID.SPIRIT, 1, "druid spirit weight")
end)

test("spirit does not leak to classes that do not want it", function()
	local ns = load()
	local weights = ns.Data.StatWeights

	for _, class in ipairs({ "WARRIOR", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "PALADIN", "SHAMAN" }) do
		equal(weights[class].SPIRIT, nil, class .. " has no spirit weight")
	end
end)

test("only warlocks rank stamina", function()
	local ns = load()
	local weights = ns.Data.StatWeights

	equal(weights.WARLOCK.STAMINA, 2, "warlock stamina weight")
	for _, class in ipairs({ "WARRIOR", "ROGUE", "MAGE", "PRIEST", "HUNTER", "PALADIN", "SHAMAN", "DRUID" }) do
		equal(weights[class].STAMINA, nil, class .. " has no stamina weight")
	end
	equal(ns.Data.UniversalWeights.STAMINA, nil, "and it is not universal")
end)

--[[
	The reason for weighting it. A plain Stamina green scored zero for every class in
	the game and went to the vendor; a levelling warlock wears it.
]]
test("a plain stamina item reaches a warlock instead of the vendor", function()
	local ns = load()
	local item = cloth(ns, { ITEM_MOD_STAMINA_SHORT = 6 }, "Stamina Robe")
	local verdict = ns.Matcher:Verdict(item)

	equal(verdict.state, ns.Matcher.GIFT, "no longer a leftover")
	equal(verdict.best, "WARLOCK", "and it is the warlock's")
end)

--[[
	THE REASON THE WEIGHT IS 2 AND NOT 3, pinned so it cannot drift back.

	This file's own scale puts 3 at "competes: ABOVE the line, enters the top bucket"
	and 2 at "secondary: admitted and offered, never outranks a primary". Stamina sits
	on most items in the game, so a warlock crossing that line competes for nearly all
	of them -- measured at 3, he entered contention for Agility and Strength rolls he
	can do nothing with, and took them off rogues and warriors on level proximity.

	At 2 his claim on a two-stat melee roll lands below classShare's boundary and he
	stays out of it. The item the weight was actually for, a plain Stamina green, is
	his either way: he is the only class with any claim on it at all.
]]
test("a warlock does not compete for melee gear that happens to carry stamina", function()
	local ns = load()

	local function contenders(stats, name)
		return ns.Matcher:Verdict(cloth(ns, stats, name)).contenders
	end

	local monkey = contenders({ ITEM_MOD_AGILITY_SHORT = 6, ITEM_MOD_STAMINA_SHORT = 6 }, "Monkey")
	check(not contains(monkey, "WARLOCK"), "no warlock on an agility roll")
	check(contains(monkey, "ROGUE"), "the rogue still competes for it")

	local bear = contenders({ ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_STAMINA_SHORT = 6 }, "Bear")
	check(not contains(bear, "WARLOCK"), "no warlock on a strength roll")
	check(contains(bear, "WARRIOR"), "the warrior still competes for it")
end)

--[[
	The Intellect-and-Spirit case is no longer decided here. Coverage demoted the mage
	off an "of the Owl" roll, because a priest ranks both halves and he ranks one -- and
	Data/Match-Rules.lua now overrules that with "Intellect and Spirit is for priests,
	mages and druids". Tests/Item-Rules.lua owns it; what is left below is the same
	mechanism on a combination no rule names.
]]

--[[
	The side effect that happens at any weight, pinned deliberately. Coverage measures a
	class against every stat some class ranks, so on Intellect-and-Stamina a warlock
	uses both halves and a mage uses one. The mage is demoted out of contention on the
	commonest caster suffix carrying stamina, and stays admitted, so he still receives
	it whenever no warlock is in range.
]]
test("of the Eagle prefers a warlock but is still offered to a mage", function()
	local ns = load()
	local eagle = cloth(ns, { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_STAMINA_SHORT = 6 }, "Robe of the Eagle")
	local verdict = ns.Matcher:Verdict(eagle)

	equal(verdict.best, "WARLOCK", "the warlock uses all of it")
	check(not contains(verdict.contenders, "MAGE"), "the mage uses half, so he is not in contention")
	check(contains(verdict.admitted, "MAGE"), "but he is still offered it")
end)

--[[
	Spirit must stay off ns.Data.UniversalWeights. A weight every class carries is
	excluded from Matcher:SpecScore, so it could never admit anybody -- which is the
	whole reason for weighting spirit in the first place.
]]
test("spirit is a class weight, not a universal one", function()
	local ns = load()
	equal(ns.Data.UniversalWeights.SPIRIT, nil, "not universal")

	local item = cloth(ns, { ITEM_MOD_SPIRIT_SHORT = 5 })
	check(ns.Matcher:SpecScore(item, "PRIEST") > 0, "so a priest has a real claim on spirit")
end)

--------------------------------------------------------------------------------
-- Where the items go
--------------------------------------------------------------------------------

--[[
	The case that prompted the change. Data/Match-Stats.lua used to name this item as
	the pure example of something every class scores zero on.
]]
test("of the Whale reaches a priest instead of the vendor", function()
	local ns = load()
	local whale = cloth(ns, { ITEM_MOD_STAMINA_SHORT = 4, ITEM_MOD_SPIRIT_SHORT = 4 }, "Robe of the Whale")
	local verdict = ns.Matcher:Verdict(whale)

	equal(verdict.state, ns.Matcher.GIFT, "no longer a leftover")
	equal(verdict.best, "PRIEST", "and it is the priest's")
	check(contains(verdict.admitted, "DRUID"), "a druid can still receive it")
	check(not contains(verdict.admitted, "MAGE"), "a mage cannot: he scores nothing on it")
end)

--[[
	The side effect, pinned deliberately rather than discovered later.

	Coverage measures a class against every stat some class ranks. Once spirit ranks,
	a mage uses half of an Intellect-and-Spirit roll where a priest uses all of it, and
	COVERAGE_MAJORITY is strictly greater than half -- so the mage drops out of
	contention on the commonest caster suffix in the game.

	He stays admitted, which is the part that matters: he still receives it when no
	priest is in range, so the item is never stuck for want of the one class.
]]
--[[
	A pure Intellect item must not have moved. Nothing about weighting spirit should
	touch an item that carries none, and coverage is exactly where that could go wrong.
]]
test("an item with no spirit on it is unchanged", function()
	local ns = load()
	local plain = cloth(ns, { ITEM_MOD_INTELLECT_SHORT = 9 }, "Plain Robe")
	local verdict = ns.Matcher:Verdict(plain)

	equal(verdict.state, ns.Matcher.GIFT, "still a gift")
	for _, class in ipairs({ "MAGE", "WARLOCK", "PRIEST" }) do
		check(contains(verdict.contenders, class), class .. " still competes for plain intellect")
	end
end)

--[[
	Of the Boar is Strength and Spirit. The strength half is a warrior's and the spirit
	half is nobody's who can also use the strength, so weighting spirit must not hand a
	melee roll to a priest.
]]
test("of the Boar still belongs to the strength classes", function()
	local ns = load()
	local boar = {
		kind = "gear",
		link = Stub.Item({ name = "Boar Mail", classID = 4, subclassID = 3 }).link,
		name = "Boar Mail",
		quality = 2,
		reqLevel = 40,
		itemLevel = 40,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 3, -- MAIL
		stats = { STRENGTH = 6, SPIRIT = 6 },
	}
	local verdict = ns.Matcher:Verdict(boar)

	check(verdict.best == "WARRIOR" or verdict.best == "PALADIN", "a plate/mail wearer, got " .. tostring(verdict.best))
	check(not contains(verdict.admitted, "PRIEST"), "a priest cannot wear mail at 40 anyway")
end)
