local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

--------------------------------------------------------------------------------
-- General Panel
--------------------------------------------------------------------------------

-- The Features switches write the same keys What to Give Away and Badge of Generosity do, so either moves both.
function ns.BuildGeneralOptions()
	local args = {
		descIntro = Kit.Desc(L["OPTIONS_DESCRIPTION"], 1),

		spacerWelcome0 = Kit.Spacer(5),
		toggleWelcome = {
			type = "toggle",
			name = L["OPTIONS_WELCOME"],
			desc = L["OPTIONS_WELCOME_DESCRIPTION"],
			width = "full",
			order = 6,
			get = Kit.Get("profile", "showWelcome"),
			set = Kit.Set("profile", "showWelcome"),
		},
	}

	Kit.Section(args, "features", 20, L["OPTIONS_FEATURES_HEADER"])
	args.featureSwitches = Kit.FeatureSwitches(23)

	Kit.Section(args, "commands", 80, L["OPTIONS_COMMANDS_HEADER"])
	args.descCommands =
		Kit.Desc(Kit.Color("INFO", L["OPTIONS_COMMAND"]) .. "  " .. L["OPTIONS_COMMAND_DESCRIPTION"], 83)

	return {
		type = "group",
		name = L["ADDON_TITLE"],
		args = args,
	}
end
