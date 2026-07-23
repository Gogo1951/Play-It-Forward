--[[
	The player's hand is sovereign in the dropdown (maintainer ruling, 2026-07-23).

	Every candidate in range is offered and every one can be picked -- somebody already
	holding another row, somebody the server refused earlier, somebody on cooldown. The
	notes beside a name ("has one", "refused", "recent") are information, never gates.
	Picking a name that holds another row takes it from that row, which returns to
	auto-assignment and its search reopens; the change is visible on screen the moment
	it happens, and nothing announces it in chat.

	One item per person stays the ALLOCATOR's rule -- two greens arriving together from
	a stranger reads as spam -- so the automatic passes never double up. The player
	overriding that by hand is the player's business.

	The list ends with a divider and "Find Recipients for This Item": one press of a
	targeted search over just that item's band, for when the names on offer are not
	good enough.
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

test("picking somebody already holding an item takes them from it", function()
	local ns = load()
	local first, second = twoMatched(ns)
	local held = first.recipient

	ns.UI:_setRecipient(second, held)

	equal(second.recipient, held, "the player's pick lands")
	equal(first.recipient, nil, "the row that held them lets go")
	check(not first.pinned, "and returns to auto-assignment rather than reading as a deliberate keep")
end)

test("somebody who already has one is offered with a note, not a gate", function()
	local ns = load()
	local first, second = twoMatched(ns)

	local option = optionFor(ns, second, first.recipient.name)
	check(option ~= nil, "they are listed")
	check(option and not option.disabled, "and can be picked")
	check(
		option and option.text:find(ns.L["PICKER_NOTE_HAS_ONE"], 1, true) ~= nil,
		"with the note saying why to think twice"
	)
end)

test("somebody free is offered and can be picked", function()
	local ns = load()
	local first, second = twoMatched(ns)

	--[[
		Priest1 is a candidate for both robes and, with two mages taking the first two,
		is the one left over. Nothing is disabled any more, so "free" is read off the
		has-one note: the entry without it is the person no row holds.
	]]
	local free
	for _, person in ipairs({ "Mage1", "Mage2", "Priest1" }) do
		local option = optionFor(ns, second, person)
		local held = option and option.text:find(ns.L["PICKER_NOTE_HAS_ONE"], 1, true)
		if option and not held and person ~= (second.recipient and second.recipient.name) then
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
	The gentler of the two ways to move a name between rows: clear the holding row
	first, then pick them fresh -- no steal involved, nothing else changes.
]]
test("clearing a row frees its recipient for another row", function()
	local ns = load()
	local first, second = twoMatched(ns)
	local held = first.recipient

	ns.UI:_setRecipient(first, nil) -- the Keep Item option
	equal(first.recipient, nil, "the first row let them go")

	local option = optionFor(ns, second, held.name)
	check(option and not option.disabled, "they are selectable again")

	ns.UI:_setRecipient(second, held)
	equal(second.recipient, held, "and the second row can have them")
end)

--[[
	A refusal is this session's history, not a law: the mail will likely bounce again,
	but retrying a name is the player's call to make.
]]
test("a recipient the server refused can still be picked by hand", function()
	local ns = load()
	local _, second = twoMatched(ns)
	local target = second.recipient
	ns.UI:_setRecipient(second, nil)
	ns.Fairness:MarkUnreachable(target.name)

	local option = optionFor(ns, second, target.name)
	check(option ~= nil, "still shown")
	check(option and not option.disabled, "and selectable")
	check(option and option.text:find(ns.L["PICKER_NOTE_REFUSED"], 1, true) ~= nil, "with the refusal noted")

	ns.UI:_setRecipient(second, target)
	equal(second.recipient, target, "the pick lands")
end)

--[[
	The dropdown is one 18-pixel row per entry, holding a cross-realm name, a level, a
	class and a note, inside a list that will not grow past PICKER_MAX_WIDTH. Nothing in
	a headless run draws it, so the guard is on the text: a note long enough to push an
	entry past the width is a note that gets cut off on screen. "(already has one, clear
	that row first)" was one, and it took the ends off every noted row in the list.
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
		local plain = (option.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		check(#plain <= 50, ("entry is %d chars: %q"):format(#plain, plain))
	end
end)

--------------------------------------------------------------------------------
-- The checkbox is always live
--------------------------------------------------------------------------------

--[[
	A disabled checkbox is a dead end the player cannot see past: keep an item once and
	nothing on the row offered a way back. The box is always clickable now -- on a row
	with a recipient it is the send switch, and on a kept or unmatched row ticking it
	means "match this again": the pin comes off and the allocator runs.
]]
test("an unticked row ticks back on", function()
	local ns = load()
	local first = twoMatched(ns)

	ns.UI:_toggleRow(first, false)
	equal(first.send, false, "unticked by hand")

	ns.UI:_toggleRow(first, true)
	equal(first.send, true, "and ticked right back")
end)

test("ticking a kept row asks for a match again", function()
	local ns = load()
	local first = twoMatched(ns)

	ns.UI:_pickerSelect(first, { clear = true })
	equal(first.recipient, nil, "kept: no name, pinned")

	ns.UI:_toggleRow(first, true)
	check(not first.pinned, "the pin came off")
	check(first.recipient ~= nil, "somebody from the pool took it again")
	equal(first.send, true, "ticked, since they are in contention")
end)

test("ticking a row with nobody around snaps back", function()
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

	local item = ns.UI:Items()[1]
	ns.UI:_toggleRow(item, true)
	equal(item.recipient, nil, "an empty pool has nobody to give")
	equal(item.send, false, "so the box shows unchecked again")
end)

--------------------------------------------------------------------------------
-- Keep Item
--------------------------------------------------------------------------------

--[[
	"Keep Item", not "vendor / disenchant": the add-on stopped telling the player what
	to do with what stays. Keeping unchecks the row, clears its name and pins it, so it
	sits under the Kept heading and nothing rebuilds over the choice.
]]
test("the first entry is Keep Item, and picking it keeps the row", function()
	local ns = load()
	local first = twoMatched(ns)
	check(first.recipient ~= nil and first.send, "matched and ticked to start")

	local options = ns.UI:_pickerOptions(first)
	check(options[1].clear, "the keep option leads the list")
	check(options[1].text:find(ns.L["PICKER_KEEP_OPTION"], 1, true) ~= nil, "and says Keep Item")

	ns.UI:_pickerSelect(first, options[1])
	equal(first.recipient, nil, "the name is gone")
	equal(first.send, false, "the row is unchecked")
	check(first.pinned, "and the choice is pinned")
end)

--[[
	The name is already class-colored, so the class word beside it said nothing twice
	and spent a third of the row saying it.
]]
test("a dropdown entry is name and level, with no class word", function()
	local ns = load()
	Stub.SetBackpack({
		Stub.Item({
			name = "Bluegill Kukri",
			quality = 2,
			reqLevel = 19,
			itemLevel = 24,
			equipLoc = "INVTYPE_WEAPONMAINHAND",
			classID = 2,
			subclassID = 7,
			bindType = 2,
			stats = {},
		}),
	})
	ns.fire("MAIL_SHOW")
	Stub.whoResults = { { name = "Willump", level = 18, class = "WARRIOR" } }
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local option = optionFor(ns, ns.UI:Items()[1], "Willump")
	check(option ~= nil, "the warrior is offered")
	check(option and option.text:find("Willump", 1, true) ~= nil, "by name")
	check(option and option.text:find("(18)", 1, true) ~= nil, "with level")
	check(option and not option.text:find("Warrior", 1, true), "and no class word, the color says it")
end)

--------------------------------------------------------------------------------
-- The targeted search at the bottom of the list
--------------------------------------------------------------------------------

test("the list ends with a divider and a targeted search", function()
	local ns = load()
	local first = twoMatched(ns)

	local options = ns.UI:_pickerOptions(first)
	local last, divider = options[#options], options[#options - 1]

	check(divider and divider.separator, "a divider sits above the action")
	check(divider and divider.disabled, "and is not clickable")
	check(last and last.text:find(ns.L["PICKER_FIND_FOR_ITEM"], 1, true) ~= nil, "the action is the last entry")
	check(last and not last.disabled, "and is clickable")
	check(last and last.findForItem, "carrying the flag the picker routes on")
end)

test("the targeted search plans only this item's band", function()
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
		Stub.Item({
			name = "Veteran Sword",
			quality = 2,
			reqLevel = 45,
			itemLevel = 48,
			equipLoc = "INVTYPE_WEAPONMAINHAND",
			classID = 2,
			subclassID = 7,
			bindType = 2,
			stats = { ITEM_MOD_STRENGTH_SHORT = 8 },
		}),
	})
	ns.fire("MAIL_SHOW")

	local robe
	for _, item in ipairs(ns.UI:Items()) do
		if item.name == "Ivycloth Robe" then
			robe = item
		end
	end

	Stub.now = Stub.now + 60
	ns.UI:_pickerSelect(robe, { findForItem = true })

	local query = Stub.whoQueries[#Stub.whoQueries]
	check(query and query:find("18%-19") ~= nil, "the robe's band went out: " .. tostring(query))
	check(query and not query:find("43%-44"), "and the sword's did not")
	equal(robe.recipient, nil, "picking the search changes nothing on the row")
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
