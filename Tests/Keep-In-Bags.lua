--[[
	Keep in Bags: an amount beside each consumable kind that stays behind. Mail takes a bag slot's
	whole stack, so only whole stacks above the amount are offered, never part of one.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- One stack of the first potion, at a level and gap that list it on its merits.
local function potion(ns, count)
	local Stub = Harness.Stub
	Stub.playerLevel = 60
	ns.db.profile.consumableLevelGap = 0
	local data = ns.Data.POTIONS[1]
	return Stub.Item({ id = data[1], name = "Keep Test", quality = 1, classID = 0, bindType = 0, count = count })
end

local function offeredCounts(items)
	local out = {}
	for _, item in ipairs(items) do
		out[#out + 1] = item.count
	end
	table.sort(out)
	return out
end

--------------------------------------------------------------------------------

test("every kind keeps nothing back by default, on a stop the dropdown offers", function()
	local ns = load()
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		equal(ns.db.profile.keepInBags[kind], 0, kind .. " keeps 0")
	end
	equal(table.concat(ns.Bags.KEEP_ORDER, ","), "0,5,10,20", "the stops on offer")
end)

test("whole stacks only, largest first, while enough stays behind", function()
	local ns = load()
	local function offered(counts, keep)
		local set = ns.Bags.OfferedStacks(counts, keep)
		local out = {}
		for index in pairs(set) do
			out[#out + 1] = index
		end
		table.sort(out)
		return table.concat(out, ",")
	end

	equal(offered({ 5, 3 }, 0), "1,2", "keeping none offers every stack")
	equal(offered({ 5, 3 }, 5), "2", "8 carried, 5 kept: the 3 goes")
	equal(offered({ 20, 5, 3 }, 5), "1,3", "28 carried, 5 kept: the 20 and the 3 go")
	equal(offered({ 10 }, 5), "", "one stack of 10 with 5 kept is never split")
	equal(offered({ 5 }, 5), "", "exactly the amount kept offers nothing")
	equal(offered({ 4 }, 5), "", "fewer than the amount offers nothing")
	equal(offered({ 3, 3, 3 }, 5), "1", "9 carried, 5 kept: one 3 goes, two stay")
end)

test("a row offers only what is above the amount: 8 carried, 5 kept, x3 offered", function()
	local ns = load()
	Harness.Stub.SetBackpack({ potion(ns, 5), potion(ns, 3) })

	equal(table.concat(offeredCounts(ns.Scanner:Scan()), ","), "3,5", "both stacks with nothing kept")
	ns.db.profile.keepInBags.POTION = 5
	equal(table.concat(offeredCounts(ns.Scanner:Scan()), ","), "3", "only the 3 with 5 kept")
end)

test("a stack held back says why in the bag scan export", function()
	local ns = load()
	Harness.Stub.SetBackpack({ potion(ns, 5), potion(ns, 3) })
	ns.db.profile.keepInBags.POTION = 5

	local held, offered = 0, 0
	for _, row in ipairs(ns.Scanner:ScanAll()) do
		if row.reason == ns.Scanner.REJECT.KEEP_IN_BAGS then
			held = held + 1
		elseif row.item then
			offered = offered + 1
		end
	end
	equal(held, 1, "one stack kept in the bags")
	equal(offered, 1, "one offered")
end)

test("another kind's amount leaves this one alone", function()
	local ns = load()
	Harness.Stub.SetBackpack({ potion(ns, 5), potion(ns, 3) })
	ns.db.profile.keepInBags.FOOD = 20

	equal(#ns.Scanner:Scan(), 2, "potions still offered whole")
end)

test("a food on two kinds keeps the most of its switched-on kinds", function()
	local ns = load()
	local Stub = Harness.Stub
	local both
	for _, row in ipairs(ns.Data.FOOD_AND_WATER) do
		if row[4] == "BOTH" then
			both = row
			break
		end
	end
	check(both ~= nil, "there is a food that restores both")
	Stub.playerLevel = 60
	ns.db.profile.consumableLevelGap = 0
	local function stack(count)
		return Stub.Item({ id = both[1], name = "Both Test", quality = 1, classID = 0, bindType = 0, count = count })
	end
	Stub.SetBackpack({ stack(10), stack(10) })

	ns.db.profile.keepInBags.FOOD = 5
	ns.db.profile.keepInBags.DRINK = 20
	equal(#ns.Scanner:Scan(), 0, "Drink's 20 keeps both stacks")
	ns.db.profile.consumableKinds.DRINK = false
	equal(#ns.Scanner:Scan(), 1, "with Drink off, Food's 5 lets one go")
end)

test("gear is never held back by a consumable amount", function()
	local ns = load()
	local Stub = Harness.Stub
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		ns.db.profile.keepInBags[kind] = 20
	end
	local robe = Stub.Item({ name = "Keep Robe", equipLoc = "INVTYPE_ROBE", reqLevel = 20 })
	Stub.SetBackpack({ robe })

	local items = ns.Scanner:Scan()
	equal(#items, 1, "the robe is still offered")
	equal(items[1].kind, "gear", "as gear")
end)
