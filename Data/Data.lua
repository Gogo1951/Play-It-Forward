local ADDON_NAME, ns = ...

ns.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

--------------------------------------------------------------------------------
-- Namespace
--------------------------------------------------------------------------------

-- Loads ahead of every other data file and of Core, all of which write ns.Data.
ns.Data = ns.Data or {}

-- Display title and the parent panel name. Never the code identifier, which is the TOC folder name.
ns.ADDON_TITLE = ns.L["ADDON_TITLE"]

-- The SavedVariables global, by name, for the Diagnostics dump.
ns.SAVED_VARIABLES_NAME = "PlayItForwardDB"

--------------------------------------------------------------------------------
-- Links
--------------------------------------------------------------------------------

-- Display order lives in Options/Options-Feedback-Support.lua. Slugs are irregular and never derived from the display name.
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
-- Options Layout Grid
--------------------------------------------------------------------------------

--[[
	A label cell plus its control add up to exactly one row, which is what puts a caption beside
	a widget rather than above it. A control wanting more room passes its own width to
	ns.OptionsRowLabel and takes ROW minus that, so every row still ends where the others do.
]]
ns.OPTIONS_ROW_WIDTH = 3.4
ns.OPTIONS_LABEL_WIDTH = 2.1
ns.OPTIONS_CONTROL_WIDTH = ns.OPTIONS_ROW_WIDTH - ns.OPTIONS_LABEL_WIDTH

-- The remove column of a player-managed item list, sized to its icon. This add-on ships no list.
ns.OPTIONS_REMOVE_ICON_WIDTH = 0.25

-- The blank cell a sub-option row leads with, so its control indents.
ns.OPTIONS_SUB_INDENT_WIDTH = 0.115

--[[
	The My Alts and My Guilds panels split in two, Magic Eraser's list layout: the characters or
	guilds down the left, the one picked on the right. The sidebar eats into the pane, so rows
	inside it spend TREE_ROW_WIDTH rather than ROW_WIDTH. The tree stays drag-resizable, and a drag
	wins over this seed.
]]
ns.OPTIONS_TREE_WIDTH = 180
ns.OPTIONS_TREE_ROW_WIDTH = 2.5

--------------------------------------------------------------------------------
-- Addon Message Prefix
--------------------------------------------------------------------------------

--[[
	The CHAT_MSG_ADDON prefix for the Given Away broadcast (Features/Generosity-Broadcast.lua). The
	client caps a prefix at 16 characters and drops longer ones; register it before sending or
	receiving. A literal, never derived from the folder name, which can be renamed.
]]
ns.ADDON_MESSAGE_PREFIX = "PIForward"

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------

-- Raw 6-character hex, no |cff prefix: Features/Utilities.lua adds that and builds COLORS and ns.GetColor.
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
	no Death Knights and only Mists has Monks; the extra keys keep the table identical across flavors.
]]
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
	How far below a class's training level an item may require and still be worth sending to it.

	THE FLAVOR FOLDER'S NATIVE_ARMOR IS A GATE ON TWO THINGS AT ONCE and only one of them is about
	eligibility.
	A hunter trains mail at 40, so on a level 36 mail belt the gate says both "he cannot wear
	this yet" and "he is not who it is for" -- and the second is wrong. Blizzard itemizes the
	35-to-39 mail with Agility and Intellect FOR hunters and shamans, who then watched it go to
	a warrior or a paladin because they were the only heavy-armor classes admitted. Reach makes
	the class eligible and moves its recipient band up to the level it can actually equip the
	item at, instead of dropping it.

	FIVE, BECAUSE AN ITEM GOES STALE. A level 36 belt is a real gift to a hunter about to hit 40
	with no mail at all; a level 20 one is not, and would arrive four tiers out of date. Any item
	further below the training level than this reverts to being ineligible outright.

	ARMOR ONLY. A weapon type is either in a class's column of the flavor folder's WEAPON_SPECS or it
	never is, so there is no weapon training level to reach for.
]]
ns.Data.PROFICIENCY_REACH = 5

-- Keeps a statless weapon out of the leftover pile: itemLevel * WEAPON_BASELINE for any eligible class.
ns.Data.WEAPON_BASELINE = 0.15

--[[
	How much of an item a class must use to count as one of the classes it is for rather than a
	fallback. Compared with Matcher:Coverage, and STRICTLY GREATER: a class using exactly half
	is demoted.

	Scoring alone cannot express "you have to use most of it" because it sums -- on "of the
	Gorilla" a paladin's 16 Strength plus 8 Intellect ties a warrior's 24, and the warrior takes
	it on proximity with half the item dead on him. Half is the bar because Classic's two-stat
	suffixes are near-even splits: one of the pair is 0.5, both is 1.0.
]]
ns.Data.COVERAGE_MAJORITY = 0.5

-- The share of the best class's claim another must reach to compete. See THE SCALE in Features/Match-Derivations.lua.
ns.Data.CLASS_SHARE = 0.35

