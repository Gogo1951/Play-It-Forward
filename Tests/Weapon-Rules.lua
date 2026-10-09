--[[
	Which hand a weapon is for, and who that makes it for.

	A rogue can only ever use one-handers. A druid can only ever use two-handers and a
	short list of one-hand maces and daggers. So a good one-hand mace landing on a druid
	is a waste twice over: the rogue who wanted it got nothing, and the druid would have
	been just as happy with the staff nobody else can use.

	Soft, like every other rule here. Everyone the weights allowed stays behind the named
	classes, so a one-hander still reaches a druid when no warrior or rogue is in range.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Statless on purpose for the handedness cases. A weapon nobody has a stat claim on
	falls to "offer it to everyone", which is the widest field a rule can be asked to
	narrow -- and it is the plain white and low-green weapons this add-on mails most.
]]
local function weapon(ns, subclassID, equipLoc, stats)
	local def = Stub.Item({
		name = "Test Weapon",
		quality = 2,
		reqLevel = 20,
		itemLevel = 30,
		equipLoc = equipLoc,
		classID = 2,
		subclassID = subclassID,
		bindType = 2,
		stats = stats,
	})
	return ns.Scanner:Describe(def.link)
end

local ONE_HAND, TWO_HAND = "INVTYPE_WEAPON", "INVTYPE_2HWEAPON"
local SWORD, MACE_1H, MACE_2H, DAGGER, STAFF, BOW, POLEARM, FIST = 7, 4, 5, 15, 10, 2, 6, 13
-- The rest of the ranged slot, which the unclaimed rule covers and pointedly does not.
local GUN, CROSSBOW, THROWN = 3, 18, 16
-- The kinds a rogue and a hunter respectively cannot hold, which is what makes them worth pinning.
local AXE_1H, SWORD_2H = 0, 8

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
	One-handers split two ways rather than one. Swords, maces, axes and fists are shared
	by the warrior and the rogue, the two classes that fight one-handed; daggers are the
	rogue's alone. Both rules name him, and what differs is who stands beside him.

	The dagger rule is what keeps the shared pool from costing him anything: every class
	in the game can be handed a dagger and he is the only one who builds around them, so
	he still has a kind of his own to fall back on.
]]
test("a one-hand sword is a warrior's and a rogue's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, SWORD, ONE_HAND, {}))

	equal(sorted(verdict.contenders), "ROGUE WARRIOR", "both lead")
	check(contains(verdict.admitted, "PALADIN"), "a paladin is behind them, not excluded")
end)

--[[
	The case the author named first. A druid is group 1 for one-hand maces, so the
	weights put him level with a warrior and ahead of a rogue.
]]
test("a one-hand mace stops going to druids first", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, MACE_1H, ONE_HAND, {}))

	equal(sorted(verdict.contenders), "ROGUE WARRIOR", "the two that fight one-handed lead")
	check(contains(verdict.admitted, "DRUID"), "and the druid is still behind them, not excluded")
end)

--[[
	A rogue cannot train axes in Era or TBC, so the matrix never admits him and the rule
	naming him costs nothing. This is the general guarantee under both weapon rules: a
	preference can only name classes scoring already admitted, so an entry that cannot
	apply falls out on its own rather than needing a second list to exclude it.
]]
test("a one-hand axe is the warrior's alone", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, AXE_1H, ONE_HAND, {}))

	equal(sorted(verdict.contenders), "WARRIOR", "the rogue is named but cannot hold one")
	check(not contains(verdict.admitted, "ROGUE"), "so he is not even admitted")
end)

test("a dagger is a rogue's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, DAGGER, ONE_HAND, {}))

	equal(sorted(verdict.contenders), "ROGUE", "the rogue alone")
	check(contains(verdict.admitted, "WARRIOR"), "a warrior can still have one")
	check(contains(verdict.admitted, "MAGE"), "and so can a mage, who holds them as stat sticks")
end)

--[[
	Fist weapons sit in the shared one-hand pool because they are 1H melee like the rest
	of it -- a combat rogue wants one about as much as a warrior does, which is now what
	the rule says rather than something only the fallback order expressed.
]]
test("a fist weapon goes with the one-hand group", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, FIST, ONE_HAND, {}))

	equal(sorted(verdict.contenders), "ROGUE WARRIOR", "both lead")
	check(contains(verdict.admitted, "DRUID"), "with the druid behind them")
