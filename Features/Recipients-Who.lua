local _, ns = ...
local L = ns.L

-- Sends what Features/Recipients-Who-Plan.lua plans; the plan and the session totals are its tables.
local Who = ns.Who
local plan, counts = Who.plan, Who.counts

--------------------------------------------------------------------------------
-- Class Names
--------------------------------------------------------------------------------

-- A result's localized class name back to its token, either gender.
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
	Mail does not cross factions, and /who on Forever answers with both (Era and TBC answer
	same-faction). A race this client cannot place, unknown or shared by two factions, is KEPT: a
	wrong drop loses a recipient for good, where a wrong keep costs one refused send.
]]
local factionByRace

local function RaceFactions()
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

local function OtherFaction(raceName)
	local mine = UnitFactionGroup("player")
	if not (mine == "Alliance" or mine == "Horde") or not raceName then
		return false
	end
	local theirs = RaceFactions()[raceName]
	return theirs and theirs ~= mine or false
end

--------------------------------------------------------------------------------
-- Querying
--------------------------------------------------------------------------------

-- The server sends at most this many results and says nothing about the rest.
local WHO_RESULT_CAP = 50

-- Exposed so the roster report names the same number this file tests against.
Who.RESULT_CAP = WHO_RESULT_CAP

local RESULT_TIMEOUT = 6 -- give up on a query that never answers (i.e. was blocked)

--[[
	Neither is a setting. The server rate-limits /who on its own, so a lower throttle only turns a
	press into a silent no-op that reads as the add-on being broken.
]]
local SUPPRESS_WHO_UI = true
local WHO_THROTTLE = 5

-- UI-Mailbox locks its button for exactly this long; re-enabling early offers a dead press.
Who.THROTTLE = WHO_THROTTLE

local pending = nil
local lastSent = 0

function Who:ResultStats()
	return counts
end

local function ParseResults()
	local list = {}
	local guildOf = ns.Guild:WhoLookup()
	-- The second return is how many matched server-side, which is what tells a full answer apart.
	local raw, total = C_FriendList.GetNumWhoResults()
	for i = 1, raw do
		local info = C_FriendList.GetWhoInfo(i)
		if info and info.fullName then
			counts.seen = counts.seen + 1
			if info.fullName:find("-", 1, true) then
				counts.connectedRealm = counts.connectedRealm + 1
			end
			local token = info.filename or classTokenByName[info.classStr]
			-- A member unticked on My Guilds is never offered anything, even once the whole guild is unticked or removed.
			local guildmate, ignored = guildOf(info.fullGuildName, info.fullName)
			if OtherFaction(info.raceStr) then
				counts.otherFaction = counts.otherFaction + 1
			elseif ignored then
				counts.ignoredGuild = counts.ignoredGuild + 1
			elseif token then
				if guildmate then
					counts.guildmates = counts.guildmates + 1
				end
				table.insert(list, {
					name = info.fullName,
					level = info.level,
					class = token,
					area = info.area,
					guild = guildmate or nil,
					guildName = guildmate and info.fullGuildName or nil,
				})
			else
				counts.unknownClass = counts.unknownClass + 1
			end
		end
	end
	-- raw, not #list: the cap is about what the server sent, and #list misses a band truncated by an unreadable class.
	return list, raw, total
end

--[[
	SetWhoToUi(true) routes results to the list GetWhoInfo reads; restored to false so a /who the
	player types prints to chat. The stock UI opens the Who panel on WHO_LIST_UPDATE, and as a
	UIPanel it closes MailFrame, ending the mailbox interaction. So every listener is deaf for
	exactly one query; the hide in EndQuery is only a safety net, too late to save the mailbox.
]]
local panelWasOpen = false
local deafened = {}

local function WhoPanel()
	return FriendsFrame
end

