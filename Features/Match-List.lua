local _, ns = ...

--[[
	What is in the bags and which roster player holds what; Features/UI-Window.lua draws it. The
	roster is Features/Match-Roster.lua's, and the search bands Features/Match-Search.lua's. items
	and assignedTo are file-scope and nothing wipes the items or the hand picks on a window close.
	The automatic pairings are released on close and come back only on Find Recipients.
]]

ns.MatchList = {}
local MatchList = ns.MatchList

local items = {} -- current scan, decorated with .verdict/.state/.score/.bandLo/.bandHi/.recipient/.send/.pinned
local assignedTo = {} -- recipient name -> the item they're currently holding
--[[
	A re-scan rebuilds items from the bags, so decisions are remembered against the slot they were
	made for; otherwise every press of Find Recipients reshuffles pairings already reviewed.
	Anything that moved slots loses its pairing deliberately -- the Distributor would refuse to
	send it. Read off the record's uid; the fallback builds the same shape for a record made
	without one.
]]
local function SlotKey(item)
	return item.uid or ("%d:%d:%s"):format(item.bag or -1, item.slot or -1, item.link or "")
end

--[[
	BAG_UPDATE fires on every loot, sale and stack merge, so it only sets a flag and the scan
	waits until something needs the answer. It also makes a second mailboxOpened free, which
	matters because MAIL_SHOW and MailFrame's OnShow both fire for one mailbox.
]]
local bagsDirty = true

-- How long the bags must stop moving before a scan: one loot fires several BAG_UPDATEs.
local SCAN_DEBOUNCE = 2

local scanTimer
local EnsureScan -- defined below, once RescanBags exists

local function WindowIsShown()
	return ns.UI and ns.UI.frame and ns.UI.frame:IsShown()
end

--[[
	Nothing to scan against before the saved variables exist, and nothing worth scanning
	mid-mail-run: the Distributor's slots stay full until each send is confirmed, and the
	BAG_UPDATE the deliveries raise brings the scan back round anyway. The dirty flag makes
	skipping a closed window safe -- nothing reads the answer away from a mailbox, so the next
	mailboxOpened pays for one scan. Tested in ScanSoon and not only in the timer: BAG_UPDATE and
	GET_ITEM_INFO_RECEIVED are the noisy events, and arming a timer that will find the window
	closed is work for nothing on nearly every one.

	One function, because the diagnostics event log classifies both events with it: a firing
	this answers true for is one that armed a rescan, and the log keeps it in full.

	A mailbox that opened on nothing to give counts as well as a shown window. That answer is
	often the cold cache's -- the first visit after login reads half the bag as NOT_CACHED --
	and making the player walk away and back to find out otherwise is the delay this closes.
]]
local function WaitingToOpen()
	return ns.UI and ns.UI:WaitingToOpen()
end

local function WouldRescan()
	return (ns.db and not ns.Distributor.busy and (WindowIsShown() or WaitingToOpen())) and true or false
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
			The whole test is asked again: the window can close and a mail run can start inside
			the debounce. Opens the window only for a mailbox still waiting on it -- away from
			one, a panel appearing because the player looted a green is the add-on talking over
			the game.

			An open window is re-matched from the pools already found, since the rescan brings a
			new row in with nobody on it. The search plan is left alone: re-planning on every bag
			change would throw away a Find Recipients for This Item search mid-run, and the next
			Find Recipients press picks up a new item's band anyway.
		]]
		if WouldRescan() then
			EnsureScan()
			if WindowIsShown() then
				ns.UI:Assign()
			else
				ns.UI:OpenIfWaiting()
			end
		end
	end)
end

local function OnBagUpdate()
	ScanSoon()
end
ns.On("BAG_UPDATE", OnBagUpdate)

