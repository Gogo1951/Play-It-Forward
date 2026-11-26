local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

-- Accepted latency: an unheard player's first hover shows nothing and pings; the block appears next hover.

local Generosity = ns.Generosity

local HOVER_PING_INTERVAL = 10
local lastPing = 0

-- Diagnostics only: GetTime() of the last hover ping, or 0.
function Generosity:LastHoverPing()
	return lastPing
end

local function OwnKey()
	return ns.QualifyPlayerName(UnitName("player")) or "?"
end

local function HoverPing()
	local now = GetTime()
	if now - lastPing < HOVER_PING_INTERVAL then
		return
	end
	lastPing = now
	Generosity:Ping()
end

-- Values stay white: GetCoinTextureString ignores a color prefix, so any other color leaves the money row out of step.
local ROW_INDENT = " "

-- The Badge of Generosity panel previews from this too, so the two cannot differ.
function Generosity:BlockLines(gifts, items, itemLevels, value)
	local labelColor, valueColor = GetColor("BODY"), GetColor("TEXT")
	local function Row(label, shown)
		return { ROW_INDENT .. labelColor .. label .. "|r", valueColor .. shown .. "|r" }
	end
	return {
		GetColor("TITLE") .. L["BADGE_OF_GENEROSITY"] .. "|r",
		GetColor("MUTED") .. L["ADDON_SHORT_NAME"] .. "|r",
	}, {
		Row(L["OPTIONS_GENEROSITY_GIFTS"], ns.CommaNumber(gifts)),
		Row(L["OPTIONS_GENEROSITY_ITEMS"], ns.CommaNumber(items)),
		Row(L["OPTIONS_GENEROSITY_ITEM_LEVELS"], ns.CommaNumber(itemLevels)),
		Row(L["OPTIONS_GENEROSITY_VALUE"], ns.MoneyString(value)),
	}
end

local function AppendBlock(tooltip, gifts, items, itemLevels, value)
	local header, rows = Generosity:BlockLines(gifts, items, itemLevels, value)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(header[1], header[2])
	for _, row in ipairs(rows) do
		tooltip:AddDoubleLine(row[1], row[2])
	end
	tooltip:Show()
end

local function OnTooltipSetUnit(tooltip)
	-- Town only, your own tooltip included; first so a hover costs nothing elsewhere.
	if not ns.AtRest() then
		return
	end
	-- The unit token is the second return; the first is the display name we already have on the tip.
	local _, unit = tooltip:GetUnit()
	if not unit then
		return
	end
	-- On WoW Forever a unit's name reads as a secret value in combat, which cannot be compared.
	if C_Secrets.ShouldUnitIdentityBeSecret(unit) then
		return
	end
	if not UnitIsPlayer(unit) then
		return
	end

	local name, realm = UnitName(unit)
	if not name then
		return
	end
	-- UnitName hands back a realm only for somebody from another one; ours is appended for us.
	local key = (realm and realm ~= "") and (name .. "-" .. realm) or ns.QualifyPlayerName(name)

	local gifts, items, itemLevels, value
	if key == OwnKey() then
		-- Always shown, even at all zeros.
		gifts, items, itemLevels, value = Generosity:Get()
	else
		local peer = Generosity:Peer(key)
		if peer then
			gifts, items, itemLevels, value = peer.gifts, peer.items, peer.itemLevels, peer.value
		end
	end

	if not gifts then
		HoverPing()
		return
	end

	AppendBlock(tooltip, gifts, items, itemLevels, value)
end

--[[
	Classic clients expose TooltipDataProcessor but never run its post-calls; GetPrimaryTooltipData
	marks a data-driven GameTooltip. The post-call fires for every unit tooltip, so only GameTooltip.
]]
local usesTooltipData = type(GameTooltip.GetPrimaryTooltipData) == "function"
	and type(TooltipDataProcessor) == "table"
	and type(TooltipDataProcessor.AddTooltipPostCall) == "function"

if usesTooltipData then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
		if tooltip == GameTooltip then
			OnTooltipSetUnit(tooltip)
		end
	end)
	Generosity.tooltipHook = "TooltipDataProcessor unit post-call"
elseif GameTooltip:HasScript("OnTooltipSetUnit") then
	GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
	Generosity.tooltipHook = "GameTooltip OnTooltipSetUnit"
else
	Generosity.tooltipHook = "none"
end
