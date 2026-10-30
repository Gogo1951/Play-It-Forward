local _, ns = ...

ns.Guild = {}
local Guild = ns.Guild

--[[
	The guild roster as a second source of recipients, alongside the /who search in
	Features/Recipients-Who.lua. Results enter the same pools through MatchList:AddResults in the
	same shape, so nothing downstream knows where a candidate came from -- except the one flag that
	ranks guildmates ahead of strangers in Matcher:RankCandidates.

	It is cheap where /who is expensive: SendWho is hardware-event gated and throttled to one query
	per five seconds, so the search is a stepper riding button presses, while the roster answers
	for the whole guild at once.
]]

--------------------------------------------------------------------------------
-- Eligibility
--------------------------------------------------------------------------------

--[[
	How long a member may have been offline and still be mailed: the My Guilds panel's Ignore
	Offline Guild Members, a key of this table in ns.GUILD_OFFLINE_ORDER. Someone away longer is
	not going to read the mail before it expires. NEVER has no limit and offers everyone.
]]
local OFFLINE_DAYS = { WEEK = 7, TWO_WEEKS = 14, NEVER = nil }
Guild.OFFLINE_DAYS = OFFLINE_DAYS

local DAY = 24 * 60 * 60

local function OfflineLimit()
	return OFFLINE_DAYS[ns.db and ns.db.profile.guildOfflineLimit or "WEEK"]
end

--[[
	Whether a member offline this many days is mailed. No reading at all counts as too long while
	there is a limit: the roster arrives in pieces, and guessing "recent" on missing data mails
	gear to somebody who quit.
]]
local function WithinLimit(days)
	local limit = OfflineLimit()
	if not limit then
		return true
	end
	return days ~= nil and days <= limit
end

--[[
	A guild warlock parked in this band is a summoning alt: Ritual of Summoning unlocks at 20, and
	they sit there rather than level on, so gear sent there is gear nobody wears. A range rather
	than the unlock level alone, because they drift a level or two before stopping.

	THIS RULE IS THE GUILD ROSTER'S ALONE: the same character found by /who is out in the world
	and playing, and nothing can tell a parked alt from a real one except which list named them.

	No level floor here, deliberately. The low levels are turned away for every source at once by
	ns.Data.MIN_RECIPIENT_LEVEL in Features/Match-Roster.lua, and a second copy of that rule here
	would drift from it.
]]
local SUMMON_ALT_MIN_LEVEL = 20
local SUMMON_ALT_MAX_LEVEL = 23
local SUMMON_ALT_CLASS = "WARLOCK"

--[[
	Days since the member was last online: 0 for online now, nil when the roster has no answer yet.
	GetGuildRosterLastOnline returns nothing at all for a member who is online right now, so that
	case is answered before it is asked. Offline it returns years, months, days and hours as
	components of one duration rather than totals, so they are summed here.
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
	NAMES GO INTO THE POOL EXACTLY AS THE ROSTER GAVE THEM, suffix and all. A name is an address:
	SendMail takes the full "Character-Realm" form, so rewriting it here -- stripping the player's
	own realm off, say -- means mailing to an address the client never gave us.

	Telling one person from another is a separate question, answered once in MatchList:AddResults
	against ns.QualifyPlayerName. No dedupe belongs here: a second one keyed differently is how a
	guildmate /who also found ends up pooled twice.
]]
--[[
	The player's own characters, keyed by qualified identity. They are guildmates like any other,
	but they belong in Your Alts, which Features/Recipients-Alts.lua fills from what each character
	recorded: kept out of this list, so one alt is never offered as a guildmate too.

	KEYED THROUGH ns.QualifyPlayerName, BOTH SIDES, and the lookup below qualifies the roster row
	the same way. Each source spells a name its own way -- UnitName bare, profileKeys as
	"Character - Realm", the roster as the client hands it -- so only the qualified form compares
	them, and a raw-string match misses your own alts and mails them your gear.

	AceDB keeps profileKeys on ns.db.sv, never on ns.db. It holds a key per character that has ever
	loaded the add-on, written as "Character - Realm", spaces and all. These are COMPARISON KEYS and
	nothing else. An alt that has never run the add-on is not in there and is not caught, which is
	the honest limit of this.
]]
local function OwnCharacters()
	local out = {}

	-- UnitName returns the player bare; the helper appends our realm, as it does for a roster row.
	local current = ns.QualifyPlayerName(UnitName and UnitName("player"))
	if current then
		out[current] = true
	end

	-- Every character that recorded itself (Features/Recipients-Alts.lua) is yours too.
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
			-- An unexpected key shape is matched whole rather than dropped.
			out[key] = true
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------

--[[
	The last read's totals for the roster report: Guild:Read zeroes them each time. Every
	rejection is counted: "the guild added nobody" and "the guild has nobody active" look
	identical from the match list, and only one is a bug. stale is offline past the limit.
]]
local counts =
	{ rows = 0, online = 0, stale = 0, summonAlts = 0, ownAlts = 0, ignored = 0, unreadable = 0, eligible = 0 }

function Guild:Stats()
	return counts
end

--------------------------------------------------------------------------------
-- Saved Guilds
--------------------------------------------------------------------------------

--[[
	Every guild any of your characters is in, saved account-wide in ns.db.global.guilds each time
	that character reads its roster -- at login, and at every Find Recipients -- so a character in
	no guild, or in a small one, still reaches the levelling players in your others. Mail never
	crosses realms or factions, so a saved guild is only read on its own realm and side.

	A SAVED ROSTER IS A PHOTOGRAPH, so a member's time offline is what it recorded plus the days
	since, and an old roster thins out on its own as its members age past the Ignore Offline Guild
	Members limit. The player's tick on the guild and the members they ignored live on the same
	entry, and a rescan keeps both.
]]

