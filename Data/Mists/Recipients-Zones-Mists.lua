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
	{ 17, 10, 33, H }, -- Northern Barrens
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
	{ 33, 30, 50, BOTH }, -- Northern Stranglethorn
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
	{ 495, 68, 72, BOTH }, -- Howling Fjord
	{ 3537, 70, 72, BOTH }, -- Borean Tundra
	{ 65, 71, 80, BOTH }, -- Dragonblight
	{ 394, 73, 75, BOTH }, -- Grizzly Hills
	{ 66, 73, 77, BOTH }, -- Zul'Drak
	{ 3711, 75, 80, BOTH }, -- Sholazar Basin
	{ 210, 77, 80, BOTH }, -- Icecrown
	{ 67, 77, 80, BOTH }, -- The Storm Peaks
}

-- [field] = its position in a ZONES row
ns.Data.ZONE_COLUMNS = { AREA_ID = 1, MIN = 2, MAX = 3, FACTION = 4 }

-- { areaID }
ns.Data.INSTANCE_AREAS = {
	{ 4738 }, -- Abyssal Maw
	{ 3428 }, -- Ahn'Qiraj
	{ 5288 }, -- Ahn'Qiraj Terrace
	{ 4494 }, -- Ahn'kahet: The Old Kingdom
	{ 3790 }, -- Auchenai Crypts
	{ 4277 }, -- Azjol-Nerub
	{ 5600 }, -- Baradin Hold
	{ 3959 }, -- Black Temple
	{ 719 }, -- Blackfathom Deeps
	{ 4926 }, -- Blackrock Caverns
	{ 1584 }, -- Blackrock Depths
	{ 1583 }, -- Blackrock Spire
	{ 5094 }, -- Blackwing Descent
	{ 2677 }, -- Blackwing Lair
	{ 2557 }, -- Dire Maul
	{ 5892 }, -- Dragon Soul
	{ 4196 }, -- Drak'Tharon Keep
	{ 5789 }, -- End Time
	{ 5723 }, -- Firelands
	{ 5976 }, -- Gate of the Setting Sun
	{ 721 }, -- Gnomeregan
	{ 4950 }, -- Grim Batol
	{ 3923 }, -- Gruul's Lair
	{ 4416 }, -- Gundrak
	{ 4272 }, -- Halls of Lightning
	{ 4945 }, -- Halls of Origination
	{ 4820 }, -- Halls of Reflection
	{ 4264 }, -- Halls of Stone
	{ 6297 }, -- Heart of Fear
	{ 3562 }, -- Hellfire Ramparts
	{ 267 }, -- Hillsbrad Foothills
	{ 5844 }, -- Hour of Twilight
	{ 3605 }, -- Hyjal Past
	{ 3606 }, -- Hyjal Summit
	{ 4812 }, -- Icecrown Citadel
	{ 3457 }, -- Karazhan
	{ 5396 }, -- Lost City of the Tol'vir
	{ 5880 }, -- Maelstrom Deathwing Fight
	{ 4131 }, -- Magisters' Terrace
	{ 3836 }, -- Magtheridon's Lair
	{ 3792 }, -- Mana-Tombs
	{ 2100 }, -- Maraudon
	{ 6182 }, -- Mogu'shan Palace
	{ 6125 }, -- Mogu'shan Vaults
	{ 2717 }, -- Molten Core
	{ 616 }, -- Mount Hyjal
	{ 3456 }, -- Naxxramas
	{ 2367 }, -- Old Hillsbrad Foothills
	{ 2159 }, -- Onyxia's Lair
	{ 4813 }, -- Pit of Saron
	{ 4894 }, -- Putricide's Laboratory of Alchemical Horrors and Fun
	{ 2437 }, -- Ragefire Chasm
	{ 722 }, -- Razorfen Downs
	{ 491 }, -- Razorfen Kraul
	{ 3429 }, -- Ruins of Ahn'Qiraj
	{ 6052 }, -- Scarlet Halls
	{ 796 }, -- Scarlet Monastery
	{ 6109 }, -- Scarlet Monastery
	{ 6066 }, -- Scholomance
	{ 2057 }, -- ScholomanceOLD
	{ 5130 }, -- Seat of Life
	{ 3607 }, -- Serpentshrine Cavern
	{ 3791 }, -- Sethekk Halls
	{ 5918 }, -- Shado-Pan Monastery
	{ 3789 }, -- Shadow Labyrinth
	{ 209 }, -- Shadowfang Keep
	{ 6214 }, -- Siege of Niuzao Temple
	{ 6738 }, -- Siege of Orgrimmar
	{ 5963 }, -- Stormstout Brewery
	{ 2017 }, -- Stratholme
	{ 1417 }, -- Sunken Temple
	{ 4075 }, -- Sunwell Plateau
	{ 3845 }, -- Tempest Keep
	{ 5956 }, -- Temple of the Jade Serpent
	{ 6067 }, -- Terrace of Endless Spring
	{ 3848 }, -- The Arcatraz
	{ 5334 }, -- The Bastion of Twilight
	{ 2366 }, -- The Black Morass
	{ 3713 }, -- The Blood Furnace
	{ 3847 }, -- The Botanica
	{ 4895 }, -- The Crimson Hall
	{ 4100 }, -- The Culling of Stratholme
	{ 1581 }, -- The Deadmines
	{ 4500 }, -- The Eye of Eternity
	{ 4809 }, -- The Forge of Souls
	{ 4893 }, -- The Frost Queen's Lair
	{ 4896 }, -- The Frozen Throne
	{ 3849 }, -- The Mechanar
	{ 4265 }, -- The Nexus
	{ 5786 }, -- The Nexus
	{ 4493 }, -- The Obsidian Sanctum
	{ 4228 }, -- The Oculus
	{ 4987 }, -- The Ruby Sanctum
	{ 4897 }, -- The Sanctum of Blood
	{ 3714 }, -- The Shattered Halls
	{ 3717 }, -- The Slave Pens
	{ 3715 }, -- The Steamvault
	{ 717 }, -- The Stockade
	{ 5088 }, -- The Stonecore
	{ 3716 }, -- The Underbog
	{ 4415 }, -- The Violet Hold
	{ 5035 }, -- The Vortex Pinnacle
	{ 6622 }, -- Throne of Thunder
	{ 5638 }, -- Throne of the Four Winds
	{ 5004 }, -- Throne of the Tides
	{ 4723 }, -- Trial of the Champion
	{ 4722 }, -- Trial of the Crusader
	{ 1337 }, -- Uldaman
	{ 4273 }, -- Ulduar
	{ 206 }, -- Utgarde Keep
	{ 1196 }, -- Utgarde Pinnacle
	{ 4603 }, -- Vault of Archavon
	{ 718 }, -- Wailing Caverns
	{ 5788 }, -- Well of Eternity
	{ 3805 }, -- Zul'Aman
	{ 1176 }, -- Zul'Farrak
	{ 1977 }, -- Zul'Gurub
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- Levelling zones, and who is in them: input to the /who queries in
	  Features/Recipients-Who.lua. A bare /who 21-22 is capped at 50 on a connected cluster and
	  mostly returns people standing in a capital; adding the zone (z-"Redridge Mountains")
	  returns people actually out there levelling, and few enough that the cap stops mattering.
	- Each row is an AreaTable ID. Features/Recipients-Zones.lua asks C_Map.GetAreaInfo for its
	  name in the client's own language, since /who matches the area name, which in some
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
	- INSTANCE_AREAS lists every dungeon and raid a /who answer can name as a player's zone, by
	  AreaTable ID. Features/Recipients-Zones.lua names each through C_Map.GetAreaInfo, the
	  same record /who reports a zone by, and places a player standing in one as INSTANCE
	  rather than ELSEWHERE. This client's last Validate Data run predates the table in its
	  manifest, so its names are unchecked here.
	- INSTANCE_AREAS was checked at 5.5.4.70631 against every top-level area on a dungeon or
	  raid map. Added from that check, awaiting the next Validate Data run: 5130 Seat of Life,
	  the five Icecrown Citadel wing areas (4893 to 4897), 3606 Hyjal Summit, 3605 Hyjal Past,
	  2367 Old Hillsbrad Foothills and 4738 Abyssal Maw. Left out: areas marked unused,
	  temporary or old (5783, 5806, 6123, 6746, 4076, 208), 207 The Great Sea, named for open
	  water, and the unused Emerald Dream map.

SQL (CMaNGOS)
	TODO: Add SQL Query

Wowhead
	None.

wago.tools
	https://wago.tools/db2/AreaTable?build=5.5.4.70631
	https://wago.tools/db2/Map?build=5.5.4.70631

QuestieDB
	None.
]]
