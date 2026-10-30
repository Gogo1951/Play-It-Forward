--[[
	Mists of Pandaria Classic: the flavor whose classes, specs and stats differ most from the
	Classic trees every other flavor scores on.

	What is pinned is what Mists changed: monks exist, a druid has four specs and is scored on the
	same three-tree scale as everybody else, a hunter holds no melee weapon and wants no Intellect,
	relics are gone, the ratings Mists gear is made of are read, and the TOC loads exactly the
	folder these cases load.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load(flavor)
	Stub.flavor = flavor or "Mists"
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT)
	Stub.flavor = "Vanilla"
	assert(ok, ns)
	-- Every spec on: these cases pin what each spec sums to, not which ones ship turned on.
	return Harness.AllSpecs(ns)
end

local function contains(list, wanted)
	for _, value in ipairs(list or {}) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function describe(ns, fields)
	fields.reqLevel = fields.reqLevel or 20
	fields.itemLevel = fields.itemLevel or fields.reqLevel
	return assert(ns.Scanner:Describe(Stub.Item(fields).link), "fixture did not describe")
end

--------------------------------------------------------------------------------
-- Loading
--------------------------------------------------------------------------------

-- The harness loads a folder by convention; this holds the TOC the client reads to the same list.
test("the Mists TOC names the Mists flavor and loads every Mists data file", function()
	local handle = assert(io.open(ADDON_ROOT .. "/Play-It-Forward_Mists.toc", "r"))
	local toc = handle:read("*a")
	handle:close()

	check(toc:find("## X-Flavor: Mists", 1, true), "X-Flavor is Mists")
	check(toc:find("## Interface: 505", 1, true), "an interface number on the 5.5 client")

	local listed = {}
	for line in toc:gmatch("[^\r\n]+") do
		if line:find("^Data/") then
			listed[#listed + 1] = line
			local file = io.open(ADDON_ROOT .. "/" .. line, "r")
			check(file ~= nil, line .. " exists")
			if file then
				file:close()
			end
			check(not line:find("^Data/%a+/") or line:find("^Data/Mists/"), line .. " is Mists' own folder")
		end
	end
	for _, name in ipairs({
		"Match-Stat-Budget",
		"Scan-Food",
		"Scan-Potions",
		"Scan-Scrolls",
		"Scan-Oils-Stones",
		"Recipients-Zones",
		"Recipients-Realms",
		"Match-Weapons",
		"Match-Armor",
		"Match-Classes",
		"Match-Specs",
		"Match-Rules",
		"Scan-Stats",
	}) do
		check(contains(listed, ("Data/Mists/%s-Mists.lua"):format(name)), name .. " is listed")
	end
end)

test("monks are a class both factions can roll", function()
	local ns = load()
	check(contains(ns.Data.FACTION_CLASSES.Alliance, "MONK"), "Alliance monks")
	check(contains(ns.Data.FACTION_CLASSES.Horde, "MONK"), "Horde monks")
	check(contains(ns.Data.FACTION_CLASSES.Alliance, "SHAMAN"), "and Alliance shamans, since Cataclysm")
	check(contains(ns.Matcher:Classes(), "MONK"), "the matcher reaches them")
	check(ns.Data.STAT_WEIGHTS.MONK ~= nil, "and has weights for them")

	local vanilla = load("Vanilla")
	check(not contains(vanilla.Matcher:Classes(), "MONK"), "nobody else's client has one")
end)

--------------------------------------------------------------------------------
-- Weights
--------------------------------------------------------------------------------

test("each spec builds on one primary stat", function()
	local weights = load().Data.STAT_WEIGHTS

	equal(weights.ROGUE.AGILITY, 6, "every rogue spec on Agility")
	equal(weights.ROGUE.STRENGTH, nil, "and none on Strength")
	equal(weights.HUNTER.INTELLECT, nil, "hunters lost their mana and their Intellect")
	equal(weights.WARRIOR.AGILITY, nil, "a warrior gets nothing from Agility")
	equal(weights.SHAMAN.AGILITY, 2, "Enhancement is an Agility spec")
	equal(weights.SHAMAN.STRENGTH, nil, "and no longer a Strength one")
	equal(weights.SHAMAN.INTELLECT, 4, "Elemental and Restoration")
	equal(weights.MONK.AGILITY, 4, "Brewmaster and Windwalker")
	equal(weights.MONK.INTELLECT, 2, "Mistweaver")
	equal(weights.MAGE.SPIRIT, nil, "a mage's Spirit is nothing")
	equal(weights.PRIEST.SPIRIT, 3, "healing mana to two priest specs, hit to Shadow")
	equal(weights.PRIEST.INTELLECT, 6, "and Intellect is every priest spec's")
end)

--[[
	A druid's four specs summed raw would put Intellect on two of them at 4 -- a shaman's two of
	three -- and every stat all four share at 8, past a rogue's 6 on his own Agility.
]]
test("four druid specs are scored on the three-tree scale", function()
	local weights = load().Data.STAT_WEIGHTS

	equal(weights.DRUID.INTELLECT, 3, "Balance and Restoration, two of four")
	equal(weights.DRUID.AGILITY, 3, "Feral and Guardian, two of four")
	equal(weights.DRUID.STRENGTH, nil, "no druid spec on Strength")
	equal(weights.DRUID.HASTE, 3, "a stat all four use weighs what all three of a rogue's do")
	equal(weights.ROGUE.HASTE, 3, "the rogue's, for comparison")
end)

test("Classic's trees are untouched on every other flavor", function()
	local vanilla = load("Vanilla").Data.STAT_WEIGHTS
	equal(vanilla.ROGUE.AGILITY, 6, "rogue Agility")
	equal(vanilla.HUNTER.INTELLECT, 2, "Classic hunters still want Intellect")
	equal(vanilla.DRUID.INTELLECT, 4, "Classic druids sum three trees unscaled")
	equal(vanilla.ROGUE.HASTE, nil, "and nobody weighs haste")
end)

--------------------------------------------------------------------------------
-- Stats
--------------------------------------------------------------------------------

test("haste, mastery and expertise are read off a Mists item", function()
	local ns = load()
	local item = describe(ns, {
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 2, -- LEATHER
		stats = {
			ITEM_MOD_AGILITY_SHORT = 20,
			ITEM_MOD_HASTE_RATING_SHORT = 10,
			ITEM_MOD_MASTERY_RATING_SHORT = 8,
			ITEM_MOD_EXPERTISE_RATING_SHORT = 6,
		},
	})
	equal(item.stats.HASTE, 10, "haste")
	equal(item.stats.MASTERY, 8, "mastery")
	equal(item.stats.EXPERTISE, 6, "expertise")
end)

--[[
	Ratings count toward coverage: the rogue uses all of an Agility-and-haste roll, so it is his
	and a monk's, and a warrior -- who scores the haste alone -- is never in contention for it.
]]
test("an Agility leather roll goes to the Agility classes", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(describe(ns, {
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 2, -- LEATHER
		stats = { ITEM_MOD_AGILITY_SHORT = 20, ITEM_MOD_HASTE_RATING_SHORT = 10 },
	}))
	check(contains(verdict.contenders, "ROGUE"), "the rogue competes")
	check(contains(verdict.contenders, "MONK"), "so does the monk")
	check(not contains(verdict.contenders, "WARRIOR"), "the warrior does not")
	check(not contains(verdict.contenders, "MAGE"), "nor a mage, who cannot wear it")
end)

--------------------------------------------------------------------------------
-- Weapons and relics
--------------------------------------------------------------------------------

test("a hunter holds a ranged weapon and nothing else", function()
	local ns = load()
	for _, key in ipairs({ "1H_SWORD", "2H_AXE", "DAGGER", "FIST", "POLEARM", "STAFF" }) do
		equal(ns.Data.WeaponPriorityFor(key, "HUNTER"), nil, "no hunter " .. key)
	end
	check(ns.Data.WeaponPriorityFor("BOW", "HUNTER") ~= nil, "but a bow")
	equal(ns.Data.WeaponPriorityFor("GUN", "WARRIOR"), nil, "and a warrior no longer pulls with a gun")

	local verdict = ns.Matcher:Verdict(describe(ns, {
		equipLoc = "INVTYPE_2HWEAPON",
		classID = 2,
		subclassID = 1, -- 2H axe
		stats = { ITEM_MOD_AGILITY_SHORT = 20 },
	}))
	check(not contains(verdict.admitted, "HUNTER"), "an Agility two-hander is not offered to a hunter")
end)

test("a monk trains fists, one-handers, polearms and staves", function()
	local ns = load()
	for _, key in ipairs({ "FIST", "1H_SWORD", "1H_MACE", "1H_AXE", "POLEARM", "STAFF" }) do
		check(ns.Data.WeaponPriorityFor(key, "MONK") ~= nil, "monk " .. key)
	end
	for _, key in ipairs({ "DAGGER", "2H_SWORD", "2H_MACE", "2H_AXE", "SHIELD", "BOW" }) do
		equal(ns.Data.WeaponPriorityFor(key, "MONK"), nil, "no monk " .. key)
	end
end)

test("relics are gone, so nobody is offered one", function()
	local ns = load()
	for _, pair in ipairs({ { "LIBRAM", "PALADIN" }, { "IDOL", "DRUID" }, { "TOTEM", "SHAMAN" }, { "RELIC", "PRIEST" } }) do
		equal(ns.Data.WeaponPriorityFor(pair[1], pair[2]), nil, pair[2] .. " " .. pair[1])
	end
end)

--------------------------------------------------------------------------------
-- Consumables
--------------------------------------------------------------------------------

test("hunters stopped drinking, and monks started", function()
	local classes = load().Data.CONSUMABLE_CLASSES
	check(not contains(classes.MANA, "HUNTER"), "no mana for a hunter")
	check(contains(classes.MANA, "MONK"), "a Mistweaver's mana")
	check(contains(classes.AGILITY, "MONK") and contains(classes.AGILITY, "SHAMAN"), "Agility scrolls")
	check(not contains(classes.STRENGTH, "DRUID"), "no Strength for a druid")
	check(not contains(classes.SPIRIT, "MAGE"), "no Spirit for a mage")

	local vanilla = load("Vanilla").Data.CONSUMABLE_CLASSES
	check(contains(vanilla.MANA, "HUNTER"), "Classic hunters still drink")
end)

--------------------------------------------------------------------------------
-- Item rules
--------------------------------------------------------------------------------

-- A Mists mage gets nothing from Spirit, so Intellect and Spirit is the healers'.
test("Intellect and Spirit goes to the healers, not the mage", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(describe(ns, {
		equipLoc = "INVTYPE_FINGER",
		classID = 4,
		subclassID = 0,
		stats = { ITEM_MOD_INTELLECT_SHORT = 10, ITEM_MOD_SPIRIT_SHORT = 10 },
	}))
	check(not contains(verdict.contenders, "MAGE"), "the mage is not in contention")
	check(contains(verdict.contenders, "MONK"), "a Mistweaver is")
	check(contains(verdict.contenders, "PALADIN"), "and a Holy paladin")
end)

test("an Agility one-handed mace is a monk's as much as a rogue's", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(describe(ns, {
		equipLoc = "INVTYPE_WEAPON",
		classID = 2,
		subclassID = 4, -- 1H mace
		stats = { ITEM_MOD_AGILITY_SHORT = 12 },
	}))
	check(contains(verdict.contenders, "MONK"), "the monk competes")
	check(contains(verdict.contenders, "ROGUE"), "beside the rogue")
end)

-- No two-hand rule on Mists: the plate classes own a Strength two-hander alike.
test("a Strength two-handed mace stays with every plate class", function()
	local ns = load()
	local verdict = ns.Matcher:Verdict(describe(ns, {
		equipLoc = "INVTYPE_2HWEAPON",
		classID = 2,
		subclassID = 5, -- 2H mace
		stats = { ITEM_MOD_STRENGTH_SHORT = 20 },
	}))
	for _, class in ipairs({ "WARRIOR", "PALADIN", "DEATHKNIGHT" }) do
		check(contains(verdict.contenders, class), class .. " competes")
	end
end)
