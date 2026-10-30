--[[
	Where a recipient is standing, and what that is worth.

	A gift is for somebody levelling, and the best evidence of that /who gives is a player out
	in a zone made for their level. A capital is full of bank alts and people idling; a dungeon
	may be a boost. So placement ranks right behind who the item is for, and a holder found
	in a capital or a dungeon leaves the search running for somebody out in the world.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Cloth with Intellect at 20: a mage at 18 to 19 is who it is for.
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

local function names(list)
	local out = {}
	for index, person in ipairs(list) do
		out[index] = person.name
	end
	return table.concat(out, " ")
end

--------------------------------------------------------------------------------
-- Placement
--------------------------------------------------------------------------------

test("a zone made for their level is levelling", function()
	local ns = load()
	local Who = ns.Who
	equal(Who:Placement({ level = 15, area = "Westfall" }), Who.PLACED_LEVELING, "Westfall at 15")
	equal(Who:Placement({ level = 20, area = "Westfall" }), Who.PLACED_LEVELING, "a couple past its top still counts")
	equal(
		Who:Placement({ level = 30, area = "Westfall" }),
		Who.PLACED_UNKNOWN,
		"far past it is somebody passing through"
	)
end)

test("a capital is somewhere else, a dungeon is an instance", function()
	local ns = load()
	local Who = ns.Who
	equal(Who:Placement({ level = 19, area = "Stormwind City" }), Who.PLACED_ELSEWHERE, "a capital")
	equal(Who:Placement({ level = 19, area = "The Deadmines" }), Who.PLACED_INSTANCE, "a dungeon, by its instance area")
end)

-- An offline guildmate reports no area: nothing is known, and nothing is held against them.
test("no area is unknown, not elsewhere", function()
	local ns = load()
	equal(ns.Who:Placement({ level = 19 }), ns.Who.PLACED_UNKNOWN, "no area at all")
	equal(ns.Who:Placement({ level = 19, area = "" }), ns.Who.PLACED_UNKNOWN, "an empty one")
end)

--------------------------------------------------------------------------------
-- Ranking
--------------------------------------------------------------------------------

test("somebody out levelling outranks a capital and a dungeon", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	local item = ns.Scanner:Scan()[1]
	item.verdict = ns.Matcher:Verdict(item)

	ns.MatchList:AddResults({
		{ name = "Banker", level = 19, class = "MAGE", area = "Stormwind City" },
		{ name = "Boosted", level = 19, class = "MAGE", area = "The Deadmines" },
		-- One level further from the robe's anchor than the other two, and still first.
		{ name = "Quester", level = 18, class = "MAGE", area = "Redridge Mountains" },
	})
	local ranked = ns.Matcher:RankCandidates(item, ns.MatchList:Pools())

	equal(ranked[1].name, "Quester", "the one out in the world leads: " .. names(ranked))
end)

test("placement never outranks who the item is for", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	local item = ns.Scanner:Scan()[1]
	item.verdict = ns.Matcher:Verdict(item)

	ns.MatchList:AddResults({
		{ name = "Mage", level = 19, class = "MAGE", area = "Stormwind City" },
		{ name = "Warrior", level = 19, class = "WARRIOR", area = "Redridge Mountains" },
	})
	local ranked = ns.Matcher:RankCandidates(item, ns.MatchList:Pools())

	equal(ranked[1] and ranked[1].name, "Mage", "the caster keeps the caster's robe: " .. names(ranked))
end)

--------------------------------------------------------------------------------
-- Stopping
--------------------------------------------------------------------------------

local function searchOnce(ns, results)
	Stub.SetBackpack({ casterCloth() })
	ns.fire("MAIL_SHOW")
	Stub.whoResults = results
	Stub.whoTotal = 999
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()[1]
end

test("a holder out levelling ends the search", function()
	local ns = load()
	local item = searchOnce(ns, { { name = "Quester", level = 19, class = "MAGE", area = "Redridge Mountains" } })

	equal(item.recipient and item.recipient.name, "Quester", "the mage holds the robe")
	equal(ns.Who:Remaining(), 0, "and the search is done")
end)

test("a holder in a capital keeps the search going", function()
	local ns = load()
	local item = searchOnce(ns, { { name = "Banker", level = 19, class = "MAGE", area = "Stormwind City" } })

	equal(item.recipient and item.recipient.name, "Banker", "the mage holds the robe meanwhile")
	check(ns.Who:Remaining() > 0, "and the plan still looks for somebody out in the world")
end)

--[[
	Pooled once with no zone, as an offline guildmate or a first sighting in a capital, a player
	found out levelling later has to be placed where they are now, or they rank as a banker
	all session and a holder found that way keeps the search running for nothing.
]]
test("a later sighting moves a pooled player to where they are now", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	local item = ns.Scanner:Scan()[1]
	item.verdict = ns.Matcher:Verdict(item)

	ns.MatchList:AddResults({ { name = "Guildie", level = 19, class = "MAGE" } })
	local pooled = ns.MatchList:Pools().MAGE[1]
	equal(ns.Who:Placement(pooled), ns.Who.PLACED_UNKNOWN, "no zone yet")

	local changed = ns.MatchList:AddResults({
		{ name = "Guildie", level = 19, class = "MAGE", area = "Redridge Mountains" },
	})
	equal(changed, 1, "the new zone counts as a change")
	equal(ns.Who:Placement(pooled), ns.Who.PLACED_LEVELING, "and places them out levelling")
end)
