local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

local UI = ns.UI
local Picker = ns.Picker

--[[
	The mail window's top bar: the giftability ticks and dropdowns, kept in step with the profile, and
	the pickers those dropdowns open. Features/UI-Window.lua builds the frame and calls
	UI:BuildTopBar on it.

	Every size and gap here is on the spacing scale, as in Features/UI-Window.lua.
]]
local TICK_SIZE = UI.TICK_SIZE
--[[
	The top bar starts clear of the portrait, CONTROLS_LEFT in, as Bags Buffs & Buttons' windows'
	controls do, TOP_BAR_Y down. Its right edge sits EDGE in from the window's.
]]
local CONTROLS_LEFT = 64
local TOP_BAR_Y = 32
local EDGE = 16
local CONTROL_GAP = 8 -- from a tick's caption to its dropdown, and between the kind ticks
local LINE_GAP = 4 -- between the top bar's two lines
-- The middles of the top bar's two lines, where its dropdowns center.
local LINE1_MIDDLE = TOP_BAR_Y + TICK_SIZE / 2
local LINE2_MIDDLE = TOP_BAR_Y + TICK_SIZE + LINE_GAP + TICK_SIZE / 2
-- Where the kind ticks end, which Features/UI-Window.lua hangs the list from.
UI.TOP_BAR_BOTTOM = TOP_BAR_Y + 2 * TICK_SIZE + LINE_GAP

-- Sized to their longest value: "Epic & Lower" and "Outgrown by 20+ Levels".
local RARITY_WIDTH = 128
local GAP_WIDTH = 208

-- Tooltip line colors, unpacked once: GetColorRGB mid-argument-list would keep only its first value.
local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")

local BuildDropdown = UI.BuildDropdown

--------------------------------------------------------------------------------
-- Building the top bar
--------------------------------------------------------------------------------

--[[
	A top-bar tick: a checkbox with its caption to the right, the caption clickable too. Its
	tooltip is the options panel's own description for the same setting, so the window and the
	panel never explain one switch two ways. The caller anchors it and sets its OnClick.
]]
local function BuildToggle(parent, text, colorKey, tooltipKey)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(TICK_SIZE, TICK_SIZE)
	check.colorKey = colorKey

	check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
	check.label:SetText(text)
	check.label:SetTextColor(ns.GetColorRGB(colorKey))
	check:SetHitRectInsets(0, -(check.label:GetStringWidth() + 2), 0, 0)

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

--[[
	A tick or dropdown in the window writes the same profile key its twin in the options panel
	does, so an open panel is told to redraw as well as the bags being re-read against it. The
	/who pool already found is kept.
]]
local function AfterToggle()
	UI:SyncControls()
	UI:Rescan()
	local registry = LibStub("AceConfigRegistry-3.0")
	registry:NotifyChange(ns.OPTIONS_REGISTRY.General)
	registry:NotifyChange(ns.OPTIONS_REGISTRY.GiveAway)
end

