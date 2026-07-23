local _, ns = ...

--[[
	Levelling zones, and who is in them -- input to the /who queries in
	Features/Recipients-Who.lua. A bare `/who 21-22` is capped at 50 on a connected cluster
	and mostly returns people standing in a capital; adding `z-"Redridge Mountains"` returns
	people actually out there levelling, and few enough that the cap stops mattering.

	These are the strings the client's own /who parser matches: deliberately not localized, and
	never to be run through AceLocale. Zone filtering is therefore ENGLISH-ONLY -- other clients
	match nothing and fall back to bare level queries, which still works, just slower. The fix
	is each zone's uiMapID read through C_Map.GetMapInfo, with the IDs verified against a live
	client, since a wrong one queries the wrong zone and says nothing about it.
]]

--[[
	FACTION IS DERIVED, NOT SOURCED. Every other column came from the author's own zone list;
	this one did not, so it is the one to check. It exists because /who is same-faction: a
	Horde player querying Elwynn Forest gets nothing back. BOTH is the safe default --
	marking a zone for one faction when the other levels there too throws a good zone away
	permanently, where the reverse costs one empty query -- so only starting zones and
	single-hub zones are locked.
]]
local A, H, BOTH = "Alliance", "Horde", nil

--[[
	name, min level, max level, faction, then the flavors to search in: Era, TBC, Wrath.
	Three columns rather than one "available from" so a row checks against the author's list.
]]
ns.Data.Zones = {
	{ "Elwynn Forest", 1, 10, A, 1, 1, 1 },
	{ "Azuremyst Isle", 1, 10, A, 0, 1, 1 },
	{ "Mulgore", 1, 10, H, 1, 1, 1 },
	{ "Durotar", 1, 10, H, 1, 1, 1 },
	{ "Eversong Woods", 1, 10, H, 0, 1, 1 },
	{ "Teldrassil", 1, 11, A, 1, 1, 1 },
	{ "Dun Morogh", 1, 12, A, 1, 1, 1 },
	{ "Tirisfal Glades", 1, 12, H, 1, 1, 1 },
	{ "Westfall", 9, 18, A, 1, 1, 1 },
	{ "Bloodmyst Isle", 9, 19, A, 0, 1, 1 },
	{ "Loch Modan", 10, 18, A, 1, 1, 1 },
	{ "Silverpine Forest", 10, 20, H, 1, 1, 1 },
	{ "Ghostlands", 10, 20, H, 0, 1, 1 },
	{ "Duskwood", 10, 30, A, 1, 1, 1 },
	{ "The Barrens", 10, 33, H, 1, 1, 1 },
	{ "Darkshore", 11, 19, A, 1, 1, 1 },
	{ "Redridge Mountains", 15, 25, A, 1, 1, 1 },
	{ "Stonetalon Mountains", 15, 25, BOTH, 1, 1, 1 },
	{ "Ashenvale", 19, 30, BOTH, 1, 1, 1 },
	{ "Wetlands", 20, 30, A, 1, 1, 1 },
	{ "Hillsbrad Foothills", 20, 31, BOTH, 1, 1, 1 },
	{ "Thousand Needles", 24, 35, BOTH, 1, 1, 1 },
	{ "Alterac Mountains", 27, 39, BOTH, 1, 1, 1 },
	{ "Desolace", 30, 39, BOTH, 1, 1, 1 },
	{ "Arathi Highlands", 30, 40, BOTH, 1, 1, 1 },
	{ "Stranglethorn Vale", 30, 50, BOTH, 1, 1, 1 },
	{ "Swamp of Sorrows", 36, 43, BOTH, 1, 1, 1 },
	{ "Badlands", 36, 45, BOTH, 1, 1, 1 },
	{ "Dustwallow Marsh", 36, 61, BOTH, 1, 1, 1 },
	{ "Tanaris", 40, 50, BOTH, 1, 1, 1 },
	{ "The Hinterlands", 41, 49, BOTH, 1, 1, 1 },
	{ "Feralas", 41, 60, BOTH, 1, 1, 1 },
	{ "Azshara", 42, 55, BOTH, 1, 1, 1 },
	{ "Searing Gorge", 43, 56, BOTH, 1, 1, 1 },
	{ "Western Plaguelands", 46, 57, BOTH, 1, 1, 1 },
	{ "Blasted Lands", 46, 63, BOTH, 1, 1, 1 },
	{ "Felwood", 47, 54, BOTH, 1, 1, 1 },
	{ "Un'Goro Crater", 48, 55, BOTH, 1, 1, 1 },
	{ "Burning Steppes", 50, 59, BOTH, 1, 1, 1 },
	{ "Deadwind Pass", 50, 60, BOTH, 1, 1, 1 },
	{ "Eastern Plaguelands", 54, 59, BOTH, 1, 1, 1 },
	{ "Silithus", 55, 59, BOTH, 1, 1, 1 },
	{ "Winterspring", 55, 60, BOTH, 1, 1, 1 },
	{ "Hellfire Peninsula", 58, 70, BOTH, 0, 1, 1 },
	{ "Zangarmarsh", 60, 63, BOTH, 0, 1, 1 },
	{ "Terokkar Forest", 62, 70, BOTH, 0, 1, 1 },
	{ "Nagrand", 64, 70, BOTH, 0, 1, 1 },
	{ "Blade's Edge Mountains", 65, 70, BOTH, 0, 1, 1 },
	{ "Netherstorm", 66, 70, BOTH, 0, 1, 1 },
	{ "Shadowmoon Valley", 67, 70, BOTH, 0, 1, 1 },
	{ "Howling Fjord", 68, 72, BOTH, 0, 0, 1 },
	{ "Borean Tundra", 70, 72, BOTH, 0, 0, 1 },
	{ "Dragonblight", 71, 80, BOTH, 0, 0, 1 },
	{ "Grizzly Hills", 73, 75, BOTH, 0, 0, 1 },
	{ "Zul'Drak", 73, 77, BOTH, 0, 0, 1 },
	{ "Sholazar Basin", 75, 80, BOTH, 0, 0, 1 },
	{ "Icecrown", 77, 80, BOTH, 0, 0, 1 },
	{ "The Storm Peaks", 77, 80, BOTH, 0, 0, 1 },
}

-- Exported: Features/Recipients-Who.lua reads rows through these same columns.
ns.Data.ZoneColumns = { NAME = 1, MIN = 2, MAX = 3, FACTION = 4, ERA = 5, TBC = 6, WRATH = 7 }

-- Ordered and filtered into a search plan by ns.Data.ZonesFor, in Features/Recipients-Who.lua.
