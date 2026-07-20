local _, ns = ...

--------------------------------------------------------------------------------
-- Diagnostic Tools
--------------------------------------------------------------------------------

--[[
	Environment probing and state capture for bug reports, not unit tests. Read-only and
	side-effect free but for the Taint Log button, which sets a CVar, and Clear History, which
	wipes the fairness list. Reports build only on a button press, never on load or panel open.
]]

local L = ns.L

--------------------------------------------------------------------------------
-- Runtime State
--------------------------------------------------------------------------------

-- Runtime-only, NOT a SavedVariable: the "initialize on PLAYER_LOGIN" rule does not apply here.
ns.diagnostics = ns.diagnostics or { enabled = false, logging = false, log = nil }

--------------------------------------------------------------------------------
-- Strings
--------------------------------------------------------------------------------

-- Intentionally NOT localized: developer-facing text. ADDON_TITLE is the exception, being identity.
ns.DiagnosticsStrings = {
	TAB = "Diagnostic Tools",
	WARNING = "These tools help diagnose problems and are meant for developers. They won't change how the add-on works, but their output includes technical details about your client and installed add-ons. Leave this off unless you're troubleshooting with someone.",
	ENABLE = "Enable Diagnostic Tools",
	EVENT_LOG_TITLE = "Event Log",
	EVENT_LOG_START = "Start Event Log",
	EVENT_LOG_STOP = "Stop Event Log",
	EVENT_LOG_SHOW = "Show Captured Events",
	EVENT_LOG_HINT = "Captures events the add-on registered for, with arguments, in order fired.",
	EVENTS_TITLE = "Event Registration",
	EVENTS_BUTTON = "Test Event Registration",
	API_TITLE = "API Endpoints",
	API_BUTTON = "Test WoW API Endpoints",
	DISPLAY_TITLE = "Display Context",
	DISPLAY_BUTTON = "Read Display Settings",
	BAGS_TITLE = "Bag Scan",
	BAGS_BUTTON = "Export Every Bag Slot",
	BAGS_HINT = "One row per occupied bag slot, giftable or not. Rejected rows carry the reason code that stopped them, which is what answers 'why isn't this item showing up'.",
	ROSTER_TITLE = "Recipient Roster",
	ROSTER_BUTTON = "Export Known Players",
	ROSTER_HINT = "Everyone found by Find Recipients so far, with their fairness state and the items they currently qualify for.",
	--[[
		Where the next /who will look, composed by Recipient-Search. The client's filter syntax
		is `21-22 z-"Redridge Mountains"`; these say the same thing in words.
	]]
	WHO_LABEL_IN_ZONE = "%s (%s)",
	WHO_LABEL_ZONES = "%d zones (%s)",
	WHO_LABEL_ANYWHERE = "anywhere (%s)",
	WHO_LABEL_FOR_CLASSES = "%s, for %s",
	VERDICT_TITLE = "Item Verdict",
	VERDICT_INPUT = "Item link",
	VERDICT_INPUT_HINT = "Shift-click an item into the chat box, copy the link, and paste it here.",
	VERDICT_BUTTON = "Explain This Item",
	GROUPS_TITLE = "Class Groups",
	GROUPS_INPUT = "Item required level",
	GROUPS_ARMOR_BUTTON = "Show Armor Groups",
	GROUPS_WEAPON_BUTTON = "Show Weapon Groups",
	MAIL_TITLE = "Outgoing Mail",
	MAIL_BUTTON = "Preview What Strangers Receive",
	WINDOW_TITLE = "Mail Window",
	WINDOW_BUTTON = "Force the Window Open",
	WINDOW_HINT = "Drops the saved position, re-centers the window and re-reads your bags. The window only opens at a mailbox when something in there is worth mailing, so use this to tell an off-screen window from an empty one.",
	-- Read at call time by Features/Mail-Window.lua, which loads before this file.
	WINDOW_FORCED = "window: shown=%s size=%dx%d, %d scanned (%d giftable), re-anchored to CENTER. Drag it where you want it.",
	HISTORY_TITLE = "Recipient History",
	HISTORY_BUTTON = "Clear History and Roster",
	HISTORY_CONFIRM = "Clear every recipient cooldown and the known-player roster? This cannot be undone.",
	HISTORY_HINT = "Writes to your saved variables. Everyone previously gifted becomes eligible again immediately.",
	ADDONS_TITLE = "Other Add-ons",
	ADDONS_BUTTON = "List Installed Add-ons",
	SAVED_TITLE = "Saved Variables",
	SAVED_BUTTON = "Dump Saved Variables",
	LIBS_TITLE = "Library Versions",
	LIBS_BUTTON = "List Library Versions",
	TAINT_TITLE = "Taint Log",
	TAINT_STATE = "Taint logging is currently set to level %d (0 = off, 2 = verbose).",
	TAINT_ON = "Turn On Taint Log",
	TAINT_OFF = "Turn Off Taint Log",
	TAINT_HINT = "Writes to Logs\\taint.log. The setting persists until turned off; reload your UI to capture taint from login onward.",
	TOOLS_TITLE = "External Tools",
	TOOLS_ERRORS = "Lua errors: install BugSack and !BugGrabber, or enable %s to surface them.",
	TOOLS_ETRACE = "Live event tracing: use %s.",
}

--------------------------------------------------------------------------------
-- Enable Gate
--------------------------------------------------------------------------------

