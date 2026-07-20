--[[
	The band an item searches in.

	Fixed rather than configurable. It was two sliders, and they interact in a way a
	slider does not show: set Widest Level Gap to 1 with Closest at 1 and the band
	collapses to a single level, which is what silently starved a shield of paladins on
	1.15.8 while every other line of its report said the matching was right.

	Two below the requirement to one below it. A level 19 sword reaches a 17 or an 18,
	prefers the 18, and never reaches a 19 -- somebody who can already equip it is not
	who this add-on is for.
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

--[[
	The point of the band, stated as the three cases the author named: a 17 may get a
	level 19 sword, an 18 is the one it should go to, and a 19 never sees it.
]]
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

--[[
	Matcher:LevelBand clamps at level 1, so a very low requirement can still produce a
	single-level band. That is arithmetic rather than a misconfiguration now, and the
	report says so without pointing at a setting that no longer exists.
]]
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

--[[
	The matching itself was never at fault in the shield case, and it is worth keeping
	pinned: a paladin is admitted for an Intellect shield and it scores as a gift.
]]
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
