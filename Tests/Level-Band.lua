--[[
	The band an item searches in: fixed, two below the requirement to one below it, never a level
	that can already equip it. Fixed rather than configurable, since two sliders could silently
	collapse it to a single level.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function sword(ns, reqLevel)
	local def = Stub.Item({
		name = "Test Sword",
		quality = 2,
		reqLevel = reqLevel or 19,
		itemLevel = 24,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 7,
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 4 },
	})
	return ns.Scanner:Describe(def.link), def
end

--------------------------------------------------------------------------------

test("a level 19 item searches levels 17 to 18", function()
	local ns = load()
	local lo, hi = ns.Matcher:LevelBand(sword(ns, 19))

	equal(lo, 17, "two below the requirement")
	equal(hi, 18, "up to one below it")
end)

test("the gaps are constants, not settings", function()
	local ns = load()

	equal(ns.Data.LEVEL_GAP_WIDEST, 2, "widest gap")
	equal(ns.Data.LEVEL_GAP_CLOSEST, 1, "closest gap")
	equal(ns.db.profile.levelOffsetLow, nil, "no longer a saved setting")
	equal(ns.db.profile.levelOffsetHigh, nil, "nor this one")
end)

test("a 19 sword reaches a 17, prefers an 18, and never reaches a 19", function()
	local ns = load()
	local item = sword(ns, 19)
	item.bandLo, item.bandHi = ns.Matcher:LevelBand(item)

	local pools = {
		WARRIOR = {
			{ name = "Seventeen", level = 17, class = "WARRIOR", shuffle = 0.1 },
			{ name = "Eighteen", level = 18, class = "WARRIOR", shuffle = 0.2 },
			{ name = "Nineteen", level = 19, class = "WARRIOR", shuffle = 0.3 },
		},
	}
	local ranked = ns.Matcher:RankCandidates(item, pools)

	local names = {}
	for index, person in ipairs(ranked) do
		names[index] = person.name
	end
	equal(#ranked, 2, "two candidates: " .. table.concat(names, ", "))
	equal(ranked[1].name, "Eighteen", "closest to equipping it comes first")
	equal(ranked[2].name, "Seventeen", "the 17 is the fallback")
	for _, person in ipairs(ranked) do
		check(person.level ~= 19, "somebody who can already equip it is never a candidate")
	end
end)

-- Matcher:LevelBand clamps at level 1, so a very low requirement can still give a single-level band.
test("a very low requirement clamps rather than going below level 1", function()
	local ns = load()
	local lo, hi = ns.Matcher:LevelBand(sword(ns, 2))

	equal(lo, 1, "never below level 1")
	check(hi >= lo, "and never inverted")
end)

test("the report shows the band and the gaps behind it", function()
	local ns = load()
	local _, def = sword(ns, 19)

	local report = ns:BuildItemVerdictReport(def.link)
	check(report:find("17 to 18"), "the band")
	check(report:find("gaps of 2 and 1"), "and the two numbers behind it")
end)

test("a paladin is a real recipient for an intellect shield", function()
	local ns = load()
	local def = Stub.Item({
		name = "Forest Buckler",
		quality = 2,
		reqLevel = 19,
		itemLevel = 24,
		equipLoc = "INVTYPE_SHIELD",
		classID = 4,
		subclassID = 6,
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 4, ITEM_MOD_STAMINA_SHORT = 2 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	equal(verdict.state, ns.Matcher.GIFT, "the shield is giftable")
	equal(verdict.best, "PALADIN", "and it is the paladin's")
end)