function ns:SetDiagnosticsEnabled(value)
	ns.diagnostics.enabled = value and true or false
	if not ns.diagnostics.enabled then
		ns:StopEventLog()
	end
end

--------------------------------------------------------------------------------
-- Report Header
--------------------------------------------------------------------------------

local function GetClientHeader()
	local version, build, _, tocVersion = GetBuildInfo()
	return string.format(
		"%s %s // Client %s // Build %s // TOC %s // Locale %s // Project %s",
		L["ADDON_TITLE"],
		ns.Version,
		version,
		build,
		tocVersion,
		GetLocale(),
		tostring(WOW_PROJECT_ID)
	)
end

--[[
	Item links are display escapes: pasted raw they render as a colored swatch, hiding the link
	data the report exists to show. Doubling the pipes shows them verbatim.
]]
local function EscapePipes(text)
	return (tostring(text or "?"):gsub("|", "||"))
end

--------------------------------------------------------------------------------
-- Event Log
--------------------------------------------------------------------------------

local EVENT_LOG_SIZE = 500
local EVENT_LOG_MAX_ARGS = 8
local EVENT_LOG_MAX_ARG_LENGTH = 255

--[[
	Dropped on volume alone: BAG_UPDATE fires per bag on every loot, sale and stack merge, and
	GET_ITEM_INFO_RECEIVED once per item the client resolves. Either buries the mailbox and /who
	events past the 500-entry cap, and the Bag Scan report already prints the scan they triggered.
]]
ns.DIAGNOSTIC_EVENT_EXCLUDE = {
	BAG_UPDATE = true,
	GET_ITEM_INFO_RECEIVED = true,
}

function ns:StartEventLog()
	ns.diagnostics.log = {}
	ns.diagnostics.logging = true
end

function ns:StopEventLog()
	ns.diagnostics.logging = false
	ns.diagnostics.log = nil
end

