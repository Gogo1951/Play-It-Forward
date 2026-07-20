local ADDON_NAME, ns = ...
local L = ns.L

-- Identity, saved-variable lifecycle and the event dispatcher. Nothing else belongs here.
ns.name = ADDON_NAME

-- An unreplaced @project-version@ token means an unpackaged dev copy, and reads as "Dev".
local function GetVersion()
	local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	local version = GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version")
	if not version or version:find("@") then
		return "Dev"
	end
	return version
end

ns.Version = GetVersion()

--------------------------------------------------------------------------------
-- Event dispatch
--------------------------------------------------------------------------------

--[[
	Every event routes through this one frame, and ns.on is the only way in: a feature file
	registering its own frame would bypass the Diagnostics event log. ns.EVENT_NAMES
	accumulates as events register rather than being a static list, because registration is
	flavor-conditional, so the exported list is exactly what this client took.
]]
local handlers = {}
local registered = {}
local frame = CreateFrame("Frame")

ns.EVENT_NAMES = {}

function ns.on(event, fn)
	handlers[event] = handlers[event] or {}
	table.insert(handlers[event], fn)
	if not registered[event] then
		registered[event] = true
		table.insert(ns.EVENT_NAMES, event)
		frame:RegisterEvent(event)
	end
end

frame:SetScript("OnEvent", function(_, event, ...)
	--[[
		The diagnostics tap: one boolean read before any allocation, so diagnostics off costs
		nothing. Logged before the handlers run, so an entry survives a handler error.
	]]
	if ns.diagnostics.logging then
		ns:LogEvent(event, ...)
	end
	local list = handlers[event]
	if not list then
		return
	end
	for _, fn in ipairs(list) do
		fn(...)
	end
end)

--------------------------------------------------------------------------------
-- Saved Variables
--------------------------------------------------------------------------------

--[[
	The database is created here and nowhere else. ADDON_LOADED is the first point the client
	has loaded our saved variables: file scope is too early, and PLAYER_ENTERING_WORLD refires
	on every loading screen. New's third argument is the shared "Default" profile -- omitting
	it silently gives every character its own, and account-wide settings stop being so.
]]
ns.on("ADDON_LOADED", function(name)
	if name ~= ADDON_NAME then
		return
	end
	ns.db = LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)

	-- The cooldown spreads gifts across one session, so the list starts empty at every login.
	wipe(ns.db.profile.recipients)

	ns:RegisterOptionsPanels()
end)

ns.on("PLAYER_LOGIN", function()
	if not ns.db.profile.showWelcome then
		return
	end
	ns:PrintMessage(L["CHAT_LOADED"]:format(ns.Version))
end)
