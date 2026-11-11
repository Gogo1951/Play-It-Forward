--[[
	Disenchant Unmatched Gear, on the What to Give Away panel.

	Gear nobody can use -- the Kept rows -- goes to one of your own characters to disenchant,
	chosen per realm cluster and faction and saved on that character's entry. It only ever takes
	what nobody else could, never a consumable, never a row the player kept, and mail to it adds
	nothing to the Generosity totals, like mail to any of your characters.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	local ns = Harness.LoadAddon(ADDON_ROOT)
	ns.fire("PLAYER_LOGIN")
	return ns
end

local function seedAlt(ns, alt)
	local key = alt.name .. "-" .. (alt.realm or "Test")
	ns.db.global.characters[key] = {
		name = alt.name,
		realm = alt.realm or "Test",
		class = alt.class,
		level = alt.level,
		faction = alt.faction or "Alliance",
	}
	return key
end

-- Level 20 plate: no class is in plate that early, so it is Kept (see Tests/Mailbox-Gate.lua).
local function lowLevelPlate()
	return Stub.Item({
		name = "Burnished Breastplate",
		reqLevel = 20,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4, -- PLATE
		stats = { ITEM_MOD_STRENGTH_SHORT = 6 },
	})
end

-- With an enchanter chosen and the switch on.
local function withEnchanter(ns)
	local key = seedAlt(ns, { name = "Dusty", class = "MAGE", level = 40 })
	ns.Alts:SetDisenchanter(key)
	ns.db.profile.disenchantUnmatched = true
	return key
end

local function atMailbox(ns, defs)
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	return ns.UI:Items()
end

--------------------------------------------------------------------------------
-- Choosing the Enchanter
--------------------------------------------------------------------------------

test("the dropdown lists every character mail reaches, included on My Alts or not", function()
	local ns = load()
	local dusty = seedAlt(ns, { name = "Dusty", class = "MAGE", level = 40 })
	local brick = seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 12 })
	seedAlt(ns, { name = "Farshore", class = "WARRIOR", level = 20, realm = "Elsewhere" })
	seedAlt(ns, { name = "Redtusk", class = "WARRIOR", level = 20, faction = "Horde" })
	ns.db.global.characters[brick].include = false

	local keys = ns.Alts:DisenchantChoices()
	equal(table.concat(keys, ","), brick .. "," .. dusty, "both in reach, in name order, never this character")
end)

test("picking an enchanter replaces the last one here, and nobody is picked at first", function()
	local ns = load()
	local dusty = seedAlt(ns, { name = "Dusty", class = "MAGE", level = 40 })
	local brick = seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 12 })
	equal(ns.Alts:Disenchanter(), nil, "none until one is picked")

	ns.Alts:SetDisenchanter(dusty)
	equal(ns.Alts:Disenchanter(), dusty, "the pick")
	ns.Alts:SetDisenchanter(brick)
	equal(ns.Alts:Disenchanter(), brick, "the new pick")
	equal(ns.db.global.characters[dusty].disenchanter, nil, "the old flag is cleared")
end)

test("an enchanter chosen on another realm cluster is left alone, and not offered here", function()
	local ns = load()
	local far = seedAlt(ns, { name = "Farshore", class = "MAGE", level = 40, realm = "Elsewhere" })
	ns.db.global.characters[far].disenchanter = true
	local dusty = seedAlt(ns, { name = "Dusty", class = "MAGE", level = 40 })

	equal(ns.Alts:Disenchanter(), nil, "out of reach, so none here")
	ns.Alts:SetDisenchanter(dusty)
	equal(ns.db.global.characters[far].disenchanter, true, "that cluster keeps its own")
end)

--------------------------------------------------------------------------------
-- Matching
--------------------------------------------------------------------------------

