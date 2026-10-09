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
	-- Signal exactly when the firing arms a rescan of the open window; otherwise it only marks the bags stale.
	BAG_UPDATE = {
		id = 1, -- (bagID)
		correlated = function()
			return ns.MatchList:WouldRescan()
		end,
	},
	GET_ITEM_INFO_RECEIVED = {
		id = 1, -- (itemID, success)
		correlated = function()
			return ns.MatchList:WouldRescan()
		end,
	},
}

--[[
	Whether this firing folds into a counter instead of reaching the buffer. Applied AT CAPTURE, in
	ns:LogEvent below, never at render: filtering at display time still lets spam push real entries
	out of a bounded buffer.

	UNCLASSIFIABLE IS SIGNAL. A firing with nothing at the id position is logged verbatim rather
	than counted, because the thing that would have decided is missing. So is one with nowhere to
	count it: this never deletes an entry it did not record.
]]
function ns:SuppressUncorrelatedMessage(event, ...)
	local rule = ns.MESSAGE_ID_FILTERED_EVENTS[event]
	if not rule then
		return false
	end

	local id = (select(rule.id, ...))
	if id == nil or id == "" then
		return false
	end
	if rule.correlated(...) then
		return false
	end

	local suppressed = ns.diagnostics.suppressed
	if not suppressed then
		return false
	end

	local key = string.format("%s(%s)", event, tostring(id))
	local entry = suppressed[key]
	if entry then
		entry.count = entry.count + 1
		return true
	end

	--[[
		First-seen text only, cut and escaped the way a logged argument is: this is what tells a
		tester an id the add-on SHOULD be correlating from one it is right to ignore.
	]]
	local text = (select(rule.id + 1, ...))
	text = string.sub(tostring(text == nil and "" or text), 1, EVENT_LOG_MAX_ARG_LENGTH)
	suppressed[key] = { event = event, id = id, text = (text:gsub("|", "||")), count = 1 }
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
    Called by Core's central dispatcher for every event while logging is active.
    Snapshots arguments to strings immediately -- never retain references, since
    some events carry frames or tables that would leak memory or go stale. Caps
    the arg count and per-argument byte length so a single entry can't run away.

    Pipes are escaped (| -> ||) AFTER the length cut so each argument shows
    verbatim in the report editbox instead of rendering as a clickable item
    swatch. Escaping last also means the cut can never leave a dangling pipe that
    would eat the following ", " separator.
]]
function ns:LogEvent(event, ...)
	if ns.DIAGNOSTIC_EVENT_EXCLUDE[event] then
		return
	end
	if ns:SuppressUncorrelatedMessage(event, ...) then
		return
	end
	local log = ns.diagnostics.log
	if not log then
		return
	end
	local parts = {}
	for index = 1, select("#", ...) do
		if index > EVENT_LOG_MAX_ARGS then
			break
		end
		local raw = string.sub(tostring((select(index, ...))), 1, EVENT_LOG_MAX_ARG_LENGTH)
		parts[index] = (raw:gsub("|", "||"))
	end
	log[#log + 1] = string.format("%.3f %s(%s)", GetTime(), event, table.concat(parts, ", "))
	if #log > EVENT_LOG_SIZE then
		table.remove(log, 1)
	end
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
	local entries = {}
	for _, entry in pairs(suppressed) do
		entries[#entries + 1] = entry
	end
	if #entries == 0 then
		return
	end
	-- Biggest offender first; the key breaks ties so the block holds still between renders.
	table.sort(entries, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return string.format("%s%s", a.event, tostring(a.id)) < string.format("%s%s", b.event, tostring(b.id))
	end)

	lines[#lines + 1] = ""
	lines[#lines + 1] = "Suppressed, counted rather than logged (nothing the add-on acts on):"
	for _, entry in ipairs(entries) do
		lines[#lines + 1] = string.format("  %s(%s, %s) x%d", entry.event, tostring(entry.id), entry.text, entry.count)
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
