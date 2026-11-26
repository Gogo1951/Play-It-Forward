local ADDON_NAME, ns = ...

--------------------------------------------------------------------------------
-- Flavor
--------------------------------------------------------------------------------

-- From the TOC, never the client: WoW Forever's WOW_PROJECT_ID has already changed value once.
ns.FLAVOR = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-Flavor")

ns.EXPANSION = ({ Vanilla = 1, Camelot = 1, TBC = 2, Wrath = 3, Mists = 5, Mainline = 12 })[ns.FLAVOR]

-- Season of Discovery shares the Classic Era client, so no TOC can name it.
ns.IS_DISCOVERY = ns.FLAVOR == "Vanilla" and C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfDiscovery

ns.DATA_FOLDER = ns.IS_DISCOVERY and "Discovery" or ns.FLAVOR
