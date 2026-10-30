local _, ns = ...

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
	{ 495, 68, 72, BOTH }, -- Howling Fjord
	{ 3537, 70, 72, BOTH }, -- Borean Tundra
	{ 65, 71, 80, BOTH }, -- Dragonblight
	{ 394, 73, 75, BOTH }, -- Grizzly Hills
	{ 66, 73, 77, BOTH }, -- Zul'Drak
	{ 3711, 75, 80, BOTH }, -- Sholazar Basin
	{ 210, 77, 80, BOTH }, -- Icecrown
	{ 67, 77, 80, BOTH }, -- The Storm Peaks
}

-- Exported: Features/Recipients-Who.lua reads rows through these same columns.
ns.Data.ZONE_COLUMNS = { AREA_ID = 1, MIN = 2, MAX = 3, FACTION = 4 }

-- { areaID }
ns.Data.INSTANCE_AREAS = {
	{ 14663 }, -- Aberrus, the Shadowed Crucible
	{ 3428 }, -- Ahn'Qiraj
	{ 5288 }, -- Ahn'Qiraj Terrace
	{ 4494 }, -- Ahn'kahet: The Old Kingdom
	{ 14032 }, -- Algeth'ar Academy
	{ 16865 }, -- Altar of Fangs
	{ 14643 }, -- Amirdrassil, the Dream's Hope
	{ 8638 }, -- Antorus, the Burning Throne
	{ 15093 }, -- Ara-Kara, City of Echoes
	{ 9028 }, -- Atal'Dazar
	{ 3790 }, -- Auchenai Crypts
	{ 6912 }, -- Auchindoun
	{ 4277 }, -- Azjol-Nerub
	{ 5600 }, -- Baradin Hold
	{ 10076 }, -- Battle of Dazar'alor
	{ 7805 }, -- Black Rook Hold
	{ 8583 }, -- Black Rook Hold
	{ 3959 }, -- Black Temple
	{ 719 }, -- Blackfathom Deeps
	{ 4926 }, -- Blackrock Caverns
	{ 1584 }, -- Blackrock Depths
	{ 15913 }, -- Blackrock Depths
	{ 6967 }, -- Blackrock Foundry
	{ 1583 }, -- Blackrock Spire
	{ 5094 }, -- Blackwing Descent
	{ 2677 }, -- Blackwing Lair
	{ 6874 }, -- Bloodmaul Slag Mines
	{ 13991 }, -- Brackenhide Hollow
	{ 13224 }, -- Castle Nathria
	{ 8527 }, -- Cathedral of Eternal Night
	{ 10582 }, -- Caverns of Time
	{ 15103 }, -- Cinderbrew Meadery
	{ 14979 }, -- City of Threads
	{ 8079 }, -- Court of Stars
	{ 10057 }, -- Crucible of Storms
	{ 14882 }, -- Darkflame Cleft
	{ 7673 }, -- Darkheart Thicket
	{ 10581 }, -- Darkmaul Citadel
	{ 14514 }, -- Dawn of the Infinite
	{ 13309 }, -- De Other Side
	{ 16368 }, -- Den of Nalorakk
	{ 2557 }, -- Dire Maul
	{ 5892 }, -- Dragon Soul
	{ 4196 }, -- Drak'Tharon Keep
	{ 17107 }, -- Dummy Dome
	{ 16104 }, -- Eco-Dome Al'dani
	{ 5789 }, -- End Time
	{ 8040 }, -- Eye of Azshara
	{ 5723 }, -- Firelands
	{ 9164 }, -- Freehold
	{ 5976 }, -- Gate of the Setting Sun
	{ 721 }, -- Gnomeregan
	{ 4950 }, -- Grim Batol
	{ 6984 }, -- Grimrail Depot
	{ 3923 }, -- Gruul's Lair
	{ 4416 }, -- Gundrak
	{ 12831 }, -- Halls of Atonement
	{ 14082 }, -- Halls of Infusion
	{ 4272 }, -- Halls of Lightning
	{ 4945 }, -- Halls of Origination
	{ 4820 }, -- Halls of Reflection
	{ 4264 }, -- Halls of Stone
	{ 7672 }, -- Halls of Valor
	{ 6297 }, -- Heart of Fear
	{ 7545 }, -- Hellfire Citadel
	{ 3562 }, -- Hellfire Ramparts
	{ 7812 }, -- Helmouth Cliffs
	{ 6996 }, -- Highmaul
	{ 267 }, -- Hillsbrad Foothills
	{ 5844 }, -- Hour of Twilight
	{ 4812 }, -- Icecrown Citadel
	{ 6951 }, -- Iron Docks
	{ 16342 }, -- Isle of Quel'Danas
	{ 3457 }, -- Karazhan
	{ 8443 }, -- Karazhan
	{ 9526 }, -- Kings' Rest
	{ 15522 }, -- Liberation of Undermine
	{ 5396 }, -- Lost City of the Tol'vir
	{ 5880 }, -- Maelstrom Deathwing Fight
	{ 4131 }, -- Magisters' Terrace
	{ 15829 }, -- Magisters' Terrace
	{ 3836 }, -- Magtheridon's Lair
	{ 16395 }, -- Maisara Caverns
	{ 3792 }, -- Mana-Tombs
	{ 16178 }, -- Manaforge Omega
	{ 2100 }, -- Maraudon
	{ 13334 }, -- Mists of Tirna Scithe
	{ 6182 }, -- Mogu'shan Palace
	{ 11384 }, -- Mogu'shan Palace
	{ 6125 }, -- Mogu'shan Vaults
	{ 11395 }, -- Mogu'shan Vaults
	{ 2717 }, -- Molten Core
	{ 616 }, -- Mount Hyjal
	{ 16091 }, -- Murder Row
	{ 3456 }, -- Naxxramas
	{ 7546 }, -- Neltharion's Lair
	{ 14011 }, -- Neltharus
	{ 14980 }, -- Nerub-ar Palace
	{ 16573 }, -- Nexus-Point Xenas
	{ 10522 }, -- Ny'alotha, the Waking City
	{ 13982 }, -- Ohn'ahran Plains
	{ 2159 }, -- Onyxia's Lair
	{ 15452 }, -- Operation: Floodgate
	{ 10225 }, -- Operation: Mechagon
	{ 4813 }, -- Pit of Saron
	{ 13228 }, -- Plaguefall
	{ 14954 }, -- Priory of the Sacred Flame
	{ 2437 }, -- Ragefire Chasm
	{ 722 }, -- Razorfen Downs
	{ 491 }, -- Razorfen Kraul
	{ 7053 }, -- Remains of Xandros
	{ 14063 }, -- Ruby Life Pools
	{ 3429 }, -- Ruins of Ahn'Qiraj
	{ 13561 }, -- Sanctum of Domination
	{ 12842 }, -- Sanguine Depths
	{ 6052 }, -- Scarlet Halls
	{ 796 }, -- Scarlet Monastery
	{ 6109 }, -- Scarlet Monastery
	{ 14872 }, -- Scarlet Monastery
	{ 2057 }, -- Scholomance
	{ 6066 }, -- Scholomance
	{ 13742 }, -- Sepulcher of the First Ones
	{ 3607 }, -- Serpentshrine Cavern
	{ 3791 }, -- Sethekk Halls
	{ 5918 }, -- Shado-Pan Monastery
	{ 3789 }, -- Shadow Labyrinth
	{ 209 }, -- Shadowfang Keep
	{ 6932 }, -- Shadowmoon Burial Grounds
	{ 9525 }, -- Shrine of the Storm
	{ 9354 }, -- Siege of Boralus
	{ 6214 }, -- Siege of Niuzao Temple
	{ 6738 }, -- Siege of Orgrimmar
	{ 10047 }, -- Siege of Orgrimmar
	{ 6988 }, -- Skyreach
	{ 12837 }, -- Spires of Ascension
	{ 16279 }, -- Sporefall
	{ 5963 }, -- Stormstout Brewery
	{ 2017 }, -- Stratholme
	{ 1417 }, -- Sunken Temple
	{ 4075 }, -- Sunwell Plateau
	{ 8124 }, -- Sword of Dawn
	{ 9826 }, -- Sword of Dawn
	{ 13577 }, -- Tazavesh, the Veiled Market
	{ 3845 }, -- Tempest Keep
	{ 8422 }, -- Tempest's Roar
	{ 9830 }, -- Tempest's Roar
	{ 9527 }, -- Temple of Sethraliss
	{ 5956 }, -- Temple of the Jade Serpent
	{ 11397 }, -- Temple of the Jade Serpent
	{ 6067 }, -- Terrace of Endless Spring
	{ 8005 }, -- Terrace of Endless Spring
	{ 3848 }, -- The Arcatraz
	{ 7855 }, -- The Arcway
	{ 13954 }, -- The Azure Vault
	{ 5334 }, -- The Bastion of Twilight
	{ 2366 }, -- The Black Morass
	{ 16359 }, -- The Blinding Vale
	{ 3713 }, -- The Blood Furnace
	{ 3847 }, -- The Botanica
	{ 4100 }, -- The Culling of Stratholme
	{ 14971 }, -- The Dawnbreaker
	{ 1581 }, -- The Deadmines
	{ 16531 }, -- The Dreamrift
	{ 8026 }, -- The Emerald Nightmare
	{ 10425 }, -- The Eternal Palace
	{ 7109 }, -- The Everbloom
	{ 4500 }, -- The Eye of Eternity
	{ 4809 }, -- The Forge of Souls
	{ 8064 }, -- The MOTHERLODE!!
	{ 3849 }, -- The Mechanar
	{ 12916 }, -- The Necrotic Wake
	{ 4265 }, -- The Nexus
	{ 5786 }, -- The Nexus
	{ 8025 }, -- The Nighthold
	{ 4493 }, -- The Obsidian Sanctum
	{ 4228 }, -- The Oculus
	{ 14938 }, -- The Rookery
	{ 4987 }, -- The Ruby Sanctum
	{ 8910 }, -- The Seat of the Triumvirate
	{ 3714 }, -- The Shattered Halls
	{ 3717 }, -- The Slave Pens
	{ 3715 }, -- The Steamvault
	{ 717 }, -- The Stockade
	{ 5088 }, -- The Stonecore
	{ 14883 }, -- The Stonevault
	{ 16671 }, -- The Tidebound Grotto
	{ 17059 }, -- The Unbinding of Kith'ix
	{ 3716 }, -- The Underbog
	{ 9391 }, -- The Underrot
	{ 16915 }, -- The Venomous Abyss
	{ 4415 }, -- The Violet Hold
	{ 16340 }, -- The Voidspire
	{ 5035 }, -- The Vortex Pinnacle
	{ 12841 }, -- Theater of Pain
	{ 6622 }, -- Throne of Thunder
	{ 5638 }, -- Throne of the Four Winds
	{ 5004 }, -- Throne of the Tides
	{ 9327 }, -- Tol Dagor
	{ 10043 }, -- Tol Dagor
	{ 8524 }, -- Tomb of Sargeras
	{ 8440 }, -- Trial of Valor
	{ 4723 }, -- Trial of the Champion
	{ 4722 }, -- Trial of the Crusader
	{ 1337 }, -- Uldaman
	{ 13968 }, -- Uldaman
	{ 9389 }, -- Uldir
	{ 4273 }, -- Ulduar
	{ 7307 }, -- Upper Blackrock Spire
	{ 206 }, -- Utgarde Keep
	{ 1196 }, -- Utgarde Pinnacle
	{ 4603 }, -- Vault of Archavon
	{ 14030 }, -- Vault of the Incarnates
	{ 16551 }, -- Vault of the Incarnates (V2)
	{ 7787 }, -- Vault of the Wardens
	{ 7996 }, -- Violet Hold
	{ 16425 }, -- Voidscar Arena
	{ 718 }, -- Wailing Caverns
	{ 9424 }, -- Waycrest Manor
	{ 5788 }, -- Well of Eternity
	{ 15808 }, -- Windrunner Spire
	{ 3805 }, -- Zul'Aman
	{ 1176 }, -- Zul'Farrak
	{ 1977 }, -- Zul'Gurub
}

-- Ordered and filtered into a search plan by ns.Data.ZonesFor, in Features/Recipients-Who.lua.
