--[[
	A gift nobody opened comes back to the inbox. At the mailbox one chat line names what came
	back and from whom, once a session per gift, and nothing else in the inbox is spoken about.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, equal = Harness.test, Harness.equal

local HELM = "|cff1eff00|Hitem:9999::::::::20:::::::|h[Grimsby's Helm]|h|r"
local RING = "|cff1eff00|Hitem:9998::::::::20:::::::|h[Plain Ring]|h|r"

local function returnedLines(ns)
	local lines = {}
	local expected = ns.L["MAIL_RETURNED"]:format(HELM, "Grimsby")
	for _, line in ipairs(Stub.printed) do
		if tostring(line):find(expected, 1, true) then
			lines[#lines + 1] = line
		end
	end
	return lines
end

test("a returned gift says so once at the mailbox", function()
	local ns = Harness.LoadAddon(ADDON_ROOT)
	Stub.inbox = {
		-- A gift that came back unopened.
		{
			sender = "Grimsby-Ashkandi",
			subject = ns.L["MAIL_SUBJECT"],
			hasItem = 1,
			wasReturned = true,
			link = HELM,
		},
		-- Something else that came back: not ours to speak about.
		{ sender = "Robin", subject = "Your ring", hasItem = 1, wasReturned = true, link = RING },
		-- A gift sent to this character, not returned.
		{ sender = "Keefe", subject = ns.L["MAIL_SUBJECT"], hasItem = 1, wasReturned = false, link = RING },
	}
	ns.visitMailbox()
	Stub.printed = {}
	ns.fire("MAIL_INBOX_UPDATE")
	equal(#returnedLines(ns), 1, "one line for the returned gift")
	equal(#Stub.printed, 1, "and nothing about the other mail")

	ns.fire("MAIL_INBOX_UPDATE")
	equal(#Stub.printed, 1, "not again on the next update")
end)

test("away from a mailbox nothing is said", function()
	local ns = Harness.LoadAddon(ADDON_ROOT)
	Stub.inbox = {
		{ sender = "Grimsby", subject = ns.L["MAIL_SUBJECT"], hasItem = 1, wasReturned = true, link = HELM },
	}
	Stub.printed = {}
	ns.fire("MAIL_INBOX_UPDATE")
	equal(#Stub.printed, 0, "no line")
end)
