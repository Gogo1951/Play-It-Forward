local _, ns = ...

ns.Who = {}
local Who = ns.Who

--------------------------------------------------------------------------------
-- Shared State
--------------------------------------------------------------------------------

--[[
	Shared with Features/Recipients-Who.lua through the module table: this file plans the attempts
	and that one sends them. Both tables are only ever changed in place, never replaced.

	Attempts still to make, one per press. A level range and its zones share one query, with at
	most one class filter on it -- see the single-filter rule under Query Planning below:

	  16-19 z-"Westfall" z-"Loch Modan" z-"Duskwood"
	  16-19 c-"Warrior"
]]
Who.plan = {}

--[[
	Session totals for the roster report; Who:Clear leaves them alone so the report still has them
	after a plan finishes. connectedRealm counts results carrying a "-Realm" suffix, and they are
	KEPT: every Classic Era and TBC realm is connected, so anyone in a /who result can be mailed.
	capped counts queries that came back at the full cap -- a thin realm against a thin sample;
	exhausted counts attempts dropped because an answer under the cap already covered them.
	otherFaction counts results dropped because mail cannot reach them. timedOut counts queries
	that never answered and went back on the plan; blocked counts SendWho calls the client refused
	because the press did not reach it as a click. panelOpened counts the Who panel showing while a
	query was out when it was closed before -- nonzero means some route still reaches it.
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
}

local plan, counts = Who.plan, Who.counts
local planned = 0

--[[
	Rebuilds the plan in place from what map returns for each attempt: the attempt, a narrowed
	replacement, or nil to drop it. Returns how many were dropped.
]]
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
	Whether the plan standing is a targeted one, Find Recipients for This Item's. MatchList:Assign
	reads it: the "every gift has a contender" rule that ends a full search must not end a targeted
	one, which is pressed exactly when the contender holding the item is not good enough. Reset by
	every Who:Plan and by Who:Clear.
]]
Who.targeted = false

--------------------------------------------------------------------------------
-- Class Names
--------------------------------------------------------------------------------

-- The localized name a /who class filter goes out with. Built once at load: the locale cannot change without a restart.
local classNameByToken = LOCALIZED_CLASS_NAMES_MALE or {}

local function ClassName(token)
	return classNameByToken[token] or token or ""
end

-- The exact read the class filter makes, for the diagnostics Game Names report.
Who.ClassName = ClassName

local femaleNameByToken = LOCALIZED_CLASS_NAMES_FEMALE or {}

--[[
	The female form, only where this locale gives the class one of its own ("Schurkin" beside
	"Schurke", "Voleuse" beside "Voleur"); nil where the two read the same, as in English, or
	differ only in case, as Mists' esMX death knight does. ChrClasses on every shipped flavor has
	them in deDE, esES, esMX, frFR, ptBR and ruRU (checked 2026-10-29).
	If /who matches the name a character displays, a filter in the male form never finds a woman
	of that class, so a single-class query is asked again in this form (Step below). Unverified
	in game.
]]
local function FemaleName(token)
	local female = femaleNameByToken[token]
	if female and female ~= "" and female:lower() ~= ClassName(token):lower() then
		return female
	end
	return nil
end

Who.FemaleName = FemaleName

--------------------------------------------------------------------------------
-- Query Planning
--------------------------------------------------------------------------------

--[[
	C_FriendList.SendWho is hardware-event gated on 1.15: a call outside the stack of a real
	click raises ADDON_ACTION_BLOCKED and does nothing -- no error, no WHO_LIST_UPDATE, just
	silence. Queries cannot be chained on a timer; every one rides a button press, so each
	press has to be spent well.

	ONE CLASS FILTER PER QUERY, NEVER A LIST. The client honors a single c-"..." and quietly
	drops the rest of an OR'd set -- observed live on 1.15.9 (2026-07-23): a query carrying
	c-"Paladin" c-"Rogue" c-"Warrior" answered with paladins alone, the first filter
	alphabetically, and the pool filled with a class the item was not for. So a zoned query
	carries a class filter only when exactly one class is wanted, and the widened stage asks
	one class per query. Multiple z-"..." filters are kept as a best effort: if the client
	honors only the first, the query still answers correctly from its first zone, and the
	per-class widening behind it is what the search actually relies on.

	THE ZONES GO FIRST. Somebody out in a zone made for their level is levelling, and that is who
	a gift is for; a bare level query fills its 50 mostly with people standing in a capital. So
	the levelling zones are asked before anywhere, and the bare and per-class queries follow as
	the fallback for a band the zones could not fill. One level-21 mage can receive the cloak as
	well as forty can, so the search stops once somebody in contention holds each item, out in
	the world (Who:Placement) -- a fallback pairing keeps its band on the plan, narrowed to the
	classes the verdict named, and so does a holder found in a city or a dungeon.
]]

