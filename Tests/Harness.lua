--[[
	Loads the add-on against Tests/Stub-WoW-API.lua and gives a test somewhere to
	assert from.

	Every case loads its own copy. items, pools and assignedTo are file-scope locals in
	Features/Match-List.lua and nothing wipes them by design -- that is what makes
	matches survive walking away from a mailbox -- so two cases sharing one load would
	see each other's bags.
]]

local Stub = require("Stub-WoW-API")

local Harness = { Stub = Stub }

--[[
	The load order from the TOC, minus the libraries and the files that only build
	options panels. Order is load-bearing: Flavor.lua sets the flavor the data files read
	as they load, Data.lua seeds ns.Data, and the locale has to register before Data.lua
	asks for it.
]]
local FILES = {
	"Locales/enUS.lua",
	"Data/Flavor.lua",
	"Data/Data.lua",
	"FLAVOR_FOLDER",
	"Data/Match-Stats.lua",
	"Data/Match-Armor.lua",
	"Data/Match-Rules.lua",
	"Data/Scan-Stats.lua",
	"Data/Default-Settings.lua",
	"Features/Utilities.lua",
	"Features/Scan-Tooltip.lua",
	"Features/Scan-Bags.lua",
	"Features/Match-Derivations.lua",
	"Features/Match-Engine.lua",
	"Features/Match-Ranking.lua",
	"Features/Match-List.lua",
	"Features/Recipients-Who-Plan.lua",
	"Features/Recipients-Who.lua",
	"Features/Recipients-Guild.lua",
	"Features/Recipients-Fairness.lua",
	"Features/Mail-Sender.lua",
	"Features/UI-Picker.lua",
	"Features/UI-Window.lua",
	"Features/UI-Assignment.lua",
	"Features/UI-Mailbox.lua",
	"Features/Generosity.lua",
	"Features/Generosity-Broadcast.lua",
	"Features/Generosity-Tooltip.lua",
	"Diagnostics/Diagnostics-Core.lua",
	"Diagnostics/Manifests.lua",
	"Diagnostics/Event-Log.lua",
	"Diagnostics/Code-Reports.lua",
	"Diagnostics/Settings-Reports.lua",
	"Diagnostics/Localization-Reports.lua",
	"Diagnostics/Validate-Data.lua",
	"Diagnostics/Report-Runner.lua",
	--[[
		Not only panels either: the /pif slash command and the combat gate in front of
		the Settings panel live here, and Tests/Options-Open.lua drives both. The panel
		builders themselves stay out; the stub answers their libraries with catch-alls.
	]]
	"Options/Options.lua",
}

local ADDON = "Play-It-Forward"

--[[
	Each TOC lists its own data folder where FLAVOR_FOLDER sits above, so the folder follows
	Stub.flavor. Classic Era's TOC lists Discovery's folder after its own, as the client does.
]]
local FLAVOR_TABLES = {
	"Match-Stat-Budget",
	"Scan-Food",
	"Scan-Potions",
	"Scan-Scrolls",
	"Recipients-Zones",
	"Match-Weapons",
	"Match-Armor",
	"Match-Classes",
}