end)

--[[
	A hunter is not eligible for two-hand maces, so this case reaches only the druid and
	the paladin however the rule is written. It is the counterpart to the two-hand sword
	below: between them they pin that each named class is kept to what it can carry.
]]
test("a two-hand mace is for druids and paladins", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, MACE_2H, TWO_HAND, {}))

	equal(sorted(verdict.contenders), "DRUID PALADIN", "the hunter cannot hold one")
	check(contains(verdict.admitted, "WARRIOR"), "a warrior can still have it when they are not around")
end)

--[[
	A hunter's melee weapon is a stat stick -- his damage comes out of the ranged slot --
	so the largest stat budget wins and that is a two-hander. He leads here beside the
	paladin, with the warrior admitted behind them; a druid cannot hold a sword at all.
]]
test("a two-hand sword is a hunter's too", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, SWORD_2H, TWO_HAND, {}))

	equal(sorted(verdict.contenders), "HUNTER PALADIN", "the hunter leads with the paladin")
	check(contains(verdict.admitted, "WARRIOR"), "the warrior is behind them, not excluded")
	check(not contains(verdict.admitted, "DRUID"), "and a druid cannot hold a two-hand sword")
end)

--[[
	A polearm is two-handed and is a hunter's before it is a two-hander. Under the
	two-hand rule it went to a paladin with the hunter behind him, which is backwards:
	an Agility polearm is one of the few melee weapons a hunter genuinely wants.
]]
test("a polearm is a hunter's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, POLEARM, TWO_HAND, {}))

	equal(sorted(verdict.contenders), "HUNTER", "the hunter leads")
	check(contains(verdict.admitted, "PALADIN"), "the paladin is still behind him")
	check(contains(verdict.admitted, "WARRIOR"), "and the warrior")
end)

test("an agility polearm is still a hunter's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, POLEARM, TWO_HAND, { ITEM_MOD_AGILITY_SHORT = 8 }))

	equal(sorted(verdict.contenders), "HUNTER", "and more so with agility on it")
end)

-- Druids train polearms in patch 3.0.8, past every shipped flavor, so no level admits one.
test("a level 60 polearm never reaches a druid", function()
	local ns = load()
	local def = Stub.Item({
		name = "Test Polearm",
		quality = 2,
		reqLevel = 60,
		itemLevel = 65,
		equipLoc = TWO_HAND,
		classID = 2,
		subclassID = POLEARM,
		bindType = 2,
		stats = { ITEM_MOD_AGILITY_SHORT = 8 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(not contains(verdict.eligible, "DRUID"), "the druid is not eligible")
	check(contains(verdict.eligible, "HUNTER"), "the hunter still is")
end)

test("the two-hand rule no longer claims polearms", function()
	local ns = load()
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
		if rule.name == "Two-hand weapons" then
			for _, key in ipairs(rule.weapon) do
				check(key ~= "POLEARM", "POLEARM is not in the two-hand list")
			end
		end
	end
end)

--------------------------------------------------------------------------------

--[[
	A staff is two-handed and is not a two-hander in the sense that matters. It is the
	caster weapon: putting it under the two-hand rule would hand every one to a druid
	ahead of the mages, priests and warlocks who have nothing else.
]]
test("a staff is not caught by the two-hand rule", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, STAFF, TWO_HAND, {}))

	check(contains(verdict.contenders, "MAGE"), "the casters still compete for it")
	check(contains(verdict.contenders, "PRIEST"), "all of them")
	check(not contains(verdict.contenders, "PALADIN"), "and a paladin cannot hold one anyway")
end)

test("a bow is neither", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, BOW, "INVTYPE_RANGED", {}))

	check(contains(verdict.contenders, "HUNTER"), "a ranged weapon is decided by the weapon matrix")
end)

--------------------------------------------------------------------------------

