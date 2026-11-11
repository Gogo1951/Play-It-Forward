local _, ns = ...

local GetClientHeader = ns.GetDiagnosticClientHeader

--------------------------------------------------------------------------------
-- Event Log
--------------------------------------------------------------------------------

local EVENT_LOG_SIZE = 500
local EVENT_LOG_MAX_ARGS = 8
local EVENT_LOG_MAX_ARG_LENGTH = 255

--[[
	Events dropped before recording, for a registered firehose that is never signal. Deliberately
	empty: every event this add-on registers is signal some of the time, and those are classified
	per firing by the filter below rather than dropped.

	AN EVENT THAT IS SOMETIMES SIGNAL DOES NOT BELONG HERE.
]]
ns.DIAGNOSTIC_EVENT_EXCLUDE = {}

--[[
	The firehoses that are sometimes signal, and where in their arguments the id that says which
	is which arrives. All four are registered: UI_ERROR_MESSAGE in Features/Mail-Sender.lua, where a
	mail refusal arrives as a red error; CHAT_MSG_ADDON in Features/Generosity-Broadcast.lua; and
	BAG_UPDATE and GET_ITEM_INFO_RECEIVED in Features/Match-List.lua, which rescan the open window.
	Logged raw, the combat errors, the other add-ons' chatter and every loot evict the mailbox and
	/who entries the log exists to carry; dropped outright, the log can never show a refusal, a
	peer arriving, or the event that did or did not refresh the list.

	FILTER BY WHAT THE ADD-ON ACTS ON, NEVER BY A DENYLIST OF NOISE. Noise is unbounded, varies by
	class and activity, and renumbers across patches. Each rule's `correlated` is the live handler's
	own test, called rather than restated: a filter that classified differently would make the log
	lie about what fired.
]]
ns.MESSAGE_ID_FILTERED_EVENTS = {
	UI_ERROR_MESSAGE = {
		id = 1, -- (messageType, message)
		correlated = function(_, message)
			return ns.Distributor:IsMailError(message)
		end,
	},
	CHAT_MSG_ADDON = {
		id = 1, -- (prefix, message, channel, sender)
		correlated = function(prefix)
			return prefix == ns.ADDON_MESSAGE_PREFIX
		end,
	},
	-- Signal exactly when the firing arms a rescan, of the open window or a waiting mailbox; otherwise it only marks the bags stale.
	BAG_UPDATE = {
		id = 1, -- (bagID)
		correlated = function()
			return ns.MatchList:WouldRescan()
		end,
	},
	GET_ITEM_INFO_RECEIVED = {
		id = 1, -- (itemID, success)
		correlated = function(itemID, success)
			return ns.MatchList:WouldRescanItem(itemID, success)
		end,
	},
}

--[[
    A secret value (WoW Forever) errors when compared, concatenated or used as
    a table key, so the log never turns one into text. Clients without secret
    values have no issecretvalue, and every value there is plain.
]]
local IsSecretValue = rawget(_G, "issecretvalue")

local function IsPlain(value)
	return not (IsSecretValue and IsSecretValue(value))
end

--[[
	The counter id a secret id folds into, since a secret can't key a table. A string no event
	argument here can be: a bag ID of 0 is the backpack, so a numeric sentinel would merge it.
]]
local SECRET_ID = "<secret>"

--[[
    Folds one uncorrelated firing into its counter: the first-seen text plus a
    count. Counters are keyed by event, then id, so one id arriving on two
    events stays two rows. A secret id counts under SECRET_ID with the text
    <secret>.
]]
local function CountUncorrelated(event, id, text)
	local suppressed = ns.diagnostics.suppressed
	if not suppressed then
		return
	end
	if not IsPlain(id) then
		id, text = SECRET_ID, "<secret>"
	elseif not IsPlain(text) then
		text = "<secret>"
	end
	local counters = suppressed[event]
	if not counters then
		counters = {}
		suppressed[event] = counters
	end
	local entry = counters[id]
	if entry then
		entry.count = entry.count + 1
		return
	end
	local raw = string.sub(tostring(text or ""), 1, EVENT_LOG_MAX_ARG_LENGTH)
	counters[id] = { text = (raw:gsub("|", "||")), count = 1 }
end

--[[
	Whether this firing folds into a counter instead of reaching the buffer. Applied AT CAPTURE, in
	ns:LogEvent below, never at render: filtering at display time still lets spam push real entries
	out of a bounded buffer. A secret id counts too, without asking the rule, which would compare it.

	UNCLASSIFIABLE IS SIGNAL. A firing with nothing at the id position is logged verbatim rather
	than counted, because the thing that would have decided is missing. So is one the rule cannot
	read, such as a secret message text: the log runs ahead of the real handlers, so a rule that
	throws here would stop them too.
]]
function ns:SuppressUncorrelatedMessage(event, ...)
	local rule = ns.MESSAGE_ID_FILTERED_EVENTS[event]
	if not rule then
		return false
	end

	local id = select(rule.id, ...)
	local text
	if select("#", ...) > rule.id then
		text = select(rule.id + 1, ...)
	end
	if not IsPlain(id) then
		CountUncorrelated(event, id, text)
		return true
	end
	if id == nil or id == "" then
		return false
	end
	local ok, correlated = pcall(rule.correlated, ...)
	if not ok or correlated then
		return false
	end

	CountUncorrelated(event, id, text)
	return true
