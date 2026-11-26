--[[
	Who wants which stat. Spirit is weighted so "of the Whale" reaches a leveling priest. That moves
	more than the score: Matcher:Coverage measures a class against every stat some class ranks, so
	Spirit ranking at all changes who competes on every item carrying it.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Built through Scanner:Describe, so stats normalize exactly as a real bag scan does.
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
-- The scale
--------------------------------------------------------------------------------

--[[
	Pins Features/Match-Derivations.lua's THE SCALE: a secondary 2 and a competes 3 sit either side
	of ns.Data.CLASS_SHARE's 2.1 admission line against a primary 6. Read off ns.Data, so moving a
	constant fails here rather than quietly rerouting every item.
]]
test("the point scale straddles the contention line", function()
	local ns = load()
	local PRIMARY, SECONDARY, COMPETES = 6, 2, 3
	local line = PRIMARY * ns.Data.CLASS_SHARE

	check(SECONDARY < line, ("a secondary %d sits below the line at %.2f"):format(SECONDARY, line))
	check(COMPETES >= line, ("a competes %d reaches it"):format(COMPETES))
end)

--[[
	The same boundary on a real pair: the rogue builds on Agility, the warrior takes it as a
	secondary. The weights are asserted too, so an edit to either cannot leave this passing.
]]
test("a secondary weight is admitted but never in contention against a primary", function()
	local ns = load()
	equal(ns.Data.STAT_WEIGHTS.ROGUE.AGILITY, 6, "the rogue's primary")
	-- Fury alone gears for it; Arms ships off.
	equal(ns.Data.STAT_WEIGHTS.WARRIOR.AGILITY, 1, "the warrior's secondary")

	local verdict = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_AGILITY_SHORT = 8 }))

	check(contains(verdict.contenders, "ROGUE"), "the rogue competes")
	check(contains(verdict.admitted, "WARRIOR"), "the warrior is admitted, so the item still reaches him")
	check(not contains(verdict.contenders, "WARRIOR"), "but never ahead of the rogue")
end)

--------------------------------------------------------------------------------
-- The weights themselves
--------------------------------------------------------------------------------

--[[
	Two of a priest's three trees heal on Spirit, and a druid's Restoration tree is the one of its
	three that does. Turning the druid's other trees off does not triple it: Spirit is a secondary.
]]
test("priests rank spirit above druids", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.PRIEST.SPIRIT, 2, "priest spirit weight")
	equal(weights.DRUID.SPIRIT, 1, "restoration druid spirit weight")
end)

test("spirit does not leak to classes that do not want it", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	for _, class in ipairs({ "WARRIOR", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "PALADIN", "SHAMAN" }) do
		equal(weights[class].SPIRIT, nil, class .. " has no spirit weight")
	end
end)

test("only warlocks rank stamina", function()
	local ns = load()
	local weights = ns.Data.STAT_WEIGHTS

	equal(weights.WARLOCK.STAMINA, 2, "warlock stamina weight")
	for _, class in ipairs({ "WARRIOR", "ROGUE", "MAGE", "PRIEST", "HUNTER", "PALADIN", "SHAMAN", "DRUID" }) do
		equal(weights[class].STAMINA, nil, class .. " has no stamina weight")
	end
end)

test("a plain stamina item reaches a warlock instead of the vendor", function()
	local ns = load()
	local item = cloth(ns, { ITEM_MOD_STAMINA_SHORT = 6 }, "Stamina Robe")
	local verdict = ns.Matcher:Verdict(item)

	equal(verdict.state, ns.Matcher.GIFT, "no longer a leftover")
	equal(verdict.best, "WARLOCK", "and it is the warlock's")
end)

--[[
	Why the warlock's Stamina weight is 2, not 3: Stamina is on most items, so at 3 he competes for
	Agility and Strength rolls he cannot use and takes them on level proximity. At 2 he stays below
	classShare's line, and a plain Stamina green is still his alone.
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
	check(contains(bear, "DRUID"), "a feral druid, the nearest strength wearer to cloth, competes for it")
end)

-- Tests/Item-Rules.lua owns Intellect and Spirit; below is coverage on combinations no rule names.

--[[
	Coverage leaves Stamina out: it is on most items, and counting it would put a mage at half of
	the commonest caster suffix. The warlock, who weighs Stamina too, is still the best fit.
]]
test("of the Eagle is every intellect class's, best for a warlock", function()
	local ns = load()
	local eagle = cloth(ns, { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_STAMINA_SHORT = 6 }, "Robe of the Eagle")
	local verdict = ns.Matcher:Verdict(eagle)

	equal(verdict.best, "WARLOCK", "the warlock uses all of it")
	check(contains(verdict.contenders, "MAGE"), "the mage competes for it")
	check(contains(verdict.contenders, "PRIEST"), "and so does the priest")
end)

-- Spirit is weighted so it can admit somebody, which only a class's own claim does.
test("spirit is a class weight", function()
	local ns = load()
	local item = cloth(ns, { ITEM_MOD_SPIRIT_SHORT = 5 })
	check(ns.Matcher:SpecScore(item, "PRIEST") > 0, "so a priest has a real claim on spirit")
end)

--------------------------------------------------------------------------------
-- Where the items go
--------------------------------------------------------------------------------

test("of the Whale reaches a priest instead of the vendor", function()
	local ns = load()
	local whale = cloth(ns, { ITEM_MOD_STAMINA_SHORT = 4, ITEM_MOD_SPIRIT_SHORT = 4 }, "Robe of the Whale")
	local verdict = ns.Matcher:Verdict(whale)

	equal(verdict.state, ns.Matcher.GIFT, "no longer a leftover")
	equal(verdict.best, "PRIEST", "and it is the priest's")
	check(contains(verdict.admitted, "DRUID"), "a druid can still receive it")
	check(not contains(verdict.admitted, "MAGE"), "a mage cannot: he scores nothing on it")
end)

-- Weighting Spirit must not touch an item carrying none; coverage is where that could go wrong.

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
