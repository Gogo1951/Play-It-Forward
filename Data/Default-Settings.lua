local _, ns = ...

--[[
	AceDB-3.0 defaults. Every user setting lives under profile; there is no global
	subtable, since that scope is for a minimap button this add-on does not have.

	Applied through metatables when a profile is created, so no call site needs an "or
	default" fallback. Table-valued defaults are materialized per profile rather than
	shared, so recipients and windowPos are safe to write into and wipe in place.
]]

local UNCOMMON = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2

ns.DATABASE_DEFAULTS = {
	profile = {
		showWelcome = true,

		--[[
			maxRarity is a cap, not a target: at the default it keeps blues and epics out
			of the list entirely, so a good drop cannot be mailed off by accident.
		]]
		minRarity = UNCOMMON,
		maxRarity = UNCOMMON,
		includeGear = true,
		includeConsumables = true,

		--[[
			Only offer a consumable once the player is this far past its level: at 55 the
			level-35 water is spare, at 45 it is still what they are drinking. Twenty
			rather than ten because the tier immediately behind still gets drunk on a long
			fight, and mailing that away is the mistake this gap exists to prevent.

			Has to stay one of ns.CONSUMABLE_GAP_ORDER or the dropdown opens on a value it
			cannot show.
		]]
		consumableLevelGap = 20,

		--[[
			The recipient level band, the vendor threshold, the class-fit share and the two
			/who values are constants, not settings: ns.Data.LEVEL_GAP_WIDEST and
			LEVEL_GAP_CLOSEST in Data/Data.lua, ns.Data.CLASS_SHARE and LEFTOVER_THRESHOLD
			in Data/Stat-Weights.lua, the /who throttle and panel suppression in
			Features/Recipient-Search.lua.

			The subject and body a stranger receives are likewise fixed text, in
			Locales/enUS.lua as MAIL_SUBJECT and MAIL_BODY.
		]]

		-- Empty until the player drags the window. Read via its point field.
		windowPos = {},

		--[[
			Fairness history: recipient name -> { level }.

			Cleared at every login, in the ADDON_LOADED handler in Features/Core.lua, so the
			cooldown only ever spreads gifts out within one session. A name that has received
			something is held back until it is next seen at a higher level, meaning they have
			levelled since.
		]]
		recipients = {},
	},
}
