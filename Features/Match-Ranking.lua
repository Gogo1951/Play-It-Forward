local _, ns = ...

local Matcher = ns.Matcher

-- Who gets an item and where to look for them, read off the verdict Features/Match-Engine.lua decides.

--------------------------------------------------------------------------------
-- Candidate Ranking
--------------------------------------------------------------------------------

--[[
	Where a candidate came from: 1 your alts, 2 your guild, 3 strangers from /who. The picker's
	sections, which name the source whatever the Recipients panel says about ranking it.
]]
function Matcher:Source(person)
	if person.alt then
		return 1
	end
	if person.guild then
		return 2
	end
	return 3
end

--[[
	The same three, as the sort and the targeted search's stopping rule weigh them: a source whose
	Prioritize switch on the Recipients panel is off ranks as a stranger, so it competes on fit,
	placement and level instead of jumping the queue. An alt who is also a guildmate falls back to
	the guild's rank when only the alts switch is off.
]]
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

--[[
	A stranger warlock in the band summoning alts park in, while the Recipients panel's Ignore
	Warlocks switch is on. Strangers only: an alt is yours, and the guild roster has its own rule.
]]
local function SkippedSummoner(person)
	local profile = ns.db and ns.db.profile
	if not (profile and profile.ignoreSummonerWarlocks) or person.alt or person.guild then
		return false
	end
	local level = person.level or 0
	return person.class == "WARLOCK" and level >= ns.Data.SUMMONER_MIN_LEVEL and level <= ns.Data.SUMMONER_MAX_LEVEL
end

--[[
	Whether one of your alts may receive this item, by its row on the My Alts panel, and
	its fit when it may. Only where the item suits the alt best, JUDGED BY THE ALT'S OWN SPECS: a
	retribution paladin alt holds strength plate though paladins default to Holy, and a mage alt
	never holds healing cloth meant for a priest. A consumable asks only the class.

	Gear is judged against the alt's own Lowest and Highest Gear Level (Alts:LevelRange), by the
	level its class equips it at: at the defaults, anything from its own level up, so a level 1
	hunter holds a level 50 bow. A consumable puts the alt in the same band as anyone else.
]]
local function AltWants(matcher, item, verdict, person, classToken, lo, hi)
	local profile = ns.db and ns.db.profile
	local entry = ns.Alts:Entry(person)
	if not (profile and profile.sendToAlts) or (entry and not ns.Alts:Included(entry)) then
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
	if item.kind ~= "consumable" then
		local equip = ns.Data.EquipLevelFor(item, classToken)
		local low, high = ns.Alts:LevelRange(entry, person.level)
		return equip >= low and equip <= high, fit
	end
	return person.level >= lo and person.level <= hi, fit
end

--[[
	Everyone in pools (classToken -> players) who can use this item and sits in its level band, in
	the order it would be handed out:

	  fit bucket -> source -> placement -> level proximity -> armor/weapon group -> class fit -> random

	Bucket leads, so a class that genuinely wants the item beats one that barely does however
	close to equipping it they are. Source follows, among equally good fits only: your alts, then
	your guild, then strangers (Matcher:SourceRank). Placement follows: somebody out in a zone made
	for their level beats somebody in a capital, and anybody beats somebody in a dungeon
	(Who:PlacementRank). Both follow the Recipients panel's switches. Level comes next, ahead of group, so a druid one level off
	beats a mage two off for cloth. Random tail, or every spare green goes to whoever is early in
	the alphabet.
]]
function Matcher:RankCandidates(item, pools)
	local out, meta = {}, {}

	--[[
		Who may receive this is Verdict's answer, never a second opinion formed here; this only
		orders the people behind those classes. A leftover still ranks candidates so the dropdown
		can overrule the vendor pile by hand; an unreadable one lands here with an empty list.
	]]
	local verdict = self:VerdictFor(item)

	--[[
		Read from Verdict, never recomputed: it buckets on claim, and fit adds the weapon baseline,
		which would compress the ratio and lift a weaker class past a stronger one on proximity.
	]]
	local topBucket = {}
	for _, class in ipairs(verdict.contenders or {}) do
		topBucket[class] = true
	end

	--[[
		PER CLASS, NEVER item.bandLo: a class that trains the armor material later searches higher
		up, and reading one band off the item would either hand a hunter mail he cannot wear for
		six levels or never look for him at all. Matcher:LevelBand answers the item's own band for
		everything else, so this is the same numbers for nearly every item.
	]]
	--[[
		Every admitted class, plus any class one of your alts plays: an alt is judged by its own
		specs, so it can want an item the class's defaults never admitted.
	]]
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
		local lo, hi = self:LevelBand(item, class)
		--[[
			The level this item is worth most at, and what proximity is measured against. Gear
			anchors to the TOP of its band, arriving just before it can be equipped; a consumable
			anchors to the BOTTOM, its own use level, because its band runs upward from there.
			Measuring a potion to the top of its band ranks whoever has most outgrown it first,
			which is backwards.
		]]
		local anchor = (item.kind == "consumable") and lo or hi
		--[[
			Bucket rather than cut. A marginal class still appears in the dropdown and still
			receives the item when nobody better is in range.
		]]
		local bucket = topBucket[class] and 1 or 2
		for _, person in ipairs(pools[class] or {}) do
			local inRange, personFit, personBucket = false, fit, bucket
			if SkippedSummoner(person) then
				inRange = false
			elseif person.alt then
				local altFit
				inRange, altFit = AltWants(self, item, verdict, person, class, lo, hi)
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
		--[[
			Who they are to you, among equally good fits: an alt before a guildmate before a
			stranger. Behind the bucket, never ahead of it, so a priest stranger still takes healing
			cloth from a mage alt who only barely wants it.
		]]
		local aSource, bSource = self:SourceRank(a), self:SourceRank(b)
		if aSource ~= bSource then
			return aSource < bSource
		end
		--[[
			Where they stand, right behind who the item is for: out in a zone made for their level
			beats a capital, because that is the evidence they are levelling and will use it, and a
			dungeon ranks last, where they may be getting boosted. Ahead of level, which only splits
			a band two levels wide.
		]]
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

