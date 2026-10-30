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
	Plate at level 20. Nobody can wear it: nothing is in plate before 40 except a death
	knight, who does not exist on Era, and 20 is far enough below that training level
	that ns.Data.PROFICIENCY_REACH does not admit the warrior and the paladin either --
	a level 20 plate chest is no gift to somebody who first equips it at 40. It still
	passes every check the bag filter makes, which is exactly why it is the fixture here.
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
		thing talking over the game. The Bag Scan report on the Diagnostic Tools panel says
		what every slot was judged, for anyone who wants to check the silence was correct.
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
	ns.fire("MAIL_CLOSED")
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

--[[
	The same cold cache, answered without walking away. The mailbox that opened on nothing
	waits for the item to resolve, and the debounced rescan opens the window then -- the
	delay a player saw was the walk back to a mailbox they were already standing at.
]]
test("an item resolving at the mailbox opens the window there", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })

	ns.fire("MAIL_SHOW")
	check(not windowShown(ns), "nothing to show while the item is unresolved")
	check(ns.UI:WaitingToOpen(), "the mailbox waits on it")

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id)
	Stub.FireTimers()

	check(windowShown(ns), "opened without leaving the mailbox")
	check(not ns.UI:WaitingToOpen(), "and the wait is over")
end)

test("an item resolving after the mailbox closed leaves the window shut", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })

	ns.fire("MAIL_SHOW")
	ns.fire("MAIL_CLOSED")

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id)
	Stub.FireTimers()

	check(not windowShown(ns), "no window out in the world")
end)

-- Closing it at the mailbox is an answer, and a bag change is not a reason to ask again.
test("a window closed at the mailbox stays closed through a bag change", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })

	ns.fire("MAIL_SHOW")
	check(windowShown(ns), "window opened")
	ns.UI:Close()

	ns.fire("BAG_UPDATE", 0)
	Stub.FireTimers()

	check(not windowShown(ns), "and stayed closed")
end)

--[[
	A setting changed with no window built used to change nothing until the bags moved: the
	next mailbox reused the scan judged under the old setting and opened on nothing.
]]
test("a setting changed with no window is read at the next mailbox", function()
	local ns = load()
	ns.db.profile.includeGear = false
	Stub.SetBackpack({ casterCloth() })

	ns.fire("MAIL_SHOW")
	ns.fire("MAIL_CLOSED")
	check(not windowShown(ns), "gear off, nothing to give")

	-- What the options panel's toggle does.
	ns.db.profile.includeGear = true
	ns.UI:Rescan()

	ns.fire("MAIL_SHOW")
	check(windowShown(ns), "the next mailbox reads the bags against the new setting")
end)

test("a setting changed while the mailbox waits opens the window there", function()
	local ns = load()
	ns.db.profile.includeGear = false
	Stub.SetBackpack({ casterCloth() })

	ns.fire("MAIL_SHOW")
	check(not windowShown(ns), "gear off, nothing to give")

	ns.db.profile.includeGear = true
	ns.UI:Rescan()

	check(windowShown(ns), "opened on the setting change")
end)

--[[
	One mailbox reports itself up to three times -- MAIL_SHOW, MailFrame's OnShow, and the
	interaction manager where it is registered -- and each report used to re-run the open,
	asking the guild roster again every time.
]]
test("one mailbox visit asks for the guild roster once", function()
	local ns = load()
	Stub.guild = { { name = "Guildie-Realm", level = 19, class = "MAGE", online = true } }
	Stub.SetBackpack({ casterCloth() })

	ns.fire("PLAYER_LOGIN")
	ns.fire("MAIL_SHOW")
	MailFrame.hooks.OnShow()
	ns.fire("MAIL_SHOW")

	equal(Stub.guildRosterRequests, 1, "one roster request for one visit")

	ns.fire("MAIL_CLOSED")
	ns.fire("MAIL_SHOW")
	equal(Stub.guildRosterRequests, 2, "and one more at the next visit")
end)

--[[
	GET_ITEM_INFO_RECEIVED fires for every item the client loads, from any source. Only an item
	the scan is waiting on can change what it returns, so only that one re-reads the bags.
]]
test("only the item the scan waits on re-reads the bags", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })
	ns.fire("MAIL_SHOW")
	check(ns.UI:WaitingToOpen(), "the mailbox waits on the robe")

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id + 1, true)
	Stub.FireTimers()
	check(not windowShown(ns), "an unrelated item answering re-reads nothing")

	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id, true)
	Stub.FireTimers()
	check(windowShown(ns), "the robe answering opens the window")
end)

--------------------------------------------------------------------------------
-- The reopen button beside Blizzard's mail frame
--------------------------------------------------------------------------------

test("closing the window at a mailbox offers the way back", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	MailFrame:Show()
	ns.fire("MAIL_SHOW")
	check(windowShown(ns), "window opened")
	equal(ns.UI:ReopenButtonShown(), false, "no button while the window is up")

	ns.UI:Close()
	equal(ns.UI:ReopenButtonShown(), true, "the button appears once it closes")

	PlayItForwardReopenButton:GetScript("OnClick")(PlayItForwardReopenButton)
	check(windowShown(ns), "and clicking it opens the window again")
	equal(ns.UI:ReopenButtonShown(), false, "and hides the button")
end)

test("a mailbox that listed nothing still offers the window", function()
	local ns = load()
	Stub.SetBackpack({})
	MailFrame:Show()
	ns.fire("MAIL_SHOW")
	check(not windowShown(ns), "nothing to give, so no window")
	equal(ns.UI:ReopenButtonShown(), true, "but the button is there")
end)

test("the button goes when the mailbox does", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	MailFrame:Show()
	ns.fire("MAIL_SHOW")
	ns.UI:Close()
	equal(ns.UI:ReopenButtonShown(), true, "shown at the mailbox")

	MailFrame:Hide()
	ns.fire("MAIL_CLOSED")
	Stub.FireTimers()
	equal(ns.UI:ReopenButtonShown(), false, "gone with it")
end)
