local _, ns = ...

--[[
	What is in the bags, who is on the roster, and which of them holds what;
	Features/Mail-Window.lua draws it. items, pools and assignedTo are file-scope and nothing
	wipes them on a window close, which is what makes matches survive walking away from a mailbox.
]]

ns.MatchList = {}
local MatchList = ns.MatchList

local pools = {} -- classToken -> { {name, level, class, area}, ... } from /who
local items = {} -- current scan, decorated with .best/.eligible/.band/.recipient
local assignedTo = {} -- recipient name -> the item they're currently holding
local seenPlayer = {} -- name -> true, dedupes across query chunks
--[[
	Session total for the roster report, never reset by ClearPools: the report explains what a
	search found, and who was too low is part of that whether or not the pools were since emptied.
]]
local tooLow = 0

--[[
	Bumped whenever the pools change, which is what makes the candidate cache below safe to hand
	out. A counter rather than a walk of every item: one increment per query, where clearing a
	field per item costs the scan it was meant to save. rescanBags deliberately has no bump -- it
	replaces every item table outright, so no cache survives it anyway.
]]
local poolsGeneration = 0

--[[
	A re-scan rebuilds items from the bags, so decisions are remembered against the slot they were
	made for; otherwise every press of Find Recipients reshuffles pairings already reviewed.
	Anything that moved slots loses its pairing deliberately -- the Distributor would refuse to
	send it. Read off the record rather than rebuilt, so the uid format has one home.
]]
local function slotKey(item)
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
local ensureScan -- defined below, once rescanBags exists

local function windowIsShown()
	return ns.UI and ns.UI.frame and ns.UI.frame:IsShown()
end

local function scanSoon()
	bagsDirty = true
	--[[
		Nothing to scan against before the saved variables exist, and nothing worth scanning
		mid-mail-run: the Distributor's slots stay full until each send is confirmed, and the
		BAG_UPDATE the deliveries raise brings the scan back round anyway. The dirty flag makes
		skipping a closed window safe -- nothing reads the answer away from a mailbox, so the next
		mailboxOpened pays for one scan. Tested here and not only in the timer: BAG_UPDATE and
		GET_ITEM_INFO_RECEIVED are the noisy events, and arming a timer that will find the window
		closed is work for nothing on nearly every one.
	]]
	if not ns.db or ns.Distributor.busy or not windowIsShown() then
		return
	end
	if scanTimer then
		scanTimer:Cancel()
	end
	scanTimer = C_Timer.NewTimer(SCAN_DEBOUNCE, function()
		scanTimer = nil
		--[[
			Asked again: the window can be closed inside the debounce. Never opens it either -- a
			panel appearing because the player looted a green is the add-on talking over the game.
		]]
		if windowIsShown() then
			ensureScan()
			ns.UI:Refresh()
		end
	end)
end

ns.on("BAG_UPDATE", scanSoon)

--[[
	An unresolved item is rejected as NOT_CACHED, so a cold-cache scan reports a bag emptier than
	it is -- and that decides whether the window opens at all.
]]
ns.on("GET_ITEM_INFO_RECEIVED", scanSoon)

