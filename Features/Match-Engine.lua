local _, ns = ...

ns.Matcher = {}
local Matcher = ns.Matcher

--[[
	Order only; FACTION_CLASSES decides who exists. A phantom class is not harmless: a death knight
	(group 1 on two-handers) would take the headline verdict on an item nobody here can use.
]]
local EVERY_CLASS =
	{ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT", "MONK" }

--[[
	Memoized only once the faction is known: a cached nil would drop a real class for the session.
	Unresolved, or a faction with no row, gets every rollable class: over-including is recoverable.
]]
local memo
local function AllClasses()
	if memo then
		return memo
	end
	local faction = UnitFactionGroup("player")
	local listed = faction and ns.Data.FACTION_CLASSES[faction]
	local rollable = {}
	for rowFaction, classes in pairs(ns.Data.FACTION_CLASSES) do
		if not listed or rowFaction == faction then
			for _, class in ipairs(classes) do
				rollable[class] = true
			end
		end
	end
	local out = {}
	for _, class in ipairs(EVERY_CLASS) do
		if rollable[class] then
			out[#out + 1] = class
		end
	end
	if faction then
		memo = out
	end
	return out
end

function Matcher:Classes()
	return AllClasses()
end

--------------------------------------------------------------------------------
-- Hard Filter
--------------------------------------------------------------------------------

function Matcher:EligibleClasses(item)
	if item.kind == "consumable" then
		local classes = ns.Data.CONSUMABLE_CLASSES[item.def.restores or item.def.buffs or item.def.enhances]
		if classes == nil or classes == "ALL" then
			return AllClasses()
		end
		-- Returned whole, CONSUMABLE_CLASSES would name the phantom classes noted at EVERY_CLASS.
		local available = {}
		for _, class in ipairs(AllClasses()) do
			available[class] = true
		end
		local out = {}
		for _, class in ipairs(classes) do
			if available[class] then
				out[#out + 1] = class
			end
		end
		return out
	end

	local out = {}
	local subclassID, equipLoc = item.subclassID, item.equipLoc

	-- Must stay above the universal check: held off-hands are armor subclass 0.
	if ns.Data.UsesWeaponMatrix(item) then
		local key = ns.Data.WeaponKey(item)
		for _, class in ipairs(AllClasses()) do
			if key and ns.Data.WeaponPriorityFor(key, class) then
				table.insert(out, class)
			end
		end
		return out
	elseif item.classID == 4 then
		-- Rings/necks/trinkets/cloaks: everyone, and no group -- stats alone decide.
		if ns.Data.UNIVERSAL_EQUIP_LOC[equipLoc] or subclassID == 0 then
			return AllClasses()
		end
		local armorType = ns.Data.ARMOR_SUBCLASS[subclassID]
		if not armorType then
			return AllClasses()
		end -- unknown -> don't over-filter
		local priority = ns.Data.ArmorPriorityFor(armorType, item.reqLevel)
		if not priority then
			return AllClasses()
		end
		for _, class in ipairs(AllClasses()) do
			if priority[class] then
				table.insert(out, class)
			end
		end
		return out
	end

	return out
end

-- Group 1 is the item's natural home; universal slots are 1 for everyone, so stats alone decide.
function Matcher:Priority(item, classToken)
	-- Must stay above the universal branch: held off-hands are armor subclass 0.
	if ns.Data.UsesWeaponMatrix(item) then
		return ns.Data.WeaponPriorityFor(ns.Data.WeaponKey(item), classToken) or 9
	end

	if item.classID ~= 4 then
		return 1
	end
	if ns.Data.UNIVERSAL_EQUIP_LOC[item.equipLoc] or item.subclassID == 0 then
		return 1
	end

	local armorType = ns.Data.ARMOR_SUBCLASS[item.subclassID]
	local priority = armorType and ns.Data.ArmorPriorityFor(armorType, item.reqLevel)
	if not priority then
		return 1
	end

	return priority[classToken] or 9 -- unlisted = can't wear it at all
end

--------------------------------------------------------------------------------
-- Soft Score
--------------------------------------------------------------------------------

-- Claim: weighted stats only, no weapon baseline. Decides admission, never ranking.
function Matcher:SpecScore(item, classToken)
	if item.kind == "consumable" then
		return 1
	end
	local weights = ns.Data.STAT_WEIGHTS[classToken]
	if not weights then
		return 0
	end

	local score = 0
	for stat, val in pairs(item.stats or {}) do
		if weights[stat] then
			score = score + ns.Data.StatPoints(stat, val) * weights[stat]
		end
	end
	return score
end

--[[
	Fit: claim plus an item-level baseline so statless weapons still place. The baseline is the same
	for every class, so it moves the threshold test, not the order. GetItemInfo is for hand-built records.
]]
function Matcher:Score(item, classToken)
	local score = self:SpecScore(item, classToken)
	if item.kind == "consumable" or not ns.Data.STAT_WEIGHTS[classToken] then
		return score
	end
	if ns.Data.UsesWeaponMatrix(item) then
		local itemLevel = item.itemLevel or select(4, C_Item.GetItemInfo(item.link)) or item.reqLevel or 1
		score = score + itemLevel * ns.Data.WEAPON_BASELINE
	end
	return score
end

--------------------------------------------------------------------------------
-- Coverage
--------------------------------------------------------------------------------

--[[
	Share of the item's scoreable stats, at budget, the class weights at all: sums let one big weight
	beat breadth (a warrior's 24 + 0 ties a paladin's 16 + 8 on "of the Gorilla"). Unscoreable stats
	stay out, or defense would demote a rogue off his own gear. Nothing scoreable is 1, not 0, or
	every statless weapon is binned.
]]
function Matcher:Coverage(item, classToken)
	local weights = ns.Data.STAT_WEIGHTS[classToken]
	if not weights then
		return 0
	end
	local ranked = ns.Data.ScoreableStats()
	local total, used = 0, 0
	for stat, value in pairs(item.stats or {}) do
		-- Stamina is everybody's: counting it would put a mage at half of an "of the Eagle" roll.
		if ranked[stat] and stat ~= "STAMINA" then
			local points = ns.Data.StatPoints(stat, value)
			total = total + points
			if (weights[stat] or 0) > 0 then
				used = used + points
			end
		end
	end
	if total == 0 then
		return 1
	end
	return used / total
end

--------------------------------------------------------------------------------
-- Verdict
--------------------------------------------------------------------------------

--[[
	Admitted is about classes, never who /who has found, or every item reads leftover before the
	first query. Unreadable stays apart from leftover: disenchanting an unevaluated item is irreversible.
]]
Matcher.GIFT, Matcher.LEFTOVER, Matcher.UNREADABLE = "gift", "leftover", "unreadable"

-- Replaces the contenders, narrowed to admitted; admission is untouched, which is what keeps a rule soft.
local function ApplyPreference(verdict, item, context)
	local preferred = ns.Data.PreferredClasses(item, context)
	if not preferred then
		return
	end
	local named = {}
	for _, class in ipairs(preferred) do
		for _, admitted in ipairs(verdict.admitted) do
			if class == admitted then
				named[#named + 1] = class
				break
			end
		end
	end
	if #named > 0 then
		verdict.contenders = named
	end
end

--[[
	After the preference, so a rule cannot promote a demoted class back (an Intellect dagger names the
	rogue). Falls back through the scoring, never straight to admitted, which would undo coverage.
]]
local function ApplyDemotion(verdict, item, scored, context)
	local demoted = ns.Data.DemotedClasses(item, context)
	if not demoted then
		return
	end

	local function Without(list)
		local out = {}
		for _, class in ipairs(list or {}) do
			if not demoted[class] then
				out[#out + 1] = class
			end
		end
		return out
	end

	for _, candidates in ipairs({ verdict.contenders, scored, verdict.admitted }) do
		local kept = Without(candidates)
		if #kept > 0 then
			verdict.contenders = kept
			return
		end
	end
end

--[[
	A weapon carrying stats nobody eligible weights has been judged, and goes to nobody rather than
	the everyone-fallback. Stamina judges nothing, so a Stamina idol still finds its druid.
]]
local PRIMARY_STATS = { "STRENGTH", "AGILITY", "INTELLECT" }

local function CarriesRankedStat(item)
	local ranked = ns.Data.ScoreableStats()
	for stat, value in pairs(item.stats or {}) do
		if stat ~= "STAMINA" and ranked[stat] and (value or 0) > 0 then
			return true
		end
	end
	return false
end

function Matcher:Verdict(item)
	local eligible = self:EligibleClasses(item)

	-- Vetoes go before scoring, or "of the Owl" buys a warlock back in through the Intellect.
	-- A class with every spec turned off goes too: the player said nobody of that class is leveling.
	if item.kind ~= "consumable" then
		local vetoed = ns.Data.VetoedClasses(item) or {}
		local kept = {}
		for _, class in ipairs(eligible) do
			if not vetoed[class] and ns.Data.ClassEnabled(class) then
				kept[#kept + 1] = class
			end
		end
		eligible = kept
	end
	local verdict = {
		state = Matcher.LEFTOVER,
		eligible = eligible,
		admitted = {},
		-- The top bucket of admitted: everyone level proximity then chooses between.
		contenders = {},
		claims = {},
		fits = {},
		-- Share of the item each admitted class can actually use, for the report.
		coverage = {},
		bestClaim = 0,
		best = nil,
		score = 0,
	}

	if #eligible == 0 then
		return verdict
	end

	-- Every eligible class wants a consumable equally, so best is a representative, not a ranking.
	if item.kind == "consumable" then
		verdict.admitted, verdict.contenders = eligible, eligible
		verdict.state = Matcher.GIFT
		-- No context: an unclaimed rule is about a stat claim, and a consumable is never scored.
		local scored = verdict.contenders
		ApplyPreference(verdict, item, nil)
		ApplyDemotion(verdict, item, scored, nil)
		verdict.best, verdict.score = verdict.contenders[1] or eligible[1], 1
		return verdict
	end

	-- Nothing read off a suffixed item is a failed parse, not a bare item: no score may judge it.
	if ns.ItemSuffixID(item.link) and next(item.stats or {}) == nil then
		verdict.state = Matcher.UNREADABLE
		return verdict
	end

	local anyClaim = false
	for _, class in ipairs(eligible) do
		verdict.fits[class] = self:Score(item, class)
		verdict.claims[class] = self:SpecScore(item, class)
		if verdict.claims[class] > verdict.bestClaim then
			verdict.bestClaim = verdict.claims[class]
		end
		if verdict.claims[class] > 0 then
			anyClaim = true
		end
	end

	--[[
		Only matrix items take the everyone-fallback: the matrix already narrows them. Statless armor
		must not, or whoever is closest in level takes it with nothing to separate them.
	]]
	local offerToEveryone = (not anyClaim) and ns.Data.UsesWeaponMatrix(item) and not CarriesRankedStat(item)

	for _, class in ipairs(eligible) do
		if offerToEveryone or verdict.claims[class] > 0 then
			verdict.admitted[#verdict.admitted + 1] = class
		end
	end

	-- Contention needs the share (magnitude) and coverage (breadth); failing either leaves a fallback.
	local shareOf = verdict.bestClaim * ns.Data.CLASS_SHARE
	local wanted = {}
	for _, class in ipairs(verdict.admitted) do
		local coverage = self:Coverage(item, class)
		verdict.coverage[class] = coverage
		if (verdict.claims[class] or 0) >= shareOf then
			wanted[#wanted + 1] = class
			if coverage > ns.Data.COVERAGE_MAJORITY then
				verdict.contenders[#verdict.contenders + 1] = class
			end
		end
	end

	-- Coverage abstains when it demotes everyone: an Agility and Spell Power roll still goes to someone.
	if #verdict.contenders == 0 then
		verdict.contenders = wanted
	end

	--[[
		The primary stat names the class: secondaries are everybody's (in Mists two of them outweigh
		the Agility beside them on a mage), so they never name a class on their own.
	]]
	local primaries = {}
	for _, stat in ipairs(PRIMARY_STATS) do
		if ((item.stats or {})[stat] or 0) > 0 then
			primaries[#primaries + 1] = stat
		end
	end
	local function Using(list, wants)
		local out = {}
		for _, class in ipairs(list) do
			for _, stat in ipairs(primaries) do
				if wants(class, stat) then
					out[#out + 1] = class
					break
				end
			end
		end
		return out
	end
	if #primaries > 0 then
		local builds = Using(verdict.contenders, function(class, stat)
			return (ns.Data.MAIN_STATS[class] or {})[stat]
		end)
		if #builds == 0 then
			builds = Using(verdict.admitted, function(class, stat)
				return ((ns.Data.STAT_WEIGHTS[class] or {})[stat] or 0) > 0
			end)
		end
		verdict.contenders = builds
	end

	-- Body armor leads with its natural home, or a holy paladin a level closer takes the mage's robe.
	if item.classID == 4 and not ns.Data.UsesWeaponMatrix(item) and not ns.Data.UNIVERSAL_EQUIP_LOC[item.equipLoc] then
		local bestTier = math.huge
		for _, class in ipairs(verdict.contenders) do
			bestTier = math.min(bestTier, self:Priority(item, class))
		end
		local home = {}
		for _, class in ipairs(verdict.contenders) do
			if self:Priority(item, class) == bestTier then
				home[#home + 1] = class
			end
		end
		verdict.contenders = home
	end

	-- unclaimed: a statless gun admits warrior, hunter and rogue alike; only that says the hunter leads.
	local scored = verdict.contenders
	local context = { unclaimed = offerToEveryone }
	ApplyPreference(verdict, item, context)
	ApplyDemotion(verdict, item, scored, context)

	-- Best of the contenders, never the admitted: the headline comes from the set the recipient does.
	local bestScore, bestTier = -math.huge, 99
	for _, class in ipairs(verdict.contenders) do
		local score, tier = verdict.fits[class] or 0, self:Priority(item, class)
		if score > bestScore or (score == bestScore and tier < bestTier) then
			bestScore, bestTier, verdict.best = score, tier, class
		end
	end

	-- No admitted class means no recipient can ever exist, whatever the score says.
	if #verdict.admitted > 0 then
		verdict.score = (bestScore > -math.huge) and bestScore or 0
		if verdict.score >= ns.Data.LEFTOVER_THRESHOLD then
			verdict.state = Matcher.GIFT
		end
	end
	return verdict
end

-- One class judged by exactly these specs (an alt's My Alts ticks); cached per class and spec set.
function Matcher:VerdictForSpecs(item, class, keys)
	local sorted = {}
	for key in pairs(keys) do
		sorted[#sorted + 1] = key
	end
	table.sort(sorted)
	local signature = class .. ":" .. table.concat(sorted, ",")
	item._specVerdicts = item._specVerdicts or {}
	if item._specVerdicts[signature] then
		return item._specVerdicts[signature]
	end

	local saved = ns.Data.SpecOverride
	ns.Data.SpecOverride = { class = class, keys = keys }
	ns.Data.RebuildStatWeights()
	local ok, verdict = pcall(self.Verdict, self, item)
	ns.Data.SpecOverride = saved
	ns.Data.RebuildStatWeights()
	if not ok then
		error(verdict, 0)
	end
	item._specVerdicts[signature] = verdict
	return verdict
end

-- Cached per scan; a record built outside one, such as the Verdict report, gets a fresh verdict.
function Matcher:VerdictFor(item)
	return item.verdict or self:Verdict(item)
end
