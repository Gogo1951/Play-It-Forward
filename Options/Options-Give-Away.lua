local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

local ConsumablesOff = ns.OptionsProfileOff("includeConsumables")

local function DisenchanterValues()
	local out = {}
	local keys, mailable = ns.Alts:DisenchantChoices()
	for _, key in ipairs(keys) do
		local alt = mailable[key]
		local label = ns.ColorName(alt.name or "?", alt.class)
			.. " "
			.. Kit.Color("HELP", "(" .. (alt.level or "?") .. ")")
		if alt.realm ~= ns.PlayerRealm() then
			label = label .. " " .. Kit.Color("HELP", alt.realm or "")
		end
		out[key] = label
	end
	return out
end

-- The root panel's Features switch, under this panel's own caption.
local function GiftSwitch(setting, nameKey)
	local switch = Kit.FeatureSwitch(setting)
	switch.name = L[nameKey]
	return switch
end

--------------------------------------------------------------------------------
-- Consumable Kinds and Keep in Bags
--------------------------------------------------------------------------------

-- Keep in Bags belongs to its kind's switch, so it hides while the kind is off.
local KEEP_LABEL_WIDTH = 0.75

local function KeepValues()
	local out = {}
	for _, amount in ipairs(ns.Bags.KEEP_ORDER) do
		out[amount] = tostring(amount)
	end
	return out
end

local function AddConsumableKinds(args, startOrder)
	for index, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		local strings = ns.CONSUMABLE_KIND_STRINGS[kind]
		local function KindOff()
			return not (ns.db and ns.db.profile.consumableKinds[kind])
		end
		local keepLabel = Kit.Label(
			Kit.SubLabel(L["OPTIONS_KEEP_IN_BAGS"]),
			nil,
			KEEP_LABEL_WIDTH,
			L["OPTIONS_KEEP_IN_BAGS_DESCRIPTION"]
		)
		keepLabel.hidden = KindOff
		args["subKind" .. kind] = Kit.SubRow(startOrder + index * 0.1, ConsumablesOff, {
			{
				type = "toggle",
				name = Kit.SubLabel(L[strings.label]),
				desc = L[strings.description],
				width = Kit.SUB_LABEL_WIDTH - KEEP_LABEL_WIDTH,
				get = Kit.Get("profile", "consumableKinds." .. kind),
				set = Kit.Set("profile", "consumableKinds." .. kind, ns.RefreshMailWindow),
			},
			keepLabel,
			{
				type = "select",
				name = "",
				desc = L["OPTIONS_KEEP_IN_BAGS_DESCRIPTION"],
				width = Kit.CONTROL_WIDTH,
				hidden = KindOff,
				values = KeepValues,
				sorting = ns.Bags.KEEP_ORDER,
				get = Kit.GetChoice("profile", "keepInBags." .. kind, KeepValues, 0),
				set = Kit.Set("profile", "keepInBags." .. kind, ns.RefreshMailWindow),
			},
		})
	end
end

--------------------------------------------------------------------------------
-- Never Give Away
--------------------------------------------------------------------------------

local REMOVE_ICON = "Interface/Buttons/UI-GroupLoot-Pass-Up"

-- The section stays while the list is empty: its line says how an item gets here.
local function AddNeverGive(args, startOrder)
	local order = Kit.Section(
		args,
		"neverGive",
		startOrder,
		L["NEVER_GIVE_AWAY"],
		L["OPTIONS_NEVER_GIVE_DESCRIPTION"]:format("|T" .. REMOVE_ICON .. ":16|t")
	)
	local itemIDs = ns.Bags:NeverGiveList()
	Kit.SortItems(itemIDs)
	local cold = {}
	for _, itemID in ipairs(itemIDs) do
		if not C_Item.GetItemInfo(itemID) then
			cold[#cold + 1] = itemID
		end
		args["neverGive" .. itemID] = Kit.Row(order, nil, {
			{
				type = "input",
				name = "",
				dialogControl = Kit.ITEM_LINK_WIDGET,
				width = Kit.ROW_WIDTH - Kit.REMOVE_ICON_WIDTH,
				get = function()
					return tostring(itemID)
				end,
				set = function() end,
			},
			-- Put back in one click from the row's list, so no confirm.
			{
				type = "execute",
				name = "",
				desc = L["OPTIONS_NEVER_GIVE_REMOVE"],
				image = REMOVE_ICON,
				imageWidth = 16,
				imageHeight = 16,
				width = Kit.REMOVE_ICON_WIDTH,
				func = function()
					ns.Bags:GiveAgain(itemID)
				end,
			},
		})
		order = order + 1
	end
	Kit.WarmItems(cold, ns.OPTIONS_REGISTRY.GiveAway)
end

--------------------------------------------------------------------------------
-- What to Give Away Panel
--------------------------------------------------------------------------------

function ns.BuildGiveAwayOptions()
	local args = {
		descIntro = Kit.Desc(L["OPTIONS_GIVE_AWAY_INTRO"], 1),
		spacerIntro = Kit.Spacer(2),

		-- One setting, so the switch is its caption: the select's values ("Rare & Lower") say what they mean.
		gear = Kit.ToggleRow(3, GiftSwitch("includeGear", "OPTIONS_DISTRIBUTE_GEAR"), {
			control = {
				type = "select",
				desc = L["OPTIONS_MAX_RARITY_DESCRIPTION"],
				values = function()
					local out = {}
					for _, quality in ipairs({ 2, 3, 4 }) do
						out[quality] = ns.QualityColor(quality) .. ns.QualityName(quality) .. "|r"
					end
					return out
				end,
				get = Kit.Get("profile", "maxRarity"),
				set = Kit.Set("profile", "maxRarity", ns.RefreshMailWindow),
			},
		}),

		spacerConsumables = Kit.Spacer(4),
		consumables = Kit.ToggleRow(5, GiftSwitch("includeConsumables", "OPTIONS_DISTRIBUTE_CONSUMABLES")),
		consumableLevelGap = Kit.SubLabelRow(6, ConsumablesOff, L["OPTIONS_CONSUMABLE_GAP"], {
			type = "select",
			desc = L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"],
			values = ns.CONSUMABLE_GAP_VALUES,
			sorting = ns.CONSUMABLE_GAP_ORDER,
			get = function()
				return ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
			end,
			set = Kit.Set("profile", "consumableLevelGap", ns.RefreshMailWindow),
		}),
		-- The five kind rows are added by AddConsumableKinds below, at orders 7.1 to 7.5.

		spacerDisenchant = Kit.Spacer(8),
		disenchant = Kit.ToggleRow(9, {
			type = "toggle",
			name = L["OPTIONS_DISENCHANT_SEND"],
			desc = L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"],
			get = Kit.Get("profile", "disenchantUnmatched"),
			set = Kit.Set("profile", "disenchantUnmatched", ns.RefreshMailWindow),
		}, {
			control = {
				type = "select",
				desc = L["OPTIONS_DISENCHANTER_DESCRIPTION"],
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
					ns.RefreshSettings()
				end,
			},
		}),
	}

	AddConsumableKinds(args, 7)
	AddNeverGive(args, 20)

	return {
		type = "group",
		name = L["TAB_GIVE_AWAY"],
		args = args,
	}
end
