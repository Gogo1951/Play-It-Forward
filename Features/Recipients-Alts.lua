local _, ns = ...

ns.Alts = {}
local Alts = ns.Alts

--[[
	The player's choices live on the same entry as what the character is: include, specs,
	levelsBelow, levelsAbove, disenchanter. A login rewrites level, class and spec, never those.
]]

--------------------------------------------------------------------------------
-- Recording
--------------------------------------------------------------------------------

--[[
	The key is the qualified name, so it compares with every source as MatchList:AddResults
	dedupes; the address is separate (Alts:Address). On WoW Forever the name is "First Last".
]]
local Normalize, Realm = ns.NormalizeRealm, ns.PlayerRealm

-- Keyed without spaces, hyphens or case so the data file can spell realms as the realm list does.
local clusterOf

local function ClusterOf(realm)
	if not clusterOf then
		clusterOf = {}
		for index, cluster in ipairs(ns.Data.LINKED_REALMS or {}) do
			for _, name in ipairs(cluster) do
				clusterOf[Normalize(name):lower()] = index
			end
		end
	end
	return clusterOf[Normalize(realm):lower()]
end

-- Megaserver flavors list no clusters, so only the same realm connects.
function Alts:Connected(realm)
	local here = Realm()
	if realm == here then
		return true
	end
	local cluster = ClusterOf(realm)
	return cluster ~= nil and cluster == ClusterOf(here)
end

-- For the roster report, beside the client's GetAutoCompleteRealms.
function Alts:LinkedRealms()
	local cluster = ClusterOf(Realm())
	return cluster and ns.Data.LINKED_REALMS[cluster] or {}
end

-- The suffix is what the alt's own client gave at its last login, so it is still a name the client spelled.
function Alts:Address(alt)
	if alt.realm == Realm() then
		return alt.name
	end
	return alt.name .. "-" .. alt.realm
end

