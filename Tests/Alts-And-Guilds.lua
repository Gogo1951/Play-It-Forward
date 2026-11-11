--[[
	The My Alts and My Guilds panels and the saved guild list behind them (maintainer rulings,
	2026-10-29).

	Every guild any of your characters is in is saved account-wide at that character's login, so
	whichever character you are on reaches the leveling players in all of them. A saved roster
	counts members active in the 3 days before the scan, and is ignored once it is older than the
	Ignore Saved Guilds setting. Both panels are trees, one node per alt or guild. Each alt has a
	tick, a Delete, the specs it is mailed gear for and whether it holds gear it has yet to grow
	into; each guild has a remove icon, a tick and an Include beside every active member, ticked by
	default. Alts and members are listed alphabetically, members as "Name - Realm".

	Any other guild can be added by name, TFTB's way (maintainer ruling, 2026-11-11). It has no
	roster, so its members are found by /who: a g-"Name" query opens each search, and anybody a
	/who answer places in one of your guilds ranks as a guildmate.
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

test("an alt's and a guild's subsections are headers, like every other panel's", function()
	local ns = load()
	ns.db.global.characters["Brickhouse-Test"] = { name = "Brickhouse", realm = "Test", class = "WARRIOR", level = 12 }
	seedGuild(ns)
	local alt = altPane(ns, "Brickhouse-Test")
	equal(alt.levelsLabel.type, "header", "Gear Levels")
	equal(alt.specsLabel.type, "header", "Specs")
	equal(guildPane(ns).membersLabel.type, "header", "Members")
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

test("delete forgets the alt; removing a saved guild hides it until it is added again", function()
	local ns = load()
	ns.db.global.characters["Brickhouse-Test"] = { name = "Brickhouse", realm = "Test", class = "WARRIOR", level = 12 }
	seedGuild(ns)
	altPane(ns, "Brickhouse-Test").delete.func()
	equal(ns.db.global.characters["Brickhouse-Test"], nil, "the alt is gone")

	guildPane(ns).title.args.remove.func()
	check(ns.db.global.guilds[GUILD_KEY] ~= nil, "a guild one of yours is in is kept, or its next login brings it back")
	equal(guildPane(ns), nil, "but it leaves the list")
	equal(#ns.Guild:ReadSaved(), 0, "and nobody in it is offered anything")

	ns.Guild:Add("far guild")
	check(guildPane(ns) ~= nil, "typing its name, in any capitals, brings it back")
	equal(#ns.Guild:ReadSaved(), 1, "with its members")
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

test("the guild you are in, unticked, is not read live", function()
	local ns = load()
	Stub.guild = { { name = "Plateguy", level = 48, class = "WARRIOR", online = true } }
	ns.Guild:Save()
	ns.db.global.guilds["Test:Alliance:Test Guild"].include = false
	equal(#ns.Guild:Read(), 0, "Include This Guild off means nobody in it")
end)

--------------------------------------------------------------------------------
-- Guilds added by name
--------------------------------------------------------------------------------

local OWLS_KEY = "Test:Alliance:Night Owls"

test("a guild added by name is listed with no roster, and removing it forgets it", function()
	local ns = load()
	equal(ns.Guild:Add(" Night  Owls , Far Guild"), 2, "two names, split on the comma")
	local owls = ns.db.global.guilds[OWLS_KEY]
	check(owls ~= nil and owls.added, "saved under its tidied name, marked added")
	check(ns.Guild:ByNameOnly(owls), "known only through /who")
	equal(ns.Guild:Add("night owls"), 0, "the same guild in other capitals is not added twice")

	local pane = guildPane(ns, OWLS_KEY)
	check(pane ~= nil, "it has a node")
	check(pane.status.name:find(ns.L["OPTIONS_GUILD_ADDED"], 1, true) ~= nil, "saying how its members are found")
	equal(pane.membersLabel, nil, "with no member list")

	pane.title.args.remove.func()
	equal(ns.db.global.guilds[OWLS_KEY], nil, "never saved by one of yours, so it is gone for good")
end)

test("a guild added by name on another faction says mail can't reach it", function()
	local ns = load()
	ns.Guild:Add("Night Owls")
	ns.db.global.guilds[OWLS_KEY].faction = "Horde"
	local status = guildPane(ns, OWLS_KEY).status.name
	check(status:find(ns.L["OPTIONS_GUILD_ADDED"], 1, true) ~= nil, "still says how it is found")
	check(status:find(ns.L["OPTIONS_GUILD_SKIPPED_FACTION"], 1, true) ~= nil, "and that it is out of reach")
end)

test("joining a guild added in other capitals takes it over rather than listing it twice", function()
	local ns = load()
	ns.Guild:Add("test guild")
	Stub.guild = { { name = "Plateguy", level = 48, class = "WARRIOR", online = true } }
	ns.Guild:Save()
	local count = 0
	for _ in pairs(ns.db.global.guilds) do
		count = count + 1
	end
	equal(count, 1, "one entry")
	check(ns.db.global.guilds["Test:Alliance:Test Guild"] ~= nil, "under the roster's spelling")
end)

test("a search opens with a query for each guild added by name", function()
	local ns = load()
	ns.Guild:Add("Night Owls")
	atMailbox(ns, { strengthPlate() })
	local first = Stub.whoQueries[1] or ""
	check(first:find('g-"Night Owls"', 1, true) ~= nil, "the guild is asked first, got: " .. first)
end)

test("no guild added by name, no guild query", function()
	local ns = load()
	seedGuild(ns)
	atMailbox(ns, { strengthPlate() })
	for _, query in ipairs(Stub.whoQueries) do
		check(not query:find("g-", 1, true), "a saved roster is read, never searched for: " .. query)
	end
end)

test("somebody /who places in one of your guilds ranks as a guildmate", function()
	local ns = load()
	ns.Guild:Add("Night Owls")
	Stub.whoResults = { { name = "Owlet", level = 48, class = "WARRIOR", guild = "Night Owls" } }
	local items = atMailbox(ns, { strengthPlate() })
	equal(recipient(items), "Owlet", "found by the guild query")
	check(items[1].recipient.guild, "and offered as a guildmate")
end)

test("a guildmate you unticked is never offered, however /who finds them", function()
	local ns = load()
	seedGuild(ns, { members = {} })
	ns.Guild:SetIgnored(ns.db.global.guilds[GUILD_KEY], "Bankalt", true)
	Stub.whoResults = { { name = "Bankalt", level = 48, class = "WARRIOR", guild = "Far Guild" } }
	local items = atMailbox(ns, { strengthPlate() })
	equal(recipient(items), nil, "left out")
	equal(ns.Who:ResultStats().ignoredGuild, 1, "and counted")
end)

test("a guildmate you unticked stays ignored after the whole guild is unticked", function()
	local ns = load()
	seedGuild(ns, { members = {} })
	local entry = ns.db.global.guilds[GUILD_KEY]
	ns.Guild:SetIgnored(entry, "Bankalt", true)
	entry.include = false
	Stub.whoResults = { { name = "Bankalt", level = 48, class = "WARRIOR", guild = "Far Guild" } }
	local items = atMailbox(ns, { strengthPlate() })
	equal(recipient(items), nil, "still left out, not mailed as a stranger")
	equal(ns.Who:ResultStats().ignoredGuild, 1, "and counted")
end)

--[[
	A change on My Guilds reaches players already pooled this session, not only the next search:
	the pool keeps everybody found until /reload.
]]
test("unticking a pooled guildmate takes them off the row at once", function()
	local ns = load()
	seedGuild(ns)
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "offered first")
	memberRow(guildPane(ns), "Guildy").args.include.set(nil, false)
	equal(recipient(ns.UI:Items()), nil, "gone without a reload")
end)

test("unticking a guild takes its pooled members off at once", function()
	local ns = load()
	seedGuild(ns)
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "offered first")
	guildPane(ns).include.set(nil, false)
	equal(recipient(ns.UI:Items()), nil, "gone without a reload")
end)

test("removing a guild takes its pooled members off at once", function()
	local ns = load()
	seedGuild(ns)
	equal(recipient(atMailbox(ns, { strengthPlate() })), "Guildy", "offered first")
	guildPane(ns).title.args.remove.func()
	equal(recipient(ns.UI:Items()), nil, "gone without a reload")
end)