local function optionTexts(ns, item)
	local texts, rescan = {}, false
	for _, option in ipairs(ns.UI:PickerOptions(item)) do
		texts[#texts + 1] = option.text or ""
		rescan = rescan or option.findForItem == true
	end
	return table.concat(texts, "\n"), rescan
end

test("a Kept row no class can take says why, and offers no rescan that would do nothing", function()
	local ns = load()
	local items = atMailbox(ns, { lowLevelPlate() })
	local item = items[1]
	equal(item.state, ns.Matcher.LEFTOVER, "kept")
	local texts, rescan = optionTexts(ns, item)
	check(texts:find(ns.L["TOOLTIP_RECIPIENT_KEPT"], 1, true) ~= nil, "the list opens on the reason")
	check(texts:find(ns.L["PICKER_NONE_IN_RANGE"], 1, true) == nil, "never sends the player to Find Recipients")
	check(not rescan, "and no Rescan for Better Match")
end)

test("with only Kept gear left and Disenchant off, the status line names Disenchant", function()
	local ns = load()
	local items = atMailbox(ns, { lowLevelPlate() })
	equal(ns.UI:StatusLine(), ns.L["STATUS_KEPT_DISENCHANT"], "the one switch that sends it")

	ns.UI:SetRecipient(items[1], nil)
	equal(ns.UI:StatusLine(), "", "a Keep Item by hand is never nagged about")
end)

test("with Disenchant on, kept gear is ready to send instead", function()
	local ns = load()
	withEnchanter(ns)
	atMailbox(ns, { lowLevelPlate() })
	equal(ns.UI:StatusLine(), ns.L["STATUS_READY"]:format(1), "Distribute is the next step")
end)

test("kept gear goes to the enchanter, and opens the window", function()
	local ns = load()
	withEnchanter(ns)
	local items = atMailbox(ns, { lowLevelPlate() })
	check(ns.UI.frame and ns.UI.frame:IsShown(), "the window opens on gear only the enchanter takes")
	local who = items[1].recipient
	equal(who and who.name, "Dusty", "the enchanter holds it")
	check(who and who.alt and who.disenchant, "as your own character, flagged disenchant")
	equal(items[1].send, true, "ticked like every pairing")
end)

test("off, kept gear stays kept", function()
	local ns = load()
	withEnchanter(ns)
	ns.db.profile.disenchantUnmatched = false
	Stub.SetBackpack({ lowLevelPlate() })
	ns.fire("MAIL_SHOW")
	check(not (ns.UI.frame and ns.UI.frame:IsShown()), "the window stays shut, as before")
end)

test("a Keep Item stands, and the picker offers the enchanter back", function()
	local ns = load()
	withEnchanter(ns)
	local items = atMailbox(ns, { lowLevelPlate() })
	local item = items[1]

	ns.UI:SetRecipient(item, nil)
	equal(item.recipient, nil, "kept")
	ns.UI:Assign()
	equal(item.recipient, nil, "and a rebuild leaves it kept")

	local offered
	for _, option in ipairs(ns.UI:PickerOptions(item)) do
		if option.pick and option.pick.disenchant then
			offered = option.pick
		end
	end
	equal(offered and offered.name, "Dusty", "the picker lists the enchanter")
	ns.UI:PickerSelect(item, { pick = offered })
	equal(item.recipient and item.recipient.name, "Dusty", "and picking it sends it there")
end)

test("mail to the enchanter adds nothing to the Generosity totals", function()
	local ns = load()
	withEnchanter(ns)
	atMailbox(ns, { lowLevelPlate() })
	Stub.sent = {}
	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")
	equal(Stub.sent[1] and Stub.sent[1].recipient, "Dusty", "mailed to the enchanter")
	equal(ns.db.global.stats.gifts, 0, "not counted as a gift")
end)

-- The gift letter is for strangers: "Hit Return and it'll find a new home" is wrong advice for dust.
test("mail to the enchanter carries no gift letter", function()
	local ns = load()
	withEnchanter(ns)
	local items = atMailbox(ns, { lowLevelPlate() })
	local name = items[1] and items[1].link and items[1].link:match("%[(.-)%]")
	Stub.sent = {}
	ns.UI:Distribute()
	local mail = Stub.sent[1]
	equal(mail and mail.recipient, "Dusty", "mailed to the enchanter")
	equal(mail and mail.subject, name, "under the item's own name")
	equal(mail and mail.body, "", "with no note")
end)

test("a consumable is never disenchantable", function()
	local ns = load()
	check(not ns.MatchList:Disenchantable({ kind = "consumable", state = ns.Matcher.LEFTOVER }), "consumable")
	check(not ns.MatchList:Disenchantable({ kind = "gear", state = ns.Matcher.GIFT }), "pending match")
	check(not ns.MatchList:Disenchantable({ kind = "gear", state = ns.Matcher.UNREADABLE }), "unreadable")
	check(ns.MatchList:Disenchantable({ kind = "gear", state = ns.Matcher.LEFTOVER }), "kept gear")
end)

--------------------------------------------------------------------------------
-- The Window
--------------------------------------------------------------------------------

test("the window's enchanter list picks the same character the panel does", function()
	local ns = load()
	local dusty = seedAlt(ns, { name = "Dusty", class = "MAGE", level = 40 })
	local options = ns.UI:DisenchanterPickerOptions()
	equal(#options, 1, "one character in reach")
	equal(options[1].altKey, dusty, "Dusty")
	equal(ns.Alts:Disenchanter(), nil, "none picked yet")
	ns.Alts:SetDisenchanter(options[1].altKey)
	equal(ns.Alts:Disenchanter(), dusty, "picked")
end)

test("with no character in reach the window's list says why, and offers nothing", function()
	local ns = load()
	local options = ns.UI:DisenchanterPickerOptions()
	equal(#options, 1, "one line")
	check(options[1].disabled and not options[1].altKey, "that cannot be picked")
end)

--------------------------------------------------------------------------------
-- Telling Dust From Gifts
--------------------------------------------------------------------------------

-- Level 50 strength plate: a warrior alt holds it to grow into, so the row is a gift.
local function strengthPlate()
	return Stub.Item({
		name = "Bulwark Breastplate",
		reqLevel = 50,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 4, -- PLATE
		stats = { ITEM_MOD_STRENGTH_SHORT = 15, ITEM_MOD_STAMINA_SHORT = 10 },
	})
end

local function disenchantOption(ns, item)
	for _, option in ipairs(ns.UI:PickerOptions(item)) do
		if option.text and option.text:find(ns.DisenchantName(), 1, true) and not option.header then
			return option
		end
	end
end

test("every gear row offers Disenchant, not only a Kept one", function()
	local ns = load()
	withEnchanter(ns)
	seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 12 })
	local item = atMailbox(ns, { strengthPlate() })[1]
	equal(item.recipient and item.recipient.name, "Brickhouse", "matched to the warrior alt")

	local option = disenchantOption(ns, item)
	check(option and option.pick and option.pick.disenchant, "Disenchant is on the matched row's list")
	ns.UI:PickerSelect(item, option)
	equal(item.recipient and item.recipient.name, "Dusty", "picking it sends the row to the enchanter")
	check(item.recipient and item.recipient.disenchant and item.pinned, "flagged disenchant, and pinned")
end)

test("a row sent to Disenchant by hand keeps its count rather than claiming nobody can use it", function()
	local ns = load()
	withEnchanter(ns)
	seedAlt(ns, { name = "Brickhouse", class = "WARRIOR", level = 12 })
	local item = atMailbox(ns, { strengthPlate() })[1]
	ns.UI:PickerSelect(item, disenchantOption(ns, item))
	local claim = ns.L["TOOLTIP_RECIPIENT_DISENCHANT"]:match("^(.-)%%s")
	local header = table.concat(ns.UI:PickerHeader(item), "\n")
	check(not header:find(claim, 1, true), "no 'No one can use this' on a row somebody can")
end)

-- A suffixed item whose stats read as nothing: the parse failed, so no class is admitted.
local function unreadableGreen()
	return Stub.Item({
		name = "Rugged Vest of the Bear",
		reqLevel = 20,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 2,
		suffix = 1200,
		stats = {},
	})
end

-- Scanned at the mailbox with no search: a mailbox holding only these rows opens no window to press in.
local function scanned(ns, defs)
	Stub.SetBackpack(defs)
	ns.fire("MAIL_SHOW")
	ns.UI:Rescan()
	return ns.UI:Items()
end

local function separatorsBackToBack(ns, item)
	local last = false
	for _, option in ipairs(ns.UI:PickerOptions(item)) do
		if option.separator and last then
			return true
		end
		last = option.separator == true
	end
	return false
end

test("an unreadable row offers no rescan, which could never place anybody", function()
	local ns = load()
	local item = scanned(ns, { unreadableGreen() })[1]
	equal(item.state, ns.Matcher.UNREADABLE, "unreadable")
	local _, rescan = optionTexts(ns, item)
	check(not rescan, "no Rescan for Better Match")
	check(not ns.UI:RescanCanHelp(item), "and the press itself refuses")
end)

test("the picker never stacks two dividers", function()
	local ns = load()
	local items = scanned(ns, { lowLevelPlate(), unreadableGreen() })
	equal(#items, 2, "both rows listed")
	for _, item in ipairs(items) do
		check(not separatorsBackToBack(ns, item), "one divider at a time on " .. tostring(item.state))
	end
end)

test("a consumable offers no Disenchant", function()
	local ns = load()
	withEnchanter(ns)
	ns.db.profile.consumableLevelGap = 0
	local scroll = atMailbox(ns, {
		Stub.Item({ id = 1180, name = "Scroll of Stamina", quality = 1, classID = 0, subclassID = 4, bindType = 0 }),
	})[1]
	equal(scroll and scroll.kind, "consumable", "a real scroll off the scanner")
	check(scroll and disenchantOption(ns, scroll) == nil, "nothing to disenchant")
end)

--[[
	Your enchanter is often an alt too, so the same name can take a gift and dust. The dropdown
	leads with the disenchant icon only when the row is going to be disenchanted.
]]
test("a row going to be disenchanted wears the icon, a gift to the same character does not", function()
	local ns = load()
	local dusty = withEnchanter(ns)
	local enchanter = ns.Alts:DisenchantRecipient()
	local asAlt = { name = "Dusty", class = "MAGE", level = 40, alt = true, altKey = dusty }
	check(ns.UI:RecipientLabel(enchanter):find(ns.UI.DISENCHANT_ICON, 1, true) == 1, "dust: icon first")
	check(ns.UI:RecipientLabel(asAlt):find(ns.UI.DISENCHANT_ICON, 1, true) == nil, "a gift: no icon")
end)

test("your alts read alphabetically in the picker, whatever their rank", function()
	local ns = load()
	seedAlt(ns, { name = "Zed", class = "WARRIOR", level = 30 })
	seedAlt(ns, { name = "Abe", class = "WARRIOR", level = 12 })
	local item = atMailbox(ns, { strengthPlate() })[1]
	equal(item.recipient and item.recipient.name, "Zed", "the closer level ranks first and is matched")

	local listed = {}
	for _, option in ipairs(ns.UI:PickerOptions(item)) do
		if option.pick and option.pick.alt and not option.pick.disenchant then
			listed[#listed + 1] = option.pick.name
		end
	end
	equal(table.concat(listed, ","), "Abe,Zed", "but the list reads by name")
end)
