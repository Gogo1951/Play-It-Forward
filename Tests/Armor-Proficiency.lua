--[[
	Armor a class has to train before it can wear it.

	The item that prompted this was a Captain's Waistguard of the Falcon: mail, requiring
	level 36, carrying nothing but Agility. Every hunter spec builds on Agility and two of
	three paladin specs merely tolerate it, so the point tables put the hunter six to the
	paladin's two -- and the hunter never got a look, because ns.Data.NATIVE_ARMOR says he
	is leather until 40 and the eligibility gate read that as "not his item" rather than
	"not yet". The belt went to a paladin and hunters were never even searched for.

	The fix is that a later training level moves the recipient band instead of closing the
	door: the hunter is looked for at 38 and 39, arriving with the belt just before he
	trains mail, while the paladin beside him is still looked for at 34 and 35. Bounded by
	ns.Data.PROFICIENCY_REACH, because a level 20 mail belt has nothing left to offer
	somebody who cannot wear it until 40.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

-- Every spec on: these cases are about armor training, and lean on a paladin or a druid as the fallback.
local function load()
	return Harness.AllSpecs(Harness.LoadAddon(ADDON_ROOT))
end

local CLOTH, LEATHER, MAIL, PLATE = 1, 2, 3, 4

local function armor(ns, subclassID, reqLevel, stats)
	local def = Stub.Item({
		name = "Test Waistguard",
		quality = 2,
		reqLevel = reqLevel,
		itemLevel = reqLevel + 5,
		equipLoc = "INVTYPE_WAIST",
		classID = 4,
		subclassID = subclassID,
		bindType = 2,
		stats = stats,
	})
	return ns.Scanner:Describe(def.link)
end

-- The belt itself: mail, requiring 36, "of the Falcon" being a single Agility roll.
local function falconBelt(ns, reqLevel)
	return armor(ns, MAIL, reqLevel or 36, { ITEM_MOD_AGILITY_SHORT = 8 })
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
-- Eligibility
--------------------------------------------------------------------------------

test("agility mail four levels short of the training level is the hunter's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(falconBelt(ns))

	equal(verdict.best, "HUNTER", "the class every spec of which wants the Agility")
	equal(sorted(verdict.contenders), "HUNTER", "and he leads alone")
	check(contains(verdict.admitted, "PALADIN"), "the paladin is still admitted behind him")
	check(contains(verdict.admitted, "WARRIOR"), "and the warrior")
end)

--[[
	The bound. Reach is five, so a level 34 belt is out and a 35 is in -- and the case
	either side of the line is the one worth pinning, because the number is a judgement
	call and this is where an edit to it shows up.
]]
test("mail further below the training level than reach does not reach the hunter", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(falconBelt(ns, 34))

	check(not contains(verdict.eligible, "HUNTER"), "a level 34 mail belt is not a hunter's problem")
	equal(verdict.best, "WARRIOR", "it goes to somebody who can wear it now")
end)

test("mail exactly reach below the training level still does", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(falconBelt(ns, 35))

	equal(verdict.best, "HUNTER", "35 is five below 40, which is the bound itself")
end)

test("mail at the training level is unchanged", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(falconBelt(ns, 40))

	equal(verdict.best, "HUNTER", "his own armor by then, and nothing here moved")
	check(contains(verdict.admitted, "PALADIN"), "the paladin is a fallback, as before")
end)

--[[
	A class that never trains the material is not reached at whatever level. Rogues and
	druids are leather for life, so no arithmetic on reach may ever admit one to mail.
]]
test("a class that never trains the material is never reached", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(falconBelt(ns))

	check(not contains(verdict.eligible, "ROGUE"), "a rogue is leather for life")
	check(not contains(verdict.eligible, "DRUID"), "and so is a druid")
	check(not contains(verdict.eligible, "MAGE"), "cloth classes are not admitted to mail either")
end)

--[[
	The same gate on the other material, and the reason it is not only about hunters:
	warriors and paladins train plate at 40 too, so on Era -- no death knights -- sub-40
	plate had NOBODY eligible at all and went straight to the kept pile.
]]
test("sub-40 plate reaches the warrior instead of the vendor pile", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(armor(ns, PLATE, 37, { ITEM_MOD_STRENGTH_SHORT = 8 }))

	equal(verdict.state, ns.Matcher.GIFT, "somebody wants it")
	equal(verdict.best, "WARRIOR", "and it is his")
end)

--[[
	Nothing above the gate moved. Leather and cloth are worn from level 1 by the classes
	that wear them at all, so no band shifts and no class joins.
]]
test("leather and cloth are untouched", function()
	local ns = load()
	local leather = ns.Matcher:Verdict(armor(ns, LEATHER, 36, { ITEM_MOD_AGILITY_SHORT = 8 }))
	local cloth = ns.Matcher:Verdict(armor(ns, CLOTH, 36, { ITEM_MOD_INTELLECT_SHORT = 8 }))

	equal(sorted(leather.contenders), "HUNTER ROGUE", "agility leather is still shared")
	check(contains(cloth.contenders, "MAGE"), "and intellect cloth is still a caster's")
end)

--------------------------------------------------------------------------------
-- The band that follows from it
--------------------------------------------------------------------------------

test("the hunter searches four levels above the paladin for the same belt", function()
	local ns = load()
	local item = falconBelt(ns)

	local hunterLo, hunterHi = ns.Matcher:LevelBand(item, "HUNTER")
	local paladinLo, paladinHi = ns.Matcher:LevelBand(item, "PALADIN")

	equal(hunterLo, 38, "the hunter is looked for two below the level he trains mail")
	equal(hunterHi, 39, "up to one below it")
	equal(paladinLo, 34, "the paladin against the item's own requirement")
	equal(paladinHi, 35, "as always")
end)

test("without a class it is still the item's own band", function()
	local ns = load()
	local lo, hi = ns.Matcher:LevelBand(falconBelt(ns))

	equal(lo, 34, "what the reports and the tooltip print")
	equal(hi, 35, "unchanged by any class")
end)

--[[
	One query cannot ask both bands, which is why the plan is built from groups rather
	than from a single pair of numbers.
]]
test("the search plans one band per group", function()
	local ns = load()
	local item = falconBelt(ns)
	item.verdict = ns.Matcher:Verdict(item)

	local groups = ns.Matcher:BandGroups(item, item.verdict.admitted)
	equal(#groups, 2, "two bands for one belt")

	local byBand = {}
	for _, group in ipairs(groups) do
		byBand[("%d-%d"):format(group.lo, group.hi)] = sorted(group.classes)
	end
	equal(byBand["38-39"], "HUNTER", "the hunter alone up there")
	equal(byBand["34-35"], "PALADIN WARRIOR", "the two who can wear it now down here")
end)

test("a band a class cannot use it in is not searched for that class", function()
	local ns = load()
	local item = falconBelt(ns)
	item.verdict = ns.Matcher:Verdict(item)

	--[[
		The 34 is exactly where the old single band would have put him, and he cannot wear
		mail for another six levels. The 38 gets it and equips it the level after next.
	]]
	local pools = {
		HUNTER = {
			{ name = "Toolow", level = 34, class = "HUNTER", shuffle = 0.1 },
			{ name = "Nearly", level = 38, class = "HUNTER", shuffle = 0.2 },
		},
		PALADIN = { { name = "Pally", level = 35, class = "PALADIN", shuffle = 0.3 } },
	}
	local ranked = ns.Matcher:RankCandidates(item, pools)

	local names = {}
	for index, person in ipairs(ranked) do
		names[index] = person.name
	end
	check(not contains(names, "Toolow"), "the 34 is not a candidate: " .. table.concat(names, ", "))
	equal(ranked[1].name, "Nearly", "the hunter about to train mail leads")
	check(contains(names, "Pally"), "and the paladin is still behind him as a fallback")
end)

--------------------------------------------------------------------------------
-- The targeted search
--------------------------------------------------------------------------------

--[[
	"Find Recipients for This Item" is meant to answer "who would be best for this", and
	the only shape /who can be filtered on is one class at a time. So every class gets a
	group of its own, the contender first, over its own band -- which is what turns the
	first press into his zones under `38-39 c-"Hunter"`, and asks for him anywhere after.
]]
test("a targeted search asks for the contender first, by name and in its own band", function()
	local ns = load()
	local item = falconBelt(ns)
	item.verdict = ns.Matcher:Verdict(item)

	local groups = ns.Matcher:TargetedBands(item)
	equal(groups[1].lo, 38, "the hunter's band leads the plan")
	equal(sorted(groups[1].classes), "HUNTER", "and he is alone in it, so the query can name him")
	local behind = {}
	for index = 2, #groups do
		equal(#groups[index].classes, 1, "every fallback has a group of its own")
		behind[#behind + 1] = groups[index].classes[1]
	end
	equal(sorted(behind), "PALADIN WARRIOR", "the fallbacks are behind him, not dropped")

	ns.Who:Plan(groups, true)
	ns.Who:Step(function() end)

	local query = Stub.whoQueries[1]
	check(query:find('c%-"Hunter"'), "the query names the hunter: " .. query)
	check(query:find("38%-39"), "over his band, not the item's: " .. query)
	check(query:find('z%-"'), "out in his levelling zones first: " .. query)
	local last = ns.Who.plan[#ns.Who.plan]
	check(#(last.zones or {}) == 0 and last.classes[1] ~= nil, "and some class asked anywhere last: " .. last.label)
end)

--[[
	Two contenders cannot both be filtered on -- the client honors one c-"..." and drops the
	rest -- so each gets its own query, and both lead the fallbacks.
]]
test("two contenders each get a query of their own, ahead of the fallbacks", function()
	local ns = load()
	local item = armor(ns, LEATHER, 36, { ITEM_MOD_AGILITY_SHORT = 8 })
	item.verdict = ns.Matcher:Verdict(item)

	local groups = ns.Matcher:TargetedBands(item)
	for _, group in ipairs(groups) do
		equal(#group.classes, 1, "one class per group")
	end
	equal(sorted({ groups[1].classes[1], groups[2].classes[1] }), "HUNTER ROGUE", "the contenders lead")
	check(#groups > 2, "and the fallbacks follow")
end)

--------------------------------------------------------------------------------
-- When the targeted search stops
--------------------------------------------------------------------------------

--[[
	Pressed from the belt's own dropdown, answered with the given roster. Capped, so the
	rest of the hunter's zones, and his class asked anywhere, stay on the plan.
]]
local function targetedSearch(ns, results)
	Stub.SetBackpack({
		Stub.Item({
			name = "Test Waistguard",
			quality = 2,
			reqLevel = 36,
			itemLevel = 41,
			equipLoc = "INVTYPE_WAIST",
			classID = 4,
			subclassID = MAIL,
			bindType = 2,
			stats = { ITEM_MOD_AGILITY_SHORT = 8 },
		}),
	})
	ns.fire("MAIL_SHOW")
	local item = ns.UI:Items()[1]

	Stub.now = Stub.now + 60
	Stub.whoResults = results
	Stub.whoTotal = 999
	ns.UI:FindRecipientsForItem(item)
	ns.fire("WHO_LIST_UPDATE")
	return item
end

local function plannedClasses(ns)
	local out = {}
	for _, attempt in ipairs(ns.Who.plan) do
		for _, class in ipairs(attempt.classes) do
			out[class] = true
		end
	end
	return out
end

test("a contender short of his anchor drops the fallbacks but keeps his own class", function()
	local ns = load()
	local item = targetedSearch(ns, { { name = "Nearly", level = 38, class = "HUNTER" } })

	equal(item.recipient and item.recipient.name, "Nearly", "the hunter holds the belt")
	local left = plannedClasses(ns)
	check(left.HUNTER, "a hunter at 39 would still beat him, so his zones stay")
	check(not left.PALADIN, "no paladin can take it off a contender")
	check(not left.WARRIOR, "nor a warrior")
end)

test("a best-fit contender at his anchor ends the search", function()
	local ns = load()
	local item = targetedSearch(ns, { { name = "Ready", level = 39, class = "HUNTER", area = "Desolace" } })

	equal(item.recipient and item.recipient.name, "Ready", "the hunter holds the belt")
	equal(ns.Who:Remaining(), 0, "nobody left to find could outrank him")
end)

-- The same hunter in a capital: somebody out levelling would still rank above him.
test("a best-fit contender in a capital keeps the search going", function()
	local ns = load()
	local item = targetedSearch(ns, { { name = "Ready", level = 39, class = "HUNTER", area = "Orgrimmar" } })

	equal(item.recipient and item.recipient.name, "Ready", "the hunter holds the belt meanwhile")
	check(ns.Who:Remaining() > 0, "and the search goes on for a hunter out in the world")
end)

test("an unheld row keeps every attempt", function()
	local ns = load()
	local item = targetedSearch(ns, {})
	local planned = ns.Who:Planned()

	equal(item.recipient, nil, "nobody found yet")
	equal(ns.Who:Remaining(), planned - 1, "only the press already spent is gone")
end)