--[[
	A ranged weapon carrying nothing anybody ranks. The matrix admits a warrior, a hunter
	and a rogue equally and the baseline gives all three the same score, so before this
	rule the tie fell to whoever came first in the class list -- the warrior, every time.

	A hunter's whole damage comes out of that slot in all three of his specs; a warrior or
	a rogue carries a gun to pull with. When there is nothing on the item to separate them,
	that is the tiebreak.
]]
test("a statless gun is the hunter's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, GUN, "INVTYPE_RANGED", {}))

	equal(sorted(verdict.contenders), "HUNTER", "the hunter leads alone")
	check(contains(verdict.admitted, "WARRIOR"), "a warrior can still have it when no hunter is around")
	check(contains(verdict.admitted, "ROGUE"), "and a rogue")
end)

test("a statless bow and crossbow are the same case", function()
	local ns = load()

	equal(sorted(ns.Matcher:Verdict(weapon(ns, BOW, "INVTYPE_RANGED", {})).contenders), "HUNTER", "bow")
	equal(sorted(ns.Matcher:Verdict(weapon(ns, CROSSBOW, "INVTYPE_RANGED", {})).contenders), "HUNTER", "crossbow")
end)

--[[
	The limit of the rule, and it is the whole reason it is written on "unclaimed" rather
	than on "ranged": a bow is good for everyone and stats decide it. Agility is a rogue's
	stat as much as a hunter's, so both compete -- the hunter has no special claim once
	there is something on the item to read.
]]
test("an agility bow is still shared with the rogue", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, BOW, "INVTYPE_RANGED", { ITEM_MOD_AGILITY_SHORT = 6 }))

	equal(sorted(verdict.contenders), "HUNTER ROGUE", "stats decide, and both build on Agility")
end)

test("a strength gun is the warrior's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, GUN, "INVTYPE_RANGED", { ITEM_MOD_STRENGTH_SHORT = 6 }))

	equal(sorted(verdict.contenders), "WARRIOR", "the rule never got to name the hunter")
	check(not contains(verdict.admitted, "HUNTER"), "he has no claim on Strength at all")
end)

--[[
	Thrown is deliberately out of the rule: the matrix gives a hunter no proficiency for
	it, so naming him there would be a line that could never apply.
]]
test("statless thrown is left to the two classes that carry it", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, THROWN, "INVTYPE_THROWN", {}))

	check(not contains(verdict.admitted, "HUNTER"), "a hunter cannot use a thrown weapon")
	check(contains(verdict.contenders, "WARRIOR"), "the warrior competes for it")
	check(contains(verdict.contenders, "ROGUE"), "and the rogue")
end)

--[[
	The rule asks about the scoring, not about the item, and only a preference may: a veto
	is applied before anything is scored, so it could never answer the question.
]]
test("the unclaimed rule never carries a veto", function()
	local ns = load()
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
		if rule.unclaimed then
			check(rule.veto == nil, rule.name .. " does not veto")
		end
	end
end)

--[[
	A caster one-hander cannot reach the rule at all, because a warrior and a rogue have
	no claim on Intellect and so are never admitted. Worth pinning: it is why the rule
	needs no "unless it has caster stats" clause.
]]
test("an intellect one-hander is left to the casters", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, MACE_1H, ONE_HAND, { ITEM_MOD_INTELLECT_SHORT = 9 }))

	check(not contains(verdict.contenders, "WARRIOR"), "no warrior on a caster mace")
	check(not contains(verdict.admitted, "ROGUE"), "nor a rogue")
	check(#verdict.contenders > 0, "somebody still wants it: " .. sorted(verdict.contenders))
end)

--[[
	Features/Match-Derivations.lua warns about this above ns.Data.UsesWeaponMatrix:
	WeaponKey falls through to the weapon subclass table for anything it does not
	recognize, and armor subclass 1 is cloth while weapon subclass 1 is a two-hand axe.
	A rule reading the key without checking the item is a weapon would call every cloth
	chest a two-hander.
]]
test("a cloth chest is not mistaken for a two-hand axe", function()
	local ns = load()
	local def = Stub.Item({
		name = "Ivycloth Robe",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1, -- cloth, and also the two-hand axe weapon subclass
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
	})
	local verdict = ns.Matcher:Verdict(ns.Scanner:Describe(def.link))

	check(contains(verdict.contenders, "MAGE"), "still a caster robe")
	check(not contains(verdict.contenders, "PALADIN"), "not a two-hander")
end)

