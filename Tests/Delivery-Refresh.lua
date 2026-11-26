--[[
	What the list does once items have gone out. MAIL_SUCCESS fires before the bag update, so a
	refresh reading the bags then still finds the sent item and would restore its pairing.
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
	ns.visitMailbox()
	for index, item in ipairs(ns.UI:Items()) do
		ns.UI:SetRecipient(item, people[index])
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

-- Through ns.ColorName, not a literal escape: it honours ClassColors and oUF-style overrides.
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
	Blizzard's Send Mail panel must stay open (UseContainerItem only attaches while it is visible;
	closed, it uses the item), so it shows the letter rather than a blank form.
]]
test("the mail panel shows who the letter is going to", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	ns.UI:Distribute()

	equal(SendMailNameEditBox.shownText, KEEFE.name, "the To box names the recipient")
	equal(Stub.MailBodyBox.shownText, ns.Distributor:BuildBody(), "and the body is the one being sent")
end)

--[[
	The body box is resolved by availability, not flavor: Classic keeps it behind
	MailEditBox:GetEditBox(), and SendMailBodyEditBox arrives with Dragonflight.
]]
test("the body box is found under whichever name the client uses", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })

	-- The retail shape: no MailEditBox, a plain SendMailBodyEditBox.
	MailEditBox = nil
	SendMailBodyEditBox = Stub.NewFrame()

	ns.UI:Distribute()

	equal(SendMailBodyEditBox.shownText, ns.Distributor:BuildBody(), "filled under the retail name too")
end)

-- Attaching writes the item's name into an empty subject box, so ours must be written after.
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

-- The window may be closed by the time a run ends, so the run reports itself in chat too.
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

test("Distribute is dead until a mailbox is open and something is ticked", function()
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.visitMailbox()

	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "nothing matched yet")

	ns.UI:SetRecipient(ns.UI:Items()[1], KEEFE)
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "matched at a mailbox")

	--[[
		The re-check is deferred a frame by design -- the mailbox closing and the interaction
		manager reporting it are not ordered -- and the stub's timers never fire on their own.
	]]
	ns.fire("MAIL_CLOSED")
	Stub.FireTimers()
	equal(ns.UI.frame.distributeButton:IsEnabled(), false, "and dead again once you walk away")
end)

-- Loot taken with the window open is matched from those already found, not left under No Recipient.

test("an item arriving with the window open is matched from those already found", function()
	local ns = load()
	Stub.SetBackpack({ cloak("First Cloak") })
	ns.visitMailbox()
	Stub.whoResults = {
		{ name = "Keefe", level = 18, class = "MAGE" },
		{ name = "Robin", level = 18, class = "PRIEST" },
	}
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	check(ns.UI:Items()[1].recipient ~= nil, "the first cloak is matched")

	Stub.SetBackpack({ cloak("First Cloak"), cloak("Second Cloak") })
	ns.fire("BAG_UPDATE", 0)
	Stub.FireTimers()

	local arrived
	for _, item in ipairs(ns.UI:Items()) do
		if item.name == "Second Cloak" then
			arrived = item
		end
	end
	check(arrived ~= nil, "the new cloak is listed")
	check(arrived.recipient ~= nil, "and matched to the one still free, not left with nobody")
end)

test("Distribute is dead when every row is unticked", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "ticked and matched")

	ns.UI:ToggleRow(ns.UI:Items()[1], false)
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
	ns.visitMailbox()

	equal(#ns.UI:Items(), 0, "still gone")
end)

--[[
	Distribute is busy for the whole run, not just the one send in flight, and goes live again at
	every pause, which is when the chat lines tell the player to press it. While the run goes out
	it reads Stop, and is live for that.
]]
test("Distribute reads Stop while a run is going", function()
	local ns = readyToDistribute({ cloak(), cloak("Second Cloak") }, { KEEFE, ROBIN })
	local flips = 0
	ns.UI:Distribute()
	ns.Distributor.onStateChange = (function(inner)
		return function()
			flips = flips + 1
			inner()
		end
	end)(ns.Distributor.onStateChange)

	equal(ns.Distributor:IsRunning(), true, "running from Start")
	equal(ns.UI.frame.distributeButton:GetText(), ns.L["BUTTON_STOP"], "the button reads Stop mid-run")
	equal(ns.UI.frame.distributeButton:IsEnabled(), true, "and Stop can be pressed")

	ns.fire("MAIL_SUCCESS")
	equal(ns.Distributor:IsRunning(), true, "still running between sends")

	ns.fire("MAIL_SUCCESS")
	equal(ns.Distributor:IsRunning(), false, "finished")
	equal(flips, 1, "one flip, at the finish")
end)

test("a confirm left waiting pauses the run", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	ns.UI:Distribute()
	equal(ns.Distributor:IsRunning(), true, "running")

	Stub.FireTimers()
	equal(ns.Distributor:IsRunning(), false, "paused once the confirm timed out")
end)

test("stopping the run clears it", function()
	local ns = readyToDistribute({ cloak() }, { KEEFE })
	ns.UI:Distribute()
	ns.Distributor:Stop()
	equal(ns.Distributor:IsRunning(), false, "stopped")
end)