-- /who is chat text: past the limit it is not answered at all, so the zone list is chunked.
local FILTER_MAX = 240
Who.FILTER_MAX = FILTER_MAX

--[[
	'c-"Warrior" c-"Paladin"', or "" when it would exclude nobody and only cost length. female
	asks a single class in its female form, where the locale has one.
]]
local function ClassFilter(classes, female)
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

-- Class names for the diagnostics roster report. Six of them is not information, so it stops at three.
local function ClassLabel(names)
	if #names == 0 then
		return nil
	end
	if #names <= 3 then
		return table.concat(names, ", ")
	end
	return ("%s +%d"):format(table.concat({ names[1], names[2], names[3] }, ", "), #names - 3)
end

--[[
	The readable form of a query, for the roster report. ns.DiagnosticsStrings is read at call
	time rather than aliased at file scope, because Diagnostics/Diagnostics-Core.lua loads after this one.
]]
local function NewAttempt(lo, hi, zones, classes, female)
	local DiagnosticsStrings = ns.DiagnosticsStrings
	local classPart, classNames = ClassFilter(classes, female)
	local levels = ("%d-%d"):format(lo, hi)
	local query = levels
	local label

	if zones and #zones > 0 then
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

	--[[
		The ingredients travel with the built strings. Who:Prune narrows the class half after an
		assignment and rebuilds from these, rather than parsing a finished query back apart.
	]]
	return {
		query = query,
		label = label,
		lo = lo,
		hi = hi,
		zones = zones,
		classes = classes or {},
		female = female or nil,
	}
end

--[[
	One planned step: a single-class attempt, then its female twin where the locale has one, kept
	together so the second form is asked straight after the first. Both carry the same class
	token, so Who:Prune and Who:PruneTargeted treat the pair as one class: a holder found under
	either form ends both.
]]
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

--[[
	One attempt from each band before coming back for seconds. Interleaved, not concatenated: a
	bag holding a level 15 cloak and a level 45 sword has two bands with nothing in common, and
	draining one band's zones first means five presses before the other item is looked at once.
]]
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

-- Packs a band's zones into as few queries as the length budget allows, best zones first.
local function ZoneChunks(lo, hi, classPart)
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
	Bands this close are asked in one query. An item's band is two levels wide, so a bag of gear
	for 52, 53 and 56 is three bands and three presses where one `/who 52-57` answers for all of
	them -- observed live (2026-10-09): five presses to fill five rows a single query would have
	mostly covered. Wider than this and the 50-result cap thins each band's share of the answer.
]]
local SPAN_MAX = 6

