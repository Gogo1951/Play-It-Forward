local _, ns = ...

local Matcher = ns.Matcher

--------------------------------------------------------------------------------
-- Candidate Ranking
--------------------------------------------------------------------------------

-- The picker's sections, which name the source whatever the Prioritize switches say.
function Matcher:Source(person)
	if person.alt then
		return 1
	end
	if person.guild then
		return 2
	end
	return 3
end

-- A source whose Prioritize switch is off ranks as a stranger, competing on fit, placement and level.
function Matcher:SourceRank(person)
	local profile = ns.db and ns.db.profile or {}
	if person.alt and profile.prioritizeAlts ~= false then
		return 1
	end
	if person.guild and profile.prioritizeGuilds ~= false then
		return 2
	end
	return 3
end

-- Strangers only: an alt is yours, and the guild roster has its own summoner rule.
local function SkippedSummoner(person)
	local profile = ns.db and ns.db.profile
	if not (profile and profile.ignoreSummonerWarlocks) or person.alt or person.guild then
		return false
	end
	local level = person.level or 0
	return person.class == "WARLOCK" and level >= ns.Data.SUMMONER_MIN_LEVEL and level <= ns.Data.SUMMONER_MAX_LEVEL
end

--[[
	Judged by the alt's own specs and its own Alts:LevelRange, never the stranger band: your alt will
	reach the level, and the My Alts Highest dropdown caps how far ahead it is stocked.
]]
local function AltWants(matcher, item, verdict, person, classToken, lo)
	local profile = ns.db and ns.db.profile
	local entry = ns.Alts:Entry(person)
	-- No entry is an alt deleted on My Alts this session: Alts:Included(nil) answers false.
	if not (profile and profile.sendToAlts) or not ns.Alts:Included(entry) then
		return false
	end
	local judged = verdict
	if item.kind ~= "consumable" and entry then
		judged = matcher:VerdictForSpecs(item, classToken, ns.Alts:SpecsFor(entry))
	end
	local contender = false
	for _, class in ipairs(judged.contenders or {}) do
		if class == classToken then
			contender = true
		end
	end
	if not contender then
		return false
	end
	local fit = judged.fits and judged.fits[classToken] or 0
	-- lo is a consumable's own use level: Matcher:LevelBand starts its band there.
	local level = (item.kind == "consumable") and lo or ns.Data.EquipLevelFor(item, classToken)
	local low, high = ns.Alts:LevelRange(entry, person.level)
	return level >= low and level <= high, fit
end

