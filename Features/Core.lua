local ADDON_NAME, ns = ...
local L = ns.L

-- Identity, saved-variable lifecycle and the event dispatcher. Nothing else belongs here.
ns.name = ADDON_NAME

-- An unreplaced @project-version@ token means an unpackaged dev copy: the @ is the signal.
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
	ns.on is the only way in: a feature file registering its own frame would bypass the Diagnostics
	event log. ns.EVENT_NAMES accumulates as events register rather than being a static list,
	because registration is flavor-conditional, so the export is exactly what this client took.
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
		One boolean read before any allocation, so diagnostics off costs nothing. Logged before the
		handlers run, so an entry survives a handler error.
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
	ADDON_LOADED is the first point the client has loaded our saved variables: file scope is too
	early, and PLAYER_ENTERING_WORLD refires on every loading screen. New's third argument is the
	shared "Default" profile -- omit it and every character silently gets its own.
]]
ns.on("ADDON_LOADED", function(name)
	if name ~= ADDON_NAME then
		return
	end
	ns.db = LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)

	-- Deprecated: a setting no control ever reached, and a constant now as ns.Data.MIN_RARITY.
	ns.db.profile.minRarity = nil

	--[[
		A reset or a profile switch replaces ns.db.profile wholesale. Settings read live off it
		catch up on their own; the built window does not, so it is re-read here -- the same two
		calls the options panel makes when a giftability setting changes.
	]]
	function ns:ApplyProfile()
		if ns.UI and ns.UI.frame then
			ns.UI:_syncRarityButton()
			ns.UI:Rescan()
		end
		LibStub("AceConfigRegistry-3.0"):NotifyChange(ns.OPTIONS_REGISTRY.General)
	end

	for _, msg in ipairs({ "OnProfileChanged", "OnProfileReset", "OnProfileCopied" }) do
		ns.db.RegisterCallback(ns, msg, "ApplyProfile")
	end

	-- The cooldown is per-session, so the list starts empty at every login.
	ns.Fairness:Reset()

	ns:RegisterOptionsPanels()
end)

ns.on("PLAYER_LOGIN", function()
	if not ns.db.profile.showWelcome then
		return
	end
	ns:PrintMessage(L["CHAT_LOADED"]:format(ns.Version))
end)
