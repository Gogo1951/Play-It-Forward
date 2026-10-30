local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

-- Each feature's on/off switch, two to a line; its settings live on that feature's own panel.
local FEATURE_TOGGLE_WIDTH = ns.OPTIONS_ROW_WIDTH / 2

-- { key, label, description, refreshes the mail window }, in display order.
local FEATURES = {
	{ "includeGear", "OPTIONS_DISTRIBUTE_GEAR", "OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION", true },
	{ "includeConsumables", "OPTIONS_DISTRIBUTE_CONSUMABLES", "OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION", true },
	{ "shareStats", "OPTIONS_SHARE_STATS", "OPTIONS_SHARE_STATS_DESCRIPTION", false },
}

-- The same keys the feature panels' own toggles bind, so either switch moves both.
local function AddFeatureToggles(args, startOrder)
	for index, feature in ipairs(FEATURES) do
		local key, label, description, refreshes = feature[1], feature[2], feature[3], feature[4]
		args["toggleFeature" .. index] = ns.OptionsProfileToggle(
			key,
			L[label],
			L[description],
			startOrder + index - 1,
			FEATURE_TOGGLE_WIDTH,
			refreshes and ns.RefreshMailWindow or nil
		)
	end
end

--------------------------------------------------------------------------------
-- General Panel
--------------------------------------------------------------------------------

function ns.BuildGeneralOptions()
	local args = {
		descIntro = ns.OptionsDesc(L["OPTIONS_DESCRIPTION"], 1),

		spacerWelcome0 = ns.OptionsSpacer(5),
		toggleWelcome = ns.OptionsProfileToggle(
			"showWelcome",
			L["OPTIONS_WELCOME"],
			L["OPTIONS_WELCOME_DESCRIPTION"],
			6
		),

		spacerFeatures0 = ns.OptionsSpacer(20),
		headerFeatures = ns.OptionsHeader(L["OPTIONS_FEATURES_HEADER"], 21),
		spacerFeatures1 = ns.OptionsSpacer(22),
		-- The feature switches are added by AddFeatureToggles below, from order 23.

		spacerCommands0 = ns.OptionsSpacer(80),
		headerCommands = ns.OptionsHeader(L["OPTIONS_COMMANDS_HEADER"], 81),
		spacerCommands1 = ns.OptionsSpacer(82),
		descCommands = ns.OptionsDesc(
			GetColor("INFO") .. L["OPTIONS_COMMAND"] .. "|r" .. "  " .. L["OPTIONS_COMMAND_DESCRIPTION"],
			83
		),
	}

	AddFeatureToggles(args, 23)

	return {
		type = "group",
		name = ns.ADDON_TITLE,
		args = args,
	}
end
