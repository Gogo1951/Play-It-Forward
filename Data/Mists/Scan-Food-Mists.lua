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
	{ 49600, 1, 5, "HEALTH" }, -- Goblin Shortbread
	{ 724, 1, 5, "HEALTH" }, -- Goretusk Liver Pie
	{ 2287, 1, 5, "HEALTH" }, -- Haunch of Meat
	{ 17406, 1, 5, "HEALTH" }, -- Holiday Cheesewheel
	{ 6316, 1, 5, "HEALTH" }, -- Loch Frenzy Delight
	{ 4592, 1, 5, "HEALTH" }, -- Longjaw Mud Snapper
	{ 5095, 1, 5, "HEALTH" }, -- Rainbow Fin Albacore
	{ 4605, 1, 5, "HEALTH" }, -- Red-Speckled Mushroom
	{ 24072, 1, 5, "HEALTH" }, -- Sand Pear Pie
	{ 1326, 1, 5, "HEALTH" }, -- Sauteed Sunfish
	{ 3448, 1, 5, "BOTH" }, -- Senggin Root
	{ 6890, 1, 5, "HEALTH" }, -- Smoked Bear Meat
	{ 19304, 1, 5, "HEALTH" }, -- Spiced Beef Jerky
	{ 5477, 1, 5, "HEALTH" }, -- Strider Stew
	{ 18633, 1, 5, "HEALTH" }, -- Styleen's Sour Suckerpop
	{ 4537, 1, 5, "HEALTH" }, -- Tel'Abim Banana
	{ 69920, 1, 5, "HEALTH" }, -- Thrice-Spiced Crunchy Stew
	{ 67230, 1, 5, "HEALTH" }, -- Venison Jerky
	{ 16167, 1, 5, "HEALTH" }, -- Versicolor Treat
	{ 733, 1, 15, "HEALTH" }, -- Westfall Stew
	{ 5526, 1, 15, "HEALTH" }, -- Clam Chowder
	{ 5478, 1, 15, "HEALTH" }, -- Dig Rat Stew
	{ 1082, 1, 15, "HEALTH" }, -- Redridge Goulash
	{ 21072, 1, 10, "BOTH" }, -- Smoked Sagefish
	{ 2685, 1, 15, "HEALTH" }, -- Succulent Pork Ribs
	{ 5479, 1, 15, "HEALTH" }, -- Crispy Lizard Tail
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
	{ 63693, 1, 20, "HEALTH" }, -- Ooey Gooey Gelato
	{ 63694, 1, 20, "HEALTH" }, -- Silithid-Free Sorbet
	{ 6807, 1, 25, "HEALTH" }, -- Frog Leg Stew
	{ 20074, 1, 25, "HEALTH" }, -- Heavy Crocolisk Stew
	{ 3728, 1, 25, "HEALTH" }, -- Tasty Lion Steak
	{ 4457, 1, 25, "HEALTH" }, -- Barbecued Buzzard Wing
	{ 63692, 1, 30, "HEALTH" }, -- Frozen "Cream" Custard
	{ 13546, 1, 35, "HEALTH" }, -- Bloodbelly Fish
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
	{ 63691, 1, 40, "HEALTH" }, -- Brivelthwerp's Crunchy Ice Cream Bar
	{ 16971, 1, 40, "HEALTH" }, -- Clamlette Surprise
	{ 69244, 1, 40, "HEALTH" }, -- Ice Cream Bar
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
	{ 32722, 1, 65, "BOTH" }, -- Enriched Terocone Juice
	{ 37452, 1, 65, "HEALTH" }, -- Fatty Bluefin
	{ 33451, 1, 65, "HEALTH" }, -- Fillet of Icefin
	{ 33052, 1, 65, "HEALTH" }, -- Fisherman's Feast
	{ 44609, 1, 65, "HEALTH" }, -- Fresh Dalaran Bread Slice
	{ 40359, 1, 65, "HEALTH" }, -- Fresh Eagle Meat
	{ 37252, 1, 65, "HEALTH" }, -- Frostberries
	{ 30355, 1, 65, "HEALTH" }, -- Grilled Shadowmoon Tuber
	{ 40356, 1, 65, "HEALTH" }, -- Grizzleberries
	{ 33452, 1, 65, "HEALTH" }, -- Honey-Spiced Lichen
	{ 33053, 1, 65, "BOTH" }, -- Hot Buttered Trout
	{ 29394, 1, 65, "HEALTH" }, -- Lyribread
	{ 29448, 1, 65, "HEALTH" }, -- Mag'har Mild Cheese
	{ 32686, 1, 65, "HEALTH" }, -- Mingo's Fortune Giblets
	{ 32685, 1, 65, "HEALTH" }, -- Ogri'la Chicken Fingers
	{ 40358, 1, 65, "HEALTH" }, -- Raw Tallhorn Chunk
	{ 38428, 1, 65, "HEALTH" }, -- Rock-Salted Pretzel
	{ 33454, 1, 65, "HEALTH" }, -- Salted Venison
	{ 44749, 1, 65, "HEALTH" }, -- Salted Yeti Cheese
	{ 90659, 1, 5, "MANA" }, -- Jasmine Tea
	{ 63530, 1, 5, "MANA" }, -- Refreshing Pineapple Punch
	{ 49601, 1, 5, "MANA" }, -- Volcanic Spring Water
	{ 90660, 1, 15, "MANA" }, -- Black Tea
	{ 33825, 1, 65, "MANA" }, -- Skullfish Soup
	{ 33443, 1, 65, "HEALTH" }, -- Sour Goat Cheese
	{ 33872, 1, 65, "HEALTH" }, -- Spicy Hot Talbuk
	{ 29453, 1, 65, "HEALTH" }, -- Sporeggar Mushroom
	{ 33048, 1, 65, "HEALTH" }, -- Stewed Trout
	{ 36831, 1, 65, "HEALTH" }, -- Stolen Ribs
	{ 29450, 1, 65, "HEALTH" }, -- Telaari Grapes
	{ 35949, 1, 65, "HEALTH" }, -- Tundra Berries
	{ 29452, 1, 65, "HEALTH" }, -- Zangar Trout
	{ 42942, 1, 70, "BOTH" }, -- Baked Manta Ray
	{ 42432, 1, 70, "HEALTH" }, -- Berry Pie Slice
	{ 42999, 1, 70, "BOTH" }, -- Blackened Dragonfin
	{ 42997, 1, 70, "HEALTH" }, -- Blackened Worg Steak
	{ 42428, 1, 70, "HEALTH" }, -- Carrot Cupcake
	{ 42433, 1, 70, "HEALTH" }, -- Chocolate Cake Slice
	{ 42998, 1, 70, "BOTH" }, -- Cuttlesteak
	{ 43268, 1, 70, "BOTH" }, -- Dalaran Clam Chowder
	{ 42430, 1, 70, "HEALTH" }, -- Dalaran Doughnut
	{ 43000, 1, 70, "BOTH" }, -- Dragonfin Filet
	{ 34767, 1, 70, "BOTH" }, -- Firecracker Salmon
	{ 43015, 1, 70, "BOTH" }, -- Fish Feast
	{ 43478, 1, 70, "BOTH" }, -- Gigantic Feast
	{ 34753, 1, 70, "BOTH" }, -- Great Feast
	{ 34760, 1, 70, "BOTH" }, -- Grilled Bonescale
	{ 34762, 1, 70, "BOTH" }, -- Grilled Sculpin
	{ 42995, 1, 70, "HEALTH" }, -- Hearty Rhino
	{ 45901, 1, 70, "HEALTH" }, -- Homemade Fish Fry
	{ 69243, 1, 70, "HEALTH" }, -- Ice Cream Cake Slice
	{ 34769, 1, 70, "BOTH" }, -- Imperial Manta Steak
	{ 34748, 1, 70, "HEALTH" }, -- Mammoth Meal
	{ 34754, 1, 70, "HEALTH" }, -- Mega Mammoth Meal
	{ 34758, 1, 70, "HEALTH" }, -- Mighty Rhino Dogs
	{ 34747, 1, 70, "HEALTH" }, -- Northern Stew
	{ 34765, 1, 70, "BOTH" }, -- Pickled Fangtooth
	{ 34764, 1, 70, "BOTH" }, -- Poached Nettlefish
	{ 34766, 1, 70, "BOTH" }, -- Poached Northern Sculpin
	{ 34752, 1, 70, "HEALTH" }, -- Rhino Dogs
	{ 42994, 1, 70, "HEALTH" }, -- Rhinolicious Wormsteak
	{ 34751, 1, 70, "HEALTH" }, -- Roasted Worg
	{ 34761, 1, 70, "BOTH" }, -- Sauteed Goby
	{ 34125, 1, 70, "HEALTH" }, -- Shoveltusk Soup
	{ 34749, 1, 70, "HEALTH" }, -- Shoveltusk Steak
	{ 43480, 1, 70, "BOTH" }, -- Small Feast
	{ 34759, 1, 70, "BOTH" }, -- Smoked Rockfin
	{ 34763, 1, 70, "BOTH" }, -- Smoked Salmon
	{ 42996, 1, 70, "BOTH" }, -- Snapper Extreme
	{ 43005, 1, 70, "PET" }, -- Spiced Mammoth Treats
	{ 34756, 1, 70, "HEALTH" }, -- Spiced Worm Burger
	{ 34768, 1, 70, "BOTH" }, -- Spicy Blue Nettlefish
	{ 42993, 1, 70, "BOTH" }, -- Spicy Fried Herring
	{ 39691, 1, 70, "HEALTH" }, -- Succulent Orca Stew
	{ 34755, 1, 70, "HEALTH" }, -- Tender Shoveltusk Steak
	{ 43001, 1, 70, "HEALTH" }, -- Tracker Snacks
	{ 34757, 1, 70, "HEALTH" }, -- Very Burnt Worg
	{ 44953, 1, 70, "BOTH" }, -- Worg Tartare
	{ 34750, 1, 70, "HEALTH" }, -- Worm Delight
	{ 44607, 1, 75, "HEALTH" }, -- Aged Dalaran Sharp
	{ 44722, 1, 75, "HEALTH" }, -- Aged Yolk
	{ 45932, 1, 75, "BOTH" }, -- Black Jelly
	{ 38706, 1, 75, "HEALTH" }, -- Bowels 'n' Brains
	{ 35952, 1, 75, "HEALTH" }, -- Briny Hardcheese
	{ 44940, 1, 75, "HEALTH" }, -- Corn-Breaded Sausage
	{ 43087, 1, 75, "HEALTH" }, -- Crisp Dalaran Apple
	{ 42778, 1, 75, "HEALTH" }, -- Crusader's Rations
	{ 42431, 1, 75, "HEALTH" }, -- Dalaran Brownie
	{ 58276, 1, 75, "HEALTH" }, -- Gilnean White
	{ 58275, 1, 75, "HEALTH" }, -- Hardtack
	{ 42434, 1, 75, "HEALTH" }, -- Lovely Cake Slice
	{ 35953, 1, 75, "HEALTH" }, -- Mead Basted Caribou
	{ 59231, 1, 75, "HEALTH" }, -- Oily Giblets
	{ 35951, 1, 75, "HEALTH" }, -- Poached Emperor Salmon
	{ 42429, 1, 75, "HEALTH" }, -- Red Velvet Cupcake
	{ 59227, 1, 75, "HEALTH" }, -- Rock-Hard Biscuit
	{ 35948, 1, 75, "HEALTH" }, -- Savory Snowplum
	{ 58277, 1, 75, "HEALTH" }, -- Simmered Squid
	{ 40202, 1, 75, "HEALTH" }, -- Sizzling Grizzly Flank
	{ 35947, 1, 75, "HEALTH" }, -- Sparkling Frostcap
	{ 42779, 1, 75, "HEALTH" }, -- Steaming Chicken Soup
	{ 41729, 1, 75, "HEALTH" }, -- Stewed Drakeflesh
	{ 58280, 1, 75, "HEALTH" }, -- Stewed Rabbit
	{ 35950, 1, 75, "HEALTH" }, -- Sweet Potato Bread
	{ 58279, 1, 75, "HEALTH" }, -- Tasty Puffball
	{ 58278, 1, 75, "HEALTH" }, -- Tropical Sunfruit
	{ 62661, 1, 80, "BOTH" }, -- Baked Rockfish
	{ 62665, 1, 80, "BOTH" }, -- Basilisk Liverdog
	{ 62670, 1, 80, "BOTH" }, -- Beer-Basted Crocolisk
	{ 62668, 1, 80, "BOTH" }, -- Blackbelly Sushi
	{ 62676, 1, 80, "HEALTH" }, -- Blackened Surprise
	{ 62655, 1, 80, "BOTH" }, -- Broiled Mountain Trout
	{ 62664, 1, 80, "BOTH" }, -- Crocolisk Au Gratin
	{ 62666, 1, 80, "BOTH" }, -- Delicious Sagefish Tail
	{ 62677, 1, 80, "HEALTH" }, -- Fish Fry
	{ 62649, 1, 80, "HEALTH" }, -- Fortune Cookie
	{ 62662, 1, 80, "BOTH" }, -- Grilled Dragon
	{ 62659, 1, 80, "BOTH" }, -- Hearty Seafood Soup
	{ 62654, 1, 80, "BOTH" }, -- Lavascale Fillet
	{ 62663, 1, 80, "BOTH" }, -- Lavascale Minestrone
	{ 62651, 1, 80, "BOTH" }, -- Lightly Fried Lurker
	{ 62657, 1, 80, "BOTH" }, -- Lurker Lunch
	{ 62667, 1, 80, "BOTH" }, -- Mushroom Sauce Mudfish
	{ 62660, 1, 80, "BOTH" }, -- Pickled Guppy
	{ 58260, 1, 80, "HEALTH" }, -- Pine Nut Bread
	{ 58268, 1, 80, "HEALTH" }, -- Roasted Beef
	{ 62653, 1, 80, "BOTH" }, -- Salted Eye
	{ 68687, 1, 80, "BOTH" }, -- Scalding Murglesnout
	{ 62652, 1, 80, "BOTH" }, -- Seasoned Crab
	{ 62671, 1, 80, "BOTH" }, -- Severed Sagefish Head
	{ 62669, 1, 80, "BOTH" }, -- Skewered Eel
	{ 58262, 1, 80, "HEALTH" }, -- Sliced Raw Billfish
	{ 58258, 1, 80, "HEALTH" }, -- Smoked String Cheese
	{ 58264, 1, 80, "HEALTH" }, -- Sour Green Apple
	{ 62658, 1, 80, "BOTH" }, -- Tender Baked Turtle
	{ 59232, 1, 80, "HEALTH" }, -- Unidentifiable Meat Dish
	{ 59228, 1, 80, "HEALTH" }, -- Vile Purple Fungus
	{ 58266, 1, 80, "HEALTH" }, -- Violet Morel
	{ 62656, 1, 80, "BOTH" }, -- Whitecrest Gumbo
	{ 81405, 1, 85, "HEALTH" }, -- Boiled Silkworm Pupa
	{ 58261, 1, 85, "HEALTH" }, -- Buttery Wheat Roll
	{ 74642, 1, 85, "BOTH" }, -- Charbroiled Tiger Steak
	{ 81175, 1, 85, "HEALTH" }, -- Crispy Dojani Eel
	{ 74921, 1, 85, "HEALTH" }, -- Darkmoon Doughnut
	{ 81404, 1, 85, "HEALTH" }, -- Dried Needle Mushrooms
	{ 81403, 1, 85, "HEALTH" }, -- Dried Peaches
	{ 74641, 1, 85, "HEALTH" }, -- Fish Cake
	{ 75026, 1, 85, "BOTH" }, -- Ginseng Tea
	{ 58263, 1, 85, "HEALTH" }, -- Grilled Shark
	{ 58265, 1, 85, "HEALTH" }, -- Highland Pomegranate
	{ 58259, 1, 85, "HEALTH" }, -- Highland Sheep Cheese
	{ 85504, 1, 85, "HEALTH" }, -- Krasarang Fritters
	{ 90457, 1, 85, "BOTH" }, -- Mah's Warm Yak-Tail Stew
	{ 58269, 1, 85, "HEALTH" }, -- Massive Turkey Leg
	{ 86026, 1, 85, "BOTH" }, -- Perfectly Cooked Instant Noodles
	{ 81400, 1, 85, "HEALTH" }, -- Pounded Rice Cake
	{ 81406, 1, 85, "BOTH" }, -- Roasted Barley Tea
	{ 73260, 1, 85, "HEALTH" }, -- Salty Sea Dog
	{ 74643, 1, 85, "BOTH" }, -- Sauteed Carrots
	{ 58267, 1, 85, "HEALTH" }, -- Scarlet Polypore
	{ 105708, 1, 85, "HEALTH" }, -- Shimmering Amber-Brew
	{ 74651, 1, 85, "BOTH" }, -- Shrimp Dumplings
	{ 86057, 1, 85, "HEALTH" }, -- Sliced Peaches
	{ 74644, 1, 85, "BOTH" }, -- Swirling Mist Soup
	{ 81402, 1, 85, "HEALTH" }, -- Toasted Fish Jerky
	{ 83097, 1, 85, "HEALTH" }, -- Tortoise Jerky
	{ 74654, 1, 85, "BOTH" }, -- Wildfowl Roast
	{ 81401, 1, 85, "HEALTH" }, -- Yak Cheese Curds
	{ 74649, 1, 87, "BOTH" }, -- Braised Turtle
	{ 74645, 1, 87, "BOTH" }, -- Eternal Blossom Fish
	{ 74652, 1, 87, "BOTH" }, -- Fire Spirit Salmon
	{ 86069, 1, 87, "BOTH" }, -- Rice Pudding
	{ 74655, 1, 87, "BOTH" }, -- Twin Fish Platter
	{ 74647, 1, 87, "BOTH" }, -- Valley Stir Fry
	{ 86070, 1, 87, "BOTH" }, -- Wildfowl Ginseng Soup
	{ 74646, 1, 90, "BOTH" }, -- Black Pepper Ribs and Shrimp
	{ 81412, 1, 90, "HEALTH" }, -- Blanched Needle Mushrooms
	{ 105719, 1, 90, "HEALTH" }, -- Brew-Curried Whitefish
	{ 105720, 1, 90, "HEALTH" }, -- Candied Apple
	{ 74656, 1, 90, "BOTH" }, -- Chun Tian Spring Rolls
	{ 101747, 1, 90, "BOTH" }, -- Farmer's Delight
	{ 101750, 1, 90, "BOTH" }, -- Fluffy Silkfeather Omelet
	{ 105724, 1, 90, "HEALTH" }, -- Fried Cheese Dumplings
	{ 82451, 1, 90, "HEALTH" }, -- Frybread
	{ 104343, 1, 90, "HEALTH" }, -- Golden Dragon Noodles
	{ 81410, 1, 90, "HEALTH" }, -- Green Curry Fish
	{ 94535, 1, 90, "BOTH" }, -- Grilled Dinosaur Haunch
	{ 104339, 1, 90, "HEALTH" }, -- Harmonious River Noodles
	{ 105721, 1, 90, "BOTH" }, -- Hot Papaya Milk
	{ 104344, 1, 90, "HEALTH" }, -- Lucky Mushroom Noodles
	{ 75038, 1, 90, "BOTH" }, -- Mad Brewer's Breakfast
	{ 101745, 1, 90, "BOTH" }, -- Mango Ice
	{ 74650, 1, 90, "BOTH" }, -- Mogu Fish Stew
	{ 105722, 1, 90, "HEALTH" }, -- Nutty Brew-Bun
	{ 81411, 1, 90, "HEALTH" }, -- Peach Pie
	{ 105723, 1, 90, "HEALTH" }, -- Peanut Pork Chops
	{ 81414, 1, 90, "BOTH" }, -- Pearl Milk Tea
	{ 81408, 1, 90, "HEALTH" }, -- Red Bean Bun
	{ 105717, 1, 90, "HEALTH" }, -- Rice-Wine Mushrooms
	{ 74648, 1, 90, "BOTH" }, -- Sea Mist Rice Noodles
	{ 101746, 1, 90, "BOTH" }, -- Seasoned Pomfruit Slices
	{ 81413, 1, 90, "HEALTH" }, -- Skewered Peanut Chicken
	{ 101748, 1, 90, "BOTH" }, -- Spiced Blossom Soup
	{ 104342, 1, 90, "HEALTH" }, -- Spicy Mushan Noodles
	{ 86073, 1, 90, "BOTH" }, -- Spicy Salmon
	{ 86074, 1, 90, "BOTH" }, -- Spicy Vegetable Chips
	{ 74653, 1, 90, "BOTH" }, -- Steamed Crab Surprise
	{ 104341, 1, 90, "HEALTH" }, -- Steaming Goat Noodles
	{ 101749, 1, 90, "BOTH" }, -- Stuffed Lushrooms
	{ 81409, 1, 90, "HEALTH" }, -- Tangy Yogurt
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
	{ 58274, 1, 75, "MANA" }, -- Fresh Water
	{ 33445, 1, 75, "MANA" }, -- Honeymint Tea
	{ 39520, 1, 75, "MANA" }, -- Kungaloosh
	{ 59229, 1, 75, "MANA" }, -- Murky Water
	{ 43236, 1, 75, "MANA" }, -- Star's Sorrow
	{ 41731, 1, 75, "MANA" }, -- Yeti Milk
	{ 59230, 1, 80, "MANA" }, -- Fungus Squeezings
	{ 59029, 1, 80, "MANA" }, -- Greasy Whale Milk
	{ 58256, 1, 80, "MANA" }, -- Sparkling Oasis Water
	{ 62675, 1, 80, "MANA" }, -- Starfire Espresso
	{ 105702, 1, 85, "MANA" }, -- Boomer Brew
	{ 105705, 1, 85, "MANA" }, -- Chani's Bitter Brew
	{ 105711, 1, 85, "MANA" }, -- Funky Monkey Brew
	{ 74636, 1, 85, "MANA" }, -- Golden Carp Consomme
	{ 105701, 1, 85, "MANA" }, -- Greenstone Brew
	{ 58257, 1, 85, "MANA" }, -- Highland Spring Water
	{ 68140, 1, 85, "MANA" }, -- Invigorating Pineapple Punch
	{ 105700, 1, 85, "MANA" }, -- Kun-Lai Kicker
	{ 88532, 1, 85, "MANA" }, -- Lotus Water
	{ 63251, 1, 85, "MANA" }, -- Mei's Masterful Brew
	{ 74822, 1, 85, "MANA" }, -- Sasparilla Sinker
	{ 105706, 1, 85, "MANA" }, -- Shado-Pan Brew
	{ 105703, 1, 85, "MANA" }, -- Stormstout Brew
	{ 104348, 1, 85, "MANA" }, -- Timeless Tea
	{ 105707, 1, 85, "MANA" }, -- Unga Brew
	{ 85501, 1, 85, "MANA" }, -- Viseclaw Soup
	{ 105704, 1, 85, "MANA" }, -- Yan-Zhu's Blazing Brew
}

