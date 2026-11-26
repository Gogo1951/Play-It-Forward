--[[
	/pif, and the gate in front of the Settings panel.

	On every target the panel is combat-protected: OpenToCategory reaches
	OpenSettingsPanel(), which the client blocks from add-on code in a fight. The
	stub models the block, so the combat case here fails with the same
	ADDON_ACTION_BLOCKED a player saw whenever the gate is missing.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, equal = Harness.test, Harness.equal

--[[
	The root panel registered through the kit, whose AddToBlizOptions hands back category 7: the
	ID the kit captures and routes by. RegisterOptionsPanels whole needs the real Ace.
]]
local function load()
	local ns = Harness.LoadAddon(ADDON_ROOT, function()
		local stubLibStub = LibStub
		LibStub = function(name)
			local lib = stubLibStub(name)
			if name == "AceConfigDialog-3.0" then
				rawset(lib, "AddToBlizOptions", function()
					return lib, 7
				end)
			end
			return lib
		end
	end)
	ns.OptionsKit.RegisterPanel("General", function() end, ns.L["ADDON_TITLE"])
	return ns
end

--------------------------------------------------------------------------------

test("out of combat /pif opens the settings panel to our category", function()
	load()
	SlashCmdList.PLAYITFORWARD()
	equal(#Stub.settingsOpened, 1, "one open")
	equal(Stub.settingsOpened[1], 7, "to the registered category")
end)

test("in combat /pif says so instead of tripping the protected panel", function()
	local ns = load()
	Stub.inCombat = true
	SlashCmdList.PLAYITFORWARD()
	equal(#Stub.settingsOpened, 0, "panel untouched")
	equal(Stub.printed[#Stub.printed], ns.L["CHAT_OPTIONS_IN_COMBAT"], "and the player told why")
end)
