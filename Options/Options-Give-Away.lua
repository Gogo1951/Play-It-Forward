local _, ns = ...
local L = ns.L

-- The rarity select hides while Distribute Gear is off, the gap select with its sub-row; spacerGive2 separates the two.
local GearOff = ns.OptionsProfileOff("includeGear")
local ConsumablesOff = ns.OptionsProfileOff("includeConsumables")
local DisenchantOff = ns.OptionsProfileOff("disenchantUnmatched")

-- Each character mail from here reaches, class-colored with its level, and its realm when not this one.
local function DisenchanterValues()
	local out = {}
	local keys, mailable = ns.Alts:DisenchantChoices()
	for _, key in ipairs(keys) do
		local alt = mailable[key]
		local label = ns.ColorName(alt.name or "?", alt.class)
			.. " "
			.. ns.OptionsHelp("(" .. (alt.level or "?") .. ")")
		if alt.realm ~= ns.PlayerRealm() then
			label = label .. " " .. ns.OptionsHelp(alt.realm or "")
		end
		out[key] = label
	end
	return out
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

local SubLabel = ns.OptionsHelp

-- One sub-row per kind under Distribute Consumables, hiding with its select.
local function AddConsumableKinds(args, startOrder)
	for index, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		local strings = ns.CONSUMABLE_KIND_STRINGS[kind]
		args["subKind" .. kind] = SubRow(startOrder + index - 1, ConsumablesOff, {
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
					ns.RefreshMailWindow()
				end,
			},
		})
	end
end

--------------------------------------------------------------------------------
-- What to Give Away Panel
--------------------------------------------------------------------------------

function ns.BuildGiveAwayOptions()
	local args = {
		descIntro = ns.OptionsDesc(L["OPTIONS_GIVE_AWAY_INTRO"], 1),
		spacerIntro = ns.OptionsSpacer(2),

		--[[
			Distribute Gear has exactly one setting, so the toggle IS its caption: it sits at label width
			with the rarity select beside it, name = "". The select's own values say what they mean
			("Rare & Lower"), which is what lets the caption go. Distribute Consumables has five, so it is
			a full-width toggle with each setting on an indented sub-row beneath it.
		]]
		toggleIncludeGear = ns.OptionsProfileToggle(
			"includeGear",
			L["OPTIONS_DISTRIBUTE_GEAR"],
			L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"],
			3,
			ns.OPTIONS_LABEL_WIDTH,
			ns.RefreshMailWindow
		),
		selectMaxRarity = {
			type = "select",
			name = "",
			desc = L["OPTIONS_MAX_RARITY_DESCRIPTION"],
			width = ns.OPTIONS_CONTROL_WIDTH,
			order = 4,
			hidden = GearOff,
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
				ns.RefreshMailWindow()
			end,
		},

		-- Between the two rows only: no trailing one.
		spacerGive2 = ns.OptionsSpacer(5),
		toggleIncludeConsumables = ns.OptionsProfileToggle(
			"includeConsumables",
			L["OPTIONS_DISTRIBUTE_CONSUMABLES"],
			L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"],
			6,
			"full",
			ns.RefreshMailWindow
		),
		subConsumableLevelGap = SubRow(7, ConsumablesOff, {
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
					ns.RefreshMailWindow()
				end,
			},
		}),
		-- The five kind switches are added by AddConsumableKinds below, at orders 8 to 12.

		--[[
			The Distribute Gear shape again: one setting, so the toggle is its caption with the
			select beside it. The characters are read each time the panel draws, so one that just
			logged in for the first time is there.
		]]
		spacerDisenchant0 = ns.OptionsSpacer(20),
		headerDisenchant = ns.OptionsHeader(L["OPTIONS_DISENCHANT_HEADER"], 21),
		spacerDisenchant1 = ns.OptionsSpacer(22),
		descDisenchant = ns.OptionsDesc(L["OPTIONS_DISENCHANT_DESCRIPTION"], 23),
		spacerDisenchant2 = ns.OptionsSpacer(24),
		toggleDisenchant = ns.OptionsProfileToggle(
			"disenchantUnmatched",
			L["OPTIONS_DISENCHANT_SEND"],
			L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"],
			25,
			ns.OPTIONS_LABEL_WIDTH,
			ns.RefreshMailWindow
		),
		selectDisenchanter = {
			type = "select",
			name = "",
			desc = L["OPTIONS_DISENCHANTER_DESCRIPTION"],
			width = ns.OPTIONS_CONTROL_WIDTH,
			order = 26,
			hidden = DisenchantOff,
			disabled = function()
				return #ns.Alts:DisenchantChoices() == 0
			end,
			values = DisenchanterValues,
			sorting = function()
				return (ns.Alts:DisenchantChoices())
			end,
			get = function()
				return (ns.Alts:Disenchanter())
			end,
			set = function(_, value)
				ns.Alts:SetDisenchanter(value)
				ns.RefreshMailWindow()
			end,
		},
	}

	AddConsumableKinds(args, 8)

	return {
		type = "group",
		name = L["TAB_GIVE_AWAY"],
		args = args,
	}
end
