--[[
	The unit-tooltip block. The hook is real -- Features/Generosity-Tooltip.lua installs it on the
	stub GameTooltip at load -- so these drive the handler the client would, with recorders standing
	in for AddLine/AddDoubleLine and GetUnit pointed at a chosen unit. The three cases the handler
	tells apart: a cached peer (block), an unknown player (no block, one ping), and yourself (live
	tally, always present). GetTime is the stub clock, so the hover-ping throttle is quiet on a first
	call and closed on an immediate second.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal
local Stub = Harness.Stub

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Point GameTooltip at a unit and record what the block adds. token "player" is your own portrait,
	where the stub reports you as "Tester-Test"; any other token is looked up in Stub.unitsByToken.
]]
local function rig(token, name, realm)
	local rows = {}
	rawset(GameTooltip, "AddLine", function(_, text)
		rows[#rows + 1] = { line = text }
	end)
	rawset(GameTooltip, "AddDoubleLine", function(_, left, right)
		rows[#rows + 1] = { left = left, right = right }
	end)
	rawset(GameTooltip, "GetUnit", function()
		return name, token
	end)
	if token ~= "player" then
		Stub.unitsByToken = { [token] = { name = name, realm = realm, isPlayer = true } }
	end
	return GameTooltip.hooks["OnTooltipSetUnit"], rows
end

--------------------------------------------------------------------------------

test("a hovered peer with cached totals gets a Generosity block", function()
	local ns = load()
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|7|120|450|9988", "YELL", "Robin-Grobbulus")

	local handler, rows = rig("mouseover", "Robin", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 6, "a blank line, the header, then four rows")
	-- The block sits under whatever the client and other add-ons wrote above it, never against it.
	equal(rows[1].line, " ", "a blank line opens the block")
	check(rows[2].line ~= nil and rows[2].line:find("Badge of Generosity") ~= nil, "the header names the block")
	check(rows[3].left ~= nil and rows[3].left:find("^ ") ~= nil, "rows are indented under the header")
	check(rows[3].right:find("7") ~= nil, "gifts value on the first row")
end)

test("a player we have not heard from adds nothing and fires one ping", function()
	load()
	Stub.addonMessages = {}

	local handler, rows = rig("mouseover", "Stranger", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 0, "no block on the first hover")
	equal(#Stub.addonMessages, 1, "a presence ping went out")
	equal(Stub.addonMessages[1].message, "1|?", "and it was a ping, not our stats")
end)

test("the hover ping is throttled within its interval", function()
	load()
	Stub.addonMessages = {}

	local handler = rig("mouseover", "Stranger", "Grobbulus")
	handler(GameTooltip)
	handler(GameTooltip) -- immediately again, same GetTime

	equal(#Stub.addonMessages, 1, "the second hover inside the interval does not re-ping")
end)

test("your own tooltip shows your live tally, block always present", function()
	load()

	local handler, rows = rig("player", "Tester", "Test")
	handler(GameTooltip)

	equal(#rows, 6, "own block present even at all zeros")
end)

--[[
	The town gate, on the display side. Outside a rest area the block does not render even for a
	peer already cached, and no ping is fired: no clutter on a tooltip mid-fight, no traffic in a
	raid. Your own tooltip is gated the same way.
]]
test("out of a rest area a cached peer renders nothing and does not ping", function()
	local ns = load()
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|7|120|450|9988", "YELL", "Robin-Grobbulus")
	Stub.addonMessages = {}
	Stub.resting = false

	local handler, rows = rig("mouseover", "Robin", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 0, "no block outside town, cached or not")
	equal(#Stub.addonMessages, 0, "and no ping outside town")
end)

test("out of a rest area your own tooltip stays clean too", function()
	load()
	Stub.resting = false

	local handler, rows = rig("player", "Tester", "Test")
	handler(GameTooltip)

	equal(#rows, 0, "own block hidden outside town")
end)

-- A non-player unit (an NPC) gets nothing: the block is for players.
test("a non-player unit is left alone", function()
	load()
	local rows
	do
		local h
		h, rows = rig("mouseover", "Innkeeper", "")
		Stub.unitsByToken.mouseover.isPlayer = false
		h(GameTooltip)
	end
	equal(#rows, 0, "no block on an NPC")
end)

--[[
	WoW Forever's client has no OnTooltipSetUnit script, so where TooltipDataProcessor exists the
	block hangs off its unit post-call instead. That post-call fires for every tooltip showing a
	unit, the comparison and embedded ones included, and only GameTooltip gets the block.
]]
test("with TooltipDataProcessor the block comes from the unit post-call", function()
	Stub.useTooltipProcessor = true
	local ok, ns = pcall(load)
	Stub.useTooltipProcessor = nil
	assert(ok, ns)
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|7|120|450|9988", "YELL", "Robin-Grobbulus")

	local _, rows = rig("mouseover", "Robin", "Grobbulus")
	check(GameTooltip.hooks["OnTooltipSetUnit"] == nil, "the script is not hooked")
	local postCall = Stub.tooltipPostCalls[Enum.TooltipDataType.Unit]
	check(postCall ~= nil, "a unit post-call is registered")

	postCall({})
	equal(#rows, 0, "another tooltip gets nothing")
	postCall(GameTooltip)
	equal(#rows, 6, "GameTooltip gets the block")
end)

--[[
	The Classic clients (TBC Anniversary among them) expose TooltipDataProcessor, but GameTooltip
	there still fires only OnTooltipSetUnit, so a post-call would never run and even your own
	tooltip stayed bare. Without the data pipeline on the frame the script is hooked instead.
]]
test("a processor without tooltip-data frames still hooks OnTooltipSetUnit", function()
	Stub.useTooltipProcessor = true
	Stub.legacyTooltipFrames = true
	local ok, ns = pcall(load)
	Stub.useTooltipProcessor = nil
	Stub.legacyTooltipFrames = nil
	assert(ok, ns)

	local handler, rows = rig("player", "Tester", "Test")
	check(handler ~= nil, "the script is hooked")
	check(Stub.tooltipPostCalls[Enum.TooltipDataType.Unit] == nil, "no post-call is registered")
	equal(ns.Generosity.tooltipHook, "GameTooltip OnTooltipSetUnit", "the diagnostics report the script")

	handler(GameTooltip)
	equal(#rows, 6, "your own tooltip gets the block")
end)

-- On Forever a unit's name reads as secret in combat: nothing renders and nothing is sent.
test("a unit whose identity is secret is left alone", function()
	load()
	Stub.addonMessages = {}
	Stub.identitySecret = true

	local handler, rows = rig("mouseover", "Stranger", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 0, "no block while identity is secret")
	equal(#Stub.addonMessages, 0, "and no ping")
end)

--[[
	The Badge of Generosity panel draws its preview from these same lines, so the two show the same
	header, labels and figures. The panel file itself stays out of the harness, like the other
	panels whose libraries are only stubbed.
]]
test("the tooltip's lines, which the panel's preview draws too", function()
	local ns = load()
	ns.db.global.stats.gifts = 338
	local header, lines = ns.Generosity:BlockLines(ns.Generosity:Get())
	check(header:find("Badge of Generosity", 1, true), "the branded header")
	equal(#lines, 4, "four rows")
	check(lines[1][2]:find("338", 1, true), "gifts on the right")
end)