--[[
	Asked of the client rather than named: Forever opened the panel with FriendsFrame and WhoFrame
	both deaf. Other add-ons' listeners are quieted too. The named pair is the fallback for a client
	without GetFramesRegisteredForEvent.
]]
local function Listeners()
	local frames
	if GetFramesRegisteredForEvent then
		frames = { GetFramesRegisteredForEvent("WHO_LIST_UPDATE") }
	else
		frames = { FriendsFrame, WhoFrame }
	end
	local list = {}
	for _, frame in ipairs(frames) do
		local forbidden = frame.IsForbidden and frame:IsForbidden()
		if frame ~= ns.eventFrame and not forbidden and frame.IsEventRegistered then
			list[#list + 1] = frame
		end
	end
	return list
end

-- For the roster report: who hears an answer right now, by name where the frame has one.
function Who:ListenerNames()
	local names = {}
	for _, frame in ipairs(Listeners()) do
		names[#names + 1] = (frame.GetName and frame:GetName()) or "(unnamed)"
	end
	return names
end

local function BeginQuery()
	panelWasOpen = WhoPanel() ~= nil and WhoPanel():IsShown()
	for _, frame in ipairs(Listeners()) do
		if frame:IsEventRegistered("WHO_LIST_UPDATE") and pcall(frame.UnregisterEvent, frame, "WHO_LIST_UPDATE") then
			deafened[#deafened + 1] = frame
		end
	end
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, true)
	end
end

local function EndQuery()
	-- Exactly the frames deafened above, so a frame that never listened is never registered.
	for index = #deafened, 1, -1 do
		pcall(deafened[index].RegisterEvent, deafened[index], "WHO_LIST_UPDATE")
		deafened[index] = nil
	end
	if C_FriendList.SetWhoToUi then
		pcall(C_FriendList.SetWhoToUi, false)
	end
	local panel = WhoPanel()
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
		Guarded because EndQuery must run either way: pending is already nil, so no timeout will
		restore SetWhoToUi or the deafened frames, and the player's own /who would stay silent.
	]]
	local ok, results, raw, total = pcall(ParseResults)
	EndQuery()
	if not ok then
		-- An unreadable answer is an empty one: the plan moves on rather than stalling on it.
		results, raw = {}, 0
	end

	local capped = raw >= WHO_RESULT_CAP or (total ~= nil and total > raw)
	if capped then
		counts.capped = counts.capped + 1
	end

	-- Canceled: read this far only for EndQuery; a callback would assign recipients in a window already closed.
	if job.canceled then
		return
	end

	-- Not on an unreadable answer: empty there means unknown.
	if ok and not capped then
		Who:Exhausted(job.attempt)
	end

	if job.cb then
		job.cb(results, job.label)
	end
end
ns.On("WHO_LIST_UPDATE", OnWhoListUpdate)

-- Counts, never acts: by OnShow the panel manager has already closed MailFrame. Evidence for the roster report.
local function OnPlayerLogin()
	local panel = WhoPanel()
	if not (panel and panel.HookScript) then
		return
	end
	panel:HookScript("OnShow", function()
		if pending and not panelWasOpen then
			counts.panelOpened = counts.panelOpened + 1
		end
	end)
end
ns.On("PLAYER_LOGIN", OnPlayerLogin)

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
ns.On("ADDON_ACTION_BLOCKED", OnAddonActionBlocked)

--[[
	Marks, never drops: the answer still has to run EndQuery, or the player's own /who stays
	silent for the session. Who:Step will not send while one is pending.
]]
function Who:CancelPending()
	if pending then
		pending.canceled = true
	end
end

-- A canceled query is not a place left to look: counting it sends the next press down a branch that cannot send.
function Who:Remaining()
	return #plan + ((pending and not pending.canceled) and 1 or 0)
end

--------------------------------------------------------------------------------
-- Reading the state
--------------------------------------------------------------------------------

-- For the diagnostics roster report: the query still out, whether it was canceled, and seconds since it went.
function Who:InFlight()
	if not pending then
		return nil
	end
	return pending.label, pending.canceled == true, GetTime() - lastSent
end

function Who:ThrottleLeft()
	return math.max(0, WHO_THROTTLE - (GetTime() - lastSent))
end

-- Nonzero with nothing in flight means a query's restore never ran, and the player's own /who is silent.
function Who:QuietedFrames()
	return #deafened
end

-- Must be called from a click or keypress. Returns sent, then the attempt's label or the seconds left to wait.
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

	BeginQuery()
	C_FriendList.SendWho(attempt.query)

	-- A blocked call never answers: requeued at the front, or Remaining counts it as done.
	C_Timer.After(RESULT_TIMEOUT, function()
		if pending ~= job then
			return
		end
		pending = nil
		EndQuery()
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

-- Drops the plan. A query in flight is canceled, not forgotten (Who:CancelPending).
function Who:Clear()
	wipe(plan)
	Who.targeted = false
	Who:CancelPending()
end
