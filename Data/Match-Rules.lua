local _, ns = ...

--[[
	Stat combinations that name their own class, on top of the point tables:
	Data/Match-Stats.lua ranks one stat at a time and cannot say that a pair together means
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
	armor      the item is body armor of one of these materials; never a cloak, ring or neck
	form       "POTION", "FOOD" or "SCROLL", for a consumable rule
	restores   any one of these, for a consumable rule
	weapon     any one of these weapon keys, for a weapon rule
	unclaimed  only when no eligible class had a stat claim on the item. Pairs with prefer or
	           demote and never with veto, which is applied before anything is scored.
	prefer     these classes are the contenders, if any of them is admitted at all
	demote     these classes drop out of contention, but stay as fallbacks
	veto       these classes are removed outright, before anything is scored
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
	{
		name = "Intellect and Spirit",
		requires = { "INTELLECT", "SPIRIT" },
		prefer = { "PRIEST", "MAGE", "DRUID" },
	},
	--[[
		The only pair a hunter needs together and nobody else does: a rogue wants the Agility
		and none of the Intellect, a mage the reverse. True on cloth too, which admits everybody.
	]]
	{
		name = "Agility and Intellect",
		requires = { "AGILITY", "INTELLECT" },
		prefer = { "HUNTER" },
	},
	--[[
		Exclusive, because Stamina beside anything else is that other stat's item. Life Tap is
		what makes a bare Stamina roll worth mailing at all rather than vendoring.
	]]
	{
		name = "Stamina alone",
		requires = { "STAMINA" },
		exclusive = true,
		prefer = { "WARLOCK" },
	},
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
		prefer = { "PRIEST", "PALADIN", "SHAMAN", "DRUID" },
	},

	--[[
		Which hand a weapon takes, and who that makes it for. The point tables put a druid level
		with a warrior on a one-hand mace and ahead of a rogue, so a good one lands on him and
		is wasted twice.

		A STAFF IS NOT A TWO-HANDER HERE. It is the caster weapon -- every mage, priest and
		warlock has nothing else -- so putting staves under the two-hand rule would hand each
		one to a druid ahead of the three classes it was made for. Wands, bows, guns, crossbows
		and thrown are out from the other direction: none is melee and the matrix already
		decides them. Shields, held off-hands and relics never reach here.

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
		The two classes that fight one-handed, and the matrix decides which kinds each may hold:
		a rogue reaches swords, maces and fists, and axes only from Wrath, so naming him costs
		nothing there.
	]]
	-- FIST is 1H melee like the rest; move it to the dagger rule above if rogues turn out to want it more.
	{
		name = "One-hand weapons",
		weapon = { "1H_SWORD", "1H_MACE", "1H_AXE", "FIST" },
		prefer = { "WARRIOR", "ROGUE" },
	},
	--[[
		A hunter's melee weapon is a stat stick: his damage comes out of the ranged slot, so the
		largest stat budget wins and that is a two-hander. A druid is the same case from the other
		side -- form damage scales off attack power, not the weapon's own damage. The matrix keeps
		each to what he can carry: a druid only meets 2H maces here, a hunter only swords and axes.
	]]
	{
		name = "Two-hand weapons",
		weapon = { "2H_SWORD", "2H_MACE", "2H_AXE" },
		prefer = { "DRUID", "PALADIN", "HUNTER" },
	},
	--[[
		A polearm is a hunter's before it is a two-hander, so POLEARM is out of the rule above
		rather than merely ahead of it: a key sitting in a rule that can never reach it lies.
	]]
	{
		name = "Polearms",
		weapon = { "POLEARM" },
		prefer = { "HUNTER" },
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
