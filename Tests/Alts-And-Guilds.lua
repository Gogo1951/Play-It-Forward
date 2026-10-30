--[[
	The My Alts and My Guilds panels and the saved guild list behind them (maintainer rulings,
	2026-10-29).

	Every guild any of your characters is in is saved account-wide at that character's login, so
	whichever character you are on reaches the levelling players in all of them. A saved roster
	counts members active in the 3 days before the scan, and is ignored once it is older than the
	Ignore Saved Guilds setting. Both panels are trees, one node per alt or guild. Each alt has a
	tick, a Delete, the specs it is mailed gear for and whether it holds gear it has yet to grow
	into; each guild has a tick and an Include beside every active member, ticked by default, and no
	Delete. Alts and members are listed alphabetically, members as "Name - Realm".
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local DAY = 24 * 60 * 60
local GUILD_KEY = "Test:Alliance:Far Guild"

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function strengthPlate()
	return Stub.Item({
		name = "Bulwark Breastplate",
		reqLevel = 50,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4,
		stats = { ITEM_MOD_STRENGTH_SHORT = 15, ITEM_MOD_STAMINA_SHORT = 10 },
	})
end

local function atMailbox(ns, defs)
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()
end

-- A guild one of your other characters is in, saved some days ago.
local function seedGuild(ns, fields)
	fields = fields or {}
	ns.db.global.guilds[fields.key or GUILD_KEY] = {
		name = "Far Guild",
		realm = fields.realm or "Test",
		faction = fields.faction or "Alliance",
		scanned = time() - (fields.age or 1) * DAY,
		scannedBy = "Otheralt",
		include = fields.include,
		members = fields.members or {
			{ name = "Guildy", level = 48, class = "WARRIOR", days = fields.days or 1 },
		},
	}
end

local function recipient(items)
	return items[1].recipient and items[1].recipient.name
end

--------------------------------------------------------------------------------
-- Saving
--------------------------------------------------------------------------------

test("a login saves the character's guild for every other character", function()
	local ns = load()
	Stub.guild = {
		{ name = "Plateguy", level = 48, class = "WARRIOR", online = true },
		{ name = "Gone", level = 30, class = "MAGE", daysAgo = 9 },
	}
	ns.fire("PLAYER_LOGIN")
	Stub.FireTimers()
	ns.fire("GUILD_ROSTER_UPDATE")

	local saved = ns.db.global.guilds["Test:Alliance:Test Guild"]
	check(saved ~= nil, "the guild is saved")
	equal(#saved.members, 2, "with its whole roster")
	equal(saved.scannedBy, "Tester", "by this character")
	equal(ns.Guild:ActiveCount(saved), 1, "one of them active")
end)

test("a rescan keeps the tick on the guild", function()
	local ns = load()
	Stub.guild = { { name = "Plateguy", level = 48, class = "WARRIOR", online = true } }
	ns.db.global.guilds["Test:Alliance:Test Guild"] = { include = false }
	ns.Guild:Save()
	equal(ns.db.global.guilds["Test:Alliance:Test Guild"].include, false, "still unticked")
end)

--------------------------------------------------------------------------------
-- Reading saved guilds
--------------------------------------------------------------------------------

test("a saved guild reaches its members from a character not in it", function()
	local ns = load()
	seedGuild(ns)
	local items = atMailbox(ns, { strengthPlate() })
	equal(recipient(items), "Guildy", "the warrior from the other guild takes it")
	check(items[1].recipient.guild, "as a guildmate")
end)

--[[
	Ignore Offline Guild Members counts a saved member's time away up to today: what the roster
	recorded, plus the days since it was saved. A week is the default.
]]
test("a member offline under the limit is offered, from an old roster too", function()
	local ns = load()
	seedGuild(ns, { days = 2, age = 4 })
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "six days away, within a week")
end)

test("a member offline longer than the limit, counted to today, is left out", function()
	local ns = load()
	seedGuild(ns, { days = 5, age = 3 })
	equal(recipient(atMailbox(ns, { strengthPlate() })), nil, "eight days away is past a week")
end)

test("two weeks lets a member eight days away through", function()
	local ns = load()
	seedGuild(ns, { days = 5, age = 3 })
	ns.db.profile.guildOfflineLimit = "TWO_WEEKS"
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "within two weeks")
end)

test("never ignoring offline members offers even one long gone", function()
	local ns = load()
	seedGuild(ns, { days = 40, age = 30 })
	ns.db.profile.guildOfflineLimit = "NEVER"
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "away for months, still offered")
end)

