--[[
	/pif, and the gate in front of the Settings panel.

	On both shipped clients the panel is combat-protected: OpenToCategory reaches
	OpenSettingsPanel(), which the client blocks from add-on code in a fight. The
	stub models the block, so the combat case here fails with the same
	ADDON_ACTION_BLOCKED a player saw whenever the gate is missing.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, equal = Harness.test, Harness.equal

local function load()
	local ns = Harness.LoadAddon(ADDON_ROOT)
	-- What registration would have captured; RegisterOptionsPanels needs the real Ace.
	ns.GeneralCategoryID = 7
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
