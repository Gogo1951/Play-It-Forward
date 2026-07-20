local _, ns = ...

--------------------------------------------------------------------------------
-- Shared Options Helpers
--------------------------------------------------------------------------------

--[[
	Widget constructors shared by every options panel. Dot-defined (no self), so callers use
	dot invocation. Header and Spacer take two arguments only: to hide a section built from
	them, inline the widgets with their own hidden functions rather than adding a third here.
]]
local GetColor = ns.GetColor

function ns.OptionsHeader(text, order)
	return { type = "header", name = GetColor("TITLE") .. text .. "|r", order = order }
end

function ns.OptionsDesc(text, order)
	return { type = "description", name = text, fontSize = "medium", order = order }
end

function ns.OptionsSpacer(order)
	return { type = "description", name = " ", order = order }
end

function ns.OptionsSubHeader(text, order, hidden)
	return {
		type = "description",
		name = "\n" .. GetColor("TITLE") .. text .. "|r",
		fontSize = "medium",
		order = order,
		hidden = hidden,
	}
end

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

--[[
	The stops are data, in Data/Data.lua. Labelled "20 levels" rather than "20", because a bare
	number says nothing about what it counts.
]]
ns.CONSUMABLE_GAP_VALUES = {}
for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
	ns.CONSUMABLE_GAP_VALUES[gap] = ns.L["OPTIONS_CONSUMABLE_GAP_VALUE"]:format(gap)
end

--[[
	A select whose current value is not in its list renders blank, which reads as a setting that
	failed to load. Display only: the stored number keeps driving the scan until the player
	picks, since rewriting somebody's setting to open a panel is worse than showing it rounded.
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
