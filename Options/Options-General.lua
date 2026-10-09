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
	One split for every label-beside-value row on this panel: a one-word label against a wide
	cell, the two totalling ns.OPTIONS_ROW_WIDTH like every other row. Shared by the link rows and
	the Generosity totals, so the numbers start where the URLs do.

	EVERY PAIR NEEDS ITS SPACER. AceConfig's flow packs cells until a row fills, and a full-width
	spacer is what ends one; pairs written without them run together and the rows interleave.
]]
local ROW_LABEL_WIDTH = 0.6
local ROW_VALUE_WIDTH = ns.OPTIONS_ROW_WIDTH - ROW_LABEL_WIDTH

-- The input stays inlined: it carries its own hidden function beside the label's.
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
			return not ns.LINKS[key]
		end
		args["label" .. link.id] =
			gatedRowLabel(GetColor("TITLE") .. link.label .. "|r", order, hidden, ROW_LABEL_WIDTH)
		args["link" .. link.id] = {
			type = "input",
			name = "",
			width = ROW_VALUE_WIDTH,
			order = order + 1,
			get = function()
				return ns.LINKS[key]
			end,
			set = function() end,
			hidden = hidden,
		}
		order = order + 2

		-- Between rows only: a trailing one would double the gap before the version line.
		if index < #FEEDBACK_LINKS then
			args["spacer" .. link.id] = ns.OptionsSpacer(order, hidden)
			order = order + 1
		end
	end
end

-- The rarity select hides while Include Gear is off, the gap select with its sub-row; spacerGive2 separates the two.
local function gearOff()
	return not (ns.db and ns.db.profile.includeGear)
end

local function consumablesOff()
	return not (ns.db and ns.db.profile.includeConsumables)
end

--[[
	Build Reference -> Sub-Option Rows. One unnamed inline group per sub-option, led by a real
	blank cell: AceConfig pins a checkbox to its own widget's left edge, so only a cell indents
	it. hidden goes on the group, or the indent is left behind on its own line.
]]
local function SubRow(order, hidden, controls)
	local args = {
		indent = { type = "description", name = "", width = ns.OPTIONS_SUB_INDENT_WIDTH, order = 0 },
	}
	for index, control in ipairs(controls) do
		control.order = index
		args["control" .. index] = control
	end
	return { type = "group", name = "", inline = true, order = order, hidden = hidden, args = args }
end

local function SubLabel(text)
	return GetColor("HELP") .. text .. "|r"
end

-- Rarity cap changes what the bag scan returns, so the open window is re-read.
local function refreshWindow()
	if ns.UI and ns.UI.frame then
		ns.UI:_syncControls()
		ns.UI:Rescan()
	end
end

-- One sub-row per kind under Include Consumables, hiding with its select.
local function addConsumableKinds(args, startOrder)
	for index, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		local strings = ns.CONSUMABLE_KIND_STRINGS[kind]
		args["subKind" .. kind] = SubRow(startOrder + index - 1, consumablesOff, {
			{
				type = "toggle",
				name = SubLabel(L[strings.label]),
				desc = L[strings.description],
				width = ns.OPTIONS_ROW_WIDTH - ns.OPTIONS_SUB_INDENT_WIDTH,
				get = function()
					return ns.db and ns.db.profile.consumableKinds[kind]
				end,
				set = function(_, value)
					ns.db.profile.consumableKinds[kind] = value
					refreshWindow()
				end,
			},
		})
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
			args["spacer" .. row.id] = ns.OptionsSpacer(order)
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

		--[[
			Include Gear has exactly one setting, so the toggle IS its caption: it sits at label width
			with the rarity select beside it, name = "". The select's own values say what they mean
			("Rare & Lower"), which is what lets the caption go. Include Consumables has five, so it is
			a full-width toggle with each setting on an indented sub-row beneath it.
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
			hidden = gearOff,
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
			width = "full",
			order = 26,
			get = function()
				return ns.db and ns.db.profile.includeConsumables
			end,
			set = function(_, value)
				ns.db.profile.includeConsumables = value
				refreshWindow()
			end,
		},
		subConsumableLevelGap = SubRow(27, consumablesOff, {
			{
				type = "description",
				name = SubLabel(L["OPTIONS_CONSUMABLE_GAP"]),
				fontSize = "medium",
				width = ns.OPTIONS_LABEL_WIDTH - ns.OPTIONS_SUB_INDENT_WIDTH,
			},
			{
				type = "select",
				name = "",
				desc = L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"],
				width = ns.OPTIONS_CONTROL_WIDTH,
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
		}),
		-- The four kind switches are added by addConsumableKinds below, at orders 28 to 31.

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

		-- Directly above Feedback & Support, after every section with settings in it.
		spacerCommands0 = ns.OptionsSpacer(80),
		headerCommands = ns.OptionsHeader(L["OPTIONS_COMMANDS_HEADER"], 81),
		spacerCommands1 = ns.OptionsSpacer(82),
		descCommands = ns.OptionsDesc(
			GetColor("INFO") .. L["OPTIONS_COMMAND"] .. "|r" .. "  " .. L["OPTIONS_COMMAND_DESCRIPTION"],
			83
		),

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

	addConsumableKinds(args, 28)
	addGenerosityStats(args, 45)
	addFeedbackLinks(args, 93)

	return {
		type = "group",
		name = ns.ADDON_TITLE,
		args = args,
	}
end
