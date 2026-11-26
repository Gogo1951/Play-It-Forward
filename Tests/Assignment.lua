--[[
	Which item is handed out first when several want the same few people: scarcity, not score. A
	shield earns only the flat weapon baseline (Armor and Block score nothing), reaches two classes
	on Era, and those two can wear most of the bag, so in score order it ends up with nobody.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function gear(name, equipLoc, classID, subclassID, stats)
	return Stub.Item({
		name = name,
		quality = 2,
		reqLevel = 20,
		itemLevel = 25,
		equipLoc = equipLoc,
		classID = classID,
		subclassID = subclassID,
		bindType = 2,
		stats = stats,
	})
end

local function recipientOf(ns, name)
	for _, item in ipairs(ns.UI:Items()) do
		if item.name == name then
			return item.recipient and item.recipient.name
		end
	end
	return nil
end

--[[
	A bag where a shield competes with gear that wants the same two classes, against a
	roster holding exactly one warrior and one paladin.
]]
local function distributeAgainstRoster(ns)
	Stub.SetBackpack({
		gear("Sturdy Buckler", "INVTYPE_SHIELD", 4, 6, { ITEM_MOD_STAMINA_SHORT = 4 }),
		gear("Cloak of the Bear", "INVTYPE_CLOAK", 4, 0, {
			ITEM_MOD_STRENGTH_SHORT = 5,
			ITEM_MOD_STAMINA_SHORT = 5,
		}),
		gear("Ring of the Tiger", "INVTYPE_FINGER", 4, 0, {
			ITEM_MOD_AGILITY_SHORT = 4,
			ITEM_MOD_STRENGTH_SHORT = 3,
		}),
		gear("Chain Vest", "INVTYPE_CHEST", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 6 }),
	})
	ns.visitMailbox()

	Stub.whoResults = {
		{ name = "Warr1", level = 18, class = "WARRIOR" },
		{ name = "Pally1", level = 19, class = "PALADIN" },
		{ name = "Rogue1", level = 18, class = "ROGUE" },
		{ name = "Mage1", level = 18, class = "MAGE" },
		{ name = "Hunt1", level = 19, class = "HUNTER" },
	}
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
end

--------------------------------------------------------------------------------

test("a shield still finds somebody when broader gear wants the same people", function()
	local ns = load()
	distributeAgainstRoster(ns)

	--[[
		Only Warr1 and Pally1 can receive a shield. Both are also candidates for the
		cloak, the ring and the mail chest, all of which outscore it many times over.
	]]
	check(recipientOf(ns, "Sturdy Buckler") ~= nil, "the shield was placed")
	check(
		recipientOf(ns, "Sturdy Buckler") == "Warr1" or recipientOf(ns, "Sturdy Buckler") == "Pally1",
		"with somebody who can actually use it"
	)
end)

test("placing the shield does not cost the other items their recipients", function()
	local ns = load()
	distributeAgainstRoster(ns)

	--[[
		The whole roster gets used. Letting the scarce item pick first costs the broad
		ones nothing but their first choice, because they have others to fall back on.
	]]
	for _, name in ipairs({ "Sturdy Buckler", "Cloak of the Bear", "Ring of the Tiger", "Chain Vest" }) do
		check(recipientOf(ns, name) ~= nil, name .. " was placed")
	end
end)

test("nobody receives two items in one pass", function()
	local ns = load()
	distributeAgainstRoster(ns)

	local seen = {}
	for _, item in ipairs(ns.UI:Items()) do
		if item.recipient then
			check(not seen[item.recipient.name], item.recipient.name .. " holds only one item")
			seen[item.recipient.name] = true
		end
	end
end)

--[[
	One person under two spellings. /who answers with a bare name for somebody on your own
	realm while the guild roster qualifies the same character "Name-Realm", so an identity
	compared on the raw string holds them twice: two pool entries, two items, two parcels in
	one stranger's mailbox -- and the sighting that arrives second never hands over the guild
	flag that earns them their tiebreak.
]]
local function mailPair(ns)
	Stub.SetBackpack({
		gear("Chain Vest", "INVTYPE_CHEST", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 6 }),
		gear("Chain Legs", "INVTYPE_LEGS", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 5 }),
	})
	ns.visitMailbox()
