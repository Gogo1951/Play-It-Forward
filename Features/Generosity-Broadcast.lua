local _, ns = ...

--[[
	Shares this account's Given Away totals with nearby Play It Forward users and caches what theirs
	report, so Features/Generosity-Tooltip.lua can show a peer's totals on their unit tooltip.

	THESE ARE ADDON MESSAGES, NEVER PLAYER-VISIBLE CHAT. Nothing here goes through SendChatMessage,
	so the player-only chat rule and the target-marker convention do not apply -- there is no target
	marker to add. Blizzard removed custom addon channels in 1.13.3 and does not deliver addon
	whispers to non-social strangers, so SAY/YELL is the only sanctioned reach to nearby strangers.
	That is why the feature is proximity-scoped by design: a peer sees your totals only when near you.

	AND TOWN-SCOPED: every send is gated on ns.AtRest(), so this add-on puts nothing on the wire
	outside a city or an inn. Resting is the cheap, reliable proxy for "somewhere nobody is fighting",
	which keeps the feature clear of raids, dungeons and open-world combat entirely.
]]

local Generosity = ns.Generosity

--[[
	Picked by availability, never by truthy result: the bare globals are the pre-9.x fallback and
	C_ChatInfo is what both shipped flavors carry.
]]
local RegisterPrefix = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendAddonMessage = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage

local PREFIX = ns.ADDON_MESSAGE_PREFIX
local PAYLOAD_VERSION = "1"
local CHANNEL = "YELL"

--[[
	Three throttles, all seconds against GetTime(). BROADCAST_MIN_INTERVAL caps how often our own
	totals go out; PING_ANSWER_INTERVAL caps how often we answer a ping, so a crowd cannot make us
	storm the channel. The hover-ping throttle is the tooltip's, since that is where a hover happens.
]]
local BROADCAST_MIN_INTERVAL = 60
local PING_ANSWER_INTERVAL = 30

--[[
	How long a cached peer stays good, seconds like the throttles above. Generous rather than tight:
	an expired entry reads as never-heard-from, and the only thing that refills it is
	Features/Generosity-Tooltip.lua firing a presence ping on a hover that found nothing -- which
	happens in a rest area alone, since the town gate returns before the lookup. Too short and a
	peer standing beside you flickers out between hovers with no way back until you are both in town.
]]
local PEER_MAX_AGE = 1800

--[[
	Registered so CHAT_MSG_ADDON delivers messages carrying this prefix. Guarded and remembered:
	a missing API just means no sharing, and the diagnostics report prints whether it took. Treats
	"the call existed and did not throw" as registered, since the return shape varies across clients.
]]
Generosity.prefixRegistered = false
if RegisterPrefix then
	local ok = pcall(RegisterPrefix, PREFIX)
	Generosity.prefixRegistered = ok and true or false
end

--[[
	Peers we have heard from, keyed "Name-Realm": { gifts, items, itemLevels, value, t }, t from
	GetTime() and what PEER_MAX_AGE is measured against. The tooltip reads this; the diagnostics
	report prints the age.
]]
local peers = {}

--[[
	Normalize a sender to "Name-Realm". CHAT_MSG_ADDON's sender carries a realm from a connected
	realm and none from your own, so append our realm when it is missing. Never filter or branch on
	the suffix: Classic realms are all connected, so every name in reach is reachable.
]]
local function normalize(nameRealm)
	if not nameRealm or nameRealm == "" then
		return nil
	end
	if nameRealm:find("-", 1, true) then
		return nameRealm
	end
	local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or ""
	return nameRealm .. "-" .. realm
end

--[[
	A peer's cached totals, or nil once the entry is past PEER_MAX_AGE -- an expired peer is reported
	as one we have never heard from, which is what puts the tooltip back on its ping-and-refresh path.
	The key is normalized the same way the handler stores it. Reads only; the sweep is on the write.
]]
function Generosity:Peer(nameRealm)
	local key = normalize(nameRealm)
	local peer = key and peers[key]
	if not peer or GetTime() - (peer.t or 0) > PEER_MAX_AGE then
		return nil
	end
	return peer
end

-- The raw peers cache, for the diagnostics report only. Not for the tooltip, which asks by name.
function Generosity:AllPeers()
	return peers
end

local lastBroadcast = 0

