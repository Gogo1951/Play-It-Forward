local _, ns = ...

ns.Matcher = {}
local Matcher = ns.Matcher

--[[
	Filtered by AllClasses to what can exist for this player. A phantom class is not a harmless
	extra: Verdict breaks ties on the lowest priority group, so a death knight (group 1 for
	two-handers, warrior 3) takes the headline verdict on an unusable item.
]]
local EVERY_CLASS =
	{ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT", "MONK" }

--[[
	/who and the mailbox are both same-faction, so a class the player's own side cannot roll is
	unreachable however well the item suits it. Which classes each faction can roll on this
	client is the flavor folder's ns.Data.FACTION_CLASSES; EVERY_CLASS only sets the order.

	Memoized only once the faction is known: a cached nil would drop a real class for the session.
	Unresolved returns every class either faction can roll and retries -- over-including is
	recoverable. A faction the table has no row for, such as a Pandaren yet to choose, gets the
	same.
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
		--[[
			CONSUMABLE_CLASSES is a client-agnostic roster of who has a mana bar, so returning it
			whole names the phantom classes described at the top of this file.
		]]
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

	-- gear
	local out = {}
	local subclassID, equipLoc = item.subclassID, item.equipLoc

	--[[
		Weapons, shields, held off-hands and relics: eligibility is "the priority lookup returned a
		group". This must stay above the universal check below: held items are armor subclass 0, so
		that branch would otherwise claim them.
	]]
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

--[[
	Group 1 is the item's natural home: the class that natively wears that armor, or whose every
	spec builds around that weapon. Rings, necks, trinkets and cloaks have no group -- everyone is
	1 and the stat weights alone decide, which is how an agility ring finds a rogue.
]]
function Matcher:Priority(item, classToken)
	-- Held is armor subclass 0, so this must stay above the universal branch below.
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

--[[
	Claim: only the stats the point tables rank for this class, with no weapon baseline. It decides
	whether a class has any claim at all, separately from how it ranks. Consumables aren't
	stat-scored; every eligible class wants them equally.
]]
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
	Fit: the claim plus an item-level baseline so statless weapons still place; shields, held
	off-hands and relics take it too, being matrix-ranked everywhere else. Constant per item, so it
	shifts every admitted class equally and only decides whether the item clears the threshold. The
	C_Item.GetItemInfo fallback is for a record built by hand rather than by the scanner.
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
	How much of an item a class actually uses, 0 to 1. Score sums, so breadth loses to one big
	weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0, a tie the warrior
	wins with half the item dead on him. Coverage separates using an item from using part of one.

	THE DENOMINATOR IS SCOREABLE STATS, NOT THE ITEM'S STAT LINE. Only stats some class
	competes on can say who competes: counting defense or a resistance would put a rogue at
	50% on his own gear and demote him off it. Each stat counts at its budget, not its raw
	number, or "+1% crit" would be a rounding error beside "+10 Agility".

	WHICH MEANS WEIGHTING A STAT IS NEVER ONLY A SCORING CHANGE. It enlarges this
	denominator on every item carrying that stat, and the majority test is strictly greater
	than half, so on a two-stat roll a class ranking one half sits at exactly 0.5 and drops
	out of contention. Stamina sits on most items in the game; that blast radius is the
	trap. A demoted class stays admitted and still receives the item when nobody better is
	in range.

	An item with nothing scoreable returns 1, not 0: those are placed by the weapon
	baseline and the statless fallback, and a 0 would quietly bin every one of them.
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
	What happens to an item, decided in one place; every other answer derives from this. An item
	is only a gift when at least one class was admitted, because admitted classes are exactly who
	RankCandidates draws from. "Admitted" is about classes, never about who /who has found:
	judging on the live roster would vendor every item before the first query.

	  gift        a class was admitted and the best of them clears the threshold
	  leftover    read fine, nobody wants it, or it scores under the threshold
	  unreadable  its stats could not be read, so neither verdict is trustworthy

	Unreadable is separate because merging it into leftover tells the player to disenchant an item
	nobody evaluated, and that is not reversible. Held out of auto-assignment for the same reason.
]]
Matcher.GIFT, Matcher.LEFTOVER, Matcher.UNREADABLE = "gift", "leftover", "unreadable"

--[[
	A rule that names classes replaces the contenders rather than adding to them: "an owl staff is
	for priests, mages and druids" overrules a shaman the point tables liked. Narrowed to classes
	already admitted, so a rule naming nobody reachable strands nothing, and admission is
	untouched -- an owl staff still reaches a hunter when nobody else is there, which is what
	makes it soft.
]]
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
	Drop the classes a rule says must not lead, keeping them admitted as fallbacks. Runs after the
	preference so a rule cannot promote a demoted class back: an Intellect dagger matches the
	dagger rule and names the rogue, who is exactly who should not lead on Intellect.

	IT FALLS BACK THROUGH THE SCORING, NOT PAST IT. Reaching straight for the admitted list would
	promote the classes coverage just demoted. The last resort exists for heavy armor carrying
	Intellect too far below its training level for PROFICIENCY_REACH to reach the hunter or the
	shaman it was written for, which leaves nobody behind a warrior.
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
	Whether an item carries a stat some class ranks. The everyone-fallback below is for a weapon
	that carries nothing to judge it by; one carrying stats nobody eligible wants -- an Agility
	staff with every Agility class's staff spec off, a Spirit shield -- has been judged, and goes
	to nobody rather than to whoever stands nearest. Stamina is everybody's and judges nothing, so a
	Stamina idol still finds its druid.
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

	--[[
		Removed before scoring. See the flavor folder's Match-Rules file: Healing against everyone
		without a healing tree, and Spirit against the classes that get nothing from it. Each must
		outrank the half of the item the class genuinely wants, or "of the Owl" buys a warlock back
		in through the Intellect and a healing roll buys a mage back in through the spell damage.
	]]
	-- A class with every spec turned off goes too: the player said nobody of that class is levelling.
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
		--[[
			This path returns before the scoring below, so the preference is applied here too. No
			context: an unclaimed rule is about a stat claim, and a consumable is never stat-scored.
		]]
		local scored = verdict.contenders
		ApplyPreference(verdict, item, nil)
		ApplyDemotion(verdict, item, scored, nil)
		verdict.best, verdict.score = verdict.contenders[1] or eligible[1], 1
		return verdict
	end

	--[[
		Nothing read off a suffixed item means the parse failed, not that the item is bare.
		Decided before scoring, because a score on an unread item looks like a judgement and is
		not one.
	]]
	if ns.ItemSuffixID(item.link) and next(item.stats or {}) == nil then
		verdict.state = Matcher.UNREADABLE
		return verdict
	end

	--[[
		Two scores per class: claim is what the point tables rank for them, fit adds the weapon
		baseline. Claim decides who is admitted, fit how they rank.
	]]
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
		With no claim anywhere, only matrix-ranked items fall back to "offer it to everyone": a
		statless weapon's level baseline is a genuine universal claim, and the matrix already
		narrows shields, held off-hands and relics to the classes that carry the type. Statless armor must
		not take the fallback -- with nothing to separate them, whoever is closest in level takes
		it. The unread case is gone by here, so this is armor that genuinely carries nothing.
	]]
	local offerToEveryone = (not anyClaim) and ns.Data.UsesWeaponMatrix(item) and not CarriesRankedStat(item)

	for _, class in ipairs(eligible) do
		if offerToEveryone or verdict.claims[class] > 0 then
			verdict.admitted[#verdict.admitted + 1] = class
		end
	end

	--[[
		Who is in the running, which is not verdict.best: best is the single highest (fit, tier)
		class, while every class in the top bucket can receive the item. Resolved here so the
		report and the ordering cannot drift. Two tests: the share asks whether a class wants it
		enough to compete (magnitude), coverage whether it uses the item or only part of one
		(breadth), which scoring cannot see. Failing either leaves a class admitted, and still a
		fallback.
	]]
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

	--[[
		Coverage abstains when it demotes everyone. It is a relative test, so a field where nobody
		clears it carries no information: an Agility and Spell Power roll, where the rogue ranks
		one half and the mage the other, is still worth sending to one of them.
	]]
	if #verdict.contenders == 0 then
		verdict.contenders = wanted
	end

	--[[
		THE PRIMARY STAT NAMES THE CLASS. An item carrying Strength, Agility or Intellect leads with
		the classes that build on one of those it carries. Secondaries are everybody's -- in Mists
		every spec gears for crit, haste and mastery, and two of them outweigh the Agility beside
		them -- so without this a mage "uses most of" an Agility cloak. A rogue's Strength is a
		secondary too, which is what keeps "of the Soldier" with the warrior. The rest stay admitted
		as fallbacks. When nobody builds on any of them, whoever gears for one leads instead: an
		Agility mail belt too low for a hunter is a warrior's. When nobody uses any of them at all --
		an Agility staff in Mists, with every Agility class that holds staves turned off -- nobody
		leads and the item is not a gift: the secondaries never name a class on their own.
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

	--[[
		Body armor leads with the classes it is the natural home of. A holy paladin wants Intellect
		as much as a mage does, and without this a paladin a level closer takes the mage's robe.
		Only among those already in contention, so a Strength leather chest still finds its warrior;
		the rest stay admitted as fallbacks. Cloaks, rings and weapons have no material to judge.
	]]
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

	--[[
		The scoring's own answer, kept so ApplyDemotion can fall back through it. The context is
		what lets a rule ask "and nobody had a claim on it": a statless gun admits a warrior, a
		hunter and a rogue on the baseline alone, and only that fact says the hunter should lead.
	]]
	local scored = verdict.contenders
	local context = { unclaimed = offerToEveryone }
	ApplyPreference(verdict, item, context)
	ApplyDemotion(verdict, item, scored, context)

	--[[
		Best of the contenders, never of the admitted: the headline must come from the same set
		the recipient does. Equal scores -- all three cloth classes on Intellect -- break to
		whichever group is closer to the item's armor type.
	]]
	local bestScore, bestTier = -math.huge, 99
	for _, class in ipairs(verdict.contenders) do
		local score, tier = verdict.fits[class] or 0, self:Priority(item, class)
		if score > bestScore or (score == bestScore and tier < bestTier) then
			bestScore, bestTier, verdict.best = score, tier, class
		end
	end

	--[[
		Both gates, and the order matters. No admitted class means no recipient can ever
		exist, whatever the score says; the threshold, ns.Data.LEFTOVER_THRESHOLD, sits on top.
	]]
	if #verdict.admitted > 0 then
		verdict.score = (bestScore > -math.huge) and bestScore or 0
		if verdict.score >= ns.Data.LEFTOVER_THRESHOLD then
			verdict.state = Matcher.GIFT
		end
	end
	return verdict
end

--[[
	The verdict this item would get if one class played exactly these specs -- one of your alts,
	judged by the specs ticked for it on the My Alts panel rather than by the class's
	defaults. Every other class is judged as usual. Cached on the item per class and set of specs:
	two alts of one class playing one spec share an answer.
]]
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
