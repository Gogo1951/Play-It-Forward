local _, ns = ...

--[[
	AceDB-3.0 defaults, all under profile. Applied through metatables, so no call site needs an
	"or default" fallback, and table defaults are per profile: safe to write into and wipe.
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

		--[[
			Only offer a consumable once the player is this far past its level. Twenty rather than
			ten because the tier immediately behind still gets drunk on a long fight. Has to stay
			one of ns.CONSUMABLE_GAP_ORDER or the dropdown opens on a value it cannot show.
		]]
		consumableLevelGap = 20,

		--[[
			Everything else is a constant, not a setting: Data/Data.lua, Data/Match-Stats.lua,
			Features/Recipients-Who.lua, and the mail text in Locales/enUS.lua.
		]]

		-- Empty until the player drags the window. Read via its point field.
		windowPos = {},

		--[[
			Fairness history: recipient name -> { level }. Cleared at every login in
			Features/Core.lua, so the cooldown only spreads gifts out within one session. A name
			that has received something is held back until it is next seen at a higher level.
		]]
		recipients = {},
	},

	--[[
		global.stats is account-wide and INTENTIONALLY survives Reset Profile, unlike everything
		under profile above: a lifetime giving tally has to span every character on the account and
		outlive a profile wipe. AceDB seeds global through metatables exactly as it does profile,
		so Features/Core.lua needs no init code for it. All four counters are integers, value in
		copper. Written only by Features/Generosity.lua.
	]]
	global = {
		stats = {
			gifts = 0, -- one per successful mailing
			items = 0, -- total quantity sent; a stack of 20 waters counts as 20
			itemLevels = 0, -- sum of item level, equippable gear only (consumables contribute 0)
			value = 0, -- sum of vendor sell price times quantity, in copper
		},
	},
}
