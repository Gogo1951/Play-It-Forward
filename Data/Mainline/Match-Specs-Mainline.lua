local _, ns = ...

-- Forward-prep: a copy of Data/Mists/Match-Specs-Mists.lua, whose comments say what the points mean.
local MELEE = { "HIT", "EXPERTISE", "CRIT", "HASTE", "MASTERY" }
local CASTER = { "HIT", "CRIT", "HASTE", "MASTERY" }
local HEALER = { "SPIRIT", "CRIT", "HASTE", "MASTERY" }
-- The casters whose Spirit is hit rating.
local HYBRID_CASTER = { "SPIRIT", "HIT", "CRIT", "HASTE", "MASTERY" }

-- key and role as every folder's Match-Specs file writes them; off ships the spec turned off.
local function Spec(key, role, off, primary, kind, secondaries)
	local main = { primary }
	if kind then
		main[#main + 1] = kind
	end
	return { key = key, role = role, off = off or nil, main = main, useful = secondaries }
end

ns.Data.SPECS = {
	WARRIOR = {
		Spec("Arms", "MELEE", true, "STRENGTH", nil, MELEE),
		Spec("Fury", "MELEE", false, "STRENGTH", nil, MELEE),
		Spec("Protection", "TANK", false, "STRENGTH", nil, MELEE),
	},
	PALADIN = {
		Spec("Holy", "HEALER", false, "INTELLECT", "HEALING", HEALER),
		Spec("Protection", "TANK", true, "STRENGTH", nil, MELEE),
		Spec("Retribution", "MELEE", false, "STRENGTH", nil, MELEE),
	},
	HUNTER = {
		Spec("BeastMastery", "RANGED", false, "AGILITY", nil, MELEE),
		Spec("Marksmanship", "RANGED", false, "AGILITY", nil, MELEE),
		Spec("Survival", "RANGED", false, "AGILITY", nil, MELEE),
	},
	ROGUE = {
		Spec("Assassination", "MELEE", false, "AGILITY", nil, MELEE),
		Spec("Combat", "MELEE", false, "AGILITY", nil, MELEE),
		Spec("Subtlety", "MELEE", false, "AGILITY", nil, MELEE),
	},
	PRIEST = {
		Spec("Discipline", "HEALER", false, "INTELLECT", "HEALING", HEALER),
		Spec("Holy", "HEALER", false, "INTELLECT", "HEALING", HEALER),
		Spec("Shadow", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", HYBRID_CASTER),
	},
	SHAMAN = {
		Spec("Elemental", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", HYBRID_CASTER),
		Spec("Enhancement", "MELEE", true, "AGILITY", nil, MELEE),
		Spec("Restoration", "HEALER", false, "INTELLECT", "HEALING", HEALER),
	},
	MAGE = {
		Spec("Arcane", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
		Spec("Fire", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
		Spec("Frost", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
	},
	WARLOCK = {
		Spec("Affliction", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
		Spec("Demonology", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
		Spec("Destruction", "CASTER", false, "INTELLECT", "SPELL_DAMAGE", CASTER),
	},
	DRUID = {
		Spec("Balance", "CASTER", true, "INTELLECT", "SPELL_DAMAGE", HYBRID_CASTER),
		Spec("Feral", "MELEE", false, "AGILITY", nil, MELEE),
		Spec("Guardian", "TANK", true, "AGILITY", nil, MELEE),
		Spec("Restoration", "HEALER", false, "INTELLECT", "HEALING", HEALER),
	},
	DEATHKNIGHT = {
		Spec("Blood", "TANK", false, "STRENGTH", nil, MELEE),
		Spec("Frost", "MELEE", false, "STRENGTH", nil, MELEE),
		Spec("Unholy", "MELEE", false, "STRENGTH", nil, MELEE),
	},
	MONK = {
		Spec("Brewmaster", "TANK", true, "AGILITY", nil, MELEE),
		Spec("Mistweaver", "HEALER", false, "INTELLECT", "HEALING", HEALER),
		Spec("Windwalker", "MELEE", true, "AGILITY", nil, MELEE),
	},
}