--[[
	A best score below this sends an item to the vendor pile. Deliberately near the floor: the
	job is to catch an item nobody scores at all, and a higher bar bins real low-level gear.
]]
ns.Data.LEFTOVER_THRESHOLD = 1.0

--------------------------------------------------------------------------------
-- Recipient Level Band
--------------------------------------------------------------------------------

--[[
	How far below an item's required level its recipients are looked for, with RankCandidates
	preferring whoever sits closest to the top of the band: a level 19 sword goes to an 18 over
	a 17 and never reaches a 19. It should arrive just before an item becomes useful, not after.

	WIDEST must stay above CLOSEST. Equal values collapse the band to a single level and
	quietly starve items of recipients.
]]
ns.Data.LEVEL_GAP_WIDEST = 2
ns.Data.LEVEL_GAP_CLOSEST = 1

--[[
	How far ABOVE its use level a consumable's recipients are looked for, with RankCandidates
	preferring whoever sits closest to the BOTTOM of that band: a level 21 Greater Healing
	Potion goes to a 21 over a 23, because the point is somebody who drinks it now.

	ONE RULE FOR EVERY CONSUMABLE. Each flavor folder's Scan-Food, Scan-Potions, Scan-Scrolls and
	Scan-Oils-Stones files share a shape and carry no per-item level range, so there is nothing to branch on.

	DELIBERATELY NOT profile.consumableLevelGap, which answers the opposite question: that is
	the sender's threshold for when a potion counts as spare, and wants to be large or a level
	60 gives away what they are still drinking. This one wants to be small.
]]
ns.Data.CONSUMABLE_RECIPIENT_GAP = 2

--[[
	The lowest level anybody can receive anything, whatever list named them. Levels 1 to 4 are
	where bank and profession alts sit.

	ENFORCED IN ONE PLACE, Features/Match-Roster.lua's AddResults, because that is the single door
	every recipient comes through -- /who results, the guild roster, anything added later. A
	copy of this rule per source is a copy that can drift.
]]
ns.Data.MIN_RECIPIENT_LEVEL = 5

--[[
	The band a stranger warlock is skipped in while the Recipients panel's Ignore Warlocks switch
	is on: Ritual of Summoning unlocks at 20, and summoning alts park there, drifting a few levels
	before they stop. Wider than the guild roster's always-on rule (Features/Recipients-Guild.lua),
	because a stranger is an opt-in guess the player made, where a guildmate's parked alt is known.
]]
ns.Data.SUMMONER_MIN_LEVEL = 20
ns.Data.SUMMONER_MAX_LEVEL = 25

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

--[[
	The stops the options panel offers; Features/Utilities.lua labels and snaps them. Zero
	is a sentinel rather than a gap: it reads as "All Consumables" and lifts the level rule in
	Features/Scan-Bags.lua entirely. The rest mean "at least this far past the item's own level".
]]
ns.CONSUMABLE_GAP_ORDER = { 0, 5, 10, 15, 20 }

-- The stops the Ignore Offline Guild Members dropdown offers, in display order: keys of ns.Guild.OFFLINE_DAYS.
ns.GUILD_OFFLINE_ORDER = { "WEEK", "TWO_WEEKS", "NEVER" }

--------------------------------------------------------------------------------
-- Alt Gear Levels
--------------------------------------------------------------------------------

--[[
	The stops the My Alts pane offers for the lowest and highest gear each alt is mailed, counted
	from its own level, in display order. "ANY" lifts the top end outright: anything the alt will
	ever grow into. A new alt starts on the first stop of the one and the last of the other, gear
	at its own level and up. Consumables keep the band everyone else is searched in.
]]
ns.ALT_LEVELS_BELOW_ORDER = { 0, 1, 2, 3 }
ns.ALT_LEVELS_ABOVE_ORDER = { 1, 2, 3, "ANY" }

--------------------------------------------------------------------------------
-- Consumable Kinds
--------------------------------------------------------------------------------

--[[
	The kinds a player switches on and off one by one, in the order the options panel and the
	mail window both draw them. One list and one map of locale keys, so the two surfaces cannot
	name or order a kind differently. Features/Scan-Bags.lua says which kinds each row is.
]]
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
	The lowest quality worth mailing a stranger: a letter from somebody you have never met
	containing a gray reads as junk rather than a gift. A constant, not a setting -- a floor
	below uncommon has no use that is not "send something worse".

	GEAR ONLY. Features/Scan-Bags.lua returns a listed consumable before the rarity checks,
	so this never tests one: a low-level water is worth having whatever its rarity.
]]
ns.Data.MIN_RARITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

--------------------------------------------------------------------------------
-- Item Quality Colors
--------------------------------------------------------------------------------

-- Not palette roles, so they get their own table rather than borrow one that looks similar.
ns.ITEM_QUALITY_COLORS = {
	UNCOMMON = "1EFF00", -- quality 2
	RARE = "0070DD", -- quality 3
	EPIC = "A335EE", -- quality 4
}
