local _, ns = ...

--[[
	Stat combinations that name their own class, on top of the talent-tree
	points, which rank one stat at a time and cannot say that a pair together means
	something neither says alone.

	SOFT BY DESIGN. A rule decides who is in contention, not who is admitted -- everybody the
	weights allowed stays behind it as a fallback. A veto is the exception and is absolute.

	FIRST MATCH WINS, so the order below is data. Two combinations can collide: cloth healing
	gear carrying Intellect and Spirit, which the priest rule takes, and Agility, Intellect and
	Spirit together, which the caster rule takes.
]]

--[[
	requires   every one of these stats must be on the item
	exclusive  and nothing else any class ranks may be
	without    and none of these may be on the item
	armor      the item is body armor of one of these materials; never a cloak, ring or neck
	form       "POTION", "FOOD", "SCROLL" or "OIL_STONE", for a consumable rule
	restores   any one of these, for a consumable rule
	weapon     any one of these weapon keys, for a weapon rule
	unclaimed  only when no eligible class had a stat claim on the item. Pairs with prefer or
	           demote and never with veto, which is applied before anything is scored.
	prefer     these classes are the contenders, if any of them is admitted at all
	demote     these classes drop out of contention, but stay as fallbacks
	veto       these classes are removed outright, before anything is scored
	vetoUnlessRole  every class with no spec of this role turned on is removed, as veto
]]
ns.Data.ITEM_RULES = {
	--[[
		Priests have two healing trees to everybody else's one, and cloth is theirs to begin with:
		a druid one level closer must not take a healing robe off them. First, so the
		Intellect-and-Spirit rule below cannot hand the same robe to a mage. Cloaks are cloth too
		and stay out: any healer wears one.
	]]
	{
		name = "Cloth healing",
		requires = { "HEALING" },
		armor = { "CLOTH" },
		prefer = { "PRIEST" },
	},
	--[[
		"Of the Owl" on cloth armor is a priest's: Intellect and Spirit together is a healer's pair,
		and the priest is the healer who wears cloth. Ahead of the general rule below, which would
		name a mage beside him. Cloaks stay out, as above.
	]]
	{
		name = "Cloth Intellect and Spirit",
		requires = { "INTELLECT", "SPIRIT" },
		armor = { "CLOTH" },
		prefer = { "PRIEST" },
	},
	{
		name = "Intellect and Spirit",
		requires = { "INTELLECT", "SPIRIT" },
		prefer = { "PRIEST", "PALADIN", "SHAMAN", "DRUID", "MONK" },
	},
	--[[
		Healing is a healer's and nobody else's, however much spell damage rides along with it: a
		mage scores the damage half of a "+healing and damage" roll and, with no priest in range,
		used to take it. Vetoed rather than demoted, so there is no last resort for it either.
		Which classes heal is read from the specs the player has on, not listed here.
	]]
	{
		name = "Healing",
		requires = { "HEALING" },
		vetoUnlessRole = "HEALER",
	},
	-- Spirit is a healer stat here, paladins and shamans included; only the warlock gets nothing from it.
	{
		name = "Spirit",
		requires = { "SPIRIT" },
		veto = { "WARLOCK" },
	},
	--[[
		Scoring alone already keeps a warrior and a rogue off a pure caster item; the hybrid
		roll is the gap, since on "of the Gorilla" the warrior claims the Strength half.

		DEMOTED, NOT VETOED, and the difference is what keeps items moving. Heavy armor
		carrying Intellect too far below its material's training level for PROFICIENCY_REACH
		to help -- a level 20 mail chest, where the shaman it was written for is still five
		armor tiers away -- has nobody but the warrior left, so a veto sends it to a vendor
		rather than to somebody who would at least use the Strength.

		Applied last, after the weapon rules, so a rule cannot promote a demoted class back
		into contention. When the demoted are the only ones left, they are the answer.
	]]
	{
		name = "Intellect",
		requires = { "INTELLECT" },
		demote = { "WARRIOR", "ROGUE" },
	},

	--[[
		Potions, and only potions: a rule keyed on what a consumable restores would catch water
		and bread as well, which is why every consumable rule names a form. These say who drinks
		one mid-fight, not who CAN -- a mage drinks healing potions too -- so both stay soft.
		"Restores both" belongs to the mana rule alone, since only mana users are eligible.
	]]
	{
		name = "Healing potions",
		form = "POTION",
		restores = { "HEALTH" },
		prefer = { "WARRIOR", "ROGUE" },
	},
	{
		name = "Mana potions",
		form = "POTION",
		restores = { "MANA", "BOTH" },
		prefer = { "PRIEST", "PALADIN", "SHAMAN", "DRUID", "MONK" },
	},

	--[[
		Which hand a weapon takes, and who that makes it for. No two-hand or polearm rule here:
		a hunter carries no melee weapon, and the plate classes own a two-hander alike, so
		scoring decides those. Staves are the caster weapon and stay out too. Wands, bows, guns,
		crossbows and thrown are out from the other direction: none is melee and the matrix
		already decides them. Shields and held off-hands never reach here.

		No rule needs an "unless it has caster stats" clause: a rule can only name classes that
		scoring already admitted.
	]]
	--[[
		Daggers stay out of the one-hand pool below so the rogue has them to himself. Both rules
		name him; what differs is who stands beside him -- a warrior shares the swords, maces,
		axes and fists, and is only a fallback on a dagger.
	]]
	{
		name = "Daggers",
		weapon = { "DAGGER" },
		prefer = { "ROGUE" },
	},
	--[[
		The classes that fight one-handed, and the matrix decides which kinds each may hold: a
		monk reaches fists, swords, maces and axes, never a dagger.
	]]
	-- FIST is 1H melee like the rest; move it to the dagger rule above if rogues turn out to want it more.
	{
		name = "One-hand weapons",
		weapon = { "1H_SWORD", "1H_MACE", "1H_AXE", "FIST" },
		prefer = { "WARRIOR", "ROGUE", "MONK" },
	},
	--[[
		A ranged weapon with nothing on it to say who it is for. All three of a hunter's trees
		build on the ranged slot and nobody else's does -- a warrior or a rogue carries a gun to
		pull with -- so when the scoring cannot separate them, he is who it is for. Without this
		the tie fell to whoever came first in the class list, which is the warrior.

		UNCLAIMED, NOT EVERY BOW. A ranged weapon carrying stats is decided by them: an Agility
		bow is a rogue's as much as a hunter's and a Strength one is the warrior's, and hunters
		have no special claim on either. Thrown is left out from the other side -- a hunter can
		train it but never carries one, since a thrown weapon does not fire Auto Shot, so the
		matrix gives him a 0 and naming him there would be a line that can never apply.
	]]
	{
		name = "Unclaimed ranged weapons",
		weapon = { "BOW", "GUN", "CROSSBOW" },
		unclaimed = true,
		prefer = { "HUNTER" },
	},
}

-- Matched against items by Features/Match-Derivations.lua, which owns the rule matching.

--[[
How We Got the Data

Last Validated
	Never. Copied from Data/Match-Rules.lua.

Notes
	- Stat combinations that name their own class, on top of the talent-tree points; see the
	-   comments above the table for the fields and the order. Policy rather than game records: no IDs.

SQL (CMaNGOS)
	None.

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
