local _, ns = ...

ns.Alts = {}
local Alts = ns.Alts

--[[
	The player's own characters as a third source of recipients, ahead of the guild and /who in
	Matcher:RankCandidates. Entries enter the same pools through MatchList:AddResults in the same
	shape, flagged alt, which is what earns them their place in the ranking, the picker's Your Alts
	section, the exemption from one parcel per run and from the gift cooldown, and their absence
	from the Generosity tally.

	Each character records itself when it logs in, and again on every level up, in
	ns.db.global.characters: the only way to know an alt's class and level while it is logged out.
	An alt that has not logged in since this file shipped is not known yet. That is the honest
	limit, and the guild roster still keeps such an alt out of its own list.

	One the server refuses mail for is forgotten (Alts:Forget, from Features/Mail-Sender.lua): a
	deleted or renamed character would otherwise be offered first forever. If it still exists
	it records itself again at its next login, so nothing is lost for good. The My Alts
	panel forgets one the same way.

	THE PLAYER'S CHOICES LIVE ON THE SAME ENTRY: include, specs, levelsBelow and levelsAbove, set
	on that panel.
	A login rewrites what the character is -- level, class, spec -- and never those.
]]

--------------------------------------------------------------------------------
-- Recording
--------------------------------------------------------------------------------

--[[
	NAME AND REALM APART. The qualified form is the key, so it compares with every other source the
	way MatchList:AddResults dedupes them. The address is the bare name for an alt on this realm,
	exactly as UnitName gave it, and "Name-Realm" for one on a connected realm (Alts:Address).
]]
local Normalize, Realm = ns.NormalizeRealm, ns.PlayerRealm

--[[
	Which cluster of ns.Data.LINKED_REALMS each realm is in, keyed without spaces, hyphens or case
	so the data file can spell names as the realm list does. Built on first use: the data loads
	before this file, but the lookup is only wanted at the mailbox.
]]
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

--[[
	Whether mail from this realm reaches one on that realm: the same realm, or one in the same
	cluster of connected realms. Megaserver flavors list no clusters, so only the same realm does.
]]
function Alts:Connected(realm)
	local here = Realm()
	if realm == here then
		return true
	end
	local cluster = ClusterOf(realm)
	return cluster ~= nil and cluster == ClusterOf(here)
end

--[[
	This realm's cluster as the data file lists it, for the roster report to print beside the
	client's GetAutoCompleteRealms. Empty for a realm in no cluster.
]]
function Alts:LinkedRealms()
	local cluster = ClusterOf(Realm())
	return cluster and ns.Data.LINKED_REALMS[cluster] or {}
end

--[[
	Where mail to this alt goes. The realm suffix is the one the alt's own client gave at its last
	login (GetNormalizedRealmName, through Realm above), so it is still a name the client spelled.
]]
function Alts:Address(alt)
	if alt.realm == Realm() then
		return alt.name
	end
	return alt.name .. "-" .. alt.realm
end

