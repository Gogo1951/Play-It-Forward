--[[
	Changing one row must not change another.

	The dropdown used to offer anybody in range, including people already holding an
	item, and picking one of them took their item off them:

	  "Rustoleum-Pagle was set for [Hefty Battlehammer of the Eagle], reassigned to
	   [Scouting Tunic of the Eagle]."

	Nobody asked for that. One row was edited and a different row silently lost its
	recipient, which is the kind of change a player has no way to see coming and no
	reason to expect.

	One item per person is still the rule -- two greens arriving together from a
	stranger reads as spam. It is now kept by not offering somebody who already has one,
	rather than by taking it off them.
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

-- Two giftable greens, both matched, exactly as the window would show them.
local function twoMatched(ns)
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
	Stub.SetBackpack({ robe, robe })
	ns.fire("MAIL_SHOW")
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()[1], ns.UI:Items()[2]
end

local function optionFor(ns, item, name)
	for _, option in ipairs(ns.UI:_pickerOptions(item)) do
		if option.pick and option.pick.name == name then
			return option
		end
	end
	return nil
end

--------------------------------------------------------------------------------

test("picking somebody already holding an item leaves that item alone", function()
	local ns = load()
	local first, second = twoMatched(ns)
	local held = first.recipient

	--[[
		The reported case: the player edits the second row and picks the person already
		on the first. The first row must not move.
	]]
	ns.UI:_setRecipient(second, held)

	equal(first.recipient, held, "the first row kept its recipient")
	check(second.recipient ~= held, "and the second row did not take them")
end)

test("the dropdown does not offer somebody who already has one", function()
	local ns = load()
	local first, second = twoMatched(ns)

	local option = optionFor(ns, second, first.recipient.name)
	check(option ~= nil, "they are still listed, so the player can see why")
	check(option and option.disabled, "but cannot be picked")
end)

test("somebody free is offered and can be picked", function()
	local ns = load()
	local first, second = twoMatched(ns)

	--[[
		Priest1 is a candidate for both robes and, with two mages taking the first two,
		is the one left over.
	]]
	local free
	for _, person in ipairs({ "Mage1", "Mage2", "Priest1" }) do
		local option = optionFor(ns, second, person)
		if option and not option.disabled and person ~= (second.recipient and second.recipient.name) then
			free = option
		end
	end
	check(free ~= nil, "somebody unassigned is offered")

	if free then
		ns.UI:_setRecipient(second, free.pick)
		equal(second.recipient.name, free.pick.name, "and picking them works")
		equal(first.recipient ~= nil, true, "without disturbing the other row")
	end
end)

--[[
	The way to move an item between two people, and the reason blocking is not a dead
	end: clear the row that holds them first, then pick them on the row you want.
]]
test("clearing a row frees its recipient for another row", function()
	local ns = load()
	local first, second = twoMatched(ns)
	local held = first.recipient

	ns.UI:_setRecipient(first, nil) -- the "vendor / don't send" option
	equal(first.recipient, nil, "the first row let them go")

	local option = optionFor(ns, second, held.name)
	check(option and not option.disabled, "they are selectable again")

	ns.UI:_setRecipient(second, held)
	equal(second.recipient, held, "and the second row can have them")
end)

--[[
	A name the mail system already refused cannot receive anything, so offering it by
	hand only spends a press on the same rejection.
]]
test("a recipient the server refused is offered but not selectable", function()
	local ns = load()
	local _, second = twoMatched(ns)
	local target = second.recipient
	ns.UI:_setRecipient(second, nil)
	ns.Fairness:MarkUnreachable(target.name)

	local option = optionFor(ns, second, target.name)
	check(option ~= nil, "still shown, so the reason is visible")
	check(option and option.disabled, "but not selectable")
end)

--[[
	The dropdown is one 18-pixel row per entry, holding a cross-realm name, a level, a
	class and a note, inside a list that will not grow past PICKER_MAX_WIDTH. Nothing in
	a headless run draws it, so the guard is on the text: a note long enough to push an
	entry past the width is a note that gets cut off on screen.

	"(already has one, clear that row first)" was one, and it took the ends off every
	greyed row in the list. The advice moved to a single hint line at the bottom.
]]
test("the notes beside a name stay short enough to fit", function()
	local ns = load()
	local first, second = twoMatched(ns)
	ns.Fairness:MarkUnreachable(ns.UI:Items()[2].recipient.name)

	for _, key in ipairs({ "PICKER_NOTE_HAS_ONE", "PICKER_NOTE_REFUSED", "PICKER_NOTE_RECENT" }) do
		check(#ns.L[key] <= 12, ("%s is %d chars: %q"):format(key, #ns.L[key], ns.L[key]))
	end

	--[[
		Measured on the whole entry, escapes stripped, since that is what has to fit. A
		long cross-realm name plus a level plus a class is most of the row on its own, so
		the bound is generous -- it is here to catch a blowout, not to police wording. The
		note that broke this took entries to 63.
	]]
	for _, option in ipairs(ns.UI:_pickerOptions(first)) do
		local plain = option.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		check(#plain <= 50, ("entry is %d chars: %q"):format(#plain, plain))
	end
end)

--[[
	Said once for the list instead of on every greyed row, which is what made the rows
	too wide. It is not selectable: it is a caption, not a candidate.
]]
test("a hint explains the greyed names, once", function()
	local ns = load()
	local first = twoMatched(ns)

	local hints = 0
	for _, option in ipairs(ns.UI:_pickerOptions(first)) do
		if option.text:find(ns.L["PICKER_HINT_GREYED"], 1, true) then
			hints = hints + 1
			check(option.disabled, "the hint cannot be picked")
			check(option.pick == nil, "and is not a candidate")
		end
	end
	equal(hints, 1, "exactly one hint line")
end)

test("no hint when every name in the list is selectable", function()
	local ns = load()
	Stub.SetBackpack({
		Stub.Item({
			name = "Ivycloth Robe",
			quality = 2,
			reqLevel = 20,
			itemLevel = 24,
			equipLoc = "INVTYPE_CHEST",
			classID = 4,
			subclassID = 1,
			bindType = 2,
			stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
		}),
	})
	ns.fire("MAIL_SHOW")
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local item = ns.UI:Items()[1]
	ns.UI:_setRecipient(item, nil) -- free everybody

	for _, option in ipairs(ns.UI:_pickerOptions(item)) do
		check(not option.text:find(ns.L["PICKER_HINT_GREYED"], 1, true), "no hint when nothing is greyed")
	end
end)

test("nothing is reassigned behind the player's back", function()
	local ns = load()
	local first, second = twoMatched(ns)
	Stub.printed = {}

	ns.UI:_setRecipient(second, first.recipient)

	for _, message in ipairs(Stub.printed) do
		check(not tostring(message):find("reassigned"), "no reassignment announced: " .. tostring(message))
	end
end)
