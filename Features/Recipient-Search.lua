local _, ns = ...
local L = ns.L

ns.Who = {}
local Who = ns.Who

--------------------------------------------------------------------------------
-- Zone Search Order
--------------------------------------------------------------------------------

-- Data/Zones.lua holds the rows and the column legend; this is their only consumer.
local ZONE = ns.Data.ZoneColumns

-- Era and Wrath-or-later are the flags the add-on already keeps; anything else is TBC.
local function flavorColumn()
	if ns.isEra then
		return ZONE.ERA
	end
	if ns.isWrathOrLater then
		return ZONE.WRATH
	end
	return ZONE.TBC
end

--[[
	Every zone worth asking about for a level band, best first. Ordering decides how many
	presses the search takes. Three keys:

	  overlap    how much of the band the zone covers
	  centrality how close the band sits to the middle of the zone's range -- a level at the
	             edge is one people pass through, the middle is where they sit and quest.
	             This is what puts a Horde 21-22 search in the Barrens first.
	  width      narrower zone first among equals, for the same reason

	Popularity is deliberately not a key: there is no honest way to rank it from this table,
	and an invented number would look like the three real measurements. Levels come back
	clipped to the overlap, so the query asks only what that zone can answer for.
]]
function ns.Data.ZonesFor(lo, hi)
	local faction = UnitFactionGroup("player")
	local column = flavorColumn()
	local bandMid = (lo + hi) / 2

	local out = {}
	for index, zone in ipairs(ns.Data.Zones) do
		local from, to = math.max(zone[ZONE.MIN], lo), math.min(zone[ZONE.MAX], hi)
		--[[
			An unresolved faction admits every zone rather than none: over-including costs one
			empty query, excluding on a nil answer silently drops half the list.
		]]
		local rightSide = (zone[ZONE.FACTION] == nil) or (faction == nil) or (zone[ZONE.FACTION] == faction)
		if from <= to and rightSide and zone[column] == 1 then
			out[#out + 1] = {
				name = zone[ZONE.NAME],
				lo = from,
				hi = to,
				overlap = to - from + 1,
				centrality = math.abs(bandMid - (zone[ZONE.MIN] + zone[ZONE.MAX]) / 2),
				width = zone[ZONE.MAX] - zone[ZONE.MIN],
				index = index,
			}
		end
	end

	table.sort(out, function(a, b)
		if a.overlap ~= b.overlap then
			return a.overlap > b.overlap
		end
		if a.centrality ~= b.centrality then
			return a.centrality < b.centrality
		end
		if a.width ~= b.width then
			return a.width < b.width
		end
		return a.index < b.index -- stable: table order among genuine equals
	end)
	return out
end

--------------------------------------------------------------------------------
-- Querying
--------------------------------------------------------------------------------

--[[
	C_FriendList.SendWho is hardware-event gated on 1.15: a call outside the stack of a real
	click raises ADDON_ACTION_BLOCKED and does nothing -- no error, no WHO_LIST_UPDATE, just
	silence. Queries cannot be chained on a timer; every one rides a button press. That is why
	they go out by level band, with results sorted into classes here, since one query per class
	would mean nine presses.

	QUERIES GO OUT BY ZONE, AND ONE MATCH ENDS THE SEARCH. A bare `/who 21-22` comes back at
	the server's 50-result cap on a connected cluster, and what it holds is mostly people
	standing in a capital. Adding `z-"Redridge Mountains"` fixes both: people out in the world
	at that level, and few enough that the cap stops mattering.

	One level-21 mage can receive the cloak as well as forty can, so the search stops at the
	first viable candidate per item and Mail-Window clears the plan once nothing is unmatched.
]]

--[[
	The server sends at most this many results and says nothing about the rest. Counted, never
	acted on: the roster report reads it to tell a thin realm from a thin sample.
]]
local WHO_RESULT_CAP = 50

-- Exposed so the roster report names the same number this file tests against.
Who.RESULT_CAP = WHO_RESULT_CAP

local RESULT_TIMEOUT = 6 -- give up on a query that never answers (i.e. was blocked)

