--[[
	Who an oil or stone goes to.

	Each row names who it enhances a weapon for, and that decides who is eligible, the way a
	scroll's stat does: stones go to the melee classes, wizard oils to the
	spell-damage casters, mana oils to anybody with mana. The field is enhances, so a rule or
	lookup reading restores or buffs alone would see nothing and hand it to everybody.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
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

-- The lowest-level real row that enhances for the token, from the loaded flavor's own data.
local function rowFor(ns, enhances)
	local found
	for _, row in ipairs(ns.Data.OILS_AND_STONES) do
		if row[4] == enhances and (not found or row[3] < found[3]) then
			found = row
		end
	end
	return found
end

-- Scans one real oil or stone out of the backpack, so the record is the one the scanner builds.
local function scan(ns, enhances)
	local row = rowFor(ns, enhances)
	check(row, "the data has a " .. enhances .. " row to test with")
	Stub.SetBackpack({
		Stub.Item({ id = row[1], name = "An Oil", quality = 1, classID = 0, subclassID = 6, bindType = 0 }),
	})
	local scanned = ns.Scanner:Scan()
	equal(#scanned, 1, "the item scanned")
	return scanned[1]
end

--------------------------------------------------------------------------------

test("the scanner records an oil or stone and who it enhances for", function()
	local ns = load()
	local item = scan(ns, "MELEE")

	equal(item.kind, "consumable", "a stone is a consumable")
	equal(item.def.form, "OIL_STONE", "it knows it is an oil or stone")
	equal(item.def.enhances, "MELEE", "and who it enhances for")
	equal(item.def.restores, nil, "it restores nothing, so no potion rule can catch it")
	equal(item.def.buffs, nil, "and buffs no stat")
end)

test("a sharpening stone goes to the melee classes", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(scan(ns, "MELEE"))

	-- The stub plays an Alliance character, and Era's Alliance has no shamans.
	equal(sorted(verdict.admitted), "PALADIN ROGUE WARRIOR", "the melee classes")
	check(not contains(verdict.admitted, "DRUID"), "not a druid, whose forms ignore the weapon")
	check(not contains(verdict.admitted, "HUNTER"), "nor a hunter, whose damage is ranged")
	equal(verdict.state, ns.Matcher.GIFT, "and it is giftable")
end)

test("a wizard oil goes to the spell-damage casters", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(scan(ns, "SPELL_DAMAGE"))

	equal(sorted(verdict.admitted), "DRUID MAGE PRIEST WARLOCK", "the casters, Alliance side")
end)

test("a mana oil goes to anybody with mana", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(scan(ns, "MANA"))

	check(contains(verdict.admitted, "HUNTER"), "a hunter, who has mana here")
	check(contains(verdict.admitted, "PALADIN"), "and a paladin")
	check(not contains(verdict.admitted, "WARRIOR"), "not a warrior")
	check(not contains(verdict.admitted, "ROGUE"), "nor a rogue")
end)

--[[
	Every flavor's rows, because a token with no CONSUMABLE_CLASSES entry falls back to every
	class, a level-1 row bands entirely below MIN_RECIPIENT_LEVEL and reaches nobody, and an id
	also listed in another consumable table is silently won by whichever table loads later.
	None of them fails loudly in game.
]]
test("every oil and stone row is known, reaches somebody, and is listed once", function()
	for _, flavor in ipairs({ "Vanilla", "TBC", "Camelot" }) do
		Stub.flavor = flavor
		local ok, ns = pcall(load)
		Stub.flavor = "Vanilla"
		assert(ok, ns)

		local elsewhere = {}
		for _, name in ipairs({ "FOOD_AND_WATER", "POTIONS", "SCROLLS" }) do
			for _, row in ipairs(ns.Data[name]) do
				elsewhere[row[1]] = name
			end
		end

		check(#ns.Data.OILS_AND_STONES > 0, flavor .. " has oils and stones")
		local seen = {}
		for _, row in ipairs(ns.Data.OILS_AND_STONES) do
			local id = flavor .. " " .. row[1]
			check(ns.Data.CONSUMABLE_CLASSES[row[4]] ~= nil, id .. " enhances for a known token")
			check(
				row[3] + ns.Data.CONSUMABLE_RECIPIENT_GAP >= ns.Data.MIN_RECIPIENT_LEVEL,
				id .. " has recipients above the level floor"
			)
			check(not seen[row[1]], id .. " is listed once")
			check(not elsewhere[row[1]], id .. " is in no other consumable table")
			seen[row[1]] = true
		end
	end
end)

--[[
	Items held out by hand, because no stat says who they help: the proc oils, an oil that only
	works in one dungeon, and one nobody has checked yet. A rebuild from Thanks for the Buff's
	list would bring them back, so each flavor, Season of Discovery included, is checked.
]]
local HELD_OUT = {
	[3824] = "Shadow Oil",
	[3829] = "Frost Oil",
	[211848] = "Blackfathom Mana Oil",
	[233996] = "Enchanted Repellent",
}

test("the oils held out by hand stay out", function()
	local flavors = {
		{ flavor = "Vanilla" },
		{ flavor = "Vanilla", season = 2, label = "Discovery" },
		{ flavor = "TBC" },
		{ flavor = "Camelot" },
	}
	for _, case in ipairs(flavors) do
		Stub.flavor, Stub.season = case.flavor, case.season
		local ok, ns = pcall(load)
		Stub.flavor, Stub.season = "Vanilla", nil
		assert(ok, ns)

		local label = case.label or case.flavor
		check(case.season == nil or ns.IS_DISCOVERY, label .. " loads as Season of Discovery")
		for _, row in ipairs(ns.Data.OILS_AND_STONES) do
			check(not HELD_OUT[row[1]], label .. " leaves out " .. tostring(HELD_OUT[row[1]]))
		end
	end
end)
