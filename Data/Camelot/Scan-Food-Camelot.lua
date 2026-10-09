local _, ns = ...

-- { id, quality, useLevel, restores }
ns.Data.FOOD_AND_WATER = {
	{ 3220, 1, 5, "HEALTH" }, -- Blood Sausage
	{ 5525, 1, 1, "HEALTH" }, -- Boiled Clams
	{ 2682, 1, 1, "HEALTH" }, -- Cooked Crab Claw
	{ 2684, 1, 5, "HEALTH" }, -- Coyote Steak
	{ 2683, 1, 5, "HEALTH" }, -- Crab Cake
	{ 3662, 1, 5, "HEALTH" }, -- Crocolisk Steak
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
	{ 6890, 1, 1, "HEALTH" }, -- Smoked Bear Meat
	{ 19304, 1, 5, "HEALTH" }, -- Spiced Beef Jerky
	{ 5477, 1, 1, "HEALTH" }, -- Strider Stew
	{ 18633, 1, 5, "HEALTH" }, -- Styleen's Sour Suckerpop
	{ 4537, 1, 5, "HEALTH" }, -- Tel'Abim Banana
	{ 16167, 1, 5, "HEALTH" }, -- Versicolor Treat
	{ 733, 1, 5, "HEALTH" }, -- Westfall Stew
	{ 5526, 1, 5, "HEALTH" }, -- Clam Chowder
	{ 5478, 1, 15, "HEALTH" }, -- Dig Rat Stew
	{ 1082, 1, 5, "HEALTH" }, -- Redridge Goulash
	{ 21072, 1, 10, "HEALTH" }, -- Smoked Sagefish
	{ 2685, 1, 15, "HEALTH" }, -- Succulent Pork Ribs
	{ 5479, 1, 5, "HEALTH" }, -- Crispy Lizard Tail
	{ 3726, 1, 5, "HEALTH" }, -- Big Bear Steak
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
	{ 3663, 1, 1, "HEALTH" }, -- Murloc Fin Soup
	{ 3770, 1, 15, "HEALTH" }, -- Mutton Chop
	{ 19305, 1, 15, "HEALTH" }, -- Pickled Kodo Foot
	{ 1017, 1, 15, "HEALTH" }, -- Seasoned Wolf Kabob
	{ 4538, 1, 15, "HEALTH" }, -- Snapvine Watermelon
	{ 4606, 1, 15, "HEALTH" }, -- Spongy Morel
	{ 16170, 1, 15, "HEALTH" }, -- Steamed Mandu
	{ 7228, 1, 15, "HEALTH" }, -- Tigule's Strawberry Ice Cream
	{ 20074, 1, 25, "HEALTH" }, -- Heavy Crocolisk Stew
	{ 3728, 1, 25, "HEALTH" }, -- Tasty Lion Steak
	{ 4457, 1, 25, "HEALTH" }, -- Barbecued Buzzard Wing
	{ 13546, 1, 25, "HEALTH" }, -- Bloodbelly Fish
	{ 12213, 1, 5, "HEALTH" }, -- Carrion Surprise
	{ 12238, 1, 5, "HEALTH" }, -- Darkshore Grouper
	{ 250077, 1, 5, "HEALTH" }, -- Twice-Spiced Raptor Slice
	{ 250080, 1, 5, "HEALTH" }, -- Breakfast Omelette
	{ 252026, 1, 5, "HEALTH" }, -- Gustberry Pie
	{ 252029, 1, 5, "HEALTH" }, -- Hippogryph Flank
	{ 252030, 1, 5, "HEALTH" }, -- Pungent Skycheddar
	{ 252032, 1, 5, "HEALTH" }, -- Red Delicious Stormapple
	{ 263509, 1, 5, "HEALTH" }, -- Skywall Souffle
	{ 263512, 1, 5, "HEALTH" }, -- Pincer Bites
	{ 278117, 1, 5, "HEALTH" }, -- Hard Boiled Eggs
	{ 4607, 1, 25, "HEALTH" }, -- Delicious Cave Mold
	{ 6038, 1, 25, "HEALTH" }, -- Giant Clam Scorcho
	{ 4539, 1, 25, "HEALTH" }, -- Goldenbark Apple
	{ 17407, 1, 25, "HEALTH" }, -- Graccu's Homemade Meat Pie
	{ 13851, 1, 25, "HEALTH" }, -- Hot Wolf Ribs
	{ 12212, 1, 35, "HEALTH" }, -- Jungle Stew
	{ 8364, 1, 25, "HEALTH" }, -- Mithril Head Trout
	{ 18632, 1, 25, "HEALTH" }, -- Moonbrook Riot Taffy
	{ 4544, 1, 25, "HEALTH" }, -- Mulgore Spice Bread
	{ 12214, 1, 15, "HEALTH" }, -- Mystery Stew
	{ 19224, 1, 25, "HEALTH" }, -- Red Hot Wings
	{ 12210, 1, 15, "HEALTH" }, -- Roast Raptor
	{ 4594, 1, 25, "HEALTH" }, -- Rockscale Cod
	{ 3729, 1, 15, "HEALTH" }, -- Soothing Turtle Bisque
	{ 248613, 1, 15, "HEALTH" }, -- Lightning in a Bottle
	{ 278121, 1, 15, "HEALTH" }, -- Smoked Sausage
	{ 1707, 1, 25, "HEALTH" }, -- Stormwind Brie
	{ 8543, 1, 25, "HEALTH" }, -- Underwater Mushroom Cap
	{ 3771, 1, 25, "HEALTH" }, -- Wild Hog Shank
	{ 16169, 1, 25, "HEALTH" }, -- Wild Ricecake
	{ 21217, 1, 30, "HEALTH" }, -- Sagefish Delight
	{ 18635, 1, 35, "HEALTH" }, -- Bellara's Nutterbar
	{ 13927, 1, 35, "HEALTH" }, -- Cooked Glossy Mightfish
	{ 19306, 1, 35, "HEALTH" }, -- Crunchy Frog
	{ 4599, 1, 35, "HEALTH" }, -- Cured Ham Steak
	{ 21030, 1, 35, "HEALTH" }, -- Darnassus Kimchi Pie
	{ 12217, 1, 25, "HEALTH" }, -- Dragonbreath Chili
	{ 13930, 1, 35, "HEALTH" }, -- Filet of Redgill
	{ 3927, 1, 35, "HEALTH" }, -- Fine Aged Cheddar
	{ 9681, 1, 35, "HEALTH" }, -- Grilled King Crawler Legs
	{ 13928, 1, 35, "HEALTH" }, -- Grilled Squid
	{ 16168, 1, 35, "HEALTH" }, -- Heaven Peach
	{ 12215, 1, 25, "HEALTH" }, -- Heavy Kodo Stew
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
	{ 13755, 1, 35, "HEALTH" }, -- Raw Winter Squid
	{ 16971, 1, 40, "HEALTH" }, -- Clamlette Surprise
	{ 12218, 1, 35, "HEALTH" }, -- Monster Omelet
	{ 12216, 1, 25, "HEALTH" }, -- Spiced Chili Crab
	{ 250073, 1, 25, "HEALTH" }, -- Raging Raptor Ribs
	{ 250074, 1, 25, "HEALTH" }, -- Bear Brisket
	{ 250078, 1, 25, "HEALTH" }, -- Giant Scrambled Eggs
	{ 260623, 1, 25, "HEALTH" }, -- Candied Fruit Sampler
	{ 274971, 1, 25, "HEALTH" }, -- Briny Seafood Stew
	{ 274976, 1, 25, "HEALTH" }, -- Plain Ol' Paletusk
	{ 278118, 1, 25, "HEALTH" }, -- Rich Broth
	{ 278120, 1, 25, "HEALTH" }, -- Fruit Platter
	{ 18045, 1, 35, "HEALTH" }, -- Tender Wolf Steak
	{ 8932, 1, 45, "HEALTH" }, -- Alterac Swiss
	{ 13935, 1, 45, "HEALTH" }, -- Baked Salmon
	{ 21031, 1, 45, "HEALTH" }, -- Cabbage Kimchi
	{ 19225, 1, 45, "HEALTH" }, -- Deep Fried Candybar
	{ 8953, 1, 45, "HEALTH" }, -- Deep Fried Plantains
	{ 8948, 1, 45, "HEALTH" }, -- Dried King Bolete
	{ 13724, 1, 45, "BOTH" }, -- Enriched Manna Biscuit
	{ 11444, 1, 45, "HEALTH" }, -- Grim Guzzler Boar
	{ 8950, 1, 45, "HEALTH" }, -- Homemade Cherry Pie
	{ 13893, 1, 45, "HEALTH" }, -- Large Raw Mightfish
	{ 13933, 1, 45, "HEALTH" }, -- Lobster Stew
	{ 13934, 1, 45, "HEALTH" }, -- Mightfish Steak
	{ 11415, 1, 45, "HEALTH" }, -- Mixed Berries
	{ 21033, 1, 45, "HEALTH" }, -- Radish Kimchi
	{ 8952, 1, 45, "HEALTH" }, -- Roasted Quail
	{ 18255, 1, 45, "HEALTH" }, -- Runn Tum Tuber
	{ 18254, 1, 35, "HEALTH" }, -- Runn Tum Tuber Surprise
	{ 250065, 1, 35, "HEALTH" }, -- Savory Stag Sliders
	{ 250076, 1, 35, "HEALTH" }, -- Raptor Rouladen
	{ 260624, 1, 35, "HEALTH" }, -- Pristine Peach
	{ 260625, 1, 35, "HEALTH" }, -- Garnished Rice Cake
	{ 286152, 1, 35, "HEALTH" }, -- Plated Armorfish
	{ 16171, 1, 45, "HEALTH" }, -- Shinsollo
	{ 20452, 1, 45, "HEALTH" }, -- Smoked Desert Dumplings
	{ 8957, 1, 45, "HEALTH" }, -- Spinefin Halibut
	{ 12763, 1, 45, "HEALTH" }, -- Un'Goro Etherfruit
	{ 22324, 1, 45, "HEALTH" }, -- Winter Kimchi
	{ 21023, 1, 45, "HEALTH" }, -- Dirge's Kickin' Chimaerok Chops
	{ 249796, 1, 45, "HEALTH" }, -- Hyjal Berries
	{ 250066, 1, 45, "HEALTH" }, -- Soaring Pamplona
	{ 250067, 1, 45, "HEALTH" }, -- Bat Hachee
	{ 250068, 1, 45, "HEALTH" }, -- Savory Turtle Stew
	{ 250069, 1, 45, "HEALTH" }, -- Flank au Poivre
	{ 250070, 1, 45, "HEALTH" }, -- Bear Bruscitti
	{ 250071, 1, 45, "HEALTH" }, -- Steaming Stag Steak
	{ 250072, 1, 45, "HEALTH" }, -- Swiftstrike Steak
	{ 250075, 1, 45, "HEALTH" }, -- Prehistoric Pulled Raptor
	{ 250081, 1, 45, "HEALTH" }, -- Clam Linguine
	{ 260627, 1, 45, "HEALTH" }, -- Savory Shen'dralar Steak
	{ 260628, 1, 45, "HEALTH" }, -- Stuffed Pumpkin
	{ 278122, 1, 45, "HEALTH" }, -- Carrot Salad
	{ 238638, 1, 55, "HEALTH" }, -- Filet o' Flank
	{ 267341, 1, 55, "HEALTH" }, -- Sweetpaw Jam
	{ 17404, 1, 5, "MANA" }, -- Blended Bean Brew
	{ 1179, 1, 5, "MANA" }, -- Ice Cold Milk
	{ 249866, 1, 5, "MANA" }, -- Royal Tea
	{ 249872, 1, 5, "MANA" }, -- Slimy Smoothie
	{ 252027, 1, 5, "MANA" }, -- Gustberry Juice
	{ 9451, 1, 15, "MANA" }, -- Bubbling Water
	{ 19299, 1, 15, "MANA" }, -- Fizzy Faire Drink
	{ 1205, 1, 15, "MANA" }, -- Melon Juice
	{ 249867, 1, 15, "MANA" }, -- Root Tea
	{ 249873, 1, 15, "MANA" }, -- Mrrggl Smrrthle
	{ 4791, 1, 25, "MANA" }, -- Enchanted Water
	{ 10841, 1, 25, "MANA" }, -- Goldthorn Tea
	{ 1708, 1, 25, "MANA" }, -- Sweet Nectar
	{ 249868, 1, 25, "MANA" }, -- Triage Tea
	{ 249874, 1, 25, "MANA" }, -- Calcified Smoothie
	{ 19300, 1, 35, "MANA" }, -- Bottled Winterspring Water
	{ 1645, 1, 35, "MANA" }, -- Moonberry Juice
	{ 249869, 1, 35, "MANA" }, -- Sunny Tea
	{ 249875, 1, 35, "MANA" }, -- Spicy Smoothie
	{ 8766, 1, 45, "MANA" }, -- Morning Glory Dew
	{ 249870, 1, 45, "MANA" }, -- Sage's Tea
	{ 249876, 1, 45, "MANA" }, -- Wicked Smoothie
	{ 285359, 1, 45, "MANA" }, -- Warm Apple Juice
	{ 18300, 1, 55, "MANA" }, -- Hyjal Nectar
}

--[[
How We Got the Data

Last Validated
	2026-10-09, WoW Forever 1.60.1.70291

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
	- Forever retuned many foods' levels from Classic Era's, and the rows carry Forever's.
	  5525 Boiled Clams, 2682 Cooked Crab Claw, 6890 Smoked Bear Meat, 5477 Strider Stew and
	  3663 Murloc Fin Soup now need only level 1, below the level 5 floor, so no recipient
	  falls in their band.
	- Forever moved many foods to spells outside the food and drink categories, so the
	  candidate IDs were settled from a Validate Data run of them rather than by category: every
	  Food & Drink item restoring health or mana that can be traded, isn't conjured and needs
	  level 5 or more went in.

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
	https://wago.tools/db2/Item?build=1.60.1.70291
	https://wago.tools/db2/ItemSparse?build=1.60.1.70291
	https://wago.tools/db2/ItemEffect?build=1.60.1.70291
	https://wago.tools/db2/ItemXItemEffect?build=1.60.1.70291
]]
