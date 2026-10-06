--[[
	Sharing the Given Away tally with nearby players. The wire is addon messages over YELL: a
	crafted CHAT_MSG_ADDON is fed through the real handler and the peers cache read back, and the
	shareStats gate is checked from both sides -- off suppresses our own broadcast, on lets it out,
	and a ping is answered either way subject to sharing. GetTime is the stub clock, so the throttles
	are quiet on a first call.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal
local Stub = Harness.Stub

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- The peers cache is keyed, not an array, so its size is a count rather than a length.
local function count(peers)
	local n = 0
	for _ in pairs(peers) do
		n = n + 1
	end
	return n
end

--------------------------------------------------------------------------------

test("a stats broadcast from a peer lands in the peers cache", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|12|340|560|78900", "YELL", "Robin-Grobbulus")

	local peer = ns.Generosity:Peer("Robin-Grobbulus")
	check(peer ~= nil, "the peer was cached")
	equal(peer.gifts, 12, "gifts parsed")
	equal(peer.items, 340, "items parsed")
	equal(peer.itemLevels, 560, "item levels parsed")
	equal(peer.value, 78900, "value parsed")
end)

--[[
	A realm-less sender is keyed to our own realm, and reachable by either form of the key: Classic
	realms are all connected, so the suffix is never a filter.
]]
test("a realm-less sender is keyed to our realm", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|1|2|3|4", "YELL", "Keefe")

	check(ns.Generosity:Peer("Keefe") ~= nil, "found by the bare name")
	check(ns.Generosity:Peer("Keefe-Test") ~= nil, "and by the fully-qualified key")
end)

test("another add-on's prefix is ignored", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", "SomeoneElse", "1|S|9|9|9|9", "YELL", "Robin-Grobbulus")

	check(ns.Generosity:Peer("Robin-Grobbulus") == nil, "not cached")
end)

test("an unknown payload version is ignored", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "9|S|1|2|3|4", "YELL", "Robin-Grobbulus")

	check(ns.Generosity:Peer("Robin-Grobbulus") == nil, "a future version is not force-parsed")
end)

--[[
	shareStats off suppresses our own broadcast; on lets exactly one out, a versioned stats payload
	over YELL carrying our prefix. Suppression is checked first so the throttle is untouched when
	sharing turns on.
]]
test("shareStats off suppresses Broadcast, on sends", function()
	local ns = load()

	ns.db.profile.shareStats = false
	ns.Generosity:Broadcast()
	equal(#Stub.addonMessages, 0, "nothing sent while sharing is off")

	ns.db.profile.shareStats = true
	ns.Generosity:Broadcast()
	equal(#Stub.addonMessages, 1, "one broadcast once sharing is on")

	local msg = Stub.addonMessages[1]
	equal(msg.prefix, ns.ADDON_MESSAGE_PREFIX, "our prefix")
	equal(msg.channel, "YELL", "over YELL")
	check(msg.message:match("^1|S|") ~= nil, "a versioned stats payload")
end)

-- Presence still broadcasts at zero gifts, so a fresh account shows up before its first gift.
test("a share-on account with an empty tally still broadcasts", function()
	local ns = load()
	ns.db.profile.shareStats = true

	ns.Generosity:Broadcast()

	equal(#Stub.addonMessages, 1, "presence went out")
	equal(Stub.addonMessages[1].message, "1|S|0|0|0|0", "all zeros, still sent")
end)

-- A ping is answered by broadcasting our totals, subject to sharing being on.
test("a ping draws a broadcast of our totals", function()
	local ns = load()
	ns.db.profile.shareStats = true

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|?", "YELL", "Robin-Grobbulus")

	equal(#Stub.addonMessages, 1, "the ping drew one answer")
	check(Stub.addonMessages[1].message:match("^1|S|") ~= nil, "and it was our stats")
end)

--------------------------------------------------------------------------------
-- The town gate
--------------------------------------------------------------------------------

--[[
	Sharing is town-only: outside a rest area nothing goes on the wire at all, which is what keeps
	the add-on clear of raids and open-world fights. The gate is checked before the throttle, so
	walking into town is not held back by an interval that a blocked send would have consumed.
]]
test("out of a rest area nothing is broadcast", function()
	local ns = load()
	ns.db.profile.shareStats = true
	Stub.resting = false

	ns.Generosity:Broadcast()

	equal(#Stub.addonMessages, 0, "no broadcast outside town")
end)

test("out of a rest area a ping is neither sent nor answered", function()
	local ns = load()
	ns.db.profile.shareStats = true
	Stub.resting = false

	ns.Generosity:Ping()
	equal(#Stub.addonMessages, 0, "we do not ping outside town")

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|?", "YELL", "Robin-Grobbulus")
	equal(#Stub.addonMessages, 0, "and we do not answer one outside town")
end)

-- Receiving stays open: caching a peer costs nothing, and the data is ready for when you get back.
test("a peer's broadcast is still cached out of a rest area", function()
	local ns = load()
	Stub.resting = false

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|5|6|7|8", "YELL", "Robin-Grobbulus")

	check(ns.Generosity:Peer("Robin-Grobbulus") ~= nil, "listening is not gated, only sending")
end)

-- The blocked send must not consume the throttle, or arriving in town would start with a dead interval.
test("a blocked send leaves the throttle unspent", function()
	local ns = load()
	ns.db.profile.shareStats = true

	Stub.resting = false
	ns.Generosity:Broadcast()
	equal(#Stub.addonMessages, 0, "nothing went out")

	Stub.resting = true
	ns.Generosity:Broadcast()
	equal(#Stub.addonMessages, 1, "reaching town broadcasts immediately")
end)

--[[
	Same rule on the answering side, and the gate has to come first for the same reason: an answer
	that cannot go out must not spend the 30s window, or a ping heard just outside an inn leaves the
	next one unanswered after the player has stepped inside. Receiving is ungated, so this path is
	reached out in the world where Broadcast's own is not.
]]
test("a blocked ping answer leaves the throttle unspent", function()
	local ns = load()
	ns.db.profile.shareStats = true

	Stub.resting = false
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|?", "YELL", "Robin-Grobbulus")
	equal(#Stub.addonMessages, 0, "nothing answered outside town")

	Stub.resting = true
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|?", "YELL", "Robin-Grobbulus")
	equal(#Stub.addonMessages, 1, "reaching town answers the next ping immediately")
end)

-- Walking into a city fires no loading screen, so the resting flip is what announces presence.
test("becoming rested broadcasts presence", function()
	local ns = load()
	ns.db.profile.shareStats = true
	Stub.resting = true

	ns.fire("PLAYER_UPDATE_RESTING")

	equal(#Stub.addonMessages, 1, "entering town announced us")
end)

--------------------------------------------------------------------------------
-- Peer cache expiry
--------------------------------------------------------------------------------

--[[
	A cached peer is evidence they are nearby only for as long as PEER_MAX_AGE, 1800s in
	Features/Generosity-Broadcast.lua. Past it Peer answers nil, which is what puts the tooltip back
	on its ping-and-refresh path. The clock is advanced rather than waited on, and the boundary is
	checked from both sides because the comparison is a strict > and an off-by-one there is
	invisible in play. These two cases hardcode the age: a deliberate change to the constant is
	meant to bring someone here.
]]
test("a peer just inside PEER_MAX_AGE still reads", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|12|340|560|78900", "YELL", "Robin-Grobbulus")
	Stub.now = Stub.now + 1799

	check(ns.Generosity:Peer("Robin-Grobbulus") ~= nil, "still nearby one second inside the 1800s age")
end)

test("a peer past PEER_MAX_AGE reads as never heard from", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|12|340|560|78900", "YELL", "Robin-Grobbulus")
	Stub.now = Stub.now + 1801

	check(ns.Generosity:Peer("Robin-Grobbulus") == nil, "one second past the 1800s age, no longer nearby")
end)

--[[
	The sweep rides the only write, which is what bounds the table without a timer: an expired row
	survives until the next stats message arrives, then goes. Counted through AllPeers, since Peer
	answers nil for an expired row either way and would prove nothing about the table's size.
]]
test("a stats message sweeps expired peers out of the cache", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|1|1|1|1", "YELL", "Robin-Grobbulus")
	Stub.now = Stub.now + 1801
	equal(count(ns.Generosity:AllPeers()), 1, "still held while nothing has written")

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|2|2|2|2", "YELL", "Somebody-Else")

	local peers = ns.Generosity:AllPeers()
	equal(count(peers), 1, "the expired row was dropped")
	check(peers["Somebody-Else"] ~= nil, "and the fresh sender is what remains")
end)

-- Expiry is not a ban: the same peer speaking again is cached afresh, with the new totals.
test("a peer heard from again after expiry is cached afresh", function()
	local ns = load()

	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|1|1|1|1", "YELL", "Robin-Grobbulus")
	Stub.now = Stub.now + 1801
	ns.fire("CHAT_MSG_ADDON", ns.ADDON_MESSAGE_PREFIX, "1|S|9|9|9|9", "YELL", "Robin-Grobbulus")

	local peer = ns.Generosity:Peer("Robin-Grobbulus")
	check(peer ~= nil, "back in the cache")
	equal(peer.gifts, 9, "carrying the totals from the new message")
end)
