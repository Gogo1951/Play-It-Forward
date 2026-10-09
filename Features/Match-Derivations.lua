local _, ns = ...

--[[
	The answers derived from the tables in Data/, living on ns.Data beside the tables they read:
	priority groups, weapon keys, and which classes a rule names. Features/Match-Engine.lua owns
	ns.Matcher and reads these.

	Load order is not load-bearing except for COLUMN below, which reads ns.Data.WEAPON_CLASS_ORDER as
	it loads and so must come after the flavor folder's Match-Weapons file.
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
	for _, weights in pairs(ns.Data.STAT_WEIGHTS) do
		for stat, points in pairs(weights) do
			if points and points > 0 then
				scoreable[stat] = true
			end
		end
	end
	return scoreable
end

--[[
	A stat's tooltip number in primary-stat points, through the flavor folder's
	ns.Data.STAT_BUDGET. Every score and every coverage share reads stats through this: "+1% hit"
	beside "+10 Strength" is a tenth of the item read raw and half of it converted.
]]
function ns.Data.StatPoints(stat, value)
	local budget = ns.Data.STAT_BUDGET
	return (value or 0) * ((budget and budget[stat]) or 1)
end

-- The armor a class wears at a level: the last NATIVE_ARMOR step at or below it, nil for an unknown class.
function ns.Data.NativeArmorAt(class, level)
	local steps = ns.Data.NATIVE_ARMOR[class]
	if not steps then
		return nil
	end
	local worn
	for _, step in ipairs(steps) do
		if level >= step[1] then
			worn = step[2]
		end
	end
	return worn
end

--[[
	The first level a class wears armor of at least this weight, PROBED OFF ns.Data.NATIVE_ARMOR
	rather than listed a second time: the 40s that gate mail and plate stay in the one table they
	are already written in. false when the class never gets there -- a rogue is leather for life.

	The ceiling is past every level cap these flavors have, so a step added above 60 is still
	found. Answered once per class and weight and cached; NATIVE_ARMOR is fixed at load.
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

	local found = false
	for level = 1, MAX_PROBE do
		if (ns.Data.ARMOR_WEIGHT[ns.Data.NativeArmorAt(class, level) or ""] or 0) >= itemWeight then
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
	local itemWeight = ns.Data.ARMOR_WEIGHT[armorType]
	if not itemWeight or not ns.Data.NATIVE_ARMOR[class] then
		return nil
	end

	local level = math.max(1, reqLevel or 1)
	if (ns.Data.ARMOR_WEIGHT[ns.Data.NativeArmorAt(class, level) or ""] or 0) >= itemWeight then
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
	local WEIGHT = ns.Data.ARMOR_WEIGHT
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
	for class in pairs(ns.Data.NATIVE_ARMOR) do
		local equipAt = ns.Data.ArmorEquipLevel(armorType, class, level)
		if equipAt then
			out[class] = WEIGHT[ns.Data.NativeArmorAt(class, equipAt)] - itemWeight + 1
		end
	end

	armorCache[armorType][level] = out
	return out
end

-- Index the columns once so lookups aren't a linear scan.
local COLUMN = {}
for i, class in ipairs(ns.Data.WEAPON_CLASS_ORDER) do
	COLUMN[class] = i
end

-- Priority group, or nil when the class cannot use the weapon.
function ns.Data.WeaponPriorityFor(weaponKey, classToken)
	local counts = ns.Data.WEAPON_SPECS[weaponKey]
	local column = COLUMN[classToken]
	if not counts or not column then
		return nil
	end

	local specs = counts[column] or 0
	if specs <= 0 then
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
	Weapons, plus shields, held off-hands and relics, which compete for a slot rather than a
	material.

	Not "does WeaponKey return something": WeaponKey falls through to the weapon subclass table,
	and armor subclass 1 (cloth) collides with weapon subclass 1 (2H axe), so a cloth chest
	answers "2H_AXE" and would take the weapon fallback.
]]
function ns.Data.UsesWeaponMatrix(item)
	if item.classID == 2 then
		return true
	end
	return item.classID == 4
		and (
			item.subclassID == 6
			or item.equipLoc == "INVTYPE_HOLDABLE"
			or ns.Data.RELIC_SUBCLASS[item.subclassID] ~= nil
		)
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
		local relic = ns.Data.RELIC_SUBCLASS[item.subclassID]
		if relic then
			item._weaponKey = relic
			return relic
		end
	end
	local key = ns.Data.WEAPON_SUBCLASS[item.subclassID]
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
]]
function ns.Data.EquipLevelFor(item, classToken)
	local req = math.max(1, item.reqLevel or 1)
	if item.classID ~= 4 or ns.Data.UsesWeaponMatrix(item) then
		return req
	end
	-- Rings, necks, trinkets and cloaks have no material to train.
	if ns.Data.UNIVERSAL_EQUIP_LOC[item.equipLoc] or item.subclassID == 0 then
		return req
	end
	local armorType = ns.Data.ARMOR_SUBCLASS[item.subclassID]
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

	if rule.armor then
		if item.classID ~= 4 or ns.Data.UNIVERSAL_EQUIP_LOC[item.equipLoc] then
			return false
		end
		local material = ns.Data.ARMOR_SUBCLASS[item.subclassID]
		local wanted = false
		for _, armorType in ipairs(rule.armor) do
			if material == armorType then
				wanted = true
			end
		end
		if not wanted then
			return false
		end
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
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
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
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
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
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
		if rule.prefer and matches(rule, item, context) then
			return rule.prefer, rule.name
		end
	end
	return nil
end