test("an unticked guild is not read", function()
	local ns = load()
	seedGuild(ns, { include = false })
	equal(recipient(atMailbox(ns, { strengthPlate() })), nil, "nobody")
end)

test("a guild on another realm or faction is not read", function()
	local ns = load()
	seedGuild(ns, { realm = "Elsewhere", key = "Elsewhere:Alliance:Far Guild" })
	seedGuild(ns, { faction = "Horde", key = "Test:Horde:Far Guild" })
	equal(recipient(atMailbox(ns, { strengthPlate() })), nil, "mail cannot reach either")
end)

test("your own characters in a saved guild are not offered as guildmates", function()
	local ns = load()
	seedGuild(ns)
	ns.db.global.characters["Guildy-Test"] = { name = "Guildy", realm = "Test", class = "WARRIOR", level = 48 }
	ns.db.profile.sendToAlts = false
	equal(recipient(atMailbox(ns, { strengthPlate() })), nil, "Guildy is yours, and alts are off")
end)

--------------------------------------------------------------------------------
-- The panel
--------------------------------------------------------------------------------

local function altPane(ns, key)
	local node = ns.BuildAltsOptions().args[key]
	return node and node.args
end

local function guildPane(ns, key)
	local node = ns.BuildGuildsOptions().args[key or GUILD_KEY]
	return node and node.args
end

-- The member row whose label names this guildmate.
local function memberRow(pane, name)
	for key, group in pairs(pane) do
		if key:find("^member%d") and group.args.label.name:find(name, 1, true) then
			return group
		end
	end
end

test("each panel has a tree node per alt and per saved guild", function()
	local ns = load()
	ns.db.global.characters["Brickhouse-Test"] = { name = "Brickhouse", realm = "Test", class = "WARRIOR", level = 12 }
	seedGuild(ns)
	equal(ns.BuildAltsOptions().childGroups, "tree", "My Alts is a tree")
	equal(ns.BuildGuildsOptions().childGroups, "tree", "My Guilds is a tree")
	check(altPane(ns, "Brickhouse-Test") ~= nil, "the alt has a node")
	check(guildPane(ns) ~= nil, "the guild has a node")
end)

test("an alt's switches write to its saved entry", function()
	local ns = load()
	ns.db.global.characters["Hammertime-Test"] =
		{ name = "Hammertime", realm = "Test", class = "PALADIN", level = 12, spec = "Holy" }
	local entry = ns.db.global.characters["Hammertime-Test"]
	local alt = altPane(ns, "Hammertime-Test")

	alt.include.set(nil, false)
	equal(entry.include, false, "unticked is stored")
	alt.include.set(nil, true)
	equal(entry.include, nil, "ticked is the default, so nothing is stored")

	-- At the cap the default is unticked, so there it is the tick that is stored.
	GetMaxPlayerLevel = function()
		return 12
	end
	check(not alt.include.get(), "at the cap it reads unticked")
	alt.include.set(nil, true)
	equal(entry.include, true, "a tick at the cap is stored")
	alt.include.set(nil, false)
	equal(entry.include, nil, "and an untick is the default there")
	GetMaxPlayerLevel = nil

	equal(alt.levelsBelow.get(), 0, "lowest starts at its own level")
	equal(alt.levelsAbove.get(), "ANY", "highest starts at any level")
	check(alt.levelsSummary.name():find("from level 12 up", 1, true), "the summary reads in real levels")
	alt.levelsBelow.set(nil, 3)
	alt.levelsAbove.set(nil, 2)
	equal(entry.levelsBelow, 3, "three below is stored")
	equal(entry.levelsAbove, 2, "two above is stored")
	check(alt.levelsSummary.name():find("levels 9 to 14", 1, true), "and the summary follows")
	alt.levelsAbove.set(nil, "ANY")
	equal(entry.levelsAbove, nil, "any level is the default, so nothing is stored")

	check(alt.spec1.get() and not alt.spec2.get() and not alt.spec3.get(), "the spec it plays starts ticked")
	alt.spec3.set(nil, true)
	check(entry.specs.Holy and entry.specs.Retribution, "ticking Retribution keeps Holy")
	equal(entry.specs.Protection, nil, "and leaves Protection off")

	entry.specs, entry.spec = nil, nil
	check(alt.spec1.get() and alt.spec2.get() and alt.spec3.get(), "with no spec recorded, every spec starts ticked")
end)