end

function ns:StartEventLog()
	ns.diagnostics.log = {}
	ns.diagnostics.suppressed = {}
	ns.diagnostics.logging = true
end

function ns:StopEventLog()
	ns.diagnostics.logging = false
end

--[[
    One entry in the buffer, for ns:LogEvent and ns:LogEventNow below.
    Snapshots arguments to strings immediately -- never retain references, since
    some events carry frames or tables that would leak memory or go stale. Caps
    the arg count and per-argument byte length so a single entry can't run away.
    A secret argument (WoW Forever) can't be turned into text, so it records as
    <secret>.

    Pipes are escaped (| -> ||) AFTER the length cut so each argument shows
    verbatim in the report editbox instead of rendering as a clickable item
    swatch. Escaping last also means the cut can never leave a dangling pipe that
    would eat the following ", " separator.
]]
local function AppendEntry(event, ...)
	local log = ns.diagnostics.log
	if not log then
		return
	end
	local parts = {}
	for index = 1, select("#", ...) do
		if index > EVENT_LOG_MAX_ARGS then
			break
		end
		local value = select(index, ...)
		if IsPlain(value) then
			local raw = string.sub(tostring(value), 1, EVENT_LOG_MAX_ARG_LENGTH)
			parts[index] = (raw:gsub("|", "||"))
		else
			parts[index] = "<secret>"
		end
	end
	log[#log + 1] = string.format("%.3f %s(%s)", GetTime(), event, table.concat(parts, ", "))
	if #log > EVENT_LOG_SIZE then
		table.remove(log, 1)
	end
end

-- Called by Core's central dispatcher for every event while logging is active.
function ns:LogEvent(event, ...)
	if ns.DIAGNOSTIC_EVENT_EXCLUDE[event] then
		return
	end
	if ns:SuppressUncorrelatedMessage(event, ...) then
		return
	end
	AppendEntry(event, ...)
end

--[[
    The way back in for an excluded firehose that is sometimes signal: the
    handler that decides a firing mattered calls this with the event and its
    arguments, and it is recorded as the dispatcher would have, past the
    exclude list. Feature code calls it, so it carries the dispatcher's own
    single boolean check before any work.
]]
function ns:LogEventNow(event, ...)
	if not ns.diagnostics.logging then
		return
	end
	AppendEntry(event, ...)
end

--[[
    Renders the suppressed-traffic counters as one compact block, biggest
    offender first. This is also how a tester discovers a message id the add-on
    should be correlating but isn't.
]]
local function AppendSuppressedSummary(lines)
	local suppressed = ns.diagnostics.suppressed
	if not suppressed then
		return
	end
	local rows = {}
	for event, counters in pairs(suppressed) do
		for id, entry in pairs(counters) do
			rows[#rows + 1] = { event = event, id = id, entry = entry }
		end
	end
	if #rows == 0 then
		return
	end
	-- Ids compare as text: one event's ids can be numbers beside the SECRET_ID string.
	table.sort(rows, function(a, b)
		if a.entry.count ~= b.entry.count then
			return a.entry.count > b.entry.count
		end
		if a.event ~= b.event then
			return a.event < b.event
		end
		return tostring(a.id) < tostring(b.id)
	end)
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Suppressed uncorrelated traffic:"
	for _, row in ipairs(rows) do
		if row.id == SECRET_ID then
			lines[#lines + 1] = string.format("%s(<secret>) x%d", row.event, row.entry.count)
		else
			lines[#lines + 1] =
				string.format("%s(%s, %s) x%d", row.event, tostring(row.id), row.entry.text, row.entry.count)
		end
	end
end

function ns:BuildEventLogReport()
	local lines = { GetClientHeader(), "" }
	local log = ns.diagnostics.log
	if not log or #log == 0 then
		lines[#lines + 1] = "(no events captured)"
	else
		for _, entry in ipairs(log) do
			lines[#lines + 1] = entry
		end
	end
	AppendSuppressedSummary(lines)
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Taint Log
--------------------------------------------------------------------------------

--[[
    The taintLog CVar controls UI taint logging to Logs\taint.log. Level 2 logs
    both blocked actions and accesses to tainted globals; 0 is off. This is the
    only state the diagnostics panel ever writes.
]]

function ns:GetTaintLogState()
	return tonumber(GetCVar("taintLog")) or 0
end

function ns:SetTaintLog(enabled)
	SetCVar("taintLog", enabled and 2 or 0)
end
