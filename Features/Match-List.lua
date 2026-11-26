local _, ns = ...

ns.MatchList = {}
local MatchList = ns.MatchList

local items = {} -- current scan, decorated with .verdict/.state/.score/.bandLo/.bandHi/.recipient/.send/.pinned
local assignedTo = {} -- recipient name -> the item they're currently holding
-- Decisions survive a rescan by slot; an item that moved loses its pairing on purpose (the send would refuse it).
local function SlotKey(item)
	return item.uid or ("%d:%d:%s"):format(item.bag or -1, item.slot or -1, item.link or "")
end

local bagsDirty = true

-- One loot fires several BAG_UPDATEs.
local SCAN_DEBOUNCE = 2

local scanTimer
local EnsureScan -- defined below, once RescanBags exists

local function WindowIsShown()
	return ns.UI and ns.UI.frame and ns.UI.frame:IsShown()
end

--[[
	Not mid-mail-run: sent slots stay full until each send is confirmed. One function, because the
	diagnostics event log classifies both bag events with it.
]]
local function WouldRescan()
	return (ns.db and not ns.Distributor.busy and WindowIsShown()) and true or false
end

local function ScanSoon()
	bagsDirty = true
	if not WouldRescan() then
		return
	end
	if scanTimer then
		scanTimer:Cancel()
	end
	scanTimer = C_Timer.NewTimer(SCAN_DEBOUNCE, function()
		scanTimer = nil
		--[[
			Asked again: the window can close or a run start inside the debounce. The plan is left
			alone, or a bag change would throw away a Rescan for Better Match mid-run.
		]]
		if WouldRescan() then
			EnsureScan()
			ns.UI:Assign()
		end
	end)
end

local function OnBagUpdate()
	ScanSoon()
end
ns.On("BAG_UPDATE", OnBagUpdate)

-- Only an item the scan rejected as NOT_CACHED: the event fires for every item the client loads.
local function ItemInfoMatters(itemID, success)
	return success ~= false and ns.Scanner:IsPending(itemID)
end

local function OnGetItemInfoReceived(itemID, success)
	if ItemInfoMatters(itemID, success) then
		ScanSoon()
	end
end
ns.On("GET_ITEM_INFO_RECEIVED", OnGetItemInfoReceived)

