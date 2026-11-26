local _, ns = ...

-- AceDB fills these in on first access, so no call site needs an "or default" fallback.

local UNCOMMON = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

ns.DATABASE_DEFAULTS = {
	profile = {
		showWelcome = true,

		-- Off stops your broadcasts, not your view of other players' totals.
		shareStats = true,

		-- A cap, not a target: at the default a blue or epic drop cannot be mailed by accident.
		maxRarity = UNCOMMON,
		includeGear = true,
		includeConsumables = true,
		consumableKinds = { FOOD = true, DRINK = true, POTION = true, SCROLL = true, OIL_STONE = true },
		-- How many of each item stay behind, one of ns.Bags.KEEP_ORDER; mail takes a stack whole.
		keepInBags = { FOOD = 0, DRINK = 0, POTION = 0, SCROLL = 0, OIL_STONE = 0 },

		-- [itemID] = true
		neverGive = {},

		--[[
			Twenty, because the tier immediately behind still gets drunk on a long fight. Zero is the
			"All Consumables" stop. Must stay one of ns.CONSUMABLE_GAP_ORDER.
		]]
		consumableLevelGap = 20,

		-- Which character disenchants is on its global.characters entry: this profile may be shared.
		disenchantUnmatched = false,

		-- Which alts, their specs and gear levels live on each alt's global.characters entry.
		sendToAlts = true,

		-- A key of ns.Guild.OFFLINE_DAYS.
		guildOfflineLimit = "WEEK",

		-- Off, a key drops out of the candidate sort rather than reversing.
		prioritizeAlts = true,
		prioritizeGuilds = true,
		prioritizeLevelingZones = true,
		prioritizeOutsideInstances = true,

		-- Off by default: /who cannot tell a parked summoning alt from a leveling warlock.
		ignoreSummonerWarlocks = false,

		--[[
			[class][spec key] = true or false, only where the player changed a default, so a default
			that changes in a release reaches everyone who never touched it.
		]]
		specs = {},

		-- Empty sends the stock copy.
		mailSubject = "",
		mailBody = "",

		-- Empty until the player moves or resizes the window. Read via its point field.
		windowPos = {},
		-- Empty until the player resizes the window from its corner grip. Read via its width field.
		windowSize = {},
	},

	-- Survives Reset Profile on purpose.
	global = {
		--[[
			Keyed by qualified name: { name, realm, class, level, faction, spec }, plus the player's
			My Alts choices (include, specs, levelsBelow, levelsAbove, disenchanter).
		]]
		characters = {},
		--[[
			Keyed by ns.Guild:Key: { name, realm, faction, scanned, scannedBy, members = { { name,
			level, class, area, days } }, include, ignored, added, removed }.
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
