local _, ns = ...
local L = ns.L

ns.Scanner = {}
local Scanner = ns.Scanner

ns.Bags = ns.Bags or {}
local Bags = ns.Bags

-- Only these items' arriving info can change a scan; GET_ITEM_INFO_RECEIVED fires for every item loaded.
local pendingItems = {}

function Scanner:IsPending(itemID)
	return itemID ~= nil and pendingItems[itemID] == true
end

local BOE_BINDTYPES = { [0] = true, [2] = true } -- 0 = no bind, 2 = Bind on Equip
local NUM_BAGS = 4 -- 0..4 (Classic Era: backpack + 4 bags, no reagent bag)
local CONSUMABLE_CLASS, WEAPON_CLASS, ARMOR_CLASS = 0, 2, 4 -- GetItemInfo classID

-- For the Bag Scan export: never shown or localized, and always the actual reason, not one merely true.
local REJECT = {
	EMPTY_SLOT = "EMPTY_SLOT",
	NOT_CACHED = "NOT_CACHED",
	CONSUMABLES_DISABLED = "CONSUMABLES_DISABLED",
	KIND_DISABLED = "KIND_DISABLED",
	CONSUMABLE_NOT_LISTED = "CONSUMABLE_NOT_LISTED",
	NO_USE_LEVEL = "NO_USE_LEVEL",
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
	REPUTATION_LOCKED = "REPUTATION_LOCKED",
	NEVER_GIVE = "NEVER_GIVE",
	KEEP_IN_BAGS = "KEEP_IN_BAGS",
}
Scanner.REJECT = REJECT

-- Bind on use stays tradeable: excluding it is this add-on's policy, so it gets its own code.
local BIND_REJECT = {
	[1] = REJECT.BIND_ON_PICKUP,
	[3] = REJECT.BIND_ON_USE,
	[4] = REJECT.QUEST_ITEM,
}

--[[
	KINDS ARE NOT FORM. Form is the source table, which item rules match on ("restores mana" alone
	would make water a potion). Kinds are the player's switches: mana food is drink, both is both.
]]
local FOOD_KINDS = { MANA = { "DRINK" }, BOTH = { "FOOD", "DRINK" } }

-- kinds is a list, or for food a lookup by what the row restores, with the list beside it as the fallback.
local CONSUMABLE_TABLES = {
	{ table = "FOOD_AND_WATER", form = "FOOD", effect = "restores", kinds = { "FOOD" }, kindsBy = FOOD_KINDS },
	{ table = "POTIONS", form = "POTION", effect = "restores", kinds = { "POTION" } },
	{ table = "SCROLLS", form = "SCROLL", effect = "buffs", kinds = { "SCROLL" } },
	{ table = "OILS_AND_STONES", form = "OIL_STONE", effect = "enhances", kinds = { "OIL_STONE" } },
}

local consumableByID
local function ConsumableIndex()
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
				[source.effect] = row[4],
				form = source.form,
				kinds = (source.kindsBy and source.kindsBy[row[4]]) or source.kinds,
			}
		end
	end
	return consumableByID
end

-- Cached per item ID only once a tooltip rendered: a loading item would pass as needing no standing.
local reputationLocked = {}

local function IsReputationLocked(itemID, link)
	local known = reputationLocked[itemID]
	if known ~= nil then
		return known
	end
	local line, rendered = ns.Tooltip:RequiredReputation(link)
	if rendered then
		reputationLocked[itemID] = line ~= nil
	end
	return line ~= nil
end

-- Any one switch on is enough: a food that restores mana too is listed under Food or Drink.
local function AnyKindOn(kinds)
	local switches = ns.db.profile.consumableKinds
	for _, kind in ipairs(kinds) do
		if switches[kind] then
			return true
		end
	end
	return false
end

--[[
	Max per stat, never sum: both sources report a fixed stat. Each source's answer also comes back,
	since the merge is lossy.
]]
local function NormalizedStats(link)
	local api = {}
	for key, value in pairs(ns.GetItemStats(link) or {}) do
		local token = ns.Data.STAT_MAP[key]
		if token then
			api[token] = (api[token] or 0) + value
		end
	end

	local tooltip, source, lines, unread = ns.Tooltip:Stats(link)

	local out = {}
	for token, value in pairs(api) do
		out[token] = value
	end
	for token, value in pairs(tooltip) do
		if value > (out[token] or 0) then
			out[token] = value
		end
	end

	-- Raw lines only when nothing parsed: the one case where read failure and no stats look alike.
	local unparsed = next(tooltip) == nil and lines or nil

	-- unread travels always: one line can miss while three read cleanly.
	return out, { source = source, api = api, tooltip = tooltip, lines = unparsed, unread = unread }
