--[[
	What the window decides when a mailbox opens.

	Two questions, and they turned out to be one bug. The window used to open on
	ns.Scanner:HasAny, which is the bag filter alone: it says a slot holds a
	bind-on-equip green of the right rarity, not that any class in the game can use it.
	And it opened on an empty list, because the scan that fills that list did not
	happen until the first press of Find Recipients.

	So a bag of low level plate opened a window with nothing in it. Both halves are
	fixed by reading the bags before deciding, which is what these cases pin.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Plate at level 20. Nobody can wear it: Data/Armor-Priority.lua derives the plate
	group from what each class wears at the item's level, and no class is in plate
	before 40 except a death knight, who does not exist on Era. It still passes every
	check the bag filter makes, which is exactly why it is the fixture here.
]]
local function lowLevelPlate()
	return Stub.Item({
		name = "Burnished Breastplate",
		reqLevel = 20,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4, -- PLATE
		stats = { ITEM_MOD_STRENGTH_SHORT = 6 },
	})
end

-- Cloth with Intellect on it: three classes rank it at their primary weight.
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

local function windowShown(ns)
	return ns.UI.frame ~= nil and ns.UI.frame:IsShown() == true
end

--------------------------------------------------------------------------------

test("empty bags leave the window shut", function()
	local ns = load()
	Stub.SetBackpack({})

	ns.fire("MAIL_SHOW")

	check(not windowShown(ns), "window stayed shut")
end)

test("a bag nobody can use leaves the window shut", function()
	local ns = load()
	Stub.SetBackpack({ lowLevelPlate() })

	--[[
		The witness for the bug. The bag filter takes the item, so the old gate said
		"open"; the matcher admits no class for it, so there was never anything to do.
		Both assertions have to hold or this case is testing the wrong item.
	]]
	local scanned = ns.Scanner:Scan()
	equal(#scanned, 1, "the bag filter accepts the item")
	equal(ns.Matcher:Verdict(scanned[1]).state, ns.Matcher.LEFTOVER, "the matcher has no class for it")

	ns.fire("MAIL_SHOW")

	check(not windowShown(ns), "window stayed shut")

	--[[
		AND SAID NOTHING ABOUT IT. Having nothing spare in your bags is the ordinary state
		of a mailbox visit, and an add-on that comments on ordinary states is one more
		thing talking over the game. Force the Window Open on the Diagnostic Tools panel is
		there for anyone who wants to check the silence was correct.
	]]
	equal(#Stub.printed, 0, "and said nothing about it")
end)

test("a giftable bag opens the window with the list already filled", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })

	ns.fire("MAIL_SHOW")

	check(windowShown(ns), "window opened")

	--[[
		The list is populated before a single /who has run. Nobody is assigned yet and
		that is fine -- the point is seeing how much there is to hand out.
	]]
	local items = ns.UI:Items()
	equal(#items, 1, "the item is in the list on open")
	equal(items[1].state, ns.Matcher.GIFT, "and it is one that can be given away")
	equal(items[1].recipient, nil, "with no recipient yet")
end)

test("items nobody can use still ride along with a giftable one", function()
	local ns = load()
	Stub.SetBackpack({ lowLevelPlate(), casterCloth() })

	ns.fire("MAIL_SHOW")

	check(windowShown(ns), "window opened")
	equal(#ns.UI:Items(), 2, "both rows are listed")
end)

--[[
	The escape hatch. A shut window is the correct answer to a bag nobody can use and it
	is also what a broken add-on looks like, so there has to be a way to open it and read
	the verdicts for yourself. That is Force the Window Open on the Diagnostic Tools
	panel, which is the only way in now that the window opens by itself or not at all.
]]
test("Force the Window Open shows a bag with nothing to give", function()
	local ns = load()
	Stub.SetBackpack({ lowLevelPlate() })

	ns.fire("MAIL_SHOW")
	check(not windowShown(ns), "the mailbox left it shut")

	ns.UI:ForceShow()

	check(windowShown(ns), "asking directly opened it")
	equal(#ns.UI:Items(), 1, "and the item is listed, with its verdict")
end)

--[[
	An item the client has not cached yet reads as no item at all, and the window now
	decides whether to open on that reading. Answering "nothing worth mailing" because
	the cache was cold is a confident wrong answer, so the scan has to be retried once
	the client resolves the item.
]]
test("a cold item cache is not mistaken for an empty bag", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })

	ns.fire("MAIL_SHOW")
	check(not windowShown(ns), "nothing to show while the item is unresolved")

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id)
	ns.fire("MAIL_SHOW")

	check(windowShown(ns), "the next mailbox re-reads the bags and opens")
	equal(#ns.UI:Items(), 1, "the item is listed once it resolves")
end)

--[[
	MAIL_SHOW and MailFrame's OnShow both fire for a single mailbox, so the decision
	runs twice. It has to reach the same answer, and the scan behind it is no longer
	the free boolean probe it replaced.
]]
test("opening a mailbox is decided the same way twice", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })

	ns.fire("PLAYER_LOGIN")
	ns.fire("MAIL_SHOW")
	local hook = MailFrame.hooks.OnShow
	check(hook ~= nil, "MailFrame's OnShow is hooked")
	if hook then
		hook()
	end

	check(windowShown(ns), "window still open")
	equal(#ns.UI:Items(), 1, "the list did not grow a duplicate")
end)
