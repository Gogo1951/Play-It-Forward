local _, ns = ...
local L = ns.L

--[[
	Renders a player's Given Away totals at the bottom of their unit tooltip: your own live tally on
	your own tooltip, and a nearby peer's cached totals on theirs. These flavors predate
	TooltipDataProcessor, so the block is added from a script hook on OnTooltipSetUnit.

	PROXIMITY MODEL, WITH ACCEPTED LATENCY. A player you have never heard from shows nothing on the
	first hover; that hover fires a throttled ping, nearby clients answer, and the block is present
	on the next hover. Broadcasts reach only players near you, so a distant friend never appears.

	TOWN ONLY. The whole block is gated on ns.AtRest(), so nothing renders and nothing is sent
	outside a city or an inn. Both halves of the loop live in the same place anyway: the people
	whose totals you can receive are the resting players standing around you.
]]

local Generosity = ns.Generosity

-- The tooltip's own throttle: at most one presence ping per HOVER_PING_INTERVAL, however fast you hover.
local HOVER_PING_INTERVAL = 10
local lastPing = 0

-- Our own "Name-Realm", to tell our own tooltip from a peer's. Realm is normalized like the broadcaster's.
local function ownKey()
	local name = UnitName("player")
	local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or ""
	return (name or "?") .. "-" .. realm
end

local function hoverPing()
	local now = GetTime()
	if now - lastPing < HOVER_PING_INTERVAL then
		return
	end
	lastPing = now
	if Generosity.Ping then
		Generosity:Ping()
	end
end

--[[
	The four rows plus a header, labels left and values right. Counts go through ns.CommaNumber and
	the money through GetCoinTextureString (ns.MoneyString wraps it with a fallback). Show() once at
	the end so the frame resizes to fit the block just added.
]]
local function appendBlock(tooltip, gifts, items, itemLevels, value)
	local title, text = ns.GetColor("TITLE"), ns.GetColor("TEXT")
	tooltip:AddLine(title .. L["TOOLTIP_GIVEN_HEADER"] .. "|r")
	tooltip:AddDoubleLine(title .. L["OPTIONS_GIVEN_GIFTS"] .. "|r", text .. ns.CommaNumber(gifts) .. "|r")
	tooltip:AddDoubleLine(title .. L["OPTIONS_GIVEN_ITEMS"] .. "|r", text .. ns.CommaNumber(items) .. "|r")
	tooltip:AddDoubleLine(title .. L["OPTIONS_GIVEN_ITEM_LEVELS"] .. "|r", text .. ns.CommaNumber(itemLevels) .. "|r")
	tooltip:AddDoubleLine(title .. L["OPTIONS_GIVEN_VALUE"] .. "|r", ns.MoneyString(value))
	tooltip:Show()
end

local function onTooltipSetUnit(tooltip)
	--[[
		TOWN ONLY, and checked first so a hover costs nothing anywhere else. Outside a rest area the
		block does not render and no ping is fired: no tooltip clutter while a player is fighting, and
		no traffic during a raid. Your own tooltip is gated the same way, for the same reason.
	]]
	if not ns.AtRest() then
		return
	end
	-- The unit token is the second return; the first is the display name we already have on the tip.
	local _, unit = tooltip:GetUnit()
	if not unit or not UnitIsPlayer(unit) then
		return
	end

	local name, realm = UnitName(unit)
	if not name then
		return
	end
	if not realm or realm == "" then
		realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or ""
	end
	local key = name .. "-" .. realm

	local gifts, items, itemLevels, value
	if key == ownKey() then
		-- Our own tooltip shows the live tally, always present even at all zeros.
		gifts, items, itemLevels, value = Generosity:Get()
	else
		local peer = Generosity:Peer(key)
		if peer then
			gifts, items, itemLevels, value = peer.gifts, peer.items, peer.itemLevels, peer.value
		end
	end

	if not gifts then
		-- Never heard from this player: ping so a nearby client answers and the next hover has it.
		hoverPing()
		return
	end

	appendBlock(tooltip, gifts, items, itemLevels, value)
end

if GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetUnit", onTooltipSetUnit)
end
