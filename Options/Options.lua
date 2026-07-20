local _, ns = ...

local D = ns.DiagnosticsStrings

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

--[[
	Registration only; panel content lives in the per-panel builder files. Called from the
	saved-variables init point in Core rather than at file scope, because the Profiles builder
	reads ns.db and registering at load would error. Child order is the display order, and each
	child passes ns.AddonTitle as the third argument so it nests under the root panel.
]]
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function ns:RegisterOptionsPanels()
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.General, ns.BuildGeneralOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.General, ns.AddonTitle)

	local profilesOptions = ns.BuildProfilesOptions()
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Profiles, profilesOptions)
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Profiles, profilesOptions.name, ns.AddonTitle)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Diagnostics, ns.BuildDiagnosticsOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Diagnostics, D.TAB, ns.AddonTitle)
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

--[[
	Settings.OpenToCategory is the modern path. The legacy call is made twice because the
	first invocation only selects the category and the second scrolls to it.
]]
function ns:OpenOptionsPanel()
	if Settings and Settings.GetCategory then
		local category = Settings.GetCategory(ns.AddonTitle)
		if category then
			Settings.OpenToCategory(category.ID)
			return
		end
	end
	if InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(ns.AddonTitle)
		InterfaceOptionsFrame_OpenToCategory(ns.AddonTitle)
		return
	end
	AceConfigDialog:Open(ns.OPTIONS_REGISTRY.General)
end

-- The one slash command, and it takes no arguments: everything else worth reaching is a button.
SLASH_PLAYITFORWARD1 = "/pif"
SlashCmdList.PLAYITFORWARD = function()
	ns:OpenOptionsPanel()
end
