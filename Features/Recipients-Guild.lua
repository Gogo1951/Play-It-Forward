local _, ns = ...

ns.Guild = {}
local Guild = ns.Guild

--------------------------------------------------------------------------------
-- Eligibility
--------------------------------------------------------------------------------

-- Keys of ns.GUILD_OFFLINE_ORDER. NEVER is nil: no limit, everyone offered.
local OFFLINE_DAYS = { WEEK = 7, TWO_WEEKS = 14, NEVER = nil }
Guild.OFFLINE_DAYS = OFFLINE_DAYS

local DAY = 24 * 60 * 60

local function OfflineLimit()
	return OFFLINE_DAYS[ns.db and ns.db.profile.guildOfflineLimit or "WEEK"]
end

-- No reading counts as too long while there is a limit: the roster arrives in pieces.
local function WithinLimit(days)
	local limit = OfflineLimit()
	if not limit then
		return true
	end
	return days ~= nil and days <= limit
end

--[[
	A guild warlock parked just past Ritual of Summoning (20) is a summoning alt. Roster-only: the
	same character found by /who is out in the world playing. No level floor here:
	ns.Data.MIN_RECIPIENT_LEVEL in MatchList:AddResults is the only one, and a copy would drift.
]]
local SUMMON_ALT_MIN_LEVEL = 20
local SUMMON_ALT_MAX_LEVEL = 23
local SUMMON_ALT_CLASS = "WARLOCK"

--[[
	GetGuildRosterLastOnline returns nothing for a member online now, and offline returns the
	components of one duration rather than totals.
]]
local function DaysOffline(index, online)
	if online then
		return 0
	end
	local years, months, days = GetGuildRosterLastOnline(index)
	if not years then
		return nil
	end
	return years * 365 + months * 30 + (days or 0)
end

--------------------------------------------------------------------------------
-- Names
--------------------------------------------------------------------------------

--[[
	Names go into the pool exactly as the roster gave them: a name is a SendMail address. People are
	told apart only in MatchList:AddResults, through ns.QualifyPlayerName; a second dedupe here,
	keyed differently, pools a guildmate /who also found twice.
]]
--[[
	Keyed through ns.QualifyPlayerName, both sides: UnitName, profileKeys and the roster each spell
	names their own way. profileKeys lives on ns.db.sv, never ns.db; an alt that has never loaded
	the add-on is not caught.
]]
local function OwnCharacters()
	local out = {}

	-- Bare ("First Last" on WoW Forever); the helper appends our realm, as it does for a roster row.
	local current = ns.QualifyPlayerName(ns.PlayerName())
	if current then
		out[current] = true
	end

	for key in pairs(ns.db and ns.db.global.characters or {}) do
		out[key] = true
	end

	local keys = ns.db and ns.db.sv and ns.db.sv.profileKeys
	if not keys then
		return out
	end
	for key in pairs(keys) do
		local character, realm = key:match("^(.-)%s+%-%s+(.+)$")
		if character and realm then
			out[character .. "-" .. ns.NormalizeRealm(realm)] = true
		else
			-- WoW Forever keys "First Last", no realm: qualified like a roster row. Any other shape is matched whole too.
			out[key] = true
			local qualified = ns.QualifyPlayerName(key)
			if qualified then
				out[qualified] = true
			end
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------

-- Every rejection counted: "the guild added nobody" and "nobody active" look the same from the match list.
local counts =
	{ rows = 0, online = 0, stale = 0, summonAlts = 0, ownAlts = 0, ignored = 0, unreadable = 0, eligible = 0 }

function Guild:Stats()
	return counts
end

--------------------------------------------------------------------------------
-- Saved Guilds
--------------------------------------------------------------------------------

--[[
	A saved roster is a photograph: a member's time offline is what it recorded plus the days since,
	so an old roster thins out on its own. The player's tick and ignores live on the same entry, and
	a rescan keeps both.
]]

local Realm = ns.PlayerRealm

