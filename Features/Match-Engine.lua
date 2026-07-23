local _, ns = ...

ns.Matcher = {}
local Matcher = ns.Matcher

--[[
	Filtered by ALL_CLASSES to what can exist for this player. A phantom class is not a harmless
	extra: Verdict breaks ties on the lowest priority group, so a death knight (group 1 for
	two-handers, warrior 3) takes the headline verdict on an unusable item.
]]
local EVERY_CLASS =
	{ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" }

--[[
	/who and the mailbox are both same-faction, so a class the player's own side cannot
	roll is unreachable however well the item suits it. The faction pair is Era only:
	draenei shamans and blood elf paladins arrive in TBC.
]]
local ABSENT = {
	DEATHKNIGHT = function()
		return not ns.isWrathOrLater
	end,
	SHAMAN = function(faction)
		return ns.isEra and faction == "Alliance"
	end,
	PALADIN = function(faction)
		return ns.isEra and faction == "Horde"
	end,
}

--[[
	Memoized only once the faction is known: a cached nil would drop a real class for the session.
	Unresolved returns unfiltered and retries -- over-including is recoverable.
]]
local memo
local function ALL_CLASSES()
	if memo then
		return memo
	end
	local faction = UnitFactionGroup("player")
	local out = {}
	for _, class in ipairs(EVERY_CLASS) do
		local absent = ABSENT[class]
		if not (absent and absent(faction)) then
			out[#out + 1] = class
		end
	end
	if faction then
		memo = out
	end
	return out
end

function Matcher:Classes()
	return ALL_CLASSES()
end

--------------------------------------------------------------------------------
-- Hard Filter
--------------------------------------------------------------------------------

function Matcher:EligibleClasses(item)
	if item.kind == "consumable" then
		local classes = ns.Data.ConsumableClasses[item.def.restores]
		if classes == nil or classes == "ALL" then
			return ALL_CLASSES()
		end
		--[[
			ConsumableClasses is a client-agnostic roster of who has a mana bar, so returning it
			whole names the phantom classes described at the top of this file.
		]]
		local available = {}
		for _, cls in ipairs(ALL_CLASSES()) do
			available[cls] = true
		end
		local out = {}
		for _, cls in ipairs(classes) do
			if available[cls] then
				out[#out + 1] = cls
			end
		end
		return out
	end

	-- gear
	local out = {}
	local classID, subID, equipLoc = item.classID, item.subclassID, item.equipLoc

	if classID == 2 then
		-- Weapons: eligibility is "the priority lookup returned a group".
		local key = ns.Data.WeaponKey(item)
		if key then
			for _, cls in ipairs(ALL_CLASSES()) do
				if ns.Data.WeaponPriorityFor(key, cls, item.reqLevel) then
					table.insert(out, cls)
				end
			end
		end
		return out
	elseif classID == 4 then
		--[[
			Armor. Shields and held off-hands use the weapon matrix, and this must stay above the
			universal check below: held items are armor subclass 0, so that branch would otherwise
			claim them.
		]]
		if ns.Data.UsesWeaponMatrix(item) then
			local key = ns.Data.WeaponKey(item)
			for _, cls in ipairs(ALL_CLASSES()) do
				if key and ns.Data.WeaponPriorityFor(key, cls, item.reqLevel) then
					table.insert(out, cls)
				end
			end
			return out
		end
		-- Rings/necks/trinkets/cloaks/held: everyone, and no group -- stats alone decide.
		if ns.Data.UniversalEquipLoc[equipLoc] or subID == 0 then
			return ALL_CLASSES()
		end
		local armorType = ns.Data.ArmorSubclass[subID]
		if not armorType then
			return ALL_CLASSES()
		end -- unknown -> don't over-filter
		local priority = ns.Data.ArmorPriorityFor(armorType, item.reqLevel)
		if not priority then
			return ALL_CLASSES()
		end
		for _, cls in ipairs(ALL_CLASSES()) do
			if priority[cls] then
				table.insert(out, cls)
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
		return ns.Data.WeaponPriorityFor(ns.Data.WeaponKey(item), classToken, item.reqLevel) or 9
	end

	if item.classID ~= 4 then
		return 1
	end
	if ns.Data.UniversalEquipLoc[item.equipLoc] or item.subclassID == 0 then
		return 1
	end

	local armorType = ns.Data.ArmorSubclass[item.subclassID]
	local priority = armorType and ns.Data.ArmorPriorityFor(armorType, item.reqLevel)
	if not priority then
		return 1
	end

	return priority[classToken] or 9 -- unlisted = can't wear it at all
end

--------------------------------------------------------------------------------
-- Soft Score
--------------------------------------------------------------------------------

function Matcher:Score(item, classToken)
	-- Consumables aren't stat-scored; every eligible class wants them equally.
	if item.kind == "consumable" then
		return 1
	end

	local weights = ns.Data.StatWeights[classToken]
	if not weights then
		return 0
	end
	local score = 0
	for stat, val in pairs(item.stats or {}) do
		if weights[stat] then
			score = score + val * weights[stat]
		end
	end
	--[[
		An item-level baseline so statless weapons still place; shields and held off-hands take it
		too, being matrix-ranked everywhere else. Constant per item, so it shifts every admitted
		class equally and only decides whether the item clears the threshold. The GetItemInfo
		fallback is for a record built by hand rather than by the scanner.
	]]
	if ns.Data.UsesWeaponMatrix(item) then
		local ilvl = item.itemLevel or select(4, GetItemInfo(item.link)) or item.reqLevel or 1
		score = score + ilvl * (ns.Data.WEAPON_BASELINE or 0)
	end
	return score
end

--[[
	Claim: only the stats the point tables rank for this class -- no universal weight, no weapon
	baseline. It decides whether a class has any claim at all, separately from how it ranks, which
	is what makes universal weights safe to add: Stamina at 0.5 for everybody would otherwise give
	a mage 2.5 on an Agility cloak, none of it from the agility.
]]
function Matcher:SpecScore(item, classToken)
	if item.kind == "consumable" then
		return 1
	end
	local weights = ns.Data.StatWeights[classToken]
	if not weights then
		return 0
	end

	local universal = ns.Data.UniversalWeights or {}
	local score = 0
	for stat, val in pairs(item.stats or {}) do
		if weights[stat] and not universal[stat] then
			score = score + val * weights[stat]
		end
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
	competes on can say who competes: counting crit, defense or a resistance would put a
	rogue at 50% on his own gear and demote him off it.

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
	local weights = ns.Data.StatWeights[classToken]
	if not weights then
		return 0
	end
	local ranked = ns.Data.ScoreableStats()
	local total, used = 0, 0
	for stat, value in pairs(item.stats or {}) do
		if ranked[stat] then
			total = total + value
			if (weights[stat] or 0) > 0 then
				used = used + value
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
local function applyPreference(verdict, item)
	local preferred = ns.Data.PreferredClasses(item)
	if not preferred then
		return
	end
	local named = {}
	for _, cls in ipairs(preferred) do
		for _, admitted in ipairs(verdict.admitted) do
			if cls == admitted then
				named[#named + 1] = cls
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
	promote the classes coverage just demoted. The last resort exists for sub-40 mail and plate
	carrying Intellect, which has nobody in heavy armor behind a warrior.
]]
local function applyDemotion(verdict, item, scored)
	local demoted = ns.Data.DemotedClasses(item)
	if not demoted then
		return
	end

	local function without(list)
		local out = {}
		for _, cls in ipairs(list or {}) do
			if not demoted[cls] then
				out[#out + 1] = cls
			end
		end
		return out
	end

	for _, candidates in ipairs({ verdict.contenders, scored, verdict.admitted }) do
		local kept = without(candidates)
		if #kept > 0 then
			verdict.contenders = kept
			return
		end
	end
end

function Matcher:Verdict(item)
	local eligible = self:EligibleClasses(item)

	--[[
		Removed before scoring. See Data/Match-Rules.lua: the only veto is Spirit against warlocks,
		and it must outrank the Intellect a warlock genuinely wants, or "of the Owl" buys him back
		in through the half he can use.
	]]
	local vetoed = ns.Data.VetoedClasses(item)
	if vetoed and item.kind ~= "consumable" then
		local kept = {}
		for _, cls in ipairs(eligible) do
			if not vetoed[cls] then
				kept[#kept + 1] = cls
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
		-- This path returns before the scoring below, so the preference is applied here too.
		local scored = verdict.contenders
		applyPreference(verdict, item)
		applyDemotion(verdict, item, scored)
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
		Two scores per class: claim is what the point tables rank for them, fit adds universal
		weights and the weapon baseline. Claim decides who is admitted, fit how they rank.
	]]
	local anyClaim = false
	for _, cls in ipairs(eligible) do
		verdict.fits[cls] = self:Score(item, cls)
		verdict.claims[cls] = self:SpecScore(item, cls)
		if verdict.claims[cls] > verdict.bestClaim then
			verdict.bestClaim = verdict.claims[cls]
		end
		if verdict.claims[cls] > 0 then
			anyClaim = true
		end
	end

	--[[
		With no claim anywhere, only matrix-ranked items fall back to "offer it to everyone": a
		statless weapon's level baseline is a genuine universal claim, and the matrix already
		narrows shields and held off-hands to the classes that carry the type. Statless armor must
		not take the fallback -- with nothing to separate them, whoever is closest in level takes
		it. The unread case is gone by here, so this is armor that genuinely carries nothing.
	]]
	local offerToEveryone = (not anyClaim) and ns.Data.UsesWeaponMatrix(item)

	for _, cls in ipairs(eligible) do
		if offerToEveryone or verdict.claims[cls] > 0 then
			verdict.admitted[#verdict.admitted + 1] = cls
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
	for _, cls in ipairs(verdict.admitted) do
		local coverage = self:Coverage(item, cls)
		verdict.coverage[cls] = coverage
		if (verdict.claims[cls] or 0) >= shareOf then
			wanted[#wanted + 1] = cls
			if coverage > ns.Data.COVERAGE_MAJORITY then
				verdict.contenders[#verdict.contenders + 1] = cls
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

	-- The scoring's own answer, kept so applyDemotion can fall back through it.
	local scored = verdict.contenders
	applyPreference(verdict, item)
	applyDemotion(verdict, item, scored)

	--[[
		Best of the contenders, never of the admitted: the headline must come from the same set
		the recipient does. Equal scores -- all three cloth classes on Intellect -- break to
		whichever group is closer to the item's armor type.
	]]
	local bestScore, bestTier = -math.huge, 99
	for _, cls in ipairs(verdict.contenders) do
		local score, tier = verdict.fits[cls] or 0, self:Priority(item, cls)
		if score > bestScore or (score == bestScore and tier < bestTier) then
			bestScore, bestTier, verdict.best = score, tier, cls
		end
	end

	--[[
		Both gates, and the order matters. No admitted class means no recipient can ever
		exist, whatever the score says; the threshold is the player's own setting on top.
	]]
	if #verdict.admitted > 0 then
		verdict.score = (bestScore > -math.huge) and bestScore or 0
		if verdict.score >= ns.Data.LEFTOVER_THRESHOLD then
			verdict.state = Matcher.GIFT
		end
	end
	return verdict
end

-- Cached per scan; a record built outside one, such as the Verdict report, gets a fresh verdict.
function Matcher:VerdictFor(item)
	return item.verdict or self:Verdict(item)
end

-- There is deliberately no Matcher:Best. Read verdict.best and verdict.state instead.

--[[
	Everyone in pools (classToken -> players) who can use this item and sits in its level band, in
	the order it would be handed out:

	  fit bucket -> level proximity -> armor/weapon group -> class fit -> random

	Bucket leads, so a class that genuinely wants the item beats one that barely does however
	close to equipping it they are. Level comes next, ahead of group, so a druid one level off
	beats a mage two off for cloth. Random tail, or every spare green goes to whoever is early in
	the alphabet.
]]
function Matcher:RankCandidates(item, pools)
	local lo, hi = item.bandLo or 1, item.bandHi or 999
	local out, meta = {}, {}

	--[[
		Who may receive this is Verdict's answer, never a second opinion formed here; this only
		orders the people behind those classes. A leftover still ranks candidates so the dropdown
		can overrule the vendor pile by hand; an unreadable one lands here with an empty list.
	]]
	local verdict = self:VerdictFor(item)

	--[[
		Read from Verdict, never recomputed: it buckets on claim, and fit would let a universal
		weight compress the ratio and lift a druid past a rogue on proximity.
	]]
	local topBucket = {}
	for _, cls in ipairs(verdict.contenders or {}) do
		topBucket[cls] = true
	end

	--[[
		The level this item is worth most at, and what proximity is measured against. Gear anchors
		to the TOP of its band, arriving just before it can be equipped; a consumable anchors to
		the BOTTOM, its own use level, because its band runs upward from there. Measuring a potion
		to the top of its band ranks whoever has most outgrown it first, which is backwards.
	]]
	local anchor = (item.kind == "consumable") and lo or hi

	for _, cls in ipairs(verdict.admitted) do
		local fit, tier = verdict.fits[cls] or 0, self:Priority(item, cls)
		--[[
			Bucket rather than cut. A marginal class still appears in the dropdown and still
			receives the item when nobody better is in range.
		]]
		local bucket = topBucket[cls] and 1 or 2
		for _, person in ipairs(pools[cls] or {}) do
			if person.level >= lo and person.level <= hi then
				table.insert(out, person)
				meta[person] = { tier = tier, fit = fit, bucket = bucket }
			end
		end
	end

	table.sort(out, function(a, b)
		local ma, mb = meta[a], meta[b]
		if ma.bucket ~= mb.bucket then
			return ma.bucket < mb.bucket
		end
		local aDist = math.abs((a.level or 0) - anchor)
		local bDist = math.abs((b.level or 0) - anchor)
		if aDist ~= bDist then
			return aDist < bDist
		end
		if ma.tier ~= mb.tier then
			return ma.tier < mb.tier
		end
		if ma.fit ~= mb.fit then
			return ma.fit > mb.fit
		end
		--[[
			Soft priority for guildmates, last before the coin flip: everything above measures how
			well the item suits the person, so a guildmate never takes something from somebody it
			suits better. It still decides often -- tier and fit are per-class, so two candidates
			of the same class at the same level reach this line with nothing between them.
		]]
		local aGuild, bGuild = a.guild or false, b.guild or false
		if aGuild ~= bGuild then
			return aGuild
		end

		--[[
			Equals. The shuffle key is precomputed per player and never rolled inside the
			comparator: a comparator that changes mid-sort makes table.sort throw.
		]]
		local aRoll, bRoll = a.shuffle or 0, b.shuffle or 0
		if aRoll ~= bRoll then
			return aRoll < bRoll
		end
		return (a.name or "") < (b.name or "")
	end)
	return out
end

-- Recipient level band. Gear spans [reqLevel - WIDEST, reqLevel - CLOSEST].
function Matcher:LevelBand(item)
	--[[
		A consumable runs from its use level up by CONSUMABLE_RECIPIENT_GAP, short on purpose: a
		potion is worth having to somebody who can drink it now. Not profile.consumableLevelGap,
		which is the sender's outgrown-it threshold and a much longer span -- the note on the
		constant has why the two are not the same number.
	]]
	if item.kind == "consumable" then
		local lo = math.max(1, item.def.useLevel)
		return lo, lo + ns.Data.CONSUMABLE_RECIPIENT_GAP
	end
	local req = item.reqLevel or 1
	local lo = math.max(1, req - ns.Data.LEVEL_GAP_WIDEST)
	local hi = math.max(lo, req - ns.Data.LEVEL_GAP_CLOSEST)
	return lo, hi
end
