--[[
	What happens when the server refuses a mail.

	Observed on 1.15.8: UI_ERROR_MESSAGE 449, "Internal mail database error!". The
	add-on listened for MAIL_SUCCESS and MAIL_FAILED and nothing else, so a send the
	server rejected this way produced neither: the run sat on its 30 second result
	timeout and then reported "Waiting on confirm for X. Click Accept, then press
	Distribute to resume."

	Every word of that is wrong. There is no confirm dialog waiting, clicking Accept is
	not what resumes it, and the item never left the bag. A stall is bad; a stall that
	tells the player to do something impossible is worse, and it is the exact failure
	mode this add-on's comments keep calling out elsewhere.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local ROSTER = {
	{ name = "Mage1", level = 18, class = "MAGE" },
	{ name = "Mage2", level = 19, class = "MAGE" },
	{ name = "Priest1", level = 18, class = "PRIEST" },
}

-- Two copies of a giftable green, matched, with the mailbox open.
local function readyToSend(ns, count)
	local robe = Stub.Item({
		name = "Ivycloth Robe",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1,
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
	})
	local bag = {}
	for index = 1, (count or 2) do
		bag[index] = robe
	end
	Stub.SetBackpack(bag)
	ns.fire("MAIL_SHOW")
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
end

local function printed(pattern)
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(pattern) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------

test("a rejected mail fails its job instead of stalling the run", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	equal(#Stub.sent, 1, "the first mail went out")

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	--[[
		The run has to move on by itself. Waiting out the timeout is what produced the
		message about a confirm dialog that was never there. It is busy again straight
		away, on the next item rather than the refused one, which is the point.
	]]
	equal(#Stub.sent, 2, "it moved straight on to the next item")
	check(ns.Distributor._current.recipient ~= Stub.sent[1].recipient, "and is working on somebody else now")
end)

test("the rejection is reported against the recipient it happened to", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	local target = Stub.sent[1].recipient

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	check(printed(target), "named who it failed for: " .. target)
end)

--[[
	A name the server will not accept is not going to start working during this
	session, and the roster is a list of strangers where a stale name is expected
	rather than exceptional. Offering them again just spends another item on the same
	rejection.
]]
test("a recipient the server refused is not offered again", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	local refused = Stub.sent[1].recipient

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	check(not ns.Fairness:IsReachable(refused), refused .. " is marked unreachable")
	for _, item in ipairs(ns.UI:Items()) do
		check(not (item.recipient and item.recipient.name == refused), "nothing is still assigned to " .. refused)
	end
end)

--[[
	UI_ERROR_MESSAGE carries everything from "You are too far away" to "Your inventory
	is full". Treating any of them as a mail failure because one happened to land mid
	send would fail jobs for reasons that have nothing to do with the mail.
]]
test("an unrelated error during a send is ignored", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()

	ns.fire("UI_ERROR_MESSAGE", 50, "You are too far away!")

	check(ns.Distributor.busy, "the send is still waiting for its real result")
	equal(#Stub.sent, 1, "and nothing else was sent")
end)

test("a mail error with no send in flight is ignored", function()
	local ns = load()
	readyToSend(ns, 2)

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	equal(#Stub.sent, 0, "nothing was sent, so nothing can have failed")
	check(ns.Fairness:IsReachable("Mage1"), "and nobody was blamed for it")
end)
