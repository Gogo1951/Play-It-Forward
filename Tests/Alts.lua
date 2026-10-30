--[[
	Your own characters as recipients (maintainer ruling, 2026-10-29).

	Matching goes Alts > Guild > Strangers, but only among the classes an item suits best: an alt
	never takes what fits a stranger better. Under the default level rule an alt holds any gear it
	has yet to grow into, so a level 12 warrior takes level 50 strength plate. An alt can take
	several items in one run, is never on the gift cooldown, and mail to it adds nothing to the
	Generosity totals. The picker groups names under Your Alts, Your Guild and Strangers.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Level 50 strength plate: a warrior's, years ahead of a level 12 warrior.
local function strengthPlate(name)
	return Stub.Item({
		name = name or "Bulwark Breastplate",
		reqLevel = 50,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4, -- PLATE
		stats = { ITEM_MOD_STRENGTH_SHORT = 15, ITEM_MOD_STAMINA_SHORT = 10 },
	})
end

local function seedAlt(ns, alt)
	ns.db.global.characters[alt.name .. "-" .. (alt.realm or "Test")] = {
		name = alt.name,
		realm = alt.realm or "Test",
		class = alt.class,
		level = alt.level,
		faction = alt.faction or "Alliance",
	}
end

local WARRIOR_ALT = { name = "Brickhouse", class = "WARRIOR", level = 12 }

-- Opens the mailbox and presses Find Recipients: nothing is matched before the press.
local function atMailbox(ns, defs)
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()
end

local function names(list)
	local out = {}
	for index, person in ipairs(list) do
		out[index] = person.name
	end
	return table.concat(out, ",")
end

--------------------------------------------------------------------------------
-- Recording
--------------------------------------------------------------------------------

test("a character records itself at login", function()
	local ns = load()
	ns.fire("PLAYER_LOGIN")
	local me = ns.db.global.characters["Tester-Test"]
	check(me ~= nil, "recorded under its qualified name")
	equal(me and me.class, "MAGE", "with its class")
	equal(me and me.level, 60, "and level")
end)

test("a level up updates the record", function()
	local ns = load()
	ns.fire("PLAYER_LOGIN")
	ns.fire("PLAYER_LEVEL_UP", 61)
	equal(ns.db.global.characters["Tester-Test"].level, 61, "the new level, from the event")
end)

test("only alts on this realm and faction are offered, never this character", function()
	local ns = load()
	ns.fire("PLAYER_LOGIN")
	seedAlt(ns, WARRIOR_ALT)
	seedAlt(ns, { name = "Farshore", class = "WARRIOR", level = 20, realm = "Elsewhere" })
	seedAlt(ns, { name = "Redtusk", class = "WARRIOR", level = 20, faction = "Horde" })
	equal(names(ns.Alts:Read()), "Brickhouse", "one alt in reach")
	local stats = ns.Alts:Stats()
	equal(stats.current, 1, "this character left out")
	equal(stats.otherRealm, 1, "the other realm left out")
	equal(stats.otherFaction, 1, "the other faction left out")
end)

--------------------------------------------------------------------------------
-- Connected Realms
--------------------------------------------------------------------------------

-- Logged in on the named realm, on the named client, in the Americas.
local function loadOn(realm, flavor)
	Stub.flavor = flavor or "Vanilla"
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT, function()
		GetRealmName = function()
			return realm
		end
		GetNormalizedRealmName = GetRealmName
	end)
	Stub.flavor = "Vanilla"
	assert(ok, ns)
	ns.fire("PLAYER_LOGIN")
	return ns
end

--[[
	Classic Era's realms are connected in clusters, and mail crosses realms within one. Mankrik and
	Pagle share a cluster; Azuresong is PvE too but in another, so it is out of reach.
]]
test("an alt on a connected realm is offered, addressed with its realm", function()
	local ns = loadOn("Mankrik")
	seedAlt(ns, { name = "Joe", class = "WARRIOR", level = 20, realm = "Pagle" })
	seedAlt(ns, { name = "Farshore", class = "WARRIOR", level = 20, realm = "Azuresong" })
	equal(names(ns.Alts:Read()), "Joe-Pagle", "the Pagle alt, as Name-Realm")
	local stats = ns.Alts:Stats()
	equal(stats.connected, 1, "counted as on a connected realm")
	equal(stats.otherRealm, 1, "Azuresong is in another cluster")
end)

test("a realm the data writes with a space matches the client's spelling without one", function()
	local ns = loadOn("Azuresong")
	seedAlt(ns, { name = "Blanche", class = "WARRIOR", level = 20, realm = "OldBlanchy" })
	equal(names(ns.Alts:Read()), "Blanche-OldBlanchy", "Old Blanchy is Azuresong's cluster")
end)

test("an alt on a connected realm is mailed as Name-Realm and forgotten when refused", function()
	local ns = loadOn("Mankrik")
	seedAlt(ns, { name = "Joe", class = "WARRIOR", level = 12, realm = "Pagle" })
	atMailbox(ns, { strengthPlate() })
	ns.UI:Distribute()
	equal(Stub.sent[1] and Stub.sent[1].recipient, "Joe-Pagle", "mailed across the cluster")

	ns.fire("UI_ERROR_MESSAGE", 1, ERR_MAIL_TARGET_NOT_FOUND)

	equal(ns.db.global.characters["Joe-Pagle"], nil, "the right record is forgotten")
end)

-- The faction rule holds across a cluster as on one realm.
test("an alt of the other faction on a connected realm is left out", function()
	local ns = loadOn("Mankrik")
	seedAlt(ns, { name = "Redtusk", class = "WARRIOR", level = 20, realm = "Pagle", faction = "Horde" })
	equal(names(ns.Alts:Read()), "", "nobody in reach")
	equal(ns.Alts:Stats().otherFaction, 1, "left out for faction")
end)

--[[
	Each flavor has its own clusters, and names repeat between them: Mists Classic's Pagle is
	connected to Galakras and not to Mankrik, unlike Classic Era's.
]]
test("Mists Classic uses its own clusters", function()
	local ns = loadOn("Pagle", "Mists")
	seedAlt(ns, { name = "Joe", class = "WARRIOR", level = 20, realm = "Galakras" })
	seedAlt(ns, { name = "Farshore", class = "WARRIOR", level = 20, realm = "Mankrik" })
	equal(names(ns.Alts:Read()), "Joe-Galakras", "Galakras is in reach, Mankrik is not")
end)

-- The megaserver flavors list no clusters, so only the alt's own realm reaches it.
test("a megaserver flavor offers no alt from another realm", function()
	local ns = loadOn("Mankrik", "TBC")
	seedAlt(ns, { name = "Joe", class = "WARRIOR", level = 20, realm = "Pagle" })
	equal(names(ns.Alts:Read()), "", "Pagle is out of reach here")
end)

--------------------------------------------------------------------------------
-- Matching
--------------------------------------------------------------------------------

test("a low level alt holds plate it has yet to grow into", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient and items[1].recipient.name, "Brickhouse", "the warrior alt takes it")
end)

