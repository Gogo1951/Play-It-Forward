local _, ns = ...
local L = ns.L

-- Sends what Features/Recipients-Who-Plan.lua plans; the plan and the session totals are its tables.
local Who = ns.Who
local plan, counts = Who.plan, Who.counts

--------------------------------------------------------------------------------
-- Class Names
--------------------------------------------------------------------------------

-- A result's localized class name back to its token, either gender. Built once at load.
local classTokenByName = {}
do
	for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
		classTokenByName[name] = token
	end
	for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
		classTokenByName[name] = token
	end
end

--------------------------------------------------------------------------------
-- Faction
--------------------------------------------------------------------------------

--[[
	Mail does not cross factions, and /who on Forever 1.60.1 answers with both: a Horde search
	paired a Horde player with an Alliance one and the send came back "Target is unfriendly."
	(2026-10-06). Era and TBC answer same-faction, so this drops nobody there.

	A result carries only its localized race, so faction is read off the race table. A race this
	client cannot place -- unknown, or one name shared by races of two factions -- is KEPT: a
	wrong drop loses a recipient for good, where a wrong keep costs one refused send, which
	Features/Mail-Sender.lua recognizes and moves past. Built on first use, then kept.
]]
local factionByRace

local function raceFactions()
	if factionByRace then
		return factionByRace
	end
	factionByRace = {}
	local info = C_CreatureInfo
	if not (info and info.GetRaceInfo and info.GetFactionInfo) then
		return factionByRace
	end
	for raceID = 1, 100 do
		local race = info.GetRaceInfo(raceID)
		local faction = info.GetFactionInfo(raceID)
		local tag = faction and faction.groupTag
		if race and race.raceName and (tag == "Alliance" or tag == "Horde") then
			local known = factionByRace[race.raceName]
			-- false marks a name two factions share; it never becomes a faction again.
			if known == nil then
				factionByRace[race.raceName] = tag
			elseif known ~= tag then
				factionByRace[race.raceName] = false
			end
		end
	end
	return factionByRace
end

local function otherFaction(raceName)
	local mine = UnitFactionGroup("player")
	if not (mine == "Alliance" or mine == "Horde") or not raceName then
		return false
	end
	local theirs = raceFactions()[raceName]
	return theirs and theirs ~= mine or false
end

--------------------------------------------------------------------------------
-- Querying
--------------------------------------------------------------------------------

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

-- UI-Mailbox locks its button for exactly this long; re-enabling early offers a dead press.
Who.THROTTLE = WHO_THROTTLE

local pending = nil -- the query awaiting a result
local lastSent = 0

function Who:ResultStats()
	return counts
end

local function parseResults()
	local list = {}
	-- The second return is how many matched server-side, which is what tells a full answer apart.
	local raw, total = C_FriendList.GetNumWhoResults()
	for i = 1, raw do
		local info = C_FriendList.GetWhoInfo(i)
		if info and info.fullName then
			counts.seen = counts.seen + 1
			if info.fullName:find("-", 1, true) then
				counts.connectedRealm = counts.connectedRealm + 1
			end
			--[[
				Discarded for an unreadable class token, without which there is no way to tell
				whether they can wear the item, or for a faction mail cannot reach.
			]]
			local token = info.filename or classTokenByName[info.classStr]
			if otherFaction(info.raceStr) then
				counts.otherFaction = counts.otherFaction + 1
			elseif token then
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
	return list, raw, total
end

--[[
	SetWhoToUi(true) routes results to the list GetWhoInfo reads; false prints them to chat, where
	there is nothing to read. Restored to false so a /who the player types behaves as expected.

	THE WHO PANEL MUST NEVER LEARN A QUERY ANSWERED. The stock UI opens it on WHO_LIST_UPDATE
	whenever results were routed to the list -- and the panel is a UIPanel, so opening it over an
	open mailbox makes the panel manager close MailFrame, whose OnHide ends the mailbox
	interaction. So the Blizzard frames that would react are unregistered for exactly the life of
	one query and put back on the way out. The hide below is only a safety net for a client that
	routes the event some other way: by the time it fires the mailbox is already gone.
]]
local panelWasOpen = false
local deafened = {}

local function whoPanel()
	return FriendsFrame
end

local function beginQuery()
	panelWasOpen = whoPanel() ~= nil and whoPanel():IsShown()
	for _, frame in ipairs({ FriendsFrame, WhoFrame }) do
		if frame and frame.IsEventRegistered and frame:IsEventRegistered("WHO_LIST_UPDATE") then
			pcall(frame.UnregisterEvent, frame, "WHO_LIST_UPDATE")
			deafened[#deafened + 1] = frame
		end
	end
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, true)
	end
