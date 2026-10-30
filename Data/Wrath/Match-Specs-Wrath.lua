local _, ns = ...

--[[
	Every spec this client has, in talent-tab order, as the player levelling it. Read by
	Features/Match-Derivations.lua, which sums the specs the player has on into class weights, and
	by the Recipients panel's Classes & Specs section, which draws one switch per spec.

	  key     names the spec in saved settings and in L["SPEC_" .. key]
	  role    HEALER, CASTER, MELEE, RANGED or TANK; the Healing rule reads HEALER
	  off     ships turned off. Nobody can see a stranger's spec, so some are assumed: Protection
	          paladins, Enhancement shamans, Arms and Balance start off; the player can turn any
	          of them back on
	  rune    a Season of Discovery role runes added on top of the three trees
	  main    stats the spec builds around, 2 points
	  useful  stats it gears for, 1 point

	MP5 IS EVERY HEALER'S, as main. Spirit is never a paladin's or a shaman's, whatever a guide
	ranks it while levelling: the flavor folder's Match-Rules file vetoes them on it.

	Stamina is everybody's and so nobody's, except the two warlock trees that Life Tap hardest.
	Defense, dodge, parry and block are nobody's: nobody levels on them, and tank gear gets sharded.
]]
ns.Data.SPECS = {
	WARRIOR = {
		{
			key = "Arms",
			role = "MELEE",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "AGILITY" },
		},
		{
			key = "Fury",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "AGILITY" },
		},
		{
			key = "Protection",
			role = "TANK",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
	},
	PALADIN = {
		{
			key = "Holy",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPELL_CRIT", "HASTE" },
		},
		{
			key = "Protection",
			role = "TANK",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "HIT", "SPELL_DAMAGE", "HOLY", "EXPERTISE" },
		},
		{
			key = "Retribution",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "AGILITY" },
		},
	},
	HUNTER = {
		{
			key = "BeastMastery",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "RANGED_AP", "INTELLECT" },
		},
		{
			key = "Marksmanship",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "RANGED_AP", "INTELLECT" },
		},
		{
			key = "Survival",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "RANGED_AP" },
		},
	},
	ROGUE = {
		{
			key = "Assassination",
			role = "MELEE",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "STRENGTH" },
		},
		{
			key = "Combat",
			role = "MELEE",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "STRENGTH" },
		},
		{
			key = "Subtlety",
			role = "MELEE",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
	},
	PRIEST = {
		{
			key = "Discipline",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "HOLY", "SPELL_CRIT", "HASTE" },
		},
		{
			key = "Holy",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "HOLY", "SPELL_CRIT", "HASTE" },
		},
		{
			key = "Shadow",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE", "MP5" },
		},
	},
	SHAMAN = {
		{
			key = "Elemental",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE", "MP5", "NATURE" },
		},
		{
			key = "Enhancement",
			role = "MELEE",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE", "AGILITY" },
		},
		{
			key = "Restoration",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPELL_CRIT", "HASTE" },
		},
	},
	MAGE = {
		{
			key = "Arcane",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE", "ARCANE" },
		},
		{
			key = "Fire",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "FIRE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE" },
		},
		{
			key = "Frost",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "FROST" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE" },
		},
	},
	WARLOCK = {
		{
			key = "Affliction",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_HIT", "HASTE", "STAMINA" },
		},
		{
			key = "Demonology",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_HIT", "HASTE", "STAMINA" },
		},
		{
			key = "Destruction",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE", "FIRE" },
		},
	},
	DRUID = {
		{
			key = "Balance",
			role = "CASTER",
			off = true,
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "HASTE", "ARCANE", "NATURE" },
		},
		{
			key = "Feral",
			role = "MELEE",
			main = { "STRENGTH", "AGILITY", "FERAL_AP" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
		{
			key = "Restoration",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "SPELL_CRIT", "HASTE" },
		},
	},
	DEATHKNIGHT = {
		{
			key = "Blood",
			role = "TANK",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
		{
			key = "Frost",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
		{
			key = "Unholy",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "HASTE", "EXPERTISE" },
		},
	},
}

--[[
How We Got the Data

Last Validated
	Never: forward-prep, a copy of the TBC choices plus death knights. 2026-10-29 against Icy Veins.

Notes
	- Stat priorities from Icy Veins' PvE stat priority page for each spec, read as a levelling
	  player: icy-veins.com/tbc-classic/<spec>-pve-stat-priority. Where a levelling page ranks a stat
	  higher than the endgame page, the levelling page wins, except where the add-on has a rule
	  of its own (no Spirit for paladins or shamans).
	- Policy rather than game records: no IDs, so Validate Data counts the rows only.

SQL (CMaNGOS)
	None.

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
