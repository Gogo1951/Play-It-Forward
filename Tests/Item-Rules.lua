--[[
	The rules that sit on top of the point tables.

	Weights say how much a class wants a stat. They cannot say "this combination of
	stats is that class's item", and a few combinations are exactly that: Intellect with
	Spirit is caster gear, Agility with Intellect is a hunter's, Stamina on its own is a
	warlock's. Scoring reaches those answers most of the time and reached the wrong one
	often enough to be worth stating outright -- an "of the Owl" staff went to a hunter.

	THREE STRENGTHS, and which one a rule takes is the whole of its design.

	  prefer  names who the item is for; everybody else drops behind them. An owl staff
	          still reaches a hunter when no priest, mage or druid is in range.
	  demote  names who must not lead, and leaves them as fallbacks. Intellect against
	          warriors and rogues: a Strength-and-Intellect chest is not theirs, but a
	          sub-40 mail one has nobody else in heavy armor and a vendor helps less.
	  veto    removes outright. Spirit against warlocks, and only that, because a
	          warlock gets nothing whatsoever from Spirit -- being his last resort is not
	          a fallback, it is a wrong answer arriving later.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- A staff, which every caster and a hunter can carry: the owl staff case.
local function staff(ns, stats)
	local def = Stub.Item({
		name = "Test Staff",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_2HWEAPON",
		classID = 2,
		subclassID = 10,
		bindType = 2,
		stats = stats,
	})
	return ns.Scanner:Describe(def.link)
end

local function cloth(ns, stats)
	local def = Stub.Item({
		name = "Test Robe",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1,
		bindType = 2,
		stats = stats,
	})
	return ns.Scanner:Describe(def.link)
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

--[[
	The item that prompted all of this.
]]
test("an owl staff is for priests, mages and druids", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(staff(ns, { ITEM_MOD_INTELLECT_SHORT = 3, ITEM_MOD_SPIRIT_SHORT = 3 }))

	equal(sorted(verdict.contenders), "DRUID MAGE PRIEST", "exactly the three")
	check(not contains(verdict.contenders, "HUNTER"), "never the hunter")
	check(not contains(verdict.contenders, "SHAMAN"), "nor a shaman")
end)

test("a hunter can still receive an owl staff when nobody better is in range", function()
	local ns = load()
	local item = staff(ns, { ITEM_MOD_INTELLECT_SHORT = 3, ITEM_MOD_SPIRIT_SHORT = 3 })
	item.verdict = ns.Matcher:Verdict(item)
	item.bandLo, item.bandHi = ns.Matcher:LevelBand(item)

	--[[
		The soft half of the choice: last resort, not exclusion. A staff sitting in a bag
		helps nobody.
	]]
	check(contains(item.verdict.admitted, "HUNTER"), "still admitted")

	local pools = { HUNTER = { { name = "Hunty", level = 18, class = "HUNTER", shuffle = 0.1 } } }
	equal(#ns.Matcher:RankCandidates(item, pools), 1, "and reachable when he is all there is")
end)

test("a priest outranks a hunter for the same staff", function()
	local ns = load()
	local item = staff(ns, { ITEM_MOD_INTELLECT_SHORT = 3, ITEM_MOD_SPIRIT_SHORT = 3 })
	item.verdict = ns.Matcher:Verdict(item)
	item.bandLo, item.bandHi = ns.Matcher:LevelBand(item)

	--[[
		Both inside the band a level 20 item searches, 18 to 19, and the hunter is the
		one closer to equipping it. The rule has to beat level proximity or it only wins
		the cases the weights were already winning.
	]]
	local pools = {
		HUNTER = { { name = "Hunty", level = 19, class = "HUNTER", shuffle = 0.1 } },
		PRIEST = { { name = "Pri", level = 18, class = "PRIEST", shuffle = 0.2 } },
	}
	local ranked = ns.Matcher:RankCandidates(item, pools)
	equal(ranked[1].name, "Pri", "the priest leads despite the hunter being nearer")
end)

--------------------------------------------------------------------------------

test("agility with intellect is a hunter's, even on cloth", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_AGILITY_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 }))

	equal(sorted(verdict.contenders), "HUNTER", "the hunter alone")
	check(contains(verdict.admitted, "ROGUE"), "a rogue is still a fallback for the agility")
	check(not contains(verdict.contenders, "ROGUE"), "but the intellect keeps him out of contention")
end)

test("stamina on its own is a warlock's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_STAMINA_SHORT = 6 }))

	equal(sorted(verdict.contenders), "WARLOCK", "the warlock alone")
end)

