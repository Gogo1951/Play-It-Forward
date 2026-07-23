local _, ns = ...

--[[
	The answers derived from the tables in Data/, living on ns.Data beside the tables they read:
	priority groups, weapon keys, and which classes a rule names. Features/Match-Engine.lua owns
	ns.Matcher and reads these.

	FUNCTIONS OVER THE TABLES, WHICH IS WHY THIS IS NOT IN Data/. Everything there is a table, read
	at load time and never called. Data/Match-Weapons.lua points at this file for that reason.

	Load order is not load-bearing except for COLUMN below, which reads ns.Data.WeaponClassOrder as
	it loads and so must come after Data/Match-Weapons.lua.
]]

--[[
	Every stat some class ranks, derived from the weight tables so a stat added there needs no
	second edit. Built on first use, so file load order is not load-bearing.
]]
local scoreable
function ns.Data.ScoreableStats()
	if scoreable then
		return scoreable
	end
	scoreable = {}
	for _, weights in pairs(ns.Data.StatWeights) do
		for stat, points in pairs(weights) do
			if points and points > 0 then
				scoreable[stat] = true
			end
		end
	end
	return scoreable
end

--[[
	Priority group = (class's native armor) - (item's armor) + 1; lighter natives cannot wear it
	at all, so plate under 40 lists nobody. Native armor is level-dependent: hunters and shamans
	are leather until 40, warriors and paladins mail. No ordering inside a group.
]]
local armorCache = {}

function ns.Data.ArmorPriorityFor(armorType, reqLevel)
	local WEIGHT = ns.Data.ArmorWeight
	local itemWeight = WEIGHT[armorType]
	if not itemWeight then
		return nil
	end

	local level = reqLevel or 1
	armorCache[armorType] = armorCache[armorType] or {}
	if armorCache[armorType][level] then
		return armorCache[armorType][level]
	end

	local out = {}
	for class, nativeFor in pairs(ns.Data.NativeArmor) do
		local classWeight = WEIGHT[nativeFor(level) or ""]
		if classWeight and classWeight >= itemWeight then
			out[class] = classWeight - itemWeight + 1
		end
	end

	armorCache[armorType][level] = out
	return out
end

-- Index the columns once so lookups aren't a linear scan.
local COLUMN = {}
for i, class in ipairs(ns.Data.WeaponClassOrder) do
	COLUMN[class] = i
end

--[[
	Priority group, or nil when the class cannot use the weapon. Eligibility is "did this return a
	number", so a level rule cannot reach the grouping and miss the eligibility check.
]]
function ns.Data.WeaponPriorityFor(weaponKey, classToken, reqLevel)
	local counts = ns.Data.WeaponSpecs[weaponKey]
	local column = COLUMN[classToken]
	if not counts or not column then
		return nil
	end

	local specs = counts[column] or 0
	if specs <= 0 then
		return nil
	end

	local gates = ns.Data.WeaponMinLevel[classToken]
	local minLevel = gates and gates[weaponKey]
	if minLevel and (reqLevel or 1) < minLevel then
		return nil
	end

	return 4 - specs
end

-- Blizzard's weapon subclass does not distinguish 1H from 2H swords, maces or axes; equipLoc does.
ns.Data.ResolveHandedness = function(key, equipLoc)
	local twoH = (equipLoc == "INVTYPE_2HWEAPON")
	if key == "1H_SWORD" or key == "2H_SWORD" then
		return twoH and "2H_SWORD" or "1H_SWORD"
	end
	if key == "1H_MACE" or key == "2H_MACE" then
		return twoH and "2H_MACE" or "1H_MACE"
	end
	if key == "1H_AXE" or key == "2H_AXE" then
		return twoH and "2H_AXE" or "1H_AXE"
	end
	return key
end

--[[
	Weapons, plus shields and held off-hands, which compete for a slot rather than a material.

	Not "does WeaponKey return something": WeaponKey falls through to the weapon subclass table,
	and armor subclass 1 (cloth) collides with weapon subclass 1 (2H axe), so a cloth chest
	answers "2H_AXE" and would take the weapon fallback.
]]
function ns.Data.UsesWeaponMatrix(item)
	if item.classID == 2 then
		return true
	end
	return item.classID == 4 and (item.subclassID == 6 or item.equipLoc == "INVTYPE_HOLDABLE")
end

-- The weapon key for an item, resolving handedness. Cached on the item.
function ns.Data.WeaponKey(item)
	if item._weaponKey then
		return item._weaponKey
	end
	if item.classID == 4 then
		if item.subclassID == 6 then
			item._weaponKey = "SHIELD"
			return "SHIELD"
		end
		if item.equipLoc == "INVTYPE_HOLDABLE" then
			item._weaponKey = "HELD"
			return "HELD"
		end
	end
	local key = ns.Data.WeaponSubclass[item.subclassID]
	if not key then
		return nil
	end
	key = ns.Data.ResolveHandedness(key, item.equipLoc)
	item._weaponKey = key
	return key
end

--[[
	Does the item carry every stat a rule asks for, and for an exclusive rule nothing else anybody
	ranks? Unranked stats do not count against exclusivity: armor and resistances sit on half the
	items in the game, so a bare Stamina ring would qualify where a bare Stamina chest does not.
]]
local function matches(rule, item)
	local def = item.def

	-- classID == 2 first: cloth collides with 2H axe, see UsesWeaponMatrix above.
	if rule.weapon then
		if item.classID ~= 2 then
			return false
		end
		local key = ns.Data.WeaponKey(item)
		for _, wanted in ipairs(rule.weapon) do
			if key == wanted then
				return true
			end
		end
		return false
	end

	if rule.form or rule.restores then
		if not def or def.form ~= rule.form then
			return false
		end
		local wanted = false
		for _, restores in ipairs(rule.restores or {}) do
			if def.restores == restores then
				wanted = true
			end
		end
		return wanted
	end
	if not rule.requires then
		return false
	end

	local stats = item.stats or {}
	for _, token in ipairs(rule.requires) do
		if (stats[token] or 0) <= 0 then
			return false
		end
	end

	if not rule.exclusive then
		return true
	end

	local required = {}
	for _, token in ipairs(rule.requires) do
		required[token] = true
	end
	local ranked = ns.Data.ScoreableStats()
	for token, value in pairs(stats) do
		if not required[token] and ranked[token] and (value or 0) > 0 then
			return false
		end
	end
	return true
end

--[[
	Classes no rule will let this item reach. Applied before anything is scored, so a
	vetoed class is gone from every answer downstream rather than filtered out of some.
]]
function ns.Data.VetoedClasses(item)
	local out = nil
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.veto and matches(rule, item) then
			out = out or {}
			for _, class in ipairs(rule.veto) do
				out[class] = true
			end
		end
	end
	return out
end

--[[
	Classes that must not lead, though they may still receive. Every matching rule contributes,
	not just the first: a demotion names one class and one stat, and two can be true at once.
]]
function ns.Data.DemotedClasses(item)
	local out = nil
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.demote and matches(rule, item) then
			out = out or {}
			for _, class in ipairs(rule.demote) do
				out[class] = true
			end
		end
	end
	return out
end

-- Classes the first matching rule names, or nil to let the point tables decide alone.
function ns.Data.PreferredClasses(item)
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.prefer and matches(rule, item) then
			return rule.prefer, rule.name
		end
	end
	return nil
end