--[[
	Neither is a setting. The panel opening on every press is a side effect of reading results
	at all, and the server rate-limits /who independently, so lowering the throttle only turns
	a query into a silent no-op that reads as the add-on being broken.
]]
local SUPPRESS_WHO_UI = true
local WHO_THROTTLE = 5

--[[
	Exposed because Mail-Window locks its button for exactly this long: a button that re-enables
	early offers a press that does nothing.
]]
Who.THROTTLE = WHO_THROTTLE

--[[
	/who is sent as chat text, and past the limit the query is not answered rather than
	truncated, so this is a hard stop and the zone list is chunked to fit under it.
]]
local FILTER_MAX = 240
Who.FILTER_MAX = FILTER_MAX

--[[
	Attempts still to make, one per press. /who ORs repeated filters of the same kind, so a
	level range, its zones and its classes are all one query:

	  16-19 z-"Westfall" z-"Loch Modan" z-"Duskwood" c-"Warrior" c-"Paladin"

	The class half matters as much as the zone half: without it, half of a capped answer is
	people who cannot receive anything in the bag.
]]
local plan = {}
local planned = 0
local pending = nil -- the query awaiting a result
local lastSent = 0

-- 'c-"Warrior" c-"Paladin"', or "" when it would exclude nobody and only cost length.
local function classFilter(classes)
	if not classes or #classes == 0 then
		return "", {}
	end
	--[[
		A filter naming every class admits everybody, so it is pure length against a budget.
		Compared against Matcher:Classes, which is what the roster can actually contain.
	]]
	if #classes >= #ns.Matcher:Classes() then
		return "", {}
	end

	local names, parts = {}, {}
	for _, token in ipairs(classes) do
		local name = ns.ClassName(token)
		if name and name ~= "" then
			names[#names + 1] = name
			parts[#parts + 1] = ('c-"%s"'):format(name)
		end
	end
	table.sort(names)
	table.sort(parts)
	return table.concat(parts, " "), names
end

-- Class names for the status line. Six of them is not information, so it stops at three.
local function classLabel(names)
	if #names == 0 then
		return nil
	end
	if #names <= 3 then
		return table.concat(names, ", ")
	end
	return ("%s +%d"):format(table.concat({ names[1], names[2], names[3] }, ", "), #names - 3)
end

--[[
	The readable form of a query, for the roster report. Read from ns.DiagnosticsStrings at call
	time rather than aliased at file scope, because Features/Diagnostics.lua loads after this
	one.
]]
local function newAttempt(lo, hi, zones, classPart, classNames)
	local D = ns.DiagnosticsStrings
	local levels = ("%d-%d"):format(lo, hi)
	local query = levels
	local label

	if zones and #zones > 0 then
		local parts = {}
		for _, name in ipairs(zones) do
			parts[#parts + 1] = ('z-"%s"'):format(name)
		end
		query = query .. " " .. table.concat(parts, " ")
		label = (#zones == 1) and D.WHO_LABEL_IN_ZONE:format(zones[1], levels)
			or D.WHO_LABEL_ZONES:format(#zones, levels)
	else
		label = D.WHO_LABEL_ANYWHERE:format(levels)
	end

	if classPart ~= "" then
		query = query .. " " .. classPart
		local named = classLabel(classNames)
		if named then
			label = D.WHO_LABEL_FOR_CLASSES:format(label, named)
		end
	end

	return { query = query, label = label, lo = lo, hi = hi }
end

--[[
	Session totals for the roster report; Who:Clear leaves them alone so the report still has
	them after a plan finishes.

	connectedRealm counts results carrying a "-Realm" suffix. They are KEPT: every Classic Era
	and TBC realm is connected and anyone in a /who result can be mailed, so the suffix says
	nothing about reachability. capped counts queries that came back at the full cap, which is
	the difference between a thin realm and a thin sample.
]]
local counts = { seen = 0, connectedRealm = 0, unknownClass = 0, capped = 0 }

function Who:ResultStats()
	return counts
end

local function parseResults()
	local list = {}
	local raw = C_FriendList.GetNumWhoResults()
	for i = 1, raw do
		local info = C_FriendList.GetWhoInfo(i)
		if info and info.fullName then
			counts.seen = counts.seen + 1
			if info.fullName:find("-", 1, true) then
				counts.connectedRealm = counts.connectedRealm + 1
			end
			--[[
				An unreadable class token is the only reason a result is discarded: without it
				there is no way to tell whether they can wear the item.
			]]
			local token = info.filename or ns.classTokenByName[info.classStr]
			if token then
				table.insert(list, {
					name = info.fullName,
					level = info.level,
					class = token,
					area = info.area,
				})
			else
				counts.unknownClass = counts.unknownClass + 1
			end
		end
	end
	--[[
		raw travels with the list because the cap is about what the server sent, not what
		survived the class filter: #list would miss a truncated band on one unreadable class.
	]]
	return list, raw
end

--[[
	Routing and hiding are two jobs, and only routing is SetWhoToUi's. SetWhoToUi(true) sends
	results to the list GetWhoInfo reads; with it false they print to chat and there is nothing
	to read. Restored to false afterwards so a /who the player types behaves as expected.

	It does not keep the Who window shut. The window opens when results arrive, so it is hidden
	after they are read, and only when this add-on opened it.
]]
local panelWasOpen = false

local function whoPanel()
	return FriendsFrame
end

local function beginQuery()
	panelWasOpen = whoPanel() ~= nil and whoPanel():IsShown()
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, true)
	end
end

local function endQuery()
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, false)
	end
	local panel = whoPanel()
	if SUPPRESS_WHO_UI and panel and panel:IsShown() and not panelWasOpen then
		pcall(HideUIPanel, panel)
	end
end

-- There is deliberately no subdivide: a capped answer is noted, never split and requeued.
ns.on("WHO_LIST_UPDATE", function()
	if not pending then
		return
	end
	local job = pending
	pending = nil
	-- Read before restoring, then close the window this add-on caused to open.
	local results, raw = parseResults()
	endQuery()

	if raw >= WHO_RESULT_CAP then
		counts.capped = counts.capped + 1
	end

	--[[
		An abandoned query is still read this far, because endQuery is the only thing that puts
		SetWhoToUi back and closes the panel. What it does not get is its callback: the plan is
		gone, and handing results to it would assign recipients in a window already closed.
	]]
	if job.canceled then
		return
	end

	if job.cb then
		job.cb(results, job.label)
	end
end)

-- Turn a blocked call into an explanation instead of a mystery BugSack popup.
ns.on("ADDON_ACTION_BLOCKED", function(addon, func)
	if addon ~= ns.name then
		return
	end
	if func and func:find("SendWho", 1, true) then
		ns:PrintWarning(L["WHO_BLOCKED"])
	end
end)

--[[
	One attempt from each band before coming back for seconds. Interleaved, not concatenated: a
	bag holding a level 15 cloak and a level 45 sword has two bands with nothing in common, and
	draining one band's zones first means five presses before the other item is looked at once.
]]
local function interleave(lists)
	local out, depth = {}, 0
	for _, list in ipairs(lists) do
		depth = math.max(depth, #list)
	end
	for index = 1, depth do
		for _, list in ipairs(lists) do
			if list[index] then
				out[#out + 1] = list[index]
			end
		end
	end
	return out
end

--[[
	Packs a band's zones into as few queries as the length budget allows, best zones
	first so a chunked list still leads with where the people are.
]]
local function zoneChunks(lo, hi, classPart)
	local fixed = #("%d-%d"):format(lo, hi) + (classPart ~= "" and (#classPart + 1) or 0)
	local out, current, used = {}, {}, 0

	for _, zone in ipairs(ns.Data.ZonesFor(lo, hi)) do
		local piece = #('z-"%s"'):format(zone.name) + 1
		--[[
			Never emit an empty chunk: a zone name long enough to blow the budget on its own
			still gets its own query rather than being dropped silently.
		]]
		if #current > 0 and fixed + used + piece > FILTER_MAX then
			out[#out + 1] = current
			current, used = {}, 0
		end
		current[#current + 1] = zone.name
		used = used + piece
	end
	if #current > 0 then
		out[#out + 1] = current
	end
	return out
end

--[[
	Abandons what is in flight without forgetting it. The client still answers, and that answer
	runs endQuery -- the only thing that restores SetWhoToUi and closes the Who panel. Drop the
	reference and Blizzard's Who window appears by itself seconds after the player closed ours.

	A canceled job answers nobody: no callback, and its band is not put back on the plan.
	Who:Step refuses to send while one is pending, so a new plan simply waits for it to land.
]]
local function cancelPending()
	if pending then
		pending.canceled = true
	end
end

--[[
	The attempt queue, built from the level bands that have an item waiting, each carrying the
	classes those items can go to. Per band, in order:

	  1  the zones covering it, in one query where they fit, filtered to those classes --
	     where somebody levelling actually is, and the press that usually ends the search
	  2  the same class filter with no zones, for a recipient in a city or an unlisted zone
	  3  bare levels, no filters at all

	Two and three are widening steps, each giving up one constraint in the order that costs
	least. Three answers with whoever is standing in a capital, the population zone filtering
	exists to avoid, so it is last -- but without it a band whose zones are empty at 3am runs
	out of ideas with no way to say so.

	The count returned is not a countdown: the search stops at the first viable match, so most
	of these attempts are never made.
]]
function Who:Plan(groups)
	wipe(plan)
	cancelPending()

	local zoned, widened, bare = {}, {}, {}
	for _, group in ipairs(groups or {}) do
		local lo = math.max(1, group.lo or 1)
		local hi = math.max(lo, group.hi or lo)
		local classPart, classNames = classFilter(group.classes)

		local perBand = {}
		for _, chunk in ipairs(zoneChunks(lo, hi, classPart)) do
			perBand[#perBand + 1] = newAttempt(lo, hi, chunk, classPart, classNames)
		end
		zoned[#zoned + 1] = perBand

		if classPart ~= "" then
			widened[#widened + 1] = { newAttempt(lo, hi, nil, classPart, classNames) }
		end
		bare[#bare + 1] = { newAttempt(lo, hi, nil, "", {}) }
	end

	for _, stage in ipairs({ zoned, widened, bare }) do
		for _, attempt in ipairs(interleave(stage)) do
			plan[#plan + 1] = attempt
		end
	end

	planned = #plan
	return #plan
end

-- How many attempts the plan started with. Read by the diagnostics roster report.
function Who:Planned()
	return planned
end

--[[
	A canceled query is not a place left to look. Counting it would leave Scan Again offered
	over an empty plan and send FindRecipients down its mid-plan branch to a press that cannot
	send.
]]
function Who:Remaining()
	return #plan + ((pending and not pending.canceled) and 1 or 0)
end

-- Where the next press will look, for the status line.
function Who:Peek()
	return plan[1] and plan[1].label
end

--[[
	Sends the next planned query. Must be called from a click or keypress handler.
	Returns sent, then either the query string or the seconds left to wait.
]]
function Who:Step(callback)
	if pending then
		return false, 0
	end
	if #plan == 0 then
		return false, 0
	end

	local wait = WHO_THROTTLE - (GetTime() - lastSent)
	if wait > 0 then
		return false, wait
	end

	local attempt = table.remove(plan, 1)
	-- The attempt travels on the job so an unanswered query can be put back.
	local job = { attempt = attempt, label = attempt.label, cb = callback }
	pending = job
	lastSent = GetTime()

	beginQuery()
	C_FriendList.SendWho(attempt.query)

	--[[
		A blocked call never fires WHO_LIST_UPDATE, so this timeout stops the UI waiting on an
		answer that is not coming. The band goes back on the front of the plan first, or it is
		lost for good and Remaining counts down as though it had succeeded. An empty answer is
		not requeued: WHO_LIST_UPDATE with no results means nobody is there.
	]]
	C_Timer.After(RESULT_TIMEOUT, function()
		if pending ~= job then
			return
		end
		pending = nil
		endQuery()
		-- Canceled: not put back, or the next plan is seeded with a band nothing asked for.
		if job.canceled then
			return
		end
		table.insert(plan, 1, job.attempt)
		if job.cb then
			job.cb(nil, job.label)
		end -- nil results = no answer
	end)

	return true, job.label
end

--[[
	Drops the plan. A query in flight is canceled rather than forgotten, so it still lands and
	still cleans up after itself. See cancelPending above.
]]
function Who:Clear()
	wipe(plan)
	cancelPending()
end
