local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit
local DiagnosticsStrings = ns.DiagnosticsStrings

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

-- Called at ADDON_LOADED, not at file scope: the Profiles builder reads ns.db. Register in tree order.

-- For ns:OptionsPanelRoute; the kit keeps its own copy to open by.
local rootCategoryID

function ns.RegisterOptionsPanels()
	local _, categoryID = Kit.RegisterPanel("General", ns.BuildGeneralOptions, L["ADDON_TITLE"])
	rootCategoryID = categoryID

	Kit.RegisterPanel("GiveAway", ns.BuildGiveAwayOptions, L["TAB_GIVE_AWAY"])
	Kit.RegisterPanel("Recipients", ns.BuildRecipientsOptions, L["TAB_RECIPIENTS"])
	Kit.RegisterPanel("Alts", ns.BuildAltsOptions, L["TAB_ALTS"], "Recipients")
	Kit.RegisterPanel("Guilds", ns.BuildGuildsOptions, L["TAB_GUILDS"], "Recipients")
	Kit.RegisterPanel("Mail", ns.BuildMailOptions, L["TAB_MAIL_MESSAGE"])
	Kit.RegisterPanel("Generosity", ns.BuildGenerosityOptions, L["BADGE_OF_GENEROSITY"])
	-- The stock table arrives with its own localized name.
	Kit.RegisterPanel("Profiles", ns.BuildProfilesOptions, ns.BuildProfilesOptions().name)
	Kit.RegisterPanel("FeedbackSupport", ns.BuildFeedbackSupportOptions, L["OPTIONS_FEEDBACK"])
	Kit.RegisterPanel("Diagnostics", ns.BuildDiagnosticsOptions, DiagnosticsStrings.TAB)

	-- My Alts opens on the character being played, My Guilds on the guild it is in, every visit.
	Kit.PrepareTree("Alts", function()
		return ns.QualifyPlayerName(ns.PlayerName())
	end)
	Kit.PrepareTree("Guilds", function()
		return ns.Guild:CurrentKey()
	end)
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

-- Mirrors the route the kit's ns:OpenOptionsPanel takes, for the diagnostics row: change them together.
function ns:OptionsPanelRoute()
	if Settings and Settings.OpenToCategory and rootCategoryID then
		return "settings", true, "Settings.OpenToCategory, category ID " .. tostring(rootCategoryID)
	end
	return "standalone", false, "AceConfigDialog standalone window, outside the Options interface"
end

-- No arguments: everything else worth reaching is a button.
SLASH_PLAYITFORWARD1 = "/pif"
SlashCmdList.PLAYITFORWARD = function()
	ns:OpenOptionsPanel()
end
