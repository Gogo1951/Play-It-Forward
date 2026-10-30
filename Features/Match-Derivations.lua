local _, ns = ...

--[[
	The answers derived from the tables in Data/, living on ns.Data beside the tables they read:
	priority groups, weapon keys, and which classes a rule names. Features/Match-Engine.lua owns
	ns.Matcher and reads these.

	Load order is not load-bearing except where a table is read as this file loads: the stat
	weights below read the flavor folder's TALENT_TREES, and COLUMN reads WEAPON_CLASS_ORDER, so
	this file comes after the whole Data block.
]]

--------------------------------------------------------------------------------
-- Stat Weights
--------------------------------------------------------------------------------

--[[
	The flavor folder's ns.Data.SPECS, written per spec, summed here into the per-class
	ns.Data.STAT_WEIGHTS over the specs the player has left on. A class with no entry for a stat
	scores zero on it, and a class with every spec off has no weights at all and is offered no gear.

	THE RECIPIENT'S SPEC IS UNKNOWABLE, so the add-on assumes some. Paladins are assumed to
	heal or fight as Retribution, shamans to heal or cast, druids to heal or fight in Feral, and warriors not to level as Arms; the specs
	that rules out ship off, and the Recipients panel's Classes & Specs section turns any back on. Nobody levels on Defense, and
	defensive gear gets sharded rather than mailed: defense, dodge, parry, block and resistances are
	parsed and reported but weighted for nobody.

	THE POINTS. Per spec, a stat it builds around is main (2) and a stat that helps it is useful
	(1), and a class weight runs 0 to 6: Agility is main in all three rogue specs and weighs 6,
	Attack Power useful in all three weighs 3. Main stats are averaged over the specs that are on,
	so a paladin with only Holy on weighs 6 on Intellect, as committed to it as a mage. Useful
	stats are not: one spec's secondary is still one spec's, or a Restoration-only druid would
	weigh 3 on Spirit and lead on "of the Boar".

	THE RULE: useful means the tree gears for it, never that it merely benefits. Every class
	likes Stamina, which is why weighting it for all of them would say nothing about who an item
	is for. A binned suffix is a parse failure, not this rule.

	SPELL_POWER IS DERIVED, never listed. It is the unified "damage and healing" line, so a tree
	takes the better of its SPELL_DAMAGE and HEALING points for it.

	THE SCALE. A number means nothing on its own: Matcher buckets on claim >= bestClaim *
	CLASS_SHARE, putting the line at 2.1 against a 6.

	  6   every tree builds on it
	  4   two trees build on it (shaman and druid Intellect)
	  3   ABOVE the line: enters the top bucket, level proximity decides
	  2   BELOW the line: admitted and offered, never outranks a 6
	  1   admitted, effectively last

	The gap between 2 and 3 is one point and it is categorical: at 2 a warrior is a fallback on
	an Agility ring, at 3 he takes it off the rogue whenever he is a level closer. Tests/ pins
	the scale to CLASS_SHARE so an edit that crosses the line fails loudly. Two sums the trees
	would otherwise reach are held at 2 for exactly that reason; each says so where it sits.

	RAW TOOLTIP NUMBERS ARE NOT COMPARABLE, so nothing here is multiplied by one directly: "+1%
	hit" reads as 1 beside "+10 Strength". ns.Data.STAT_BUDGET, in each flavor folder, converts
	every stat to what it costs on an item first.
]]
local MAIN, USEFUL = 2, 1

ns.Data.STAT_WEIGHTS = {}
-- [class][stat] = true for every stat some spec the player has on builds around (lists it as main).
ns.Data.MAIN_STATS = {}

-- A stat listed as both main and useful in one spec counts once, as main.
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

--[[
	Whether the player counts this spec: their own choice on the Recipients panel's Classes & Specs section, or the
	flavor folder's default when they have not made one. Before saved variables load, the default.
]]
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

-- Whether any spec the player counts for this class plays the role: "HEALER", "TANK" and so on.
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
	THE SCALE IS WRITTEN FOR THREE SPECS. Main stats are averaged over the specs that are on and
	multiplied by three: a class with all three on is the plain sum, and a paladin with only Holy
	on reads as Holy three times over, so a hybrid the player says is a healer does not trail a
	mage on Intellect for having fewer specs on. Useful stats sum over the specs that are on,
	scaled down only for a class with more than three -- a Mists druid's four -- so a stat on two
	of its four weighs what "two of three" does and no more.
]]
local SCALE_SPECS = 3
local scoreable

--[[
	Rebuilt at load from the defaults, again once saved variables exist, and whenever the player
	changes a spec. Every cache that reads the weights is dropped with them; a verdict cached on a
	scanned item is not, so a caller that changes a spec rescans the bags too.
]]
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

--[[
	Every stat some class ranks, derived from the weight tables so a stat added there needs no
	second edit. Built on first use, so file load order is not load-bearing.
]]
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

--[[
	The level this class could first equip an item of this armor type: the item's own requirement,
	or the level the class trains the material, whichever is later. nil means never -- it cannot
	wear the type at all, or the item is further below the training level than PROFICIENCY_REACH,
	where waiting for it is no longer a gift. See that constant in Data/Data.lua for why a
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

	local trains = TrainedAt(class, itemWeight)
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
local function Matches(rule, item, context)
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

--[[
	Classes no rule will let this item reach. Applied before anything is scored, so a
	vetoed class is gone from every answer downstream rather than filtered out of some.
]]
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

--[[
	Classes that must not lead, though they may still receive. Every matching rule contributes,
	not just the first: a demotion names one class and one stat, and two can be true at once.
]]
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