--[[
	The veto, which is absolute rather than soft. A warlock ranks Stamina, so without
	this an "of the Whale" roll is his best claim outright.
]]
test("a warlock never receives anything carrying spirit", function()
	local ns = load()
	local whale = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_STAMINA_SHORT = 4, ITEM_MOD_SPIRIT_SHORT = 4 }))

	check(not contains(whale.eligible, "WARLOCK"), "not even eligible")
	check(not contains(whale.admitted, "WARLOCK"), "so never admitted")
	check(contains(whale.contenders, "PRIEST"), "and it goes where the spirit points")
end)

test("the spirit veto beats the intellect the warlock does want", function()
	local ns = load()
	local owl = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_INTELLECT_SHORT = 3, ITEM_MOD_SPIRIT_SHORT = 3 }))

	check(not contains(owl.admitted, "WARLOCK"), "the intellect does not buy him back in")
end)

test("a warlock still receives intellect gear with no spirit on it", function()
	local ns = load()
	local plain = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_INTELLECT_SHORT = 9 }))

	check(contains(plain.contenders, "WARLOCK"), "no rule applies, so the weights decide")
	check(contains(plain.contenders, "MAGE"), "alongside the other intellect classes")
end)

--------------------------------------------------------------------------------

--[[
	A rule that cannot reach anybody must not strand the item. Mail at this level is
	worn by warriors and paladins, none of whom the caster rule names.
]]
test("a rule that names nobody eligible leaves the weights alone", function()
	local ns = load()
	local def = Stub.Item({
		name = "Chain Vest",
		quality = 2,
		reqLevel = 45,
		itemLevel = 50,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 3, -- MAIL
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_SPIRIT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	equal(verdict.state, ns.Matcher.GIFT, "still giftable")
	check(#verdict.contenders > 0, "and somebody is still in contention for it")
end)

test("an item no rule matches is scored the way it always was", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(cloth(ns, { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_AGILITY_SHORT = 6 }))

	check(#verdict.contenders > 0, "the point tables still decide")
	check(not contains(verdict.contenders, "PRIEST"), "and a strength roll is not a caster's")
end)

--[[
	Rules are tried in the order they are written and the first match takes the item, so
	the order is part of the data rather than an accident of the loop.
]]
test("the rules are applied first match first", function()
	local ns = load()
	local names = {}
	for index, rule in ipairs(ns.Data.ItemRules) do
		names[index] = rule.name
	end
	check(#ns.Data.ItemRules >= 4, "all four rules are present: " .. table.concat(names, " | "))
end)

--------------------------------------------------------------------------------
-- Intellect is never a warrior's or a rogue's
--------------------------------------------------------------------------------

--[[
	Neither class has an Intellect weight, so a pure caster item already excluded them
	by scoring: no claim, no admission. What did not exclude them was a hybrid roll --
	"of the Gorilla" is Strength and Intellect, the warrior claims the Strength half, and
	in he goes. The weapon rules made it worse by promoting him into contention there.

	Vetoed rather than demoted, matching the Spirit rule above: a warrior gets nothing
	whatsoever out of Intellect, so being the last resort for it is not a fallback, it is
	the same wrong answer arriving later.
]]
test("a warrior and a rogue never lead on anything carrying intellect", function()
	local ns = load()
	local gorilla = ns.Matcher:Verdict(cloth(ns, {
		ITEM_MOD_STRENGTH_SHORT = 6,
		ITEM_MOD_INTELLECT_SHORT = 6,
	}, "Robe of the Gorilla"))

	check(not contains(gorilla.contenders, "WARRIOR"), "the warrior does not lead")
	check(not contains(gorilla.contenders, "ROGUE"), "nor the rogue")
	check(contains(gorilla.admitted, "WARRIOR"), "but he is still a fallback for the strength")
	check(contains(gorilla.contenders, "PALADIN"), "and the paladin, who uses both halves, leads")
end)

test("the melee half keeps them as fallbacks, not leaders", function()
	local ns = load()
	local falcon = ns.Matcher:Verdict(cloth(ns, {
		ITEM_MOD_AGILITY_SHORT = 6,
		ITEM_MOD_INTELLECT_SHORT = 6,
	}, "Robe of the Falcon"))

	check(contains(falcon.admitted, "ROGUE"), "the agility still admits the rogue")
	check(not contains(falcon.contenders, "ROGUE"), "the intellect keeps him behind")
	check(contains(falcon.contenders, "HUNTER"), "and it is a hunter's roll anyway")
end)

--[[
	A weapon rule can only name classes that were admitted, so the veto reaches through
	it. This is the case the sanity check found: a Strength-and-Intellect one-hander had
	the warrior contending because the weapon rule promoted him.
]]
test("a weapon rule cannot promote a demoted class", function()
	local ns = load()
	local def = Stub.Item({
		name = "Mace of the Gorilla",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 4,
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(not contains(verdict.contenders, "WARRIOR"), "the one-hand rule did not promote him")
	check(contains(verdict.admitted, "WARRIOR"), "he is still there, just not leading")
end)

--[[
	The case that named this: the dagger rule leads with the rogue, and an Intellect
	dagger is a caster's. Demotion runs after the weapon rules for exactly this.
]]
test("an intellect dagger goes to the casters, not the rogue", function()
	local ns = load()
	local def = Stub.Item({
		name = "Dagger of the Gorilla",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 15,
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(not contains(verdict.contenders, "ROGUE"), "the dagger rule did not hand it to the rogue")
	check(contains(verdict.admitted, "ROGUE"), "he is still behind whoever does lead")
	check(#verdict.contenders > 0, "and somebody leads: " .. sorted(verdict.contenders))
end)

--[[
	Agility and Intellect mail past 40 is hunter and shaman gear -- they move out of
	leather at 40, which is the whole reason such an item exists.
]]
test("agility and intellect mail past 40 is a hunter's", function()
	local ns = load()
	local def = Stub.Item({
		name = "Chain of the Falcon",
		quality = 2,
		reqLevel = 45,
		itemLevel = 50,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 3, -- MAIL
		bindType = 2,
		stats = { ITEM_MOD_AGILITY_SHORT = 8, ITEM_MOD_INTELLECT_SHORT = 8 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(contains(verdict.contenders, "HUNTER"), "the hunter leads: " .. sorted(verdict.contenders))
	check(not contains(verdict.contenders, "WARRIOR"), "the warrior does not")
end)

--[[
	The reason this is a demotion and not a veto. Mail below 40 is worn by warriors and
	paladins alone, and on Era the Horde has no paladin -- so a veto left an Intellect
	mail chest with nobody at all and sent it to a vendor.
]]
test("intellect gear with nobody else left still reaches a warrior", function()
	local ns = load()
	UnitFactionGroup = function()
		return "Horde"
	end
	local def = Stub.Item({
		name = "Chain of the Gorilla",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 3, -- MAIL
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	equal(verdict.state, ns.Matcher.GIFT, "not stranded in the vendor pile")
	check(contains(verdict.contenders, "WARRIOR"), "the demotion abstains when he is all there is")
end)

test("gear with no intellect on it is untouched", function()
	local ns = load()
	local bear = ns.Matcher:Verdict(cloth(ns, {
		ITEM_MOD_STRENGTH_SHORT = 6,
		ITEM_MOD_STAMINA_SHORT = 6,
	}, "Robe of the Bear"))

	check(contains(bear.contenders, "WARRIOR"), "a strength roll is still a warrior's")
end)

test("a statless weapon is still theirs", function()
	local ns = load()
	local def = Stub.Item({
		name = "Plain Sword",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 7,
		bindType = 2,
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(contains(verdict.contenders, "WARRIOR"), "no intellect, no veto")
end)

--[[
	Demotion falls back through the scoring, not past it.

	A Strength-and-Intellect one-hand mace: coverage says the paladin is the only class
	using all of it and everybody else uses half. The one-hand weapon rule then replaces
	the contenders with the warrior, and removing him has to land back on coverage's
	answer -- reaching for the admitted list instead handed the lead to a priest and a
	druid as well, two classes coverage had just demoted, promoted by the step meant to
	demote somebody else.
]]
test("demoting a class does not promote the ones scoring already ruled out", function()
	local ns = load()
	local def = Stub.Item({
		name = "Mace of the Gorilla",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 4, -- 1H mace: warrior, paladin, rogue, priest, druid
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	equal(sorted(verdict.contenders), "PALADIN", "the one class using all of it")
	check(contains(verdict.admitted, "PRIEST"), "the priest is still a fallback")
	check(contains(verdict.admitted, "WARRIOR"), "and so is the warrior")
end)

--[[
	Same shape on a dagger, where no paladin can hold one. Coverage abstains -- everybody
	uses half -- so the fallback is the class-share set, and the hunter is below that
	line. Reaching for the admitted list put him in the lead.
]]
test("the fallback keeps the class-share line", function()
	local ns = load()
	local def = Stub.Item({
		name = "Dagger of the Gorilla",
		quality = 2,
		reqLevel = 30,
		itemLevel = 35,
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 15,
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 6 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(not contains(verdict.contenders, "HUNTER"), "the hunter never cleared the share line")
	check(contains(verdict.admitted, "HUNTER"), "though he is admitted")
	check(contains(verdict.contenders, "MAGE"), "the classes that did clear it lead")
end)
