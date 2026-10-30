local _, ns = ...

--[[
	What a search is still looking for: the bands a scan or a press of Find Recipients asks /who
	about, which gifts are still searching, and the one row a targeted search is for.
	Features/Match-List.lua calls in through ns.MatchSearch.
]]

local MatchList = ns.MatchList

ns.MatchSearch = {}
local MatchSearch = ns.MatchSearch

--[[
	Clusters, not one span: bags routinely hold low-level gear and high-level consumables and
	nothing between, and one span queries the empty middle while the bands that matter come back a
	thin sample against the /who cap.

	Merging unions the class sets as well as the level spans -- two items sharing a band are one
	query, which has to ask for everybody either of them can go to. Shared by the scan bands, the
	unmatched bands below and Features/Recipients-Who-Plan.lua's spans, so Who:Prune matches
	attempts against bands built the same way.

	canJoin decides whether a band folds into the one before it: by default when it touches or
	overlaps it. With emptyMeansAnyone, a band naming no class asks for everybody, and so does
	whatever it folds into.
]]
local function AddClasses(band, classes)
	for _, class in ipairs(classes) do
		if not band.seen[class] then
			band.seen[class] = true
			band.classes[#band.classes + 1] = class
		end
	end
end

local function Touches(last, band)
	return band.lo <= last.hi + 1
end

local function MergeBands(bands, canJoin, emptyMeansAnyone)
	canJoin = canJoin or Touches
	table.sort(bands, function(a, b)
		return a.lo < b.lo
	end)

	local merged = {}
	for _, band in ipairs(bands) do
		local classes = band.classes or {}
		local anyone = emptyMeansAnyone and #classes == 0
		local last = merged[#merged]
		if last and canJoin(last, band) then
			last.hi = math.max(last.hi, band.hi)
			if last.anyone or anyone then
				last.anyone, last.classes = true, {}
			else
				AddClasses(last, classes)
			end
		else
			local new = { lo = band.lo, hi = band.hi, classes = {}, seen = {}, anyone = anyone or nil }
			if not anyone then
				AddClasses(new, classes)
			end
			merged[#merged + 1] = new
		end
	end
	return merged
end

-- Whether this class is one the verdict put in contention, not merely admitted behind them.
local function InContention(item, classToken)
	for _, class in ipairs((item.verdict and item.verdict.contenders) or {}) do
		if class == classToken then
			return true
		end
	end
	return false
end

--[[
	A gift is still worth searching for while nobody holds it -- or while only a fallback does.
	The contenders are who the verdict says the item is FOR, and a fallback pairing must not
	read as the search having found them, or the plan clears before the contenders' bands are
	asked. A pinned row is the player's
	decision, and final; an unticked row is pinned, so it is never searched for. Leftovers and
	unreadables are excluded, or the plan never empties and every press of Find Recipients goes
	on spending the /who throttle for the whole session.

	A holder standing in a capital or a dungeon counts as a fallback too (Who:KeepsSearching): the
	zones still on the plan may turn up somebody out levelling, who is who the gift is for. The
	plan running dry is what ends that search, so it costs at most the presses already planned.
]]
local function StillSearching(item)
	if item.state ~= ns.Matcher.GIFT or item.pinned then
		return false
	end
	if not item.recipient then
		return true
	end
	if ns.Who:KeepsSearching(item.recipient) then
		return true
	end
	return not InContention(item, item.recipient.class)
end

--[[
	Which classes a band should query for. A fallback-held item narrows to the contenders --
	somebody suitable already holds it, so the only find worth a press is an upgrade -- while an
	unheld one asks for everybody admitted, since there a fallback beats nobody. Admitted, or
	eligible when nothing was admitted: narrowing on an empty set asks for no classes at all.
]]
local function BandClasses(item, verdict)
	if item.recipient and not item.pinned and not InContention(item, item.recipient.class) then
		return verdict.contenders
	end
	return (#verdict.admitted > 0) and verdict.admitted or verdict.eligible
end

--[[
	The row a targeted search is looking for, by slot key: RescanBags replaces every item table,
	so a reference would go stale under it. Read only while Who.targeted says the plan is still
	that search's; a fresh plan or a Clear ends it without this having to be told.
]]
local targetKey

-- The row itself, or nil once it has left the bags.
local function TargetItem()
	if not targetKey then
		return nil
	end
	for _, item in ipairs(MatchList:Items()) do
		if MatchList:SlotKey(item) == targetKey then
			return item
		end
	end
	return nil
end

--[[
	Narrows a targeted search to the attempts that could still turn up somebody who outranks the
	row's holder, and ends it once none is left -- or at once when the row is gone or the player
	decided it by hand. An attempt with no class filter (a consumable's zones) asks for everybody,
	so it stays while any admitted class could.
]]
local function NarrowTargeted()
	local item = TargetItem()
	if not item or item.pinned then
		ns.Who:Clear()
		return
	end

	local admitted = (item.verdict and item.verdict.admitted) or {}
	ns.Who:PruneTargeted(function(attempt)
		local classes = (#attempt.classes > 0) and attempt.classes or admitted
		for _, class in ipairs(classes) do
			if ns.Matcher:CouldOutrank(item, item.recipient, class) then
				return true
			end
		end
		return false
	end)

	-- Remaining, not the plan alone: a query still in flight is answered and assigned first.
	if ns.Who:Remaining() == 0 then
		ns.Who:Clear()
	end
end

local function SearchingGifts()
	local waiting = 0
	for _, item in ipairs(MatchList:Items()) do
		if StillSearching(item) then
			waiting = waiting + 1
		end
	end
	return waiting
end

--[[
	The bands a search still has something to find for. Leftovers are left out here, where the
	scan bands keep them: the plan is dropped whole the moment no gift is searching, so a band
	held open for a leftover would spend presses on a row the search was never going to finish.
	Reads the verdict RescanBags cached rather than asking the matcher again -- a second opinion
	here could prune a band the list still shows as waiting.
]]
local function SearchingBands()
	local bands = {}
	for _, item in ipairs(MatchList:Items()) do
		if StillSearching(item) then
			local verdict = item.verdict
			local eligible = (verdict and verdict.eligible) or {}
			if #eligible > 0 then
				for _, group in ipairs(ns.Matcher:BandGroups(item, BandClasses(item, verdict))) do
					bands[#bands + 1] = group
				end
			end
		end
	end
	return MergeBands(bands)
end

-- Marks the row a targeted search is for; Assign narrows and ends that search against it.
function MatchList:Target(item)
	targetKey = item and MatchList:SlotKey(item) or nil
end

MatchSearch.MergeBands = MergeBands
MatchSearch.BandClasses = BandClasses
MatchSearch.NarrowTargeted = NarrowTargeted
MatchSearch.SearchingGifts = SearchingGifts
MatchSearch.SearchingBands = SearchingBands
