--[[
	The Distribution window's own controls: a section heading's tick, Stop, the Sent section, the
	order a run's chat lines print in, and Reset Window Position.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Requires 19, so the recipient band is 17-18. Intellect is what a mage or priest wants.
local function cloak(name)
	return Stub.Item({
		name = name or "Sentry Cloak",
		reqLevel = 19,
		equipLoc = "INVTYPE_CLOAK",
		classID = 4,
		subclassID = 1,
		stats = { ITEM_MOD_INTELLECT_SHORT = 5 },
	})
end

local PEOPLE = {
	{ name = "Keefe", level = 18, class = "MAGE" },
	{ name = "Robin", level = 18, class = "PRIEST" },
	{ name = "Ashby", level = 17, class = "MAGE" },
}

-- A mailbox with the window open and every item paired by hand with somebody different.
local function readyToDistribute(count)
	local ns = load()
	local defs = {}
	for index = 1, count do
		defs[index] = cloak("Cloak " .. index)
	end
	Stub.SetBackpack(defs)
	ns.visitMailbox()
	for index, item in ipairs(ns.UI:Items()) do
		ns.UI:SetRecipient(item, PEOPLE[index])
	end
	return ns
end

local function pressDistribute(ns)
	ns.UI.frame.distributeButton:GetScript("OnClick")(ns.UI.frame.distributeButton)
end

local function starts(text, prefix)
	return tostring(text):sub(1, #prefix) == prefix
end

local SENT_PREFIX = "Sent "

--------------------------------------------------------------------------------
-- A heading's tick
--------------------------------------------------------------------------------

test("a heading's tick shows ticked while every row under it is", function()
	local ns = readyToDistribute(2)
	local tickable, all = ns.UI:SectionTick(1)
	equal(tickable, 2, "both matched rows can be ticked")
	equal(all, true, "rows start ticked")

	ns.UI:ToggleRow(ns.UI:Items()[1], false)
	local _, after = ns.UI:SectionTick(1)
	equal(after, false, "one row unticked, the heading is not")
end)

test("a heading's untick unticks every row under it, and it sticks", function()
	local ns = readyToDistribute(2)
	ns.UI:ToggleSection(1, false)
	for _, item in ipairs(ns.UI:Items()) do
		equal(item.send, false, item.name .. " unticked")
		equal(item.pinned, true, item.name .. " remembered like a row's own untick")
	end

	-- A search must never undo it.
	Stub.whoResults = { { name = "Fernly", level = 18, class = "MAGE" } }
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	for _, item in ipairs(ns.UI:Items()) do
		equal(item.send, false, item.name .. " still unticked after a search")
	end
	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "nothing left to send")

	ns.UI:ToggleSection(1, true)
	for _, item in ipairs(ns.UI:Items()) do
		equal(item.send, true, item.name .. " ticked again")
	end
end)

--------------------------------------------------------------------------------
-- A run's chat lines
--------------------------------------------------------------------------------

test("the Sent lines wait for the run to end, then follow the Done line", function()
	local ns = readyToDistribute(2)
	Stub.printed = {}
	pressDistribute(ns)
	ns.fire("MAIL_SUCCESS")
	for _, line in ipairs(Stub.printed) do
		check(not starts(line, SENT_PREFIX), "no Sent line mid-run: " .. tostring(line))
	end

	ns.fire("MAIL_SUCCESS")
	local done
	for index, line in ipairs(Stub.printed) do
		if line == ns.L["MAIL_DONE"]:format(2, 2) then
			done = index
		end
	end
	check(done ~= nil, "the run said Done")
	check(starts(Stub.printed[done + 1], SENT_PREFIX), "the first Sent line comes after it")
	check(starts(Stub.printed[done + 2], SENT_PREFIX), "and the second")
end)

--------------------------------------------------------------------------------
-- Stop
--------------------------------------------------------------------------------

test("Stop finishes the letter in hand, then halts", function()
	local ns = readyToDistribute(3)
	pressDistribute(ns)
	equal(#Stub.sent, 1, "the first letter is out")

	Stub.printed = {}
	pressDistribute(ns)
	equal(ns.Distributor:IsRunning(), true, "the letter in hand still finishes")
	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "a pressed Stop waits")

	ns.fire("MAIL_SUCCESS")
	equal(ns.Distributor:IsRunning(), false, "halted")
	equal(#Stub.sent, 1, "nothing more went out")

	local stopped = ns.L["MAIL_STOPPED"]:format(1, 3)
	equal(Stub.printed[1], stopped, "chat says Stopped first")
	check(starts(Stub.printed[2], SENT_PREFIX), "then the held Sent line")
	equal(ns.UI:StatusLine(), stopped, "and the status line says it too")
	equal(ns.UI.frame.distributeButton:GetText(), ns.L["BUTTON_DISTRIBUTE"], "back to Distribute")
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "live for the rest")

	pressDistribute(ns)
	ns.fire("MAIL_SUCCESS")
	ns.fire("MAIL_SUCCESS")
	equal(#Stub.sent, 3, "Distribute sends the rest")
end)

test("Stop on the last letter lets the run finish as Done", function()
	local ns = readyToDistribute(1)
	pressDistribute(ns)
	Stub.printed = {}
	pressDistribute(ns)
	ns.fire("MAIL_SUCCESS")
	equal(Stub.printed[1], ns.L["MAIL_DONE"]:format(1, 1), "nothing left to stop")
	equal(ns.Distributor:Stopped(), nil, "no Stopped line on the window")
end)

--------------------------------------------------------------------------------
-- The Sent section
--------------------------------------------------------------------------------

test("a delivered letter is listed under Sent, with who got it, until the window closes", function()
	local ns = readyToDistribute(2)
	pressDistribute(ns)
	ns.fire("MAIL_SUCCESS")

	local sent = ns.Distributor:Sent()
	equal(#sent, 1, "one sent")
	equal(sent[1].recipient, "Keefe", "with who got it")
	equal(#ns.UI:Items(), 1, "and off the live list")

	ns.UI:Close()
	equal(#ns.Distributor:Sent(), 0, "cleared when the window closes")
end)

--------------------------------------------------------------------------------
-- Reset Window Position
--------------------------------------------------------------------------------

test("Reset Window Position forgets where and how big the window was", function()
	local ns = readyToDistribute(1)
	ns.db.profile.windowPos = { point = "CENTER", relativePoint = "CENTER", x = 300, y = 40 }
	ns.db.profile.windowSize = { width = 960, height = 640 }

	ns.UI:ResetWindowPosition()
	equal(ns.db.profile.windowPos.point, nil, "opens beside the mailbox tab again")
	equal(ns.db.profile.windowSize.width, nil, "at its first width")
	equal(ns.db.profile.windowSize.height, nil, "and height")
end)
