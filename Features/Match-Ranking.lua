local _, ns = ...

local Matcher = ns.Matcher

-- Who gets an item and where to look for them, read off the verdict Features/Match-Engine.lua decides.

--------------------------------------------------------------------------------
-- Candidate Ranking
--------------------------------------------------------------------------------

--[[
	Everyone in pools (classToken -> players) who can use this item and sits in its level band, in
	the order it would be handed out:

	  fit bucket -> level proximity -> armor/weapon group -> class fit -> guild -> random

	Bucket leads, so a class that genuinely wants the item beats one that barely does however
	close to equipping it they are. Level comes next, ahead of group, so a druid one level off
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
		Read from Verdict, never recomputed: it buckets on claim, and fit would let a universal
		weight compress the ratio and lift a druid past a rogue on proximity.
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
	for _, class in ipairs(verdict.admitted) do
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
			if person.level >= lo and person.level <= hi then
				table.insert(out, person)
				meta[person] = { tier = tier, fit = fit, bucket = bucket, anchor = anchor }
			end
		end
	end

	table.sort(out, function(a, b)
		local ma, mb = meta[a], meta[b]
		if ma.bucket ~= mb.bucket then
			return ma.bucket < mb.bucket
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
	the way Features/Recipients-Who.lua wants a plan, so the query looking for the hunter can ask
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
	The bands one targeted search should ask for, best first: the classes the verdict says the item
	is FOR, then everybody admitted behind them.

	CONTENDERS LEAD. A lone contender is the only shape /who can be filtered on --
	the client honors one c-"..." and drops the rest -- so leading with it is what turns this into
	a query for hunters instead of the unfiltered one the main button already sent. The fallbacks
	keep their own group behind it and are still asked for, one press later.
]]
function Matcher:TargetedBands(item)
	local verdict = self:VerdictFor(item)
	local admitted = (#verdict.admitted > 0) and verdict.admitted or verdict.eligible
	local contenders = (#(verdict.contenders or {}) > 0) and verdict.contenders or admitted

	local leads = {}
	for _, class in ipairs(contenders) do
		leads[class] = true
	end
	local behind = {}
	for _, class in ipairs(admitted) do
		if not leads[class] then
			behind[#behind + 1] = class
		end
	end

	local groups = self:BandGroups(item, contenders)
	for _, group in ipairs(self:BandGroups(item, behind)) do
		--[[
			Folded back into the leaders' group when they share a band and there is more than one
			of them: two classes carry no class filter either way, so a separate group would spend
			a whole press on a query identical to the one in front of it.
		]]
		local merged
		for _, lead in ipairs(groups) do
			if lead.lo == group.lo and lead.hi == group.hi and #lead.classes > 1 then
				merged = lead
				break
			end
		end
		if merged then
			for _, class in ipairs(group.classes) do
				merged.classes[#merged.classes + 1] = class
			end
		else
			groups[#groups + 1] = group
		end
	end
	return groups
end
