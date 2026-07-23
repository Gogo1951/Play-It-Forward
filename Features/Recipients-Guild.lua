local _, ns = ...

ns.Guild = {}
local Guild = ns.Guild

--[[
	The guild roster as a second source of recipients, alongside the /who search in
	Features/Recipients-Who.lua. Results enter the same pools through MatchList:AddResults in the
	same shape, so nothing downstream knows where a candidate came from -- except the one flag that
	earns guildmates their tiebreak in Matcher:RankCandidates.

	It is cheap where /who is expensive: SendWho is hardware-event gated and throttled to one query
	per five seconds, so the search is a stepper riding button presses, while the roster answers
	for the whole guild at once.
]]

--------------------------------------------------------------------------------
-- Eligibility
--------------------------------------------------------------------------------

--[[
	How recently a member has to have logged in to be worth mailing. Someone who has not been on
	in longer is not going to read the mail before it expires, and their spot is better spent on
	somebody who will.

	Three days rather than a week (maintainer ruling, 2026-07): a guild this size has far more
	eligible members than there are items to hand out, so the tighter window costs nothing and
	the gear lands with somebody who is actually playing.
]]
local ACTIVE_DAYS = 3

-- Exposed so the roster report names the same number this file filters on.
Guild.ACTIVE_DAYS = ACTIVE_DAYS

--[[
	A guild warlock parked in this band is a summoning alt: Ritual of Summoning unlocks at 20, and
	they sit there rather than level on, so gear sent there is gear nobody wears. A range rather
	than the unlock level alone, because they drift a level or two before stopping (maintainer
	ruling, 2026-07-20). THIS RULE IS THE GUILD ROSTER'S ALONE: the same character found by /who is
	out in the world and playing, and nothing can tell a parked alt from a real one except which
	list named them.

	No level floor here, deliberately. The low levels are turned away for every source at once by
	ns.Data.MIN_RECIPIENT_LEVEL in Features/Match-List.lua; a second copy of that rule living here
	is how the guild floor and the consumable band drifted into each other the first time.
]]
local SUMMON_ALT_MIN_LEVEL = 20
local SUMMON_ALT_MAX_LEVEL = 23
local SUMMON_ALT_CLASS = "WARLOCK"

--[[
	GetGuildRosterLastOnline returns nothing at all for a member who is online right now, so that
	case is answered before it is asked. Offline it returns years, months, days and hours as
	components of one duration rather than totals, which is why "recent" is the first two being
	zero. No reading at all counts as too old: the roster arrives in pieces, and guessing "recent"
	on missing data mails gear to somebody who quit.
]]
local function activeRecently(index, online)
	if online then
		return true
	end
	local years, months, days = GetGuildRosterLastOnline(index)
	if not years then
		return false
	end
	return years == 0 and months == 0 and (days or 0) < ACTIVE_DAYS
end

--------------------------------------------------------------------------------
-- Names
--------------------------------------------------------------------------------

--[[
	NAMES GO INTO THE POOL EXACTLY AS THE ROSTER GAVE THEM, suffix and all. A name is an address:
	SendMail takes the full "Character-Realm" form, so rewriting it here -- stripping the player's
	own realm off, say -- means mailing to an address the client never gave us.
]]
local function packedRealm()
	local realm = GetRealmName and GetRealmName()
	if not realm or realm == "" then
		return nil
	end
	-- Suffixes carry no spaces, so "Blade's Edge" appears as "BladesEdge".
	return (realm:gsub("%s+", ""))
end

--[[
	The player's own characters, keyed in the form the roster names them. They are guildmates like
	any other, but mailing yourself is not paying anything forward; /who never raised this, since
	nobody is online on two characters at once.

	AceDB keeps profileKeys on ns.db.sv, never on ns.db. It holds a key per character that has ever
	loaded the add-on, written as "Character - Realm", spaces and all. Rebuilding that into the
	roster's "Character-Realm" is a COMPARISON KEY and nothing else. An alt that has never run the
	add-on is not in there and is not caught, which is the honest limit of this.
]]
local function ownCharacters()
	local out = {}
	local suffix = packedRealm()

	-- UnitName returns the player bare, so the realm is appended to match the roster's shape.
	local current = UnitName and UnitName("player")
	if current and suffix then
		out[current .. "-" .. suffix] = true
	end

	local keys = ns.db and ns.db.sv and ns.db.sv.profileKeys
	if not keys then
		return out
	end
	for key in pairs(keys) do
		local character, realm = key:match("^(.-)%s+%-%s+(.+)$")
		if character and realm then
			out[character .. "-" .. (realm:gsub("%s+", ""))] = true
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
	Session totals for the roster report. Every rejection is counted: "the guild added nobody" and
	"the guild has nobody active" look identical from the match list, and only one is a bug.
]]
local counts = { rows = 0, online = 0, stale = 0, summonAlts = 0, ownAlts = 0, unreadable = 0, eligible = 0 }

function Guild:Stats()
	return counts
end

--[[
	The whole roster, filtered, in the shape /who results arrive in. The class TOKEN is
	GetGuildRosterInfo's eleventh return, and the only one of its two class fields not localized.
]]
function Guild:Read()
	local out = {}
	for key in pairs(counts) do
		counts[key] = 0
	end

	if not IsInGuild or not IsInGuild() then
		return out
	end

	local mine = ownCharacters()
	local total = GetNumGuildMembers() or 0
	counts.rows = total

	for index = 1, total do
		local name, _, _, level, _, zone, _, _, online, _, classToken = GetGuildRosterInfo(index)
		if online then
			counts.online = counts.online + 1
		end

		-- Without the class token there is no way to tell whether they can wear the item.
		if not name or name == "" or not classToken then
			counts.unreadable = counts.unreadable + 1
		elseif mine[name] then
			-- Ahead of the other rules: one of yours is one of yours at any level or recency.
			counts.ownAlts = counts.ownAlts + 1
		elseif classToken == SUMMON_ALT_CLASS and level >= SUMMON_ALT_MIN_LEVEL and level <= SUMMON_ALT_MAX_LEVEL then
			counts.summonAlts = counts.summonAlts + 1
		elseif not activeRecently(index, online) then
			counts.stale = counts.stale + 1
		else
			counts.eligible = counts.eligible + 1
			out[#out + 1] = {
				-- Verbatim. This is the address the mail goes to.
				name = name,
				level = level,
				class = classToken,
				area = zone,
				-- The tiebreak in Matcher:RankCandidates, and the only trace of the source.
				guild = true,
			}
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
	-- C_GuildInfo.GuildRoster is the modern name; the bare global is the pre-9.0 one.
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	elseif GuildRoster then
		GuildRoster()
	end
	return true
end

ns.on("GUILD_ROSTER_UPDATE", function()
	if not pendingCallback then
		return
	end
	local callback = pendingCallback
	pendingCallback = nil
	callback(Guild:Read())
end)
