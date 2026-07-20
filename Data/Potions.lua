local _, ns = ...

--[[
	Same shape as Data/Food-And-Water.lua. Injectors and engineering-restricted potions are in
	because the query filters on class, subclass and bonding only; one a recipient cannot use
	is still a tradeable item.
]]

--[[
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
]]

--[[
	Entry 44728, Endless Rejuvenation Potion, is held out of the rows below by hand. It is the
	only quality 0 result the query returns, an internal item the name exclusions above match
	nothing in, and it returns on every re-run: drop it again rather than reading it as new.
]]

-- { id, quality, useLevel, restores }
ns.Data.Potions = {
	{ 858, 1, 3, "HEALTH" }, -- Lesser Healing Potion
	{ 4596, 1, 5, "HEALTH" }, -- Discolored Healing Potion
	{ 929, 1, 12, "HEALTH" }, -- Healing Potion
	{ 1710, 1, 21, "HEALTH" }, -- Greater Healing Potion
	{ 3928, 1, 35, "HEALTH" }, -- Superior Healing Potion
	{ 13446, 1, 45, "HEALTH" }, -- Major Healing Potion
	{ 43531, 1, 55, "HEALTH" }, -- Argent Healing Potion
	{ 32947, 1, 55, "HEALTH" }, -- Auchenai Healing Potion
	{ 23822, 1, 55, "HEALTH" }, -- Healing Potion Injector
	{ 33092, 1, 55, "HEALTH" }, -- Healing Potion Injector
	{ 22829, 1, 55, "HEALTH" }, -- Super Healing Potion
	{ 28100, 1, 55, "HEALTH" }, -- Volatile Healing Potion
	{ 39671, 1, 65, "HEALTH" }, -- Resurgent Healing Potion
	{ 41166, 1, 70, "HEALTH" }, -- Runic Healing Injector
	{ 33447, 1, 70, "HEALTH" }, -- Runic Healing Potion
	{ 2455, 1, 5, "MANA" }, -- Minor Mana Potion
	{ 3385, 1, 14, "MANA" }, -- Lesser Mana Potion
	{ 3827, 1, 22, "MANA" }, -- Mana Potion
	{ 6149, 1, 31, "MANA" }, -- Greater Mana Potion
	{ 13443, 1, 41, "MANA" }, -- Superior Mana Potion
	{ 13444, 1, 49, "MANA" }, -- Major Mana Potion
	{ 43530, 1, 55, "MANA" }, -- Argent Mana Potion
	{ 32948, 1, 55, "MANA" }, -- Auchenai Mana Potion
	{ 23823, 1, 55, "MANA" }, -- Mana Potion Injector
	{ 33093, 1, 55, "MANA" }, -- Mana Potion Injector
	{ 22832, 1, 55, "MANA" }, -- Super Mana Potion
	{ 28101, 1, 55, "MANA" }, -- Unstable Mana Potion
	{ 31677, 1, 60, "MANA" }, -- Fel Mana Potion
	{ 40067, 1, 65, "MANA" }, -- Icy Mana Potion
	{ 42545, 1, 70, "MANA" }, -- Runic Mana Injector
	{ 33448, 1, 70, "MANA" }, -- Runic Mana Potion
	{ 2456, 1, 5, "BOTH" }, -- Minor Rejuvenation Potion
	{ 18253, 1, 50, "BOTH" }, -- Major Rejuvenation Potion
	{ 22850, 1, 65, "BOTH" }, -- Super Rejuvenation Potion
	{ 40087, 1, 70, "BOTH" }, -- Powerful Rejuvenation Potion
}
