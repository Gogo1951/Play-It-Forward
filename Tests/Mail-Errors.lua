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
		message about a confirm dialog that was never there. It moves on after the short
		settle window, on the next item rather than the refused one, which is the point.
	]]
	Stub.FireTimers()
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
	Observed on Forever 1.60.1: mailing somebody of the other faction answers
	ERR_PLAYER_WRONG_FACTION, "Target is unfriendly." -- a refusal without the ERR_MAIL
	prefix, so it stalled the run on its timeout exactly as the database error once did.
]]
test("a wrong-faction refusal fails its job and marks the recipient", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	local refused = Stub.sent[1].recipient

	ns.fire("UI_ERROR_MESSAGE", 1, ERR_PLAYER_WRONG_FACTION)

	Stub.FireTimers()
	equal(#Stub.sent, 2, "it moved straight on to the next item")
	check(not ns.Fairness:IsReachable(refused), refused .. " is marked unreachable")
end)

--[[
	A recipient who refused one parcel refuses the rest. Your own alt can hold several items in
	one run, so a deleted alt was refused once per item, and the second refusal stopped the run
	before anybody else was mailed.
]]
test("the rest of a refused recipient's items stay unsent and the run goes on", function()
	local ns = load()
	ns.db.global.characters["Sparkle-Test"] =
		{ name = "Sparkle", realm = "Test", class = "MAGE", level = 12, faction = "Alliance" }
	readyToSend(ns, 3)
	local items = ns.UI:Items()
	equal(items[1].recipient and items[1].recipient.name, "Sparkle", "the alt holds the first")
	equal(items[2].recipient and items[2].recipient.name, "Sparkle", "and the second")
	ns.UI:SetRecipient(items[3], { name = "Mage1", level = 18, class = "MAGE" })

	ns.UI:Distribute()
	equal(Stub.sent[1] and Stub.sent[1].recipient, "Sparkle", "the first goes to the alt")
	ns.fire("UI_ERROR_MESSAGE", 1, ERR_MAIL_TARGET_NOT_FOUND)
	Stub.FireTimers()

	equal(#Stub.sent, 2, "one more mail went out")
	equal(Stub.sent[2].recipient, "Mage1", "to somebody else, not the alt that refused")
	check(not printed(ns.L["MAIL_ABORTED"]), "the run was not aborted")
	equal(#ns.UI:Items(), 3, "nothing delivered yet, so every row is still listed")
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

--[[
	One refusal can arrive as both signals. Counted twice, the second lands on the next
	parcel: it blames the wrong recipient and trips the two-error abort on one bad name.
]]
local function countPrinted(pattern)
	local found = 0
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(pattern) then
			found = found + 1
		end
	end
	return found
end

test("a refusal reported as a UI error and MAIL_FAILED counts once", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	local refused = Stub.sent[1].recipient

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)
	ns.fire("MAIL_FAILED")

	equal(countPrinted(refused), 1, "one failure line for " .. refused)
	equal(ns.Distributor.errors, 1, "counted once")
	check(not printed(ns.L["MAIL_ABORTED"]), "the run was not aborted")

	Stub.FireTimers()
	equal(#Stub.sent, 2, "and the next mail still goes out")
end)

test("a UI error after MAIL_FAILED still marks the refused recipient", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	local refused = Stub.sent[1].recipient

	ns.fire("MAIL_FAILED")
	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	check(not ns.Fairness:IsReachable(refused), refused .. " is marked unreachable")
	for _, item in ipairs(ns.UI:Items()) do
		check(not (item.recipient and item.recipient.name == refused), "nothing is still assigned to " .. refused)
	end
	equal(ns.Distributor.errors, 1, "and the failure was counted once")
end)

test("a mail error with no send in flight is ignored", function()
	local ns = load()
	readyToSend(ns, 2)

	ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)

	equal(#Stub.sent, 0, "nothing was sent, so nothing can have failed")
	check(ns.Fairness:IsReachable("Mage1"), "and nobody was blamed for it")
end)

--[[
	A wrong-faction refusal is about one recipient, not the run. The faction filter on /who
	cannot place every race name (female names differ in some locales), so two of them can
	land back to back, and counting them would abort a run that is working.
]]
test("back-to-back wrong-faction refusals do not abort the run", function()
	local ns = load()
	readyToSend(ns, 3)
	ns.UI:Distribute()

	ns.fire("UI_ERROR_MESSAGE", 1, ERR_PLAYER_WRONG_FACTION)
	Stub.FireTimers()
	ns.fire("UI_ERROR_MESSAGE", 1, ERR_PLAYER_WRONG_FACTION)
	Stub.FireTimers()

	check(not printed(ns.L["MAIL_ABORTED"]), "the run was not aborted")
	equal(ns.Distributor.errors, 0, "neither refusal counted toward the abort")
	equal(#Stub.sent, 3, "the third job was attempted")
end)

test("back-to-back MAIL_FAILED still abort the run", function()
	local ns = load()
	readyToSend(ns, 3)
	ns.UI:Distribute()

	ns.fire("MAIL_FAILED")
	Stub.FireTimers()
	ns.fire("MAIL_FAILED")
	Stub.FireTimers()

	check(printed(ns.L["MAIL_ABORTED"]), "the run was aborted")
	equal(#Stub.sent, 2, "and the third job was never attempted")
end)

--[[
	The client can report a refusal as a UI error inside the attach call itself. The handler
	fails the job there and then, so the run must not also carry on with it, finish a second
	time, or blame the recipient for a refusal about the item.
]]
test("a refusal raised inside the attach fails the job once", function()
	local ns = load()
	readyToSend(ns, 2)
	local attach = C_Container.UseContainerItem
	local refusedOnce = false
	C_Container.UseContainerItem = function(bag, slot)
		if not refusedOnce then
			refusedOnce = true
			ns.fire("UI_ERROR_MESSAGE", 449, ERR_MAIL_DATABASE_ERROR)
			return
		end
		return attach(bag, slot)
	end
	ns.UI:Distribute()
	local blamed = ns.Distributor._current.recipient

	equal(#Stub.sent, 0, "the refused item was never sent")
	check(not printed(ns.L["MAIL_ATTACH_FAILED"]:sub(1, 12)), "no second failure line for the same item")
	check(ns.Fairness:IsReachable(blamed), "the recipient was not blamed for an item refusal")

	Stub.FireTimers()
	equal(#Stub.sent, 1, "the run moved on to the next item")
	ns.fire("MAIL_SUCCESS")
	local doneLines = 0
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find("Done%.") then
			doneLines = doneLines + 1
		end
	end
	equal(doneLines, 1, "the run finished exactly once")
	C_Container.UseContainerItem = attach
end)

--[[
	A send that timed out waiting on its confirm can still land. Distribute pressed before it
	does must not start a run whose first job would be credited with that late result.
]]
test("Distribute waits on a send still awaiting its result", function()
	local ns = load()
	readyToSend(ns, 2)
	ns.UI:Distribute()
	equal(#Stub.sent, 1, "the first mail went out")
	Stub.FireTimers()
	check(ns.Distributor._awaiting ~= nil, "the timeout left it awaiting its result")

	ns.Distributor:Start({ { bag = 0, slot = 2, link = "x", recipient = "Someone" } })
	equal(#Stub.sent, 1, "no new send started")
	check(printed(ns.L["MAIL_STILL_SENDING"]), "and the player is told why")

	Stub.now = Stub.now + 60
	ns.Distributor:Start({})
	check(ns.Distributor._awaiting == nil, "a send that never answered stops holding Distribute back")
end)
