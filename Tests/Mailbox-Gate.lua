--[[
	The window (656 by 512, bigger than the mailbox) never opens by itself: a mailbox puts up a tab
	on its right edge that opens and closes it. The list the tab opens on is already read from the
	bags, so a click never shows an empty list for a bag with gifts in it.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Level 20 plate: nobody can wear it on Era (PROFICIENCY_REACH keeps out classes first equipping
	plate at 40), yet it passes every bag-filter check.
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

local function openMailbox(ns)
	MailFrame:Show()
	ns.fire("MAIL_SHOW")
end

local function clickTab()
	PlayItForwardMailboxTab:GetScript("OnClick")(PlayItForwardMailboxTab)
end

--------------------------------------------------------------------------------
-- The mailbox opens alone
--------------------------------------------------------------------------------

test("a mailbox with a gift in the bags puts up the tab and opens nothing", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })

	openMailbox(ns)

	check(not windowShown(ns), "the window stays shut")
	equal(ns.UI:MailboxTabShown(), true, "the tab is up")
	equal(ns.UI:MailboxTabLit(), false, "and not lit")
	-- And says nothing: a mailbox visit is the ordinary state of the game.
	equal(#Stub.printed, 0, "and nothing is said")
end)

test("the tab is there with nothing to give, too", function()
	local ns = load()
	Stub.SetBackpack({})

	openMailbox(ns)

	equal(ns.UI:MailboxTabShown(), true, "the tab is up on an empty bag")
	clickTab()
	check(windowShown(ns), "and opens the window")
	equal(#ns.UI:Items(), 0, "on an empty list")
end)

--[[
	MAIL_SHOW and MailFrame's OnShow both fire for a single mailbox, and the interaction manager
	reports it a third time where it is registered. One tab, nothing opened, however many reports.
]]
test("a mailbox reported twice still opens nothing", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })

	ns.fire("PLAYER_LOGIN")
	openMailbox(ns)
	local hook = MailFrame.hooks.OnShow
	check(hook ~= nil, "MailFrame's OnShow is hooked")
	if hook then
		hook()
	end

	check(not windowShown(ns), "the window stays shut")
	equal(ns.UI:MailboxTabShown(), true, "the tab is up")
end)

-- Nothing is asked of the server until the player wants the window.
test("a mailbox opening asks for no guild roster until the tab is clicked", function()
	local ns = load()
	Stub.guild = { { name = "Guildie-Realm", level = 19, class = "MAGE", online = true } }
	Stub.SetBackpack({ casterCloth() })

	ns.fire("PLAYER_LOGIN")
	openMailbox(ns)
	MailFrame.hooks.OnShow()
	equal(Stub.guildRosterRequests, 0, "nothing asked at the mailbox")

	clickTab()
	equal(Stub.guildRosterRequests, 1, "one roster request once the window opens")
end)

--------------------------------------------------------------------------------
-- The tab opens and closes the window
--------------------------------------------------------------------------------

-- Matched rows come only on Find Recipients, but the items are already read from the bags.
test("the tab opens the window with the list already filled", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)

	clickTab()

	check(windowShown(ns), "the window opened")
	local items = ns.UI:Items()
	equal(#items, 1, "the item is in the list on open")
	equal(items[1] and items[1].state, ns.Matcher.GIFT, "and it is one that can be given away")
	equal(items[1] and items[1].recipient, nil, "with no recipient yet")
end)

test("items nobody can use still ride along with a giftable one", function()
	local ns = load()
	Stub.SetBackpack({ lowLevelPlate(), casterCloth() })
	openMailbox(ns)

	clickTab()

	check(windowShown(ns), "the window opened")
	equal(#ns.UI:Items(), 2, "both rows are listed")
end)

test("the tab stays up and lit while the window is open, and a second click closes it", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)

	clickTab()
	equal(ns.UI:MailboxTabShown(), true, "the tab stays with the window up")
	equal(ns.UI:MailboxTabLit(), true, "lit while the window is up")

	clickTab()
	check(not windowShown(ns), "the second click closes the window")
	equal(ns.UI:MailboxTabLit(), false, "and the tab goes dark")
end)

