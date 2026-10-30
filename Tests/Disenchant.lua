--[[
	Disenchant Unmatched Items, on the What to Give Away panel.

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