end

test("a player found under both name spellings is one person, not two", function()
	local ns = load()
	mailPair(ns)

	equal(ns.MatchList:AddResults({ { name = "Bob", level = 19, class = "WARRIOR" } }), 1, "the bare name is new")
	equal(
		ns.MatchList:AddResults({ { name = "Bob-Test", level = 19, class = "WARRIOR", guild = true } }),
		1,
		"the qualified spelling is the same person, changed only by the guild flag"
	)

	local warriors = ns.UI:Pools()["WARRIOR"] or {}
	equal(#warriors, 1, "one pool entry")
	check(warriors[1].guild, "carrying the guild flag the second sighting brought")
	equal(warriors[1].name, "Bob", "under the name the client actually gave us, which is the address")
end)

-- The guild flag a later sighting hands over has to reach a ranking already cached.
test("a guild sighting of a known player re-ranks the cached candidates", function()
	local ns = load()
	mailPair(ns)
	ns.MatchList:AddResults({
		{ name = "Bob", level = 19, class = "WARRIOR" },
		{ name = "Carl", level = 19, class = "WARRIOR" },
	})
	-- Carl wins the coin flip, so only the guild tiebreak can put Bob ahead of him.
	for _, person in ipairs(ns.UI:Pools()["WARRIOR"]) do
		person.shuffle = (person.name == "Carl") and 0.1 or 0.9
	end
	local item = ns.UI:Items()[1]
	ns.MatchList:Candidates(item)
	ns.MatchList:Candidates(item)

	-- Cached before the flips above took effect, so ask past them once.
	ns.MatchList:AddResults({ { name = "Dave", level = 30, class = "WARRIOR" } })
	equal(ns.MatchList:Candidates(item)[1].name, "Carl", "Carl leads on the coin flip")

	ns.MatchList:AddResults({ { name = "Bob-Test", level = 19, class = "WARRIOR", guild = true } })
	equal(ns.MatchList:Candidates(item)[1].name, "Bob", "the guildmate now wins the tie")
end)

test("neither spelling of one player is handed a second item", function()
	local ns = load()
	mailPair(ns)

	ns.MatchList:AddResults({ { name = "Bob", level = 19, class = "WARRIOR" } })
	ns.MatchList:AddResults({ { name = "Bob-Test", level = 19, class = "WARRIOR", guild = true } })
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local held = 0
	for _, item in ipairs(ns.UI:Items()) do
		if item.recipient then
			held = held + 1
		end
	end
	equal(held, 1, "one person, one parcel")
end)

--[[
	Scarcity leads, but it must not throw away the ranking. Between two items that can
	reach the same number of people, the better item still picks first.
]]
test("equally reachable items are still handed out best-first", function()
	local ns = Harness.AllSpecs(load())
	Stub.SetBackpack({
		gear("Weak Chain Vest", "INVTYPE_CHEST", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 2 }),
		gear("Strong Chain Vest", "INVTYPE_LEGS", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 9 }),
	})
	ns.visitMailbox()

	--[[
		Mail admits only warriors and paladins here, so both items reach the same two; Warr1 is
		closer to equipping them. A 17 would be outside a level 20 item's 18-19 band.
	]]

	Stub.whoResults = {
		{ name = "Warr1", level = 19, class = "WARRIOR" },
		{ name = "Pally1", level = 18, class = "PALADIN" },
	}
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	equal(recipientOf(ns, "Strong Chain Vest"), "Warr1", "the better item got first pick")
	equal(recipientOf(ns, "Weak Chain Vest"), "Pally1", "the weaker one took who was left")
end)