test("delete forgets the alt, and a guild has no delete", function()
	local ns = load()
	ns.db.global.characters["Brickhouse-Test"] = { name = "Brickhouse", realm = "Test", class = "WARRIOR", level = 12 }
	seedGuild(ns)
	altPane(ns, "Brickhouse-Test").delete.func()
	equal(ns.db.global.characters["Brickhouse-Test"], nil, "the alt is gone")
	equal(guildPane(ns).delete, nil, "the guild pane offers no delete")
end)

test("alts and guildmates are listed alphabetically", function()
	local ns = load()
	for _, name in ipairs({ "Zed", "Alpha", "Mid" }) do
		ns.db.global.characters[name .. "-Test"] = { name = name, realm = "Test", class = "MAGE", level = 60 - #name }
	end
	local order = {}
	for key, node in pairs(ns.BuildAltsOptions().args) do
		if node.type == "group" then
			order[#order + 1] = { key = key, order = node.order }
		end
	end
	table.sort(order, function(a, b)
		return a.order < b.order
	end)
	equal(order[1].key, "Alpha-Test", "Alpha first")
	equal(order[#order].key, "Zed-Test", "Zed last")

	seedGuild(ns, {
		members = {
			{ name = "Young", level = 20, class = "MAGE", days = 1 },
			{ name = "Elder", level = 60, class = "MAGE", days = 1 },
		},
	})
	local listed = ns.Guild:ListedMembers(ns.db.global.guilds[GUILD_KEY])
	equal(listed[1].name, "Elder", "by name, not level")
end)

--------------------------------------------------------------------------------
-- Ignoring guildmates
--------------------------------------------------------------------------------

test("an active guildmate is listed with an Include tick, an inactive one is not", function()
	local ns = load()
	seedGuild(ns, {
		members = {
			{ name = "Guildy", level = 48, class = "WARRIOR", days = 1 },
			{ name = "Gone", level = 30, class = "MAGE", days = 9 },
		},
	})
	local pane = guildPane(ns)
	check(memberRow(pane, "Guildy") ~= nil, "Guildy is listed")
	equal(memberRow(pane, "Gone"), nil, "Gone is not, being inactive")
	check(memberRow(pane, "Guildy").args.include.get(), "and starts included")
	check(memberRow(pane, "Guildy").args.label.name:find("Guildy - Test", 1, true), "named with the realm")
end)

test("an ignored guildmate is never mailed, and stays listed to take it back", function()
	local ns = load()
	seedGuild(ns)
	memberRow(guildPane(ns), "Guildy").args.include.set(nil, false)
	equal(recipient(atMailbox(ns, { strengthPlate() })), nil, "the bank alt gets nothing")
	equal(memberRow(guildPane(ns), "Guildy").args.include.get(), false, "still listed, unticked")

	memberRow(guildPane(ns), "Guildy").args.include.set(nil, true)
	equal(ns.db.global.guilds[GUILD_KEY].ignored, nil, "taking it back leaves nothing stored")
end)

test("an ignore survives the rescan that replaces the roster", function()
	local ns = load()
	Stub.guild = { { name = "Bankalt", level = 48, class = "WARRIOR", online = true } }
	ns.Guild:Save()
	local entry = ns.db.global.guilds["Test:Alliance:Test Guild"]
	ns.Guild:SetIgnored(entry, "Bankalt", true)
	ns.Guild:Save()
	check(ns.Guild:Ignored(ns.db.global.guilds["Test:Alliance:Test Guild"], "Bankalt"), "still ignored")
end)

test("the guild you are in honors its ignores on the live read", function()
	local ns = load()
	Stub.guild = { { name = "Bankalt", level = 48, class = "WARRIOR", online = true } }
	ns.Guild:Save()
	ns.Guild:SetIgnored(ns.db.global.guilds["Test:Alliance:Test Guild"], "Bankalt", true)
	equal(#ns.Guild:Read(), 0, "the live roster leaves the bank out")
	equal(ns.Guild:Stats().ignored, 1, "and counts it as ignored")
end)