--[[
How We Got the Data

Last Validated
	2026-10-29, Mists of Pandaria Classic 5.5.4.70631

Notes
	- Food and drink a player can give away: Food & Drink consumables that restore health, mana
	  or both while the player sits, can be traded, aren't conjured, and need level 5 or more.
	- Level 5 is the floor because a consumable's recipients run from its use level up by
	  ns.Data.CONSUMABLE_RECIPIENT_GAP, and nobody under ns.Data.MIN_RECIPIENT_LEVEL (5)
	  receives anything (both in Data/Data.lua). Food needing less would reach nobody.
	- useLevel is the level the item requires on this client and quality its quality. restores
	  is HEALTH, MANA or BOTH, from what the item's use text says it restores, never from a
	  well-fed buff after it. It decides who can receive the food through
	  ns.Data.CONSUMABLE_CLASSES in this folder's Match-Classes file.
	- The query ran against a Wrath-era database and its spell categories file every food that
	  restores health and mana as HEALTH, so restores was corrected by hand from this client's
	  use text: 33825 Skullfish Soup restores only mana, and the Sagefish, Crab Claw, Manna
	  Biscuit, Terocone Juice, Buttered Trout, Northrend fish and feast rows restore both.
	- This client raises nine low rows' levels over the query's, and useLevel follows the client:
	  733, 1082, 2685, 5478, 5479 and 5526 need 15, 3728 and 20074 need 25, and 13546 needs 35.
	- 12217 Dragonbreath Chili and 33866 Stormchops restore nothing: their use is a melee buff.
	  Both are filed as HEALTH, which every class receives.
	- 43005 Spiced Mammoth Treats heals a hunter's pet, so it is filed as PET and reaches only
	  hunters. 27656 Sporeling Snack (level 0, Poor on this client) and 33874 Kibler's Bits
	  (level 1) also feed a pet, but are held out: their band tops out below the floor.
	- Held out besides: 43004 Critter Bites, which is Miscellaneous here and restores nothing, and
	  34770 Cooked Northrend Fish 12, which this client does not have.
	- Checked against this client's tables at 5.5.4.70631: Food & Drink, tradeable, not
	  conjured, level 5 or more, and an eat or drink effect that restores health or mana.
	  restores follows the spells the item casts outright, never the well-fed buff a timer
	  grants later. The Wrath-era query never saw Cataclysm's or Pandaria's food, so 151 rows
	  were added from that check, awaiting the next Validate Data run: every candidate
	  QuestieDB gives a drop, vendor or quest source, or a spell in the tables creates.
	- Held out from that check: drinks that make you drunk (62672 South Island Iced Tea, 75037
	  Jade Witch Brew, 104340 Crazy Snake Noodles; the ones that sober you up stay); retired,
	  test and internal items (4418, 29402, 76747, 85577 Tradeskill Food); and, as likely
	  unobtainable with no source in QuestieDB and no spell creating them, 12238, 49360,
	  49361, 49397, 49398, 49602, 49603, 74609, 81889, 81916 to 81924, 82448 to 82450, 90135,
	  98111, 98116, 98118 and 108920.

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
          AND it.RequiredLevel > 4   -- must clear ns.Data.MIN_RECIPIENT_LEVEL: a consumable's band
                                     -- is [useLevel, useLevel + CONSUMABLE_RECIPIENT_GAP], so
                                     -- anything lower tops out under the floor and reaches nobody
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
	https://wago.tools/db2/Item?build=5.5.4.70631
	https://wago.tools/db2/ItemSparse?build=5.5.4.70631
	https://wago.tools/db2/ItemEffect?build=5.5.4.70631
	https://wago.tools/db2/SpellEffect?build=5.5.4.70631
	https://wago.tools/db2/SpellName?build=5.5.4.70631
	https://wago.tools/db2/Spell?build=5.5.4.70631

QuestieDB
	https://raw.githubusercontent.com/Questie/QuestieDB/master/data/MoP/mopItemDB.lua
]]
