--[[
	Who gets handed out first when several items want the same few people.

	The bug: shields never found a recipient. Nothing in the shield path was wrong --
	the scanner accepts them, the weapon matrix admits warriors, paladins and shamans,
	and RankCandidates ranks them. They lost in UI:_assign, which handed items out in
	score order and gives one item per person per pass.

	A shield is the worst possible item under that rule, for three reasons that compound:
	its real value is Armor and Block, neither of which any stat table scores, so it
	only ever earns the flat weapon baseline and sorts last; it has the narrowest
	eligibility of any armor type, two classes on Era against eight for a cloak; and
	those two classes can wear nearly everything else in the bag, so they are claimed
	early. By the time the shield picked, every warrior and paladin was taken.

	Score order is the wrong question. Scarcity is: an item with two possible recipients
	has to pick before one with fifty, or it is the only one that ends up with nobody.
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
	ns.fire("MAIL_SHOW")

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
	Scarcity leads, but it must not throw away the ranking. Between two items that can
	reach the same number of people, the better item still picks first.
]]
test("equally reachable items are still handed out best-first", function()
	local ns = load()
	Stub.SetBackpack({
		gear("Weak Chain Vest", "INVTYPE_CHEST", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 2 }),
		gear("Strong Chain Vest", "INVTYPE_LEGS", 4, 3, { ITEM_MOD_STRENGTH_SHORT = 9 }),
	})
	ns.fire("MAIL_SHOW")

	--[[
		Mail admits warriors and paladins at this level and nobody else, so both items
		reach exactly the same two people. Warr1 is the closer to equipping them.

		Both inside the band a level 20 item searches, which is 18 to 19: two levels
		below the requirement up to one below it. A 17 here would simply be out of range
		and the case would prove nothing about ordering.
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
