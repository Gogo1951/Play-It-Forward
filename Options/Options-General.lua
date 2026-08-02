local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

--[[
	A gated label row: ns.OptionsRowLabel takes no hidden argument, so a label that hides with its
	control sets it on the returned table.
]]
local function gatedRowLabel(text, order, hidden, width)
	local label = ns.OptionsRowLabel(text, order, width)
	label.hidden = hidden
	return label
end

--[[
	One split for every label-beside-value row on this panel, copied from GogoLoot: a one-word
	label against a wide cell. The label takes 0.6 so the cell beside it lands on exactly 2.0 --
	the guide's double width for a read-only input -- without the row outgrowing every other row.
	Shared by the link rows and the Generosity totals, so the numbers start where the URLs do.

	EVERY PAIR NEEDS ITS SPACER. AceConfig's flow packs cells until a row fills, and a full-width
	spacer is what ends one; pairs written without them run together and the rows interleave.
]]
local ROW_LABEL_WIDTH = 0.6
local ROW_VALUE_WIDTH = ns.OPTIONS_ROW_WIDTH - ROW_LABEL_WIDTH

-- The input and spacer stay inlined: ns.OptionsDesc and ns.OptionsSpacer take no hidden argument.
local FEEDBACK_LINKS = {
	{ id = "Discord", label = L["OPTIONS_DISCORD"], key = "DISCORD" },
	{ id = "GitHub", label = L["OPTIONS_GITHUB"], key = "GITHUB" },
	{ id = "CurseForge", label = L["OPTIONS_CURSEFORGE"], key = "CURSEFORGE" },
	{ id = "Wago", label = L["OPTIONS_WAGO"], key = "WAGO" },
}

local function addFeedbackLinks(args, startOrder)
	local order = startOrder
	for index, link in ipairs(FEEDBACK_LINKS) do
		local key = link.key
		local hidden = function()
			return not ns.Links[key]
		end
		args["label" .. link.id] =
			gatedRowLabel(GetColor("TITLE") .. link.label .. "|r", order, hidden, ROW_LABEL_WIDTH)
		args["link" .. link.id] = {
			type = "input",
			name = "",
			width = ROW_VALUE_WIDTH,
			order = order + 1,
			get = function()
				return ns.Links[key]
			end,
			set = function() end,
			hidden = hidden,
		}
		order = order + 2

		-- Between rows only: a trailing one would double the gap before the version line.
		if index < #FEEDBACK_LINKS then
			args["spacer" .. link.id] = {
				type = "description",
				name = " ",
				order = order,
				hidden = hidden,
			}
			order = order + 1
		end
	end
end

--[[
	Each select greys out with the toggle beside it rather than hiding: a hidden select leaves a
	gap the next toggle flows up into, which pairs two toggles on one row and is exactly the
	formatting this section was cleaned up to avoid.
]]
local function gearOff()
	return not (ns.db and ns.db.profile.includeGear)
end

local function consumablesOff()
	return not (ns.db and ns.db.profile.includeConsumables)
end

-- Rarity cap changes what the bag scan returns, so the open window is re-read.
local function refreshWindow()
	if ns.UI and ns.UI.frame then
		ns.UI:_syncControls()
		ns.UI:Rescan()
	end
end

--[[
	The read-only tally, on the same split as the link rows above, so its numbers start exactly
	where the URL boxes do. Each value is a function, so the display tracks ns.db.global.stats
	live rather than freezing at build time, and it returns its own formatting: the counts
	comma-grouped and white, the money as the client's coin string, which do not color alike.
]]
local GENEROSITY_STATS = {
	{
		id = "Gifts",
		label = L["OPTIONS_GENEROSITY_GIFTS"],
		value = function()
			local gifts = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(gifts) .. "|r"
		end,
	},
	{
		id = "Items",
		label = L["OPTIONS_GENEROSITY_ITEMS"],
		value = function()
			local _, items = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(items) .. "|r"
		end,
	},
	{
		id = "ItemLevels",
		label = L["OPTIONS_GENEROSITY_ITEM_LEVELS"],
		value = function()
			local _, _, itemLevels = ns.Generosity:Get()
			return GetColor("TEXT") .. ns.CommaNumber(itemLevels) .. "|r"
		end,
	},
	{
		id = "Value",
		label = L["OPTIONS_GENEROSITY_VALUE"],
		value = function()
			local _, _, _, value = ns.Generosity:Get()
			return ns.MoneyString(value)
		end,
	},
}

