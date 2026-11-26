local ADDON_NAME, ns = ...

ns.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

--------------------------------------------------------------------------------
-- Namespace
--------------------------------------------------------------------------------

ns.Data = ns.Data or {}

-- Display title only; the code identifier is ADDON_NAME, the folder name.
ns.ADDON_TITLE = ns.L["ADDON_TITLE"]

-- The SavedVariables global, by name, for the Diagnostics dump.
ns.SAVED_VARIABLES_NAME = "PlayItForwardDB"

--------------------------------------------------------------------------------
-- Links
--------------------------------------------------------------------------------

-- Slugs are irregular: never derive them from the display name. Display order is in Options-Feedback-Support.lua.
ns.LINKS = {
	DISCORD = "https://discord.gg/eh8hKq992Q",
	GITHUB = "https://github.com/Gogo1951/Play-It-Forward",
	CURSEFORGE = "https://www.curseforge.com/wow/addons/play-it-forward",
	WAGO = "https://addons.wago.io/addons/play-it-forward",
}

--------------------------------------------------------------------------------
-- Options Registry
--------------------------------------------------------------------------------

-- AceConfig registry names: stable identifiers, never localized and never built inline.
ns.OPTIONS_REGISTRY = {
	General = ADDON_NAME,
	GiveAway = ADDON_NAME .. "_GiveAway",
	Recipients = ADDON_NAME .. "_Recipients",
	Alts = ADDON_NAME .. "_Alts",
	Guilds = ADDON_NAME .. "_Guilds",
	Mail = ADDON_NAME .. "_Mail",
	Generosity = ADDON_NAME .. "_Generosity",
	Profiles = ADDON_NAME .. "_Profiles",
	FeedbackSupport = ADDON_NAME .. "_FeedbackSupport",
	Diagnostics = ADDON_NAME .. "_Diagnostics",
}

--------------------------------------------------------------------------------
-- Addon Message Prefix
--------------------------------------------------------------------------------

-- At most 16 characters or the client drops it. A literal: the folder can be renamed.
ns.ADDON_MESSAGE_PREFIX = "PIForward"

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------

-- Raw hex, no |cff prefix: ns.GetColor adds it.
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

-- Fallback only: CUSTOM_CLASS_COLORS and RAID_CLASS_COLORS win. Every class on every flavor, on purpose.
ns.CLASS_COLORS = {
	DEATHKNIGHT = "C41E3A",
	DRUID = "FF7C0A",
	HUNTER = "AAD372",
	MAGE = "3FC7EB",
	MONK = "00FF98",
	PALADIN = "F48CBA",
	PRIEST = "FFFFFF",
	ROGUE = "FFF468",
	SHAMAN = "0070DD",
	WARLOCK = "8788EE",
	WARRIOR = "C69B6D",
}

--------------------------------------------------------------------------------
-- Matching
--------------------------------------------------------------------------------

--[[
	Armor only: how far below a class's training level an item may require and still go to it,
	banded at the training level. Further below, the item would arrive stale.
]]
ns.Data.PROFICIENCY_REACH = 5

-- Keeps a statless weapon out of the leftover pile: itemLevel * WEAPON_BASELINE for any eligible class.
ns.Data.WEAPON_BASELINE = 0.15

--[[
	Compared with Matcher:Coverage, STRICTLY GREATER: a class using exactly half is demoted. Half,
	because Classic's two-stat suffixes split near-evenly: one of the pair is 0.5, both is 1.0.
]]
ns.Data.COVERAGE_MAJORITY = 0.5

-- The share of the best class's claim another must reach to compete. See THE SCALE in Features/Match-Derivations.lua.
ns.Data.CLASS_SHARE = 0.35

-- Near the floor on purpose: it catches what nobody scores; a higher bar bins real low-level gear.
ns.Data.LEFTOVER_THRESHOLD = 1.0

--------------------------------------------------------------------------------
-- Recipient Level Band
--------------------------------------------------------------------------------

-- WIDEST must stay above CLOSEST: equal values collapse the band to one level and starve items.
ns.Data.LEVEL_GAP_WIDEST = 2
ns.Data.LEVEL_GAP_CLOSEST = 1

--[[
	Above the use level, closest to the bottom first. Not profile.consumableLevelGap, the sender's
	spare threshold, which wants to be large; this one wants to be small.
]]
ns.Data.CONSUMABLE_RECIPIENT_GAP = 2

-- Enforced only in Features/Match-Roster.lua's AddResults, the one door every source uses.
ns.Data.MIN_RECIPIENT_LEVEL = 5

--[[
	Ritual of Summoning unlocks at 20 and summoning alts park there. Wider than the guild roster's
	always-on rule, because a stranger is an opt-in guess where a guildmate's parked alt is known.
]]
ns.Data.SUMMONER_MIN_LEVEL = 20
ns.Data.SUMMONER_MAX_LEVEL = 25

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

-- Zero is the "All Consumables" sentinel, not a gap: it lifts the level rule in Features/Scan-Bags.lua.
ns.CONSUMABLE_GAP_ORDER = { 0, 5, 10, 15, 20 }

-- Keys of ns.Guild.OFFLINE_DAYS, in display order.
ns.GUILD_OFFLINE_ORDER = { "WEEK", "TWO_WEEKS", "NEVER" }

--------------------------------------------------------------------------------
-- Alt Gear Levels
--------------------------------------------------------------------------------

--[[
	Counted from the alt's own level. Position matters: an alt that never picked starts on the
	first BELOW stop and the last ABOVE stop. "ANY" lifts the top end outright.
]]
ns.ALT_LEVELS_BELOW_ORDER = { 0, 1, 2, 3 }
ns.ALT_LEVELS_ABOVE_ORDER = { 1, 2, 3, "ANY" }

--------------------------------------------------------------------------------
-- Consumable Kinds
--------------------------------------------------------------------------------

-- One list for the options panel and the mail window, so neither can name or order a kind differently.
ns.CONSUMABLE_KIND_ORDER = { "FOOD", "DRINK", "POTION", "SCROLL", "OIL_STONE" }

ns.CONSUMABLE_KIND_STRINGS = {
	FOOD = { label = "OPTIONS_KIND_FOOD", description = "OPTIONS_KIND_FOOD_DESCRIPTION" },
	DRINK = { label = "OPTIONS_KIND_DRINK", description = "OPTIONS_KIND_DRINK_DESCRIPTION" },
	POTION = { label = "OPTIONS_KIND_POTIONS", description = "OPTIONS_KIND_POTIONS_DESCRIPTION" },
	SCROLL = { label = "OPTIONS_KIND_SCROLLS", description = "OPTIONS_KIND_SCROLLS_DESCRIPTION" },
	OIL_STONE = { label = "OPTIONS_KIND_OILS_STONES", description = "OPTIONS_KIND_OILS_STONES_DESCRIPTION" },
}

--------------------------------------------------------------------------------
-- Rarity Floor
--------------------------------------------------------------------------------

--[[
	A constant, not a setting: a gray from a stranger reads as junk. Gear only: Features/Scan-Bags.lua
	returns a listed consumable before the rarity checks.
]]
ns.Data.MIN_RARITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

--------------------------------------------------------------------------------
-- Item Quality Colors
--------------------------------------------------------------------------------

-- Not palette roles, so never folded into ns.PALETTE.
ns.ITEM_QUALITY_COLORS = {
	UNCOMMON = "1EFF00", -- quality 2
	RARE = "0070DD", -- quality 3
	EPIC = "A335EE", -- quality 4
}