test("an alt can take several items in one run", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	local items = atMailbox(ns, { strengthPlate("First Plate"), strengthPlate("Second Plate") })
	equal(items[1].recipient and items[1].recipient.name, "Brickhouse", "the first")
	equal(items[2].recipient and items[2].recipient.name, "Brickhouse", "and the second")

	Stub.sent = {}
	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")
	equal(#Stub.sent, 2, "both go out in one run")
end)

test("an alt only takes what its class is a best fit for", function()
	local ns = load()
	seedAlt(ns, { name = "Sparkle", class = "MAGE", level = 12 })
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "a mage alt never holds warrior plate")
end)

-- Highest Gear Level set to Their Level +3 on the alt's pane.
test("an alt with a near top end is not sent gear far above it", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	ns.db.global.characters["Brickhouse-Test"].levelsAbove = 3
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "level 12 is nowhere near level 50 plate")
end)

--[[
	The range is counted from the alt's level by the level its class equips the item at. A level
	47 warrior and plate from 44 to 60: at the defaults, its own level and up.
]]
local function plateAt(level)
	return Stub.Item({
		name = "Plate " .. level,
		reqLevel = level,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4, -- PLATE
		stats = { ITEM_MOD_STRENGTH_SHORT = 15, ITEM_MOD_STAMINA_SHORT = 10 },
	})