function UI:BuildTopBar(window)
	--[[
		The giftability controls, the same set the options panel carries and drawing the same
		locale strings. Consumables leads on the left with its level rule beside it and its five
		kind ticks beneath; Gear sits on the right with its rarity cap. Each
		dropdown value states what it means ("Rare & Lower", "Outgrown by 20+ Levels"), so the
		window cannot word a setting differently to the panel. A dropdown hides while its tick is
		off, as its select does in the panel.
	]]
	local consumables =
		BuildToggle(window, L["WINDOW_CONSUMABLES_LABEL"], "TITLE", "OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION")
	consumables:SetPoint("TOPLEFT", CONTROLS_LEFT, -TOP_BAR_Y)
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

	-- Vertically centered on the ticks' line.
	local rarity = BuildDropdown(window, RARITY_WIDTH)
	rarity:SetPoint("RIGHT", window, "TOPRIGHT", -EDGE, -LINE1_MIDDLE)
	rarity:SetScript("OnClick", function(button)
		UI:OpenRarityPicker(button)
	end)
	window.rarityButton = rarity

	-- Right to left from the dropdown: caption, then its box.
	local gear = BuildToggle(window, L["WINDOW_GEAR_LABEL"], "TITLE", "OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION")
	gear.label:ClearAllPoints()
	gear.label:SetPoint("RIGHT", rarity, "LEFT", -CONTROL_GAP, 0)
	gear:SetPoint("RIGHT", gear.label, "LEFT", -2, 0)
	gear:SetScript("OnClick", function(check)
		ns.db.profile.includeGear = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.gearToggle = gear

	--[[
		Disenchant Unmatched Gear on the second line, under Gear and laid out the same way: its
		dropdown under the rarity cap at the same width, so the two right edges line up, and the
		tick and caption right to left from it, centered on the kind ticks' line.
	]]
	local enchanter = BuildDropdown(window, RARITY_WIDTH)
	enchanter:SetPoint("RIGHT", window, "TOPRIGHT", -EDGE, -LINE2_MIDDLE)
	enchanter:SetScript("OnClick", function(button)
		UI:OpenDisenchanterPicker(button)
	end)
	window.disenchanterButton = enchanter

	local disenchant = BuildToggle(window, ns.DisenchantName(), "TITLE", "OPTIONS_DISENCHANT_SEND_DESCRIPTION")
	disenchant.label:ClearAllPoints()
	disenchant.label:SetPoint("RIGHT", enchanter, "LEFT", -CONTROL_GAP, 0)
	disenchant:SetPoint("RIGHT", disenchant.label, "LEFT", -2, 0)
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
			toggle:SetPoint("TOPLEFT", consumables, "BOTTOMLEFT", 0, -LINE_GAP)
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

--[[
	The whole top bar at once. The one entry point, so a caller that changes any setting cannot
	refresh half the bar: Features/Core.lua's profile hook, the options panel's own setters and
	the window's ticks all come through here.
]]
function UI:SyncControls()
	self:SyncToggles()
	self:SyncRarityButton()
	self:SyncGapButton()
	self:SyncDisenchanterButton()
end

--[[
	The kind ticks are disabled and dimmed, never hidden, while Consumables is off, so the row
	keeps its shape and the player can see what will come back with it.
]]
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

--[[
	Snapped for display the same way the panel's dropdown is, so a stored value between stops
	shows the stop it reads as rather than blank. The stored number is left alone.
]]
function UI:SyncGapButton()
	if not self.frame or not self.frame.gapButton then
		return
	end
	local gap = ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
	self.frame.gapButton.text:SetText(GetColor("TEXT") .. (ns.CONSUMABLE_GAP_VALUES[gap] or "") .. "|r")
end

-- The enchanter's name in its class color, or a muted prompt while none is picked for this realm cluster.
function UI:SyncDisenchanterButton()
	if not self.frame or not self.frame.disenchanterButton then
		return
	end
	local _, alt = ns.Alts:Disenchanter()
	local text = alt and ns.ColorName(ns.Alts:Address(alt), alt.class)
		or (GetColor("MUTED") .. L["WINDOW_DISENCHANT_PICK"] .. "|r")
	self.frame.disenchanterButton.text:SetText(text)
end

--[[
	The option lists are split from opening the pickers so Tests/Options-Values.lua can read them
	without a frame, the same split Tests/Manual-Assignment.lua relies on for the recipient list.
	Both draw the panel's own strings rather than wording anything a second time.
]]
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

function UI:GapPickerOptions()
	local options = {}
	for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
		options[#options + 1] = {
			text = GetColor("TEXT") .. (ns.CONSUMABLE_GAP_VALUES[gap] or "") .. "|r",
			gap = gap,
		}
	end
	return options
end

-- The options panel's own list: every character mail from here reaches, in name order.
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
		-- Compared against nil, never truthiness: the All Consumables stop is a zero.
		if option.gap == nil then
			return
		end
		ns.db.profile.consumableLevelGap = option.gap
		AfterToggle()
	end)
end
