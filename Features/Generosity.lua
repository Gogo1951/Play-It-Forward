local _, ns = ...

-- In global, so the lifetime tally survives Reset Profile and spans characters. RecordSend is the only writer.

ns.Generosity = {}
local Generosity = ns.Generosity

-- quantity comes from the mailer: the slot is stale by MAIL_SUCCESS. Item info is warm here but still nil-guarded.
function Generosity:RecordSend(link, quantity)
	if not ns.db then
		return
	end
	local stats = ns.db.global.stats
	local count = quantity or 1

	stats.gifts = stats.gifts + 1
	stats.items = stats.items + count

	if C_Item.IsEquippableItem(link) then
		local itemLevel = select(4, C_Item.GetItemInfo(link))
		if itemLevel then
			stats.itemLevels = stats.itemLevels + itemLevel
		end
	end

	stats.value = stats.value + (select(11, C_Item.GetItemInfo(link)) or 0) * count
end

function Generosity:Get()
	local stats = ns.db and ns.db.global.stats
	if not stats then
		return 0, 0, 0, 0
	end
	return stats.gifts, stats.items, stats.itemLevels, stats.value
end
