local _, ns = ...

local A, H, BOTH = "Alliance", "Horde", nil

-- { areaID, min level, max level, faction }
ns.Data.ZONES = {
	{ 12, 1, 10, A }, -- Elwynn Forest
	{ 3524, 1, 10, A }, -- Azuremyst Isle
	{ 215, 1, 10, H }, -- Mulgore
	{ 14, 1, 10, H }, -- Durotar
	{ 3430, 1, 10, H }, -- Eversong Woods
	{ 141, 1, 11, A }, -- Teldrassil
	{ 1, 1, 12, A }, -- Dun Morogh
	{ 85, 1, 12, H }, -- Tirisfal Glades
	{ 40, 9, 18, A }, -- Westfall
	{ 3525, 9, 19, A }, -- Bloodmyst Isle
	{ 38, 10, 18, A }, -- Loch Modan
	{ 130, 10, 20, H }, -- Silverpine Forest
	{ 3433, 10, 20, H }, -- Ghostlands
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
	{ 3483, 58, 70, BOTH }, -- Hellfire Peninsula
	{ 3521, 60, 63, BOTH }, -- Zangarmarsh
	{ 3519, 62, 70, BOTH }, -- Terokkar Forest
	{ 3518, 64, 70, BOTH }, -- Nagrand
	{ 3522, 65, 70, BOTH }, -- Blade's Edge Mountains
	{ 3523, 66, 70, BOTH }, -- Netherstorm
	{ 3520, 67, 70, BOTH }, -- Shadowmoon Valley
}

-- [field] = its position in a ZONES row
ns.Data.ZONE_COLUMNS = { AREA_ID = 1, MIN = 2, MAX = 3, FACTION = 4 }

-- { areaID }
ns.Data.INSTANCE_AREAS = {
	{ 3428 }, -- Ahn'Qiraj
	{ 3790 }, -- Auchenai Crypts
	{ 3959 }, -- Black Temple
	{ 719 }, -- Blackfathom Deeps
	{ 1584 }, -- Blackrock Depths
	{ 1583 }, -- Blackrock Spire
	{ 2677 }, -- Blackwing Lair
	{ 2557 }, -- Dire Maul
	{ 721 }, -- Gnomeregan
	{ 3923 }, -- Gruul's Lair
	{ 3535 }, -- Hellfire Citadel
	{ 3562 }, -- Hellfire Ramparts
	{ 267 }, -- Hillsbrad Foothills
	{ 616 }, -- Hyjal
	{ 3605 }, -- Hyjal Past
	{ 3606 }, -- Hyjal Summit
	{ 3457 }, -- Karazhan
	{ 4131 }, -- Magisters' Terrace
	{ 3836 }, -- Magtheridon's Lair
	{ 3792 }, -- Mana-Tombs
	{ 2100 }, -- Maraudon
	{ 2717 }, -- Molten Core
	{ 3456 }, -- Naxxramas
	{ 2367 }, -- Old Hillsbrad Foothills
	{ 2159 }, -- Onyxia's Lair
	{ 2437 }, -- Ragefire Chasm
	{ 722 }, -- Razorfen Downs
	{ 491 }, -- Razorfen Kraul
	{ 3429 }, -- Ruins of Ahn'Qiraj
	{ 796 }, -- Scarlet Monastery
	{ 2057 }, -- Scholomance
	{ 3607 }, -- Serpentshrine Cavern
	{ 3791 }, -- Sethekk Halls
	{ 3789 }, -- Shadow Labyrinth
	{ 209 }, -- Shadowfang Keep
	{ 2017 }, -- Stratholme
	{ 1417 }, -- Sunken Temple
	{ 4075 }, -- Sunwell Plateau
	{ 3845 }, -- Tempest Keep
	{ 3848 }, -- The Arcatraz
	{ 2366 }, -- The Black Morass
	{ 3713 }, -- The Blood Furnace
	{ 3847 }, -- The Botanica
	{ 1581 }, -- The Deadmines
	{ 3849 }, -- The Mechanar
	{ 3714 }, -- The Shattered Halls
	{ 3717 }, -- The Slave Pens
	{ 3715 }, -- The Steamvault
	{ 717 }, -- The Stockade
	{ 1477 }, -- The Temple of Atal'Hakkar
	{ 3716 }, -- The Underbog
	{ 1337 }, -- Uldaman
	{ 718 }, -- Wailing Caverns
	{ 3805 }, -- Zul'Aman
	{ 1176 }, -- Zul'Farrak
	{ 1977 }, -- Zul'Gurub
}

--[[
How We Got the Data

Last Validated
	2026-10-29, TBC Anniversary 2.5.6.70577

Notes
	- Levelling zones, and who is in them: input to the /who queries in
	  Features/Recipients-Who.lua. A bare /who 21-22 is capped at 50 on a connected cluster and
	  mostly returns people standing in a capital; adding the zone returns people actually out
	  there levelling, and few enough that the cap stops mattering.
	- Each row is an AreaTable ID. Features/Recipients-Zones.lua asks C_Map.GetAreaInfo for
	  its name in the client's own language, since /who matches the area name, which in some
	  locales is not the map's name. A wrong ID queries the wrong zone and says nothing about
	  it, which is why Validate Data checks every name.
	- min and max level came from the author's own zone list.
	- ZONE_COLUMNS names each field's position in a row. Features/Recipients-Zones.lua, the
	  only reader, reads every row through it, and ns.Data.ZonesFor there orders and filters
	  the rows into a search plan for a level band.
	- Faction is derived, not sourced, so it is the column to check. It exists because /who is
	  same-faction: a Horde player querying Elwynn Forest gets nothing back. Both (no faction)
	  is the safe default, since marking a zone for one faction when the other levels there
	  too throws a good zone away permanently, where the reverse costs one empty query. Only
	  starting zones and single-hub zones are locked.
	- The wago.tools check confirmed every ID and name. AreaTable carries no level range, so
	  no zone can be added from it; a new zone needs its levels from the author's list.
	- 4080 Isle of Quel'Danas is left out: it is a level 70 zone, so nobody is levelling there.
	- INSTANCE_AREAS lists every dungeon and raid a /who answer can name as a player's zone, by
	  AreaTable ID. Features/Recipients-Zones.lua names each through C_Map.GetAreaInfo, the
	  same record /who reports a zone by, and places a player standing in one as INSTANCE
	  rather than ELSEWHERE.
	- INSTANCE_AREAS was checked at 2.5.6.70577 against every top-level area on a dungeon or
	  raid map. Added from that check, awaiting the next Validate Data run: 3606 Hyjal Summit,
	  3605 Hyjal Past, 2367 Old Hillsbrad Foothills and 1477 The Temple of Atal'Hakkar, which
	  sit on the instance maps beside the 616 Hyjal, 267 Hillsbrad Foothills and 1417 Sunken
	  Temple rows. Left out: unused and test areas (206, 208, 3477, 4076, 3817), 207 The Great
	  Sea, named for open water, and the unused Emerald Dream map.
	- 267 Hillsbrad Foothills is a ZONES row as well, and Features/Recipients-Zones.lua looks
	  a zone up in ZONES first, so its INSTANCE_AREAS row never decides anything.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/AreaTable?build=2.5.6.70577
	https://wago.tools/db2/Map?build=2.5.6.70577

QuestieDB
	None.
]]