--[[
	Folds neighbouring bands into one span, classes unioned. A band asking for no class in
	particular asks for everybody, so a span holding one asks for everybody too.
]]
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
	The attempt queue, built from the level bands that have an item waiting, each carrying the
	classes those items can go to. Neighbouring bands share a span (SPAN_MAX above). Per span:

	  1  the zones covering it, packed into as few queries as fit, best zone first -- the people
	     out there levelling. Unfiltered by class unless exactly one is wanted, per the
	     single-filter rule at the top of this file. A zoned answer never ends anything
	     (Who:Exhausted), so every zone gets its press before the fallback.
	  2  bare levels, no filters -- the fallback, and the query most likely to fill all 50: it
	     reaches the capitals and dungeons too, whose people rank last but can still open a
	     parcel. An answer under the cap is everybody online at those levels, which ends the
	     span outright.
	  3  one query per wanted class, no zones, for a class the capped answer crowded out

	TARGETED skips the coalescing and the bare stage, and asks each class in its zones before
	asking for it anywhere: Find Recipients for This Item exists to ask for the classes it names,
	and a bare query is what the main button already sent. See TargetedPlan below. The count returned is not a countdown: the
	search stops at the first match in contention, or for a targeted search once nothing left on
	the plan could outrank whoever holds the row.
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
		-- Only its length is wanted here, for the chunk budget; each attempt builds its own.
		local singlePart = SinglePart(single)

		local perBand = {}
		for _, chunk in ipairs(ZoneChunks(lo, hi, singlePart)) do
			perBand[#perBand + 1] = Step(lo, hi, chunk, single)
		end
		zoned[#zoned + 1] = perBand

		-- A list naming every class narrows nothing; the bare stage below already asks that.
		if #classes > 0 and #classes < #ns.Matcher:Classes() then
			local perClass = {}
			for _, token in ipairs(classes) do
				perClass[#perClass + 1] = Step(lo, hi, nil, { token })
			end
			widened[#widened + 1] = perClass
		end
		-- No classes: the last widening step gives up the class half, so it must not be narrowed.
		bare[#bare + 1] = { Step(lo, hi, nil, nil) }
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
	Matcher:TargetedBands hands over one class per group, best fit first. Two stages, each in that
	order and never interleaved, because the order IS the ranking:

	  1  the zones, under the class filter -- that class out levelling, which is who the gift is
	     for (Who:Placement)
	  2  one class-filtered query per group, no zones -- everybody of that class at those levels,
	     wherever they stand, as the fallback for a class the zones turned up nobody for

	A group naming several classes (a consumable's, which every class wants equally) asks its
	zones unfiltered, then each of them by class.

	After every answer MatchList:Assign drops the attempts whose class could not outrank the row's
	holder (Who:PruneTargeted), so a search ends as soon as no press left could change the row.
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
	Called with a query that came back under the cap, which means the server sent everybody it
	had: every planned attempt asking a subset of the same question can only repeat that answer,
	so it is dropped rather than spending a press and the throttle on it.

	A subset is the same levels or fewer, and the same class filter or a narrower one. A zoned
	answer never exhausts anything -- the client may honor only its first zone, so "under the
	cap" there says nothing about the rest.
]]
function Who:Exhausted(attempt)
	if not attempt or #(attempt.zones or {}) > 0 or #plan == 0 then
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

-- How many attempts the plan started with. Read by the diagnostics roster report.
function Who:Planned()
	return planned
end

--[[
	Narrows a plan already under way to the bands that still have somebody to find, called after
	every assignment -- Who:Clear applied one band at a time.

	ONLY EVER REMOVES. Re-planning through Who:Plan would rebuild the queue from its best-first
	attempt and re-send what has already been asked, so a search re-planning on each press would
	never get past its first zone. An attempt whose band holds no unmatched gift is dropped:
	interleaving means a satisfied band keeps taking its turn, and every turn costs a click and
	the full throttle. A survivor's class half is intersected with what the remaining bands want
	-- never unioned, since widening would send a query nothing planned for.
]]
function Who:Prune(groups)
	if #plan == 0 then
		return 0
	end

	-- What an attempt becomes after narrowing, or nil when nothing is left for it to ask.
	local function Survivor(attempt)
		local wanted, overlaps = {}, false
		for _, group in ipairs(groups or {}) do
			local groupLow = group.lo or 1
			local groupHigh = group.hi or groupLow
			--[[
				Every overlapping band contributes, unioned: one merged band split back in two by
				an assignment leaves a single attempt still answering for both halves.
			]]
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
		--[[
			An empty intersection is not "ask everybody": an empty class list would send the
			attempt unfiltered, a wider query than the one being pruned.
		]]
		if #narrowed == 0 then
			return nil
		end
		-- Subset by construction, so equal length is the same set and the strings can stand.
		if #narrowed == #attempt.classes then
			return attempt
		end
		return NewAttempt(attempt.lo, attempt.hi, attempt.zones, narrowed, attempt.female)
	end

	local dropped = FilterPlan(Survivor)

	--[[
		Counted for the roster report, which otherwise shows places-left falling without a press
		and no way to tell pruning from a query that quietly went missing.
	]]
	counts.pruned = counts.pruned + dropped
	return dropped
end

--[[
	Drops every planned attempt keep turns down, for a targeted search narrowed against its row's
	holder. Only ever removes, as Who:Prune does, and counted with it.
]]
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