local Realm = ns.PlayerRealm

-- The saved guild's key: a guild name is unique only on its own realm and side.
function Guild:Key(name, realm, faction)
	return ("%s:%s:%s"):format(realm or "", faction or "", name or "")
end

-- The key of the guild this character is in now, or nil.
function Guild:CurrentKey()
	local name = IsInGuild and IsInGuild() and GetGuildInfo and GetGuildInfo("player")
	if not name or name == "" then
		return nil
	end
	return self:Key(name, Realm(), UnitFactionGroup("player"))
end

--[[
	Saves the roster this character can see right now, keeping the player's tick and ignores on the
	guild. Returns the entry it wrote and how many members are online, or nil when it wrote none.
	Rows without a name or a class token are left out: there is no way to tell what they can wear.
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
	local entry = ns.db.global.guilds[key] or {}
	entry.name = GetGuildInfo("player")
	entry.realm = Realm()
	entry.faction = UnitFactionGroup("player")
	entry.scanned = time()
	entry.scannedBy = UnitName("player")
	entry.members = members
	ns.db.global.guilds[key] = entry
	return entry, online
end

-- Whether the player has this guild ticked on the My Guilds panel. Unset is ticked.
function Guild:Included(entry)
	return entry ~= nil and entry.include ~= false
end

--[[
	Members the player ignored on the My Guilds panel -- a guild bank, an alt of somebody else's --
	kept as entry.ignored[qualified name] = true. Keyed by the qualified identity, the one spelling
	every roster read agrees on, so the ignore survives the rescan that replaces entry.members.
]]
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

-- A saved member's days offline as of today: what the roster recorded, plus the days since it was saved.
local function SavedDaysOffline(entry, member)
	if member.days == nil then
		return nil
	end
	return member.days + math.max(0, math.floor((time() - (entry.scanned or 0)) / DAY))
end

--[[
	Why a saved member is not mailed, as its counts key, or nil when they are. In this order: one of
	yours is one of yours at any level or recency, then the player's ignores, then the rules.
]]
local function Classify(entry, member, mine)
	if mine[ns.QualifyPlayerName(member.name)] then
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

--[[
	Members within the offline limit as of today. The player's ignores do not count against it, so
	the panel can still list somebody it ignored.
]]
local function Active(entry, member, mine)
	local why = Classify(entry, member, mine)
	return why == nil or why == "ignored"
end

local function Eligible(entry, member, mine)
	return Classify(entry, member, mine) == nil
end

-- A member in the shape /who results arrive in. The name is verbatim: it is the address.
local function AsCandidate(member)
	return {
		name = member.name,
		level = member.level,
		class = member.class,
		area = member.area,
		-- Where they rank in Matcher:RankCandidates, and the only trace of the source.
		guild = true,
	}
end

-- Members who would be mailed: active, and not ignored.
function Guild:ActiveCount(entry)
	local mine, count = OwnCharacters(), 0
	for _, member in ipairs(entry.members or {}) do
		if Eligible(entry, member, mine) then
			count = count + 1
		end
	end
	return count
end

--[[
	The members the My Guilds panel lists: everybody active, ignored or not, alphabetically.
	Inactive members are left off -- they are not mailed whatever the tick says -- unless they are
	ignored, so an ignore can always be taken back.
]]
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

--[[
	Whether a saved guild can be read from this character, and why not when it cannot: "realm" or
	"faction" for one mail cannot reach, "off" for one the player unticked. An old roster is not
	skipped whole: its members age out one by one. The guild this character is in is read live instead.
]]
function Guild:Usable(entry)
	if entry.realm ~= Realm() then
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

--[[
	Every usable saved guild's active members, in the shape /who results arrive in, leaving out
	the guild this character is in: Guild:Request reads that one live.
]]
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
					out[#out + 1] = AsCandidate(member)
				end
			end
		end
	end
	return out
end

--[[
	The whole roster, filtered, in the shape /who results arrive in. Saved for your other characters
	as it is read, then filtered from what was saved, so each member is read off the roster once.
	The class TOKEN is GetGuildRosterInfo's eleventh return, and the only one of its two class
	fields not localized.
]]
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

	local mine = OwnCharacters()
	for _, member in ipairs(entry.members) do
		local why = Classify(entry, member, mine)
		if why then
			counts[why] = counts[why] + 1
		else
			counts.eligible = counts.eligible + 1
			out[#out + 1] = AsCandidate(member)
		end
	end

	return out
end

--------------------------------------------------------------------------------
-- Requesting
--------------------------------------------------------------------------------

--[[
	Asks the server for a fresh roster and hands the result to one callback, mirroring Who:Step so
	UI-Mailbox wires both sources the same way. The callback is what gates the read:
	GUILD_ROSTER_UPDATE fires on its own constantly -- every login, logout, note edit and rank
	change -- and rereading the whole roster with a GetGuildRosterLastOnline call per row each time
	is work nobody asked for.
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

-- Whether a roster request is still waiting for its answer. Read by the diagnostics roster report.
function Guild:Pending()
	return pendingCallback ~= nil
end

--[[
	Every character saves its guild at login, so the account's guild list stays fresh on its own.
	The roster is asked for a few seconds in, once the client has the guild at all, and the first
	answer with members in it is saved.
]]
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
