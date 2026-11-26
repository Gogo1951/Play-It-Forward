local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

local UI = ns.UI
local Picker = ns.Picker

-- On the Spacing Scale, as in Features/UI-Window.lua.
local TICK_SIZE = UI.TICK_SIZE
-- Clear of the portrait, as Bags Buffs & Buttons' window controls are.
local CONTROLS_LEFT = 64
local TOP_BAR_Y = 32
local EDGE = 16
local LINE_HEIGHT = UI.FIELD_HEIGHT
local CONTROL_GAP = 8
local CAPTION_GAP = 4
local LINE_GAP = 8
local LINE1_MIDDLE = TOP_BAR_Y + LINE_HEIGHT / 2
local LINE2_MIDDLE = TOP_BAR_Y + LINE_HEIGHT + LINE_GAP + LINE_HEIGHT / 2
-- Features/UI-Window.lua hangs the list from it.
UI.TOP_BAR_BOTTOM = TOP_BAR_Y + 2 * LINE_HEIGHT + LINE_GAP

-- Gear's and Disenchant's fields, one width so their right edges line up; the level rule's fits "Outgrown by 20+ Levels".
local RARITY_WIDTH = 144
local GAP_WIDTH = 208

-- Unpacked once: ns.GetColorRGB mid-argument-list would keep only its first value.
local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")

local BuildDropdown = UI.BuildDropdown

--------------------------------------------------------------------------------
-- Building the top bar
--------------------------------------------------------------------------------

-- The tooltip is the options panel's own description, so the two never explain one switch two ways.
local function BuildToggle(parent, text, colorKey, tooltipKey)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(TICK_SIZE, TICK_SIZE)
	check.colorKey = colorKey

	-- One type size in the window (Style Guide → WINDOWS).
	check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	check.label:SetPoint("LEFT", check, "RIGHT", CAPTION_GAP, 0)
	check.label:SetText(text)
	check.label:SetTextColor(ns.GetColorRGB(colorKey))
	check:SetHitRectInsets(0, -(check.label:GetStringWidth() + CAPTION_GAP), 0, 0)

	check:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, ns.GetColorRGB("TITLE"))
		GameTooltip:AddLine(L[tooltipKey], BODY_R, BODY_G, BODY_B, true)
		GameTooltip:Show()
	end)
	check:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	ns.SkinWidget("CheckBox", check)
	return check
end

-- Same profile keys as the options panel, so open panels redraw too. The /who pool is kept.
local function AfterToggle()
	UI:SyncControls()
	UI:Rescan()
	ns.RefreshSettings()
end

