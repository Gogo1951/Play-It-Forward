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

-- Our own identity, to tell our own tooltip from a peer's. The same helper the peers cache keys on.
local function ownKey()
	return ns.QualifyPlayerName(UnitName("player")) or "?"
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
	A blank line, the branded header, then the four rows: labels left and values right. The blank
	line separates the block from whatever the client and other add-ons put above it, so ours never
	reads as another line of theirs.

	Rows are indented under the header, a silver HELP label against a white value. The four labels
	are the same words on every tooltip and the figures are what a reader stopped for, so the
	label is muted and the number carries the weight. HELP rather than TITLE deliberately: gold
	field titles are the options panel's rule, where a caption sits beside a control the player
	acts on, and nothing here is a control.

	THE VALUES CANNOT BE ANY OTHER COLOR. The money row comes from GetCoinTextureString, which
	carries the client's own markup and ignores a color prefix, so it renders white whatever it is
	given. Coloring the other three anything else leaves that row visibly out of step with them.
	Counts go through ns.CommaNumber, the money through ns.MoneyString. Show() once at the end so
	the frame resizes to fit.
]]
local ROW_INDENT = " "

local function appendBlock(tooltip, gifts, items, itemLevels, value)
	local labelColor, valueColor = ns.GetColor("HELP"), ns.GetColor("TEXT")
	local function row(label, shown)
		tooltip:AddDoubleLine(ROW_INDENT .. labelColor .. label .. "|r", valueColor .. shown .. "|r")
	end

	tooltip:AddLine(" ")
	-- The same branded line a chat print carries: blue name, gray separator, white body.
	tooltip:AddLine(ns:BuildBrandedLine(L["TOOLTIP_GENEROSITY_HEADER"]))
	row(L["OPTIONS_GENEROSITY_GIFTS"], ns.CommaNumber(gifts))
	row(L["OPTIONS_GENEROSITY_ITEMS"], ns.CommaNumber(items))
	row(L["OPTIONS_GENEROSITY_ITEM_LEVELS"], ns.CommaNumber(itemLevels))
	row(L["OPTIONS_GENEROSITY_VALUE"], ns.MoneyString(value))
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
	-- UnitName hands back a realm only for somebody from another one; ours is appended for us.
	local key = (realm and realm ~= "") and (name .. "-" .. realm) or ns.QualifyPlayerName(name)

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
