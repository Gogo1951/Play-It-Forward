local _, ns = ...

-- [GetCurrentRegion] = { { realm name, ... }, ... }
local CLUSTERS = {
	-- GetCurrentRegion 1: the Americas and Oceania.
	[1] = {
		-- PvE
		{ "Pagle", "Galakras", "Raden", "Lei Shen", "Nazgrim", "Immerseus" },
	},
	-- GetCurrentRegion 3: Europe.
	[3] = {
		-- English PvE
		{ "Shek'zeer", "Mirage Raceway", "Hoptallus", "Garalon", "Norushen" },
		-- German PvE
		{ "Everlook", "Ook Ook" },
	},
}

ns.Data.LINKED_REALMS = CLUSTERS[GetCurrentRegion and GetCurrentRegion()] or {}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- Mists Classic's connected realms: mail reaches any character of the same faction on a
	  realm in the same cluster. Only clusters of two or more are listed; a realm alone reaches
	  only itself.
	- Some names repeat Classic Era's, Pagle and Everlook among them, but these are other realms
	  in other clusters, which is why each flavor keeps its own list.
	- Grouped by GetCurrentRegion, and LINKED_REALMS holds only the player's own region's
	  clusters.
	- From ironforge.pro/population/classic, the 14-20 October 2026 reset. Blizzard reshuffles
	  clusters, so this goes stale: the Diagnostics roster report prints this realm's cluster
	  beside the client's own GetAutoCompleteRealms, which is where a drift shows.
	- Names as the realm list spells them, spaces and all: Features/Recipients-Alts.lua compares
	  them without spaces, hyphens or case.
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
