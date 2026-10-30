--[[
	The status line above the window's two buttons says the next step, whatever state the window
	is in. Each case reads UI:StatusLine, the words the line is set to.
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

local KEEFE = { name = "Keefe", level = 18, class = "MAGE" }

local function atMailbox(defs)
	local ns = load()
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	return ns
end

local function starts(text, prefix)
	return text:sub(1, #prefix) == prefix
end

--------------------------------------------------------------------------------

test("before any search it says to press Find Recipients", function()
	local ns = atMailbox({ cloak() })
	local line = ns.UI:StatusLine()
	equal(line, ns.L["STATUS_START"]:format(1), "one item waiting")
	equal(ns.UI.frame.statusText.shownText, line, "and the window shows it")
end)

test("after the last planned search it says the search is finished", function()
	local ns = atMailbox({ cloak() })
	Stub.whoResults = {}
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	-- Step through whatever the plan still holds, letting each throttle lapse.
	for _ = 1, 20 do
		if ns.Who:Remaining() == 0 then
			break
		end
		Stub.now = Stub.now + 10
		Stub.FireTimers()
		ns.UI:FindRecipients()
		ns.fire("WHO_LIST_UPDATE")
	end
	equal(ns.UI:StatusLine(), ns.L["STATUS_DONE"]:format(1), "nobody turned up")
end)

test("mid-plan it says how many searches are left", function()
	local ns = atMailbox({ cloak() })
	Stub.whoResults = {}
	ns.UI:FindRecipients()
	local remaining = ns.Who:Remaining()
	if remaining > 0 then
		equal(ns.UI:StatusLine(), ns.L["STATUS_MORE"]:format(remaining), "searches left")
	else
		check(starts(ns.UI:StatusLine(), "Search finished"), "a one-query plan is already done")
	end
end)

test("a matched row at the mailbox says to press Distribute", function()
	local ns = atMailbox({ cloak() })
	ns.UI:SetRecipient(ns.UI:Items()[1], KEEFE)
	equal(ns.UI:StatusLine(), ns.L["STATUS_READY"]:format(1), "ready")
end)

test("a matched row away from the mailbox says to open one", function()
	local ns = atMailbox({ cloak() })
	ns.UI:SetRecipient(ns.UI:Items()[1], KEEFE)
	ns.fire("MAIL_CLOSED")
	equal(ns.UI:StatusLine(), ns.L["STATUS_AWAY"]:format(1), "away")
end)

test("while mailing it shows the run's progress", function()
	local ns = atMailbox({ cloak() })
	ns.UI:SetRecipient(ns.UI:Items()[1], KEEFE)
	ns.UI:Distribute()
	equal(ns.UI:StatusLine(), ns.L["STATUS_SENDING"]:format(1, 1), "first of one")
end)

test("rows the player is keeping say nothing", function()
	local ns = atMailbox({ cloak() })
	ns.UI:ToggleRow(ns.UI:Items()[1], false)
	equal(ns.UI:StatusLine(), "", "nothing to do")
end)
