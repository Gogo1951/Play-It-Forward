local _, ns = ...

--[[
	The AceDB-3.0 defaults: settings under profile, the account-wide giving tally under global.
	AceDB copies these into the saved table on first access, so no call site needs an "or default"
	fallback, and table defaults are per profile: safe to write into and wipe.
]]

local UNCOMMON = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

ns.DATABASE_DEFAULTS = {
	profile = {
		showWelcome = true,

		--[[
			Share this account's Given Away totals with nearby Play It Forward users, who see them on
			your unit tooltip. Turning it off stops your broadcasts but not your view of theirs; see
			Features/Generosity-Broadcast.lua.
		]]
		shareStats = true,

		-- A cap, not a target: at the default a blue or epic drop cannot be mailed by accident.
		maxRarity = UNCOMMON,
		includeGear = true,
		includeConsumables = true,
		-- One switch per kind in ns.CONSUMABLE_KIND_ORDER, read only while includeConsumables is on.
		consumableKinds = { FOOD = true, DRINK = true, POTION = true, SCROLL = true, OIL_STONE = true },

		--[[
			Only offer a consumable once the player is at least this far past its level. Twenty
			rather than ten because the tier immediately behind still gets drunk on a long fight.
			Zero is not a gap of nothing: it is the "All Consumables" stop and lifts the level rule
			outright, so an item the player is under the level for is still offered. Has to stay one
			of ns.CONSUMABLE_GAP_ORDER or the dropdown opens on a value it cannot show.
		]]
		consumableLevelGap = 20,

		--[[
			Mail gear nobody matched -- the Kept rows -- to one of your own characters to
			disenchant. Which character is chosen per realm cluster and faction, on its
			ns.db.global.characters entry (Alts:SetDisenchanter), since this profile may be shared
			by characters it cannot mail.
		]]
		disenchantUnmatched = false,

		--[[
			Mail your own characters at all, among the classes an item suits best. Which alts, for
			which specs, and the gear levels each is mailed, is set per alt on the
			My Alts panel and saved on its ns.db.global.characters entry.
		]]
		sendToAlts = true,

		--[[
			Leave out guildmates offline longer than this, counted to today: a key of
			ns.Guild.OFFLINE_DAYS, in ns.GUILD_OFFLINE_ORDER. Applies to the guild the current
			character is in and to every saved one.
		]]
		guildOfflineLimit = "WEEK",

		--[[
			The Recipients panel's ordering switches, read by Matcher:SourceRank and Who:PlacementRank
			in the candidate sort. Off, a key drops out of the sort rather than reversing: an alt with
			prioritizeAlts off competes with guildmates and strangers on fit, level and placement.
		]]
		prioritizeAlts = true,
		prioritizeGuilds = true,
		prioritizeLevelingZones = true,
		prioritizeOutsideInstances = true,

		--[[
			Skip strangers who are warlocks in ns.Data.SUMMONER_MIN_LEVEL to SUMMONER_MAX_LEVEL, the
			band summoning alts park in. Off by default: /who cannot tell a parked alt from a real
			one, and most warlocks there are levelling. The guild roster's own summoner rule is
			separate and always on (Features/Recipients-Guild.lua).
		]]
		ignoreSummonerWarlocks = false,

		--[[
			[class][spec key] = true or false, only where the player changed a spec from its default
			on the Recipients panel. Unset means the flavor folder's Match-Specs default, so a
			default that changes in a release reaches everyone who never touched it.
		]]
		specs = {},

		--[[
			The player's own mail copy, edited on the Mail Message Text panel. Empty sends the stock
			L["MAIL_SUBJECT"] and L["MAIL_BODY"]; a custom body goes out with
			L["MAIL_POWERED_BY"] after it (Features/Mail-Copy.lua).
		]]
		mailSubject = "",
		mailBody = "",

		--[[
			Everything else is a constant, not a setting: Data/Data.lua, the flavor folders and
			Features/Recipients-Who.lua.
		]]

		-- Empty until the player drags the window. Read via its point field.
		windowPos = {},
		-- Empty until the player resizes the window from its corner grip. Read via its width field.
		windowSize = {},
	},

	--[[
		global.stats is account-wide and INTENTIONALLY survives Reset Profile, unlike everything
		under profile above: a lifetime giving tally has to span every character on the account and
		outlive a profile wipe. AceDB seeds global exactly as it does profile, so Features/Core.lua
		needs no init code for it. All four counters are integers, value in copper. Written only by
		Features/Generosity.lua.
	]]
	global = {
		--[[
			Every character that has logged in with the add-on, keyed by qualified name: { name,
			realm, class, level, faction }. Written by Features/Recipients-Alts.lua at login and
			level up, the only way to offer an alt that is logged out.
		]]
		characters = {},
		--[[
			Every guild any character is in, keyed by ns.Guild:Key: { name, realm, faction, scanned,
			scannedBy, members = { { name, level, class, area, days } }, include }. Written by
			Features/Recipients-Guild.lua at login and at each live roster read.
		]]
		guilds = {},
		stats = {
			gifts = 0, -- one per successful mailing
			items = 0, -- total quantity sent; a stack of 20 waters counts as 20
			itemLevels = 0, -- sum of item level, equippable gear only (consumables contribute 0)
			value = 0, -- sum of vendor sell price times quantity, in copper
		},
	},
}