end

-- A fresh session per item: a second Find Recipients in one session steps the plan rather than rescanning.
local function takes(levels, item)
	local ns = load()
	seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 47 })
	local entry = ns.db.global.characters["Brickhouse-Test"]
	entry.levelsBelow, entry.levelsAbove = levels.below, levels.above
	local items = atMailbox(ns, { plateAt(item) })
	return (items[1].recipient and items[1].recipient.name) == "Brickhouse", ns, entry
end

test("at the defaults an alt takes gear from its own level up, with no top end", function()
	local defaults = {}
	check(not takes(defaults, 46), "nothing below its level")
	check(takes(defaults, 47), "its own level")
	check(takes(defaults, 60), "and anything above")
end)

test("the lowest and highest gear levels bound what an alt takes", function()
	local range = { below = 2, above = 3 }
	local _, ns, entry = takes(range, 45)
	equal(table.concat({ ns.Alts:LevelRange(entry) }, "-"), "45-50", "levels 45 to 50")
	check(takes(range, 45), "two below")
	check(not takes(range, 44), "not three below")
	check(takes(range, 50), "three above")
	check(not takes(range, 51), "not four above")
end)

test("an alt left unticked is not offered anything", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	ns.db.global.characters["Brickhouse-Test"].include = false
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "the warrior alt is left out")
end)

--[[
	A character at the level cap starts unticked: it has outgrown what the add-on gives away. The
	client's cap is stubbed at 60, and a tick the player makes still wins.
]]
local function loadCapped()
	local ns = load()
	GetMaxPlayerLevel = function()
		return 60
	end
	return ns
end

test("a character at the level cap starts unticked, and a tick wins", function()
	local ns = loadCapped()
	seedAlt(ns, { name = "Capped", class = "WARRIOR", level = 60 })
	seedAlt(ns, WARRIOR_ALT)
	local capped = ns.db.global.characters["Capped-Test"]
	check(not ns.Alts:Included(capped), "unticked at 60")
	check(ns.Alts:Included(ns.db.global.characters["Brickhouse-Test"]), "a level 12 stays ticked")
	equal(names(ns.Alts:Read()), "Brickhouse", "only the level 12 is offered")

	capped.include = true
	check(ns.Alts:Included(capped), "ticked by hand, it is included")
	GetMaxPlayerLevel = nil
end)

test("a character reaching the level cap unticks itself unless ticked by hand", function()
	local ns = loadCapped()
	seedAlt(ns, { name = "Dinger", class = "WARRIOR", level = 59 })
	local entry = ns.db.global.characters["Dinger-Test"]
	check(ns.Alts:Included(entry), "ticked at 59")
	entry.level = 60
	check(not ns.Alts:Included(entry), "unticked once it reaches 60")
	GetMaxPlayerLevel = nil
end)

--[[
	An alt is judged by its own specs: paladins default to Holy, but an alt with no spec recorded
	starts with every spec ticked, so it holds strength plate like any warrior until the player
	narrows it. One that recorded a spec starts on that spec alone.
]]
test("a paladin alt holds strength plate though paladins default to holy", function()
	local ns = load()
	seedAlt(ns, { name = "Hammertime", class = "PALADIN", level = 12 })
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient and items[1].recipient.name, "Hammertime", "the paladin alt takes it")
end)

test("an alt starts on the spec it last played", function()
	local ns = load()
	seedAlt(ns, { name = "Hammertime", class = "PALADIN", level = 12 })
	local entry = ns.db.global.characters["Hammertime-Test"]
	entry.spec = "Holy"
	local specs = ns.Alts:SpecsFor(entry)
	check(specs.Holy and not specs.Retribution and not specs.Protection, "only Holy is ticked")
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "so a holy paladin alt does not hold strength plate")
end)

