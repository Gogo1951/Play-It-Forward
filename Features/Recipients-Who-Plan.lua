local _, ns = ...

ns.Who = {}
local Who = ns.Who

--------------------------------------------------------------------------------
-- Shared State
--------------------------------------------------------------------------------

-- Shared with Features/Recipients-Who.lua by reference: both tables are changed in place, never replaced.
Who.plan = {}

--[[
	Session totals for the roster report; Who:Clear leaves them so the report still has them after
	a plan ends. connectedRealm results are kept, not dropped: a connected realm's player can be
	mailed. panelOpened nonzero means some route still opens the Who panel mid-query.
]]
Who.counts = {
	seen = 0,
	connectedRealm = 0,
	unknownClass = 0,
	otherFaction = 0,
	capped = 0,
	pruned = 0,
	exhausted = 0,
	timedOut = 0,
	blocked = 0,
	panelOpened = 0,
	guildmates = 0,
	ignoredGuild = 0,
}

local plan, counts = Who.plan, Who.counts
local planned = 0

-- map returns the attempt, a narrowed replacement, or nil to drop it.
local function FilterPlan(map)
	local kept, dropped = {}, 0
	for _, attempt in ipairs(plan) do
		local survives = map(attempt)
		if survives then
			kept[#kept + 1] = survives
		else
			dropped = dropped + 1
		end
	end
	wipe(plan)
	for _, attempt in ipairs(kept) do
		plan[#plan + 1] = attempt
	end
	return dropped
end

--[[
	Read by MatchList:Assign: the "every gift has a contender" stop must not end a targeted search,
	which is pressed exactly because the contender holding the item is not good enough.
]]
Who.targeted = false

--------------------------------------------------------------------------------
-- Class Names
--------------------------------------------------------------------------------

-- Built once at load: the locale cannot change without a restart.
local classNameByToken = LOCALIZED_CLASS_NAMES_MALE or {}

local function ClassName(token)
	return classNameByToken[token] or token or ""
end

-- The exact read the class filter makes, for the diagnostics Game Names report.
Who.ClassName = ClassName

local femaleNameByToken = LOCALIZED_CLASS_NAMES_FEMALE or {}

--[[
	Only where this locale gives the class a form of its own (deDE "Schurkin"); nil where the two
	match or differ only in case (Mists esMX death knight). Assumes /who matches the name a
	character displays, so a male filter misses women. Unverified in game.
]]
local function FemaleName(token)
	local female = femaleNameByToken[token]
	if female and female ~= "" and female:lower() ~= ClassName(token):lower() then
		return female
	end
	return nil
end

--------------------------------------------------------------------------------
-- Query Planning
--------------------------------------------------------------------------------

--[[
	SendWho works only inside a real click, so every press has to be spent well.
	One c-"..." per query, never a list: the client honors the first and silently drops the rest
	(seen live on 1.15.9). Zones go first: somebody in a zone made for their level is leveling,
	while a bare level query fills its 50 mostly with people standing in a capital.
]]

-- /who is chat text: past the limit it is not answered at all, so the zone list is chunked.
local FILTER_MAX = 240
Who.FILTER_MAX = FILTER_MAX

-- "" when the filter would exclude nobody and only cost length.
local function ClassFilter(classes, female)
	if not classes or #classes == 0 then
		return "", {}
	end
	if #classes >= #ns.Matcher:Classes() then
		return "", {}
	end

	local names, parts = {}, {}
	for _, token in ipairs(classes) do
		local name = (female and #classes == 1 and FemaleName(token)) or ClassName(token)
		if name and name ~= "" then
			names[#names + 1] = name
			parts[#parts + 1] = ('c-"%s"'):format(name)
		end
	end
	table.sort(names)
	table.sort(parts)
	return table.concat(parts, " "), names
end

local function ClassLabel(names)
	if #names == 0 then
		return nil
	end
	if #names <= 3 then
		return table.concat(names, ", ")
	end
	return ("%s +%d"):format(table.concat({ names[1], names[2], names[3] }, ", "), #names - 3)
end

-- ns.DiagnosticsStrings is read at call time, not aliased: Diagnostics/Diagnostics-Core.lua loads after this file.
local function NewAttempt(lo, hi, zones, classes, female, guild)
	local DiagnosticsStrings = ns.DiagnosticsStrings
	local classPart, classNames = ClassFilter(classes, female)
	local levels = ("%d-%d"):format(lo, hi)
	local query = levels
	local label

	if guild then
		query = ('%s g-"%s"'):format(levels, guild)
		label = DiagnosticsStrings.WHO_LABEL_GUILD:format(guild, levels)
	elseif zones and #zones > 0 then
		local parts = {}
		for _, name in ipairs(zones) do
			parts[#parts + 1] = ('z-"%s"'):format(name)
		end
		query = query .. " " .. table.concat(parts, " ")
		label = (#zones == 1) and DiagnosticsStrings.WHO_LABEL_IN_ZONE:format(zones[1], levels)
			or DiagnosticsStrings.WHO_LABEL_ZONES:format(#zones, levels)
	else
		label = DiagnosticsStrings.WHO_LABEL_ANYWHERE:format(levels)
	end

	if classPart ~= "" then
		query = query .. " " .. classPart
		local named = ClassLabel(classNames)
		if named then
			label = DiagnosticsStrings.WHO_LABEL_FOR_CLASSES:format(label, named)
		end
	end

	-- The ingredients travel with the strings so Who:Prune rebuilds a narrowed attempt instead of parsing the query.
	return {
		query = query,
		label = label,
		lo = lo,
		hi = hi,
		zones = zones,
		classes = classes or {},
		female = female or nil,
		guild = guild,
	}
end

-- A single-class attempt and its female twin, asked back to back; the same token makes pruning treat them as one class.
local function Step(lo, hi, zones, single)
	local step = { NewAttempt(lo, hi, zones, single) }
	if single and FemaleName(single[1]) then
		step[2] = NewAttempt(lo, hi, zones, single, true)
	end
	return step
end

-- The longer of a single class's two filters, so a zone chunk has room for either form.
local function SinglePart(single)
	if not single then
		return ""
	end
	local male, female = (ClassFilter(single)), (ClassFilter(single, true))
	return (#female > #male) and female or male
end

-- Interleaved, not concatenated: draining one band's zones first leaves a distant item unlooked-at for presses.
local function Interleave(lists)
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

local function ZoneChunks(lo, hi, classPart)
	local fixed = #("%d-%d"):format(lo, hi) + (classPart ~= "" and (#classPart + 1) or 0)
	local out, current, used = {}, {}, 0

	for _, zone in ipairs(ns.Data.ZonesFor(lo, hi)) do
		local piece = #('z-"%s"'):format(zone.name) + 1
		-- A zone name too long for the budget alone still gets its own query, never an empty chunk.
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
	Bands this close share one query: an item's band is two levels wide, so 52, 53 and 56 would
	cost three presses where one /who 52-57 answers. Wider, and the 50-result cap thins each band.
]]
local SPAN_MAX = 6

-- A band asking for no class in particular makes its whole span ask everybody (MergeBands' last argument).
local function WithinSpan(last, group)
	return math.max(last.hi, group.hi) - last.lo + 1 <= SPAN_MAX
end

local function Coalesce(groups)
	local normalized = {}
	for _, group in ipairs(groups or {}) do
		local lo = math.max(1, group.lo or 1)
		normalized[#normalized + 1] = { lo = lo, hi = math.max(lo, group.hi or lo), classes = group.classes or {} }
	end
	return ns.MatchSearch.MergeBands(normalized, WithinSpan, true)
end

--[[
	Per span: zones, unfiltered unless one class is wanted; bare levels; one query per class.
	A zoned answer never ends anything, so every zone gets its press before the fallback. The count
	returned is not a countdown: the search stops at the first match in contention.
]]
local TargetedPlan

function Who:Plan(groups, targeted)
	wipe(plan)
	Who:CancelPending()
	Who.targeted = targeted and true or false

	if targeted then
		return TargetedPlan(groups)
	end
	groups = Coalesce(groups)

	local zoned, widened, bare = {}, {}, {}
	for _, group in ipairs(groups or {}) do
		local lo = math.max(1, group.lo or 1)
		local hi = math.max(lo, group.hi or lo)
		local classes = group.classes or {}
		local single = (#classes == 1) and classes or nil
		-- Only its length is wanted here, for the chunk budget.
		local singlePart = SinglePart(single)

		local perBand = {}
		for _, chunk in ipairs(ZoneChunks(lo, hi, singlePart)) do
			perBand[#perBand + 1] = Step(lo, hi, chunk, single)
		end
		zoned[#zoned + 1] = perBand

		-- A list naming every class narrows nothing; the bare stage already asks that.
		if #classes > 0 and #classes < #ns.Matcher:Classes() then
			local perClass = {}
			for _, token in ipairs(classes) do
				perClass[#perClass + 1] = Step(lo, hi, nil, { token })
			end
			widened[#widened + 1] = perClass
		end
		-- Classless on purpose: Who:Prune never narrows a classless attempt.
		bare[#bare + 1] = { Step(lo, hi, nil, nil) }
	end

	-- One query per guild across every band: a guild rarely fills 50, and asking per band costs a press each.
	local names = ns.Guild:SearchNames()
	if #names > 0 and #groups > 0 then
		local lo, hi = math.huge, 0
		for _, group in ipairs(groups) do
			lo = math.min(lo, math.max(1, group.lo or 1))
			hi = math.max(hi, group.hi or group.lo or 1)
		end
		for _, name in ipairs(names) do
			plan[#plan + 1] = NewAttempt(lo, math.max(lo, hi), nil, nil, nil, name)
		end
	end

	-- Interleaved by step, so a female twin is never split from its male form by another band.
	for _, stage in ipairs({ zoned, bare, widened }) do
		for _, step in ipairs(Interleave(stage)) do
			for _, attempt in ipairs(step) do
				plan[#plan + 1] = attempt
			end
		end
	end

	planned = #plan
	return #plan
end

--[[
	Rescan for Better Match: no coalescing, no bare stage, no guild queries. Zones under the class
	filter, then each class anywhere, never interleaved: Matcher:TargetedBands' order is the
	ranking. A group naming several classes (a consumable's) asks its zones unfiltered.
]]
function TargetedPlan(groups)
	local filtered, zoned = {}, {}
	for _, group in ipairs(groups or {}) do
		local lo = math.max(1, group.lo or 1)
		local hi = math.max(lo, group.hi or lo)
		local classes = group.classes or {}

		if #classes > 0 and #classes < #ns.Matcher:Classes() then
			for _, token in ipairs(classes) do
				filtered[#filtered + 1] = Step(lo, hi, nil, { token })
			end
		end

		local single = (#classes == 1) and classes or nil
		for _, chunk in ipairs(ZoneChunks(lo, hi, SinglePart(single))) do
			zoned[#zoned + 1] = Step(lo, hi, chunk, single)
		end
	end

	for _, stage in ipairs({ zoned, filtered }) do
		for _, step in ipairs(stage) do
			for _, attempt in ipairs(step) do
				plan[#plan + 1] = attempt
			end
		end
	end

	planned = #plan
	return #plan
end

--[[
	An answer under the cap is everybody the server had, so a planned subset (same levels or fewer,
	same classes or narrower) can only repeat it. A zoned answer exhausts nothing: the client may
	honor only its first zone.
]]
function Who:Exhausted(attempt)
	-- A guild's answer under the cap is everybody in that guild, which says nothing about anyone else.
	if not attempt or #(attempt.zones or {}) > 0 or attempt.guild or #plan == 0 then
		return 0
	end
	local asked = {}
	for _, class in ipairs(attempt.classes or {}) do
		asked[class] = true
	end

	local function Answered(other)
		if other.lo < attempt.lo or other.hi > attempt.hi then
			return false
		end
		if #(attempt.classes or {}) == 0 then
			return true
		end
		if #other.classes == 0 then
			return false
		end
		-- One form's answer says nothing about the other's, if the server matches the name shown.
		if (other.female or false) ~= (attempt.female or false) then
			return false
		end
		for _, class in ipairs(other.classes) do
			if not asked[class] then
				return false
			end
		end
		return true
	end

	local dropped = FilterPlan(function(other)
		return not Answered(other) and other or nil
	end)
	counts.exhausted = counts.exhausted + dropped
	return dropped
end

-- How many attempts the plan started with, for the diagnostics roster report.
function Who:Planned()
	return planned
end

--[[
	ONLY EVER REMOVES: re-planning restarts at the best-first attempt, so a search re-planned on
	each press never gets past its first zone. A survivor's classes are intersected with what the
	remaining bands want, never unioned, which would send a query nothing planned for.
]]
function Who:Prune(groups)
	if #plan == 0 then
		return 0
	end

	local function Survivor(attempt)
		local wanted, overlaps = {}, false
		for _, group in ipairs(groups or {}) do
			local groupLow = group.lo or 1
			local groupHigh = group.hi or groupLow
			-- Unioned across overlapping bands: a merged band split by an assignment leaves one attempt answering for both.
			if attempt.lo <= groupHigh and groupLow <= attempt.hi then
				overlaps = true
				for _, class in ipairs(group.classes or {}) do
					wanted[class] = true
				end
			end
		end

		if not overlaps then
			return nil
		end
		-- The last widening step carries no classes on purpose; narrowing is what it undoes.
		if #attempt.classes == 0 then
			return attempt
		end

		local narrowed = {}
		for _, class in ipairs(attempt.classes) do
			if wanted[class] then
				narrowed[#narrowed + 1] = class
			end
		end
		-- An empty intersection drops it: an empty class list would send it unfiltered, wider than before.
		if #narrowed == 0 then
			return nil
		end
		-- Subset by construction, so equal length is the same set and the strings can stand.
		if #narrowed == #attempt.classes then
			return attempt
		end
		return NewAttempt(attempt.lo, attempt.hi, attempt.zones, narrowed, attempt.female, attempt.guild)
	end

	local dropped = FilterPlan(Survivor)

	-- Counted so the roster report can tell pruning from a query that quietly went missing.
	counts.pruned = counts.pruned + dropped
	return dropped
end

function Who:PruneTargeted(keep)
	local dropped = FilterPlan(function(attempt)
		return keep(attempt) and attempt or nil
	end)
	counts.pruned = counts.pruned + dropped
	return dropped
end

-- Where the next press will look, for the diagnostics roster report.
function Who:Peek()
	return plan[1] and plan[1].label
end
