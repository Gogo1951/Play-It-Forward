local _, ns = ...

-- Reads ns.Data.SPECS and WEAPON_CLASS_ORDER as it loads, so it comes after the whole Data block.

--------------------------------------------------------------------------------
-- Stat Weights
--------------------------------------------------------------------------------

--[[
	A class weight runs 0 to 6, and Matcher contends on claim >= bestClaim * CLASS_SHARE: against a
	6, a 2 is only ever a fallback and a 3 contends on level. Tests/ pins the scale to CLASS_SHARE.
	Useful means the tree gears for the stat, never that it merely benefits (every class likes Stamina).
]]
local MAIN, USEFUL = 2, 1

ns.Data.STAT_WEIGHTS = {}
-- [class][stat] = true for every stat some spec the player has on builds around (lists it as main).
ns.Data.MAIN_STATS = {}

-- SPELL_POWER is never listed: a tree takes the better of its SPELL_DAMAGE and HEALING points.
local function SpecPoints(spec)
	local points = {}
	for _, stat in ipairs(spec.useful or {}) do
		points[stat] = USEFUL
	end
	for _, stat in ipairs(spec.main or {}) do
		points[stat] = MAIN
	end
	points.SPELL_POWER = math.max(points.SPELL_POWER or 0, points.SPELL_DAMAGE or 0, points.HEALING or 0)
	if points.SPELL_POWER == 0 then
		points.SPELL_POWER = nil
	end
	return points
end

function ns.Data.SpecEnabled(class, spec)
	-- One of your alts being judged by its own specs: see Matcher:VerdictForSpecs.
	local override = ns.Data.SpecOverride
	if override and override.class == class then
		return override.keys[spec.key] == true
	end
	local saved = ns.db and ns.db.profile.specs and ns.db.profile.specs[class]
	if saved and saved[spec.key] ~= nil then
		return saved[spec.key]
	end
	return not spec.off
end

function ns.Data.ClassHasRole(class, role)
	for _, spec in ipairs(ns.Data.SPECS[class] or {}) do
		if spec.role == role and ns.Data.SpecEnabled(class, spec) then
			return true
		end
	end
	return false
end

-- A class with every spec turned off is offered no gear; consumables do not ask.
function ns.Data.ClassEnabled(class)
	return ns.Data.STAT_WEIGHTS[class] ~= nil
end

--[[
	On a three-spec scale: main stats average over the enabled specs (Holy-only paladin = mage on
	Intellect); useful stats sum, shrunk only for a class with more than three specs.
]]
local SCALE_SPECS = 3
local scoreable

-- A verdict cached on a scanned item is not rebuilt with the weights: a spec change rescans too.
function ns.Data.RebuildStatWeights()
	wipe(ns.Data.STAT_WEIGHTS)
	wipe(ns.Data.MAIN_STATS)
	scoreable = nil
	for class, specs in pairs(ns.Data.SPECS) do
		local on = {}
		for _, spec in ipairs(specs) do
			if ns.Data.SpecEnabled(class, spec) then
				on[#on + 1] = spec
			end
		end
		local weights, main = {}, {}
		local usefulScale = math.min(1, SCALE_SPECS / #specs)
		for _, spec in ipairs(on) do
			for _, stat in ipairs(spec.main or {}) do
				main[stat] = true
			end
			for stat, points in pairs(SpecPoints(spec)) do
				local scale = (points == MAIN) and (SCALE_SPECS / #on) or usefulScale
				weights[stat] = (weights[stat] or 0) + points * scale
			end
		end
		if #on > 0 then
			ns.Data.STAT_WEIGHTS[class] = weights
			ns.Data.MAIN_STATS[class] = main
		end
	end
end

ns.Data.RebuildStatWeights()

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

-- Every score and coverage share reads stats through this, or "+1% hit" is noise beside "+10 Strength".
function ns.Data.StatPoints(stat, value)
	local budget = ns.Data.STAT_BUDGET
	return (value or 0) * ((budget and budget[stat]) or 1)
end

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
	Training levels are probed off NATIVE_ARMOR rather than listed twice; false when the class never
	gets there. MAX_PROBE must clear every level cap.
]]
local MAX_PROBE = 90
local trainedCache = {}

local function TrainedAt(class, itemWeight)
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

-- nil: never wearable, or trained more than PROFICIENCY_REACH (Data/Data.lua) past the item's level.
function ns.Data.ArmorEquipLevel(armorType, class, reqLevel)
	local itemWeight = ns.Data.ARMOR_WEIGHT[armorType]
	if not itemWeight or not ns.Data.NATIVE_ARMOR[class] then
		return nil
	end

	local level = math.max(1, reqLevel or 1)
	if (ns.Data.ARMOR_WEIGHT[ns.Data.NativeArmorAt(class, level) or ""] or 0) >= itemWeight then
		return level
	end

	local trains = TrainedAt(class, itemWeight)
	if not trains or (trains - level) > ns.Data.PROFICIENCY_REACH then
		return nil
	end
	return trains
end

--[[
	Group = native armor weight at the level the class equips this - item's weight + 1, so a
	hunter is group 1 for a level 36 mail belt as for a level 40 one.
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

local COLUMN = {}
for i, class in ipairs(ns.Data.WEAPON_CLASS_ORDER) do
	COLUMN[class] = i
end

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
	Weapons plus shields, held off-hands and relics. Never "WeaponKey returns something": cloth
	(armor subclass 1) collides with 2H axe (weapon subclass 1).
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

-- Later than the item's requirement only where the class must train the armor material first.
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
	-- Falls back rather than refusing: an ineligible class is already gone from verdict.admitted.
	return ns.Data.ArmorEquipLevel(armorType, classToken, req) or req
end

-- exclusive ignores unranked stats, or armor and resistances would pass a bare Stamina ring but not a chest.
local function Matches(rule, item, context)
	local def = item.def

	-- context exists only after scoring, so an unclaimed rule never matches for a veto.
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
	for _, token in ipairs(rule.without or {}) do
		if (stats[token] or 0) > 0 then
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

function ns.Data.VetoedClasses(item)
	local out = nil
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
		if (rule.veto or rule.vetoUnlessRole) and Matches(rule, item) then
			out = out or {}
			for _, class in ipairs(rule.veto or {}) do
				out[class] = true
			end
			-- Read live: which classes heal is the player's spec choice, not the rule's.
			if rule.vetoUnlessRole then
				for class in pairs(ns.Data.SPECS) do
					if not ns.Data.ClassHasRole(class, rule.vetoUnlessRole) then
						out[class] = true
					end
				end
			end
		end
	end
	return out
end

-- Every matching rule contributes, unlike prefer: two demotions can be true at once.
function ns.Data.DemotedClasses(item, context)
	local out = nil
	for _, rule in ipairs(ns.Data.ITEM_RULES) do
		if rule.demote and Matches(rule, item, context) then
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
		if rule.prefer and Matches(rule, item, context) then
			return rule.prefer, rule.name
		end
	end
	return nil
end
