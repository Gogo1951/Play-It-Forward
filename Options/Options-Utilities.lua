local _, ns = ...

--------------------------------------------------------------------------------
-- Shared Options Helpers
--------------------------------------------------------------------------------

--[[
	Header takes an optional third argument to collapse a gated section. Spacer does not, so a
	gated spacer is inlined as its own description widget carrying a hidden function.
]]
local GetColor = ns.GetColor

function ns.OptionsHeader(text, order, hidden)
	return { type = "header", name = GetColor("TITLE") .. text .. "|r", order = order, hidden = hidden }
end

function ns.OptionsDesc(text, order)
	return { type = "description", name = text, fontSize = "medium", order = order }
end

function ns.OptionsSpacer(order)
	return { type = "description", name = " ", order = order }
end

--[[
	The left half of a label-beside-control row. The control that follows carries name = "" and
	the remaining width, ordered one past this: a caption left on the control puts the label back
	above the widget and breaks the row in two.
]]
function ns.OptionsRowLabel(text, order, width)
	return {
		type = "description",
		name = text,
		fontSize = "medium",
		width = width or ns.OPTIONS_LABEL_WIDTH,
		order = order,
	}
end

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

--[[
	The stops are data, in Data/Data.lua; the words are here. Zero is the "All Consumables" stop
	and lifts the level rule outright (see Features/Scan-Bags.lua), so it reads as itself rather
	than as a gap of nothing.
]]
ns.CONSUMABLE_GAP_VALUES = {}
for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
	ns.CONSUMABLE_GAP_VALUES[gap] = (gap == 0) and ns.L["OPTIONS_CONSUMABLE_GAP_ALL"]
		or ns.L["OPTIONS_CONSUMABLE_GAP_VALUE"]:format(gap)
end

--[[
	A select whose value is not in its list renders blank, reading as a setting that failed to
	load. Display only: the stored number keeps driving the scan until the player picks.
]]
function ns.NearestConsumableGap(value)
	local stored = tonumber(value) or 0
	local best, bestDistance = ns.CONSUMABLE_GAP_ORDER[1], math.huge
	for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
		local distance = math.abs(stored - gap)
		if distance < bestDistance then
			best, bestDistance = gap, distance
		end
	end
	return best
end
