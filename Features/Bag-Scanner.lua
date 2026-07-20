local _, ns = ...

ns.Scanner = {}
local Scanner = ns.Scanner

local BOE_BINDTYPES = { [0] = true, [2] = true } -- 0 = no bind, 2 = Bind on Equip
local NUM_BAGS = 4 -- 0..4 (Classic Era: backpack + 4 bags, no reagent bag)
local CONSUMABLE_CLASS, WEAPON_CLASS, ARMOR_CLASS = 0, 2, 4 -- GetItemInfo classID

--[[
	Why a slot was passed over. Diagnostic identifiers read by the Bag Scan export, never
	shown to a player and never localized. They answer "why is this item not showing up", so
	a code that is merely true is not good enough: it has to be the actual reason.
]]
local REJECT = {
	EMPTY_SLOT = "EMPTY_SLOT",
	NOT_CACHED = "NOT_CACHED",
	CONSUMABLES_DISABLED = "CONSUMABLES_DISABLED",
	CONSUMABLE_NOT_LISTED = "CONSUMABLE_NOT_LISTED",
	LEVEL_GAP = "LEVEL_GAP",
	GEAR_DISABLED = "GEAR_DISABLED",
	WRONG_CLASS = "WRONG_CLASS",
	BELOW_MIN_RARITY = "BELOW_MIN_RARITY",
	ABOVE_MAX_RARITY = "ABOVE_MAX_RARITY",
	NOT_EQUIPPABLE = "NOT_EQUIPPABLE",
	BIND_ON_PICKUP = "BIND_ON_PICKUP",
	BIND_ON_USE = "BIND_ON_USE",
	QUEST_ITEM = "QUEST_ITEM",
	SOULBOUND = "SOULBOUND",
}
Scanner.REJECT = REJECT

--[[
	Bind on use gets its own code because those items are still fully tradeable: excluding
	them is this add-on's policy rather than the client's rule, and a code that says so keeps
	the decision reviewable.
]]
local BIND_REJECT = {
	[1] = REJECT.BIND_ON_PICKUP,
	[3] = REJECT.BIND_ON_USE,
	[4] = REJECT.QUEST_ITEM,
}

--[[
	One itemID -> definition lookup across every consumable table, built once, turning the
	data files' positional rows into named fields so nothing downstream indexes by number.

	Form travels with each row because what a consumable restores is not enough to say what
	it is: forty-odd Food-And-Water entries restore mana and every one is water, so "restores
	mana" alone would put mages behind priests for a bottle of water.
]]
local CONSUMABLE_TABLES = {
	{ table = "FoodAndWater", form = "FOOD" },
	{ table = "Potions", form = "POTION" },
}

local consumableByID
local function consumableIndex()
	if consumableByID then
		return consumableByID
	end
	consumableByID = {}
	for _, source in ipairs(CONSUMABLE_TABLES) do
		for _, row in ipairs(ns.Data[source.table]) do
			consumableByID[row[1]] = {
				id = row[1],
				quality = row[2],
				useLevel = row[3],
				restores = row[4],
				form = source.form,
			}
		end
	end
	return consumableByID
end

--[[
	GetItemStats first, then the tooltip overlaid. GetItemStats ignores an item's random
	suffix, so a rolled green comes back statless from it; ns.Tooltip reads the rendered item
	and sees the roll. Merged by max per stat, never sum: both report the same stat on a
	fixed-stat item and summing would double it.

	Each source's answer also comes back separately. The merge is lossy, so a report built
	from it alone cannot tell a working source from a dead one.
]]
local function normalizedStats(link)
	local api = {}
	for key, val in pairs(GetItemStats(link) or {}) do
		local token = ns.Data.StatMap[key]
		if token then
			api[token] = (api[token] or 0) + val
		end
	end

	local tooltip, source, lines, unread = ns.Tooltip:Stats(link)

	local out = {}
	for token, val in pairs(api) do
		out[token] = val
	end
	for token, val in pairs(tooltip) do
		if val > (out[token] or 0) then
			out[token] = val
		end
	end

	--[[
		Raw lines only when the tooltip parsed to nothing: that is the one case where "we failed
		to read a stat" and "there was no stat" look identical in the parsed table.
	]]
	local unparsed = next(tooltip) == nil and lines or nil

	--[[
		unread travels always: lines that looked like stats and resolved to no token are a gap
		in the name table, and an item can have that gap on one line while reading three
		cleanly.
	]]
	return out, { source = source, api = api, tooltip = tooltip, lines = unparsed, unread = unread }
end

--[[
	Which item this is, not what it is called: two "Ivycloth Robe" in different slots are two
	items, and everything acting on one specific item keys on this.

	Slot and link together, because neither alone holds -- a slot is reused the moment its
	item is mailed, and a link is shared by every copy of a plain item. Stable across a
	rescan, which is how a pairing survives one.
]]
local function itemUID(bag, slot, link)
	return ("%d:%d:%s"):format(bag or -1, slot or -1, link or "")
end

