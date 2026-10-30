local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

-- { { realm name, ... }, ... }
ns.Data.LINKED_REALMS = {}

--[[
How We Got the Data

Last Validated
	2026-10-29, Season of Discovery 1.15.9.70576

Notes
	- Season of Discovery runs on megaservers, with no connected realms to list: an alt is in reach
	  only on its own realm. Kept as an empty table so every flavor folder declares the same
	  tables, and Features/Recipients-Alts.lua finds no cluster.
	- No client API names a realm off this cluster, so Validate Data counts the rows only.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	None.

QuestieDB
	None.
]]