--------------------------------------------------------------------------------
-- Level Bands
--------------------------------------------------------------------------------

--[[
	Recipient level band. Gear spans [equip level - WIDEST, equip level - CLOSEST].

	WITH A CLASS IT IS THAT CLASS'S BAND, and for nearly every item the two are the same answer:
	the equip level is the item's own requirement. It moves only where the class has to train the
	armor material first -- a level 36 mail belt is equipped at 40 by a hunter and at 36 by a
	paladin, so the two search 38-39 and 34-35 and one band cannot state both. Called without a
	class it answers for the item alone, which is what the reports and the tooltip want.
]]
function Matcher:LevelBand(item, classToken)
	--[[
		A consumable runs from its use level up by CONSUMABLE_RECIPIENT_GAP, short on purpose: a
		potion is worth having to somebody who can drink it now. Not profile.consumableLevelGap,
		which is the sender's outgrown-it threshold and a much longer span -- the note on the
		constant has why the two are not the same number. No class shift: nothing is trained to
		drink one.
	]]
	if item.kind == "consumable" then
		local lo = math.max(1, item.def.useLevel)
		return lo, lo + ns.Data.CONSUMABLE_RECIPIENT_GAP
	end
	local req = classToken and ns.Data.EquipLevelFor(item, classToken) or (item.reqLevel or 1)
	local lo = math.max(1, req - ns.Data.LEVEL_GAP_WIDEST)
	local hi = math.max(lo, req - ns.Data.LEVEL_GAP_CLOSEST)
	return lo, hi
end

--[[
	The classes grouped by the band each of them searches -- one group for nearly every item, two
	for the sub-40 mail and plate half the field cannot wear until it trains the material. Shaped
	the way Features/Recipients-Who-Plan.lua wants a plan, so the query looking for the hunter can ask
	38-39 while the one beside it asks the paladin's 34-35.

	Group order follows the class list it was given, which is what lets a caller put the classes
	the item is FOR at the front of the plan.
]]
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

--[[
	Every band the item searches, as one span. For the tooltip and the reports, which have room
	for one pair of numbers; the search itself uses the groups above and never this. Falls back to
	the item's own band when no class was passed, so an item nobody is admitted for still reads.
]]
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

--[[
	The classes one targeted search asks for, best first: the contenders the verdict says the item
	is FOR, then everybody admitted behind them. Each half sorts the way RankCandidates breaks a
	level tie -- armor group, then fit -- so the class most likely to take the row is asked
	first: on "of the Bear" plate, the warrior ahead of the paladin, who ranks only part of it.
]]
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
	The bands one targeted search should ask for, best first: ONE CLASS PER GROUP, in the order
	TargetedClasses puts them. A lone class is the only shape /who can be filtered on -- the
	client honors one c-"..." and drops the rest -- and a class filter reaches everybody of that
	class wherever they stand, where a zone filter misses anyone in a dungeon, a battleground or
	a zone the table does not list. Observed live (2026-10-10): a 54 warrior in Sunken Temple, the
	best fit for a pair of "of the Bear" gauntlets, never turned up while the search asked the
	unfiltered zones its two plate contenders shared.

	A consumable keeps its classes in one group: every class wants it equally, so splitting by
	class orders nothing and only multiplies the presses.
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

-- The level RankCandidates measures this class's proximity against: the top of its band for gear, the bottom for a consumable.
local function AnchorFor(matcher, item, classToken)
	local lo, hi = matcher:LevelBand(item, classToken)
	return (item.kind == "consumable") and lo or hi
end

--[[
	Whether somebody of this class, standing at that class's own anchor, would sort ahead of
	person under RankCandidates: bucket, then source, then placement, then distance from each one's
	own anchor, then group, then fit. A tie never outranks -- past it only the coin flip is left. A
	class the verdict did not admit never ranks at all; nobody holding the row is outranked by
	every class that did.

	What a targeted search stops on: an attempt for a class that cannot outrank the holder can
	only turn up somebody who ties or loses, and is not worth a press.
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
	local heldBucket = contenders[person.class] and 1 or 2
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
