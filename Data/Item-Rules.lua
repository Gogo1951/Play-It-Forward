local _, ns = ...

--[[
	Stat combinations that name their own class, on top of the point tables.

	Data/Stat-Weights.lua ranks one stat at a time and cannot say that a pair together
	means something neither says alone: Intellect with Spirit is caster gear, Agility with
	Intellect is a hunter's, Stamina with nothing else is a warlock's.

	SOFT BY DESIGN. A rule decides who is in contention, not who is admitted: everybody the
	weights allowed stays behind it as a fallback. A veto is the exception and is absolute,
	because a warlock gets nothing whatsoever out of Spirit.

	FIRST MATCH WINS, so the order below is data. Only one combination can collide --
	Agility, Intellect and Spirit together -- and the caster rule takes it.
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
		The only pair a hunter needs together and nobody else does: a rogue wants the
		Agility and none of the Intellect, a mage the reverse. On cloth as much as on mail,
		since cloth admits everybody and only the stat line says anything.
	]]
	{
		name = "Agility and Intellect",
		requires = { "AGILITY", "INTELLECT" },
		prefer = { "HUNTER" },
	},
	--[[
		Exclusive, because Stamina beside anything else is that other stat's item. Life
		Tap is what makes a bare Stamina roll worth mailing at all rather than vendoring.
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
		Scoring alone already keeps a warrior and a rogue off a pure caster item. A hybrid
		roll is the gap: on "of the Gorilla" the warrior claims the Strength half, and the
		weapon rules below then promote him into contention on a one-hander.

		DEMOTED, NOT VETOED, and the difference is what keeps items moving. Sub-40 mail and
		plate carrying Intellect has nobody else in heavy armor to fall back to, so a veto
		sends those to a vendor rather than to a warrior who would use the Strength.

		Applied last, after the weapon rules have had their say, so a rule cannot promote a
		demoted class back into contention. When the demoted are the only ones left, they
		are the answer.
	]]
	{
		name = "Intellect",
		requires = { "INTELLECT" },
		demote = { "WARRIOR", "ROGUE" },
	},

	--[[
		Potions, and only potions: a rule keyed on what a consumable restores would catch
		water and bread as well, which is why every consumable rule names a form.

		Who drinks one mid-fight, not who CAN use one -- a mage drinks healing potions often
		enough -- so both are soft and everybody stays admitted behind them. "Restores both"
		belongs to the mana rule alone, since only mana users are eligible for one at all.
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
		Which hand a weapon takes, and who that makes it for. The point tables put a druid
		level with a warrior on a one-hand mace and ahead of a rogue, so a good one lands on
		him and is wasted twice.

		A STAFF IS NOT A TWO-HANDER HERE, and leaving it out is the one judgement in this
		pair. It is the caster weapon -- every mage, priest and warlock has nothing else --
		so putting staves under the two-hand rule would hand each one to a druid ahead of
		the three classes it was made for. Wands, bows, guns, crossbows and thrown are out
		from the other direction: none is a melee weapon and the matrix already decides
		them. Shields and held off-hands are armor by class and never reach here.

		Nothing here needs an "unless it has caster stats" clause: a rule can only ever name
		classes that scoring already admitted.
	]]
	--[[
		Daggers are their own rule and belong to rogues alone. Every class can be handed one
		and most casters are group 1 for it, but a rogue is the only class that builds
		around them. Pooled with the other one-handers, a warrior and a rogue compete for
		each other's weapons when each has a kind of its own.
	]]
	{
		name = "Daggers",
		weapon = { "DAGGER" },
		prefer = { "ROGUE" },
	},
	--[[
		FIST sits here because it is 1H melee like the rest of the group. A combat rogue
		wants one about as much as a warrior does and is still a fallback for them -- move
		FIST to the rule above if that turns out to be the wrong way round.
	]]
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
		A polearm is a hunter's before it is a two-hander, so POLEARM is out of the rule
		above rather than merely ahead of it -- a key sitting in a rule that can never reach
		it is a comment that lies. It is where an Agility two-hander goes.
	]]
	{
		name = "Polearms",
		weapon = { "POLEARM" },
		prefer = { "HUNTER" },
	},
}

-- Matched against items by Features/Matching-Engine.lua, which owns the rule engine.