local function flavorFiles(flavor)
	local folders = (flavor == "Vanilla") and { "Vanilla", "Discovery" } or { flavor }
	local out = {}
	for _, folder in ipairs(folders) do
		for _, name in ipairs(FLAVOR_TABLES) do
			out[#out + 1] = ("Data/%s/%s-%s.lua"):format(folder, name, folder)
		end
	end
	return out
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, inner in pairs(value) do
		out[key] = copy(inner)
	end
	return out
end

--[[
	The two modules not worth loading whole, injected before anything else so the files
	that call them at load time find them there.

	There are no longer any exclusions: every file the add-on runs at a mailbox is the
	real one. The delivery race lives in Mail-Sender.lua, the query planning in
	Recipients-Who.lua and the suffix parsing in Scan-Tooltip.lua, and answering any
	of them with a stub would test the answer rather than the code. The client is stubbed
	instead, down to the scanning tooltip.
]]
local function injectModules(ns, events)
	ns.on = function(event, fn)
		events[event] = events[event] or {}
		table.insert(events[event], fn)
	end

	ns.PrintMessage = function(_, message)
		table.insert(Stub.printed, message)
	end
	ns.PrintWarning = ns.PrintMessage

	--[[
		Undecorated on purpose: cases assert what a line says, never its color escapes, and the
		real format lives in Features/Announcements.lua rather than being pinned a second time
		here. The name and separator are present because callers render them as one string.
	]]
	ns.BuildBrandedLine = function(_, message)
		return ((ns.L and ns.L["ADDON_TITLE"]) or "") .. " // " .. tostring(message)
	end

	--[[
		Core.lua sets this at load and is not loaded here. "Dev" is what it answers for an
		unpackaged copy. Left nil, the diagnostics header's string.format raises on Lua 5.1,
		the version WoW embeds, where 5.4 would quietly print "nil".
	]]
	ns.Version = "Dev"
end

--[[
	A freshly loaded add-on, its saved variables at shipped defaults, plus a handle for
	firing the events the client would.
]]
function Harness.LoadAddon(root)
	Stub.Install()

	local ns = {}
	local events = {}
	injectModules(ns, events)

	local function run(file)
		local chunk = assert(loadfile(root .. "/" .. file))
		chunk(ADDON, ns)
	end
	for _, file in ipairs(FILES) do
		if file == "FLAVOR_FOLDER" then
			for _, flavorFile in ipairs(flavorFiles(Stub.flavor)) do
				run(flavorFile)
			end
		else
			run(file)
		end
	end

	--[[
		Saved variables arrive at ADDON_LOADED in the game, which is after every file has
		loaded, so building them here rather than earlier is not a convenience. A file
		reading ns.db at load time would be a bug and this ordering is what catches it.

		Both scopes are seeded, the way AceDB seeds profile and global alike: the giving tally
		lives in global.stats, so a case that never touched it would still expect it present.
	]]
	--[[
		sv is the raw saved table AceDB hangs its own bookkeeping off, and profileKeys lives
		there rather than on db: the own-alt check in Features/Recipients-Guild.lua reads it,
		and db.profileKeys answers nil. Empty by default; a case that wants alts seeds it.
	]]
	ns.db = {
		profile = copy(ns.DATABASE_DEFAULTS.profile),
		global = copy(ns.DATABASE_DEFAULTS.global),
		sv = { profileKeys = {} },
	}

	ns.fire = function(event, ...)
		for _, fn in ipairs(events[event] or {}) do
			fn(...)
		end
	end
	ns.registered = function(event)
		return events[event] ~= nil
	end

	return ns
end

--------------------------------------------------------------------------------
-- Assertions
--------------------------------------------------------------------------------

local cases = {}

function Harness.test(name, fn)
	table.insert(cases, { name = name, fn = fn })
end

local current

function Harness.check(ok, message)
	table.insert(current.checks, { ok = ok and true or false, message = message })
	if not ok then
		current.failed = true
	end
end

function Harness.equal(actual, expected, message)
	Harness.check(actual == expected, ("%s (got %s, want %s)"):format(message, tostring(actual), tostring(expected)))
end

function Harness.run()
	local failures = 0
	for _, case in ipairs(cases) do
		current = { checks = {} }
		local ok, err = pcall(case.fn)
		if not ok then
			current.failed = true
			table.insert(current.checks, { ok = false, message = "error: " .. tostring(err) })
		end
		if current.failed then
			failures = failures + 1
			print(("FAIL  %s"):format(case.name))
			for _, check in ipairs(current.checks) do
				if not check.ok then
					print(("        %s"):format(check.message))
				end
			end
		else
			print(("ok    %s"):format(case.name))
		end
	end
	print(("\n%d case(s), %d failed"):format(#cases, failures))
	return failures
end

return Harness
