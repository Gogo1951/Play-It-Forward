local _, ns = ...

--[[
	Food and drink a player can be given. What a row restores decides who is eligible, per
	ns.Data.ConsumableClasses in Data/Data.lua, so there is no per-item class list.

	useLevel is the item's own required level; the recipient band is derived from it in
	Matcher:LevelBand rather than stored per row.
]]

--[[
    SELECT
        it.entry,
        it.name,
        it.Quality,
        it.RequiredLevel AS UseLevel,
        CASE
            WHEN 11 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
             AND 59 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                THEN 'Hybrid'
            WHEN 11 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                THEN 'Food'
            WHEN 59 IN (it.spellcategory_1,it.spellcategory_2,it.spellcategory_3,it.spellcategory_4,it.spellcategory_5)
                THEN 'Water'
            ELSE 'Other'
        END AS Kind
    FROM item_template it
    WHERE it.class    = 0        -- Consumable
      AND it.subclass = 5        -- Food & Drink
      AND it.bonding  = 0        -- non-soulbound
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
    HAVING Kind <> 'Other'       -- keep only Food / Water / Hybrid (restores HP or mana)
    ORDER BY Kind, UseLevel, it.name;
]]

-- { id, quality, useLevel, restores }
ns.Data.FoodAndWater = {
	{ 43491, 1, 0, "HEALTH" }, -- Bad Clams
	{ 1119, 1, 0, "HEALTH" }, -- Bottled Spirits
	{ 46887, 1, 0, "HEALTH" }, -- Bountiful Feast
	{ 11584, 1, 0, "HEALTH" }, -- Cactus Apple Surprise
	{ 33924, 1, 0, "HEALTH" }, -- Delicious Chocolate Cake
	{ 6522, 1, 0, "HEALTH" }, -- Deviate Fish
	{ 6807, 1, 0, "HEALTH" }, -- Frog Leg Stew
	{ 43492, 1, 0, "HEALTH" }, -- Haunted Herring
	{ 961, 1, 0, "HEALTH" }, -- Healing Herb
	{ 43488, 1, 0, "HEALTH" }, -- Last Weeks Mammoth
	{ 27635, 1, 0, "HEALTH" }, -- Lynx Steak
	{ 24105, 1, 0, "HEALTH" }, -- Roasted Moongraze Tenderloin
	{ 1326, 1, 0, "HEALTH" }, -- Sauteed Sunfish
	{ 6657, 1, 0, "HEALTH" }, -- Savory Deviate Delight
	{ 3448, 1, 0, "HEALTH" }, -- Senggin Root
	{ 43490, 1, 0, "HEALTH" }, -- Tasty Cupcake
	{ 17199, 1, 1, "HEALTH" }, -- Bad Egg Nog
	{ 16166, 1, 1, "HEALTH" }, -- Bean Soup
	{ 2888, 1, 1, "HEALTH" }, -- Beer Basted Boar Ribs
	{ 6290, 1, 1, "HEALTH" }, -- Brilliant Smallfish
	{ 44839, 1, 1, "HEALTH" }, -- Candied Sweet Potato
	{ 7807, 1, 1, "HEALTH" }, -- Candy Bar
	{ 17344, 1, 1, "HEALTH" }, -- Candy Cane
	{ 46690, 1, 1, "HEALTH" }, -- Candy Skull
	{ 2679, 1, 1, "HEALTH" }, -- Charred Wolf Meat
	{ 7808, 1, 1, "HEALTH" }, -- Chocolate Square
	{ 23756, 1, 1, "HEALTH" }, -- Cookie's Jumbo Gumbo
	{ 44854, 1, 1, "HEALTH" }, -- Cranberries
	{ 44840, 1, 1, "HEALTH" }, -- Cranberry Chutney
	{ 12224, 1, 1, "HEALTH" }, -- Crispy Bat Wing
	{ 19223, 1, 1, "HEALTH" }, -- Darkmoon Dog
	{ 2070, 1, 1, "HEALTH" }, -- Darnassian Bleu
	{ 17198, 1, 1, "HEALTH" }, -- Egg Nog
	{ 4604, 1, 1, "HEALTH" }, -- Forest Mushroom Cap
	{ 17197, 1, 1, "HEALTH" }, -- Gingerbread Cookie
	{ 6888, 1, 1, "HEALTH" }, -- Herb Baked Egg
	{ 20857, 1, 1, "HEALTH" }, -- Honey Bread
	{ 5472, 1, 1, "HEALTH" }, -- Kaldorei Spider Kabob
	{ 7097, 1, 1, "HEALTH" }, -- Leg Meat
	{ 7806, 1, 1, "HEALTH" }, -- Lollipop
	{ 46797, 1, 1, "HEALTH" }, -- Mulgore Sweet Potato
	{ 44836, 1, 1, "HEALTH" }, -- Pumpkin Pie
	{ 46784, 1, 1, "HEALTH" }, -- Ripe Elwynn Pumpkin
	{ 46796, 1, 1, "HEALTH" }, -- Ripe Tirisfal Pumpkin
	{ 5057, 1, 1, "HEALTH" }, -- Ripe Watermelon
	{ 2681, 1, 1, "HEALTH" }, -- Roasted Boar Meat
	{ 5474, 1, 1, "HEALTH" }, -- Roasted Kodo Meat
	{ 5473, 1, 1, "HEALTH" }, -- Scorpid Surprise
	{ 4536, 1, 1, "HEALTH" }, -- Shiny Red Apple
	{ 6299, 1, 1, "HEALTH" }, -- Sickly Looking Fish
	{ 787, 1, 1, "HEALTH" }, -- Slitherskin Mackerel
	{ 44838, 1, 1, "HEALTH" }, -- Slow-Roasted Turkey
	{ 4656, 1, 1, "HEALTH" }, -- Small Pumpkin
	{ 11109, 1, 1, "HEALTH" }, -- Special Chicken Feed
	{ 30816, 1, 1, "HEALTH" }, -- Spice Bread
	{ 44837, 1, 1, "HEALTH" }, -- Spice Bread Stuffing
	{ 2680, 1, 1, "HEALTH" }, -- Spiced Wolf Meat
	{ 46793, 1, 1, "HEALTH" }, -- Tangy Southfury Cranberries
	{ 4540, 1, 1, "HEALTH" }, -- Tough Hunk of Bread
	{ 117, 1, 1, "HEALTH" }, -- Tough Jerky
	{ 44855, 1, 1, "HEALTH" }, -- Yam
	{ 1401, 1, 4, "HEALTH" }, -- Green Tea Leaf
	{ 27636, 1, 5, "HEALTH" }, -- Bat Bites
	{ 3220, 1, 5, "HEALTH" }, -- Blood Sausage
	{ 5525, 1, 5, "HEALTH" }, -- Boiled Clams
	{ 2682, 1, 5, "HEALTH" }, -- Cooked Crab Claw
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
	{ 5526, 1, 10, "HEALTH" }, -- Clam Chowder
	{ 5478, 1, 10, "HEALTH" }, -- Dig Rat Stew
	{ 1082, 1, 10, "HEALTH" }, -- Redridge Goulash
	{ 21072, 1, 10, "HEALTH" }, -- Smoked Sagefish
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
	{ 7228, 1, 15, "HEALTH" }, -- Tigule and Foror's Strawberry Ice Cream
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
	{ 21217, 1, 30, "HEALTH" }, -- Sagefish Delight
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
	{ 8932, 1, 45, "HEALTH" }, -- Alterac Swiss
	{ 13935, 1, 45, "HEALTH" }, -- Baked Salmon
	{ 21031, 1, 45, "HEALTH" }, -- Cabbage Kimchi
	{ 35563, 1, 45, "HEALTH" }, -- Charred Bear Kabobs
	{ 19225, 1, 45, "HEALTH" }, -- Deep Fried Candybar
	{ 8953, 1, 45, "HEALTH" }, -- Deep Fried Plantains
	{ 8948, 1, 45, "HEALTH" }, -- Dried King Bolete
	{ 13724, 1, 45, "HEALTH" }, -- Enriched Manna Biscuit
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
	{ 41751, 1, 55, "HEALTH" }, -- Black Mushroom
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
	{ 33874, 1, 55, "HEALTH" }, -- Kibler's Bits
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
	{ 27656, 1, 55, "HEALTH" }, -- Sporeling Snack
	{ 33866, 1, 55, "HEALTH" }, -- Stormchops
	{ 30458, 1, 55, "HEALTH" }, -- Stromgarde Muenster
	{ 27858, 1, 55, "HEALTH" }, -- Sunspring Carp
	{ 27660, 1, 55, "HEALTH" }, -- Talbuk Steak
	{ 27659, 1, 55, "HEALTH" }, -- Warp Burger
	{ 27859, 1, 55, "HEALTH" }, -- Zangar Caps
	{ 29449, 1, 65, "HEALTH" }, -- Bladespire Bagel
	{ 29451, 1, 65, "HEALTH" }, -- Clefthoof Ribs
	{ 33449, 1, 65, "HEALTH" }, -- Crusty Flatbread
	{ 44608, 1, 65, "HEALTH" }, -- Dalaran Swiss
	{ 35710, 1, 65, "HEALTH" }, -- Delicious Baked Ham
	{ 32722, 1, 65, "HEALTH" }, -- Enriched Terocone Juice
	{ 37452, 1, 65, "HEALTH" }, -- Fatty Bluefin
	{ 33451, 1, 65, "HEALTH" }, -- Fillet of Icefin
	{ 33052, 1, 65, "HEALTH" }, -- Fisherman's Feast
	{ 44609, 1, 65, "HEALTH" }, -- Fresh Dalaran Bread Slice
	{ 40359, 1, 65, "HEALTH" }, -- Fresh Eagle Meat
	{ 37252, 1, 65, "HEALTH" }, -- Frostberries
	{ 30355, 1, 65, "HEALTH" }, -- Grilled Shadowmoon Tuber
	{ 40356, 1, 65, "HEALTH" }, -- Grizzleberries
	{ 33452, 1, 65, "HEALTH" }, -- Honey-Spiced Lichen
	{ 33053, 1, 65, "HEALTH" }, -- Hot Buttered Trout
	{ 29394, 1, 65, "HEALTH" }, -- Lyribread
	{ 29448, 1, 65, "HEALTH" }, -- Mag'har Mild Cheese
	{ 32686, 1, 65, "HEALTH" }, -- Mingo's Fortune Giblets
	{ 32685, 1, 65, "HEALTH" }, -- Ogri'la Chicken Fingers
	{ 40358, 1, 65, "HEALTH" }, -- Raw Tallhorn Chunk
	{ 38428, 1, 65, "HEALTH" }, -- Rock-Salted Pretzel
	{ 33454, 1, 65, "HEALTH" }, -- Salted Venison
	{ 44749, 1, 65, "HEALTH" }, -- Salted Yeti Cheese
	{ 33825, 1, 65, "HEALTH" }, -- Skullfish Soup
	{ 33443, 1, 65, "HEALTH" }, -- Sour Goat Cheese
	{ 33872, 1, 65, "HEALTH" }, -- Spicy Hot Talbuk
	{ 29453, 1, 65, "HEALTH" }, -- Sporeggar Mushroom
	{ 33048, 1, 65, "HEALTH" }, -- Stewed Trout
	{ 36831, 1, 65, "HEALTH" }, -- Stolen Ribs
	{ 29450, 1, 65, "HEALTH" }, -- Telaari Grapes
	{ 35949, 1, 65, "HEALTH" }, -- Tundra Berries
	{ 29452, 1, 65, "HEALTH" }, -- Zangar Trout
	{ 42942, 1, 70, "HEALTH" }, -- Baked Manta Ray
	{ 42432, 1, 70, "HEALTH" }, -- Berry Pie Slice
	{ 42999, 1, 70, "HEALTH" }, -- Blackened Dragonfin
	{ 42997, 1, 70, "HEALTH" }, -- Blackened Worg Steak
	{ 42428, 1, 70, "HEALTH" }, -- Carrot Cupcake
	{ 42433, 1, 70, "HEALTH" }, -- Chocolate Cake Slice
	{ 34770, 1, 70, "HEALTH" }, -- Cooked Northrend Fish 12
	{ 43004, 1, 70, "HEALTH" }, -- Critter Bites
	{ 42998, 1, 70, "HEALTH" }, -- Cuttlesteak
	{ 43268, 1, 70, "HEALTH" }, -- Dalaran Clam Chowder
	{ 42430, 1, 70, "HEALTH" }, -- Dalaran Doughnut
	{ 43000, 1, 70, "HEALTH" }, -- Dragonfin Filet
	{ 34767, 1, 70, "HEALTH" }, -- Firecracker Salmon
	{ 43015, 1, 70, "HEALTH" }, -- Fish Feast
	{ 43478, 1, 70, "HEALTH" }, -- Gigantic Feast
	{ 34753, 1, 70, "HEALTH" }, -- Great Feast
	{ 34760, 1, 70, "HEALTH" }, -- Grilled Bonescale
	{ 34762, 1, 70, "HEALTH" }, -- Grilled Sculpin
	{ 42995, 1, 70, "HEALTH" }, -- Hearty Rhino
	{ 45901, 1, 70, "HEALTH" }, -- Homemade Fish Fry
	{ 34769, 1, 70, "HEALTH" }, -- Imperial Manta Steak
	{ 34748, 1, 70, "HEALTH" }, -- Mammoth Meal
	{ 34754, 1, 70, "HEALTH" }, -- Mega Mammoth Meal
	{ 34758, 1, 70, "HEALTH" }, -- Mighty Rhino Dogs
	{ 34747, 1, 70, "HEALTH" }, -- Northern Stew
	{ 34765, 1, 70, "HEALTH" }, -- Pickled Fangtooth
	{ 34764, 1, 70, "HEALTH" }, -- Poached Nettlefish
	{ 34766, 1, 70, "HEALTH" }, -- Poached Northern Sculpin
	{ 34752, 1, 70, "HEALTH" }, -- Rhino Dogs
	{ 42994, 1, 70, "HEALTH" }, -- Rhinolicious Wormsteak
	{ 34751, 1, 70, "HEALTH" }, -- Roasted Worg
	{ 34761, 1, 70, "HEALTH" }, -- Sauteed Goby
	{ 34125, 1, 70, "HEALTH" }, -- Shoveltusk Soup
	{ 34749, 1, 70, "HEALTH" }, -- Shoveltusk Steak
	{ 43480, 1, 70, "HEALTH" }, -- Small Feast
	{ 34759, 1, 70, "HEALTH" }, -- Smoked Rockfin
	{ 34763, 1, 70, "HEALTH" }, -- Smoked Salmon
	{ 42996, 1, 70, "HEALTH" }, -- Snapper Extreme
	{ 43005, 1, 70, "HEALTH" }, -- Spiced Mammoth Treats
	{ 34756, 1, 70, "HEALTH" }, -- Spiced Worm Burger
	{ 34768, 1, 70, "HEALTH" }, -- Spicy Blue Nettlefish
	{ 42993, 1, 70, "HEALTH" }, -- Spicy Fried Herring
	{ 39691, 1, 70, "HEALTH" }, -- Succulent Orca Stew
	{ 34755, 1, 70, "HEALTH" }, -- Tender Shoveltusk Steak
	{ 43001, 1, 70, "HEALTH" }, -- Tracker Snacks
	{ 34757, 1, 70, "HEALTH" }, -- Very Burnt Worg
	{ 44953, 1, 70, "HEALTH" }, -- Worg Tartare
	{ 34750, 1, 70, "HEALTH" }, -- Worm Delight
	{ 44607, 1, 75, "HEALTH" }, -- Aged Dalaran Sharp
	{ 44722, 1, 75, "HEALTH" }, -- Aged Yolk
	{ 45932, 1, 75, "HEALTH" }, -- Black Jelly
	{ 38706, 1, 75, "HEALTH" }, -- Bowels 'n' Brains
	{ 35952, 1, 75, "HEALTH" }, -- Briny Hardcheese
	{ 44940, 1, 75, "HEALTH" }, -- Corn-Breaded Sausage
	{ 43087, 1, 75, "HEALTH" }, -- Crisp Dalaran Apple
	{ 42778, 1, 75, "HEALTH" }, -- Crusader's Rations
	{ 42431, 1, 75, "HEALTH" }, -- Dalaran Brownie
	{ 42434, 1, 75, "HEALTH" }, -- Lovely Cake Slice
	{ 35953, 1, 75, "HEALTH" }, -- Mead Basted Caribou
	{ 35951, 1, 75, "HEALTH" }, -- Poached Emperor Salmon
	{ 42429, 1, 75, "HEALTH" }, -- Red Velvet Cupcake
	{ 35948, 1, 75, "HEALTH" }, -- Savory Snowplum
	{ 40202, 1, 75, "HEALTH" }, -- Sizzling Grizzly Flank
	{ 35947, 1, 75, "HEALTH" }, -- Sparkling Frostcap
	{ 42779, 1, 75, "HEALTH" }, -- Steaming Chicken Soup
	{ 41729, 1, 75, "HEALTH" }, -- Stewed Drakeflesh
	{ 35950, 1, 75, "HEALTH" }, -- Sweet Potato Bread
	{ 21721, 1, 0, "MANA" }, -- Moonglow
	{ 5342, 1, 0, "MANA" }, -- Raptor Punch
	{ 159, 1, 1, "MANA" }, -- Refreshing Spring Water
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
	{ 37253, 1, 65, "MANA" }, -- Frostberry Juice
	{ 30457, 1, 65, "MANA" }, -- Gilneas Sparkling Water
	{ 40357, 1, 65, "MANA" }, -- Grizzleberry Juice
	{ 34411, 1, 65, "MANA" }, -- Hot Apple Cider
	{ 44750, 1, 65, "MANA" }, -- Mountain Water
	{ 27860, 1, 65, "MANA" }, -- Purified Draenic Water
	{ 29401, 1, 65, "MANA" }, -- Sparkling Southshore Cider
	{ 32453, 1, 65, "MANA" }, -- Star's Tears
	{ 35954, 1, 65, "MANA" }, -- Sweetened Goat's Milk
	{ 38698, 1, 70, "MANA" }, -- Bitter Plasma
	{ 43086, 1, 70, "MANA" }, -- Fresh Apple Juice
	{ 44941, 1, 70, "MANA" }, -- Fresh-Squeezed Limeade
	{ 33444, 1, 70, "MANA" }, -- Pungent Seal Whey
	{ 42777, 1, 75, "MANA" }, -- Crusader's Waterskin
	{ 33445, 1, 75, "MANA" }, -- Honeymint Tea
	{ 39520, 1, 75, "MANA" }, -- Kungaloosh
	{ 43236, 1, 75, "MANA" }, -- Star's Sorrow
	{ 41731, 1, 75, "MANA" }, -- Yeti Milk
}
