local _, ns = ...

local D = ns.DiagnosticsStrings

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

--[[
	Called from the saved-variables init point in Core rather than at file scope, because the
	Profiles builder reads ns.db and registering at load would error. Child order is the display
	order, and each child passes ns.AddonTitle as the third argument so it nests under the root.
]]
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function ns:RegisterOptionsPanels()
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.General, ns.BuildGeneralOptions())
	--[[
		Both return values are kept: AddToBlizOptions hands back (frame, categoryID), and the ID
		is the only dependable way back to this panel. AceConfigDialog overrides the category ID
		to the display name only on clients lacking C_SettingsUtil.OpenSettingsPanel, so on a
		client that has it the ID is a generated one and a name lookup finds nothing. Era lacks
		it and TBC Anniversary has it, which is why a name lookup worked on exactly one flavor.
	]]
	ns.GeneralPanel, ns.GeneralCategoryID = AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.General, ns.AddonTitle)

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
	Which path the panel opens by, decided here and nowhere else. The diagnostics row reads this
	rather than re-testing the same conditions, where a second copy of the branch is free to drift
	from the opener and describe a route the add-on does not take.

	Ordered modern, legacy, standalone. The first two are routed by the ID captured at registration
	and by the panel frame respectively, because the display name is not an identifier.
]]
function ns:OptionsPanelRoute()
	if Settings and Settings.OpenToCategory and ns.GeneralCategoryID then
		return "settings", true, "Settings.OpenToCategory, category ID " .. tostring(ns.GeneralCategoryID)
	end
	if InterfaceOptionsFrame_OpenToCategory and ns.GeneralPanel then
		return "legacy", true, "InterfaceOptionsFrame_OpenToCategory, by panel frame"
	end
	return "standalone", false, "AceConfigDialog standalone window, outside the Options interface"
end

function ns:OpenOptionsPanel()
	local route = ns:OptionsPanelRoute()
	if route == "settings" then
		Settings.OpenToCategory(ns.GeneralCategoryID)
		return
	end
	if route == "legacy" then
		-- Twice: the first invocation only selects the category and the second scrolls to it.
		InterfaceOptionsFrame_OpenToCategory(ns.GeneralPanel)
		InterfaceOptionsFrame_OpenToCategory(ns.GeneralPanel)
		return
	end
	AceConfigDialog:Open(ns.OPTIONS_REGISTRY.General)
end

-- The one slash command, and it takes no arguments: everything else worth reaching is a button.
SLASH_PLAYITFORWARD1 = "/pif"
SlashCmdList.PLAYITFORWARD = function()
	ns:OpenOptionsPanel()
end