function UI:BuildTopBar(window)
	local consumables =
		BuildToggle(window, L["WINDOW_CONSUMABLES_LABEL"], "TITLE", "OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION")
	consumables:SetPoint("LEFT", window, "TOPLEFT", CONTROLS_LEFT, -LINE1_MIDDLE)
	consumables:SetScript("OnClick", function(check)
		ns.db.profile.includeConsumables = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.consumablesToggle = consumables

	local gap = BuildDropdown(window, GAP_WIDTH)
	gap:SetPoint("LEFT", consumables.label, "RIGHT", CONTROL_GAP, 0)
	gap:SetScript("OnClick", function(button)
		UI:OpenGapPicker(button)
	end)
	window.gapButton = gap

	local rarity = BuildDropdown(window, RARITY_WIDTH)
	rarity:SetPoint("RIGHT", window, "TOPRIGHT", -EDGE, -LINE1_MIDDLE)
	rarity:SetScript("OnClick", function(button)
		UI:OpenRarityPicker(button)
	end)
	window.rarityButton = rarity

	local gear = BuildToggle(window, L["WINDOW_GEAR_LABEL"], "TITLE", "OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION")
	gear.label:ClearAllPoints()
	gear.label:SetPoint("RIGHT", rarity, "LEFT", -CONTROL_GAP, 0)
	gear:SetPoint("RIGHT", gear.label, "LEFT", -CAPTION_GAP, 0)
	gear:SetScript("OnClick", function(check)
		ns.db.profile.includeGear = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.gearToggle = gear

	local enchanter = BuildDropdown(window, RARITY_WIDTH)
	enchanter:SetPoint("RIGHT", window, "TOPRIGHT", -EDGE, -LINE2_MIDDLE)
	enchanter:SetScript("OnClick", function(button)
		UI:OpenDisenchanterPicker(button)
	end)
	window.disenchanterButton = enchanter

	local disenchant = BuildToggle(window, ns.DisenchantName(), "TITLE", "OPTIONS_DISENCHANT_SEND_DESCRIPTION")
	disenchant.label:ClearAllPoints()
	disenchant.label:SetPoint("RIGHT", enchanter, "LEFT", -CONTROL_GAP, 0)
	disenchant:SetPoint("RIGHT", disenchant.label, "LEFT", -CAPTION_GAP, 0)
	disenchant:SetScript("OnClick", function(check)
		ns.db.profile.disenchantUnmatched = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.disenchantToggle = disenchant

	window.kindToggles = {}
	local previous
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		local strings = ns.CONSUMABLE_KIND_STRINGS[kind]
		local toggle = BuildToggle(window, L[strings.label], "TEXT", strings.description)
		if previous then
			toggle:SetPoint("LEFT", previous.label, "RIGHT", CONTROL_GAP, 0)
		else
			toggle:SetPoint("LEFT", window, "TOPLEFT", CONTROLS_LEFT, -LINE2_MIDDLE)
		end
		toggle:SetScript("OnClick", function(check)
			ns.db.profile.consumableKinds[kind] = check:GetChecked() and true or false
			AfterToggle()
		end)
		window.kindToggles[kind] = toggle
		previous = toggle
	end
end

--------------------------------------------------------------------------------
-- Keeping it in step
--------------------------------------------------------------------------------

-- The one entry point (profile hook, panel setters, the window's ticks), so no caller refreshes half the bar.
function UI:SyncControls()
	self:SyncToggles()
	self:SyncRarityButton()
	self:SyncGapButton()
	self:SyncDisenchanterButton()
end

-- Kind ticks dim, never hide, while Consumables is off, so the line keeps its shape.
function UI:SyncToggles()
	local window = self.frame
	if not window or not window.gearToggle then
		return
	end
	local profile = ns.db.profile
	window.gearToggle:SetChecked(profile.includeGear)
	window.rarityButton:SetShown(profile.includeGear)
	window.consumablesToggle:SetChecked(profile.includeConsumables)
	window.gapButton:SetShown(profile.includeConsumables)
	window.disenchantToggle:SetChecked(profile.disenchantUnmatched)
	window.disenchanterButton:SetShown(profile.disenchantUnmatched)
	for kind, toggle in pairs(window.kindToggles) do
		toggle:SetChecked(profile.consumableKinds[kind])
		toggle:SetEnabled(profile.includeConsumables)
		toggle.label:SetTextColor(ns.GetColorRGB(profile.includeConsumables and toggle.colorKey or "MUTED"))
	end
end

function UI:SyncRarityButton()
	if not self.frame or not self.frame.rarityButton then
		return
	end
	local cap = ns.db.profile.maxRarity
	self.frame.rarityButton.text:SetText(("%s%s|r"):format(ns.QualityColor(cap), ns.QualityName(cap)))
end

-- Snapped for display, as the panel's is, so an off-stop value never shows blank; the stored number is left alone.
function UI:SyncGapButton()
	if not self.frame or not self.frame.gapButton then
		return
	end
	local gap = ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
	self.frame.gapButton.text:SetText(GetColor("VALUE") .. (ns.CONSUMABLE_GAP_VALUES[gap] or "") .. "|r")
end

function UI:SyncDisenchanterButton()
	if not self.frame or not self.frame.disenchanterButton then
		return
	end
	local _, alt = ns.Alts:Disenchanter()
	local text = alt and ns.ColorName(ns.Alts:Address(alt), alt.class)
		or (GetColor("MUTED") .. L["WINDOW_DISENCHANT_PICK"] .. "|r")
	self.frame.disenchanterButton.text:SetText(text)
end

-- Option lists split from the pickers so Tests/Options-Values.lua reads them without a frame.
function UI:RarityPickerOptions()
	local options = {}
	for _, quality in ipairs({ 2, 3, 4 }) do
		options[#options + 1] = {
			text = ("%s%s|r"):format(ns.QualityColor(quality), ns.QualityName(quality)),
			quality = quality,
		}
	end
	return options
end

--[[
	Plain words, so Menu-Kit colors the pick. Marked by selected: the field's own text is colored,
	so it would match no option by its words.
]]
function UI:GapPickerOptions()
	local options = {}
	local current = ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
	for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
		options[#options + 1] = {
			text = ns.CONSUMABLE_GAP_VALUES[gap] or "",
			gap = gap,
			selected = gap == current,
		}
	end
	return options
end

function UI:DisenchanterPickerOptions()
	local options = {}
	local keys, mailable = ns.Alts:DisenchantChoices()
	for _, key in ipairs(keys) do
		local alt = mailable[key]
		options[#options + 1] = {
			text = ("%s " .. GetColor("MUTED") .. "(%s)|r"):format(
				ns.ColorName(ns.Alts:Address(alt), alt.class),
				tostring(alt.level or "?")
			),
			altKey = key,
		}
	end
	if #options == 0 then
		options[1] = { text = GetColor("MUTED") .. L["WINDOW_DISENCHANT_NONE"] .. "|r", disabled = true }
	end
	return options
end

function UI:OpenDisenchanterPicker(anchor)
	Picker:Open(anchor, self:DisenchanterPickerOptions(), function(option)
		if not option.altKey then
			return
		end
		ns.Alts:SetDisenchanter(option.altKey)
		AfterToggle()
	end)
end

function UI:OpenRarityPicker(anchor)
	Picker:Open(anchor, self:RarityPickerOptions(), function(option)
		if not option.quality then
			return
		end
		ns.db.profile.maxRarity = option.quality
		AfterToggle()
	end)
end

function UI:OpenGapPicker(anchor)
	Picker:Open(anchor, self:GapPickerOptions(), function(option)
		-- Against nil: the All Consumables stop is a zero.
		if option.gap == nil then
			return
		end
		ns.db.profile.consumableLevelGap = option.gap
		AfterToggle()
	end)
end
