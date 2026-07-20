--[[
	What the list does once items have actually gone out.

	The bug these pin: the window kept showing a delivered item, matched to the person
	it had just been mailed to and ticked to send again. Features/Mail-Sender.lua states
	the reason in its own comments -- MAIL_SUCCESS fires before the bag update arrives --
	and the post-delivery refresh read the bags at exactly that instant. The sent item
	was still in its slot, so the scan found it, and rescanBags restored the pairing it
	had just been sent under.

	It showed up as the last item of a run: every earlier slot had cleared by the time
	the run ended, so four sends left one row behind.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

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

-- A mailbox with the window open and every item paired with somebody.
local function readyToDistribute(defs, people)
	local ns = load()
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	for index, item in ipairs(ns.UI:Items()) do
		ns.UI:_setRecipient(item, people[index])
	end
	return ns
end

local KEEFE = { name = "Keefe", level = 18, class = "MAGE" }
local ROBIN = { name = "Robin", level = 18, class = "PRIEST" }

--------------------------------------------------------------------------------

test("a delivered item leaves the list before the bag catches up", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	local item = ns.UI:Items()[1]
	equal(#ns.UI:Items(), 1, "matched and ready")

	ns.UI:Distribute()
	equal(#Stub.sent, 1, "the mail went out")

	ns.fire("MAIL_SUCCESS")

	--[[
		The slot still holds the item at this instant, exactly as the client leaves it.
		The list must not be reading the bags to decide what was delivered.
	]]
	check(ns.GetItemLink(item.bag, item.slot) == item.link, "the bag has not caught up yet")
	equal(#ns.UI:Items(), 0, "the delivered item is off the list anyway")
end)

test("the last item of a run does not survive the run", function()
	local ns = readyToDistribute({ cloak("First Cloak"), cloak("Sentry Cloak") }, { KEEFE, ROBIN })
	equal(#ns.UI:Items(), 2, "two matched")

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS") -- first delivered, the mailer sends the second
	ns.fire("MAIL_SUCCESS") -- second delivered, the run finishes

	equal(#Stub.sent, 2, "both went out")
	equal(#ns.UI:Items(), 0, "and neither is still listed")
end)

test("an item that failed to send stays on the list", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()
	ns.fire("MAIL_FAILED")

	equal(#ns.UI:Items(), 1, "still there to try again")
	equal(ns.UI:Items()[1].recipient, KEEFE, "still matched to the same person")
end)

--[[
	Unticked rows are not part of the run. Clearing the window on "done" has to mean
	clearing what went, never everything that was on it.
]]
test("items that were not sent stay on the list", function()
	local ns = readyToDistribute({ cloak("First Cloak"), cloak("Kept Cloak") }, { KEEFE, ROBIN })
	local kept = ns.UI:Items()[2]
	kept.send = false

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")

	equal(#Stub.sent, 1, "only the ticked one went")
	equal(#ns.UI:Items(), 1, "the other is still listed")
	equal(ns.UI:Items()[1].link, kept.link, "and it is the one that was kept")
end)

--[[
	Asserted against the locale rather than a literal, so a reworded status stays
	passing and a status built from the wrong string does not. Matching loosely here is
	how the first version of this case passed against the bug it was written for.
]]
--[[
	A name in chat and the same name in the window should read as one person. The window
	has always class-colored its rows; the mail lines printed the bare string, so the
	running commentary on a distribution was the one place a recipient lost their color.

	Asserted through ns.ColorName rather than against a literal escape, because that
	function honours ClassColors and oUF-style overrides when the player runs one, and a
	hardcoded color here would pass while the real output disagreed with their UI.
]]
test("recipient names in chat carry their class color", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")

	local colored = ns.ColorName(KEEFE.name, KEEFE.class)
	local found = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(colored, 1, true) then
			found = true
		end
	end
	check(found, "the sent line names them in class color")
end)

test("a failed send names the recipient in color too", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()
	ns.fire("MAIL_FAILED")

	local colored = ns.ColorName(KEEFE.name, KEEFE.class)
	local found = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(colored, 1, true) then
			found = true
		end
	end
	check(found, "the failure line names them in class color")
end)

--[[
	What the player watches while a run goes out.

	Blizzard's Send Mail panel has to be open for any of this to work -- UseContainerItem
	only attaches while it is visible, and with it closed the same call drinks the potion
	instead -- so it cannot be hidden. It was left blank though: an empty To field, an
	empty body, and a subject the client had auto-filled with the item's name. That reads
	as a broken form waiting to be typed into.
]]
test("the mail panel shows who the letter is going to", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()

	equal(SendMailNameEditBox.shownText, KEEFE.name, "the To box names the recipient")
	equal(Stub.MailBodyBox.shownText, ns.Distributor:BuildBody(), "and the body is the one being sent")
end)

--[[
	The body box is not SendMailBodyEditBox on this client. That name arrives with
	Dragonflight; Classic keeps the body behind MailEditBox:GetEditBox(), which is why
	the To and Subject boxes filled and the body stayed empty. Resolved by availability
	rather than by flavour, the same way Features/Utilities.lua picks its container API.
]]
test("the body box is found under whichever name the client uses", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	--[[
		The retail shape: no MailEditBox, a plain SendMailBodyEditBox instead. A resolver
		that only knew the Classic name would leave this one empty.
	]]
	MailEditBox = nil
	SendMailBodyEditBox = Stub.NewFrame()

	ns.UI:Distribute()

	equal(SendMailBodyEditBox.shownText, ns.Distributor:BuildBody(), "filled under the retail name too")
end)

--[[
	Attaching an item writes its name into an empty subject box, so the panel showed
	"Lesser Healing Potion (2)". The subject has to be written after the attach or the
	client's guess wins.
]]
test("the subject shown is ours, not the item's name", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()

	equal(SendMailSubjectEditBox.shownText, ns.Distributor:BuildSubject(), "our subject survived the attach")
	check(not tostring(SendMailSubjectEditBox.shownText):find("Cloak"), "not the item name the client filled in")
end)

test("each letter of a run shows its own recipient", function()
	local ns = readyToDistribute({ cloak("First Cloak"), cloak("Second Cloak") }, { KEEFE, ROBIN })

	ns.UI:Distribute()
	local first = SendMailNameEditBox.shownText
	ns.fire("MAIL_SUCCESS")
	local second = SendMailNameEditBox.shownText

	check(first ~= second, ("the panel followed the run: %s then %s"):format(tostring(first), tostring(second)))
end)

--[[
	Distributing used to print the subject and then the body a line at a time, before
	sending anything. That was worth doing while the text was editable; with it fixed
	nobody can have changed it, so it was six lines of chat repeating the same paragraphs
	every run.
]]
test("distributing does not print the mail text to chat", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	Stub.printed = {}

	ns.UI:Distribute()

	for _, message in ipairs(Stub.printed) do
		for line in (ns.Distributor:BuildBody() .. "\n"):gmatch("([^\n]+)\n") do
			check(not tostring(message):find(line, 1, true), "body line not printed: " .. line:sub(1, 40))
		end
		check(not tostring(message):find("subject:"), "no subject preview: " .. tostring(message))
	end
end)

test("distributing still says how many are going", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	Stub.printed = {}

	ns.UI:Distribute()

	local announced = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(ns.L["MAIL_DISTRIBUTING"]:format(1), 1, true) then
			announced = true
		end
	end
	check(announced, "the run announces itself")
end)

--[[
	The length guard outlived the preview it was buried in. It cannot fire on the
	shipped English text, but a translation of the same paragraphs can run long and
	nothing measures those.
]]
test("an oversized body still warns before anything is sent", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	ns.L["MAIL_BODY"] = string.rep("x", 600)
	Stub.printed = {}

	ns.UI:Distribute()

	local warned = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find("600") then
			warned = true
		end
	end
	check(warned, "said the body is too long")
end)

--[[
	The window has no status line any more, so the run reports itself in chat and the
	list reports what is left. Both halves are worth pinning: a run that says nothing
	anywhere is indistinguishable from one that did not happen.
]]
test("a finished run says so in chat", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	Stub.printed = {}

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")

	local said = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find(ns.L["MAIL_DONE"]:format(1, 1), 1, true) then
			said = true
		end
	end
	check(said, "the run reported one of one delivered")
	equal(#ns.UI:Items(), 0, "and the list is what says nothing is left")
end)

test("what was kept back is still on the list after a run", function()
	local ns = readyToDistribute({ cloak("First Cloak"), cloak("Kept Cloak") }, { KEEFE, ROBIN })
	ns.UI:Items()[2].send = false

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")

	equal(#ns.UI:Items(), 1, "one delivered, one still there")
	equal(ns.UI:Items()[1].name, "Kept Cloak", "and it is the one that was kept")
end)

--[[
	Distribute is greyed until pressing it would send something. Both conditions used to
	be discovered by pressing it and reading a warning.
]]
test("Distribute is dead until a mailbox is open and something is ticked", function()
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")

	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "nothing matched yet")

	ns.UI:_setRecipient(ns.UI:Items()[1], KEEFE)
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "matched at a mailbox")

	ns.fire("MAIL_CLOSED")
	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "and dead again once you walk away")
end)

test("Distribute is dead when every row is unticked", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "ticked and matched")

	ns.UI:_setSend(ns.UI:Items()[1], false)
	ns.UI:Refresh()
	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "unticked leaves nothing to send")
end)

--[[
	SendMail has already fired by the time a run is stopped, so a confirm clicked
	afterwards still delivers. The mailer records that recipient's cooldown on this
	path; the row has to go the same way.
]]
test("a confirm clicked after the run stopped still clears its row", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()
	ns.Distributor:Stop()
	ns.fire("MAIL_SUCCESS")

	equal(#ns.UI:Items(), 0, "the delivered item is off the list")
end)

--[[
	The bags catching up is a second step, and it must not undo the first. This is the
	client's real sequence: the send lands, then the slot empties, then BAG_UPDATE.
]]
test("the bag catching up does not put the item back", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")

	Stub.SetBackpack({})
	ns.fire("BAG_UPDATE", 0)
	ns.fire("MAIL_SHOW")

	equal(#ns.UI:Items(), 0, "still gone")
end)
