--[[
	Where /who looks, and when it stops looking.

	The old search asked `/who 21-22` with no zone, got the server's 50-result cap back,
	split the band and asked twice more. A six-press plan grew to fifteen while the
	player watched, and it kept counting down after every item already had a recipient:
	"Not done: press again for levels 21-22 (0 item(s) unmatched)".

	Two things fix it and both are pinned here. Queries carry a zone, so what comes back
	is people out levelling rather than the capital-city population that fills a bare
	level query. And the plan is abandoned the moment no gift is left unmatched, because
	one level 21 mage can receive the cloak as well as forty of them can.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function names(zones)
	local out = {}
	for index, zone in ipairs(zones) do
		out[index] = zone.name
	end
	return out
end

local function contains(list, wanted)
	for _, value in ipairs(list) do
		if value == wanted then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Zone selection
--------------------------------------------------------------------------------

test("only the player's own faction's zones are offered", function()
	local ns = load()
	local found = names(ns.Data.ZonesFor(2, 5))

	--[[
		/who is same-faction, so a Horde starting zone can never answer an Alliance
		query. Offering one is a press that could not have worked.
	]]
	check(contains(found, "Elwynn Forest"), "Alliance starting zone offered")
	check(not contains(found, "Durotar"), "Horde starting zone not offered")
	check(not contains(found, "Tirisfal Glades"), "nor the other one")
end)

test("contested zones are offered to both factions", function()
	local ns = load()
	local alliance = names(ns.Data.ZonesFor(31, 33))
	UnitFactionGroup = function()
		return "Horde"
	end
	local horde = names(ns.Data.ZonesFor(31, 33))

	check(contains(alliance, "Arathi Highlands"), "Alliance can search Arathi")
	check(contains(horde, "Arathi Highlands"), "so can Horde")
end)

test("zones from a later expansion are not searched on Era", function()
	local ns = load()
	local found = names(ns.Data.ZonesFor(60, 63))

	check(not contains(found, "Zangarmarsh"), "no Outland zone on an Era client")
	check(not contains(found, "Hellfire Peninsula"), "nor that one")
end)

--[[
	Ordering is what decides how many presses this takes, since each press is one zone.
	A band sitting in the middle of a zone's range should beat one clinging to its edge.
]]
test("the best zone for a band comes first", function()
	local ns = load()
	local found = names(ns.Data.ZonesFor(21, 22))

	check(#found > 0, "Alliance has somewhere to look at 21")
	check(
		found[1] == "Redridge Mountains" or found[1] == "Duskwood",
		"a zone centered near 21 leads, got " .. tostring(found[1])
	)

	--[[
		Hillsbrad covers 21-22 too, but only just: its range is 20-31, so a level 21 is
		somebody who arrived this morning. It belongs in the list and behind the others.
	]]
	local hillsbrad
	for index, name in ipairs(found) do
		if name == "Hillsbrad Foothills" then
			hillsbrad = index
		end
	end
	check(hillsbrad ~= nil, "Hillsbrad is still offered")
	check(hillsbrad > 1, "but not first")
end)

test("a query asks only for the levels its zone can answer for", function()
	local ns = load()
	for _, zone in ipairs(ns.Data.ZonesFor(10, 30)) do
		if zone.name == "Redridge Mountains" then
			equal(zone.lo, 15, "clipped to where Redridge starts")
			equal(zone.hi, 25, "and to where it ends")
			return
		end
	end
	check(false, "Redridge was not offered for a 10-30 band")
end)

--------------------------------------------------------------------------------
-- Query planning
--------------------------------------------------------------------------------

--[[
	Which zones lead is Data/Recipients-Zones.lua's job and is checked above. This is about the
	shape of the plan: zones first, nothing last. They arrive lumped into one query now,
	so the first label names a count rather than a place -- see Tests/Query-Building.lua.
]]
test("the first query carries zones, and the last one does not", function()
	local ns = load()
	local steps = ns.Who:Plan({ { lo = 21, hi = 22 } })

	check(steps > 1, "more than one place to look")
	check(ns.Who:Peek():find("zone"), "starts in the zones: " .. ns.Who:Peek())

	--[[
		The bare level query is the one this whole approach moved away from, so it is
		last. It is still there: without it a band whose zones are all empty at 3am would
		cycle forever with no way to say it had run out of ideas.
	]]
	local last
	while ns.Who:Remaining() > 0 do
		last = ns.Who:Peek()
		ns.Who:Step(function() end)
		Stub.now = Stub.now + 60
		ns.fire("WHO_LIST_UPDATE")
	end
	equal(last, ns.DiagnosticsStrings.WHO_LABEL_ANYWHERE:format("21-22"), "the last resort is a bare level query")
end)

test("bands take turns rather than one running to exhaustion", function()
	local ns = load()
	ns.Who:Plan({ { lo = 21, hi = 22 }, { lo = 45, hi = 47 } })

	local first = ns.Who:Peek()
	ns.Who:Step(function() end)
	Stub.now = Stub.now + 60
	ns.fire("WHO_LIST_UPDATE")
	local second = ns.Who:Peek()

	--[[
		A bag holding a level 24 cloak and a level 48 sword has two bands with nothing in
		common. Running one to exhaustion first means five presses before the other item
		is looked at once.
	]]
	check(first ~= second, "the second press looks somewhere else")
	check(not (first:find("21%-22") and second:find("21%-22")), "and at the other band: " .. first .. " / " .. second)
end)

--[[
	The growth the author watched happen. A capped answer used to be split into two
	narrower bands pushed to the front of the plan, and on a connected cluster nearly
	every bare query capped.
]]
test("a capped answer does not grow the plan", function()
	local ns = load()
	ns.Who:Plan({ { lo = 21, hi = 22 } })
	local before = ns.Who:Remaining()

	Stub.whoResults = {}
	for index = 1, ns.Who.RESULT_CAP do
		table.insert(Stub.whoResults, { name = "Filler" .. index, level = 21, class = "MAGE" })
	end

	ns.Who:Step(function() end)
	ns.fire("WHO_LIST_UPDATE")

	equal(ns.Who:Remaining(), before - 1, "the plan got shorter, not longer")
	equal(ns.Who:ResultStats().capped, 1, "the cap was still noticed and counted")
end)

--------------------------------------------------------------------------------
-- Stopping
--------------------------------------------------------------------------------

local function bagWithOneCloak(ns)
	Stub.SetBackpack({
		Stub.Item({
			name = "Ivy Orb of the Eagle",
			reqLevel = 20,
			equipLoc = "INVTYPE_CHEST",
			classID = 4,
			subclassID = 1, -- CLOTH
			stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
		}),
	})
	ns.fire("MAIL_SHOW")
end

--[[
	The button is dead for the length of the /who throttle after a press.

	Not decoration: Who:Step refuses a query inside that window and the only sign was a
	line of status text, so the button looked live and did nothing. Held for the full
	throttle rather than until the answer lands, because an answer often comes back in
	well under a second and the server would still refuse the next press.
]]
test("pressing Find Recipients locks the button while the throttle runs", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()

	equal(ns.UI.frame.findButton:IsEnabled(), false, "the button is dead")
	equal(ns.UI.frame.findButton.shownText, ns.L["BUTTON_SEARCHING"], "and says what it is doing")
end)

test("the lock outlasts the answer", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	Stub.whoResults = { { name = "Agathe", level = 18, class = "MAGE" } }
	ns.fire("WHO_LIST_UPDATE")

	--[[
		Everything downstream of an answer calls _syncFindButton -- the query callback and
		_assign both do -- and either would put a live-looking label back on a button the
		server will still refuse.
	]]
	equal(ns.UI.frame.findButton:IsEnabled(), false, "still dead after the results arrive")
	equal(ns.UI.frame.findButton.shownText, ns.L["BUTTON_SEARCHING"], "still saying so")
end)

test("the button comes back when the throttle is up", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	Stub.FireTimers()

	equal(ns.UI.frame.findButton:IsEnabled(), true, "clickable again")
	equal(ns.UI.frame.findButton.shownText, ns.L["BUTTON_SCAN_AGAIN"], "and offering another look")
end)

--[[
	One number, in Recipients-Who.lua. A lock shorter than the throttle hands back a
	press the server refuses; longer, and it sits idle for no reason.
]]
test("the lock lasts exactly as long as the throttle", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()

	local locks = 0
	for _, timer in ipairs(Stub.timers) do
		if timer.delay == ns.Who.THROTTLE then
			locks = locks + 1
		end
	end
	check(locks > 0, "a timer was set for the throttle length of " .. tostring(ns.Who.THROTTLE))
end)

test("finding a recipient ends the search", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	check(#Stub.whoQueries == 1, "one query went out")
	check(Stub.whoQueries[1]:find('z%-"'), "with a zone on it: " .. Stub.whoQueries[1])

	Stub.whoResults = { { name = "Agathe", level = 18, class = "MAGE" } }
	ns.fire("WHO_LIST_UPDATE")

	equal(ns.UI:Items()[1].recipient.name, "Agathe", "the item found somebody")
	equal(ns.Who:Remaining(), 0, "and the search stopped rather than counting down")

	--[[
		The button is still locked here: it holds for the whole /who throttle rather than
		until the answer lands. Its final label is what the timer restores.
	]]
	Stub.FireTimers()
	equal(ns.UI.frame.findButton.shownText, ns.L["BUTTON_FIND_RECIPIENTS"], "the button is not offering Scan Again")
end)

--[[
	Abandoning a query must not abandon its cleanup.

	Who:Clear used to drop the pending job outright, so when the answer landed the
	handler returned early and endQuery never ran: SetWhoToUi stayed true and the Who
	panel this add-on had caused to open was left standing. The player closed our window
	and Blizzard's opened by itself a second later.

	The panel is the observable here because it is the symptom. The stub raises it by
	hand the way the client does when results arrive, and endQuery is the only thing in
	the add-on that puts it away again.
]]
test("a query abandoned mid-flight still cleans up after itself", function()
	local ns = load()
	bagWithOneCloak(ns)

	local answered = 0
	ns.Who:Plan({ { lo = 17, hi = 18 } })
	ns.Who:Step(function()
		answered = answered + 1
	end)

	ns.Who:Clear()

	FriendsFrame:Show() -- the client raising its own panel as results arrive
	Stub.whoResults = { { name = "Agathe", level = 18, class = "MAGE" } }
	ns.fire("WHO_LIST_UPDATE")

	check(not FriendsFrame:IsShown(), "the panel this add-on caused was closed again")
	equal(answered, 0, "and the abandoned query answered nobody")
	equal(ns.Who:Remaining(), 0, "leaving nothing behind to press at")
end)

--[[
	THE WHO PANEL MUST NEVER LEARN A QUERY ANSWERED. The stock UI opens it on
	WHO_LIST_UPDATE, and the panel is a UIPanel: opening it over an open mailbox makes
	the panel manager close MailFrame, whose OnHide ends the mailbox interaction --
	pressing Find Recipients at a mailbox closed the mailbox. Hiding the panel after
	reading results (above) is the safety net, not the fix: by then the mailbox is gone.
	So the frame's WHO_LIST_UPDATE registration is lifted for the life of one query and
	put back on the way out, the old WhoLib approach.
]]
test("the Who panel never hears a query answered", function()
	local ns = load()
	bagWithOneCloak(ns)

	check(FriendsFrame:IsEventRegistered("WHO_LIST_UPDATE"), "the panel listens, as the stock UI ships")

	ns.UI:FindRecipients()
	check(not FriendsFrame:IsEventRegistered("WHO_LIST_UPDATE"), "deaf while our query is in flight")

	Stub.whoResults = { { name = "Agathe", level = 18, class = "MAGE" } }
	ns.fire("WHO_LIST_UPDATE")
	check(FriendsFrame:IsEventRegistered("WHO_LIST_UPDATE"), "and listening again once the answer is read")
end)

test("an unanswered query still gives the panel its ears back", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	check(not FriendsFrame:IsEventRegistered("WHO_LIST_UPDATE"), "deaf while waiting")

	Stub.FireTimers() -- the RESULT_TIMEOUT path: a blocked query never answers
	check(FriendsFrame:IsEventRegistered("WHO_LIST_UPDATE"), "restored by the timeout's cleanup")
end)

test("a fresh plan sends again once the abandoned query has landed", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.Who:Plan({ { lo = 17, hi = 18 } })
	ns.Who:Step(function() end)
	ns.Who:Clear()
	ns.fire("WHO_LIST_UPDATE")

	Stub.now = Stub.now + 60
	ns.Who:Plan({ { lo = 17, hi = 18 } })
	local sent = ns.Who:Step(function() end)

	check(sent, "the next plan is not blocked by the one that was abandoned")
	equal(#Stub.whoQueries, 2, "and its query actually went out")
end)

--[[
	The same thing by the route a player takes: the X on the window, which calls
	Who:Clear. Nothing may be assigned into a window they have closed.
]]
test("closing the window mid-search leaves no Who panel and no assignment", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	ns.UI:Close()

	FriendsFrame:Show()
	Stub.whoResults = { { name = "Agathe", level = 18, class = "MAGE" } }
	ns.fire("WHO_LIST_UPDATE")

	check(not FriendsFrame:IsShown(), "the Who panel did not outlive our window")
	equal(ns.UI:Items()[1].recipient, nil, "and the closed window took no recipient")
end)

test("an empty answer keeps the search going", function()
	local ns = load()
	bagWithOneCloak(ns)

	ns.UI:FindRecipients()
	Stub.whoResults = {}
	ns.fire("WHO_LIST_UPDATE")

	equal(ns.UI:Items()[1].recipient, nil, "nobody found")
	check(ns.Who:Remaining() > 0, "somewhere else left to look")

	Stub.FireTimers() -- the throttle lock, which outlasts the answer
	equal(ns.UI.frame.findButton.shownText, ns.L["BUTTON_SCAN_AGAIN"], "and the button says so")
end)
