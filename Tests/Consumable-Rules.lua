--[[
	Who a potion goes to.

	Consumables were never prioritised at all: every class the potion could be used by
	was in contention, so a healing potion was as likely to reach a mage as a warrior.
	The two rules here are the same shape as the gear ones in Tests/Item-Rules.lua --
	they set who is in contention and leave everybody else admitted behind them.

	POTIONS, NOT FOOD, and that distinction is the whole care in this file.
	Data/Food-And-Water.lua holds 42 things that restore mana, and all of them are
	water. A rule reading only "restores mana" would put mages behind priests for water,
	when a mage drinks more of it than anybody in the game.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- A consumable record as the scanner builds one, without needing a bag behind it.
local function consumable(restores, form)
	return {
		kind = "consumable",
		link = "|cffffffff|Hitem:1234::::::|h[Test Consumable]|h|r",
		name = "Test Consumable",
		count = 1,
		def = { id = 1234, quality = 1, useLevel = 5, restores = restores, form = form },
	}
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

--------------------------------------------------------------------------------

test("a healing potion is for warriors and rogues", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(consumable("HEALTH", "POTION"))

	equal(sorted(verdict.contenders), "ROGUE WARRIOR", "the two classes with no way to heal themselves")
	check(contains(verdict.admitted, "MAGE"), "a mage is still admitted behind them")
	equal(verdict.state, ns.Matcher.GIFT, "and it is still giftable")
end)

--[[
	Alliance on Era, so there is no shaman to name. The rule lists one and the class
	filter drops it, which is the same thing that happens to a gear rule naming a class
	this client cannot have.
]]
test("a mana potion is for the healers and hybrids", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(consumable("MANA", "POTION"))

	equal(sorted(verdict.contenders), "DRUID PALADIN PRIEST", "the classes that drink them mid-fight")
	check(contains(verdict.admitted, "MAGE"), "a mage is still admitted")
	check(contains(verdict.admitted, "WARLOCK"), "and a warlock")
end)

test("a shaman is named for mana potions where one can exist", function()
	local ns = load()
	UnitFactionGroup = function()
		return "Horde"
	end
	local verdict = ns.Matcher:Verdict(consumable("MANA", "POTION"))

	check(contains(verdict.contenders, "SHAMAN"), "a Horde shaman contends: " .. sorted(verdict.contenders))
	check(not contains(verdict.contenders, "PALADIN"), "and there is no Horde paladin to name")
end)

--[[
	A rejuvenation potion restores both. Only mana users are eligible for it at all, so
	the healing rule cannot apply and the mana rule is the one that should.
]]
test("a potion restoring both follows the mana rule", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(consumable("BOTH", "POTION"))

	check(contains(verdict.contenders, "PRIEST"), "a priest contends")
	check(not contains(verdict.contenders, "WARRIOR"), "and a warrior was never eligible for it")
end)

--------------------------------------------------------------------------------

--[[
	The reason the rules name a form. Water restores mana and is not a potion.
]]
test("water is not a mana potion", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(consumable("MANA", "FOOD"))

	check(contains(verdict.contenders, "MAGE"), "a mage competes for water like everybody else")
	check(contains(verdict.contenders, "PRIEST"), "alongside the priest")
	check(#verdict.contenders > 4, "no rule narrowed it: " .. sorted(verdict.contenders))
end)

test("food is not a healing potion", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(consumable("HEALTH", "FOOD"))

	check(contains(verdict.contenders, "MAGE"), "everybody still eats")
	check(#verdict.contenders > 4, "no rule narrowed it: " .. sorted(verdict.contenders))
end)

--------------------------------------------------------------------------------

--[[
	End to end, through the scanner, because the rules read a field the scanner has to
	put on the record. Hand-built fixtures above would pass whether or not it does.
]]
test("the scanner records whether a consumable is a potion", function()
	local ns = load()

	local potion, water
	for _, row in ipairs(ns.Data.Potions) do
		if row[4] == "HEALTH" and row[3] <= 30 and not potion then
			potion = row
		end
	end
	for _, row in ipairs(ns.Data.FoodAndWater) do
		if row[4] == "MANA" and row[3] <= 30 and not water then
			water = row
		end
	end
	check(potion and water, "the data has both to test with")

	Stub.SetBackpack({
		Stub.Item({ id = potion[1], name = "A Potion", quality = 1, classID = 0, subclassID = 1, bindType = 0 }),
		Stub.Item({ id = water[1], name = "Some Water", quality = 1, classID = 0, subclassID = 0, bindType = 0 }),
	})

	local byName = {}
	for _, item in ipairs(ns.Scanner:Scan()) do
		byName[item.name] = item
	end

	equal(byName["A Potion"] and byName["A Potion"].def.form, "POTION", "the potion knows it is one")
	equal(byName["Some Water"] and byName["Some Water"].def.form, "FOOD", "and the water knows it is not")
end)

test("a real healing potion off the scanner reaches warriors and rogues", function()
	local ns = load()

	local potion
	for _, row in ipairs(ns.Data.Potions) do
		if row[4] == "HEALTH" and row[3] <= 30 and not potion then
			potion = row
		end
	end
	Stub.SetBackpack({
		Stub.Item({ id = potion[1], name = "A Potion", quality = 1, classID = 0, subclassID = 1, bindType = 0 }),
	})

	local scanned = ns.Scanner:Scan()
	equal(#scanned, 1, "the potion scanned")
	equal(sorted(ns.Matcher:Verdict(scanned[1]).contenders), "ROGUE WARRIOR", "and the rule reached it")
end)
