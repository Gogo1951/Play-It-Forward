--[[
	Keeping the event log readable when a registered event is a firehose.

	UI_ERROR_MESSAGE is registered because a mail refusal sometimes arrives as a red
	error rather than as MAIL_FAILED, and CHAT_MSG_ADDON because that is how a nearby
	player's Generosity totals reach us. Both carry vastly more traffic than that: every
	combat error the client prints, and every other add-on's chatter in a city.

	Logged raw they evict the mailbox and /who entries the log exists to carry, out of a
	buffer that holds 500. Excluded outright, the log can never show a refusal arriving
	or a peer answering, which is exactly what a "why doesn't sharing work" report needs.

	So the filter keeps what the add-on acts on and counts the rest, classifying with the
	live handlers' own tests. These cases pin the three outcomes.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--------------------------------------------------------------------------------

test("a firehose of uncorrelated errors collapses to one counted row", function()
	local ns = load()
	ns:StartEventLog()

	for _ = 1, 469 do
		ns:LogEvent("UI_ERROR_MESSAGE", 56, "Ability is not ready yet.")
	end
	ns:LogEvent("MAIL_SHOW")

	equal(#ns.diagnostics.log, 1, "only the entry the log exists to carry reached the buffer")
	check(ns.diagnostics.log[1]:find("MAIL_SHOW", 1, true), "and it is that one")

	local report = ns:BuildEventLogReport()
	check(
		report:find("UI_ERROR_MESSAGE%(56, Ability is not ready yet%.%) x469"),
		"the traffic is counted, not deleted: " .. report
	)
end)

--[[
	The half that makes this a filter rather than an exclusion. Features/Mail-Sender.lua
	acts on this exact firing, so the log has to show it.
]]
test("a mail refusal is still logged in full", function()
	local ns = load()
	ns:StartEventLog()

	ns:LogEvent("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	equal(#ns.diagnostics.log, 1, "the firing the add-on acts on reached the buffer")
	check(ns.diagnostics.log[1]:find("Internal mail database error!", 1, true), "verbatim")
	equal(next(ns.diagnostics.suppressed), nil, "and nothing was counted")
end)

--[[
	Unclassifiable is signal: with nothing at the id position the thing that would have
	decided is missing, so the firing is kept rather than guessed at.
]]
test("a firing with nothing at the id position is logged verbatim", function()
	local ns = load()
	ns:StartEventLog()

	ns:LogEvent("UI_ERROR_MESSAGE", nil, "Ability is not ready yet.")

	equal(#ns.diagnostics.log, 1, "kept")
	equal(next(ns.diagnostics.suppressed), nil, "and not counted either")
end)

--[[
	The same rule on the other filtered event, where the id is the prefix and the live
	test is the one Features/Generosity-Broadcast.lua opens its handler with.
]]
test("another add-on's chatter is counted and ours is kept", function()
	local ns = load()
	ns:StartEventLog()

	ns:LogEvent("CHAT_MSG_ADDON", "DBM", "pull|10", "RAID", "Someone")
	ns:LogEvent("CHAT_MSG_ADDON", "DBM", "pull|10", "RAID", "Someone")
	ns:LogEvent("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|?", "YELL", "Giver")

	equal(#ns.diagnostics.log, 1, "our own prefix reaches the buffer")
	check(
		ns:BuildEventLogReport():find("CHAT_MSG_ADDON%(DBM, pull||10%) x2"),
		"the rest is counted, with its pipes escaped"
	)
end)

-- The counters are the log's footnote, so they go when it does.
test("stopping the log releases the counters with it", function()
	local ns = load()
	ns:StartEventLog()
	ns:LogEvent("UI_ERROR_MESSAGE", 56, "Ability is not ready yet.")
	check(next(ns.diagnostics.suppressed) ~= nil, "something was counted")

	ns:StopEventLog()

	equal(ns.diagnostics.log, nil, "the buffer is gone")
	equal(ns.diagnostics.suppressed, nil, "and so are the counters")
end)
