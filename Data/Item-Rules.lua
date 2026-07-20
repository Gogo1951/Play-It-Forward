local _, ns = ...

--[[
	Stat combinations that name their own class, on top of the point tables:
	Data/Stat-Weights.lua ranks one stat at a time and cannot say that a pair together means
	something neither says alone.

	SOFT BY DESIGN. A rule decides who is in contention, not who is admitted -- everybody the
	weights allowed stays behind it as a fallback. A veto is the exception and is absolute.

	FIRST MATCH WINS, so the order below is data. Only one combination can collide -- Agility,
	Intellect and Spirit together -- and the caster rule takes it.
]]

--[[
	requires   every one of these stats must be on the item
	exclusive  and nothing else any class ranks may be
	form       "POTION" or "FOOD", for a consumable rule
	restores   any one of these, for a consumable rule
	weapon     any one of these weapon keys, for a weapon rule
	prefer     these classes are the contenders, if any of them is admitted at all
	demote     these classes drop out of contention, but stay as fallbacks
	veto       these classes are removed outright, before anything is scored
]]
ns.Data.ItemRules = {
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

		DEMOTED, NOT VETOED, and the difference is what keeps items moving. Sub-40 mail and
		plate carrying Intellect has nobody else in heavy armor to fall back to, so a veto
		sends those to a vendor rather than to a warrior who would use the Strength.

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
		decides them. Shields and held off-hands never reach here.

		No rule needs an "unless it has caster stats" clause: a rule can only name classes that
		scoring already admitted.
	]]
	--[[
		Daggers get their own rule because a rogue is the only class that builds around them.
		Pooled with the other one-handers, a warrior and a rogue compete for each other's
		weapons when each has a kind of its own.
	]]
	{
		name = "Daggers",
		weapon = { "DAGGER" },
		prefer = { "ROGUE" },
	},
	-- FIST is 1H melee like the rest; move it to the dagger rule above if rogues turn out to want it more.
	{
		name = "One-hand weapons",
		weapon = { "1H_SWORD", "1H_MACE", "1H_AXE", "FIST" },
		prefer = { "WARRIOR" },
	},
	{
		name = "Two-hand weapons",
		weapon = { "2H_SWORD", "2H_MACE", "2H_AXE" },
		prefer = { "DRUID", "PALADIN" },
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
}

-- Matched against items by Features/Matching-Engine.lua, which owns the rule engine.