--[[
	Hand-out order (CouldOutrank mirrors it):
	  fit bucket -> source -> placement -> level proximity -> armor/weapon group -> class fit -> random
]]
function Matcher:RankCandidates(item, pools)
	local out, meta = {}, {}

	-- A leftover still ranks, so the dropdown can overrule the vendor pile by hand.
	local verdict = self:VerdictFor(item)

	-- Never recomputed from fit: the weapon baseline compresses the ratio and lifts a weaker class.
	local topBucket = {}
	for _, class in ipairs(verdict.contenders or {}) do
		topBucket[class] = true
	end

	-- Plus any class an alt plays: judged by its own specs, it can want what the defaults never admitted.
	local classes, seen = {}, {}
	for _, class in ipairs(verdict.admitted) do
		classes[#classes + 1], seen[class] = class, true
	end
	for class, people in pairs(pools) do
		if not seen[class] then
			for _, person in ipairs(people) do
				if person.alt then
					classes[#classes + 1], seen[class] = class, true
					break
				end
			end
		end
	end
	local admitted = {}
	for _, class in ipairs(verdict.admitted) do
		admitted[class] = true
	end

	for _, class in ipairs(classes) do
		local fit, tier = verdict.fits[class] or 0, self:Priority(item, class)
		-- Per class, never item.bandLo: a class that trains the armor material later searches higher.
		local lo, hi = self:LevelBand(item, class)
		-- Gear anchors to the top of its band, a consumable to the bottom (its use level); AnchorFor mirrors it.
		local anchor = (item.kind == "consumable") and lo or hi
		-- Bucket rather than cut: a marginal class still receives when nobody better is in range.
		local bucket = topBucket[class] and 1 or 2
		for _, person in ipairs(pools[class] or {}) do
			local inRange, personFit, personBucket = false, fit, bucket
			if SkippedSummoner(person) then
				inRange = false
			elseif person.alt then
				local altFit
				inRange, altFit = AltWants(self, item, verdict, person, class, lo)
				personFit, personBucket = altFit or fit, 1
			elseif admitted[class] then
				inRange = person.level >= lo and person.level <= hi
			end
			if inRange then
				table.insert(out, person)
				meta[person] = {
					tier = tier,
					fit = personFit,
					bucket = personBucket,
					anchor = anchor,
					placement = ns.Who:PlacementRank(person),
				}
			end
		end
	end

	table.sort(out, function(a, b)
		local ma, mb = meta[a], meta[b]
		if ma.bucket ~= mb.bucket then
			return ma.bucket < mb.bucket
		end
		-- Behind the bucket, never ahead: a priest stranger still beats a mage alt who barely wants it.
		local aSource, bSource = self:SourceRank(a), self:SourceRank(b)
		if aSource ~= bSource then
			return aSource < bSource
		end
		-- Placement is the evidence they are leveling; ahead of level, which only splits a two-level band.
		if ma.placement ~= mb.placement then
			return ma.placement < mb.placement
		end
		-- Each against its own class's anchor, which is the level that class equips the item at.
		local aDist = math.abs((a.level or 0) - ma.anchor)
		local bDist = math.abs((b.level or 0) - mb.anchor)
		if aDist ~= bDist then
			return aDist < bDist
		end
		if ma.tier ~= mb.tier then
			return ma.tier < mb.tier
		end
		if ma.fit ~= mb.fit then
			return ma.fit > mb.fit
		end

		-- Shuffle is rolled at pool entry, never here: a comparator that changes mid-sort makes table.sort throw.
		local aRoll, bRoll = a.shuffle or 0, b.shuffle or 0
		if aRoll ~= bRoll then
			return aRoll < bRoll
		end
		return (a.name or "") < (b.name or "")
	end)
	return out
end

--------------------------------------------------------------------------------
-- Level Bands
--------------------------------------------------------------------------------

-- With a class, that class's band (it moves where the class trains the armor later); without, the item's.
function Matcher:LevelBand(item, classToken)
	-- CONSUMABLE_RECIPIENT_GAP, never profile.consumableLevelGap (the sender's outgrown-it threshold).
	if item.kind == "consumable" then
		local lo = math.max(1, item.def.useLevel)
		return lo, lo + ns.Data.CONSUMABLE_RECIPIENT_GAP
	end
	local req = classToken and ns.Data.EquipLevelFor(item, classToken) or (item.reqLevel or 1)
	local lo = math.max(1, req - ns.Data.LEVEL_GAP_WIDEST)
	local hi = math.max(lo, req - ns.Data.LEVEL_GAP_CLOSEST)
	return lo, hi
end

-- Shaped as Recipients-Who-Plan wants; group order follows the class list, so callers lead with contenders.
function Matcher:BandGroups(item, classes)
	local order, byBand = {}, {}
	for _, class in ipairs(classes or {}) do
		local lo, hi = self:LevelBand(item, class)
		local key = ("%d:%d"):format(lo, hi)
		local group = byBand[key]
		if not group then
			group = { lo = lo, hi = hi, classes = {} }
			byBand[key] = group
			order[#order + 1] = group
		end
		group.classes[#group.classes + 1] = class
	end
	return order
end

-- One span for display and reports only; the search uses BandGroups, never this.
function Matcher:SearchBand(item, classes)
	local lo, hi
	for _, group in ipairs(self:BandGroups(item, classes)) do
		lo = math.min(lo or group.lo, group.lo)
		hi = math.max(hi or group.hi, group.hi)
	end
	if not lo then
		return self:LevelBand(item)
	end
	return lo, hi
end

-- Contenders, then the rest admitted; each half sorted as RankCandidates breaks a level tie.
function Matcher:TargetedClasses(item)
	local verdict = self:VerdictFor(item)
	local admitted = (#verdict.admitted > 0) and verdict.admitted or verdict.eligible
	local contenders = (#(verdict.contenders or {}) > 0) and verdict.contenders or admitted

	local leads, behind = {}, {}
	for _, class in ipairs(contenders) do
		leads[class] = true
	end
	for _, class in ipairs(admitted) do
		if not leads[class] then
			behind[#behind + 1] = class
		end
	end

	local function Ranked(list)
		local out, position = {}, {}
		for index, class in ipairs(list) do
			out[index], position[class] = class, index
		end
		table.sort(out, function(a, b)
			local tierA, tierB = self:Priority(item, a), self:Priority(item, b)
			if tierA ~= tierB then
				return tierA < tierB
			end
			local fitA, fitB = verdict.fits[a] or 0, verdict.fits[b] or 0
			if fitA ~= fitB then
				return fitA > fitB
			end
			return position[a] < position[b] -- stable: the verdict's own order among equals
		end)
		return out
	end

	local out = Ranked(contenders)
	for _, class in ipairs(Ranked(behind)) do
		out[#out + 1] = class
	end
	return out
end

--[[
	One class per group: /who honors one c-"..." filter, and a class filter reaches players in
	dungeons and unlisted zones a zone filter misses. A consumable stays one group: splitting only adds presses.
]]
function Matcher:TargetedBands(item)
	local classes = self:TargetedClasses(item)
	if item.kind == "consumable" then
		return self:BandGroups(item, classes)
	end

	local groups = {}
	for _, class in ipairs(classes) do
		local lo, hi = self:LevelBand(item, class)
		groups[#groups + 1] = { lo = lo, hi = hi, classes = { class } }
	end
	return groups
end

-- Must match RankCandidates' anchor.
local function AnchorFor(matcher, item, classToken)
	local lo, hi = matcher:LevelBand(item, classToken)
	return (item.kind == "consumable") and lo or hi
end

--[[
	Whether a find of this class, at its own anchor, would sort ahead of person: RankCandidates' keys
	in order, so change both together. A tie never outranks.
]]
function Matcher:CouldOutrank(item, person, classToken)
	local verdict = self:VerdictFor(item)
	local admitted, contenders = false, {}
	for _, class in ipairs(verdict.admitted) do
		if class == classToken then
			admitted = true
			break
		end
	end
	if not admitted then
		return false
	end
	if not (person and person.class and person.level) then
		return true
	end

	for _, class in ipairs(verdict.contenders or {}) do
		contenders[class] = true
	end
	local bucket = contenders[classToken] and 1 or 2
	-- An alt holder ranks with the contenders by its own specs, as RankCandidates buckets it.
	local heldBucket = (person.alt or contenders[person.class]) and 1 or 2
	if bucket ~= heldBucket then
		return bucket < heldBucket
	end

	-- A search turns up strangers, and a stranger never outranks an alt or a guildmate in the same bucket.
	if self:SourceRank(person) < 3 then
		return false
	end

	-- Placement is the next key, and any class can turn up somebody better placed.
	if ns.Who:PlacementRank(person) > 0 then
		return true
	end

	if person.level ~= AnchorFor(self, item, person.class) then
		return true
	end

	local tier, heldTier = self:Priority(item, classToken), self:Priority(item, person.class)
	if tier ~= heldTier then
		return tier < heldTier
	end
	return (verdict.fits[classToken] or 0) > (verdict.fits[person.class] or 0)
end