--[[
	The hard filter for one bag slot: everything except reading the item's stats. Local and
	deliberately incomplete -- a statless gear record reaching the matcher reads as a parse
	failure, so Scanner:Classify is the public way in and finishes the record first.
]]
local function filterSlot(bag, slot)
	local link = ns.GetItemLink(bag, slot)
	if not link then
		return nil, REJECT.EMPTY_SLOT
	end

	--[[
		One call, two shapes: C_Container returns a table, the legacy globals a positional list
		whose 2nd and 11th values are the count and bound flag. Both are read because the API is
		picked by availability -- drop the legacy shape and the soulbound check never fires
		there.
	]]
	local first, count, _, _, _, _, _, _, _, _, isBound = ns.GetItemInfoC(bag, slot)
	if type(first) == "table" then
		count, isBound = first.stackCount, first.isBound
	end

	local name, _, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID, bindType =
		GetItemInfo(link)
	if not name then
		-- Not in the client's item cache yet. Re-opening the bags resolves it.
		return nil, REJECT.NOT_CACHED
	end

	local iid = ns.GetInfoInstant(link)

	--[[
		Only once the player has outgrown it: at 45 the new water is trained and a level-35
		stack is spare, but at 40 it is still what they are drinking.
	]]
	local cdef = consumableIndex()[iid]
	if cdef then
		if not ns.db.profile.includeConsumables then
			return nil, REJECT.CONSUMABLES_DISABLED
		end
		local gap = ns.db.profile.consumableLevelGap
		if (UnitLevel("player") or 1) - cdef.useLevel < gap then
			return nil, REJECT.LEVEL_GAP
		end
		return {
			kind = "consumable",
			link = link,
			bag = bag,
			slot = slot,
			uid = itemUID(bag, slot, link),
			itemID = iid,
			name = name,
			count = count or 1,
			def = cdef,
		}
	end

	--[[
		Stops here, before the gear checks describe it as something it is not, and before the
		gear toggle, or a bandage scanned with gear off comes back GEAR_DISABLED.
	]]
	if classID == CONSUMABLE_CLASS then
		return nil, REJECT.CONSUMABLE_NOT_LISTED
	end

	--[[
		Weapons and armor only, as a positive check on classID. Do not relax to "has an equip
		slot" -- recipes carry one on this client, which puts crafting plans in the giftable
		list.
	]]
	if not ns.db.profile.includeGear then
		return nil, REJECT.GEAR_DISABLED
	end
	if classID ~= WEAPON_CLASS and classID ~= ARMOR_CLASS then
		return nil, REJECT.WRONG_CLASS
	end
	if quality < ns.db.profile.minRarity then
		return nil, REJECT.BELOW_MIN_RARITY
	end
	if quality > ns.db.profile.maxRarity then
		return nil, REJECT.ABOVE_MAX_RARITY
	end
	if not equipLoc or equipLoc == "" then
		return nil, REJECT.NOT_EQUIPPABLE
	end
	if not BOE_BINDTYPES[bindType or 0] then
		-- The fallback covers a bindType this table does not know, which we cannot vouch for.
		return nil, BIND_REJECT[bindType] or REJECT.BIND_ON_PICKUP
	end
	if isBound then
		return nil, REJECT.SOULBOUND
	end

	return {
		kind = "gear",
		link = link,
		bag = bag,
		slot = slot,
		uid = itemUID(bag, slot, link),
		itemID = iid,
		name = name,
		count = 1,
		quality = quality,
		reqLevel = reqLevel or 1,
		-- Read here rather than per eligible class: Matcher:Score folds it into every score.
		itemLevel = itemLevel,
		equipLoc = equipLoc,
		classID = classID,
		subclassID = subclassID,
	}
end

--[[
	The filter above with the item's stats read and attached. Returns the record, or nil plus
	the reject code -- a caller seeing only nil cannot tell "consumables are switched off" from
	"this is already soulbound", which is exactly what a player asks.
]]
function Scanner:Classify(bag, slot)
	local record, reason = filterSlot(bag, slot)
	if not record then
		return nil, reason
	end
	if record.kind == "gear" then
		--[[
			The expensive half: one tooltip per item. Bounded by what cleared the filter, and
			Mail-Window asks once per change, so it lands on the open that read the bags anyway.
		]]
		record.stats, record.statRead = normalizedStats(record.link)
	end
	return record
end

-- A gear record straight from a link, with no bag slot behind it. Used by the Item Verdict report.
function Scanner:Describe(link)
	local name, _, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = GetItemInfo(link)
	if not name then
		return nil
	end
	local stats, statRead = normalizedStats(link)
	return {
		kind = "gear",
		link = link,
		name = name,
		itemID = ns.GetInfoInstant(link),
		quality = quality,
		reqLevel = reqLevel or 1,
		itemLevel = itemLevel,
		equipLoc = equipLoc,
		classID = classID,
		subclassID = subclassID,
		stats = stats,
		statRead = statRead,
	}
end

--[[
	No Scanner:HasAny: the filter says a slot holds an unbound green, never that a class exists
	who can use it, so it cannot answer "is the window worth opening". Mail-Window reads
	verdicts.
]]

-- Scan all bags, return a flat list of giftable item records.
function Scanner:Scan()
	local items = {}
	for bag = 0, NUM_BAGS do
		local slots = ns.GetNumSlots(bag) or 0
		for slot = 1, slots do
			local rec = self:Classify(bag, slot)
			if rec then
				table.insert(items, rec)
			end
		end
	end
	return items
end

--[[
	Every occupied bag slot with its record or its reason code, for the Bag Scan export, where
	the rejected rows are the point. Empty slots are left out: not a rejection, only padding.
]]
function Scanner:ScanAll()
	local rows = {}
	for bag = 0, NUM_BAGS do
		local slots = ns.GetNumSlots(bag) or 0
		for slot = 1, slots do
			local record, reason = self:Classify(bag, slot)
			if record or reason ~= REJECT.EMPTY_SLOT then
				table.insert(rows, {
					bag = bag,
					slot = slot,
					link = ns.GetItemLink(bag, slot),
					item = record,
					reason = reason,
				})
			end
		end
	end
	return rows
end
