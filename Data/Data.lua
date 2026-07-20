local ADDON_NAME, ns = ...

ns.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

--------------------------------------------------------------------------------
-- Namespace and Client Flavor
--------------------------------------------------------------------------------

--[[
	Loads ahead of every other data file and of Core, because the files below read these at load
	time: Stat-Weights branches on ns.isWrathOrLater while building, and all of them write
	ns.Data.
]]
ns.Data = ns.Data or {}

-- Display title and the parent panel name. Never the code identifier, which is the TOC folder name.
ns.AddonTitle = ns.L["ADDON_TITLE"]

--[[
	Load-bearing in two places: the zone flavor column ns.Data.ZonesFor reads in
	Features/Recipient-Search.lua, and the interaction-manager mailbox registrations in
	Features/Mail-Window.lua, which are taken off Era only. MAIL_SHOW and MAIL_CLOSED are
	registered on every flavor and do not read this.
]]
ns.isEra = (WOW_PROJECT_ID == (WOW_PROJECT_CLASSIC or 2))

-- 3.0 merged the caster stats into one. Before that they rank differently per class, so the tables branch here.
local PRE_WRATH = {
	[WOW_PROJECT_CLASSIC or 2] = true,
	[WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5] = true,
}
ns.isWrathOrLater = not PRE_WRATH[WOW_PROJECT_ID or 2]

--------------------------------------------------------------------------------
-- Links
--------------------------------------------------------------------------------

--[[
	Rendered in this order, each row skipped when its key is missing. Slugs are irregular across
	the add-ons and are never derived from the display name.
]]
ns.Links = {
	DISCORD = "https://discord.gg/eh8hKq992Q",
	GITHUB = "https://github.com/Gogo1951/Play-It-Forward",
	CURSEFORGE = "https://www.curseforge.com/wow/addons/play-it-forward",
	WAGO = "https://addons.wago.io/addons/play-it-forward",
}

--------------------------------------------------------------------------------
-- Options Registry
--------------------------------------------------------------------------------

--[[
	AceConfig registry names, never localized. Referenced by Options.lua's registration and by
	NotifyChange in the panels, so they are stable identifiers, never built inline.
]]
ns.OPTIONS_REGISTRY = {
	General = ADDON_NAME,
	Profiles = ADDON_NAME .. "_Profiles",
	Diagnostics = ADDON_NAME .. "_Diagnostics",
}

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------

--[[
	Raw 6-character hex, no |cff prefix: that escape is added in Features/Utilities.lua, where
	the derived COLORS table and ns.GetColor are built.
]]
ns.PALETTE = {
	TITLE = "FFD100", -- Gold: Titles, Headers, Section Names, Field Titles
	INFO = "00BBFF", -- Blue: Interactions, Toggles, Links, Keybinds, Slash Commands
	BODY = "FFFFFF", -- White: Descriptions, Options Body Text
	HELP = "CCCCCC", -- Silver: Pro Tips, Helper Text
	TEXT = "FFFFFF", -- White: Messages, Values, Spell Names
	ON = "33CC33", -- Green: On
	OFF = "CC3333", -- Red: Off
	SEPARATOR = "AAAAAA", -- Gray: Separators, Dividers
	MUTED = "808080", -- Dark Gray: Meta-data, Version Numbers
}

--[[
	Fallback only: CUSTOM_CLASS_COLORS and RAID_CLASS_COLORS win when present. Era and TBC have
	no Death Knights; the extra key keeps the table identical across flavors.
]]
ns.CLASS_COLORS = {
	DEATHKNIGHT = "C41E3A",
	DRUID = "FF7C0A",
	HUNTER = "AAD372",
	MAGE = "3FC7EB",
	PALADIN = "F48CBA",
	PRIEST = "FFFFFF",
	ROGUE = "FFF468",
	SHAMAN = "0070DD",
	WARLOCK = "8788EE",
	WARRIOR = "C69B6D",
}

--------------------------------------------------------------------------------
-- Recipient Level Band
--------------------------------------------------------------------------------

--[[
	How far below an item's required level its recipients are looked for, with
	RankCandidates preferring whoever sits closest to the top of the band. A level 19 sword
	reaches a 17 or an 18, goes to the 18, and never reaches a 19: it should arrive just
	before an item becomes useful, not after.

	WIDEST must stay above CLOSEST. Equal values collapse the band to a single level and
	quietly starve items of recipients.
]]
ns.Data.LEVEL_GAP_WIDEST = 2
ns.Data.LEVEL_GAP_CLOSEST = 1

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

-- The gaps the options panel offers, in fives.
ns.CONSUMABLE_GAP_ORDER = { 0, 5, 10, 15, 20 }

-- Labelled and snapped for the dropdown by Options/Options-Utilities.lua.

--------------------------------------------------------------------------------
-- Consumable Eligibility
--------------------------------------------------------------------------------

--[[
	What a consumable restores decides who can receive it, not a class list on every row.
	Hunters have mana in Classic and TBC and belong here; death knights use runic power.
]]
local MANA_USERS = { "MAGE", "PRIEST", "WARLOCK", "PALADIN", "SHAMAN", "DRUID", "HUNTER" }

ns.Data.ConsumableClasses = {
	HEALTH = "ALL",
	MANA = MANA_USERS,
	BOTH = MANA_USERS,
}

--------------------------------------------------------------------------------
-- Item Quality Colors
--------------------------------------------------------------------------------

-- Not palette roles, so they get their own table rather than borrow one that looks similar.
ns.ITEM_QUALITY_COLORS = {
	UNCOMMON = "1EFF00", -- quality 2
	RARE = "0070DD", -- quality 3
	EPIC = "A335EE", -- quality 4
}