--[[
	Mists Classic has no global GetSpecialization, and its GetNumTalentTabs is a stub that throws.
	Earlier flavors take the most-pointed tree; GetTalentTabInfo leads with the name on Classic Era
	and a numeric id later, which moves the points from the third return to the fifth.
]]
local PICKS_SPECIALIZATION = ns.EXPANSION >= 5
local GetSpec = PICKS_SPECIALIZATION
	and ((C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization)

local function DetectSpec(classToken)
	local specs = ns.Data.SPECS[classToken]
	if not specs then
		return nil
	end
	if PICKS_SPECIALIZATION then
		local index = GetSpec and GetSpec()
		return index and specs[index] and specs[index].key or nil
	end
	if not (GetNumTalentTabs and GetTalentTabInfo) then
		return nil
	end
	local ok, numTabs = pcall(GetNumTalentTabs)
	if not ok or type(numTabs) ~= "number" then
		return nil
	end
	local best, bestPoints = nil, 0
	for tab = 1, numTabs do
		local info = { GetTalentTabInfo(tab) }
		local points = (type(info[1]) == "number") and info[5] or info[3]
		if type(points) == "number" and points > bestPoints and specs[tab] then
			best, bestPoints = specs[tab].key, points
		end
	end
	return best
end

-- MIGRATION (remove after 2026-12-05)
--[[
	FIRST NAMES GROWN INTO FULL ONES. Before surnames were read, a WoW Forever character recorded
	itself under UnitName's first name alone: "Gogobank", where mail and /who know "Gogobank Gogo".
	Such an entry is moved onto its full name, choices and all, so nothing the player set is lost.
	Where both exist -- the character logged in again since -- the fresh one is kept and only
	choices it never had are carried over.
]]
local CHOICES = { "include", "specs", "levelsBelow", "levelsAbove", "disenchanter" }

-- MIGRATION (remove after 2026-12-05)
local function Adopt(oldKey, newKey, fullName)
	local characters = ns.db.global.characters
	local old = characters[oldKey]
	if not old or oldKey == newKey then
		return
	end
	local entry = characters[newKey]
	if entry then
		for _, field in ipairs(CHOICES) do
			if entry[field] == nil then
				entry[field] = old[field]
			end
		end
	else
		entry = old
		characters[newKey] = entry
	end
	entry.name = fullName
	characters[oldKey] = nil
end

-- MIGRATION (remove after 2026-12-05)
--[[
	Every character on this realm still recorded by first name, given its full one where AceDB's
	profileKeys name exactly one "First Last" for it: AceDB keys a surname client's characters that
	way, so a character that loaded the add-on once is known in full before it logs in again.
]]
local function UpgradeFirstNames()
	local profileKeys = ns.db.sv and ns.db.sv.profileKeys
	if not profileKeys then
		return
	end
	local fullNames = {}
	for profileKey in pairs(profileKeys) do
		local first, last = profileKey:match("^(%S+) (%S+)$")
		if first then
			fullNames[first] = (fullNames[first] == nil) and (first .. " " .. last) or false
		end
	end
	local here, moves = Realm(), {}
	for key, alt in pairs(ns.db.global.characters) do
		local full = alt.name and alt.realm == here and fullNames[alt.name]
		if full then
			moves[key] = full
		end
	end
	for oldKey, full in pairs(moves) do
		Adopt(oldKey, ns.QualifyPlayerName(full), full)
	end
end

-- Full name where surnames are on, qualified like every other source.
local function CurrentKey()
	return ns.QualifyPlayerName(ns.PlayerName())
end

local function Record(level)
	if not ns.db then
		return
	end
	local name = ns.PlayerName()
	local _, classToken = UnitClass("player")
	if not name or name == "" or not classToken then
		return
	end
	local key = ns.QualifyPlayerName(name)
	if ns.UsesSurnames() then
		-- MIGRATION (remove after 2026-12-05)
		Adopt(ns.QualifyPlayerName(UnitName("player")), key, name)
		-- MIGRATION (remove after 2026-12-05)
		UpgradeFirstNames()
	end
	local entry = ns.db.global.characters[key] or {}
	entry.name = name
	entry.realm = Realm()
	entry.class = classToken
	entry.level = level or UnitLevel("player")
	entry.faction = UnitFactionGroup("player")
	entry.spec = DetectSpec(classToken) or entry.spec
	ns.db.global.characters[key] = entry
end

-- By the address the mail went to: qualifying it lands on the key it was recorded under.
function Alts:Forget(name)
	local key = ns.db and ns.QualifyPlayerName(name)
	if key then
		ns.db.global.characters[key] = nil
	end
end

local function OnPlayerLogin()
	Record()
end
ns.On("PLAYER_LOGIN", OnPlayerLogin)

local function OnCharacterPointsChanged()
	Record()
end
ns.On("CHARACTER_POINTS_CHANGED", OnCharacterPointsChanged)

-- Mists picks a spec rather than spending points into a tree, so a respec there fires this instead.
if PICKS_SPECIALIZATION then
	local function OnPlayerSpecializationChanged()
		Record()
	end
	ns.On("PLAYER_SPECIALIZATION_CHANGED", OnPlayerSpecializationChanged)
end

-- The event carries the new level: UnitLevel can still answer the old one while it fires.
local function OnPlayerLevelUp(level)
	Record(level)
end
ns.On("PLAYER_LEVEL_UP", OnPlayerLevelUp)

--------------------------------------------------------------------------------
-- The Player's Choices
--------------------------------------------------------------------------------

-- GetMaxPlayerLevel alone wherever it exists; MAX_PLAYER_LEVEL only on a client without it.
local function MaxLevel()
	local cap
	if type(GetMaxPlayerLevel) == "function" then
		cap = GetMaxPlayerLevel()
	else
		cap = MAX_PLAYER_LEVEL
	end
	return (type(cap) == "number" and cap > 0) and cap or nil
end

--[[
	Read at the recorded level, so the default flips the session after the ding. No level floor: a
	fresh level 1 alt is who the player wants to gear, and AddResults exempts alts from
	ns.Data.MIN_RECIPIENT_LEVEL. A bank alt is unticked once by hand.
]]
function Alts:IncludedByDefault(alt)
	local cap = MaxLevel()
	return not (cap and (alt.level or 0) >= cap)
end

-- Unset is the default above.
function Alts:Included(alt)
	if alt == nil then
		return false
	end
	if alt.include ~= nil then
		return alt.include
	end
	return self:IncludedByDefault(alt)
end

-- The My Alts Lowest and Highest dropdowns, unset at the defaults.
function Alts:LevelsBelow(alt)
	return alt and alt.levelsBelow or ns.ALT_LEVELS_BELOW_ORDER[1]
end

function Alts:LevelsAbove(alt)
	if alt and alt.levelsAbove ~= nil then
		return alt.levelsAbove
	end
	return ns.ALT_LEVELS_ABOVE_ORDER[#ns.ALT_LEVELS_ABOVE_ORDER]
end

-- "ANY" is math.huge.
function Alts:LevelRange(alt, level)
	level = level or (alt and alt.level) or 1
	local above = self:LevelsAbove(alt)
	local hi = (above == "ANY") and math.huge or level + above
	return math.max(1, level - self:LevelsBelow(alt)), hi
end

--[[
	The player's ticks, else the spec it last played, else every spec. Never the class defaults:
	what your own character plays is known.
]]
function Alts:SpecsFor(alt)
	local out = {}
	if alt.specs then
		for key, on in pairs(alt.specs) do
			if on then
				out[key] = true
			end
		end
		return out
	end
	local specs = ns.Data.SPECS[alt.class] or {}
	for _, spec in ipairs(specs) do
		if spec.key == alt.spec then
			out[spec.key] = true
			return out
		end
	end
	for _, spec in ipairs(specs) do
		out[spec.key] = true
	end
	return out
end

-- Read live so a change on the panel applies at once.
function Alts:Entry(person)
	return ns.db and person and person.altKey and ns.db.global.characters[person.altKey]
end

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------

-- The last read's totals for the roster report.
local counts = { known = 0, current = 0, otherRealm = 0, otherFaction = 0, excluded = 0, offered = 0, connected = 0 }

function Alts:Stats()
	return counts
end

local function Unmailable(key, alt, current, faction)
	if key == current then
		return "current"
	elseif not Alts:Connected(alt.realm) then
		return "otherRealm"
	elseif not faction or alt.faction ~= faction then
		return "otherFaction"
	end
	return nil
end

-- Whether or not My Alts includes it.
local function Mailable()
	local out = {}
	if not ns.db then
		return out
	end
	local current = CurrentKey()
	local faction = UnitFactionGroup("player")
	for key, alt in pairs(ns.db.global.characters) do
		if not Unmailable(key, alt, current, faction) then
			out[key] = alt
		end
	end
	return out
end

function Alts:Read()
	local out = {}
	for key in pairs(counts) do
		counts[key] = 0
	end
	if not ns.db then
		return out
	end

	local current = CurrentKey()
	local realm, faction = Realm(), UnitFactionGroup("player")
	for key, alt in pairs(ns.db.global.characters) do
		counts.known = counts.known + 1
		local why = Unmailable(key, alt, current, faction)
		if why then
			counts[why] = counts[why] + 1
		elseif not Alts:Included(alt) then
			counts.excluded = counts.excluded + 1
		else
			counts.offered = counts.offered + 1
			if alt.realm ~= realm then
				counts.connected = counts.connected + 1
			end
			out[#out + 1] = {
				name = Alts:Address(alt),
				level = alt.level,
				class = alt.class,
				alt = true,
				-- Where Alts:Entry finds the player's choices for this alt.
				altKey = key,
			}
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- The Disenchanter
--------------------------------------------------------------------------------

--[[
	On the character entry, not the profile: the shared Default profile serves every cluster, and an
	enchanter is out of mail's reach from all but its own. One per cluster and faction; the
	enchanter itself, logged in, has none.
]]

-- Keys in name order, for the dropdown's values and its sorting.
function Alts:DisenchantChoices()
	local keys = {}
	local mailable = Mailable()
	for key in pairs(mailable) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b)
		local nameA, nameB = mailable[a].name or "", mailable[b].name or ""
		if nameA ~= nameB then
			return nameA < nameB
		end
		return a < b
	end)
	return keys, mailable
end

-- Read in name order, so two flagged agree.
function Alts:Disenchanter()
	local keys, mailable = self:DisenchantChoices()
	for _, key in ipairs(keys) do
		if mailable[key].disenchanter then
			return key, mailable[key]
		end
	end
	return nil
end

function Alts:SetDisenchanter(chosen)
	for key, alt in pairs(Mailable()) do
		alt.disenchanter = (key == chosen) or nil
	end
end

-- disenchant lets the window say why it holds a row nobody matched; alt exempts it like any of your characters.
function Alts:DisenchantRecipient()
	local key, alt = self:Disenchanter()
	if not key then
		return nil
	end
	return {
		name = Alts:Address(alt),
		level = alt.level,
		class = alt.class,
		alt = true,
		altKey = key,
		disenchant = true,
	}
end
