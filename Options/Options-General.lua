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

--[[
	One read-only line in the Given Away tally: a gold label and its value. The value is a function
	so the display tracks ns.db.global.stats live rather than freezing at build time, and it returns
	the value already formatted -- the counts arrive comma-grouped and white, the money row as the
	client's coin string -- because those two do not color the same way.
]]
local function givenStat(order, label, valueFn)
	return {
		type = "description",
		fontSize = "medium",
		order = order,
		name = function()
			return GetColor("TITLE") .. label .. "|r  " .. valueFn()
		end,
	}
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

		--------------------------------------------------------------------------
		-- Recipient history
		--------------------------------------------------------------------------
		--[[
			The one control on this panel that writes saved variables, so it is confirm-gated. It
			belongs here rather than under Diagnostic Tools: a player wanting to hand a green to
			somebody they already gifted has no reason to be behind a developer toggle, and the
			diagnostics panel writes nothing but the taintLog CVar.
		]]
		spacerHistory0 = ns.OptionsSpacer(30),
		headerHistory = ns.OptionsHeader(L["OPTIONS_HISTORY_HEADER"], 31),
		descHistory = ns.OptionsDesc(GetColor("HELP") .. L["OPTIONS_HISTORY_DESCRIPTION"] .. "|r", 32),
		spacerHistory1 = ns.OptionsSpacer(33),
		buttonHistory = {
			type = "execute",
			name = L["OPTIONS_HISTORY_BUTTON"],
			order = 34,
			confirm = true,
			confirmText = L["OPTIONS_HISTORY_CONFIRM"],
			func = function()
				ns.Fairness:Reset()
				--[[
					Guarded because the window may never have been built this session. Re-assigning
					is what makes the emptied roster visible: an open window would otherwise keep
					rendering pairings drawn from the pools just wiped. Not Rescan -- the bags have
					not moved, and re-planning the search here would spend presses on nothing.
				]]
				if ns.UI and ns.UI.ClearPools then
					ns.UI:ClearPools()
					if ns.UI.frame then
						ns.UI:_assign()
					end
				end
			end,
		},

		--------------------------------------------------------------------------
		-- Given away
		--------------------------------------------------------------------------
		--[[
			Read-only, and account-wide: these four come from ns.db.global.stats through
			ns.Generosity:Get, so they survive Reset Profile and span every character.
			Money renders through the client's coin string; the other three are comma-grouped counts.
		]]
		spacerGiven0 = ns.OptionsSpacer(40),
		headerGiven = ns.OptionsHeader(L["OPTIONS_GIVEN_HEADER"], 41),
		spacerGiven1 = ns.OptionsSpacer(42),

		givenGifts = givenStat(43, L["OPTIONS_GIVEN_GIFTS"], function()
			local gifts = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(gifts) .. "|r"
		end),
		givenItems = givenStat(44, L["OPTIONS_GIVEN_ITEMS"], function()
			local _, items = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(items) .. "|r"
		end),
		givenItemLevels = givenStat(45, L["OPTIONS_GIVEN_ITEM_LEVELS"], function()
			local _, _, itemLevels = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(itemLevels) .. "|r"
		end),
		givenValue = givenStat(46, L["OPTIONS_GIVEN_VALUE"], function()
			local _, _, _, value = ns.Generosity:Get()
			return ns.MoneyString(value)
		end),

		--[[
			The one control in this section that writes a setting. Sharing is proximity-scoped:
			nearby players running the add-on see these totals on your tooltip. Off stops your own
			broadcasts but not your view of theirs, which is why the description says so.
		]]
		spacerGivenShare = ns.OptionsSpacer(47),
		toggleShareStats = {
			type = "toggle",
			name = L["OPTIONS_SHARE_STATS"],
			desc = L["OPTIONS_SHARE_STATS_DESCRIPTION"],
			width = "full",
			order = 48,
			get = function()
				return ns.db and ns.db.profile.shareStats
			end,
			set = function(_, value)
				ns.db.profile.shareStats = value
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
