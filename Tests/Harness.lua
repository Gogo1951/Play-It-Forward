--[[
	Loads the add-on against Tests/Stub-WoW-API.lua and gives a test somewhere to
	assert from.

	Every case loads its own copy. items, pools and assignedTo are file-scope locals in
	Features/Mail-Window.lua and nothing wipes them by design -- that is what makes
	matches survive walking away from a mailbox -- so two cases sharing one load would
	see each other's bags.
]]

local Stub = require("Stub-WoW-API")

local Harness = { Stub = Stub }

--[[
	The load order from the TOC, minus the libraries and the files that only build
	options panels. Order is load-bearing: Data.lua seeds ns.Data and the flavor flags
	the data files read as they load, and the locale has to register before Data.lua
	asks for it.
]]
local FILES = {
	"Locales/enUS.lua",
	"Data/Data.lua",
	"Data/Default-Settings.lua",
	"Data/Stat-Map.lua",
	"Data/Stat-Weights.lua",
	"Data/Item-Rules.lua",
	"Data/Armor-Priority.lua",
	"Data/Weapon-Priority.lua",
	"Data/Food-And-Water.lua",
	"Data/Potions.lua",
	"Data/Zones.lua",
	"Features/Utilities.lua",
	"Features/Tooltip-Scanner.lua",
	"Features/Bag-Scanner.lua",
	"Features/Matching-Engine.lua",
	"Features/Recipient-Cooldown.lua",
	"Features/Recipient-Search.lua",
	"Features/Mail-Sender.lua",
	"Features/Recipient-Picker.lua",
	"Features/Match-List.lua",
	"Features/Mail-Window.lua",
	"Features/Diagnostics.lua",
	--[[
		The options panels are not loaded, but this file is not only panels: the consumable
		gap labels and the snapping the dropdown reads live here, and Tests/Options-Values.lua
		asserts on both. It loads last because it reads ns.GetColor and ns.L.
	]]
	"Options/Options-Utilities.lua",
}

local ADDON = "Play-It-Forward"

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
	Recipient-Search.lua and the suffix parsing in Tooltip-Scanner.lua, and answering any
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

	ns.diagnostics = { enabled = false, logging = false }
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

	for _, file in ipairs(FILES) do
		local chunk = assert(loadfile(root .. "/" .. file))
		chunk(ADDON, ns)
	end

	--[[
		Saved variables arrive at ADDON_LOADED in the game, which is after every file has
		loaded, so building them here rather than earlier is not a convenience. A file
		reading ns.db at load time would be a bug and this ordering is what catches it.
	]]
	ns.db = { profile = copy(ns.DATABASE_DEFAULTS.profile) }

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
