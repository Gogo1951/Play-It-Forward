--[[
	Who a scroll goes to.

	A scroll buffs one stat, and that stat decides who is eligible, the way what a potion
	restores does. The difference is the field: a scroll's fourth column is the stat it buffs,
	so the scanner files it under buffs rather than restores, and a rule or lookup reading
	restores alone would see nothing on a scroll and hand it to everybody.
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

-- The lowest-level real scroll that buffs the stat, from the loaded flavor's own data.
local function scrollFor(ns, buffs)
	local found
	for _, row in ipairs(ns.Data.SCROLLS) do
		if row[4] == buffs and (not found or row[3] < found[3]) then
			found = row
		end
	end
	return found
end

-- Scans one real scroll out of the backpack, so the record is the one the scanner builds.
local function scanScroll(ns, buffs)
	local row = scrollFor(ns, buffs)
	check(row, "the data has a " .. buffs .. " scroll to test with")
	Stub.SetBackpack({
		Stub.Item({ id = row[1], name = "A Scroll", quality = 1, classID = 0, subclassID = 4, bindType = 0 }),
	})
	local scanned = ns.Scanner:Scan()
	equal(#scanned, 1, "the scroll scanned")
	return scanned[1]
end

--------------------------------------------------------------------------------

test("the scanner records a scroll and the stat it buffs", function()
	local ns = load()
	local item = scanScroll(ns, "AGILITY")

	equal(item.kind, "consumable", "a scroll is a consumable")
	equal(item.def.form, "SCROLL", "it knows it is a scroll")
	equal(item.def.buffs, "AGILITY", "and which stat it buffs")
	equal(item.def.restores, nil, "it restores nothing, so no potion rule can catch it")
end)

test("a scroll of agility skips the casters", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(scanScroll(ns, "AGILITY"))

	equal(sorted(verdict.admitted), "DRUID HUNTER ROGUE WARRIOR", "the classes that build on Agility")
	equal(verdict.state, ns.Matcher.GIFT, "and it is giftable")
end)

test("a scroll of intellect skips warriors and rogues", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(scanScroll(ns, "INTELLECT"))

	check(contains(verdict.admitted, "MAGE"), "a mage is eligible")
	check(contains(verdict.admitted, "HUNTER"), "and a hunter, who has mana here")
	check(not contains(verdict.admitted, "WARRIOR"), "a warrior is not")
	check(not contains(verdict.admitted, "ROGUE"), "nor a rogue")
end)

test("stamina and protection scrolls are for everybody", function()
	local ns = load()
	local everybody = sorted(ns.Matcher:Classes())

	equal(sorted(ns.Matcher:Verdict(scanScroll(ns, "STAMINA")).admitted), everybody, "Stamina")
	equal(sorted(ns.Matcher:Verdict(scanScroll(ns, "ARMOR")).admitted), everybody, "and armor")
end)

--[[
	Every flavor's rows, because a stat with no CONSUMABLE_CLASSES entry falls back to every
	class, and a level-1 row bands entirely below MIN_RECIPIENT_LEVEL and reaches nobody.
	Neither fails loudly in game.
]]
test("every scroll row names a known stat and reaches somebody", function()
	for _, flavor in ipairs({ "Vanilla", "TBC", "Camelot" }) do
		Stub.flavor = flavor
		local ok, ns = pcall(load)
		Stub.flavor = "Vanilla"
		assert(ok, ns)

		check(#ns.Data.SCROLLS > 0, flavor .. " has scrolls")
		for _, row in ipairs(ns.Data.SCROLLS) do
			check(ns.Data.CONSUMABLE_CLASSES[row[4]] ~= nil, flavor .. " " .. row[1] .. " buffs a known stat")
			check(
				row[3] + ns.Data.CONSUMABLE_RECIPIENT_GAP >= ns.Data.MIN_RECIPIENT_LEVEL,
				flavor .. " " .. row[1] .. " has recipients above the level floor"
			)
		end
	end
end)