--[[
	Clusters, not one span: bags routinely hold low-level gear and high-level consumables and
	nothing between, and one span queries the empty middle while the bands that matter come back a
	thin sample against the /who cap.

	Merging unions the class sets as well as the level spans -- two items sharing a band are one
	query, which has to ask for everybody either of them can go to. Shared by the scan bands and
	the unmatched bands below, so Who:Prune matches attempts against bands built the same way.
]]
local function mergeBands(bands)
	table.sort(bands, function(a, b)
		return a.lo < b.lo
	end)

	local merged = {}
	for _, band in ipairs(bands) do
		local last = merged[#merged]
		if last and band.lo <= last.hi + 1 then
			last.hi = math.max(last.hi, band.hi)
			for _, class in ipairs(band.classes or {}) do
				if not last.seen[class] then
					last.seen[class] = true
					last.classes[#last.classes + 1] = class
				end
			end
		else
			local seen, classes = {}, {}
			for _, class in ipairs(band.classes or {}) do
				if not seen[class] then
					seen[class] = true
					classes[#classes + 1] = class
				end
			end
			merged[#merged + 1] = { lo = band.lo, hi = band.hi, classes = classes, seen = seen }
		end
	end
	return merged
end

local function rescanBags()
	--[[
		Carried across the rescan: the pairing, the tick, and whether the player set them. A
		pinned row with no recipient is a deliberate vendor, so the pin is what must survive.
	]]
	local previous = {}
	for _, item in ipairs(items) do
		if item.recipient or item.pinned then
			previous[slotKey(item)] = { recipient = item.recipient, send = item.send, pinned = item.pinned }
		end
	end

	items = ns.Scanner:Scan()
	wipe(assignedTo)

	local bands = {}
	for _, item in ipairs(items) do
		-- Computed once and cached: everything downstream reads this verdict, never a new one.
		local verdict = ns.Matcher:Verdict(item)
		local bandLo, bandHi = ns.Matcher:LevelBand(item)
		item.verdict, item.state = verdict, verdict.state
		item.best, item.score, item.eligible = verdict.best, verdict.score, verdict.eligible
		item.bandLo, item.bandHi = bandLo, bandHi
		local eligible = verdict.eligible

		local kept = previous[slotKey(item)]
		local taken = kept and kept.recipient and assignedTo[kept.recipient.name]
		if kept and not taken then
			item.recipient, item.send, item.pinned = kept.recipient, kept.send, kept.pinned
			if kept.recipient then
				assignedTo[kept.recipient.name] = item
			end
		else
			item.recipient, item.send = nil, false
		end

		--[[
			Leftovers count toward the band too: the dropdown needs candidates behind them for a
			manual override. Classes travel with the band because Who:Plan filters on them --
			admitted, or eligible when nothing was admitted, since narrowing on an empty set asks
			for no classes at all.
		]]
		if #eligible > 0 then
			bands[#bands + 1] = {
				lo = bandLo,
				hi = bandHi,
				classes = (#verdict.admitted > 0) and verdict.admitted or eligible,
			}
		end
	end

	bagsDirty = false
	return mergeBands(bands)
end

--[[
	Run only if the bags have moved; bagsDirty starts true so the first mailbox always scans.
	Assigned rather than declared, because scanSoon schedules this before rescanBags exists.
]]
function ensureScan()
	if bagsDirty then
		rescanBags()
	end
end

--[[
	Gifts still looking for somebody: the only thing deciding whether another press is worth it.
	Leftovers and unreadables are excluded, or Scan Again stays offered for the whole session.
]]
local function unmatchedGifts()
	local waiting = 0
	for _, item in ipairs(items) do
		if item.state == ns.Matcher.GIFT and not item.recipient then
			waiting = waiting + 1
		end
	end
	return waiting
end

--[[
	The bands a search still has something to find for. Leftovers are left out here, where the
	scan bands keep them: the plan is dropped whole the moment no gift is unmatched, so a band
	held open for a leftover would spend presses on a row the search was never going to finish.
	Reads the verdict rescanBags cached rather than asking the matcher again -- a second opinion
	here could prune a band the list still shows as waiting.
]]
local function unmatchedBands()
	local bands = {}
	for _, item in ipairs(items) do
		if item.state == ns.Matcher.GIFT and not item.recipient then
			local verdict = item.verdict
			local eligible = (verdict and verdict.eligible) or {}
			if #eligible > 0 then
				bands[#bands + 1] = {
					lo = item.bandLo,
					hi = item.bandHi,
					classes = (#verdict.admitted > 0) and verdict.admitted or eligible,
				}
			end
		end
	end
	return mergeBands(bands)
end

--[[
	For a setting that changes what counts as giftable. Never after a distribution run: the client
	has not finished emptying the sent slots, so this would find delivered items still in the bags
	and put them back on the list. UI:_afterDelivery is that path, and it does not scan.
]]
function MatchList:RescanBags()
	return rescanBags()
end

function MatchList:EnsureScan()
	ensureScan()
end

function MatchList:UnmatchedGifts()
	return unmatchedGifts()
end

function MatchList:SlotKey(item)
	return slotKey(item)
end

-- Assigns each item a recipient, one item per person per pass.
function MatchList:Assign()
	--[[
		EVERY PASS DECIDES AGAIN, from scratch, against the whole roster. Filling only the gaps is
		wrong as soon as a rule is soft: an "of the Owl" staff falls back to a hunter, so a press
		that finds only a hunter hands him the staff and a later press finding a priest never
		looks at it again.

		What survives is what the player decided: a pinned row is one they touched, and rebuilding
		over those is the one thing a rebuild must not do.
	]]
	wipe(assignedTo)
	for _, item in ipairs(items) do
		if item.pinned then
			if item.recipient then
				assignedTo[item.recipient.name] = item
			end
		else
			item.recipient, item.send = nil, false
		end
	end

	--[[
		Every item, not just the ones that scored: a leftover showing candidates but holding no
		assignment reads as broken. Ranked once here, or the sort calls RankCandidates O(n log
		n) times for an answer that cannot change; who is still free does move, hence isTaken.
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

	local function isTaken(person)
		return assignedTo[person.name] ~= nil
	end

	for _, entry in ipairs(order) do
		local pick = ns.Fairness:PickFrom(entry.ranked, isTaken)
		if pick then
			entry.item.recipient, entry.item.send = pick, true
			assignedTo[pick.name] = entry.item
		end
	end

	--[[
		The search is over the moment every gift has somebody; a plan left standing is a countdown
		over finished work. Short of that, the finished parts of it still are: attempts interleave
		one per band, so a filled band keeps taking a turn that costs a click and the full
		throttle to ask a question nothing is waiting on.
	]]
	if unmatchedGifts() == 0 then
		ns.Who:Clear()
	else
		ns.Who:Prune(unmatchedBands())
	end
end

--------------------------------------------------------------------------------
-- Reading the state
--------------------------------------------------------------------------------

--[[
	items is REASSIGNED by rescanBags, so a caller holding the table would keep rendering the
	pre-scan list. pools and assignedTo are only ever wiped in place, so handing those out is
	safe.
]]
function MatchList:Items()
	return items
end

function MatchList:Pools()
	return pools
end

function MatchList:AssignedTo()
	return assignedTo
end

--[[
	RankCandidates sorts every admitted class against every pooled player, and the same answer is
	asked for repeatedly -- once per Assign, once per dropdown open, and once per mouse-over of a
	recipient button, which has no ceiling. Its inputs are the pools and the item's own verdict
	and band: it never reads item.recipient, so an assignment does not invalidate a cached answer.

	HANDED OUT BY REFERENCE, NEVER COPIED. Every caller only reads it, and one that sorted or
	removed in place would poison the cache for everybody after it.
]]
function MatchList:Candidates(item)
	if item._candidates and item._candidatesGeneration == poolsGeneration then
		return item._candidates
	end
	local ranked = ns.Matcher:RankCandidates(item, pools)
	item._candidates, item._candidatesGeneration = ranked, poolsGeneration
	return ranked
end

--[[
	Folds one query's results into the roster, deduped. The shuffle key is rolled once as a player
	enters the pool, so the order among equals holds still instead of moving between renders.
]]
function MatchList:AddResults(results)
	local added = 0
	for _, p in ipairs(results) do
		--[[
			THE ONE LEVEL FLOOR, here rather than in either reader because this is the single door
			every recipient comes through: /who and the guild roster both arrive at this line, and
			a source added later inherits it without having to remember to. Counted before the
			dedupe, so the number means "people this rule turned away", not "people it turned away
			who were also new".
		]]
		if (p.level or 0) < ns.Data.MIN_RECIPIENT_LEVEL then
			tooLow = tooLow + 1
		elseif not seenPlayer[p.name] then
			seenPlayer[p.name] = true
			p.shuffle = math.random()
			pools[p.class] = pools[p.class] or {}
			table.insert(pools[p.class], p)
			added = added + 1
		end
	end
	--[[
		Only when somebody actually entered a pool: a query returning nothing new leaves the
		ranking unchanged, and bumping would throw the cache away once per press for an answer
		that could not have moved -- the common case, since the guild roster re-answers in full
		every time.
	]]
	if added > 0 then
		poolsGeneration = poolsGeneration + 1
	end
	return added
end

-- How many candidates the level floor turned away this session, for the roster report.
function MatchList:TooLowCount()
	return tooLow
end

-- Empties the roster. The Diagnostic Tools Clear History and Roster button is the caller.
function MatchList:ClearPools()
	wipe(pools)
	wipe(seenPlayer)
	poolsGeneration = poolsGeneration + 1
end