--[[
	The spec this character plays, as its key in the flavor folder's Match-Specs file, or nil when
	it cannot tell: no points spent yet, or no API to ask. Mists picks a specialization, read
	directly -- from C_SpecializationInfo on Mists Classic, which has no global GetSpecialization
	and keeps GetNumTalentTabs only as a stub that throws "API unsupported". Every earlier flavor
	is read as the talent tree holding the most points. GetTalentTabInfo answers in two shapes --
	Classic Era leads with the name, the later clients with a numeric id, which moves the points
	from the third return to the fifth.
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

local function Record(level)
	if not ns.db then
		return
	end
	local name = UnitName("player")
	local _, classToken = UnitClass("player")
	if not name or name == "" or not classToken then
		return
	end
	local key = ns.QualifyPlayerName(name)
	local entry = ns.db.global.characters[key] or {}
	entry.name = name
	entry.realm = Realm()
	entry.class = classToken
	entry.level = level or UnitLevel("player")
	entry.faction = UnitFactionGroup("player")
	entry.spec = DetectSpec(classToken) or entry.spec
	ns.db.global.characters[key] = entry
end

--[[
	By the address the mail went to: a bare name is qualified with this realm, and one on a
	connected realm already carries its own, so either lands on the key it was recorded under.
]]
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

-- A respec at any point in the session is what the next panel read should show.
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

--[[
	The level cap on this client, or nil when it cannot say. GetMaxPlayerLevel answers the
	expansion's cap on every Classic client; MAX_PLAYER_LEVEL is the older global.
]]
local function MaxLevel()
	local cap = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or MAX_PLAYER_LEVEL
	return (type(cap) == "number" and cap > 0) and cap or nil
end

--[[
	Ticked below the level cap and unticked at it: a character at the cap has outgrown what this
	add-on gives away, so it is left out until the player ticks it. Read at its recorded level, so
	the default flips the session after it dings.
]]
function Alts:IncludedByDefault(alt)
	local cap = MaxLevel()
	return not (cap and (alt.level or 0) >= cap)
end

-- Whether the player has this alt ticked on the My Alts panel. Unset is the default above.
function Alts:Included(alt)
	if alt == nil then
		return false
	end
	if alt.include ~= nil then
		return alt.include
	end
	return self:IncludedByDefault(alt)
end

--[[
	How far below and above its own level this alt's gear may sit: the My Alts pane's Lowest and
	Highest dropdowns, saved as levelsBelow and levelsAbove and unset at the defaults.
]]
function Alts:LevelsBelow(alt)
	return alt and alt.levelsBelow or ns.ALT_LEVELS_BELOW_ORDER[1]
end

function Alts:LevelsAbove(alt)
	if alt and alt.levelsAbove ~= nil then
		return alt.levelsAbove
	end
	return ns.ALT_LEVELS_ABOVE_ORDER[#ns.ALT_LEVELS_ABOVE_ORDER]
end

-- The equip levels this alt is mailed gear at, from the level given or its recorded one. Any is math.huge.
function Alts:LevelRange(alt, level)
	level = level or (alt and alt.level) or 1
	local above = self:LevelsAbove(alt)
	local hi = (above == "ANY") and math.huge or level + above
	return math.max(1, level - self:LevelsBelow(alt)), hi
end

--[[
	The specs gear is mailed to this alt for, as a set of keys: the player's own ticks on the
	panel; else the spec the character last played, as it recorded at login; else, before it has
	one, every spec the class has. Never the class defaults: it is your own character, so what it
	actually plays is known, and the player widens or narrows it on the My Alts panel.
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

-- The recorded entry behind a pooled alt, read live so a change on the panel applies at once.
function Alts:Entry(person)
	return ns.db and person and person.altKey and ns.db.global.characters[person.altKey]
end

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------

--[[
	The last read's totals for the roster report, zeroed by Alts:Read: known, then why each left out
	was, then how many were offered and how many of those are on a connected realm.
]]
local counts = { known = 0, current = 0, otherRealm = 0, otherFaction = 0, excluded = 0, offered = 0, connected = 0 }

function Alts:Stats()
	return counts
end

--[[
	Why mail from here cannot reach this character, as its counts key, or nil when it can: it is
	the one logged in, on a realm outside this cluster, or on the other faction.
]]
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

-- Every recorded character mail from here reaches, by key, whether or not My Alts includes it.
local function Mailable()
	local out = {}
	if not ns.db then
		return out
	end
	local current = ns.QualifyPlayerName(UnitName("player"))
	local faction = UnitFactionGroup("player")
	for key, alt in pairs(ns.db.global.characters) do
		if not Unmailable(key, alt, current, faction) then
			out[key] = alt
		end
	end
	return out
end

--[[
	Every recorded character but this one, on this realm or a connected one and on this faction, in
	the shape /who results arrive in. Mail never crosses factions, nor realms outside the cluster,
	so those alts cannot be sent anything. No level floor here: ns.Data.MIN_RECIPIENT_LEVEL turns
	the low ones away for every source in MatchList:AddResults.
]]
function Alts:Read()
	local out = {}
	for key in pairs(counts) do
		counts[key] = 0
	end
	if not ns.db then
		return out
	end

	local current = ns.QualifyPlayerName(UnitName("player"))
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
	The character the What to Give Away panel's Disenchant Unmatched Items mails kept gear to. A
	choice, like include and specs, so it lives on the entry, as disenchanter = true. One per
	cluster and faction rather than one per profile: the Default profile is shared by every
	character on the account, and an enchanter on one cluster is out of mail's reach from every
	other. Picking one clears the flag on every other character mail from here reaches, so each
	cluster keeps its own, and the enchanter itself, logged in, simply has none.
]]

-- The characters the dropdown offers, as keys in name order, for its values and its sorting.
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

-- The chosen character mail from here reaches, as its key and entry, or nil. Read in name order, so two flagged agree.
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

--[[
	The chosen character in the shape Alts:Read gives, flagged disenchant so the window can say
	why it holds a row nobody matched. alt, so it is exempt from one parcel per run and the gift
	cooldown, and adds nothing to the Generosity totals, as mail to any of your characters is.
]]
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
