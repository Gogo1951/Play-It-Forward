--[[
	The four consumable switches: Food, Drink, Potions and Scrolls.

	The food table splits across two of them. What restores mana is drink, and what restores
	both is food and drink at once, so it stays listed while either switch is on. Turning a
	whole kind off has to hold back exactly that kind, with its own reject code, and nothing else.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- The first row of a data table whose fourth field matches, or any row when wanted is nil.
local function row(rows, wanted)
	for _, candidate in ipairs(rows) do
		if wanted == nil or candidate[4] == wanted then
			return candidate
		end
	end
end

-- One backpack slot holding the row's item, at a level and gap that list it on its merits.
local function backpack(ns, data)
	local Stub = Harness.Stub
	Stub.playerLevel = 60
	ns.db.profile.consumableLevelGap = 0
	local def = Stub.Item({ id = data[1], name = "Kind Test", quality = 1, classID = 0, bindType = 0 })
	Stub.SetBackpack({ def })
end

--------------------------------------------------------------------------------

test("every kind starts on", function()
	local ns = load()
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		equal(ns.db.profile.consumableKinds[kind], true, kind .. " is on by default")
	end
end)

test("with Drink off, water is held back as KIND_DISABLED", function()
	local ns = load()
	local water = row(ns.Data.FOOD_AND_WATER, "MANA")
	check(water ~= nil, "there is a drink to test with")
	backpack(ns, water)

	equal(#ns.Scanner:Scan(), 1, "listed while Drink is on")
	ns.db.profile.consumableKinds.DRINK = false
	local record, reason = ns.Scanner:Classify(0, 1)
	equal(record, nil, "not listed with Drink off")
	equal(reason, ns.Scanner.REJECT.KIND_DISABLED, "and the reason says why")

	ns.db.profile.consumableKinds.DRINK = true
	equal(#ns.Scanner:Scan(), 1, "listed again once Drink is back on")
end)

test("Drink off leaves food alone", function()
	local ns = load()
	local meal = row(ns.Data.FOOD_AND_WATER, "HEALTH")
	backpack(ns, meal)

	ns.db.profile.consumableKinds.DRINK = false
	equal(#ns.Scanner:Scan(), 1, "food still listed")
	ns.db.profile.consumableKinds.FOOD = false
	equal(#ns.Scanner:Scan(), 0, "until Food goes off too")
end)

test("a food that restores mana too stays while either Food or Drink is on", function()
	local ns = load()
	local both = row(ns.Data.FOOD_AND_WATER, "BOTH")
	check(both ~= nil, "there is a food that restores both")
	backpack(ns, both)

	ns.db.profile.consumableKinds.FOOD = false
	equal(#ns.Scanner:Scan(), 1, "listed with only Drink on")
	ns.db.profile.consumableKinds.FOOD = true
	ns.db.profile.consumableKinds.DRINK = false
	equal(#ns.Scanner:Scan(), 1, "listed with only Food on")
	ns.db.profile.consumableKinds.FOOD = false
	equal(#ns.Scanner:Scan(), 0, "held back with both off")
end)

test("potions and scrolls each follow their own switch", function()
	local ns = load()
	local potion = row(ns.Data.POTIONS)
	local scroll = row(ns.Data.SCROLLS)

	backpack(ns, potion)
	ns.db.profile.consumableKinds.SCROLL = false
	equal(#ns.Scanner:Scan(), 1, "a potion ignores the Scrolls switch")
	ns.db.profile.consumableKinds.POTION = false
	equal(#ns.Scanner:Scan(), 0, "and answers to its own")

	ns.db.profile.consumableKinds.POTION = true
	backpack(ns, scroll)
	equal(#ns.Scanner:Scan(), 0, "a scroll is held back with Scrolls off")
	ns.db.profile.consumableKinds.SCROLL = true
	equal(#ns.Scanner:Scan(), 1, "and listed once it is back on")
end)

test("Include Consumables off still wins over every kind", function()
	local ns = load()
	backpack(ns, row(ns.Data.POTIONS))
	ns.db.profile.includeConsumables = false
	local _, reason = ns.Scanner:Classify(0, 1)
	equal(reason, ns.Scanner.REJECT.CONSUMABLES_DISABLED, "the parent switch is checked first")
end)
