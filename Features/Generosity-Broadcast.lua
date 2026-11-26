local _, ns = ...

--[[
	Add-on messages, never chat, so the player-only chat rule does not apply. YELL because Classic
	has no custom channels and drops add-on whispers to strangers; every send is gated on ns.AtRest().
]]

local Generosity = ns.Generosity

local RegisterPrefix = C_ChatInfo.RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo.SendAddonMessage

local PREFIX = ns.ADDON_MESSAGE_PREFIX
local PAYLOAD_VERSION = "1"
local CHANNEL = "YELL"

-- Covers ping answers too, so a crowd of pings cannot storm the channel.
local BROADCAST_MIN_INTERVAL = 60

-- Generous: too short and a peer standing beside you flickers out between hovers.
local PEER_MAX_AGE = 1800

-- Exposed so the diagnostics sharing report measures against the same numbers this file does.
Generosity.BROADCAST_MIN_INTERVAL = BROADCAST_MIN_INTERVAL
Generosity.PEER_MAX_AGE = PEER_MAX_AGE

-- "Did not throw" counts as registered: the return shape varies across clients.
Generosity.prefixRegistered = false
if RegisterPrefix then
	local ok = pcall(RegisterPrefix, PREFIX)
	Generosity.prefixRegistered = ok and true or false
end

-- Keyed by ns.QualifyPlayerName: the sender carries a realm only from a connected realm.
local peers = {}

-- Expired reads as never heard from, which puts the tooltip back on its ping path. The sweep is on the write.
function Generosity:Peer(nameRealm)
	local key = ns.QualifyPlayerName(nameRealm)
	local peer = key and peers[key]
	if not peer or GetTime() - (peer.t or 0) > PEER_MAX_AGE then
		return nil
	end
	return peer
end

-- Diagnostics only: still holds expired entries until the next message sweeps them.
function Generosity:AllPeers()
	return peers
end

local lastBroadcast = 0

-- Diagnostics only: GetTime() of our last send, ping answers included, or 0.
function Generosity:LastSends()
	return lastBroadcast
end

-- A refused channel is a return value, not an error, and nothing else would show it.
Generosity.lastSendResult = nil

local function Send(payload)
	if not SendAddonMessage then
		return
	end
	local ok, result = pcall(SendAddonMessage, PREFIX, payload, CHANNEL)
	Generosity.lastSendResult = { ok = ok, result = tostring(result) }
end

-- Zero gifts still broadcast, so presence shows before a first gift.
function Generosity:Broadcast()
	if not (ns.db and ns.db.profile.shareStats) then
		return
	end
	-- Town gate before the throttle, so a send that never happens does not burn the interval.
	if not ns.AtRest() then
		return
	end
	local now = GetTime()
	if now - lastBroadcast < BROADCAST_MIN_INTERVAL then
		return
	end
	lastBroadcast = now
	local gifts, items, itemLevels, value = self:Get()
	Send(table.concat({ PAYLOAD_VERSION, "S", gifts, items, itemLevels, value }, "|"))
end

-- Ignores shareStats: a ping reveals presence, not totals, and sharing off must still see theirs.
function Generosity:Ping()
	if not ns.AtRest() then
		return
	end
	Send(PAYLOAD_VERSION .. "|?")
end

-- An empty field comes back as "", keeping positions aligned.
local function Split(message)
	local parts = {}
	for field in (message .. "|"):gmatch("([^|]*)|") do
		parts[#parts + 1] = field
	end
	return parts
end

-- Anyone in yelling range can send these, so only plain integers are believed ("nan", "1e999", "0x10" are not).
local PEER_TOTAL_MAX = 1e12
local STATS_FIELDS = 6

local function ReadTotal(field)
	if type(field) ~= "string" or not field:match("^%d+$") then
		return nil
	end
	local value = tonumber(field)
	return (value and value <= PEER_TOTAL_MAX) and value or nil
end

local function OnChatMsgAddon(prefix, message, _, sender)
	-- On WoW Forever a payload can arrive secret, and comparing one throws. Other clients lack the check.
	local IsSecretValue = rawget(_G, "issecretvalue")
	if IsSecretValue and (IsSecretValue(prefix) or IsSecretValue(message) or IsSecretValue(sender)) then
		return
	end
	if prefix ~= PREFIX or not message then
		return
	end
	local parts = Split(message)
	if parts[1] ~= PAYLOAD_VERSION then
		return
	end
	-- Our own YELL echoes back; answering it would spend the interval on nobody.
	local senderKey = ns.QualifyPlayerName(sender)
	if senderKey and senderKey == ns.QualifyPlayerName(ns.PlayerName()) then
		return
	end
	local kind = parts[2]
	if kind == "S" then
		local key = ns.QualifyPlayerName(sender)
		local gifts, items, itemLevels, value =
			ReadTotal(parts[3]), ReadTotal(parts[4]), ReadTotal(parts[5]), ReadTotal(parts[6])
		if #parts ~= STATS_FIELDS or not (gifts and items and itemLevels and value) then
			return
		end
		if key then
			-- Swept where the table grows, so no timer. Clearing during pairs is defined; adding is not.
			local now = GetTime()
			for name, peer in pairs(peers) do
				if now - (peer.t or 0) > PEER_MAX_AGE then
					peers[name] = nil
				end
			end
			peers[key] = {
				gifts = gifts,
				items = items,
				itemLevels = itemLevels,
				value = value,
				t = now,
			}
		end
	elseif kind == "?" then
		-- Through Broadcast, so its interval, town gate and Share switch decide the answer.
		Generosity:Broadcast()
	end
end
ns.On("CHAT_MSG_ADDON", OnChatMsgAddon)

-- Presence on entering the world; the throttle in Broadcast absorbs the refire on every load screen.
local function OnPlayerEnteringWorld()
	Generosity:Broadcast()
end
ns.On("PLAYER_ENTERING_WORLD", OnPlayerEnteringWorld)

-- Walking into a city fires no loading screen; this is what catches the town gate opening.
local function OnPlayerUpdateResting()
	Generosity:Broadcast()
end
ns.On("PLAYER_UPDATE_RESTING", OnPlayerUpdateResting)
