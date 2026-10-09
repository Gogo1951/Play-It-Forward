local _, ns = ...

-- { id, quality, useLevel, restores }
ns.Data.FOOD_AND_WATER = {
	{ 27636, 1, 5, "HEALTH" }, -- Bat Bites
	{ 3220, 1, 5, "HEALTH" }, -- Blood Sausage
	{ 5525, 1, 5, "HEALTH" }, -- Boiled Clams
	{ 2682, 1, 5, "BOTH" }, -- Cooked Crab Claw
	{ 2684, 1, 5, "HEALTH" }, -- Coyote Steak
	{ 2683, 1, 5, "HEALTH" }, -- Crab Cake
	{ 3662, 1, 5, "HEALTH" }, -- Crocolisk Steak
	{ 22645, 1, 5, "HEALTH" }, -- Crunchy Spider Surprise
	{ 414, 1, 5, "HEALTH" }, -- Dalaran Sharp
	{ 17119, 1, 5, "HEALTH" }, -- Deeprun Rat Kabob
	{ 2687, 1, 5, "HEALTH" }, -- Dry Pork Ribs
	{ 5476, 1, 5, "HEALTH" }, -- Fillet of Frenzy
	{ 5066, 1, 5, "HEALTH" }, -- Fissure Plant
	{ 4541, 1, 5, "HEALTH" }, -- Freshly Baked Bread
	{ 724, 1, 5, "HEALTH" }, -- Goretusk Liver Pie
	{ 2287, 1, 5, "HEALTH" }, -- Haunch of Meat
	{ 17406, 1, 5, "HEALTH" }, -- Holiday Cheesewheel
	{ 6316, 1, 5, "HEALTH" }, -- Loch Frenzy Delight
	{ 4592, 1, 5, "HEALTH" }, -- Longjaw Mud Snapper
	{ 5095, 1, 5, "HEALTH" }, -- Rainbow Fin Albacore
	{ 4605, 1, 5, "HEALTH" }, -- Red-speckled Mushroom
	{ 24072, 1, 5, "HEALTH" }, -- Sand Pear Pie
	{ 6890, 1, 5, "HEALTH" }, -- Smoked Bear Meat
	{ 19304, 1, 5, "HEALTH" }, -- Spiced Beef Jerky
	{ 5477, 1, 5, "HEALTH" }, -- Strider Stew
	{ 18633, 1, 5, "HEALTH" }, -- Styleen's Sour Suckerpop
	{ 4537, 1, 5, "HEALTH" }, -- Tel'Abim Banana
	{ 16167, 1, 5, "HEALTH" }, -- Versicolor Treat
	{ 733, 1, 5, "HEALTH" }, -- Westfall Stew
	{ 12238, 1, 5, "HEALTH" }, -- Darkshore Grouper
	{ 5526, 1, 10, "HEALTH" }, -- Clam Chowder
	{ 5478, 1, 10, "HEALTH" }, -- Dig Rat Stew
	{ 1082, 1, 10, "HEALTH" }, -- Redridge Goulash
	{ 21072, 1, 10, "BOTH" }, -- Smoked Sagefish
	{ 2685, 1, 10, "HEALTH" }, -- Succulent Pork Ribs
	{ 5479, 1, 12, "HEALTH" }, -- Crispy Lizard Tail
	{ 3726, 1, 15, "HEALTH" }, -- Big Bear Steak
	{ 4593, 1, 15, "HEALTH" }, -- Bristle Whisker Catfish
	{ 3664, 1, 15, "HEALTH" }, -- Crocolisk Gumbo
	{ 3665, 1, 15, "HEALTH" }, -- Curiously Tasty Omelet
	{ 422, 1, 15, "HEALTH" }, -- Dwarven Mild
	{ 5527, 1, 15, "HEALTH" }, -- Goblin Deviled Clams
	{ 3666, 1, 15, "HEALTH" }, -- Gooey Spider Cake
	{ 3727, 1, 15, "HEALTH" }, -- Hot Lion Chops
	{ 5480, 1, 15, "HEALTH" }, -- Lean Venison
	{ 12209, 1, 15, "HEALTH" }, -- Lean Wolf Steak
	{ 4542, 1, 15, "HEALTH" }, -- Moist Cornbread
	{ 3663, 1, 15, "HEALTH" }, -- Murloc Fin Soup
	{ 3770, 1, 15, "HEALTH" }, -- Mutton Chop
	{ 19305, 1, 15, "HEALTH" }, -- Pickled Kodo Foot
	{ 1017, 1, 15, "HEALTH" }, -- Seasoned Wolf Kabob
	{ 4538, 1, 15, "HEALTH" }, -- Snapvine Watermelon
	{ 4606, 1, 15, "HEALTH" }, -- Spongy Morel
	{ 16170, 1, 15, "HEALTH" }, -- Steamed Mandu
	{ 7228, 1, 15, "HEALTH" }, -- Tigule's Strawberry Ice Cream
	{ 20074, 1, 20, "HEALTH" }, -- Heavy Crocolisk Stew
	{ 3728, 1, 20, "HEALTH" }, -- Tasty Lion Steak
	{ 4457, 1, 25, "HEALTH" }, -- Barbecued Buzzard Wing
	{ 13546, 1, 25, "HEALTH" }, -- Bloodbelly Fish
	{ 12213, 1, 25, "HEALTH" }, -- Carrion Surprise
	{ 4607, 1, 25, "HEALTH" }, -- Delicious Cave Mold
	{ 6038, 1, 25, "HEALTH" }, -- Giant Clam Scorcho
	{ 4539, 1, 25, "HEALTH" }, -- Goldenbark Apple
	{ 17407, 1, 25, "HEALTH" }, -- Graccu's Homemade Meat Pie
	{ 13851, 1, 25, "HEALTH" }, -- Hot Wolf Ribs
	{ 12212, 1, 25, "HEALTH" }, -- Jungle Stew
	{ 8364, 1, 25, "HEALTH" }, -- Mithril Head Trout
	{ 18632, 1, 25, "HEALTH" }, -- Moonbrook Riot Taffy
	{ 4544, 1, 25, "HEALTH" }, -- Mulgore Spice Bread
	{ 12214, 1, 25, "HEALTH" }, -- Mystery Stew
	{ 19224, 1, 25, "HEALTH" }, -- Red Hot Wings
	{ 12210, 1, 25, "HEALTH" }, -- Roast Raptor
	{ 4594, 1, 25, "HEALTH" }, -- Rockscale Cod
	{ 3729, 1, 25, "HEALTH" }, -- Soothing Turtle Bisque
	{ 12211, 1, 25, "HEALTH" }, -- Spiced Wolf Ribs
	{ 1707, 1, 25, "HEALTH" }, -- Stormwind Brie
	{ 8543, 1, 25, "HEALTH" }, -- Underwater Mushroom Cap
	{ 3771, 1, 25, "HEALTH" }, -- Wild Hog Shank
	{ 16169, 1, 25, "HEALTH" }, -- Wild Ricecake
	{ 21217, 1, 30, "BOTH" }, -- Sagefish Delight
	{ 18635, 1, 35, "HEALTH" }, -- Bellara's Nutterbar
	{ 13927, 1, 35, "HEALTH" }, -- Cooked Glossy Mightfish
	{ 19306, 1, 35, "HEALTH" }, -- Crunchy Frog
	{ 4599, 1, 35, "HEALTH" }, -- Cured Ham Steak
	{ 21030, 1, 35, "HEALTH" }, -- Darnassus Kimchi Pie
	{ 12217, 1, 35, "HEALTH" }, -- Dragonbreath Chili
	{ 13930, 1, 35, "HEALTH" }, -- Filet of Redgill
	{ 3927, 1, 35, "HEALTH" }, -- Fine Aged Cheddar
	{ 9681, 1, 35, "HEALTH" }, -- Grilled King Crawler Legs
	{ 13928, 1, 35, "HEALTH" }, -- Grilled Squid
	{ 16168, 1, 35, "HEALTH" }, -- Heaven Peach
	{ 12215, 1, 35, "HEALTH" }, -- Heavy Kodo Stew
	{ 13929, 1, 35, "HEALTH" }, -- Hot Smoked Bass
	{ 4602, 1, 35, "HEALTH" }, -- Moon Harvest Pumpkin
	{ 13931, 1, 35, "HEALTH" }, -- Nightfin Soup
	{ 13932, 1, 35, "HEALTH" }, -- Poached Sunscale Salmon
	{ 4608, 1, 35, "HEALTH" }, -- Raw Black Truffle
	{ 4601, 1, 35, "HEALTH" }, -- Soft Banana Bread
	{ 17408, 1, 35, "HEALTH" }, -- Spicy Beefstick
	{ 17222, 1, 35, "HEALTH" }, -- Spider Sausage
	{ 6887, 1, 35, "HEALTH" }, -- Spotted Yellowtail
	{ 21552, 1, 35, "HEALTH" }, -- Striped Yellowtail
	{ 16766, 1, 35, "HEALTH" }, -- Undermine Clam Chowder
	{ 13755, 1, 35, "HEALTH" }, -- Winter Squid
	{ 16971, 1, 40, "HEALTH" }, -- Clamlette Surprise
	{ 12218, 1, 40, "HEALTH" }, -- Monster Omelet
	{ 12216, 1, 40, "HEALTH" }, -- Spiced Chili Crab
	{ 18045, 1, 40, "HEALTH" }, -- Tender Wolf Steak
	{ 33004, 1, 40, "HEALTH" }, -- Clamlette Surprise
	{ 8932, 1, 45, "HEALTH" }, -- Alterac Swiss
	{ 13935, 1, 45, "HEALTH" }, -- Baked Salmon
	{ 21031, 1, 45, "HEALTH" }, -- Cabbage Kimchi
	{ 35563, 1, 45, "HEALTH" }, -- Charred Bear Kabobs
	{ 19225, 1, 45, "HEALTH" }, -- Deep Fried Candybar
	{ 8953, 1, 45, "HEALTH" }, -- Deep Fried Plantains
	{ 8948, 1, 45, "HEALTH" }, -- Dried King Bolete
	{ 13724, 1, 45, "BOTH" }, -- Enriched Manna Biscuit
	{ 11444, 1, 45, "HEALTH" }, -- Grim Guzzler Boar
	{ 8950, 1, 45, "HEALTH" }, -- Homemade Cherry Pie
	{ 35565, 1, 45, "HEALTH" }, -- Juicy Bear Burger
	{ 13893, 1, 45, "HEALTH" }, -- Large Raw Mightfish
	{ 13933, 1, 45, "HEALTH" }, -- Lobster Stew
	{ 13934, 1, 45, "HEALTH" }, -- Mightfish Steak
	{ 11415, 1, 45, "HEALTH" }, -- Mixed Berries
	{ 21033, 1, 45, "HEALTH" }, -- Radish Kimchi
	{ 8952, 1, 45, "HEALTH" }, -- Roasted Quail
	{ 18255, 1, 45, "HEALTH" }, -- Runn Tum Tuber
	{ 18254, 1, 45, "HEALTH" }, -- Runn Tum Tuber Surprise
	{ 16171, 1, 45, "HEALTH" }, -- Shinsollo
	{ 20452, 1, 45, "HEALTH" }, -- Smoked Desert Dumplings
	{ 8957, 1, 45, "HEALTH" }, -- Spinefin Halibut
	{ 12763, 1, 45, "HEALTH" }, -- Un'Goro Etherfruit
	{ 22324, 1, 45, "HEALTH" }, -- Winter Kimchi
	{ 27657, 1, 55, "HEALTH" }, -- Blackened Basilisk
	{ 27663, 1, 55, "HEALTH" }, -- Blackened Sporefish
	{ 27661, 1, 55, "HEALTH" }, -- Blackened Trout
	{ 29293, 1, 55, "HEALTH" }, -- Bonestripper Buzzard Hotwings
	{ 33867, 1, 55, "HEALTH" }, -- Broiled Bloodfin
	{ 27651, 1, 55, "HEALTH" }, -- Buzzard Bites
	{ 30155, 1, 55, "HEALTH" }, -- Clam Bar
	{ 31673, 1, 55, "HEALTH" }, -- Crunchy Serpent
	{ 29393, 1, 55, "HEALTH" }, -- Diamond Berries
	{ 21023, 1, 55, "HEALTH" }, -- Dirge's Kickin' Chimaerok Chops
	{ 27662, 1, 55, "HEALTH" }, -- Feltail Delight
	{ 27857, 1, 55, "HEALTH" }, -- Garadar Sharp
	{ 27666, 1, 55, "HEALTH" }, -- Golden Fish Sticks
	{ 27664, 1, 55, "HEALTH" }, -- Grilled Mudfish
	{ 29292, 1, 55, "HEALTH" }, -- Helboar Bacon
	{ 24338, 1, 55, "HEALTH" }, -- Hellfire Spineleaf
	{ 29412, 1, 55, "HEALTH" }, -- Jessen's Special Slop
	{ 33874, 1, 55, "PET" }, -- Kibler's Bits
	{ 27855, 1, 55, "HEALTH" }, -- Mag'har Grainbread
	{ 24539, 1, 55, "HEALTH" }, -- Marsh Lichen
	{ 31672, 1, 55, "HEALTH" }, -- Mok'Nathal Shortribs
	{ 28486, 1, 55, "HEALTH" }, -- Moser's Magnificent Muffin
	{ 38427, 1, 55, "HEALTH" }, -- Pickled Egg
	{ 27665, 1, 55, "HEALTH" }, -- Poached Bluefish
	{ 27655, 1, 55, "HEALTH" }, -- Ravager Dog
	{ 28501, 1, 55, "HEALTH" }, -- Ravager Egg Omelet
	{ 27658, 1, 55, "HEALTH" }, -- Roasted Clefthoof
	{ 27856, 1, 55, "HEALTH" }, -- Skethyl Berries
	{ 30610, 1, 55, "HEALTH" }, -- Smoked Black Bear Meat
	{ 27854, 1, 55, "HEALTH" }, -- Smoked Talbuk Venison
	{ 27667, 1, 55, "HEALTH" }, -- Spicy Crawdad
	{ 27656, 1, 55, "PET" }, -- Sporeling Snack
	{ 33866, 1, 55, "HEALTH" }, -- Stormchops
	{ 30458, 1, 55, "HEALTH" }, -- Stromgarde Muenster
	{ 27858, 1, 55, "HEALTH" }, -- Sunspring Carp
	{ 27660, 1, 55, "HEALTH" }, -- Talbuk Steak
	{ 27659, 1, 55, "HEALTH" }, -- Warp Burger
	{ 27859, 1, 55, "HEALTH" }, -- Zangar Caps
	{ 29449, 1, 65, "HEALTH" }, -- Bladespire Bagel
	{ 29451, 1, 65, "HEALTH" }, -- Clefthoof Ribs
	{ 35710, 1, 65, "HEALTH" }, -- Delicious Baked Ham
	{ 32722, 1, 65, "BOTH" }, -- Enriched Terocone Juice
	{ 33052, 1, 65, "HEALTH" }, -- Fisherman's Feast
	{ 30355, 1, 65, "HEALTH" }, -- Grilled Shadowmoon Tuber
	{ 33053, 1, 65, "BOTH" }, -- Hot Buttered Trout
	{ 29394, 1, 65, "HEALTH" }, -- Lyribread
	{ 29448, 1, 65, "HEALTH" }, -- Mag'har Mild Cheese
	{ 32686, 1, 65, "HEALTH" }, -- Mingo's Fortune Giblets
	{ 32685, 1, 65, "HEALTH" }, -- Ogri'la Chicken Fingers
	{ 38428, 1, 65, "HEALTH" }, -- Rock-Salted Pretzel
	{ 33825, 1, 65, "MANA" }, -- Skullfish Soup
	{ 33872, 1, 65, "HEALTH" }, -- Spicy Hot Talbuk
	{ 29453, 1, 65, "HEALTH" }, -- Sporeggar Mushroom
	{ 33048, 1, 65, "HEALTH" }, -- Stewed Trout
	{ 29450, 1, 65, "HEALTH" }, -- Telaari Grapes
	{ 29452, 1, 65, "HEALTH" }, -- Zangar Trout
	{ 17404, 1, 5, "MANA" }, -- Blended Bean Brew
	{ 1179, 1, 5, "MANA" }, -- Ice Cold Milk
	{ 9451, 1, 15, "MANA" }, -- Bubbling Water
	{ 19299, 1, 15, "MANA" }, -- Fizzy Faire Drink
	{ 1205, 1, 15, "MANA" }, -- Melon Juice
	{ 4791, 1, 25, "MANA" }, -- Enchanted Water
	{ 10841, 1, 25, "MANA" }, -- Goldthorn Tea
	{ 1708, 1, 25, "MANA" }, -- Sweet Nectar
	{ 19300, 1, 35, "MANA" }, -- Bottled Winterspring Water
	{ 1645, 1, 35, "MANA" }, -- Moonberry Juice
	{ 38429, 1, 45, "MANA" }, -- Blackrock Spring Water
	{ 8766, 1, 45, "MANA" }, -- Morning Glory Dew
	{ 18300, 1, 55, "MANA" }, -- Hyjal Nectar
	{ 32455, 1, 55, "MANA" }, -- Star's Lament
	{ 38430, 1, 60, "MANA" }, -- Blackrock Mineral Water
	{ 28399, 1, 60, "MANA" }, -- Filtered Draenic Water
	{ 29454, 1, 60, "MANA" }, -- Silverwine
	{ 33042, 1, 65, "MANA" }, -- Black Coffee
	{ 38431, 1, 65, "MANA" }, -- Blackrock Fortified Water
	{ 32668, 1, 65, "MANA" }, -- Dos Ogris
	{ 29395, 1, 65, "MANA" }, -- Ethermead
	{ 30457, 1, 65, "MANA" }, -- Gilneas Sparkling Water
	{ 34411, 1, 65, "MANA" }, -- Hot Apple Cider
	{ 27860, 1, 65, "MANA" }, -- Purified Draenic Water
	{ 29401, 1, 65, "MANA" }, -- Sparkling Southshore Cider
	{ 32453, 1, 65, "MANA" }, -- Star's Tears
}

