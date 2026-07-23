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

test("a hovered peer with cached totals gets a Given Away block", function()
	local ns = load()
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|7|120|450|9988", "YELL", "Robin-Grobbulus")

	local handler, rows = rig("mouseover", "Robin", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 5, "header plus four rows")
	check(rows[1].line ~= nil and rows[1].line:find("Given Away") ~= nil, "the header names the block")
	check(rows[2].right:find("7") ~= nil, "gifts value on the first row")
end)

test("a player we have not heard from adds nothing and fires one ping", function()
	local ns = load()
	Stub.addonMessages = {}

	local handler, rows = rig("mouseover", "Stranger", "Grobbulus")
	handler(GameTooltip)

	equal(#rows, 0, "no block on the first hover")
	equal(#Stub.addonMessages, 1, "a presence ping went out")
	equal(Stub.addonMessages[1].message, "1|?", "and it was a ping, not our stats")
end)

test("the hover ping is throttled within its interval", function()
	local ns = load()
	Stub.addonMessages = {}

	local handler = rig("mouseover", "Stranger", "Grobbulus")
	handler(GameTooltip)
	handler(GameTooltip) -- immediately again, same GetTime

	equal(#Stub.addonMessages, 1, "the second hover inside the interval does not re-ping")
end)

test("your own tooltip shows your live tally, block always present", function()
	local ns = load()

	local handler, rows = rig("player", "Tester", "Test")
	handler(GameTooltip)

	equal(#rows, 5, "own block present even at all zeros")
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
	local ns = load()
	Stub.resting = false

	local handler, rows = rig("player", "Tester", "Test")
	handler(GameTooltip)

	equal(#rows, 0, "own block hidden outside town")
end)

-- A non-player unit (an NPC) gets nothing: the block is for players.
test("a non-player unit is left alone", function()
	local ns = load()
	local rows
	do
		local h
		h, rows = rig("mouseover", "Innkeeper", "")
		Stub.unitsByToken.mouseover.isPlayer = false
		h(GameTooltip)
	end
	equal(#rows, 0, "no block on an NPC")
end)