test("closing the window with its X darkens the tab", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)
	clickTab()

	ns.UI:Close()

	equal(ns.UI:MailboxTabShown(), true, "the tab is still up")
	equal(ns.UI:MailboxTabLit(), false, "and no longer lit")
end)

test("the tab goes when the mailbox does", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)
	equal(ns.UI:MailboxTabShown(), true, "shown at the mailbox")

	MailFrame:Hide()
	ns.fire("MAIL_CLOSED")
	Stub.FireTimers()
	equal(ns.UI:MailboxTabShown(), false, "gone with it")
end)

--[[
	The menu is Menu-Kit's (Style Guide → MENUS): the add-on's name, a spacer, the row that opens
	the window, the row that puts it back in its first place, then the Options footer the kit
	builds, a spacer, a separator and Options.
]]
test("hovering the tab opens its menu, and its first row opens the window", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)

	local kinds, labels = {}, {}
	for _, entry in ipairs(ns.UI:MailboxTabMenuEntries()) do
		kinds[#kinds + 1] = entry.kind
		labels[#labels + 1] = entry.left or ""
	end
	equal(
		table.concat(kinds, " "),
		"header spacer action action spacer separator action",
		"the kit's rows, in its order"
	)
	local entries = ns.UI:MailboxTabMenuEntries()
	equal(labels[1], ns.L["WINDOW_TITLE"], "named for the window it opens")
	equal(entries[1].right, ns.L["ADDON_SHORT_NAME"], "with the Short Name on the right")
	equal(labels[3], ns.L["REOPEN_MENU_OPEN"], "the window first")
	equal(labels[4], ns.L["REOPEN_MENU_RESET_POSITION"], "then Reset Window Position")
	equal(labels[7], ns.L["REOPEN_MENU_OPTIONS"]:format(ns.L["ADDON_SHORT_NAME"]), "then whose options open")

	PlayItForwardMailboxTab:GetScript("OnEnter")(PlayItForwardMailboxTab)
	check(ns.UI:MailboxTabMenuShown(), "the mouse over the tab opens the menu")
	ns.UI:MailboxTabMenuEntries()[3].onClick()
	check(windowShown(ns), "and Open Distribution Window opens it")
	equal(ns.UI:MailboxTabLit(), true, "with the tab lit")
end)

-- Reset Window Position hands off to the window's own reset (Features/UI-Window.lua).
test("the menu's Reset Window Position row resets the window's place", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)

	local reset = ns.UI:MailboxTabMenuEntries()[4]
	local calls = 0
	local real = ns.UI.ResetWindowPosition
	ns.UI.ResetWindowPosition = function()
		calls = calls + 1
	end
	reset.onClick()
	ns.UI.ResetWindowPosition = real
	equal(calls, 1, "the window is put back")
	equal(reset.closes, true, "and the menu closes")
end)

--------------------------------------------------------------------------------
-- The list behind the tab
--------------------------------------------------------------------------------

--[[
	An item the client has not cached yet reads as no item at all. With the window up, the item
	resolving joins the list without a second click.
]]
test("an item resolving with the window open joins the list", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })
	openMailbox(ns)
	clickTab()
	equal(#ns.UI:Items(), 0, "nothing listed while the item is unresolved")

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id)
	Stub.FireTimers()

	equal(#ns.UI:Items(), 1, "the item is listed once it resolves")
end)

