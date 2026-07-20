local _, ns = ...

--[[
	AceDB-3.0 defaults, all under profile. Applied through metatables, so no call site needs an
	"or default" fallback, and table defaults are per profile: safe to write into and wipe.
]]

local UNCOMMON = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

ns.DATABASE_DEFAULTS = {
	profile = {
		showWelcome = true,

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
			Everything else is a constant, not a setting: Data/Data.lua, Data/Stat-Weights.lua,
			Features/Recipient-Search.lua, and the mail text in Locales/enUS.lua.
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
}
