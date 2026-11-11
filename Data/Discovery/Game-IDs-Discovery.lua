local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

-- [constant] = spellId, -- Spell Name
ns.Data.SPELL_IDS = {
	DISENCHANT = 13262, -- Disenchant
}

--[[
How We Got the Data

Last Validated
	Never.

Notes
	- The game records Play It Forward shows by name, stored by ID so the client supplies the name in every locale.
	- DISENCHANT is the Disenchant spell: its name labels the Distribution Window's Disenchant tick, the Disenchant section band and the picker's Disenchant row (ns.DisenchantName in Features/Utilities.lua).

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/SpellName?build=1.15.9.70576

QuestieDB
	None.
]]