-- A guild name is unique only on its own realm and side.
function Guild:Key(name, realm, faction)
	return ("%s:%s:%s"):format(realm or "", faction or "", name or "")
end

function Guild:CurrentKey()
	local name = IsInGuild and IsInGuild() and GetGuildInfo and GetGuildInfo("player")
	if not name or name == "" then
		return nil
	end
	return self:Key(name, Realm(), UnitFactionGroup("player"))
end

--[[
	Rows without a name or class token are left out: no way to tell what they can wear. The token is
	GetGuildRosterInfo's eleventh return, the only one of its two class fields not localized.
]]
function Guild:Save()
	local key = ns.db and self:CurrentKey()
	local total = GetNumGuildMembers and GetNumGuildMembers() or 0
	if not key or total == 0 then
		return nil, 0
	end
	local members, online = {}, 0
	for index = 1, total do
		local name, _, _, level, _, zone, _, _, isOnline, _, classToken = GetGuildRosterInfo(index)
		if isOnline then
			online = online + 1
		end
		if name and name ~= "" and classToken then
			members[#members + 1] = {
				name = name,
				level = level,
				class = classToken,
				area = zone,
				days = DaysOffline(index, isOnline),
			}
		end
	end
	local entry = ns.db.global.guilds[key]
	-- A guild added by name in other capitals is this one: taken over, ticks and ignores and all, so it is never listed twice.
	if not entry then
		local found, oldKey = self:Find(GetGuildInfo("player"))
		if found then
			ns.db.global.guilds[oldKey] = nil
			entry = found
		end
	end
	entry = entry or {}
	entry.name = GetGuildInfo("player")
	entry.realm = Realm()
	entry.faction = UnitFactionGroup("player")
	entry.scanned = time()
	entry.scannedBy = ns.PlayerName()
	entry.members = members
	ns.db.global.guilds[key] = entry
	return entry, online
end

-- Unset is ticked.
function Guild:Included(entry)
	return entry ~= nil and entry.include ~= false
end

-- Keyed by qualified name, the one spelling every roster read agrees on, so an ignore survives the rescan.
function Guild:Ignored(entry, name)
	local key = ns.QualifyPlayerName(name) or name
	return entry ~= nil and entry.ignored ~= nil and entry.ignored[key] == true
end

function Guild:SetIgnored(entry, name, ignored)
	local key = ns.QualifyPlayerName(name) or name
	if ignored then
		entry.ignored = entry.ignored or {}
		entry.ignored[key] = true
	elseif entry.ignored then
		entry.ignored[key] = nil
		if next(entry.ignored) == nil then
			entry.ignored = nil
		end
	end
end

local function SavedDaysOffline(entry, member)
	if member.days == nil then
		return nil
	end
	return member.days + math.max(0, math.floor((time() - (entry.scanned or 0)) / DAY))
end

--[[
	A bare name in a guild saved on a connected realm is that realm's character, so it takes the
	guild's realm, as Alts:Address does; bare, it would address somebody on this realm.
]]
local function Address(entry, member)
	local name = member.name
	if not name or name:find("-", 1, true) or not entry.realm or entry.realm == Realm() then
		return name
	end
	return name .. "-" .. entry.realm
end

-- Why a member is not mailed, as its counts key. In order: one of yours at any level or recency, ignores, the rules.
local function Classify(entry, member, mine)
	if mine[ns.QualifyPlayerName(Address(entry, member))] then
		return "ownAlts"
	end
	if Guild:Ignored(entry, member.name) then
		return "ignored"
	end
	if
		member.class == SUMMON_ALT_CLASS
		and member.level >= SUMMON_ALT_MIN_LEVEL
		and member.level <= SUMMON_ALT_MAX_LEVEL
	then
		return "summonAlts"
	end
	if not WithinLimit(SavedDaysOffline(entry, member)) then
		return "stale"
	end
	return nil
end