--[[
	Stat rules are written above the weapon rules and the first match wins.

	An Intellect-and-Spirit two-hand mace matches both: the caster rule names priests,
	mages and druids, the two-hand rule names druids and paladins. Only a druid can hold
	one of the three the caster rule names, so the caster rule winning leaves the druid
	alone -- and the paladin the two-hand rule would have added is the tell.
]]
test("a stat rule still beats a weapon rule", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(weapon(ns, MACE_2H, TWO_HAND, {
		ITEM_MOD_INTELLECT_SHORT = 6,
		ITEM_MOD_SPIRIT_SHORT = 6,
	}))

	equal(sorted(verdict.contenders), "DRUID", "the caster rule took it")
	check(contains(verdict.admitted, "PALADIN"), "the paladin is admitted")
	check(not contains(verdict.contenders, "PALADIN"), "but the two-hand rule never got to name him")
end)

--[[
	Each flavor folder carries the weapon matrix its own client trains, with no patch table
	applied on top: Wrath's folder already gives rogues one-hand axes and druids polearms,
	and Classic's gives neither.
]]
local function loadFlavor(flavor)
	Stub.flavor = flavor
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT)
	Stub.flavor = "Vanilla"
	assert(ok, ns)
	return ns
end

local function specsFor(ns, weaponKey, class)
	for column, token in ipairs(ns.Data.WEAPON_CLASS_ORDER) do
		if token == class then
			return ns.Data.WEAPON_SPECS[weaponKey][column]
		end
	end
end

test("each flavor folder carries its own weapon matrix", function()
	local wrath = loadFlavor("Wrath")
	equal(specsFor(wrath, "1H_AXE", "ROGUE"), 1, "Wrath rogues train one-hand axes")
	equal(specsFor(wrath, "POLEARM", "DRUID"), 1, "Wrath druids train polearms")

	local vanilla = loadFlavor("Vanilla")
	equal(specsFor(vanilla, "POLEARM", "DRUID"), 0, "Classic druids never carry a polearm")
end)

test("Classic's faction table leaves shamans off the Alliance side", function()
	local ns = loadFlavor("Vanilla")
	local alliance = {}
	for _, class in ipairs(ns.Data.FACTION_CLASSES.Alliance) do
		alliance[class] = true
	end
	check(not alliance.SHAMAN, "no Alliance shamans on Classic")
	check(alliance.PALADIN, "Alliance paladins are there")
	local reachable = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		reachable[class] = true
	end
	check(not reachable.SHAMAN and not reachable.DEATHKNIGHT, "and the matcher's class list agrees")
end)

--[[
	Relics are armor with no material, so the armor path once offered them to whoever their stats
	suited: a Stamina idol went to a warlock. Each routes through the weapon matrix to the one class
	that can equip it, and a statless one still finds that class on the baseline.
]]
local function relic(ns, subclassID, stats)
	local def = Stub.Item({
		name = "Test Relic",
		quality = 3,
		reqLevel = 57,
		itemLevel = 63,
		equipLoc = "INVTYPE_RELIC",
		classID = 4,
		subclassID = subclassID,
		bindType = 2,
		stats = stats,
	})
	return ns.Scanner:Describe(def.link)
end

test("each relic reaches only the class that can equip it", function()
	for _, flavor in ipairs({ "Vanilla", "TBC", "Camelot" }) do
		local ns = loadFlavor(flavor)
		local cases = {
			{ 7, "PALADIN", { ITEM_MOD_SPELL_HEALING_DONE_SHORT = 20 } },
			{ 8, "DRUID", { ITEM_MOD_STAMINA_SHORT = 10 } },
			{ 9, "SHAMAN", { ITEM_MOD_SPELL_POWER_SHORT = 12 } },
			{ 7, "PALADIN", nil },
		}
		for _, case in ipairs(cases) do
			local subclassID, owner, stats = case[1], case[2], case[3]
			local label = flavor .. " subclass " .. subclassID .. (stats and "" or ", statless")
			local verdict = ns.Matcher:Verdict(relic(ns, subclassID, stats))
			-- Classic Era's Alliance has no shamans, so a totem there has nobody to go to.
			if contains(ns.Matcher:Classes(), owner) then
				equal(sorted(verdict.admitted), owner, label .. " admits only its class")
				equal(verdict.state, ns.Matcher.GIFT, label .. " is a gift")
			else
				equal(sorted(verdict.admitted), "", label .. " admits nobody on this side")
			end
		end
	end
end)