--[[
	Arguments snapshotted to strings immediately, never retained: some events carry frames or
	tables that would leak or go stale. Pipes are escaped AFTER the length cut, so a truncated
	argument cannot leave a dangling pipe that eats the following separator.
]]
function ns:LogEvent(event, ...)
	if ns.DIAGNOSTIC_EVENT_EXCLUDE[event] then
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
	local log = ns.diagnostics.log
	log[#log + 1] = string.format("%.3f %s(%s)", GetTime(), event, table.concat(parts, ", "))
	if #log > EVENT_LOG_SIZE then
		table.remove(log, 1)
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
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

--[[
	Registers then immediately unregisters each event with no handler attached, so nothing is ever
	processed. The list is ns.EVENT_NAMES from Core, so it cannot drift from what the add-on uses.
]]

local probeFrame

local function GetProbeFrame()
	if not probeFrame then
		probeFrame = CreateFrame("Frame")
	end
	return probeFrame
end

function ns:RunEventChecks()
	local lines = { GetClientHeader(), "" }
	local hasIsEventValid = type(C_EventUtils) == "table" and type(C_EventUtils.IsEventValid) == "function"
	local probe = GetProbeFrame()
	local failures = 0
	for _, event in ipairs(ns.EVENT_NAMES or {}) do
		local valid = "n/a"
		if hasIsEventValid then
			valid = C_EventUtils.IsEventValid(event) and "valid" or "INVALID"
		end
		local ok = pcall(probe.RegisterEvent, probe, event)
		if ok then
			probe:UnregisterEvent(event)
		else
			failures = failures + 1
		end
		lines[#lines + 1] = string.format("[%s] %s (IsEventValid: %s)", ok and "PASS" or "FAIL", event, valid)
	end
	lines[#lines + 1] = ""
	if failures == 0 then
		lines[#lines + 1] = "All events register on this client."
	else
		lines[#lines + 1] = string.format("%d event(s) failed to register.", failures)
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- API Endpoints
--------------------------------------------------------------------------------

--[[
	Existence and shape checks only: read-only, no side effects, no protected calls. One row per
	API reached through a compatibility guard in Features/Utilities.lua, plus the load-bearing
	calls the scan, search and mail loops depend on. Modern and legacy fallbacks get their own rows.
]]
ns.DIAGNOSTIC_API_CHECKS = {
	-- { label, testFunction }
	{
		"C_AddOns.GetAddOnMetadata",
		function()
			return type(C_AddOns) == "table" and type(C_AddOns.GetAddOnMetadata) == "function"
		end,
	},
	{
		"C_Container.GetContainerNumSlots",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerNumSlots) == "function"
		end,
	},
	{
		"C_Container.GetContainerItemLink",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerItemLink) == "function"
		end,
	},
	{
		"C_Container.GetContainerItemInfo",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerItemInfo) == "function"
		end,
	},
	{
		"C_Container.UseContainerItem",
		function()
			return type(C_Container) == "table" and type(C_Container.UseContainerItem) == "function"
		end,
	},
	--[[
		No rows for the bare GetContainerNumSlots/GetContainerItemInfo globals: both target flavors
		ship C_Container, so a FAIL on a path the add-on cannot take reads as a defect.

		The C_TooltipInfo rows below are the opposite case, branched on at runtime by
		Features/Tooltip-Scanner.lua. They carry optional = true so absence reports ABSENT, not
		FAIL: neither shipped flavor has them, and a row that always fails teaches the reader to
		skim. Marked this way they still report PASS if a future build adds the API.
	]]
	{
		"C_Item.GetItemInfoInstant",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemInfoInstant) == "function"
		end,
	},
	{
		"GetItemInfoInstant [legacy]",
		function()
			return type(GetItemInfoInstant) == "function"
		end,
	},
	{
		"GetItemInfo",
		function()
			return type(GetItemInfo) == "function"
		end,
	},
	{
		"GetItemStats",
		function()
			return type(GetItemStats) == "function"
		end,
	},
	{
		"C_TooltipInfo.GetHyperlink",
		function()
			return type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetHyperlink) == "function"
		end,
		optional = true,
	},
	{
		"TooltipUtil.SurfaceArgs",
		function()
			return type(TooltipUtil) == "table" and type(TooltipUtil.SurfaceArgs) == "function"
		end,
		optional = true,
	},
	--[[
		The stat-name globals the locale-safe "+9 Intellect" path reads, probed one at a time:
		a missing one falls back to the English name and that stat silently never parses.
	]]
	{
		"ITEM_MOD_STRENGTH_SHORT",
		function()
			return type(ITEM_MOD_STRENGTH_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_AGILITY_SHORT",
		function()
			return type(ITEM_MOD_AGILITY_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_STAMINA_SHORT",
		function()
			return type(ITEM_MOD_STAMINA_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_INTELLECT_SHORT",
		function()
			return type(ITEM_MOD_INTELLECT_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_SPIRIT_SHORT",
		function()
			return type(ITEM_MOD_SPIRIT_SHORT) == "string"
		end,
	},
	--[[
		English-only by decision for the initial release, so this row fails on any other locale on
		purpose: a known limitation, rather than items quietly scoring low for no visible reason.
	]]
	{
		"Equip-effect parsing available (English clients only)",
		function()
			return ns.Tooltip.equipPatternsUsable == true
		end,
	},
	--[[
		Both of Blizzard's line formats, fed literal strings so these rows need no item, no cache
		and no tooltip and cannot flake. The second is the regression guard: a random-suffix roll
		arrives color-wrapped rather than bare, and when that form stops parsing every rolled green
		reads as statless and lands in the vendor pile while fixed-stat items carry on working. The
		escapes are built from parts because this label is printed into a font string unescaped,
		where a literal color code would be swallowed as formatting.
	]]
	{
		"Tooltip stat parsing, plain line",
		function()
			local stats = ns.Tooltip:StatsFromLines({ "Item Name", "+4 Intellect" })
			return stats.INTELLECT == 4
		end,
	},
	{
		"Tooltip stat parsing, color-wrapped line (random suffix and enchants)",
		function()
			local wrapped = "|" .. "cffffffff+15 Intellect|" .. "r\n"
			local stats = ns.Tooltip:StatsFromLines({ "Item Name", wrapped })
			return stats.INTELLECT == 15
		end,
	},
	--[[
		The third line format, and the one with no GetItemStats key behind it: a per-school damage
		roll exists only as tooltip text, so nothing covers it when this stops parsing.
	]]
	{
		"Tooltip stat parsing, equip-effect line",
		function()
			if not ns.Tooltip.equipPatternsUsable then
				return false
			end
			local stats = ns.Tooltip:StatsFromLines({
				"Item Name",
				"Equip: Increases damage done by Nature spells and effects by up to 7.",
			})
			return stats.NATURE == 7
		end,
	},
	--[[
		End to end on a real item: the rows above prove the parser understands the formats, this
		proves the client still hands back lines at all. Reports which path the read took, observed
		rather than inferred from whether the API exists, and separates the two ways this fails --
		a naked character, and a client that stopped handing back lines.
	]]
	{
		"Tooltip readable for a real item (needs something equipped)",
		function()
			for slot = 1, 19 do
				local link = GetInventoryItemLink("player", slot)
				if link then
					local _, source = ns.Tooltip:Stats(link)
					return source ~= "none", "read via " .. source
				end
			end
			return false, "nothing equipped to read"
		end,
	},
	--[[
		Load-bearing for routing, not display: the eligible class list is built from the client
		flavor and this answer, so a nil faction silently widens every item's candidate list.
	]]
	{
		"UnitFactionGroup returns this player's faction",
		function()
			local faction = UnitFactionGroup("player")
			return faction == "Alliance" or faction == "Horde"
		end,
	},
	{
		"C_FriendList.SendWho",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.SendWho) == "function"
		end,
	},
	{
		"C_FriendList.SetWhoToUi",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.SetWhoToUi) == "function"
		end,
	},
	{
		"C_FriendList.GetWhoInfo",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.GetWhoInfo) == "function"
		end,
	},
	{
		"C_FriendList.GetNumWhoResults",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.GetNumWhoResults) == "function"
		end,
	},
	--[[
		GetGuildRosterLastOnline is the one to watch: the activity window in
		Features/Guild-Roster.lua is built entirely on it, and without it every offline member
		reads as too stale to mail, leaving the guild to contribute only whoever is logged in.
	]]
	{
		"GetGuildRosterInfo",
		function()
			return type(GetGuildRosterInfo) == "function"
		end,
	},
	{
		"GetGuildRosterLastOnline",
		function()
			return type(GetGuildRosterLastOnline) == "function"
		end,
	},
	{
		"C_GuildInfo.GuildRoster",
		function()
			return (type(C_GuildInfo) == "table" and type(C_GuildInfo.GuildRoster) == "function")
				or type(GuildRoster) == "function"
		end,
	},
	{
		"C_PlayerInteractionManager.IsInteractingWithNpcOfType",
		function()
			return type(C_PlayerInteractionManager) == "table"
				and type(C_PlayerInteractionManager.IsInteractingWithNpcOfType) == "function"
		end,
	},
	{
		"Enum.PlayerInteractionType.MailInfo",
		function()
			return type(Enum) == "table"
				and type(Enum.PlayerInteractionType) == "table"
				and Enum.PlayerInteractionType.MailInfo ~= nil
		end,
	},
	{
		"SendMail",
		function()
			return type(SendMail) == "function"
		end,
	},
	{
		"GetSendMailItem",
		function()
			return type(GetSendMailItem) == "function"
		end,
	},
	{
		"C_XMLUtil.GetTemplateInfo",
		function()
			return type(C_XMLUtil) == "table" and type(C_XMLUtil.GetTemplateInfo) == "function"
		end,
	},
	--[[
		Where /pif actually lands. The failing case is silent by design -- the panel opens, just as
		a standalone window rather than the add-on's page in the Options interface.

		Reports the route rather than the APIs behind it: which of AddToBlizOptions' identifiers a
		client honors is not something the presence of Settings.OpenToCategory answers.
	]]
	{
		"Options panel opens inside the Blizzard interface",
		function()
			local _, inOptions, description = ns:OptionsPanelRoute()
			return inOptions, description
		end,
	},
}