--[[
How We Got the Data

Last Validated
	2026-10-09, TBC Anniversary 2.5.6.69795

Notes
	- Food and drink a player can give away: Food & Drink consumables that restore health, mana
	  or both while the player sits, can be traded, aren't conjured, and need level 5 or more.
	- Level 5 is the floor because a consumable's recipients run from its use level up by
	  ns.Data.CONSUMABLE_RECIPIENT_GAP, and nobody under ns.Data.MIN_RECIPIENT_LEVEL (5)
	  receives anything (both in Data/Data.lua). Food needing less would reach nobody.
	- Alcohol and drinks that only buff are out; the query drops the drunk-making spells by ID.
	- useLevel is the level the item requires and quality its quality. restores is HEALTH, MANA
	  or BOTH, from what the item's use text says it restores, never from a well-fed buff after
	  it. It decides who can receive the food through ns.Data.CONSUMABLE_CLASSES in
	  Data/Data.lua, so there is no per-item class list. Features/Scan-Bags.lua reads every
	  field.
	- 12217 Dragonbreath Chili restores nothing: its use is a melee fire buff. It is filed as
	  HEALTH, which every class receives.
	- 27656 Sporeling Snack and 33874 Kibler's Bits feed a hunter's pet, so they are filed as
	  PET and reach only hunters. 33866 Stormchops is a lightning buff that restores nothing,
	  and is filed as HEALTH.
	- Every row is Food & Drink (class 0, subclass 5) on this client. The Brewfest and holiday
	  sausages, ales and brews in the wago.tools tables are filed as plain Consumable
	  (subclass 0), so they stay out, as does 29402 Jessen's Special Slop OLD, a retired copy.

SQL (CMaNGOS)
	Database not recorded. It returned Wrath items, so it ran against a Wrath-era database,
	and each client's Validate Data run prunes what that client lacks.

    SELECT CONCAT('\t{ ', entry, ', ', Quality, ', ', UseLevel, ', "', Restores, '" }, -- ', name) AS LuaRow
    FROM (
        SELECT
            it.entry,
            it.name,
            it.Quality,
            it.RequiredLevel AS UseLevel,
            CASE
                WHEN 11 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                 AND 59 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                    THEN 'BOTH'
                WHEN 11 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                    THEN 'HEALTH'
                WHEN 59 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                    THEN 'MANA'
                ELSE 'Other'
            END AS Restores
        FROM item_template it
        WHERE it.class    = 0        -- Consumable
          AND it.subclass = 5        -- Food & Drink
          AND it.bonding  = 0        -- non-soulbound
          AND it.RequiredLevel > 4   -- must clear ns.Data.MIN_RECIPIENT_LEVEL
          AND (it.Flags & 0x2) = 0   -- NOT conjured
          AND it.name NOT LIKE 'Conjured %'
          AND it.spelltrigger_1 IN (0,5)
          AND (it.spellid_2 = 0 OR it.spellid_2 IS NULL)
          AND it.name NOT LIKE '[PH]%'        -- placeholder
          AND it.name NOT LIKE 'Test %'       -- debug
          AND it.name NOT LIKE 'Deprecated %' -- retired
          AND it.name NOT LIKE 'DEPCREATED %' -- retired, misspelled upstream
          AND it.spellid_1 NOT IN (      -- weed out alcohol / inebriate spells
                11007, 11008, 11009,     -- core booze tiers
                11629,                   -- Nethergarde Bitter, Darkmoon Special Reserve
                5909,                    -- Watered-down Beer
                25037, 25722, 25804,     -- Rumsey Rum (Light/Dark/Black Label)
                50986,                   -- Sulfuron Slammer
                55296                    -- [PH] placeholder wine
              )
    ) c
    WHERE Restores <> 'Other'      -- keep only food / water / hybrid (restores HP or mana)
    ORDER BY FIELD(Restores, 'HEALTH', 'MANA', 'BOTH'), UseLevel, name;

Wowhead
	None.

wago.tools
	https://wago.tools/db2/Item?build=2.5.6.69795
	https://wago.tools/db2/ItemSparse?build=2.5.6.69795
	https://wago.tools/db2/ItemEffect?build=2.5.6.69795
	https://wago.tools/db2/Spell?build=2.5.6.69795
]]