-- Ignores do not count against activity, so the panel can still list somebody it ignored.
local function Active(entry, member, mine)
	local why = Classify(entry, member, mine)
	return why == nil or why == "ignored"
end

local function Eligible(entry, member, mine)
	return Classify(entry, member, mine) == nil
end

-- guildName rides along so MatchList:RecheckGuildmates can ask again after My Guilds changes.
local function AsCandidate(member, entry)
	return {
		name = Address(entry, member),
		level = member.level,
		class = member.class,
		area = member.area,
		-- Where they rank in Matcher:RankCandidates, and the only trace of the source.
		guild = true,
		guildName = entry.name,
	}
end

function Guild:ActiveCount(entry)
	local mine, count = OwnCharacters(), 0
	for _, member in ipairs(entry.members or {}) do
		if Eligible(entry, member, mine) then
			count = count + 1
		end
	end
	return count
end

-- Inactive members are left off unless ignored, so an ignore can always be taken back.
function Guild:ListedMembers(entry)
	local mine, out = OwnCharacters(), {}
	for _, member in ipairs(entry.members or {}) do
		if Active(entry, member, mine) or self:Ignored(entry, member.name) then
			out[#out + 1] = member
		end
	end
	table.sort(out, function(a, b)
		return (a.name or "") < (b.name or "")
	end)
	return out
end

-- An old roster is never skipped whole: its members age out one by one.
function Guild:Usable(entry)
	if entry.removed then
		return false, "removed"
	end
	if not ns.Alts:Connected(entry.realm) then
		return false, "realm"
	end
	if entry.faction ~= UnitFactionGroup("player") then
		return false, "faction"
	end
	if not self:Included(entry) then
		return false, "off"
	end
	return true
end

-- Leaves out the guild this character is in: Guild:Read reads that one live.
function Guild:ReadSaved()
	local out = {}
	if not ns.db then
		return out
	end
	local current, mine = self:CurrentKey(), OwnCharacters()
	for key, entry in pairs(ns.db.global.guilds) do
		if key ~= current and self:Usable(entry) then
			for _, member in ipairs(entry.members or {}) do
				if Eligible(entry, member, mine) then
					out[#out + 1] = AsCandidate(member, entry)
				end
			end
		end
	end
	return out
end

-- Saved for your other characters as it is read, then filtered from what was saved.
function Guild:Read()
	local out = {}
	for key in pairs(counts) do
		counts[key] = 0
	end

	if not IsInGuild or not IsInGuild() then
		return out
	end
	local entry, online = self:Save()
	counts.rows = GetNumGuildMembers() or 0
	counts.online = online
	if not entry then
		return out
	end
	counts.unreadable = counts.rows - #entry.members
	-- Unticked or removed on My Guilds: saved for the panel, but nobody in it is offered anything.
	if not self:Usable(entry) then
		return out
	end

	local mine = OwnCharacters()
	for _, member in ipairs(entry.members) do
		local why = Classify(entry, member, mine)
		if why then
			counts[why] = counts[why] + 1
		else
			counts.eligible = counts.eligible + 1
			out[#out + 1] = AsCandidate(member, entry)
		end
	end

	return out
end

--------------------------------------------------------------------------------
-- Guilds Added by Name
--------------------------------------------------------------------------------

--[[
	Only a member can read a roster, so a guild added by name has none: Who:Plan asks g-"Name" for
	it and Guild:WhoLookup ranks the answers as guildmates. Removing a guild one of your characters
	is in only flags it removed, since that character would save it again at its next login.
]]

-- One spelling for comparing guild names: trimmed, inner spaces collapsed, lower case.
local function NameKey(name)
	local trimmed = (name or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
	if trimmed == "" then
		return nil
	end
	return trimmed:lower(), trimmed
end

-- The saved entry for a guild name on this realm and side, whatever its capitals, and its key.
function Guild:Find(name)
	local wanted = NameKey(name)
	if not wanted or not ns.db then
		return nil
	end
	local realm, faction = Realm(), UnitFactionGroup("player")
	for key, entry in pairs(ns.db.global.guilds) do
		if entry.realm == realm and entry.faction == faction and NameKey(entry.name) == wanted then
			return entry, key
		end
	end
	return nil
end

function Guild:Add(text)
	if not ns.db then
		return 0
	end
	local changed = 0
	for piece in (text or ""):gmatch("[^,;\n]+") do
		local _, name = NameKey(piece)
		if name then
			local entry = self:Find(name)
			if entry then
				if entry.removed or entry.include == false then
					entry.removed, entry.include = nil, nil
					changed = changed + 1
				end
			else
				local key = self:Key(name, Realm(), UnitFactionGroup("player"))
				ns.db.global.guilds[key] = {
					name = name,
					realm = Realm(),
					faction = UnitFactionGroup("player"),
					added = true,
					members = {},
				}
				changed = changed + 1
			end
		end
	end
	return changed
end

function Guild:Remove(key)
	local entry = ns.db and ns.db.global.guilds[key]
	if not entry then
		return
	end
	if entry.added and not entry.scanned then
		ns.db.global.guilds[key] = nil
	else
		entry.removed = true
	end
end

function Guild:ByNameOnly(entry)
	return entry ~= nil and entry.added == true and not entry.scanned
end

-- Alphabetical, so the plan is the same each time.
function Guild:SearchNames()
	local out = {}
	if not ns.db then
		return out
	end
	for _, entry in pairs(ns.db.global.guilds) do
		if self:ByNameOnly(entry) and self:Usable(entry) then
			out[#out + 1] = entry.name
		end
	end
	table.sort(out)
	return out
end

--[[
	Answers guildmate, ignored for a /who result. An ignore holds in any saved guild, usable or not,
	so unticking or removing a guild never hands its ignored members back as strangers. Built once
	per answer, so fifty results cost one pass over the saved guilds.
]]
function Guild:WhoLookup()
	local byName = {}
	if ns.db then
		for _, entry in pairs(ns.db.global.guilds) do
			local wanted = NameKey(entry.name)
			if wanted then
				byName[wanted] = byName[wanted] or {}
				table.insert(byName[wanted], entry)
			end
		end
	end
	return function(guildName, playerName)
		local guildmate, ignored = false, false
		for _, entry in ipairs(byName[NameKey(guildName) or ""] or {}) do
			guildmate = guildmate or (self:Usable(entry) and true or false)
			ignored = ignored or self:Ignored(entry, playerName)
		end
		return guildmate, ignored
	end
end

--------------------------------------------------------------------------------
-- Requesting
--------------------------------------------------------------------------------

--[[
	The callback gates the read: GUILD_ROSTER_UPDATE fires constantly (logins, note edits, rank
	changes), and each read costs a GetGuildRosterLastOnline per row.
]]
local pendingCallback = nil

function Guild:Request(callback)
	if not IsInGuild or not IsInGuild() then
		return false
	end
	pendingCallback = callback
	C_GuildInfo.GuildRoster()
	return true
end

-- For the diagnostics roster report.
function Guild:Pending()
	return pendingCallback ~= nil
end

-- Every character saves its guild at login: asked a few seconds in, saved from the first answer with members.
local saveAtLogin = false

local function OnPlayerLogin()
	saveAtLogin = true
	C_Timer.After(5, function()
		if IsInGuild and IsInGuild() then
			C_GuildInfo.GuildRoster()
		end
	end)
end
ns.On("PLAYER_LOGIN", OnPlayerLogin)

local function OnGuildRosterUpdate()
	if saveAtLogin and (GetNumGuildMembers and GetNumGuildMembers() or 0) > 0 then
		saveAtLogin = false
		Guild:Save()
	end
	if not pendingCallback then
		return
	end
	local callback = pendingCallback
	pendingCallback = nil
	callback(Guild:Read())
end
ns.On("GUILD_ROSTER_UPDATE", OnGuildRosterUpdate)
