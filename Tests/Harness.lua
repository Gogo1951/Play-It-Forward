--[[
	Loads the add-on against Tests/Stub-WoW-API.lua. Every case loads its own copy: items, pools
	and assignedTo are file-scope locals in Features/Match-List.lua that nothing wipes, so cases
	sharing a load would see each other's bags.
]]

local Stub = require("Stub-WoW-API")

local Harness = { Stub = Stub }

--[[
	TOC load order, minus the libraries and most options panels. Order is load-bearing: Flavor.lua
	sets the flavor the data files read, Data.lua seeds ns.Data, and the locale registers first.
]]
local FILES = {
	"Locales/enUS.lua",
	"Data/Flavor.lua",
	"Data/Data.lua",
	"FLAVOR_FOLDER",
	"Data/Default-Settings.lua",
	"Features/Utilities.lua",
	"Features/Menu-Kit.lua",
	"Features/Scan-Tooltip.lua",
	"Features/Scan-Bags.lua",
	"Features/Match-Derivations.lua",
	"Features/Match-Engine.lua",
	"Features/Match-Ranking.lua",
	"Features/Match-List.lua",
	"Features/Match-Roster.lua",
	"Features/Match-Search.lua",
	"Features/Recipients-Who-Plan.lua",
	"Features/Recipients-Zones.lua",
	"Features/Recipients-Who.lua",
	"Features/Recipients-Guild.lua",
	"Features/Recipients-Alts.lua",
	"Features/Recipients-Fairness.lua",
	"Features/Mail-Sender.lua",
	"Features/Mail-Copy.lua",
	"Features/UI-Picker.lua",
	"Features/UI-Window.lua",
	"Features/UI-Top-Bar.lua",
	"Features/UI-Status.lua",
	"Features/UI-Assignment.lua",
	"Features/UI-Mailbox.lua",
	"Features/UI-Mailbox-Tab.lua",
	"Features/Generosity.lua",
	"Features/Generosity-Broadcast.lua",
	"Features/Generosity-Tooltip.lua",
	"Diagnostics/Diagnostics-Core.lua",
	"Diagnostics/Manifests.lua",
	"Diagnostics/Event-Log.lua",
	"Diagnostics/Code-Reports.lua",
	"Diagnostics/Settings-Reports.lua",
	"Diagnostics/Validate-Data.lua",
	"Diagnostics/Localization-Reports.lua",
	"Diagnostics/Report-Runner.lua",
	-- Panel builders the stubbed libraries can run whole.
	"Options/Options-Kit.lua",
	"Options/Options-Utilities.lua",
	"Options/Options-Recipients.lua",
	"Options/Options-Alts.lua",
	"Options/Options-Guilds.lua",
	-- For /pif and the Settings combat gate, which Tests/Options-Open.lua drives.
	"Options/Options.lua",
}

local ADDON = "Play-It-Forward"

-- FLAVOR_FOLDER follows Stub.flavor; Classic Era's TOC lists Discovery's folder after its own.
local FLAVOR_TABLES = {
	"Match-Stat-Budget",
	"Scan-Food",
	"Scan-Potions",
	"Scan-Scrolls",
	"Scan-Oils-Stones",
	"Recipients-Zones",
	"Recipients-Realms",
	"Match-Weapons",
	"Match-Armor",
	"Match-Classes",
	"Match-Specs",
	"Match-Rules",
	"Scan-Stats",
	"Game-IDs",
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
	The two modules not loaded whole, injected first so files calling them at load find them.
	Every other file the add-on runs at a mailbox is the real one; only the client is stubbed.
]]
local function injectModules(ns, events)
	ns.On = function(event, fn)
		events[event] = events[event] or {}
		table.insert(events[event], fn)
	end

	ns.PrintMessage = function(_, message)
		table.insert(Stub.printed, message)
	end
	ns.PrintWarning = ns.PrintMessage

	-- Undecorated: cases assert what a line says, never its color escapes.
	ns.BuildBrandedLine = function(_, message, nameKey)
		return ((ns.L and ns.L[nameKey or "ADDON_TITLE"]) or "") .. " // " .. tostring(message)
	end

	--[[
		Core.lua is not loaded; "Dev" is its answer for an unpackaged copy. Left nil, the
		diagnostics header's string.format raises on Lua 5.1, where 5.4 would print "nil".
	]]
	ns.Version = "Dev"
end

-- setup runs between the stubs and the add-on's files, for a global the add-on reads at load.
function Harness.LoadAddon(root, setup)
	Stub.Install()
	if setup then
		setup()
	end

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
		Built after every file, as ADDON_LOADED is in the game, so a file reading ns.db at load
		fails here. profileKeys lives on the raw sv, not db: the own-alt check in
		Features/Recipients-Guild.lua reads it there.
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

	--[[
		Open the mailbox, then click the gift tab: the window never opens by itself. A window
		already up is left alone, since a second click would close it.
	]]
	ns.visitMailbox = function()
		MailFrame:Show()
		ns.fire("MAIL_SHOW")
		if not (ns.UI.frame and ns.UI.frame:IsShown()) then
			PlayItForwardMailboxTab:GetScript("OnClick")(PlayItForwardMailboxTab)
		end
	end

	return ns
end

--------------------------------------------------------------------------------
-- Assertions
--------------------------------------------------------------------------------

local cases = {}

--[[
	Every spec on, for a case whose point is a mechanism (demotion, armor training, a band per
	group) written with a Retribution paladin or Feral druid. Tests/Spec-Choices.lua pins defaults.
]]

function Harness.AllSpecs(ns)
	for class, specs in pairs(ns.Data.SPECS) do
		ns.db.profile.specs[class] = {}
		for _, spec in ipairs(specs) do
			ns.db.profile.specs[class][spec.key] = true
		end
	end
	ns.Data.RebuildStatWeights()
	return ns
end

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
