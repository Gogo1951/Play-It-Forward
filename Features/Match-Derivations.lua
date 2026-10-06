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
	The first level a class wears armor of at least this weight, PROBED OFF ns.Data.NativeArmor
	rather than listed a second time: the 40s that gate mail and plate stay in the one table they
	are already written in. false when the class never gets there -- a rogue is leather for life.

	The ceiling is past every level cap these flavors have, so a step added above 60 is still
	found. Answered once per class and weight and cached; NativeArmor is a pure function of level.
]]
local MAX_PROBE = 80
local trainedCache = {}

local function trainedAt(class, itemWeight)
	local byWeight = trainedCache[class]
	if not byWeight then
		byWeight = {}
		trainedCache[class] = byWeight
	end
	if byWeight[itemWeight] ~= nil then
		return byWeight[itemWeight]
	end

	local nativeFor = ns.Data.NativeArmor[class]
	local found = false
	for level = 1, MAX_PROBE do
		if (ns.Data.ArmorWeight[nativeFor(level) or ""] or 0) >= itemWeight then
			found = level
			break
		end
	end
	byWeight[itemWeight] = found
	return found
end

--[[
	The level this class could first equip an item of this armor type: the item's own requirement,
	or the level the class trains the material, whichever is later. nil means never -- it cannot
	wear the type at all, or the item is further below the training level than PROFICIENCY_REACH,
	where waiting for it is no longer a gift. See that constant in Data/Match-Armor.lua for why a
	later training level is not a disqualification.
]]
function ns.Data.ArmorEquipLevel(armorType, class, reqLevel)
	local itemWeight = ns.Data.ArmorWeight[armorType]
	local nativeFor = ns.Data.NativeArmor[class]
	if not itemWeight or not nativeFor then
		return nil
	end

	local level = math.max(1, reqLevel or 1)
	if (ns.Data.ArmorWeight[nativeFor(level) or ""] or 0) >= itemWeight then
		return level
	end

	local trains = trainedAt(class, itemWeight)
	if not trains or (trains - level) > ns.Data.PROFICIENCY_REACH then
		return nil
	end
	return trains
end

--[[
	Priority group = (class's native armor at the level it equips this) - (item's armor) + 1.
	Lighter natives cannot wear it at all and are left out; a class that trains the material
	within reach is grouped at the level it trains it, so a hunter is group 1 for a level 36
	mail belt exactly as he is for a level 40 one. No ordering inside a group.
]]
local armorCache = {}

function ns.Data.ArmorPriorityFor(armorType, reqLevel)
	local WEIGHT = ns.Data.ArmorWeight
	local itemWeight = WEIGHT[armorType]
	if not itemWeight then
		return nil
	end

	local level = math.max(1, reqLevel or 1)
	armorCache[armorType] = armorCache[armorType] or {}
	if armorCache[armorType][level] then
		return armorCache[armorType][level]
	end

	local out = {}
	for class, nativeFor in pairs(ns.Data.NativeArmor) do
		local equipAt = ns.Data.ArmorEquipLevel(armorType, class, level)
		if equipAt then
			out[class] = WEIGHT[nativeFor(equipAt)] - itemWeight + 1
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
	The level THIS class could equip THIS item at, which is what its recipient band is measured
	back from. The item's own requirement for nearly everything; later only where the armor matrix
	says the class has to train the material first, which is what sends a level 36 mail belt
	looking for hunters at 38 and 39 rather than at 34 and 35.

	The weapon matrix deliberately does not move it: ns.Data.WeaponMinLevel is "never in this
	flavor" written as a level, and shifting a band onto it would look for druids carrying
	polearms they cannot train.
]]
function ns.Data.EquipLevelFor(item, classToken)
	local req = math.max(1, item.reqLevel or 1)
	if item.classID ~= 4 or ns.Data.UsesWeaponMatrix(item) then
		return req
	end
	-- Rings, necks, trinkets and cloaks have no material to train.
	if ns.Data.UniversalEquipLoc[item.equipLoc] or item.subclassID == 0 then
		return req
	end
	local armorType = ns.Data.ArmorSubclass[item.subclassID]
	if not armorType then
		return req
	end
	--[[
		Falls back to the requirement rather than refusing: an ineligible class is already gone
		from verdict.admitted, so the only callers left are asking about a class that can wear it.
	]]
	return ns.Data.ArmorEquipLevel(armorType, classToken, req) or req
end

--[[
	Does the item carry every stat a rule asks for, and for an exclusive rule nothing else anybody
	ranks? Unranked stats do not count against exclusivity: armor and resistances sit on half the
	items in the game, so a bare Stamina ring would qualify where a bare Stamina chest does not.
]]
local function matches(rule, item, context)
	local def = item.def

	--[[
		The one thing a rule can ask about the scoring rather than the item: whether nobody had a
		claim on it. Matcher passes it after scoring, so a rule carrying this is never true for a
		veto, which is applied before anything is scored.
	]]
	if rule.unclaimed and not (context and context.unclaimed) then
		return false
	end

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
function ns.Data.DemotedClasses(item, context)
	local out = nil
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.demote and matches(rule, item, context) then
			out = out or {}
			for _, class in ipairs(rule.demote) do
				out[class] = true
			end
		end
	end
	return out
end

-- Classes the first matching rule names, or nil to let the point tables decide alone.
function ns.Data.PreferredClasses(item, context)
	for _, rule in ipairs(ns.Data.ItemRules) do
		if rule.prefer and matches(rule, item, context) then
			return rule.prefer, rule.name
		end
	end
	return nil
end
