local _, ns = ...

-- { id, quality, useLevel, restores }
ns.Data.POTIONS = {
	{ 858, 1, 3, "HEALTH" }, -- Lesser Healing Potion
	{ 4596, 1, 5, "HEALTH" }, -- Discolored Healing Potion
	{ 929, 1, 12, "HEALTH" }, -- Healing Potion
	{ 1710, 1, 21, "HEALTH" }, -- Greater Healing Potion
	{ 3928, 1, 35, "HEALTH" }, -- Superior Healing Potion
	{ 13446, 1, 45, "HEALTH" }, -- Major Healing Potion
	{ 32947, 1, 55, "HEALTH" }, -- Auchenai Healing Potion
	{ 23822, 1, 55, "HEALTH" }, -- Healing Potion Injector
	{ 33092, 1, 55, "HEALTH" }, -- Healing Potion Injector
	{ 32763, 1, 55, "HEALTH" }, -- Rulkster's Secret Sauce
	{ 22829, 1, 55, "HEALTH" }, -- Super Healing Potion
	{ 28100, 1, 55, "HEALTH" }, -- Volatile Healing Potion
	{ 2455, 1, 5, "MANA" }, -- Minor Mana Potion
	{ 3385, 1, 14, "MANA" }, -- Lesser Mana Potion
	{ 3827, 1, 22, "MANA" }, -- Mana Potion
	{ 6149, 1, 31, "MANA" }, -- Greater Mana Potion
	{ 13443, 1, 41, "MANA" }, -- Superior Mana Potion
	{ 13444, 1, 49, "MANA" }, -- Major Mana Potion
	{ 32948, 1, 55, "MANA" }, -- Auchenai Mana Potion
	{ 23823, 1, 55, "MANA" }, -- Mana Potion Injector
	{ 33093, 1, 55, "MANA" }, -- Mana Potion Injector
	{ 32762, 1, 55, "MANA" }, -- Rulkster's Brain Juice
	{ 22832, 1, 55, "MANA" }, -- Super Mana Potion
	{ 28101, 1, 55, "MANA" }, -- Unstable Mana Potion
	{ 31677, 1, 60, "MANA" }, -- Fel Mana Potion
	{ 2456, 1, 5, "BOTH" }, -- Minor Rejuvenation Potion
	{ 18253, 1, 50, "BOTH" }, -- Major Rejuvenation Potion
	{ 22850, 1, 65, "BOTH" }, -- Super Rejuvenation Potion
}

--[[
How We Got the Data

Last Validated
	2026-10-09, TBC Anniversary 2.5.6.69795

Notes
	- Healing, mana and rejuvenation potions a player can give away: Potion consumables that can
	  be traded, named for what they restore. Injectors and engineering-restricted potions are
	  in, because one a recipient can't drink is still a tradeable item.
	- Potions needing only level 1 are out: their recipient band tops out under
	  ns.Data.MIN_RECIPIENT_LEVEL (Data/Data.lua) and they would reach nobody.
	- useLevel is the level the potion requires and quality its quality. restores comes from
	  the name: Rejuvenation and Restore are BOTH, Healing and Health are HEALTH, Mana is MANA.
	  It decides who can receive the potion through ns.Data.CONSUMABLE_CLASSES in
	  Data/Data.lua. Features/Scan-Bags.lua reads every field.
	- 44728 Endless Rejuvenation Potion is held out by hand. It is the only quality 0 result
	  the query returns, an internal item the name exclusions match nothing in, and it returns
	  on every re-run: drop it again rather than reading it as new.
	- 32762 Rulkster's Brain Juice and 32763 Rulkster's Secret Sauce are added by hand. Their
	  names say neither Healing nor Mana, so the query files them as Other and drops them: add
	  them back after a re-run.

SQL (CMaNGOS)
	Database not recorded. It returned Wrath items, so it ran against a Wrath-era database,
	and each client's Validate Data run prunes what that client lacks.

    SELECT
        it.entry,
        it.name,
        it.Quality,
        it.RequiredLevel AS UseLevel,
        CASE
            WHEN it.name LIKE '%Rejuvenation%'
              OR it.name LIKE '%Restore%'        THEN 'Hybrid'   -- restores HP + mana
            WHEN it.name LIKE '%Healing%'
              OR it.name LIKE '%Health%'         THEN 'Heal'
            WHEN it.name LIKE '%Mana%'           THEN 'Mana'
            ELSE 'Other'
        END AS Kind
    FROM item_template it
    WHERE it.class    = 0        -- Consumable
      AND it.subclass = 1        -- Potion
      AND it.bonding  = 0        -- non-soulbound
      AND it.RequiredLevel <> 1  -- level-1 potions: band tops out below MIN_RECIPIENT_LEVEL
      AND it.name NOT LIKE '[PH]%'        -- placeholder
      AND it.name NOT LIKE 'Test %'       -- debug
      AND it.name NOT LIKE 'Deprecated %' -- retired
      AND it.name NOT LIKE 'DEPCREATED %' -- retired, misspelled upstream
    HAVING Kind <> 'Other'       -- keep only Heal / Mana / Hybrid
    ORDER BY Kind, UseLevel, it.name;

Wowhead
	None.

wago.tools
	https://wago.tools/db2/Item?build=2.5.6.69795
	https://wago.tools/db2/ItemSparse?build=2.5.6.69795
]]
