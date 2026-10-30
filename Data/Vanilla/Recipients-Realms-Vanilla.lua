local _, ns = ...

if ns.IS_DISCOVERY then
	return
end

-- [GetCurrentRegion] = { { realm name, ... }, ... }
local CLUSTERS = {
	-- GetCurrentRegion 1: the Americas and Oceania.
	[1] = {
		-- West PvP
		{
			"Whitemane",
			"Thunderfury",
			"Bigglesworth",
			"Anathema",
			"Fairbanks",
			"Arcanite Reaper",
			"Blaumeux",
			"Kurinnaxx",
			"Smolderweb",
			"Rattlegore",
		},
		-- East PvE
		{ "Mankrik", "Westfall", "Ashkandi", "Pagle", "Windseeker" },
		-- West PvE
		{ "Azuresong", "Atiesh", "Old Blanchy", "Myzrael" },
		-- East PvP
		{ "Faerlina", "Benediction", "Incendius", "Netherwind", "Heartseeker" },
		-- East PvP
		{ "Earthfury", "Herod", "Kirtonos", "Kromcrush", "Skeram", "Stalagg", "Sulfuras", "Thalnos" },
		-- Oceanic PvP
		{ "Arugal", "Felstriker", "Yojamba" },
	},
	-- GetCurrentRegion 3: Europe.
	[3] = {
		-- English PvP
		{
			"Firemaw",
			"Ashbringer",
			"Golemagg",
			"Bloodfang",
			"Noggenfogger",
			"Mograine",
			"Earthshaker",
			"Skullflame",
			"Dragonfang",
			"Gandling",
		},
		-- English PvP
		{ "Dreadmist", "Flamelash", "Gehennas", "Judgement", "Razorgore", "Shazzrah", "Stonespine", "Ten Storms" },
		-- English PvE
		{ "Pyrewood Village", "Mirage Raceway", "Nethergarde Keep" },
		-- German PvE
		{ "Everlook", "Lakeshire" },
		-- German PvP
		{ "Lucifron", "Patchwerk", "Transcendence" },
		-- German PvP
		{ "Dragon's Call", "Heartstriker", "Venoxis" },
		-- French PvP
		{ "Amnennar", "Finkle", "Sulfuron" },
		-- Russian PvP: Flamegor, Harbinger of Doom, Rhok'delar, Wyrmthalak
		{
			"Пламегор",
			"Вестник Рока",
			"Рок-Делар",
			"Змейталак",
			"Flamegor",
			"Harbinger of Doom",
			"Rhok'delar",
			"Wyrmthalak",
		},
	},
}

ns.Data.LINKED_REALMS = CLUSTERS[GetCurrentRegion and GetCurrentRegion()] or {}

--[[
How We Got the Data

Last Validated
	2026-10-29, Classic Era 1.15.9.70576

Notes
	- Classic Era's connected realms: mail reaches any character of the same faction on a realm
	  in the same cluster, so an alt on Pagle is in reach from Mankrik and one on Azuresong is
	  not, PvE though both are. Only clusters of two or more are listed; a realm alone reaches
	  only itself.
	- Grouped by GetCurrentRegion, and LINKED_REALMS holds only the player's own region's
	  clusters.
	- From ironforge.pro/population/era, the 14-20 October 2026 reset. Blizzard reshuffles
	  clusters, so this goes stale: the Diagnostics roster report prints this realm's cluster
	  beside the client's own GetAutoCompleteRealms, which is where a drift shows.
	- Names as the realm list spells them, spaces and all: Features/Recipients-Alts.lua compares
	  them without spaces, hyphens or case. The Russian realms are listed in both scripts, since
	  the client names them in Cyrillic.
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
