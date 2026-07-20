local _, ns = ...

ns.Matcher = {}
local Matcher = ns.Matcher

--[[
	Every class in the game. ALL_CLASSES below filters it to the ones that can exist for
	this player, and a phantom class is not a harmless extra name: Verdict breaks a tied
	score on the lowest priority group, so a death knight (group 1 for two-handers, where
	a warrior is group 3) takes the headline verdict on an item nobody can receive.
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
	Memoized only once the faction is known: a nil UnitFactionGroup cached at file scope
	would silently drop a real class for the whole session, so an unresolved faction
	returns the unfiltered list and tries again. Over-including is recoverable.
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
-- Data Derivations
--------------------------------------------------------------------------------

--[[
	Every stat some class ranks. Derived from the weight tables rather than listed, so a
	stat added there appears here without a second edit, and built on first use so file
	order is not load-bearing.
]]
local scoreable
function ns.Data.ScoreableStats()
	if scoreable then
		return scoreable
	end
	scoreable = {}
	for _, weights in pairs(ns.Data.StatWeights) do
		for stat, points in pairs(weights) do
			if points and points > 0 then
				scoreable[stat] = true
			end
		end
	end
	return scoreable
end

--[[
	Priority group = (class's native armor) - (item's armor) + 1. A class whose native
	armor is lighter cannot wear the item at all, so plate under 40 lists nobody. Native
	armor is level-dependent: hunters and shamans are in leather until 40, warriors and
	paladins in mail. No ordering inside a group.
]]
local armorCache = {}

function ns.Data.ArmorPriorityFor(armorType, reqLevel)
	local WEIGHT = ns.Data.ArmorWeight
	local itemWeight = WEIGHT[armorType]
	if not itemWeight then
		return nil
	end

	local level = reqLevel or 1
	armorCache[armorType] = armorCache[armorType] or {}
	if armorCache[armorType][level] then
		return armorCache[armorType][level]
	end

	local out = {}
	for class, nativeFor in pairs(ns.Data.NativeArmor) do
		local classWeight = WEIGHT[nativeFor(level) or ""]
		if classWeight and classWeight >= itemWeight then
			out[class] = classWeight - itemWeight + 1
		end
	end

	armorCache[armorType][level] = out
	return out
end

-- Index the columns once so lookups aren't a linear scan.
local COLUMN = {}
for i, class in ipairs(ns.Data.WeaponClassOrder) do
	COLUMN[class] = i
end

--[[
	Priority group for a class on a weapon type, or nil when they cannot use it.
	Eligibility is "did this return a number", so a level rule cannot apply to the
	grouping and be missed by the eligibility check.
]]
function ns.Data.WeaponPriorityFor(weaponKey, classToken, reqLevel)
	local counts = ns.Data.WeaponSpecs[weaponKey]
	local column = COLUMN[classToken]
	if not counts or not column then
		return nil
	end

	local specs = counts[column] or 0
	if specs <= 0 then
		return nil
	end

	local gates = ns.Data.WeaponMinLevel[classToken]
	local minLevel = gates and gates[weaponKey]
	if minLevel and (reqLevel or 1) < minLevel then
		return nil
	end

	return 4 - specs
end

--[[
	Blizzard's weapon subclass does not distinguish 1H from 2H swords, maces or axes;
	equipLoc does. INVTYPE_2HWEAPON resolves to the 2H variant, everything else to 1H.
]]
ns.Data.ResolveHandedness = function(key, equipLoc)
	local twoH = (equipLoc == "INVTYPE_2HWEAPON")
	if key == "1H_SWORD" or key == "2H_SWORD" then
		return twoH and "2H_SWORD" or "1H_SWORD"
	end
	if key == "1H_MACE" or key == "2H_MACE" then
		return twoH and "2H_MACE" or "1H_MACE"
	end
	if key == "1H_AXE" or key == "2H_AXE" then
		return twoH and "2H_AXE" or "1H_AXE"
	end
	return key
end

--[[
	Ranked by the weapon matrix rather than by armor material: weapons, plus shields and
	held off-hands, which compete for a slot rather than for a material.

	Do not replace this with "does WeaponKey return something". WeaponKey falls through to
	the weapon subclass table for anything it does not recognize, and armor subclass 1
	(cloth) collides with weapon subclass 1 (two-hand axe), so a cloth chest answers
	"2H_AXE" and would take the weapon fallback.
]]
function ns.Data.UsesWeaponMatrix(item)
	if item.classID == 2 then
		return true
	end
	return item.classID == 4 and (item.subclassID == 6 or item.equipLoc == "INVTYPE_HOLDABLE")
end

-- The weapon key for an item, resolving handedness. Cached on the item.
function ns.Data.WeaponKey(item)
	if item._weaponKey then
		return item._weaponKey
	end
	if item.classID == 4 then
		if item.subclassID == 6 then
			item._weaponKey = "SHIELD"
			return "SHIELD"
		end
		if item.equipLoc == "INVTYPE_HOLDABLE" then
			item._weaponKey = "HELD"
			return "HELD"
		end
	end
	local key = ns.Data.WeaponSubclass[item.subclassID]
	if not key then
		return nil
	end
	key = ns.Data.ResolveHandedness(key, item.equipLoc)
	item._weaponKey = key
	return key
end

--[[
	Does an item carry every stat a rule asks for, and for an exclusive rule, nothing else
	anybody ranks? Unranked stats do not count against exclusivity: armor and resistances
	sit on half the items in the game, so counting them would make a bare Stamina ring
	qualify where a bare Stamina chest does not.
]]
local function matches(rule, item)
	local def = item.def

	-- classID == 2 first: cloth collides with 2H axe, see UsesWeaponMatrix above.
	if rule.weapon then
		if item.classID ~= 2 then
			return false
		end
		local key = ns.Data.WeaponKey(item)
		for _, wanted in ipairs(rule.weapon) do
			if key == wanted then
				return true
			end
		end
		return false
	end

	if rule.form or rule.restores then
		if not def or def.form ~= rule.form then
			return false
		end
		local wanted = false
		for _, restores in ipairs(rule.restores or {}) do
			if def.restores == restores then
				wanted = true
			end
		end
		return wanted
	end
	if not rule.requires then
		return false
	end

	local stats = item.stats or {}
	for _, token in ipairs(rule.requires) do
		if (stats[token] or 0) <= 0 then
			return false
		end
	end

	if not rule.exclusive then
		return true
	end

	local required = {}
	for _, token in ipairs(rule.requires) do
		required[token] = true
	end
	local ranked = ns.Data.ScoreableStats()
	for token, value in pairs(stats) do
		if not required[token] and ranked[token] and (value or 0) > 0 then
			return false
		end
	end
	return true
end

--[[
	Classes no rule will let this item reach. Applied before anything is scored, so a
	vetoed class is gone from every answer downstream rather than filtered out of some.
]]
function ns.Data.VetoedClasses(item)
	local out = nil
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.veto and matches(rule, item) then
			out = out or {}
			for _, class in ipairs(rule.veto) do
				out[class] = true
			end
		end
	end
	return out
end

--[[
	Classes that must not lead on this item, though they may still receive it. Collected
	from every matching rule rather than the first, exactly as the vetoes are: a demotion
	is a statement about one class and one stat, and two can be true of the same item.
]]
function ns.Data.DemotedClasses(item)
	local out = nil
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.demote and matches(rule, item) then
			out = out or {}
			for _, class in ipairs(rule.demote) do
				out[class] = true
			end
		end
	end
	return out
end

--[[
	The classes the first matching rule names, or nil when no rule applies and the point
	tables should decide on their own.
]]
function ns.Data.PreferredClasses(item)
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.prefer and matches(rule, item) then
			return rule.prefer, rule.name
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Hard Filter
--------------------------------------------------------------------------------

-- Which classes can use this item at all.
function Matcher:EligibleClasses(item)
	-- A consumable's classes come from what it restores; ConsumableClasses is the mapping.
	if item.kind == "consumable" then
		local classes = ns.Data.ConsumableClasses[item.def.restores]
		if classes == nil or classes == "ALL" then
			return ALL_CLASSES()
		end
		--[[
			Filtered through the available list like everything else. ConsumableClasses is a
			plain roster of who has a mana bar, written without reference to any client, so
			returning it whole names the phantom classes the note at the top of this file
			describes for gear.
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
		-- Weapons: eligibility is "the priority lookup returned a group", never a second test.
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
			Armor. Shields and held off-hand items use the weapon-style matrix. This must stay
			above the universal check below: held items are armor subclass 0, so that branch
			would otherwise claim them.
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
		-- Real armor: only classes the priority spec lists for this type at this level.
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
	Which priority group a class sits in for this item. Group 1 is the item's natural
	home: the class that natively wears that armor, or whose every spec builds around
	that weapon. Rings, necks, trinkets and cloaks deliberately have no group -- everyone
	is group 1 and the stat weights alone decide, which is how an agility ring finds a
	rogue.
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

-- How much a given class wants this item.
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
		Weapons get a small item-level baseline so statless weapons still place, and shields
		and held off-hand items take it too -- they are ranked by the weapon matrix
		everywhere else.

		The baseline is a constant per item, so it shifts every admitted class equally and
		cannot reorder them. It only decides whether the item clears the threshold at all.

		Read off the record, which resolved the level once when the item was built. The
		GetItemInfo fallback is for a record built by hand rather than by the scanner.
	]]
	if ns.Data.UsesWeaponMatrix(item) then
		local ilvl = item.itemLevel or select(4, GetItemInfo(item.link)) or item.reqLevel or 1
		score = score + ilvl * (ns.Data.WEAPON_BASELINE or 0)
	end
	return score
end

--[[
	Claim: only the stats the point tables rank for this class, with no universal weight
	and no weapon baseline. It decides whether a class has any claim at all, separately
	from how it ranks, which is what makes a universal weight safe to add -- Stamina at
	0.5 for everybody would otherwise give a mage 2.5 on an Agility cloak, none of it from
	the agility. Claim ignores those weights, so they can only ever break a tie.
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
	How much of an item a class actually uses, 0 to 1. Score sums, so breadth loses to a
	single large weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0,
	an exact tie the warrior wins with half the item dead on him. Coverage separates using
	an item from using part of one.

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
	What happens to an item, decided in one place; every other answer derives from this.
	An item is only a gift when at least one class was admitted, because admitted classes
	are exactly who RankCandidates draws from. "Admitted" is about classes, never about
	who /who has found: judging on the live roster would put every item in the vendor pile
	before the first query.

	  gift        a class was admitted and the best of them clears the threshold
	  leftover    read fine, nobody wants it, or it scores under the threshold
	  unreadable  its stats could not be read, so neither verdict is trustworthy

	The third exists because merging it into leftover tells the player to vendor or
	disenchant an item nobody evaluated, and disenchanting is not reversible. Held out of
	auto-assignment for the same reason.
]]
Matcher.GIFT, Matcher.LEFTOVER, Matcher.UNREADABLE = "gift", "leftover", "unreadable"

--[[
	A rule that names its own class replaces the contenders rather than adding to them:
	"an owl staff is for priests, mages and druids" is a statement about who it is for,
	and leaving a shaman in because the point tables liked his Intellect is what the rule
	exists to overrule.

	Narrowed only to classes already admitted, so a rule naming nobody reachable leaves
	the weights to it rather than stranding the item. Admission is untouched, which is
	what makes a rule soft: an owl staff still reaches a hunter when nobody else is there.
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
	Drop the classes a rule says must not lead, keeping them admitted as fallbacks. Runs
	after the preference above so a rule cannot promote a demoted class back -- the case
	it exists for is an Intellect dagger, which matches the dagger rule and names the
	rogue, who is exactly who should not lead on Intellect.

	IT FALLS BACK THROUGH THE SCORING, NOT PAST IT. When demoting the contenders leaves
	nobody, the next answer is what coverage and the class share had already agreed on;
	only when that is empty too does the wider admitted list get a turn, and only then do
	the demoted keep it. Reaching straight for the admitted list would promote the classes
	coverage just demoted, by the very step meant to demote somebody else.

	The last resort exists for sub-40 mail and plate carrying Intellect, which has nobody
	in heavy armor behind a warrior.
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
		Removed before anything is scored. See Data/Item-Rules.lua: the only veto is Spirit
		against warlocks, and it has to outrank the Intellect a warlock genuinely does
		want, or an "of the Owl" roll buys him back in through the half he can use.
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

	--[[
		Consumables aren't stat-scored; every eligible class wants them equally, so every
		one of them is in contention and best is a representative rather than a ranking.
	]]
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
		Nothing read off a suffixed item means the parse failed, not that the item is bare:
		a rolled green carries every stat it has in that suffix. Decided before scoring,
		because a score on an unread item looks like a judgement and is not one.
	]]
	if ns.ItemSuffixID(item.link) and next(item.stats or {}) == nil then
		verdict.state = Matcher.UNREADABLE
		return verdict
	end

	--[[
		Two scores per class. Claim is what the point tables actually rank for them; fit
		adds any universal weight and the weapon baseline. Claim decides who is admitted,
		fit how they rank.
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
		With no claim anywhere, only matrix-ranked items fall back to "offer it to
		everyone": a statless weapon is a real item and its level baseline is a genuine
		universal claim, and the matrix already narrows shields and held off-hands to the
		classes that carry the type.

		Statless armor proper must not take the fallback -- with no stats to separate
		them, whoever is closest in level takes it. The unread case is already gone by
		here, so this is armor that genuinely carries nothing.
	]]
	local offerToEveryone = (not anyClaim) and ns.Data.UsesWeaponMatrix(item)

	for _, cls in ipairs(eligible) do
		if offerToEveryone or verdict.claims[cls] > 0 then
			verdict.admitted[#verdict.admitted + 1] = cls
		end
	end

	--[[
		Who is in the running, which is not verdict.best: best is the single highest
		(fit, tier) class, while every class in the top bucket can receive the item.
		Resolved here rather than in RankCandidates so the report and the ordering cannot
		drift.

		Two tests answering two questions. The share asks whether a class wants it enough
		to compete (magnitude); coverage asks whether it uses the item or only part of one
		(breadth), which scoring cannot see, since a warrior ties a paladin on
		Strength-plus-Intellect by scoring the Strength twice as hard. Failing either
		leaves a class admitted, still in the dropdown and still a fallback.
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
		Coverage abstains when it demotes everyone, exactly as it returns 1 for an item
		with nothing scoreable. It is a relative test, so a field where nobody clears it
		carries no information: an Agility and Spell Power roll, where the rogue ranks one
		half and the mage the other, is still worth sending to one of them.
	]]
	if #verdict.contenders == 0 then
		verdict.contenders = wanted
	end

	-- The scoring's own answer, kept so applyDemotion can fall back through it.
	local scored = verdict.contenders
	applyPreference(verdict, item)
	applyDemotion(verdict, item, scored)

	--[[
		The best of the contenders, never of the admitted: the headline has to be drawn
		from the same set the recipient is. An equal score, which all three cloth classes
		have on Intellect, breaks to whichever group is closer to the item's armor type.
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

--[[
	The verdict for an item, computed once per scan and cached on it. Callers that build
	an item record outside a scan, such as the single-item Verdict report, get a fresh one.
]]
function Matcher:VerdictFor(item)
	return item.verdict or self:Verdict(item)
end

-- There is deliberately no Matcher:Best. Read verdict.best and verdict.state instead.

--[[
	Everyone in pools (classToken -> players) who can use this item and sits in its level
	band, in the order it would be handed out:

	  fit bucket -> level proximity -> armor/weapon group -> class fit -> random

	Bucket leads, so a class that genuinely wants the item beats one that barely does
	however close to equipping it they are. Level comes next, ahead of the group, so a
	druid one level off beats a mage two levels off for cloth; group then breaks ties
	between people at the same level. The tail is random rather than alphabetical, or
	every spare green goes to whoever is early in the alphabet.
]]
function Matcher:RankCandidates(item, pools)
	local lo, hi = item.bandLo or 1, item.bandHi or 999
	local out, meta = {}, {}

	--[[
		Who may receive this is Verdict's answer, never a second opinion formed here; this
		orders the people behind those classes. A leftover still ranks candidates so the
		dropdown can overrule the vendor pile by hand; an unreadable item admits nobody and
		lands here with an empty list.
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

	for _, cls in ipairs(verdict.admitted) do
		local fit, tier = verdict.fits[cls] or 0, self:Priority(item, cls)
		--[[
			Bucket rather than cut. A marginal class still appears in the dropdown and still
			receives the item when nobody better is in range, so a bow does not go unsent
			because no hunter happened to be online.
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
		local aDist = math.abs((a.level or 0) - hi)
		local bDist = math.abs((b.level or 0) - hi)
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
		A consumable runs from its useLevel up by the same gap that decides whether the sender
		has outgrown it, so the two stay symmetric by construction.
	]]
	if item.kind == "consumable" then
		local lo = math.max(1, item.def.useLevel)
		return lo, lo + ns.db.profile.consumableLevelGap
	end
	local req = item.reqLevel or 1
	local lo = math.max(1, req - ns.Data.LEVEL_GAP_WIDEST)
	local hi = math.max(lo, req - ns.Data.LEVEL_GAP_CLOSEST)
	return lo, hi
end