local function addGenerosityStats(args, startOrder)
	local order = startOrder
	for index, row in ipairs(GENEROSITY_STATS) do
		args["label" .. row.id] = ns.OptionsRowLabel(GetColor("TITLE") .. row.label .. "|r", order, ROW_LABEL_WIDTH)
		args["value" .. row.id] = {
			type = "description",
			name = row.value,
			fontSize = "medium",
			width = ROW_VALUE_WIDTH,
			order = order + 1,
		}
		order = order + 2

		-- Between rows only, as the link rows do: a trailing one doubles the gap before Feedback.
		if index < #GENEROSITY_STATS then
			args["spacer" .. row.id] = { type = "description", name = " ", order = order }
			order = order + 1
		end
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
			GetColor("INFO") .. L["OPTIONS_COMMAND"] .. "|r" .. "  " .. L["OPTIONS_COMMAND_DESCRIPTION"],
			13
		),

		--------------------------------------------------------------------------
		-- What to give away
		--------------------------------------------------------------------------
		--[[
			The toggle IS the caption: it sits at label width with its select beside it, so these
			rows need no separate label cell and each select carries name = "". The select's own
			values say what they mean ("Rare & Lower", "Outgrown by 20+ Levels"), which is what
			lets the caption go.
		]]
		spacerGive0 = ns.OptionsSpacer(20),
		headerGive = ns.OptionsHeader(L["OPTIONS_GIVE_HEADER"], 21),
		spacerGive1 = ns.OptionsSpacer(22),

		toggleIncludeGear = {
			type = "toggle",
			name = L["OPTIONS_INCLUDE_GEAR"],
			desc = L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"],
			width = ns.OPTIONS_LABEL_WIDTH,
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
			name = "",
			desc = L["OPTIONS_MAX_RARITY_DESCRIPTION"],
			width = ns.OPTIONS_CONTROL_WIDTH,
			order = 24,
			disabled = gearOff,
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

		-- Between the two rows only, matching the link rows below: no trailing one.
		spacerGive2 = ns.OptionsSpacer(25),
		toggleIncludeConsumables = {
			type = "toggle",
			name = L["OPTIONS_INCLUDE_CONSUMABLES"],
			desc = L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"],
			width = ns.OPTIONS_LABEL_WIDTH,
			order = 26,
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
			name = "",
			desc = L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"],
			width = ns.OPTIONS_CONTROL_WIDTH,
			order = 27,
			disabled = consumablesOff,
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
		-- Generosity stats
		--------------------------------------------------------------------------
		--[[
			The toggle leads, then the four totals. It is proximity-scoped sharing: nearby players
			running the add-on see these totals on your tooltip, and you see theirs on the same
			terms. Off stops your own broadcasts but not your view of theirs, and the totals below
			keep counting either way, which is why they are not gated on it.
		]]
		spacerGiven0 = ns.OptionsSpacer(40),
		headerGiven = ns.OptionsHeader(L["OPTIONS_GENEROSITY_HEADER"], 41),
		spacerGiven1 = ns.OptionsSpacer(42),

		toggleShareStats = {
			type = "toggle",
			name = L["OPTIONS_SHARE_STATS"],
			desc = L["OPTIONS_SHARE_STATS_DESCRIPTION"],
			width = "full",
			order = 43,
			get = function()
				return ns.db and ns.db.profile.shareStats
			end,
			set = function(_, value)
				ns.db.profile.shareStats = value
			end,
		},
		spacerGiven2 = ns.OptionsSpacer(44),
		-- The four totals are added by addGenerosityStats below, from order 45.

		-- No Finding Recipients, Matching or The Mail section: Data/Default-Settings.lua records why.

		--------------------------------------------------------------------------
		-- Feedback and version
		--------------------------------------------------------------------------
		spacerFeedback0 = ns.OptionsSpacer(90),
		headerFeedback = ns.OptionsHeader(L["OPTIONS_FEEDBACK_HEADER"], 91),
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

	addGenerosityStats(args, 45)
	addFeedbackLinks(args, 93)

	return {
		type = "group",
		name = ns.AddonTitle,
		args = args,
	}
end
