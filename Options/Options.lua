local _, ns = ...
local L = ns.L

local DiagnosticsStrings = ns.DiagnosticsStrings

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

--[[
	Called from the saved-variables init point in Core rather than at file scope, because the
	Profiles builder reads ns.db and registering at load would error. The tree:

	  Play It Forward (General, the root)
	    What to Give Away
	    Recipients
	      My Alts
	      My Guilds
	    Mail Message Text
	    Badge of Generosity
	    Profiles
	    Feedback & Support
	    Diagnostic Tools

	Registration order is tree order within each level. A top-level child passes ns.ADDON_TITLE as
	the third argument; My Alts and My Guilds pass the category ID Recipients' own AddToBlizOptions
	returned instead, because AceConfigDialog maps only a root's display name to its ID, while the
	Settings panel finds a category at any depth by ID.
]]
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--[[
	Seeds a list panel's tree before it is first drawn, as Magic Eraser does:
	  - treewidth sizes the tree (ns.OPTIONS_TREE_WIDTH). AceGUI fills it in only when the key is
	    absent, so seeding it here wins, while a player dragging the splitter still overwrites it.
	  - selected opens the tree on Home(): the character being played, or the guild it is in. Set
	    again every time the panel hides, so each visit starts there. A key the tree no longer has
	    falls back to its first row (AceConfigDialog checks GroupExists).
]]
local function PrepareListTree(registryName, panel, Home)
	local status = AceConfigDialog:GetStatusTable(registryName)
	status.groups = status.groups or {}
	status.groups.treewidth = ns.OPTIONS_TREE_WIDTH
	status.groups.selected = Home()

	if panel and panel.HookScript then
		panel:HookScript("OnHide", function()
			status.groups.selected = Home()
		end)
	end
end

function ns:RegisterOptionsPanels()
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.General, ns.BuildGeneralOptions())
	--[[
		Both return values are kept: AddToBlizOptions hands back (frame, categoryID), and the ID
		is the only dependable way back to this panel. AceConfigDialog overrides the category ID
		to the display name only on clients lacking C_SettingsUtil.OpenSettingsPanel, so on a
		client that has it the ID is a generated one and a name lookup finds nothing. Era lacks
		it and TBC Anniversary has it, which is why a name lookup worked on exactly one flavor.
	]]
	ns.GeneralPanel, ns.GeneralCategoryID =
		AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.General, ns.ADDON_TITLE)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.GiveAway, ns.BuildGiveAwayOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.GiveAway, L["TAB_GIVE_AWAY"], ns.ADDON_TITLE)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Recipients, ns.BuildRecipientsOptions())
	local _, recipientsCategoryID =
		AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Recipients, L["TAB_RECIPIENTS"], ns.ADDON_TITLE)

	-- Builder functions: the rows are the saved characters and guilds, read each time one is drawn.
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Alts, ns.BuildAltsOptions)
	local altsPanel = AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Alts, L["TAB_ALTS"], recipientsCategoryID)
	PrepareListTree(ns.OPTIONS_REGISTRY.Alts, altsPanel, function()
		return ns.QualifyPlayerName(UnitName("player"))
	end)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Guilds, ns.BuildGuildsOptions)
	local guildsPanel =
		AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Guilds, L["TAB_GUILDS"], recipientsCategoryID)
	PrepareListTree(ns.OPTIONS_REGISTRY.Guilds, guildsPanel, function()
		return ns.Guild:CurrentKey()
	end)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Mail, ns.BuildMailOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Mail, L["TAB_MAIL_MESSAGE"], ns.ADDON_TITLE)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Generosity, ns.BuildGenerosityOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Generosity, L["TAB_GENEROSITY"], ns.ADDON_TITLE)

	local profilesOptions = ns.BuildProfilesOptions()
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Profiles, profilesOptions)
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Profiles, profilesOptions.name, ns.ADDON_TITLE)

	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.FeedbackSupport, ns.BuildFeedbackSupportOptions())
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.FeedbackSupport, L["OPTIONS_FEEDBACK"], ns.ADDON_TITLE)

	-- A builder function, so the tabs come and go with the enable toggle (see Diagnostics/Options-Diagnostics.lua).
	AceConfig:RegisterOptionsTable(ns.OPTIONS_REGISTRY.Diagnostics, ns.BuildDiagnosticsOptions)
	AceConfigDialog:AddToBlizOptions(ns.OPTIONS_REGISTRY.Diagnostics, DiagnosticsStrings.TAB, ns.ADDON_TITLE)
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

--[[
	Which path the panel opens by, decided here and nowhere else. The diagnostics row reads this
	rather than re-testing the same conditions, where a second copy of the branch is free to drift
	from the opener and describe a route the add-on does not take.

	Routed by the category ID captured at registration, because the display name is not an
	identifier. The standalone window is a last resort a correctly registered panel never reaches.
]]
function ns:OptionsPanelRoute()
	if Settings and Settings.OpenToCategory and ns.GeneralCategoryID then
		return "settings", true, "Settings.OpenToCategory, category ID " .. tostring(ns.GeneralCategoryID)
	end
	return "standalone", false, "AceConfigDialog standalone window, outside the Options interface"
end

function ns:OpenOptionsPanel()
	--[[
		Combat first: the Settings panel is protected there, so the modern route's
		OpenToCategory would be stopped at OpenSettingsPanel() with ADDON_ACTION_BLOCKED
		shown to the player. One gate in front of every route rather than a check on that
		one, so /pif in a fight answers the same way on every flavor.
	]]
	if InCombatLockdown() then
		ns:PrintMessage(L["CHAT_OPTIONS_IN_COMBAT"])
		return
	end
	local route = ns:OptionsPanelRoute()
	if route == "settings" then
		Settings.OpenToCategory(ns.GeneralCategoryID)
		return
	end
	AceConfigDialog:Open(ns.OPTIONS_REGISTRY.General)
end

-- The one slash command, and it takes no arguments: everything else worth reaching is a button.
SLASH_PLAYITFORWARD1 = "/pif"
SlashCmdList.PLAYITFORWARD = function()
	ns:OpenOptionsPanel()
end
