local _, ns = ...

--[[
	The account-wide giving tally: what this account has given away through Play It Forward, kept
	in ns.db.global.stats so a lifetime total survives Reset Profile and spans every character.
	RecordSend is the only writer, called from Features/Mail-Sender.lua once per successful send.
	No networking here; Features/Generosity-Broadcast.lua broadcasts what Get returns.
]]

ns.Generosity = {}
local Generosity = ns.Generosity

--[[
	One successful mailing. quantity is the stack size, captured at send time in the mailer because
	the bag slot is already stale by MAIL_SUCCESS -- a stack of 20 waters must count as 20, not 1.
	Item level counts for equippable gear only; a consumable adds nothing to it. Value is the vendor
	sell price times the stack. GetItemInfo is warm here (the item was just scanned and mailed), but
	every read off it is guarded for nil rather than assumed.
]]
function Generosity:RecordSend(link, quantity)
	if not ns.db then
		return
	end
	local stats = ns.db.global.stats
	local count = quantity or 1

	stats.gifts = stats.gifts + 1
	stats.items = stats.items + count

	if IsEquippableItem(link) then
		local itemLevel = select(4, GetItemInfo(link))
		if itemLevel then
			stats.itemLevels = stats.itemLevels + itemLevel
		end
	end

	stats.value = stats.value + (select(11, GetItemInfo(link)) or 0) * count
end

-- The four counters, for the General panel's Given Away display and Features/Generosity-Broadcast.lua.
function Generosity:Get()
	local stats = ns.db and ns.db.global.stats
	if not stats then
		return 0, 0, 0, 0
	end
	return stats.gifts, stats.items, stats.itemLevels, stats.value
end
