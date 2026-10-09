local _, ns = ...

if not ns.IS_DISCOVERY then
	return
end

-- [faction] = the class tokens that faction can roll
ns.Data.FACTION_CLASSES = {
	Alliance = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "DRUID" },
	Horde = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
}