test("an item resolving with the window shut opens nothing", function()
	local ns = load()
	local robe = casterCloth()
	robe.cached = false
	Stub.SetBackpack({ robe })
	openMailbox(ns)

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id)
	Stub.FireTimers()

	check(not windowShown(ns), "the window stays shut")
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
	openMailbox(ns)
	clickTab()

	robe.cached = true
	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id + 1, true)
	Stub.FireTimers()
	equal(#ns.UI:Items(), 0, "an unrelated item answering re-reads nothing")

	ns.fire("GET_ITEM_INFO_RECEIVED", robe.id, true)
	Stub.FireTimers()
	equal(#ns.UI:Items(), 1, "the robe answering lists it")
end)

-- A setting changed with no window built is read on the next open, not when the bags next move.

test("a setting changed with no window is read when the tab opens it", function()
	local ns = load()
	ns.db.profile.includeGear = false
	Stub.SetBackpack({ casterCloth() })
	openMailbox(ns)
	clickTab()
	equal(#ns.UI:Items(), 0, "gear off, nothing listed")
	clickTab()

	-- What the options panel's toggle does, with the window shut.
	ns.db.profile.includeGear = true
	ns.UI:Rescan()
	check(not windowShown(ns), "the setting opens nothing")

	clickTab()
	equal(#ns.UI:Items(), 1, "the tab reads the bags against the new setting")
end)

--------------------------------------------------------------------------------
-- TSM's mail window in Blizzard's place
--------------------------------------------------------------------------------

--[[
	TSM hides Blizzard's mail window and shows its own, which has no name. The tab finds it by the
	file that made it, a child of UIParent from a TradeSkillMaster file, while TSM's public API says
	its mail window is up.
]]
local function withTSM(up)
	local window = Stub.NewFrame()
	rawset(window, "GetSourceLocation", function()
		return "Interface/AddOns/TradeSkillMaster/LibTSMUI/Source/Util/Widgets.lua:577"
	end)
	local other = Stub.NewFrame()
	rawset(other, "GetSourceLocation", function()
		return "Interface/AddOns/SomethingElse/Frame.lua:12"
	end)
	window:Show()
	other:Show()
	-- A frame the game locks away from add-ons, as the shop and Edit Mode's dialogs are: any call but IsForbidden errors.
	local locked = setmetatable({}, {
		__index = function(_, key)
			if key == "IsForbidden" then
				return function()
					return true
				end
			end
			return function()
				error("Attempt to access forbidden object from code tainted by an AddOn")
			end
		end,
	})
	rawset(UIParent, "GetChildren", function()
		return locked, other, window
	end)
	TSM_API = {
		IsUIVisible = function(name)
			return name == "MAILING" and up()
		end,
	}
	return window
end

test("the tab sits on TSM's mail window when TSM replaces Blizzard's", function()
	local ns = load()
	Stub.SetBackpack({ casterCloth() })
	local tsmUp = true
	local window = withTSM(function()
		return tsmUp
	end)

	ns.fire("MAIL_SHOW")

	equal(ns.UI:MailboxTabShown(), true, "the tab is up with Blizzard's window hidden")
	check(ns.UI:MailboxTabHost() == window, "on TSM's window, not the other add-on's")
	clickTab()
	check(windowShown(ns), "and the tab opens the window")
	equal(#ns.UI:Items(), 1, "with the list filled")

	tsmUp = false
	window:Hide()
	ns.UI:SyncMailboxTab()
	equal(ns.UI:MailboxTabShown(), false, "gone when TSM's window closes")
	TSM_API = nil
end)

test("TSM's WoW UI button brings the tab back to Blizzard's window", function()
	local ns = load()
	local window = withTSM(function()
		return not MailFrame:IsShown()
	end)
	ns.fire("MAIL_SHOW")
	check(ns.UI:MailboxTabHost() == window, "on TSM's window first")

	window:Hide()
	MailFrame:Show()
	ns.UI:SyncMailboxTab()
	check(ns.UI:MailboxTabHost() == MailFrame, "then on Blizzard's")
	equal(ns.UI:MailboxTabShown(), true, "still up")
	TSM_API = nil
end)

test("with no mail window showing, no tab", function()
	local ns = load()
	ns.fire("MAIL_SHOW")
	equal(ns.UI:MailboxTabShown(), false, "no Blizzard window and no TSM, no tab")
end)