test("the specs ticked for an alt win over every spec and the one it last played", function()
	local ns = load()
	seedAlt(ns, { name = "Hammertime", class = "PALADIN", level = 12 })
	local entry = ns.db.global.characters["Hammertime-Test"]
	entry.spec = "Retribution"
	entry.specs = { Holy = true }
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "a holy paladin alt does not hold strength plate")
end)

test("a login keeps the choices made for that character", function()
	local ns = load()
	ns.db.global.characters["Tester-Test"] =
		{ name = "Tester", class = "MAGE", include = false, levelsBelow = 2, levelsAbove = 3 }
	ns.fire("PLAYER_LOGIN")
	local entry = ns.db.global.characters["Tester-Test"]
	equal(entry.include, false, "still unticked")
	equal(entry.levelsBelow, 2, "still two below")
	equal(entry.levelsAbove, 3, "and three above")
	equal(entry.realm, "Test", "and what the character is was refreshed")
end)

test("turning Send to Alts off leaves alts out", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	ns.db.profile.sendToAlts = false
	local items = atMailbox(ns, { strengthPlate() })
	equal(items[1].recipient, nil, "nobody, with no alts and no search yet")
end)

test("an alt comes before a guildmate and a stranger of the same fit", function()
	local ns = load()
	seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 47 })
	ns.MatchList:AddResults({
		{ name = "Guildie", class = "WARRIOR", level = 48, guild = true },
		{ name = "Stranger", class = "WARRIOR", level = 49 },
	})
	local items = atMailbox(ns, { strengthPlate() })
	local ranked = ns.UI:Candidates(items[1])
	equal(ranked[1] and ranked[1].name, "Brickhouse", "your alt first")
	equal(ranked[2] and ranked[2].name, "Guildie", "then your guild")
	equal(ranked[3] and ranked[3].name, "Stranger", "then strangers")
end)

--------------------------------------------------------------------------------
-- The picker and the tally
--------------------------------------------------------------------------------

test("the picker groups names under Your Alts, Your Guild and Strangers", function()
	local ns = load()
	seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 47 })
	ns.MatchList:AddResults({
		{ name = "Guildie", class = "WARRIOR", level = 48, guild = true },
		{ name = "Stranger", class = "WARRIOR", level = 49 },
	})
	local items = atMailbox(ns, { strengthPlate() })
	local order = {}
	for _, option in ipairs(ns.UI:PickerOptions(items[1])) do
		if option.header then
			order[#order + 1] = option.text:find(ns.L["PICKER_SECTION_ALTS"], 1, true) and "alts"
				or option.text:find(ns.L["PICKER_SECTION_GUILD"], 1, true) and "guild"
				or "strangers"
		elseif option.pick then
			order[#order + 1] = option.pick.name
		end
	end
	equal(table.concat(order, ","), "alts,Brickhouse,guild,Guildie,strangers,Stranger", "three sections, in order")
end)

test("an empty section is left out of the picker", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	local items = atMailbox(ns, { strengthPlate() })
	local headers = 0
	for _, option in ipairs(ns.UI:PickerOptions(items[1])) do
		if option.header then
			headers = headers + 1
		end
	end
	equal(headers, 1, "only Your Alts")
end)

test("mail to your own alt adds nothing to the Generosity totals", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	atMailbox(ns, { strengthPlate() })
	local before = ns.db.global.stats.gifts
	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")
	equal(ns.db.global.stats.gifts, before, "no gift counted")
end)

--[[
	Every character is remembered for good, so one deleted or renamed since was offered first for
	everything its class suits, every session. The server's refusal is the only word that it is gone.
]]
test("an alt the server refuses mail for is forgotten", function()
	local ns = load()
	seedAlt(ns, WARRIOR_ALT)
	atMailbox(ns, { strengthPlate() })
	ns.UI:Distribute()
	equal(Stub.sent[1] and Stub.sent[1].recipient, "Brickhouse", "mailed to the alt")

	ns.fire("UI_ERROR_MESSAGE", 1, ERR_MAIL_TARGET_NOT_FOUND)

	equal(ns.db.global.characters["Brickhouse-Test"], nil, "no longer recorded")
	equal(names(ns.Alts:Read()), "", "and no longer offered")
end)