--[[
	Three states, not two: a row marked optional reports ABSENT rather than FAIL when it comes back
	false, so FAIL stays reserved for rows where a false answer means something is actually broken.

	The detail is whatever the check learned on the way, appended to the label. pcall hands back
	every return value, so a check opts in just by returning a second one.
]]
function ns:RunApiChecks()
	local lines = { GetClientHeader(), "" }
	for _, check in ipairs(ns.DIAGNOSTIC_API_CHECKS) do
		local ok, result, detail = pcall(check[2])
		local status
		if ok and result then
			status = "[PASS] "
		elseif ok and check.optional then
			status = "[ABSENT] "
		else
			--[[
				A check that throws is a defect in the check, never an absence in the client, so it
				reports FAIL even on an optional row and carries the error text: without it a thrown
				check is indistinguishable from one that simply answered no.
			]]
			status = "[FAIL] "
		end
		local note = ok and detail or (not ok and tostring(result)) or nil
		lines[#lines + 1] = status .. check[1] .. (note and (" -- " .. note) or "")
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Display Context
--------------------------------------------------------------------------------

-- The window is movable, so off-screen and wrong-scale are real failure modes. Reads only.
function ns:BuildDisplayReport()
	local lines = { GetClientHeader(), "" }

	if type(GetPhysicalScreenSize) == "function" then
		local width, height = GetPhysicalScreenSize()
		lines[#lines + 1] = string.format("GetPhysicalScreenSize() = %s x %s", tostring(width), tostring(height))
	else
		lines[#lines + 1] = "GetPhysicalScreenSize: not available"
	end

	lines[#lines + 1] = string.format("UIParent:GetScale() = %s", tostring(UIParent and UIParent:GetScale()))
	lines[#lines + 1] = string.format("CVar uiScale = %s", tostring(GetCVar and GetCVar("uiScale")))
	lines[#lines + 1] = string.format("CVar useUiScale = %s", tostring(GetCVar and GetCVar("useUiScale")))

	local saved = ns.db and ns.db.profile.windowPos
	if saved and saved.point then
		lines[#lines + 1] = string.format(
			"Saved window position: %s relative %s at %.1f, %.1f",
			tostring(saved.point),
			tostring(saved.relativePoint),
			saved.x or 0,
			saved.y or 0
		)
	else
		lines[#lines + 1] = "Saved window position: none, the window anchors to the mailbox"
	end

	local frame = ns.UI and ns.UI.frame
	if frame then
		lines[#lines + 1] = string.format(
			"Window: shown=%s size=%dx%d",
			tostring(frame:IsShown()),
			math.floor(frame:GetWidth() or 0),
			math.floor(frame:GetHeight() or 0)
		)
	else
		lines[#lines + 1] = "Window: not built yet this session"
	end

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Shared Formatting
--------------------------------------------------------------------------------

local function FormatStats(stats)
	local keys = {}
	for token in pairs(stats or {}) do
		keys[#keys + 1] = token
	end
	if #keys == 0 then
		return "(none)"
	end
	table.sort(keys)
	local parts = {}
	for _, token in ipairs(keys) do
		parts[#parts + 1] = string.format("%s %s", token, tostring(stats[token]))
	end
	return table.concat(parts, ", ")
end

-- The internal state tokens spelled out for someone deciding whether to vendor the item.
local VERDICT_TEXT = {
	gift = "gift",
	leftover = "vendor/disenchant",
	unreadable = "STATS UNREADABLE, held back rather than matched or vendored",
}

-- Shared by the bag export and the single-item verdict, so the two cannot disagree.
local function AppendVerdict(lines, item, indent)
	-- The same verdict the window acts on, never a second opinion computed here.
	local verdict = ns.Matcher:VerdictFor(item)
	local eligible = verdict.eligible
	local bandLo, bandHi = ns.Matcher:LevelBand(item)

	-- What the item IS: equipLoc and subclass route it down the weapon matrix or the armor one.
	lines[#lines + 1] = string.format(
		"%skind: %s, equip %s, class %s/%s (%s), ilvl %s, requires %s, quality %s",
		indent,
		tostring(item.kind or "?"),
		tostring(item.equipLoc ~= "" and item.equipLoc or "none"),
		tostring(item.classID),
		tostring(item.subclassID),
		ns.Data.UsesWeaponMatrix(item) and ("weapon matrix: " .. tostring(ns.Data.WeaponKey(item) or "no key"))
			or ("armor: " .. tostring(ns.Data.ArmorSubclass[item.subclassID] or "universal, stats alone decide")),
		tostring(item.itemLevel or "?"),
		tostring(item.reqLevel or "?"),
		tostring(item.quality or "?")
	)

	--[[
		All three lines matter separately: the merge takes the max per stat, so GetItemStats
		covering fixed-stat items while the tooltip returns nothing looks like both working.
	]]
	local read = item.statRead or {}
	lines[#lines + 1] = indent .. "stats: " .. FormatStats(item.stats)
	lines[#lines + 1] = indent .. "  GetItemStats: " .. FormatStats(read.api)
	lines[#lines + 1] = indent
		.. "  tooltip: "
		.. FormatStats(read.tooltip)
		.. " (via "
		.. tostring(read.source or "not recorded")
		.. ")"

	-- Without this, an item that reads three stats cleanly and drops a fourth shows nothing amiss.
	if read.unread and #read.unread > 0 then
		lines[#lines + 1] = indent .. "  NOT UNDERSTOOD, these look like stat lines and matched no rule:"
		for _, text in ipairs(read.unread) do
			lines[#lines + 1] = indent .. "    | " .. text
		end
	end

	-- A suffixed item with nothing parsed is a read failure, not a plain item. Say so outright.
	local suffix = ns.ItemSuffixID(item.link)
	if suffix then
		local parsed = next(item.stats or {}) ~= nil
		lines[#lines + 1] = string.format(
			"%srandom suffix %d: %s",
			indent,
			suffix,
			parsed and "stats read" or "NO STATS READ, this item is a parse failure and stays unmatched"
		)
		--[[
			What the client actually rendered, failure case only: an uncovered line and no stat
			line at all both print as an empty list, and only the raw lines tell them apart.
		]]
		if not parsed and read.lines then
			lines[#lines + 1] = indent .. "  tooltip as rendered, since nothing parsed:"
			for _, text in ipairs(read.lines) do
				if text ~= "" then
					lines[#lines + 1] = indent .. "    | " .. text
				end
			end
		end
	end

	if #eligible == 0 then
		lines[#lines + 1] = indent .. "eligible: none, no class can use this"
	else
		--[[
			"use" is the share of the item's scoreable stats this class ranks. Two classes can
			print an identical claim, and only this column says which one takes the item.
		]]
		local parts = {}
		for _, class in ipairs(eligible) do
			--[[
				Floored rather than handed to %d as a fraction: a remainder truncates silently on
				this client's Lua and errors on a stricter one.
			]]
			parts[#parts + 1] = string.format(
				"%s claim %.2f fit %.2f use %d%% g%d",
				class,
				ns.Matcher:SpecScore(item, class),
				ns.Matcher:Score(item, class),
				math.floor(ns.Matcher:Coverage(item, class) * 100),
				ns.Matcher:Priority(item, class)
			)
		end
		table.sort(parts)
		lines[#lines + 1] = indent .. "eligible: " .. table.concat(parts, " | ")
	end

	-- Eligible is who could wear it, admitted is who may receive it: the gap answers "why not sent".
	local admitted = (#verdict.admitted > 0) and table.concat(verdict.admitted, ", ")
		or "nobody, so this item has no possible recipient"
	lines[#lines + 1] = indent .. "admitted: " .. admitted

	lines[#lines + 1] = string.format(
		"%sbest fit: %s score %.2f threshold %.2f -> %s",
		indent,
		tostring(verdict.best or "nobody"),
		verdict.score or 0,
		ns.Data.LEFTOVER_THRESHOLD,
		VERDICT_TEXT[verdict.state] or verdict.state
	)

	--[[
		"best fit" is one class picked on score and group; the recipient is picked on level
		proximity across everyone in contention, and the two disagree constantly.
	]]
	local contenders = verdict.contenders or {}
	if #verdict.admitted > 1 then
		if #contenders == 1 then
			lines[#lines + 1] = string.format("%sin contention: %s alone", indent, contenders[1])
		else
			lines[#lines + 1] = string.format(
				"%sin contention: %s -- level proximity to %d decides between them",
				indent,
				table.concat(contenders, ", "),
				bandHi
			)
		end
	end

	--[[
		Admitted but not in contention, with the reason per class: "uses 50%" lost on breadth, a
		claim figure means it wanted the item less.
	]]
	local inContention = {}
	for _, class in ipairs(contenders) do
		inContention[class] = true
	end
	local demoted = {}
	for _, class in ipairs(verdict.admitted) do
		if not inContention[class] then
			local used = (verdict.coverage or {})[class] or 1
			demoted[#demoted + 1] = (used <= ns.Data.COVERAGE_MAJORITY)
					and string.format("%s (uses %d%% of it)", class, used * 100)
				or string.format("%s (claim %.2f)", class, verdict.claims[class] or 0)
		end
	end
	if #demoted > 0 then
		table.sort(demoted)
		lines[#lines + 1] = indent
			.. "fallback only: "
			.. table.concat(demoted, ", ")
			.. " -- offered when nobody above is in range"
	end

	--[[
		Printed with the two constants that produced it: without them "level band: 18 to 18"
		reads as a fact about the item when it is a fact about the gaps.
	]]
	local low, high = ns.Data.LEVEL_GAP_WIDEST, ns.Data.LEVEL_GAP_CLOSEST
	lines[#lines + 1] = string.format(
		"%slevel band: %d to %d, preferring %d (requires %d, minus gaps of %d and %d)",
		indent,
		bandLo,
		bandHi,
		bandHi,
		item.reqLevel or 1,
		low,
		high
	)
	-- WIDEST at or below CLOSEST collapses the band to one level, which is drastic and invisible.
	if bandLo == bandHi then
		lines[#lines + 1] = string.format(
			"%s  ONE LEVEL ONLY. Widest Level Gap (%d) is not above Closest Level Gap (%d), so the band "
				.. "collapsed: this item will only ever match somebody at exactly level %d. "
				.. "Raise Widest Level Gap to search a range.",
			indent,
			low,
			high,
			bandHi
		)
	end
end

--------------------------------------------------------------------------------
-- Bag Scan Export
--------------------------------------------------------------------------------

--[[
	The rejected rows are the point: "why is this green not in the list" is answered here and
	nowhere else. Re-runs the same Scanner:Classify the window uses, so the two cannot disagree.
]]
function ns:BuildBagScanReport()
	local lines = { GetClientHeader(), "" }
	local rows = ns.Scanner:ScanAll()

	if #rows == 0 then
		lines[#lines + 1] = "(no items in bags)"
		return table.concat(lines, "\n")
	end

	--[[
		Accepted is not giftable: passing the hard filter only means the slot holds a tradeable
		green. Whether anyone wants it is the verdict, counted separately below.
	]]
	local accepted, byState, byReason = 0, {}, {}
	for _, row in ipairs(rows) do
		local name, _, quality, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID, bindType =
			GetItemInfo(row.link)
		lines[#lines + 1] = string.format(
			"bag %d slot %d | %s | id %s | quality %s | req %s | %s | class %s/%s | bind %s",
			row.bag,
			row.slot,
			tostring(name or "uncached"),
			tostring(ns.GetInfoInstant(row.link)),
			tostring(quality),
			tostring(reqLevel),
			tostring(equipLoc ~= "" and equipLoc or "(none)"),
			tostring(classID),
			tostring(subclassID),
			tostring(bindType)
		)
		lines[#lines + 1] = "    link: " .. EscapePipes(row.link)

		if row.item then
			accepted = accepted + 1
			local state = ns.Matcher:VerdictFor(row.item).state
			byState[state] = (byState[state] or 0) + 1
			lines[#lines + 1] = "    ACCEPTED as " .. tostring(row.item.kind)
			if row.item.kind == "gear" then
				AppendVerdict(lines, row.item, "    ")
			else
				local lo, hi = ns.Matcher:LevelBand(row.item)
				lines[#lines + 1] =
					string.format("    consumable, recipient levels %s to %s", tostring(lo), tostring(hi))
			end
		else
			byReason[row.reason] = (byReason[row.reason] or 0) + 1
			lines[#lines + 1] = "    REJECTED: " .. tostring(row.reason)
		end
		lines[#lines + 1] = ""
	end

	-- ScanAll leaves empty slots out, so this counts occupied slots, never bag size.
	lines[#lines + 1] =
		string.format("%d occupied slot(s), %d accepted, %d rejected.", #rows, accepted, #rows - accepted)
	lines[#lines + 1] = string.format(
		"Of the %d accepted: %d to gift, %d to vendor/disenchant, %d with unreadable stats.",
		accepted,
		byState[ns.Matcher.GIFT] or 0,
		byState[ns.Matcher.LEFTOVER] or 0,
		byState[ns.Matcher.UNREADABLE] or 0
	)
	local reasons = {}
	for reason, count in pairs(byReason) do
		reasons[#reasons + 1] = string.format("%s x%d", reason, count)
	end
	table.sort(reasons)
	if #reasons > 0 then
		lines[#lines + 1] = "Rejections: " .. table.concat(reasons, ", ")
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Recipient Roster Export
--------------------------------------------------------------------------------

--[[
	Everyone the /who stepper has found, with fairness state and what the parser discarded: a thin
	roster is usually unresolvable class tokens, not an empty realm.
]]
function ns:BuildRosterReport()
	local lines = { GetClientHeader(), "" }
	local pools = (ns.UI and ns.UI.Pools and ns.UI:Pools()) or {}
	local items = (ns.UI and ns.UI.Items and ns.UI:Items()) or {}

	--[[
		Labeled by slot, not name alone: two copies of one green share a name, so "Ivycloth
		Robe, Ivycloth Robe" cannot say whether that is two items or a repeated line.
	]]
	local candidateFor = {}
	for _, item in ipairs(items) do
		if item.eligible then
			local label =
				string.format("%s (bag %s slot %s)", item.name or item.link, tostring(item.bag), tostring(item.slot))
			for _, person in ipairs(ns.Matcher:RankCandidates(item, pools)) do
				candidateFor[person.name] = candidateFor[person.name] or {}
				table.insert(candidateFor[person.name], label)
			end
		end
	end

	local classes, total = {}, 0
	for class, list in pairs(pools) do
		classes[#classes + 1] = class
		total = total + #list
	end
	table.sort(classes)

	lines[#lines + 1] = string.format("%d player(s) known across %d class(es).", total, #classes)
	for _, class in ipairs(classes) do
		lines[#lines + 1] = string.format("  %s: %d", class, #pools[class])
	end
	lines[#lines + 1] = ""

	local stats = ns.Who:ResultStats()
	lines[#lines + 1] = string.format(
		"Who results seen %d, kept %d, of which %d from a connected realm. Dropped %d for an unreadable class.",
		stats.seen,
		stats.seen - stats.unknownClass,
		stats.connectedRealm,
		stats.unknownClass
	)
	-- Only once an answer has been truncated: a permanent "capped 0" row trains the eye to skip it.
	if stats.capped > 0 then
		lines[#lines + 1] = string.format(
			"%d quer(ies) came back full at the %d-result cap, so the server had more to send. "
				.. "Not chased: an item needs one recipient, not every candidate.",
			stats.capped,
			ns.Who.RESULT_CAP
		)
	end
	local searchLine = string.format(
		"Search: %d place(s) left to look of %d, next %s.",
		ns.Who:Remaining(),
		ns.Who:Planned(),
		tostring(ns.Who:Peek() or "none")
	)
	--[[
		Only once something has been pruned, for the same reason the cap row above is conditional.
		Without it the two numbers do not reconcile: places-left drops without a press whenever an
		assignment finishes off a band, which otherwise reads as queries going missing.
	]]
	if stats.pruned > 0 then
		searchLine = searchLine .. string.format(" %d dropped once their band was matched.", stats.pruned)
	end
	lines[#lines + 1] = searchLine

	--[[
		"The guild added nobody" and "the guild has nobody active" look identical from the match
		list, and only one of them is a bug worth chasing.
	]]
	local guild = ns.Guild:Stats()
	if guild.rows > 0 then
		-- Reads the window off ns.Guild rather than naming it here, which would drift the day it changes.
		lines[#lines + 1] =
			string.format("Guild: %d of %d eligible, %d online.", guild.eligible, guild.rows, guild.online)
		lines[#lines + 1] = string.format(
			"  Dropped: %d not on in %d day(s), %d summoning alts, %d of your own characters, %d unreadable.",
			guild.stale,
			ns.Guild.ACTIVE_DAYS,
			guild.summonAlts,
			guild.ownAlts,
			guild.unreadable
		)
	end

	--[[
		Reported once for both sources because it is enforced once for both, and only when it has
		actually turned somebody away, on the same reasoning as the cap row above.
	]]
	local tooLow = ns.MatchList:TooLowCount()
	if tooLow > 0 then
		lines[#lines + 1] = string.format(
			"Level floor: %d candidate(s) turned away below level %d, from every source.",
			tooLow,
			ns.Data.MIN_RECIPIENT_LEVEL
		)
	end
	lines[#lines + 1] = ""

	if total == 0 then
		lines[#lines + 1] = "(no players found yet, press Find Recipients)"
		return table.concat(lines, "\n")
	end

	for _, class in ipairs(classes) do
		for _, person in ipairs(pools[class]) do
			local fresh = ns.Fairness:IsFresh(person.name, person.level)
			local wanted = candidateFor[person.name]
			lines[#lines + 1] = string.format(
				"%s | level %s | %s | %s | %s | candidate for: %s",
				tostring(person.name),
				tostring(person.level),
				tostring(person.class),
				tostring(person.area or "?"),
				fresh and "fresh" or "on cooldown",
				wanted and EscapePipes(table.concat(wanted, ", ")) or "nothing"
			)
		end
	end

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Item Verdict
--------------------------------------------------------------------------------

-- One pasted link, both stat sources side by side so a parse failure is visible as one.
function ns:BuildItemVerdictReport(link)
	local lines = { GetClientHeader(), "" }
	if not link or link == "" then
		lines[#lines + 1] = "Paste an item link into the box above first."
		return table.concat(lines, "\n")
	end

	local item = ns.Scanner:Describe(link)
	if not item then
		lines[#lines + 1] = "Could not read that item. Paste a real item link."
		return table.concat(lines, "\n")
	end

	lines[#lines + 1] = "item: " .. EscapePipes(item.link)

	if not ns.Tooltip.equipPatternsUsable then
		lines[#lines + 1] = string.format(
			'NOTE: equip-effect parsing is English-only and this client is %s, so any stat written as an "Equip: ..." line is not counted above.',
			GetLocale()
		)
	end
	AppendVerdict(lines, item, "")
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Class Groups
--------------------------------------------------------------------------------

--[[
	Both reports print only classes that can exist for this player, the same list the matcher
	routes on: the full ten would make a phantom class look like a real routing decision.
]]
local function AvailableClasses()
	local set = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		set[class] = true
	end
	return set
end

local function GroupedByTier(byClass, maxTier, available)
	local byTier = {}
	for class, tier in pairs(byClass) do
		if not available or available[class] then
			byTier[tier] = byTier[tier] or {}
			table.insert(byTier[tier], class)
		end
	end
	local parts = {}
	for tier = 1, maxTier do
		if byTier[tier] then
			table.sort(byTier[tier])
			parts[#parts + 1] = table.concat(byTier[tier], ", ")
		end
	end
	return #parts > 0 and table.concat(parts, " / ") or "(nobody)"
end

-- Names the resolved class list, so a wrong flavor or faction gate is visible at a glance.
local function AppendClassLine(lines)
	local classes = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		classes[#classes + 1] = class
	end
	table.sort(classes)
	lines[#lines + 1] = string.format(
		"Classes on this client and faction (%s): %s",
		tostring(UnitFactionGroup("player") or "unknown"),
		table.concat(classes, ", ")
	)
	lines[#lines + 1] = ""
end

function ns:BuildArmorGroupsReport(level)
	level = tonumber(level) or UnitLevel("player") or 60
	local lines = { GetClientHeader(), "" }
	AppendClassLine(lines)
	local available = AvailableClasses()
	lines[#lines + 1] = string.format("Armor groups for an item requiring level %d:", level)
	for _, armorType in ipairs({ "CLOTH", "LEATHER", "MAIL", "PLATE" }) do
		lines[#lines + 1] = string.format(
			"  %-8s %s",
			armorType:lower(),
			GroupedByTier(ns.Data.ArmorPriorityFor(armorType, level) or {}, 9, available)
		)
	end
	return table.concat(lines, "\n")
end

local WEAPON_ORDER = {
	"1H_SWORD",
	"2H_SWORD",
	"1H_MACE",
	"2H_MACE",
	"1H_AXE",
	"2H_AXE",
	"DAGGER",
	"FIST",
	"POLEARM",
	"STAFF",
	"BOW",
	"GUN",
	"CROSSBOW",
	"THROWN",
	"WAND",
	"SHIELD",
	"HELD",
}

function ns:BuildWeaponGroupsReport(level)
	level = tonumber(level) or UnitLevel("player") or 60
	local lines = { GetClientHeader(), "" }
	AppendClassLine(lines)
	lines[#lines + 1] =
		string.format("Weapon priority for an item requiring level %d (group 1 = every spec wants it):", level)
	for _, weaponKey in ipairs(WEAPON_ORDER) do
		local byClass = {}
		for _, class in ipairs(ns.Matcher:Classes()) do
			local group = ns.Data.WeaponPriorityFor(weaponKey, class, level)
			if group then
				byClass[class] = group
			end
		end
		lines[#lines + 1] = string.format("  %-9s %s", weaponKey:lower(), GroupedByTier(byClass, 3))
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Outgoing Mail Preview
--------------------------------------------------------------------------------

function ns:BuildMailPreviewReport()
	local lines = { GetClientHeader(), "" }
	local subject = ns.Distributor:BuildSubject()
	local body = ns.Distributor:BuildBody()

	lines[#lines + 1] = string.format("subject (%d/%d): %s", #subject, ns.Distributor.SUBJECT_MAX, subject)
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("body (%d/%d):", #body, ns.Distributor.BODY_MAX)
	if body == "" then
		lines[#lines + 1] = "  (empty)"
	else
		for line in (body .. "\n"):gmatch("([^\n]*)\n") do
			lines[#lines + 1] = "  " .. line
		end
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Other Add-ons
--------------------------------------------------------------------------------

function ns:BuildAddOnReport()
	local lines = { GetClientHeader(), "" }
	local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
	local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	local count = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns()) or GetNumAddOns()
	for index = 1, count do
		local name, _, _, loadable = getInfo(index)
		local version = getMeta(index, "Version") or "?"
		lines[#lines + 1] = string.format("%s v%s [%s]", name, version, loadable and "loadable" or "disabled")
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Saved Variables
--------------------------------------------------------------------------------

local function DumpTable(value, indent, depth, lines)
	if depth > 8 then
		lines[#lines + 1] = indent .. "<max depth>"
		return
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	for _, key in ipairs(keys) do
		local entry = value[key]
		if type(entry) == "table" then
			lines[#lines + 1] = indent .. tostring(key) .. " = {"
			DumpTable(entry, indent .. "    ", depth + 1, lines)
			lines[#lines + 1] = indent .. "}"
		else
			lines[#lines + 1] = indent .. tostring(key) .. " = " .. EscapePipes(entry)
		end
	end
end

function ns:BuildSavedVariablesReport()
	local lines = { GetClientHeader(), "", "PlayItForwardDB = {" }
	DumpTable(PlayItForwardDB or {}, "    ", 1, lines)
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Library Versions
--------------------------------------------------------------------------------

function ns:BuildLibraryReport()
	local lines = { GetClientHeader(), "" }
	local names = {}
	for name in LibStub:IterateLibraries() do
		names[#names + 1] = name
	end
	table.sort(names)
	for _, name in ipairs(names) do
		lines[#lines + 1] = string.format("%s (minor %s)", name, tostring(LibStub.minors[name]))
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Taint Log
--------------------------------------------------------------------------------

-- taintLog writes to Logs\taint.log: level 2 logs blocked actions and tainted-global reads, 0 off.

function ns:GetTaintLogState()
	return tonumber(GetCVar("taintLog")) or 0
end

function ns:SetTaintLog(enabled)
	SetCVar("taintLog", enabled and 2 or 0)
end
