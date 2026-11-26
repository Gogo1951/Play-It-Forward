local _, ns = ...

local MatchList = ns.MatchList

ns.MatchSearch = {}
local MatchSearch = ns.MatchSearch

--[[
	Clusters, not one span, or the empty middle eats the /who cap. Shared with Recipients-Who-Plan's
	spans so Who:Prune matches attempts against bands built the same way. With emptyMeansAnyone, a
	classless band asks for everybody, and so does whatever it folds into.
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

local function InContention(item, classToken)
	for _, class in ipairs((item.verdict and item.verdict.contenders) or {}) do
		if class == classToken then
			return true
		end
	end
	return false
end

-- An alt always is: admitted by its own specs, it ranks with the contenders (CouldOutrank agrees).
local function HolderInContention(item)
	local holder = item.recipient
	return holder.alt == true or InContention(item, holder.class)
end

--[[
	Leftovers and unreadables never count, or the plan never empties. A holder ranked as a stranger
	(SourceRank 3) in a capital or dungeon still searches; one ranked above strangers never does.
]]
local function StillSearching(item)
	if item.state ~= ns.Matcher.GIFT or item.pinned then
		return false
	end
	if not item.recipient then
		return true
	end
	if ns.Matcher:SourceRank(item.recipient) >= 3 and ns.Who:KeepsSearching(item.recipient) then
		return true
	end
	return not HolderInContention(item)
end

--[[
	A fallback-held item asks only for contenders (only an upgrade is worth a press); an unheld one
	for everybody admitted, or eligible when nobody was, since an empty set asks for no classes.
]]
local function BandClasses(item, verdict)
	if item.recipient and not item.pinned and not HolderInContention(item) then
		return verdict.contenders
	end
	return (#verdict.admitted > 0) and verdict.admitted or verdict.eligible
end

-- By slot key, since RescanBags replaces every item table; read only while Who.targeted holds.
local targetKey

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

-- A classless attempt (a consumable's zones) asks for everybody, so it stays while any admitted class could outrank.
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
	Leftovers left out, unlike the scan bands: the plan drops whole once no gift searches. Reads the
	cached verdict, since a second opinion could prune a band the list still shows waiting.
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

function MatchList:Target(item)
	targetKey = item and MatchList:SlotKey(item) or nil
end

MatchSearch.MergeBands = MergeBands
MatchSearch.BandClasses = BandClasses
MatchSearch.NarrowTargeted = NarrowTargeted
MatchSearch.SearchingGifts = SearchingGifts
MatchSearch.SearchingBands = SearchingBands