local function RescanBags()
	-- A pinned row with no recipient is a deliberate keep, so the pin must survive.
	local previous = {}
	for _, item in ipairs(items) do
		if item.recipient or item.pinned then
			previous[SlotKey(item)] = { recipient = item.recipient, send = item.send, pinned = item.pinned }
		end
	end

	items = ns.Scanner:Scan()
	wipe(assignedTo)

	-- Hand picks first, or an automatic row earlier in the bags takes the name from a pick further down.
	for _, item in ipairs(items) do
		local kept = previous[SlotKey(item)]
		if kept and kept.pinned and kept.recipient and not kept.recipient.alt then
			assignedTo[kept.recipient.name] = item
		end
	end

	local bands = {}
	for _, item in ipairs(items) do
		-- Computed once and cached: everything downstream reads this verdict, never a new one.
		local verdict = ns.Matcher:Verdict(item)
		item.verdict, item.state = verdict, verdict.state
		item.best, item.score, item.eligible = verdict.best, verdict.score, verdict.eligible
		local eligible = verdict.eligible
		-- Displayed, never searched: the groups below keep a hunter's mail query off the paladin's band.
		local reachable = (#verdict.admitted > 0) and verdict.admitted or eligible
		item.bandLo, item.bandHi = ns.Matcher:SearchBand(item, reachable)

		-- The untick always survives; a ticked row that loses its name unpins, or it sits pinned to nobody.
		local kept = previous[SlotKey(item)]
		if kept then
			item.send, item.pinned = kept.send, kept.pinned
			local name = kept.recipient and kept.recipient.name
			local free = kept.recipient and (kept.pinned or kept.recipient.alt or not assignedTo[name])
			if free then
				item.recipient = kept.recipient
				if not kept.recipient.alt then
					assignedTo[name] = assignedTo[name] or item
				end
			else
				item.recipient = nil
				if item.send then
					item.pinned = false
				end
			end
		else
			item.recipient, item.send = nil, true
		end

		-- Leftovers get bands too, so the dropdown has candidates for a manual override.
		if #eligible > 0 then
			for _, group in ipairs(ns.Matcher:BandGroups(item, ns.MatchSearch.BandClasses(item, verdict))) do
				bands[#bands + 1] = group
			end
		end
	end

	bagsDirty = false
	return ns.MatchSearch.MergeBands(bands)
end

-- Assigns the local declared above, which ScanSoon captured before RescanBags existed.
function EnsureScan()
	if bagsDirty then
		RescanBags()
	end
end

-- Never after a run: sent slots are not empty yet, so delivered items return. UI:AfterDelivery skips the scan.
function MatchList:RescanBags()
	return RescanBags()
end

function MatchList:EnsureScan()
	EnsureScan()
end

-- A setting changed with no window: the scan the next mailbox would reuse was judged the old way.
function MatchList:MarkStale()
	bagsDirty = true
end

-- Whether the next mailbox rescans the bags, for the Mailbox report. Reads the flag only.
function MatchList:IsStale()
	return bagsDirty
end

-- Whether a bag event right now would arm a rescan. Read by the event log filter.
function MatchList:WouldRescan()
	return WouldRescan()
end

-- The same for one GET_ITEM_INFO_RECEIVED firing: its item is one the scan waits on.
function MatchList:WouldRescanItem(itemID, success)
	return ItemInfoMatters(itemID, success) and WouldRescan()
end

function MatchList:SlotKey(item)
	return SlotKey(item)
end

-- The row under this slot key and its index, or nil once it has left the list.
function MatchList:FindByKey(key)
	for index, item in ipairs(items) do
		if SlotKey(item) == key then
			return item, index
		end
	end
	return nil
end

local function KeepPinnedOnly(resetSend)
	wipe(assignedTo)
	for _, item in ipairs(items) do
		if item.pinned then
			if item.recipient and not item.recipient.alt then
				assignedTo[item.recipient.name] = item
			end
		else
			item.recipient = nil
			if resetSend then
				item.send = true
			end
		end
	end
end

function MatchList:Assign()
	--[[
		Every pass decides again from scratch: filling only gaps strands soft rules (an "of the Owl"
		staff handed to a hunter never reaches the priest a later press finds). Pins are kept.
	]]
	KeepPinnedOnly(true)

	-- Leftovers too, or a row showing candidates but holding none reads as broken. Ranked once, here.
	local order = {}
	for _, item in ipairs(items) do
		if not item.pinned then
			order[#order + 1] = { item = item, ranked = self:Candidates(item) }
		end
	end

	--[[
		Scarcest first: with one item per person, an item two can receive picks before one fifty
		can, or the fifty-candidate item may take one of the two. Zero candidates sorts last.
	]]
	table.sort(order, function(a, b)
		local countA, countB = #a.ranked, #b.ranked
		if (countA == 0) ~= (countB == 0) then
			return countB == 0
		end
		if countA ~= countB then
			return countA < countB
		end
		return (a.item.score or 0) > (b.item.score or 0)
	end)

	local function IsTaken(person)
		return not person.alt and assignedTo[person.name] ~= nil
	end

	for _, entry in ipairs(order) do
		local pick = ns.Fairness:PickFrom(entry.ranked, IsTaken)
		if pick then
			-- Arrives ticked, fallback included; unpinned, so a contender found later takes it over.
			entry.item.recipient, entry.item.send = pick, true
			if not pick.alt then
				assignedTo[pick.name] = entry.item
			end
		end
	end

	-- Last and unpinned, so it only takes what nobody else could, and a later gift takes it back.
	local enchanter = ns.db and ns.db.profile.disenchantUnmatched and ns.Alts:DisenchantRecipient()
	if enchanter then
		for _, item in ipairs(items) do
			if not item.pinned and not item.recipient and self:Disenchantable(item) then
				item.recipient, item.send = enchanter, true
			end
		end
	end

	--[[
		Satisfied bands are pruned, since each still costs a press. A targeted search is pressed when a
		contender already holds the row, so it narrows against that holder instead of ending at once.
	]]
	if ns.Who.targeted then
		ns.MatchSearch.NarrowTargeted()
	elseif ns.MatchSearch.SearchingGifts() == 0 then
		ns.Who:Clear()
	else
		ns.Who:Prune(ns.MatchSearch.SearchingBands())
	end
end

--------------------------------------------------------------------------------
-- Reading the state
--------------------------------------------------------------------------------

-- RescanBags reassigns items, so never cache this; assignedTo is only wiped in place.
function MatchList:Items()
	return items
end

function MatchList:AssignedTo()
	return assignedTo
end

--[[
	Leftover gear only: a Pending Match row may still fill, an unreadable one may suit somebody once
	read. All scanned gear is green or better, so it disenchants.
]]
function MatchList:Disenchantable(item)
	return item.kind == "gear" and item.state == ns.Matcher.LEFTOVER
end

-- On close, so the next open matches against the whole roster found since; pins and pool survive.
function MatchList:ReleaseAutomatic()
	KeepPinnedOnly(false)
end