end

local function endQuery()
	-- Exactly the frames deafened above, so a frame that never listened is never registered.
	for index = #deafened, 1, -1 do
		pcall(deafened[index].RegisterEvent, deafened[index], "WHO_LIST_UPDATE")
		deafened[index] = nil
	end
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, false)
	end
	local panel = whoPanel()
	if SUPPRESS_WHO_UI and panel and panel:IsShown() and not panelWasOpen then
		pcall(HideUIPanel, panel)
	end
end

-- A capped answer is counted, never split and requeued.
local function OnWhoListUpdate()
	if not pending then
		return
	end
	local job = pending
	pending = nil

	--[[
		Read before restoring, then close the window this add-on caused to open.

		THE RESTORE RUNS WHETHER OR NOT THE READ SUCCEEDED, which is why the read is guarded. By
		here `pending` is already nil, so Who:Step's timeout will not fire either: a throw inside
		parseResults would leave SetWhoToUi routed at a list nothing reads and WHO_LIST_UPDATE
		still unregistered from the Blizzard frames, and the player's own /who would answer with
		silence until they reloaded. endQuery is the only path back.
	]]
	local ok, results, raw, total = pcall(parseResults)
	endQuery()
	if not ok then
		-- An unreadable answer is an empty one: the plan moves on rather than stalling on it.
		results, raw = {}, 0
	end

	local capped = raw >= WHO_RESULT_CAP or (total ~= nil and total > raw)
	if capped then
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

	--[[
		Everybody the server had for this question arrived, so whatever else the plan meant to
		ask inside it is already answered. Not on an unreadable answer: empty there means unknown.
	]]
	if ok and not capped then
		Who:Exhausted(job.attempt)
	end

	if job.cb then
		job.cb(results, job.label)
	end
end
ns.on("WHO_LIST_UPDATE", OnWhoListUpdate)

-- Turn a blocked call into an explanation instead of a mystery BugSack popup.
local function OnAddonActionBlocked(addon, func)
	if addon ~= ns.name then
		return
	end
	if func and func:find("SendWho", 1, true) then
		counts.blocked = counts.blocked + 1
		ns:PrintMessage(L["WHO_BLOCKED"])
	end
end
ns.on("ADDON_ACTION_BLOCKED", OnAddonActionBlocked)

--[[
	Abandons what is in flight without forgetting it. The client still answers, and that answer
	runs endQuery -- the only thing that restores SetWhoToUi and re-registers the Who panel's
	WHO_LIST_UPDATE. Drop the reference and the player's own /who stays broken for the session:
	results routed to a list nothing reads, on a panel that no longer hears them. A canceled job
	answers nobody, and Who:Step will not send while one is pending.
]]
function Who:CancelPending()
	if pending then
		pending.canceled = true
	end
end

--[[
	A canceled query is not a place left to look: counting it would leave the next press of Find
	Recipients stepping an empty plan, down its mid-plan branch to a press that cannot send.
]]
function Who:Remaining()
	return #plan + ((pending and not pending.canceled) and 1 or 0)
end

--------------------------------------------------------------------------------
-- Reading the state
--------------------------------------------------------------------------------

--[[
	For the diagnostics roster report, reads only. The query still waiting on the server, or nil:
	its label, whether it was canceled, and how long ago it went out.
]]
function Who:InFlight()
	if not pending then
		return nil
	end
	return pending.label, pending.canceled == true, GetTime() - lastSent
end

-- Seconds until the throttle lets the next query out, never below zero.
function Who:ThrottleLeft()
	return math.max(0, WHO_THROTTLE - (GetTime() - lastSent))
end

--[[
	How many Blizzard frames are deaf to WHO_LIST_UPDATE right now. Nonzero with nothing in flight
	means a query's restore never ran, and the player's own /who answers with silence.
]]
function Who:QuietedFrames()
	return #deafened
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
		answer that is not coming. The band goes back on the front of the plan, or it is lost for
		good and Remaining counts down as though it had succeeded. An empty answer is not
		requeued.
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
		counts.timedOut = counts.timedOut + 1
		table.insert(plan, 1, job.attempt)
		if job.cb then
			job.cb(nil, job.label)
		end -- nil results = no answer
	end)

	return true, job.label
end

-- Drops the plan. A query in flight is canceled, not forgotten -- see Who:CancelPending above.
function Who:Clear()
	wipe(plan)
	Who:CancelPending()
end
