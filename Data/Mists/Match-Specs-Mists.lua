local _, ns = ...

--[[
	Mists' specializations, in the shape Features/Match-Derivations.lua sums. Every folder's
	Match-Specs file declares this table; the Classic folders hold the three talent trees. Same points, same
	rule -- a stat a spec builds around is main (2), one it gears for is useful (1) -- and the same
	reading of every spec as the player levelling it.

	ONE PRIMARY STAT PER SPEC, which is what makes Mists simpler than Classic: Strength is a plate
	wearer's, Agility a leather or mail fighter's or a hunter's, Intellect a caster's or a healer's,
	and a stat a spec does not use is worth nothing to it at all. Hunters dropped Intellect with
	their mana, Enhancement shamans and both druid melee specs moved to Agility, and a rogue gets
	nothing from Strength.

	THE SECONDARIES DO NOT DECIDE, and are listed anyway. Every damage spec gears for hit, crit,
	haste and mastery, so they sum alike across classes and the primary stat still names the class;
	what they buy is coverage, so a ring of Agility and haste counts as all used by a rogue rather
	than half. Expertise is the melee and hunter kind of hit, which no caster wants. Spirit is a
	healer's mana, and hit to the three casters whose Spirit converts to it -- Balance, Shadow and
	Elemental -- but never a mage's or a warlock's. Dodge and parry stay unweighted, as in Classic:
	nobody levels on them.

	FOUR DRUID SPECS. Features/Match-Derivations.lua brings any class above three back to the three-tree
	scale, so Intellect on two of four druid specs weighs 3 where a shaman's two of three weigh 4.
]]
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
