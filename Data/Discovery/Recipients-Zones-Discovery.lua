local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

--[[
	Levelling zones, and who is in them -- input to the /who queries in
	Features/Recipients-Who.lua. A bare `/who 21-22` is capped at 50 on a connected cluster
	and mostly returns people standing in a capital; adding `z-"Redridge Mountains"` returns
	people actually out there levelling, and few enough that the cap stops mattering.

	Each row is an AreaTable ID, and Features/Recipients-Who.lua asks C_Map.GetAreaInfo for its
	name in the client's own language: /who matches the area name, which in some locales is not
	the map's name. A wrong ID queries the wrong zone and says nothing about it.
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

-- { areaID, min level, max level, faction }
ns.Data.ZONES = {
	{ 12, 1, 10, A }, -- Elwynn Forest
	{ 215, 1, 10, H }, -- Mulgore
	{ 14, 1, 10, H }, -- Durotar
	{ 141, 1, 11, A }, -- Teldrassil
	{ 1, 1, 12, A }, -- Dun Morogh
	{ 85, 1, 12, H }, -- Tirisfal Glades
	{ 40, 9, 18, A }, -- Westfall
	{ 38, 10, 18, A }, -- Loch Modan
	{ 130, 10, 20, H }, -- Silverpine Forest
	{ 10, 10, 30, A }, -- Duskwood
	{ 17, 10, 33, H }, -- The Barrens
	{ 148, 11, 19, A }, -- Darkshore
	{ 44, 15, 25, A }, -- Redridge Mountains
	{ 406, 15, 25, BOTH }, -- Stonetalon Mountains
	{ 331, 19, 30, BOTH }, -- Ashenvale
	{ 11, 20, 30, A }, -- Wetlands
	{ 267, 20, 31, BOTH }, -- Hillsbrad Foothills
	{ 400, 24, 35, BOTH }, -- Thousand Needles
	{ 36, 27, 39, BOTH }, -- Alterac Mountains
	{ 405, 30, 39, BOTH }, -- Desolace
	{ 45, 30, 40, BOTH }, -- Arathi Highlands
	{ 33, 30, 50, BOTH }, -- Stranglethorn Vale
	{ 8, 36, 43, BOTH }, -- Swamp of Sorrows
	{ 3, 36, 45, BOTH }, -- Badlands
	{ 15, 36, 61, BOTH }, -- Dustwallow Marsh
	{ 440, 40, 50, BOTH }, -- Tanaris
	{ 47, 41, 49, BOTH }, -- The Hinterlands
	{ 357, 41, 60, BOTH }, -- Feralas
	{ 16, 42, 55, BOTH }, -- Azshara
	{ 51, 43, 56, BOTH }, -- Searing Gorge
	{ 28, 46, 57, BOTH }, -- Western Plaguelands
	{ 4, 46, 63, BOTH }, -- Blasted Lands
	{ 361, 47, 54, BOTH }, -- Felwood
	{ 490, 48, 55, BOTH }, -- Un'Goro Crater
	{ 46, 50, 59, BOTH }, -- Burning Steppes
	{ 41, 50, 60, BOTH }, -- Deadwind Pass
	{ 139, 54, 59, BOTH }, -- Eastern Plaguelands
	{ 1377, 55, 59, BOTH }, -- Silithus
	{ 618, 55, 60, BOTH }, -- Winterspring
}

-- Exported: Features/Recipients-Who.lua reads rows through these same columns.
ns.Data.ZONE_COLUMNS = { AREA_ID = 1, MIN = 2, MAX = 3, FACTION = 4 }

-- Ordered and filtered into a search plan by ns.Data.ZonesFor, in Features/Recipients-Who.lua.
