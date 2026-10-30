local _, ns = ...

if ns.IS_DISCOVERY then
	return
end

-- [classToken] = { { key, role, off, main, useful }, ... }
ns.Data.SPECS = {
	WARRIOR = {
		{
			key = "Arms",
			role = "MELEE",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "AGILITY" },
		},
		{
			key = "Fury",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "AGILITY" },
		},
		{ key = "Protection", role = "TANK", main = { "STRENGTH" }, useful = { "ATTACK_POWER", "CRIT", "HIT" } },
	},
	PALADIN = {
		{ key = "Holy", role = "HEALER", main = { "INTELLECT", "HEALING", "MP5" }, useful = { "SPELL_CRIT" } },
		{
			key = "Protection",
			role = "TANK",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "HIT", "SPELL_DAMAGE", "HOLY" },
		},
		{
			key = "Retribution",
			role = "MELEE",
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "AGILITY" },
		},
	},
	HUNTER = {
		{
			key = "BeastMastery",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "RANGED_AP", "INTELLECT" },
		},
		{
			key = "Marksmanship",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "RANGED_AP", "INTELLECT" },
		},
		{
			key = "Survival",
			role = "RANGED",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "RANGED_AP" },
		},
	},
	ROGUE = {
		{
			key = "Assassination",
			role = "MELEE",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "STRENGTH" },
		},
		{
			key = "Combat",
			role = "MELEE",
			main = { "AGILITY" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "STRENGTH" },
		},
		{ key = "Subtlety", role = "MELEE", main = { "AGILITY" }, useful = { "ATTACK_POWER", "CRIT", "HIT" } },
	},
	PRIEST = {
		{
			key = "Discipline",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "HOLY", "SPELL_CRIT" },
		},
		{
			key = "Holy",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "HOLY", "SPELL_CRIT" },
		},
		{
			key = "Shadow",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "MP5" },
		},
	},
	SHAMAN = {
		{
			key = "Elemental",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "MP5", "NATURE" },
		},
		{
			key = "Enhancement",
			role = "MELEE",
			off = true,
			main = { "STRENGTH" },
			useful = { "ATTACK_POWER", "CRIT", "HIT", "AGILITY" },
		},
		{
			key = "Restoration",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPELL_CRIT" },
		},
	},
	MAGE = {
		{
			key = "Arcane",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "ARCANE" },
		},
		{
			key = "Fire",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "FIRE" },
			useful = { "SPELL_CRIT", "SPELL_HIT" },
		},
		{
			key = "Frost",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "FROST" },
			useful = { "SPELL_CRIT", "SPELL_HIT" },
		},
	},
	WARLOCK = {
		{
			key = "Affliction",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_HIT", "STAMINA" },
		},
		{
			key = "Demonology",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_HIT", "STAMINA" },
		},
		{
			key = "Destruction",
			role = "CASTER",
			main = { "INTELLECT", "SPELL_DAMAGE", "SHADOW" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "FIRE" },
		},
	},
	DRUID = {
		{
			key = "Balance",
			role = "CASTER",
			off = true,
			main = { "INTELLECT", "SPELL_DAMAGE" },
			useful = { "SPELL_CRIT", "SPELL_HIT", "ARCANE", "NATURE" },
		},
		{
			key = "Feral",
			role = "MELEE",
			main = { "STRENGTH", "AGILITY", "FERAL_AP" },
			useful = { "ATTACK_POWER", "CRIT", "HIT" },
		},
		{
			key = "Restoration",
			role = "HEALER",
			main = { "INTELLECT", "HEALING", "MP5" },
			useful = { "SPIRIT", "SPELL_CRIT" },
		},
	},
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Classic Era 1.15.9.70576

Notes
	- Every spec this client has, in talent-tab order, as the player levelling it. Read by
	  Features/Match-Derivations.lua, which sums the specs the player has on into class
	  weights, and by the Recipients panel's Classes & Specs section, which draws one switch
	  per spec.
	- key names the spec in saved settings and in L["SPEC_" .. key]. role is HEALER, CASTER,
	  MELEE, RANGED or TANK; the Healing rule reads HEALER. main is the stats the spec builds
	  around, worth 2 points, and useful the stats it gears for, worth 1.
	- off ships the spec turned off. Nobody can see a stranger's spec, so some are assumed:
	  Protection paladins, Enhancement shamans, Arms and Balance start off, and the player can
	  turn any of them back on.
	- MP5 is every healer's, as main. Spirit is never a paladin's or a shaman's, whatever a
	  guide ranks it while levelling: this folder's Match-Rules file vetoes them on it.
	- Stamina is everybody's and so nobody's, except the two warlock trees that Life Tap
	  hardest. Defense, dodge, parry and block are nobody's: nobody levels on them, and tank
	  gear gets sharded.
	- Stat priorities from Icy Veins' PvE stat priority page for each spec, read as a levelling
	  player: icy-veins.com/wow-classic/<spec>-pve-stat-priority. Where a levelling page ranks a stat
	  higher than the endgame page, the levelling page wins, except where the add-on has a rule
	  of its own (no Spirit for paladins or shamans).
	- Stat priorities checked against Icy Veins on 2026-10-29.
	- Policy rather than game records: no IDs, so Validate Data counts the rows only.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
