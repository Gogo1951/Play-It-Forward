local _, ns = ...

--[[
	The zones a /who is aimed at and where a candidate is standing, both read off the flavor
	folder's zone table. Features/Recipients-Who-Plan.lua plans queries with ns.Data.ZonesFor;
	the ranking and the search read Who:Placement.
]]

local Who = ns.Who

--------------------------------------------------------------------------------
-- Zone Search Order
--------------------------------------------------------------------------------

-- Each flavor folder's Recipients-Zones file holds the rows and the column legend; this is their only consumer.
local ZONE = ns.Data.ZONE_COLUMNS

--[[
	The area's name in the client's own language, which is what /who matches. Asked once per area
	and kept for the session; false marks an area this client has no name for, so its row is skipped
	rather than sent as an empty z-"".
]]
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
	Every zone worth asking about for a level band, best first. Ordering decides how many presses
	the search takes. Three keys:

	  overlap    how much of the band the zone covers
	  centrality how close the band sits to the middle of the zone's range -- the edge is where
	             people pass through, the middle is where they sit and quest. This is what puts
	             a Horde 21-22 search in the Barrens first.
	  width      narrower zone first among equals, for the same reason

	Popularity is not a key: there is no honest way to rank it from this table. Levels come back
	clipped to the overlap, so the query asks only what that zone can answer for.
]]
function ns.Data.ZonesFor(lo, hi)
	local faction = UnitFactionGroup("player")
	local bandMid = (lo + hi) / 2

	local out = {}
	for index, zone in ipairs(ns.Data.ZONES) do
		local from, to = math.max(zone[ZONE.MIN], lo), math.min(zone[ZONE.MAX], hi)
		--[[
			An unresolved faction admits every zone rather than none: over-including costs one
			empty query, excluding on a nil answer silently drops half the list.
		]]
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
	Where a candidate is standing, as the best evidence there is that they are levelling. Somebody
	out in a zone made for their level is questing their way up and will use the gift; somebody in
	a capital may be an alt parked at the bank, and somebody in a dungeon may be getting boosted
	through it. Four places, best first:

	  LEVELING   a zone in ns.Data.ZONES whose range fits their level, give or take the slack
	  UNKNOWN    no area reported (an offline guildmate), or a listed zone they have outgrown
	  ELSEWHERE  an area the zone table does not list: a capital, a battleground
	  INSTANCE   a dungeon or raid, by the client's own map list (InstanceNames below)

	How much each counts is the Recipients panel's call (Who:PlacementRank). None is excluded:
	the worst-placed candidate still beats nobody.
]]
Who.PLACED_LEVELING, Who.PLACED_UNKNOWN, Who.PLACED_ELSEWHERE, Who.PLACED_INSTANCE = 1, 2, 3, 4

--[[
	[localized name] = true for every dungeon and raid the flavor folder's INSTANCE_AREAS lists,
	built on first use. Named through AreaName, the same AreaTable record /who reports a player's
	zone by, never the uiMap list: Classic Era and WoW Forever ship no dungeon maps at all, and a
	map's name is a different record from the zone /who names.
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

-- [localized area name] = its ZONES row, built on first use: AreaName answers once per session.
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
	Placement as the candidate sort weighs it, lower first, by the Recipients panel's two switches
	under When Searching for Strangers:

	  Prioritize Strangers in Level-Appropriate Zones   LEVELING 0, UNKNOWN 1, ELSEWHERE and INSTANCE 2
	  Prioritize Strangers Not in Instances             INSTANCE 3 more, behind everybody else

	Both off, every placement ties and level decides.
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

--[[
	Whether a holder stands somewhere a better-placed find would beat: a capital or a dungeon, as
	the switches weigh them. An UNKNOWN holder ends the search -- that is mostly an offline
	guildmate, and pressing on for somebody one placement better is not worth the presses.
]]
function Who:KeepsSearching(person)
	return self:PlacementRank(person) >= SEARCH_ON_RANK
end