--[[
	Send our totals, if sharing is on. Versioned payload "1|S|gifts|items|itemLevels|value" from
	Get. A share-on user with zero gifts still broadcasts, so presence shows before their first gift.
	Throttled so nothing that calls this can exceed one send per BROADCAST_MIN_INTERVAL, which is
	also what guards the PLAYER_ENTERING_WORLD refire on every loading screen.
]]
function Generosity:Broadcast()
	if not (ns.db and ns.db.profile.shareStats) then
		return
	end
	--[[
		TOWN ONLY. Nothing goes over the wire outside a rest area, so a raid, a dungeon or a fight in
		the open world never carries this add-on's traffic. Checked before the throttle, so a run that
		finishes out in the world does not burn the interval on a send that never happens.
	]]
	if not ns.AtRest() then
		return
	end
	local now = GetTime()
	if now - lastBroadcast < BROADCAST_MIN_INTERVAL then
		return
	end
	lastBroadcast = now
	local gifts, items, itemLevels, value = self:Get()
	local payload = table.concat({ PAYLOAD_VERSION, "S", gifts, items, itemLevels, value }, "|")
	if SendAddonMessage then
		pcall(SendAddonMessage, PREFIX, payload, CHANNEL)
	end
end

--[[
	Ask nearby clients to broadcast. Independent of shareStats: a ping reveals presence, not totals,
	and turning sharing off must still let you see theirs. The tooltip throttles how often it fires.
]]
function Generosity:Ping()
	-- Town only, for the same reason Broadcast is: a ping is wire traffic like any other.
	if not ns.AtRest() then
		return
	end
	if SendAddonMessage then
		pcall(SendAddonMessage, PREFIX, PAYLOAD_VERSION .. "|?", CHANNEL)
	end
end

local lastPingAnswer = 0

--[[
	An answer that cannot go out must not spend the window, so the town gate is read before the
	clock is stamped -- the same ordering Broadcast uses. Receiving is ungated, so this runs out in
	the world too, where a ping heard just outside an inn would otherwise leave the next one
	unanswered once the player stepped inside. Rate-limited on its own clock past that, so a crowd
	of pings draws one answer.
]]
local function answerPing()
	if not ns.AtRest() then
		return
	end
	local now = GetTime()
	if now - lastPingAnswer < PING_ANSWER_INTERVAL then
		return
	end
	lastPingAnswer = now
	Generosity:Broadcast()
end

--[[
	Split "a|b|c" into fields. A trailing separator is appended so gmatch yields the last field, and
	an empty field comes back as "" rather than being skipped, so positions stay aligned.
]]
local function split(message)
	local parts = {}
	for field in (message .. "|"):gmatch("([^|]*)|") do
		parts[#parts + 1] = field
	end
	return parts
end

--[[
	Handler args are prefix, message, channel, sender. Ignore other add-ons' prefixes and unknown
	payload versions; on "S" cache the sender's four totals, on "?" answer with our own (throttled).
]]
ns.on("CHAT_MSG_ADDON", function(prefix, message, _, sender)
	if prefix ~= PREFIX or not message then
		return
	end
	local parts = split(message)
	if parts[1] ~= PAYLOAD_VERSION then
		return
	end
	local kind = parts[2]
	if kind == "S" then
		local key = normalize(sender)
		if key then
			--[[
				Swept here because this is the only place the table grows, so nothing needs a timer.
				Clearing fields of a table being traversed with pairs is defined behavior; adding
				would not be, and this only ever clears.
			]]
			local now = GetTime()
			for name, peer in pairs(peers) do
				if now - (peer.t or 0) > PEER_MAX_AGE then
					peers[name] = nil
				end
			end
			peers[key] = {
				gifts = tonumber(parts[3]) or 0,
				items = tonumber(parts[4]) or 0,
				itemLevels = tonumber(parts[5]) or 0,
				value = tonumber(parts[6]) or 0,
				t = now,
			}
		end
	elseif kind == "?" then
		answerPing()
	end
end)

-- Presence on entering the world; the throttle in Broadcast absorbs the refire on every load screen.
ns.on("PLAYER_ENTERING_WORLD", function()
	Generosity:Broadcast()
end)

--[[
	The moment the town gate opens. Walking from a field into a city fires no loading screen, so
	PLAYER_ENTERING_WORLD alone would leave a player silent until something else happened to send.
	This fires on leaving a rest area too, where Broadcast simply returns on the gate.
]]
ns.on("PLAYER_UPDATE_RESTING", function()
	Generosity:Broadcast()
end)
