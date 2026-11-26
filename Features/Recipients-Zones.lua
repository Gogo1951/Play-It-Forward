local _, ns = ...

local Who = ns.Who

--------------------------------------------------------------------------------
-- Zone Search Order
--------------------------------------------------------------------------------

-- The column legend lives in each flavor folder's Recipients-Zones file; this is its only consumer.
local ZONE = ns.Data.ZONE_COLUMNS

-- What /who matches, cached per session; false marks an area with no client name, skipped rather than sent as z-"".
local areaNames = {}

local function AreaName(areaID)
	local name = areaNames[areaID]
	if name == nil then
		name = C_Map.GetAreaInfo(areaID)
		if not name or name == "" then
			name = false
		end
		areaNames[areaID] = name
	end
	return name or nil
end

-- The exact read the zone filter makes, for the diagnostics Game Names report.
Who.AreaName = AreaName

--[[
	Best first, which decides how many presses a search takes: overlap, then centrality (the middle
	of a zone's range is where people quest, the edge where they pass through), then narrower.
	Popularity is not a key: there is no honest way to rank it from this table.
]]
function ns.Data.ZonesFor(lo, hi)
	local faction = UnitFactionGroup("player")
	local bandMid = (lo + hi) / 2

	local out = {}
	for index, zone in ipairs(ns.Data.ZONES) do
		local from, to = math.max(zone[ZONE.MIN], lo), math.min(zone[ZONE.MAX], hi)
		-- An unresolved faction admits every zone: over-including costs one empty query, excluding drops half the list.
		local rightSide = (zone[ZONE.FACTION] == nil) or (faction == nil) or (zone[ZONE.FACTION] == faction)
		local name = AreaName(zone[ZONE.AREA_ID])
		if from <= to and rightSide and name then
			out[#out + 1] = {
				name = name,
				lo = from,
				hi = to,
				overlap = to - from + 1,
				centrality = math.abs(bandMid - (zone[ZONE.MIN] + zone[ZONE.MAX]) / 2),
				width = zone[ZONE.MAX] - zone[ZONE.MIN],
				index = index,
			}
		end
	end

	table.sort(out, function(a, b)
		if a.overlap ~= b.overlap then
			return a.overlap > b.overlap
		end
		if a.centrality ~= b.centrality then
			return a.centrality < b.centrality
		end
		if a.width ~= b.width then
			return a.width < b.width
		end
		return a.index < b.index -- stable: table order among genuine equals
	end)
	return out
end

--------------------------------------------------------------------------------
-- Placement
--------------------------------------------------------------------------------

--[[
	Where a candidate stands, as evidence they are leveling. UNKNOWN is no area (an offline
	guildmate) or a listed zone their level does not fit; ELSEWHERE is any unlisted area, such as a
	capital. None is excluded: the worst-placed candidate still beats nobody.
]]
Who.PLACED_LEVELING, Who.PLACED_UNKNOWN, Who.PLACED_ELSEWHERE, Who.PLACED_INSTANCE = 1, 2, 3, 4

--[[
	Named through AreaName, never the uiMap list: Classic Era and WoW Forever ship no dungeon maps,
	and a map's name is a different record from the zone /who reports.
]]
local instanceNames

local function InstanceNames()
	if instanceNames then
		return instanceNames
	end
	instanceNames = {}
	for _, row in ipairs(ns.Data.INSTANCE_AREAS) do
		local name = AreaName(row[1])
		if name then
			instanceNames[name] = true
		end
	end
	return instanceNames
end

-- The same read, for the diagnostics Game Names report.
Who.InstanceNames = InstanceNames

-- People linger a level or two past a zone's top, and arrive a little under its bottom.
local ZONE_LEVEL_SLACK = 2

-- [localized area name] = its ZONES row, built on first use.
local zoneByName

function Who:Placement(person)
	local area = person and person.area
	if type(area) ~= "string" or area == "" then
		return Who.PLACED_UNKNOWN
	end
	if not zoneByName then
		zoneByName = {}
		for _, zone in ipairs(ns.Data.ZONES) do
			local name = AreaName(zone[ZONE.AREA_ID])
			if name then
				zoneByName[name] = zone
			end
		end
	end
	local zone = zoneByName[area]
	if not zone then
		return InstanceNames()[area] and Who.PLACED_INSTANCE or Who.PLACED_ELSEWHERE
	end
	local level = person.level or 0
	if level >= zone[ZONE.MIN] - ZONE_LEVEL_SLACK and level <= zone[ZONE.MAX] + ZONE_LEVEL_SLACK then
		return Who.PLACED_LEVELING
	end
	return Who.PLACED_UNKNOWN
end

--[[
	Lower first. Level-Appropriate Zones: LEVELING 0, UNKNOWN 1, ELSEWHERE and INSTANCE 2.
	Not in Instances: INSTANCE 3 more. Both off, every placement ties and level decides.
]]
local SEARCH_ON_RANK = 2

function Who:PlacementRank(person)
	local profile = ns.db and ns.db.profile or {}
	local placed = self:Placement(person)
	local rank = 0
	if profile.prioritizeLevelingZones ~= false then
		rank = math.min(placed, Who.PLACED_ELSEWHERE) - 1
	end
	if placed == Who.PLACED_INSTANCE and profile.prioritizeOutsideInstances ~= false then
		rank = rank + 3
	end
	return rank
end

-- An UNKNOWN holder, mostly an offline guildmate, ends the search: one placement better is not worth the presses.
function Who:KeepsSearching(person)
	return self:PlacementRank(person) >= SEARCH_ON_RANK
end