end

--[[
	Slot and link together: a slot is reused once its item is mailed, and a link is shared by every
	copy of a plain item. Stable across a rescan, which is how a pairing survives one.
]]
local function ItemUID(bag, slot, link)
	return ("%d:%d:%s"):format(bag or -1, slot or -1, link or "")
end

-- Local on purpose: a gear record without stats reads as a parse failure, so Scanner:Classify is the way in.
local function FilterSlot(bag, slot)
	local link = ns.GetItemLink(bag, slot)
	if not link then
		return nil, REJECT.EMPTY_SLOT
	end

	-- First, and before the cache check: an item the player took off the list is never offered.
	if Bags:IsNeverGive(ns.GetInfoInstant(link)) then
		return nil, REJECT.NEVER_GIVE
	end

	local slotInfo = ns.GetItemInfoC(bag, slot)
	local count = slotInfo and slotInfo.stackCount
	local isBound = slotInfo and slotInfo.isBound

	local name, _, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID, bindType =
		C_Item.GetItemInfo(link)
	if not name then
		-- GET_ITEM_INFO_RECEIVED rescans for it while the window is open.
		local itemID = ns.GetInfoInstant(link)
		if itemID then
			pendingItems[itemID] = true
		end
		return nil, REJECT.NOT_CACHED
	end

	local itemID = ns.GetInfoInstant(link)

	local consumable = ConsumableIndex()[itemID]
	if consumable then
		if not ns.db.profile.includeConsumables then
			return nil, REJECT.CONSUMABLES_DISABLED
		end
		if not AnyKindOn(consumable.kinds) then
			return nil, REJECT.KIND_DISABLED
		end
		--[[
			A useLevel of 0 bands below MIN_RECIPIENT_LEVEL, so nobody could ever take it. Held back
			until those rows (Bountiful Feast, Delicious Chocolate Cake) get a real level.
		]]
		if (consumable.useLevel or 0) <= 0 then
			return nil, REJECT.NO_USE_LEVEL
		end
		-- Zero lifts the rule outright: as a gap it would still demand the player reach the item's level.
		local gap = ns.db.profile.consumableLevelGap
		if gap > 0 and (UnitLevel("player") or 1) - consumable.useLevel < gap then
			return nil, REJECT.LEVEL_GAP
		end
		if isBound then
			return nil, REJECT.SOULBOUND
		end
		-- Most recipients lack the standing. Last, as the one test that reads a tooltip.
		if IsReputationLocked(itemID, link) then
			return nil, REJECT.REPUTATION_LOCKED
		end
		return {
			kind = "consumable",
			link = link,
			bag = bag,
			slot = slot,
			uid = ItemUID(bag, slot, link),
			itemID = itemID,
			name = name,
			count = count or 1,
			def = consumable,
		}
	end

	-- Before the gear toggle, or a bandage scanned with gear off comes back GEAR_DISABLED.
	if classID == CONSUMABLE_CLASS then
		return nil, REJECT.CONSUMABLE_NOT_LISTED
	end

	-- A positive classID check, never "has an equip slot": recipes carry one.
	if not ns.db.profile.includeGear then
		return nil, REJECT.GEAR_DISABLED
	end
	if classID ~= WEAPON_CLASS and classID ~= ARMOR_CLASS then
		return nil, REJECT.WRONG_CLASS
	end
	if quality < ns.Data.MIN_RARITY then
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
		uid = ItemUID(bag, slot, link),
		itemID = itemID,
		name = name,
		count = 1,
		quality = quality,
		reqLevel = reqLevel or 1,
		itemLevel = itemLevel,
		equipLoc = equipLoc,
		classID = classID,
		subclassID = subclassID,
	}
end

function Scanner:Classify(bag, slot)
	local record, reason = FilterSlot(bag, slot)
	if not record then
		return nil, reason
	end
	if record.kind == "gear" then
		-- The expensive half: one tooltip per item, bounded by what cleared the filter.
		record.stats, record.statRead = NormalizedStats(record.link)
	end
	return record
end

-- No bag slot behind it; for the Item Verdict report.
function Scanner:Describe(link)
	local name, _, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(link)
	if not name then
		return nil
	end
	local stats, statRead = NormalizedStats(link)
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

