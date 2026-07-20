local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

-- Inlined rather than using ns.OptionsDesc/OptionsSpacer, which take no hidden argument.
local FEEDBACK_LINKS = {
	{ id = "Discord", label = L["OPTIONS_DISCORD"], key = "DISCORD" },
	{ id = "GitHub", label = L["OPTIONS_GITHUB"], key = "GITHUB" },
	{ id = "CurseForge", label = L["OPTIONS_CURSEFORGE"], key = "CURSEFORGE" },
	{ id = "Wago", label = L["OPTIONS_WAGO"], key = "WAGO" },
}

local function addFeedbackLinks(args, startOrder)
	local order = startOrder
	for _, link in ipairs(FEEDBACK_LINKS) do
		local key = link.key
		local hidden = function()
			return not ns.Links[key]
		end
		args["label" .. link.id] = {
			type = "description",
			name = GetColor("TITLE") .. link.label .. "|r",
			fontSize = "medium",
			order = order,
			hidden = hidden,
		}
		args["link" .. link.id] = {
			type = "input",
			name = "",
			width = "double",
			order = order + 1,
			get = function()
				return ns.Links[key]
			end,
			set = function() end,
			hidden = hidden,
		}
		args["spacer" .. link.id] = {
			type = "description",
			name = " ",
			order = order + 2,
			hidden = hidden,
		}
		order = order + 3
	end
end

-- Rarity cap changes what the bag scan returns, so the open window is re-read.
local function refreshWindow()
	if ns.UI and ns.UI.frame then
		ns.UI:_syncRarityButton()
		ns.UI:Rescan()
	end
end

--------------------------------------------------------------------------------
-- General Panel
--------------------------------------------------------------------------------

function ns.BuildGeneralOptions()
	local args = {
		descIntro = ns.OptionsDesc(L["OPTIONS_DESCRIPTION"], 1),

		spacerWelcome0 = ns.OptionsSpacer(5),
		toggleWelcome = {
			type = "toggle",
			name = L["OPTIONS_WELCOME"],
			desc = L["OPTIONS_WELCOME_DESCRIPTION"],
			width = "full",
			order = 6,
			get = function()
				return ns.db and ns.db.profile.showWelcome
			end,
			set = function(_, value)
				ns.db.profile.showWelcome = value
			end,
		},

		spacerCommands0 = ns.OptionsSpacer(10),
		headerCommands = ns.OptionsHeader(L["OPTIONS_COMMANDS_HEADER"], 11),
		spacerCommands1 = ns.OptionsSpacer(12),
		descCommands = ns.OptionsDesc(
			GetColor("INFO") .. L["OPTIONS_COMMAND_PIF"] .. "|r" .. "  " .. L["OPTIONS_COMMAND_PIF_DESCRIPTION"],
			13
		),

		--------------------------------------------------------------------------
		-- What to give away
		--------------------------------------------------------------------------
		--[[
			One row per toggle: a double-width checkbox with its select on the right, the select's
			own name as the caption -- a description widget beside it counts as a second control and
			breaks the row in two. Each select hides with its toggle rather than graying out.
		]]
		spacerGive0 = ns.OptionsSpacer(20),
		headerGive = ns.OptionsHeader(L["OPTIONS_GIVE_HEADER"], 21),
		spacerGive1 = ns.OptionsSpacer(22),

		toggleIncludeGear = {
			type = "toggle",
			name = L["OPTIONS_INCLUDE_GEAR"],
			desc = L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"],
			width = "double",
			order = 23,
			get = function()
				return ns.db and ns.db.profile.includeGear
			end,
			set = function(_, value)
				ns.db.profile.includeGear = value
				refreshWindow()
			end,
		},
		selectMaxRarity = {
			type = "select",
			name = L["OPTIONS_MAX_RARITY"],
			desc = L["OPTIONS_MAX_RARITY_DESCRIPTION"],
			width = "normal",
			order = 24,
			hidden = function()
				return not (ns.db and ns.db.profile.includeGear)
			end,
			values = function()
				local out = {}
				for _, quality in ipairs({ 2, 3, 4 }) do
					out[quality] = ns.QualityColor(quality) .. ns.QualityName(quality) .. "|r"
				end
				return out
			end,
			get = function()
				return ns.db.profile.maxRarity
			end,
			set = function(_, value)
				ns.db.profile.maxRarity = value
				refreshWindow()
			end,
		},

		toggleIncludeConsumables = {
			type = "toggle",
			name = L["OPTIONS_INCLUDE_CONSUMABLES"],
			desc = L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"],
			width = "double",
			order = 25,
			get = function()
				return ns.db and ns.db.profile.includeConsumables
			end,
			set = function(_, value)
				ns.db.profile.includeConsumables = value
				refreshWindow()
			end,
		},
		selectConsumableLevelGap = {
			type = "select",
			name = L["OPTIONS_CONSUMABLE_GAP_LABEL"],
			desc = L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"],
			width = "normal",
			order = 26,
			hidden = function()
				return not (ns.db and ns.db.profile.includeConsumables)
			end,
			values = ns.CONSUMABLE_GAP_VALUES,
			sorting = ns.CONSUMABLE_GAP_ORDER,
			get = function()
				return ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
			end,
			set = function(_, value)
				ns.db.profile.consumableLevelGap = value
				refreshWindow()
			end,
		},

		-- No Finding Recipients, Matching or The Mail section: Data/Default-Settings.lua records why.

		--------------------------------------------------------------------------
		-- Feedback and version
		--------------------------------------------------------------------------
		spacerFeedback0 = ns.OptionsSpacer(90),
		headerFeedback = ns.OptionsHeader(L["OPTIONS_FEEDBACK"], 91),
		spacerFeedback1 = ns.OptionsSpacer(92),

		spaceVersion0 = {
			type = "description",
			name = " ",
			width = "full",
			order = 998,
		},
		versionLine = {
			type = "description",
			name = GetColor("MUTED") .. L["OPTIONS_VERSION"]:format(ns.Version) .. "|r",
			fontSize = "medium",
			order = 999,
		},
	}

	addFeedbackLinks(args, 93)

	return {
		type = "group",
		name = ns.AddonTitle,
		args = args,
	}
end
