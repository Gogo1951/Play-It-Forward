local _, ns = ...

--[[
	GetItemStats keys -> internal stat tokens. The key set differs between clients,
	especially around spell power, so a stat that scores on one client and not another
	means a row is missing here rather than the scorer being wrong.
]]
ns.Data.StatMap = {
	ITEM_MOD_STRENGTH_SHORT = "STRENGTH",
	ITEM_MOD_AGILITY_SHORT = "AGILITY",
	ITEM_MOD_INTELLECT_SHORT = "INTELLECT",
	ITEM_MOD_SPIRIT_SHORT = "SPIRIT",
	ITEM_MOD_STAMINA_SHORT = "STAMINA",

	ITEM_MOD_ATTACK_POWER_SHORT = "ATTACK_POWER",
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "RANGED_AP",

	-- Pre-Wrath these are three separate stats the weight tables rank differently: never fold them together.
	ITEM_MOD_SPELL_POWER_SHORT = "SPELL_POWER", -- unified damage+healing
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SPELL_DAMAGE", -- generic spell damage
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "HEALING",
	ITEM_MOD_HEALING_DONE_SHORT = "HEALING",
	--[[
		Per-school damage (ARCANE, FIRE, FROST, NATURE, SHADOW, HOLY) has no GetItemStats
		key in Vanilla. Tooltip text only, which is why Features/Tooltip-Scanner.lua is not
		optional.
	]]

	ITEM_MOD_HIT_RATING_SHORT = "HIT",
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "SPELL_HIT",
	ITEM_MOD_CRIT_RATING_SHORT = "CRIT",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "SPELL_CRIT",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DEFENSE",
	ITEM_MOD_DODGE_RATING_SHORT = "DODGE",
	ITEM_MOD_BLOCK_RATING_SHORT = "BLOCK",
	ITEM_MOD_MANA_REGENERATION_SHORT = "MP5",
	-- RESISTANCE0_NAME (armor) and RESISTANCE1..7 (schools) intentionally omitted.
}
