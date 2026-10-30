--[[
	Which specs count. Nobody can see another player's spec, so the add-on assumes some: Protection
	paladins, Enhancement shamans, Arms and Balance start off. The Recipients panel's Classes & Specs
	section turns any spec on or off. A spec that is off counts for nothing: a paladin with only
	Holy on is never offered Strength plate.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load(flavor)
	Stub.flavor = flavor or "Vanilla"
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT)
	Stub.flavor = "Vanilla"
	assert(ok, ns)
	return ns
end

local function contains(list, wanted)
	for _, value in ipairs(list or {}) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function gear(ns, subclassID, stats, fields)
	fields = fields or {}
	local def = Stub.Item({
		name = "Test Gear",
		quality = 2,
		reqLevel = fields.reqLevel or 45,
		itemLevel = (fields.reqLevel or 45) + 4,
		equipLoc = fields.equipLoc or "INVTYPE_CHEST",
		classID = fields.classID or 4,
		subclassID = subclassID,
		bindType = 2,
		stats = stats,
	})
	return assert(ns.Scanner:Describe(def.link), "fixture did not describe")
end

local PLATE, MAIL, CLOTH = 4, 3, 1

-- The panel's own switch, so the cases drive what the player drives.
local function toggle(ns, class, key, value)
	local panel = ns.BuildRecipientsOptions()
	local row = panel.args["class" .. class]
	assert(row, "no row for " .. class)
	for _, control in pairs(row.args) do
		if control.type == "toggle" and control.name == ns.L["SPEC_" .. key] then
			control.set(nil, value)
			return control
		end
	end
	error("no " .. key .. " switch for " .. class)
end

local function enabled(ns, class, key)
	for _, spec in ipairs(ns.Data.SPECS[class]) do
		if spec.key == key then
			return ns.Data.SpecEnabled(class, spec)
		end
	end
	error("no spec " .. key)
end

--------------------------------------------------------------------------------
-- The defaults
--------------------------------------------------------------------------------

test("the shipped spec defaults", function()
	local ns = load()
	check(not enabled(ns, "WARRIOR", "Arms"), "arms off")
	check(enabled(ns, "WARRIOR", "Fury") and enabled(ns, "WARRIOR", "Protection"), "fury and protection on")
	check(enabled(ns, "PALADIN", "Holy"), "holy paladin on")
	check(not enabled(ns, "PALADIN", "Protection"), "protection paladin off")
	check(enabled(ns, "PALADIN", "Retribution"), "retribution on")
	check(enabled(ns, "DRUID", "Restoration") and enabled(ns, "DRUID", "Feral"), "restoration and feral on")
	check(not enabled(ns, "DRUID", "Balance"), "balance off")
	check(enabled(ns, "SHAMAN", "Restoration"), "restoration shaman on")
	check(enabled(ns, "SHAMAN", "Elemental"), "elemental on")
	check(not enabled(ns, "SHAMAN", "Enhancement"), "enhancement off")
end)

test("a shaman is not offered agility mail", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(gear(ns, MAIL, { ITEM_MOD_AGILITY_SHORT = 12 }))
	check(contains(verdict.contenders, "HUNTER"), "the hunter leads")
	check(not contains(verdict.admitted, "SHAMAN"), "the restoration shaman has no claim on it")
end)

test("mp5 is a healer's", function()
	local ns = load()
	for _, class in ipairs({ "PRIEST", "PALADIN", "SHAMAN", "DRUID" }) do
		check((ns.Data.STAT_WEIGHTS[class].MP5 or 0) >= 2, class .. " builds on mp5")
	end
end)

--------------------------------------------------------------------------------
-- Turning specs on and off
--------------------------------------------------------------------------------

test("turning retribution off takes the paladin off strength plate", function()
	local ns = load()
	local item = gear(ns, PLATE, { ITEM_MOD_STRENGTH_SHORT = 12 })
	check(contains(ns.Matcher:Verdict(item).admitted, "PALADIN"), "a retribution paladin is offered it")
	toggle(ns, "PALADIN", "Retribution", false)
	check(not contains(ns.Matcher:Verdict(item).admitted, "PALADIN"), "a holy-only paladin is not")
end)

test("a switch saves only what differs from the default", function()
	local ns = load()
	toggle(ns, "PALADIN", "Retribution", false)
	equal(ns.db.profile.specs.PALADIN.Retribution, false, "the choice is kept")
	toggle(ns, "PALADIN", "Retribution", true)
	equal(ns.db.profile.specs.PALADIN.Retribution, nil, "back at the default, nothing is kept")
end)

test("reset puts every spec back", function()
	local ns = load()
	toggle(ns, "PALADIN", "Retribution", false)
	toggle(ns, "MAGE", "Fire", false)
	ns.BuildRecipientsOptions().args.reset.func()
	check(enabled(ns, "PALADIN", "Retribution"), "retribution on again")
	check(enabled(ns, "MAGE", "Fire"), "fire on again")
end)

test("a class with every spec off is offered no gear, but still its consumables", function()
	local ns = load()
	for _, key in ipairs({ "Arcane", "Fire", "Frost" }) do
		toggle(ns, "MAGE", key, false)
	end
	local verdict = ns.Matcher:Verdict(gear(ns, CLOTH, { ITEM_MOD_INTELLECT_SHORT = 12 }))
	check(not contains(verdict.eligible, "MAGE"), "no mage on intellect cloth")
	check(contains(verdict.contenders, "PRIEST"), "the other casters still are")
	check(not ns.Data.ClassEnabled("MAGE"), "the class reads as off")
end)

test("healing gear follows the healer specs that are on", function()
	local ns = load()
	local item = gear(ns, CLOTH, { ITEM_MOD_SPELL_HEALING_DONE_SHORT = 20 })
	check(contains(ns.Matcher:Verdict(item).eligible, "PRIEST"), "a priest heals by default")

	toggle(ns, "PRIEST", "Discipline", false)
	toggle(ns, "PRIEST", "Holy", false)
	check(not contains(ns.Matcher:Verdict(item).eligible, "PRIEST"), "a shadow-only priest does not")
end)

-- What a profile switch does through ns:ApplyProfile, which Features/Core.lua defines at ADDON_LOADED.
test("rebuilding reads the specs the profile holds now", function()
	local ns = load()
	toggle(ns, "PALADIN", "Retribution", false)
	equal(ns.Data.STAT_WEIGHTS.PALADIN.STRENGTH, nil, "a holy-only paladin has no strength")
	ns.db.profile.specs = {}
	ns.Data.RebuildStatWeights()
	check(ns.Data.STAT_WEIGHTS.PALADIN.STRENGTH ~= nil, "the weights follow the new profile")
end)

-- Spec names come from the game wherever it can name them, and from our strings elsewhere.
test("spec names come from the game where it has them", function()
	local ns = load()
	local arms = ns.Data.SPECS.WARRIOR[1]
	equal(ns.SpecName("WARRIOR", 1, arms), ns.L["SPEC_" .. arms.key], "another class's tree falls back to our string")
	-- Answering with the key itself shows which string was read, since enUS spells both the same.
	local strings = ns.L
	ns.L = setmetatable({}, {
		__index = function(_, key)
			return key
		end,
	})
	for _, class in ipairs({ "PALADIN", "WARRIOR" }) do
		for index, spec in ipairs(ns.Data.SPECS[class]) do
			if spec.key == "Protection" then
				local expected = class == "PALADIN" and "SPEC_PALADIN_Protection" or "SPEC_Protection"
				equal(ns.SpecName(class, index, spec), expected, "a shared key reads its class's own string")
			end
		end
	end
	ns.L = strings

	GetTalentTabInfo = function(index)
		return 100 + index, "Tree " .. index
	end
	equal(ns.SpecName("MAGE", 2, ns.Data.SPECS.MAGE[2]), "Tree 2", "the logged-in class's tree comes from the game")
	GetTalentTabInfo = nil

	C_CreatureInfo.GetClassInfo = function(classID)
		return classID == 1 and { classFile = "WARRIOR" } or nil
	end
	GetSpecializationInfoForClassID = function(classID, index)
		return 70 + index, classID == 1 and ("Spec " .. index) or nil
	end
	equal(ns.SpecName("WARRIOR", 1, arms), "Spec 1", "any class's spec where the client names them")
	C_CreatureInfo.GetClassInfo, GetSpecializationInfoForClassID = nil, nil
end)