local function EachSlot(fn)
	for bag = 0, NUM_BAGS do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			fn(bag, slot, Scanner:Classify(bag, slot))
		end
	end
end

--------------------------------------------------------------------------------
-- Keep in Bags
--------------------------------------------------------------------------------

Bags.KEEP_ORDER = { 0, 5, 10, 20 }

local function KeepAmount(def)
	local profile = ns.db.profile
	local keep = 0
	for _, kind in ipairs(def.kinds or {}) do
		if profile.consumableKinds[kind] then
			keep = math.max(keep, (profile.keepInBags or {})[kind] or 0)
		end
	end
	return keep
end

--[[
	Mail attaches a whole slot, so stacks are never split. Largest first, each offered only while
	the rest still covers keep: carrying 5 and 3 with 5 kept offers the 3.
]]
function Bags.OfferedStacks(counts, keep)
	local offered = {}
	local remaining = 0
	local byLargest = {}
	for index, count in ipairs(counts) do
		remaining = remaining + count
		byLargest[#byLargest + 1] = index
	end
	-- Ties keep bag order, so the same bags always offer the same stacks.
	table.sort(byLargest, function(a, b)
		if counts[a] ~= counts[b] then
			return counts[a] > counts[b]
		end
		return a < b
	end)
	for _, index in ipairs(byLargest) do
		if remaining - counts[index] >= keep then
			offered[index] = true
			remaining = remaining - counts[index]
		end
	end
	return offered
end

local function HeldBack(records)
	local byItem, order = {}, {}
	for _, record in ipairs(records) do
		if record.kind == "consumable" then
			local group = byItem[record.itemID]
			if not group then
				group = {}
				byItem[record.itemID] = group
				order[#order + 1] = record.itemID
			end
			group[#group + 1] = record
		end
	end
	local held = {}
	for _, itemID in ipairs(order) do
		local group = byItem[itemID]
		local keep = KeepAmount(group[1].def)
		if keep > 0 then
			local counts = {}
			for index, record in ipairs(group) do
				counts[index] = record.count or 1
			end
			local offered = Bags.OfferedStacks(counts, keep)
			for index, record in ipairs(group) do
				if not offered[index] then
					held[record.uid] = true
				end
			end
		end
	end
	return held
end

--------------------------------------------------------------------------------
-- Scans
--------------------------------------------------------------------------------

function Scanner:Scan()
	wipe(pendingItems)
	local records = {}
	EachSlot(function(_, _, record)
		if record then
			table.insert(records, record)
		end
	end)
	local held = HeldBack(records)
	local items = {}
	for _, record in ipairs(records) do
		if not held[record.uid] then
			table.insert(items, record)
		end
	end
	return items
end

-- Empty slots are left out: not a rejection, only padding.
function Scanner:ScanAll()
	local rows = {}
	local records = {}
	EachSlot(function(bag, slot, record, reason)
		if record or reason ~= REJECT.EMPTY_SLOT then
			table.insert(rows, {
				bag = bag,
				slot = slot,
				link = ns.GetItemLink(bag, slot),
				item = record,
				reason = reason,
			})
			if record then
				records[#records + 1] = record
			end
		end
	end)
	local held = HeldBack(records)
	for _, row in ipairs(rows) do
		if row.item and held[row.item.uid] then
			row.item, row.reason = nil, REJECT.KEEP_IN_BAGS
		end
	end
	return rows
end

--------------------------------------------------------------------------------
-- Never Give Away
--------------------------------------------------------------------------------

function Bags:IsNeverGive(itemID)
	local list = itemID and ns.db and ns.db.profile.neverGive
	return list ~= nil and list[itemID] == true
end

function Bags:NeverGiveList()
	local out = {}
	for itemID in pairs(ns.db and ns.db.profile.neverGive or {}) do
		out[#out + 1] = itemID
	end
	return out
end

local function Changed()
	ns.UI:Rescan()
	if ns.RefreshSettings then
		ns.RefreshSettings()
	end
end

function Bags:NeverGive(itemID, link)
	if not itemID then
		return
	end
	ns.db.profile.neverGive[itemID] = true
	link = link or select(2, C_Item.GetItemInfo(itemID)) or ("item:" .. itemID)
	ns:PrintMessage(L["CHAT_NEVER_GIVE"]:format(link, L["TAB_GIVE_AWAY"]))
	Changed()
end

function Bags:GiveAgain(itemID)
	ns.db.profile.neverGive[itemID] = nil
	Changed()
end
