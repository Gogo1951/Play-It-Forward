--[[
	Characters copied in from another game version, dropped at load (Features/Core.lua). One case
	per direction: a WoW Forever load drops a realm client's "Name - Realm" character, and a realm
	load drops a Forever "First Last" one while keeping a character on another realm.

	The harness leaves Core.lua out, so each case loads it on top of the usual load, with AceDB
	answered by a stub that hands back the seeded saved table, then fires ADDON_LOADED at the
	dispatcher frame Core builds.
]]

local Harness = require("Harness")
local test, check = Harness.test, Harness.check

local function LoadWithSaved(currentKey, sv)
	local ns = Harness.LoadAddon(ADDON_ROOT)
	ns.diagnostics = ns.diagnostics or { logging = false }
	ns.RegisterOptionsPanels = function() end

	local stubLibStub = LibStub
	LibStub = function(name)
		if name == "AceDB-3.0" then
			return {
				New = function()
					return {
						keys = { char = currentKey, profile = "Default" },
						sv = sv,
						profile = ns.db.profile,
						global = ns.db.global,
						RegisterCallback = function() end,
					}
				end,
			}
		end
		return stubLibStub(name)
	end

	local chunk = assert(loadfile(ADDON_ROOT .. "/Features/Core.lua"))
	chunk("Play-It-Forward", ns)
	ns.eventFrame:GetScript("OnEvent")(ns.eventFrame, "ADDON_LOADED", "Play-It-Forward")
	LibStub = stubLibStub
	return ns
end

--------------------------------------------------------------------------------

test("a WoW Forever load drops a character copied from a realm client", function()
	local sv = {
		char = { ["Gogo Bank"] = {}, ["Gogo - Whitemane"] = {} },
		profileKeys = { ["Gogo Bank"] = "Default", ["Gogo - Whitemane"] = "Gogo - Whitemane" },
		profiles = { Default = {}, ["Gogo - Whitemane"] = {} },
	}
	LoadWithSaved("Gogo Bank", sv)
	check(sv.char["Gogo - Whitemane"] == nil, "the realm character's char section goes")
	check(sv.profileKeys["Gogo - Whitemane"] == nil, "and its profile choice")
	check(sv.profiles["Gogo - Whitemane"] == nil, "and its own profile")
	check(sv.char["Gogo Bank"] ~= nil, "the character being played stays")
	check(sv.profiles.Default ~= nil, "Default is never touched")
end)

test("a realm load drops a WoW Forever character and keeps one on another realm", function()
	local sv = {
		char = { ["Gogo - Whitemane"] = {}, ["Gogo Bank"] = {}, ["Alt - Mankrik"] = {} },
		profileKeys = {
			["Gogo - Whitemane"] = "Default",
			["Gogo Bank"] = "Default",
			["Alt - Mankrik"] = "Default",
		},
		profiles = { Default = {} },
	}
	LoadWithSaved("Gogo - Whitemane", sv)
	check(sv.char["Gogo Bank"] == nil, "the Forever character's char section goes")
	check(sv.profileKeys["Gogo Bank"] == nil, "and its profile choice")
	check(sv.char["Alt - Mankrik"] ~= nil, "a character on another realm stays")
	check(sv.profileKeys["Alt - Mankrik"] == "Default", "with its profile choice")
	check(sv.profiles.Default ~= nil, "Default is never touched, though the dropped character used it")
end)