--[[
	An unresolved item is rejected as NOT_CACHED, so a cold-cache scan reports a bag emptier than
	it is -- and that decides whether the window opens at all. Only an item the scan is waiting on
	counts: the event fires for every item the client loads, mail, chat links and other add-ons
	included, and each of those would otherwise re-read the whole bag.
]]
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
	--[[
		Carried across the rescan: the pairing, the tick, and whether the player set them. A
		pinned row with no recipient is a deliberate keep, so the pin is what must survive.
	]]
	local previous = {}
	for _, item in ipairs(items) do
		if item.recipient or item.pinned then
			previous[SlotKey(item)] = { recipient = item.recipient, send = item.send, pinned = item.pinned }
		end
	end

	items = ns.Scanner:Scan()
	wipe(assignedTo)

	--[[
		THE PLAYER'S PICKS FIRST, and they always survive, even two rows set to one name by hand.
		Only then do the automatic pairings come back, each one only if nobody holds its name:
		read in bag order alone, an automatic row early in the bags would take the name and drop
		the pick the player made further down.
	]]
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
		--[[
			The span across everybody who could receive it, which is the item's own band unless a
			class has to train the armor material first. Displayed, never searched: the groups
			below carry a band apiece so a hunter's mail query is not widened to the paladin's.
		]]
		local reachable = (#verdict.admitted > 0) and verdict.admitted or eligible
		item.bandLo, item.bandHi = ns.Matcher:SearchBand(item, reachable)

		--[[
			THE UNTICK ALWAYS SURVIVES. Only a recipient another row already holds is dropped, and
			a row still ticked that loses its name goes back to auto-assignment, or it would sit
			pinned to nobody. A row with nothing remembered starts ticked, like every row.
		]]
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

		--[[
			Leftovers count toward the band too: the dropdown needs candidates behind them for a
			manual override. Classes travel with the band because Who:Plan filters on them; a
			kept fallback pairing narrows its band to the contenders, same as the prune path.
		]]
		if #eligible > 0 then
			for _, group in ipairs(ns.Matcher:BandGroups(item, ns.MatchSearch.BandClasses(item, verdict))) do
				bands[#bands + 1] = group
			end
		end
	end

	bagsDirty = false
	return ns.MatchSearch.MergeBands(bands)
end

--[[
	Run only if the bags have moved; bagsDirty starts true so the first mailbox always scans.
	Assigned rather than declared, because ScanSoon schedules this before RescanBags exists.
]]
function EnsureScan()
	if bagsDirty then
		RescanBags()
	end
end

--[[
	For a setting that changes what counts as giftable. Never after a distribution run: the client
	has not finished emptying the sent slots, so this would find delivered items still in the bags
	and put them back on the list. UI:AfterDelivery is that path, and it does not scan.
]]
function MatchList:RescanBags()
	return RescanBags()
end

function MatchList:EnsureScan()
	EnsureScan()
end

--[[
	For a setting changed while no window is built to re-read into. The scan the next mailbox
	would otherwise reuse was judged under the old setting, so a switch to All Consumables at
	a bag that has not moved since opened nothing.
]]
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

--[[
	Every automatic pairing let go, and only the player's picks held: a pinned row keeps its name,
	every other row loses it. resetSend also ticks every unpinned row again, as a fresh pass does.
]]
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

--[[
	Assigns each item a recipient, one item per person per pass. Two are exempt: your own alts,
	who can take every item that suits them, and the player's own picks, which always stand.
]]
function MatchList:Assign()
	--[[
		EVERY PASS DECIDES AGAIN, from scratch, against the whole roster. Filling only the gaps is
		wrong as soon as a rule is soft: an "of the Owl" staff falls back to a hunter, so a press
		that finds only a hunter hands him the staff and a later press finding a priest never
		looks at it again.

		What survives is what the player decided: a pinned row is one they touched, and rebuilding
		over those is the one thing a rebuild must not do.
	]]
	KeepPinnedOnly(true)

	--[[
		Every item, not just the ones that scored: a leftover showing candidates but holding no
		assignment reads as broken. Ranked once here, or the sort calls RankCandidates O(n log
		n) times for an answer that cannot change; who is still free does move, hence IsTaken.
	]]
	local order = {}
	for _, item in ipairs(items) do
		if not item.pinned then
			order[#order + 1] = { item = item, ranked = self:Candidates(item) }
		end
	end

	--[[
		SCARCEST FIRST, AND ONLY THEN BEST FIRST. One item per person per pass makes this an
		allocation problem, not a ranking one: an item two people can receive must pick before one
		fifty can, or the fifty-candidate item takes one of the two and the other gets nobody
		where the other order places both. A shield is the worst case, admitting two classes on
		Era where a cloak admits eight. Score breaks ties; an item nobody can receive sorts last,
		since zero is the impossible case, not the scarcest.
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
			--[[
				EVERY ROW IS TICKED UNTIL THE PLAYER SAYS OTHERWISE, so a match arrives ticked, a
				fallback included. A fallback is still not final -- the row stays unpinned and its
				band stays on the plan, so a contender turning up on a later press takes it over.
				Unticking is the player's veto, and pins it.
			]]
			entry.item.recipient, entry.item.send = pick, true
			if not pick.alt then
				assignedTo[pick.name] = entry.item
			end
		end
	end

	--[[
		Last, so it only ever takes what nobody else could: gear still unpaired after every player
		found had their turn. Unpinned like any automatic pairing, so a Keep Item stands and a rule
		change that turns a Kept row into a gift takes it back.
	]]
	local enchanter = ns.db and ns.db.profile.disenchantUnmatched and ns.Alts:DisenchantRecipient()
	if enchanter then
		for _, item in ipairs(items) do
			if not item.pinned and not item.recipient and self:Disenchantable(item) then
				item.recipient, item.send = enchanter, true
			end
		end
	end

	--[[
		The search is over the moment every gift has somebody in contention -- a fallback pairing
		keeps its band alive, narrowed to the classes the verdict named. Short of over, the
		finished parts of the plan still end: attempts interleave one per band, so a satisfied
		band keeps taking a turn that costs a click and the full throttle to ask a question
		nothing is waiting on.
	]]
	--[[
		A targeted search is the exception: it is pressed exactly when somebody in contention
		already holds the row and is not good enough, so that rule would end it after one press.
		It is narrowed against its one row's holder instead, and the bands below never touch it.
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

--[[
	items is REASSIGNED by RescanBags, so a caller holding the table would keep rendering the
	pre-scan list. assignedTo is only ever wiped in place, so handing it out is safe.
]]
function MatchList:Items()
	return items
end

function MatchList:AssignedTo()
	return assignedTo
end

--[[
	A Kept row Disenchant Unmatched Items may send off: gear, since every weapon and armor piece the
	scan admits is green or better and so disenchants, and nothing a consumable turns into. Never
	a Pending Match row, which a later search may still fill, nor an unreadable one, which may yet
	suit somebody once its stats read.
]]
function MatchList:Disenchantable(item)
	return item.kind == "gear" and item.state == ns.Matcher.LEFTOVER
end

--[[
	Every name the allocator chose, let go, for the window closing: the next open matches again
	from the whole roster found this session rather than showing pairings made against an older
	one. A row the player set by hand keeps its name, and nothing found is forgotten.
]]
function MatchList:ReleaseAutomatic()
	KeepPinnedOnly(false)
end
