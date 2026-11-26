--[[
	The dropdown lists on the shared menu plate, all through ns.Picker: each row's recipient list
	and the top bar's Level Rule, Gear and Disenchant lists.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	local ns = Harness.LoadAddon(ADDON_ROOT)
	ns.fire("PLAYER_LOGIN")
	return ns
end

local ROSTER = {
	{ name = "Mage1", level = 18, class = "MAGE" },
	{ name = "Mage2", level = 19, class = "MAGE" },
	{ name = "Priest1", level = 18, class = "PRIEST" },
}

local function robe()
	return Stub.Item({
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
end

-- Two giftable greens, both matched.
local function twoMatched(ns)
	local item = robe()
	Stub.SetBackpack({ item, item })
	ns.visitMailbox()
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()[1], ns.UI:Items()[2]
end

local function withEnchanter(ns)
	local key = "Dusty-Test"
	ns.db.global.characters[key] = { name = "Dusty", realm = "Test", class = "MAGE", level = 40, faction = "Alliance" }
	ns.Alts:SetDisenchanter(key)
	return key
end

local function find(options, matches)
	for _, option in ipairs(options) do
		if matches(option) then
			return option
		end
	end
end

local function checked(options)
	local out = {}
	for _, option in ipairs(options) do
		if option.selected then
			out[#out + 1] = option
		end
	end
	return out
end

-- The list as the kit draws it, from a frame-less button.
local function opened(ns, options, onSelect)
	local anchor = CreateFrame("Button")
	ns.Picker:Open(anchor, options, onSelect or function() end)
	return ns.Picker.frame, anchor
end

local function rowFor(ns, matches)
	for _, row in ipairs(ns.Picker.frame.rows) do
		if row.entry and row.entry.option and matches(row.entry.option) then
			return row
		end
	end
end

--------------------------------------------------------------------------------
-- The check
--------------------------------------------------------------------------------

test("the row's name carries the check, and nothing else does", function()
	local ns = load()
	local first = twoMatched(ns)
	local options = ns.UI:PickerOptions(first)
	local picks = checked(options)
	equal(#picks, 1, "one checked choice")
	equal(picks[1] and picks[1].pick and picks[1].pick.name, first.recipient.name, "the row's own recipient")
	equal(picks[1] and picks[1].kind, "choice", "drawn as a choice, with the check")
end)

test("Keep Item carries the check once the player keeps the row", function()
	local ns = load()
	local first = twoMatched(ns)
	ns.UI:PickerSelect(first, { clear = true })
	local picks = checked(ns.UI:PickerOptions(first))
	equal(#picks, 1, "one checked choice")
	check(picks[1] and picks[1].clear, "Keep Item")
end)

test("Disenchant carries the check once the row goes to the enchanter", function()
	local ns = load()
	withEnchanter(ns)
	local first = twoMatched(ns)
	local disenchant = find(ns.UI:PickerOptions(first), function(option)
		return option.pick and option.pick.disenchant
	end)
	check(disenchant and not disenchant.disabled, "offered with an enchanter picked")
	ns.UI:PickerSelect(first, disenchant)
	local picks = checked(ns.UI:PickerOptions(first))
	equal(#picks, 1, "one checked choice")
	check(picks[1] and picks[1].pick and picks[1].pick.disenchant, "Disenchant, not the enchanter's name")
end)

test("Disenchant with no enchanter is gray and still explains itself", function()
	local ns = load()
	local first = twoMatched(ns)
	local options = ns.UI:PickerOptions(first)
	local disenchant = find(options, function(option)
		return option.text and option.text:find(ns.DisenchantName(), 1, true)
	end)
	check(disenchant and disenchant.disabled, "disabled")
	equal(disenchant and disenchant.tooltip, ns.L["PICKER_DISENCHANT_NONE_DESCRIPTION"], "with its tooltip")

	opened(ns, options)
	local row = rowFor(ns, function(option)
		return option == disenchant
	end)
	check(row and row.entry.disabled, "the kit draws it disabled")
	equal(type(row and row.entry.tooltip), "function", "and still shows its tooltip")
end)

--------------------------------------------------------------------------------
-- Notes on the right
--------------------------------------------------------------------------------

test("a note sits on the name's right, gray, without brackets", function()
	local ns = load()
	local first, second = twoMatched(ns)
	local option = find(ns.UI:PickerOptions(second), function(candidate)
		return candidate.pick and candidate.pick.name == first.recipient.name
	end)
	equal(option and option.kind, "choice", "a choice, keeping the check's room so the names line up")
	equal(option and option.right, ns.L["PICKER_TAG_HAS_ONE"], "Has One")
	equal(option and option.rightColor, "MUTED", "in gray")
	for _, key in ipairs({ "PICKER_TAG_HAS_ONE", "PICKER_TAG_REFUSED", "PICKER_TAG_RECENT" }) do
		check(not ns.L[key]:find("[%(%)%[%]]"), key .. " has no brackets")
	end
end)

--------------------------------------------------------------------------------
-- Grouping
--------------------------------------------------------------------------------

test("the recipient list has one line, under a spacer, above Disenchant", function()
	local ns = load()
	local first = twoMatched(ns)
	local options = ns.UI:PickerOptions(first)
	local lines, at = 0, nil
	for index, option in ipairs(options) do
		if option.kind == "separator" then
			lines, at = lines + 1, index
		end
	end
	equal(lines, 1, "one line")
	equal(options[at - 1] and options[at - 1].kind, "spacer", "a spacer above it")
	check(
		options[at + 1] and options[at + 1].text and options[at + 1].text:find(ns.DisenchantName(), 1, true),
		"Disenchant right under it"
	)
end)

test("a line in an old-style list gets its spacer", function()
	local ns = load()
	local entries = ns.Picker:Entries(CreateFrame("Button"), {
		{ text = "One" },
		{ separator = true },
		{ text = "Two" },
	}, function() end)
	local kinds = {}
	for _, entry in ipairs(entries) do
		kinds[#kinds + 1] = entry.kind
	end
	equal(table.concat(kinds, " "), "choice spacer separator choice", "spacer, then the line")
end)

--------------------------------------------------------------------------------
-- The top bar's lists
--------------------------------------------------------------------------------

test("a top bar list checks the choice its button shows", function()
	local ns = load()
	local options = ns.UI:RarityPickerOptions()
	local anchor = CreateFrame("Button")
	anchor.text:SetText(options[2].text)
	local entries = ns.Picker:Entries(anchor, options, function() end)
	equal(entries[1].selected, false, "not the first")
	equal(entries[2].selected, true, "the shown one")
	equal(entries[3].selected, false, "not the last")
end)

test("the Disenchant list checks the enchanter its button names", function()
	local ns = load()
	local key = withEnchanter(ns)
	local options = ns.UI:DisenchanterPickerOptions()
	local anchor = CreateFrame("Button")
	local _, alt = ns.Alts:Disenchanter()
	anchor.text:SetText(ns.ColorName(ns.Alts:Address(alt), alt.class))
	local entries = ns.Picker:Entries(anchor, options, function() end)
	local entry = find(entries, function(candidate)
		return candidate.option.altKey == key
	end)
	equal(entry and entry.selected, true, "name and level against the button's name")
end)

test("a pick from a top bar list runs and closes the list", function()
	local ns = load()
	local got
	opened(ns, ns.UI:RarityPickerOptions(), function(option)
		got = option.quality
	end)
	check(ns.Picker.frame:IsShown(), "open")
	local row = rowFor(ns, function(option)
		return option.quality == 3
	end)
	row:GetScript("OnClick")(row)
	equal(got, 3, "the pick ran")
	equal(ns.Picker.frame:IsShown(), false, "and the list closed")
end)

--------------------------------------------------------------------------------
-- Never Give Away
--------------------------------------------------------------------------------

test("Never Give Away hands the item to the never-give list and closes", function()
	local ns = load()
	local first = twoMatched(ns)
	local given
	ns.Bags = ns.Bags or {}
	ns.Bags.NeverGive = function(_, itemID)
		given = itemID
	end
	opened(ns, ns.UI:PickerOptions(first), function(option)
		ns.UI:PickerSelect(first, option)
	end)
	local row = rowFor(ns, function(option)
		return option.neverGive
	end)
	check(row ~= nil, "the last action is drawn")
	row:GetScript("OnClick")(row)
	equal(given, first.itemID, "this row's item")
	equal(ns.Picker.frame:IsShown(), false, "and the list closed")
end)

test("Never Give Away does nothing harmful before the never-give list exists", function()
	local ns = load()
	local first = twoMatched(ns)
	local saved = ns.Bags
	ns.Bags = nil
	local recipient = first.recipient
	ns.UI:PickerSelect(first, { neverGive = true })
	ns.Bags = saved
	equal(first.recipient, recipient, "the row is unchanged")
end)

--------------------------------------------------------------------------------
-- Escape
--------------------------------------------------------------------------------

local function contains(list, value)
	for _, entry in ipairs(list) do
		if entry == value then
			return true
		end
	end
	return false
end

test("while the list is open, Escape closes the list and not the window", function()
	local ns = load()
	local first = twoMatched(ns)
	check(contains(UISpecialFrames, "PlayItForwardMailFrame"), "the window is on the Escape list")
	local frame = opened(ns, ns.UI:PickerOptions(first))
	check(contains(UISpecialFrames, "PlayItForwardRecipientPicker"), "the list is on it")
	check(not contains(UISpecialFrames, "PlayItForwardMailFrame"), "the window steps off while it is open")

	frame:Hide()
	-- The stub fires no hooks; the client runs the kit's OnHide hook, which hands back onClose.
	frame.hooks.OnHide(frame)
	check(not contains(UISpecialFrames, "PlayItForwardMailFrame"), "not in the frame the list closed")
	Stub.FireTimers()
	check(contains(UISpecialFrames, "PlayItForwardMailFrame"), "and steps back on once it closes")
end)

test("the Escape that closes the list never reaches the window", function()
	local ns = load()
	local first = twoMatched(ns)
	opened(ns, ns.UI:PickerOptions(first))
	local window = _G["PlayItForwardMailFrame"]
	check(window and window:IsShown(), "the window is open")

	-- The client's Escape: one walk over the list, hiding whatever is shown, the kit's hook included.
	for _, name in pairs(UISpecialFrames) do
		local shown = _G[name]
		if shown and shown:IsShown() then
			shown:Hide()
			if shown.hooks and shown.hooks.OnHide then
				shown.hooks.OnHide(shown)
			end
		end
	end
	check(window:IsShown(), "the window stays open")
	Stub.FireTimers()
	check(contains(UISpecialFrames, "PlayItForwardMailFrame"), "and is back on the Escape list")
end)
