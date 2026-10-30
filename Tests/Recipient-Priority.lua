--[[
	The Recipients panel's ordering switches (maintainer ruling, 2026-10-29).

	Who Comes First: your alts ahead of guildmates and strangers, your guildmates ahead of
	strangers, each on by default. When Searching for Strangers: somebody questing in a zone made
	for their level ahead of somebody in a city, anybody out in the world ahead of somebody in a
	dungeon, both on by default; and an off-by-default switch that skips stranger warlocks in the
	band summoning alts park in. A switch that is off drops its key from the sort -- it never
	reverses it.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Cloth with Intellect at 20: a mage or warlock at 18 to 19 is who it is for.
local function casterCloth()
	return Stub.Item({
		name = "Robe of Testing",
		reqLevel = 20,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1, -- CLOTH
		stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
	})
end

local function scanned(ns, def)
	Stub.SetBackpack({ def or casterCloth() })
	local item = ns.Scanner:Scan()[1]
	item.verdict = ns.Matcher:Verdict(item)
	return item
end

local function ranked(ns, item, people)
	ns.MatchList:AddResults(people)
	local out = {}
	for index, person in ipairs(ns.Matcher:RankCandidates(item, ns.MatchList:Pools())) do
		out[index] = person.name
	end
	return out
end

-- The panel's own switch, so the cases drive what the player drives.
local function switch(ns, key, value)
	ns.BuildRecipientsOptions().args[key].set(nil, value)
end

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

test("every switch ships as the panel describes", function()
	local ns = load()
	local profile = ns.db.profile
	check(profile.prioritizeAlts, "alts first")
	check(profile.prioritizeGuilds, "guilds before strangers")
	check(profile.prioritizeLevelingZones, "level-appropriate zones first")
	check(profile.prioritizeOutsideInstances, "instances last")
	equal(profile.ignoreSummonerWarlocks, false, "summoner warlocks are not skipped")
end)

--------------------------------------------------------------------------------
-- Who comes first
--------------------------------------------------------------------------------

test("a guildmate leads a stranger, until the guild switch is off", function()
	local ns = load()
	local item = scanned(ns)
	-- The stranger is closer to the robe's anchor, so only the source rank puts the guildmate first.
	local people = {
		{ name = "Guildy", level = 18, class = "MAGE", guild = true },
		{ name = "Stranger", level = 19, class = "MAGE" },
	}
	equal(ranked(ns, item, people)[1], "Guildy", "the guildmate first")
	switch(ns, "prioritizeGuilds", false)
	equal(ranked(ns, item, {})[1], "Stranger", "off, the closer level wins")
end)

test("the alts switch off drops an alt back to the guild's rank when it is a guildmate", function()
	local ns = load()
	local profile = ns.db.profile
	profile.prioritizeAlts = false
	equal(ns.Matcher:SourceRank({ alt = true, guild = true }), 2, "still a guildmate")
	equal(ns.Matcher:SourceRank({ alt = true }), 3, "otherwise a stranger")
	equal(ns.Matcher:Source({ alt = true }), 1, "while the picker still files it under Your Alts")
end)

--------------------------------------------------------------------------------
-- Strangers
--------------------------------------------------------------------------------

test("a dungeon ranks behind a capital, and the switch puts it back level with it", function()
	local ns = load()
	local item = scanned(ns)
	local people = {
		{ name = "Boosted", level = 19, class = "MAGE", area = "The Deadmines" },
		-- A level further from the anchor, so only placement puts the banker ahead.
		{ name = "Banker", level = 18, class = "MAGE", area = "Stormwind City" },
	}
	equal(ranked(ns, item, people)[1], "Banker", "the dungeon goes last")
	switch(ns, "prioritizeOutsideInstances", false)
	equal(ranked(ns, item, {})[1], "Boosted", "off, the closer level wins")
end)

test("the zones switch off lets level decide between a quester and a banker", function()
	local ns = load()
	local item = scanned(ns)
	local people = {
		{ name = "Banker", level = 19, class = "MAGE", area = "Stormwind City" },
		{ name = "Quester", level = 18, class = "MAGE", area = "Redridge Mountains" },
	}
	equal(ranked(ns, item, people)[1], "Quester", "on, the quester leads")
	switch(ns, "prioritizeLevelingZones", false)
	equal(ranked(ns, item, {})[1], "Banker", "off, the closer level wins")
end)

test("a holder in a dungeon keeps the search going while either switch weighs it", function()
	local ns = load()
	local person = { level = 19, area = "The Deadmines" }
	check(ns.Who:KeepsSearching(person), "both on")
	ns.db.profile.prioritizeLevelingZones = false
	check(ns.Who:KeepsSearching(person), "instances alone")
	ns.db.profile.prioritizeOutsideInstances = false
	check(not ns.Who:KeepsSearching(person), "neither, so nothing better can turn up")
end)

test("summoner warlocks are skipped only when asked, and only strangers", function()
	local ns = load()
	local item = scanned(
		ns,
		Stub.Item({
			name = "Robe of the Summoner",
			reqLevel = 25,
			equipLoc = "INVTYPE_CHEST",
			classID = 4,
			subclassID = 1,
			stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
		})
	)
	local people = {
		{ name = "Summoner", level = 23, class = "WARLOCK" },
		{ name = "Guildlock", level = 23, class = "WARLOCK", guild = true },
	}
	local before = table.concat(ranked(ns, item, people), " ")
	check(before:find("Summoner", 1, true), "off by default, the stranger is offered: " .. before)

	switch(ns, "ignoreSummonerWarlocks", true)
	local after = table.concat(ranked(ns, item, {}), " ")
	check(not after:find("Summoner", 1, true), "on, the stranger is skipped: " .. after)
	check(after:find("Guildlock", 1, true), "the guildmate is not: " .. after)
end)

test("the warlock switch names its level range", function()
	local ns = load()
	local name = ns.BuildRecipientsOptions().args.ignoreSummonerWarlocks.name
	check(name:find("20%-25"), "the label reads 20-25: " .. name)
end)
