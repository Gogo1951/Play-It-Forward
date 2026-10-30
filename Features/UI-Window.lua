local ADDON_NAME, ns = ...
local L = ns.L

local GetColor = ns.GetColor

ns.UI = {}
local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

local ROW_HEIGHT = 24
--[[
	The top bar starts clear of the portrait, CONTROLS_LEFT in, as Bags Buffs & Buttons' windows'
	controls do. The frame is wider by that clearance, so the bar keeps the room translations had.
]]
local CONTROLS_LEFT = 64
local FRAME_WIDTH = 600 + CONTROLS_LEFT - 12
local FRAME_HEIGHT = 470
--[[
	The corner grip's limits. The default width is also the narrowest, because the top bar is laid
	out for it; the shortest still shows a few rows between the top bar and the buttons.
]]
local MIN_HEIGHT = 320
local MAX_WIDTH = 1200
local MAX_HEIGHT = 1000
-- The row's width less the scrollbar and the frame's border, as the inset leaves it.
local ROW_INSET = 44
--[[
	The item column gets the room, and all of a wider window: a random suffix ("of the Monkey")
	ends the name and is what says who the item is for. The widest recipient label is a cross-realm
	name with its level, "Bubbafrances-Ashkandi (26)" shaped, which fits in 200. The tick and the
	gaps take ITEM_SLACK, so the two columns stay inside window.rowWidth, clear of the scrollbar.
]]
local RECIPIENT_WIDTH = 200
local ITEM_SLACK = 56

local function ItemWidth(rowWidth)
	return rowWidth - RECIPIENT_WIDTH - ITEM_SLACK
end
-- A floor, not the width: both buttons are sized to the widest label either can show.
local BUTTON_WIDTH = 150
local BUTTON_PAD = 24 -- room around the label, matching the picker's ruler allowance
-- Neither button may pass half the space between the margins. A too-long label is clipped instead.
local BUTTON_GAP = 20

--[[
	The portrait frame Bags Buffs & Buttons' windows use, the gold gift in its portrait. A client
	without it gets the plain frame and no portrait. The gift sits 4px left and 1px up of Gift.tga's
	centre on purpose: the template's ring is centred there, not on the portrait texture.
]]
local FRAME_TEMPLATE = ns.PickTemplate("PortraitFrameTemplate", "BasicFrameTemplate", "BackdropTemplate")
local INSET_TEMPLATE = ns.PickTemplate("InsetFrameTemplate3", "InsetFrameTemplate2", "InsetFrameTemplate")
local PORTRAIT_ICON = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Includes\\Images\\Gift"
-- The portrait frame's border is 4 wide, as ButtonFrameTemplate places its own inset; the plain frame's is 6.
local INSET_LEFT = FRAME_TEMPLATE == "PortraitFrameTemplate" and 4 or 6

local rows = {}
-- The section bands, pooled like the rows.
local headers = {}

-- Tooltip line colors, unpacked once: GetColorRGB mid-argument-list would keep only its first value.
local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")
local HELP_R, HELP_G, HELP_B = ns.GetColorRGB("HELP")

-- Sized to their longest value: "Epic & Lower" and "Outgrown by 20+ Levels".
local RARITY_WIDTH = 130
local GAP_WIDTH = 200

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

--[[
	A top-bar dropdown: its current value, an arrow and a hover highlight. Two are built from
	this, so the pair cannot drift apart the way two hand-rolled copies would. It carries no
	caption: the tick beside it names what it governs, as the toggle does in the options panel.

	The caller anchors it. The value text is anchored on both sides and ellipsized, or a long one
	runs under the arrow.
]]
local function BuildDropdown(parent, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, 18)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetPoint("LEFT", 3, 0)
	button.text:SetPoint("RIGHT", -16, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetWordWrap(false)

	local arrow = button:CreateTexture(nil, "OVERLAY")
	arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	arrow:SetSize(14, 14)
	arrow:SetPoint("RIGHT", 0, 0)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.10)

	ns.SkinWidget("Button", button)
	return button
end

--[[
	A top-bar tick: a checkbox with its caption to the right, the caption clickable too. Its
	tooltip is the options panel's own description for the same setting, so the window and the
	panel never explain one switch two ways. The caller anchors it and sets its OnClick.
]]
local function BuildToggle(parent, text, colorKey, tooltipKey)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(20, 20)
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

function UI:BuildFrame()
	if UI.frame then
		return UI.frame
	end

	-- A stock template brings the chrome and, the point of using one, gets restyled by ElvUI.
	local window = CreateFrame("Frame", "PlayItForwardMailFrame", UIParent, FRAME_TEMPLATE)
	-- The size the player last left it at, held inside the grip's limits for a saved size from another build.
	local size = ns.db.profile.windowSize
	local width = math.min(MAX_WIDTH, math.max(FRAME_WIDTH, size.width or FRAME_WIDTH))
	local height = math.min(MAX_HEIGHT, math.max(MIN_HEIGHT, size.height or FRAME_HEIGHT))
	window:SetSize(width, height)

	-- A mailbox right of center would put a wide window off-screen, so it is clamped and draggable.
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		UI:SaveGeometry()
	end)

	--[[
		Resized from the corner grip below. Everything but the rows is anchored by two corners and
		follows on its own; the rows have widths, which UI:Relayout sets.
	]]
	window:SetResizable(true)
	if window.SetResizeBounds then
		window:SetResizeBounds(FRAME_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
	end
	window:SetScript("OnSizeChanged", function()
		UI:Relayout()
	end)

	-- AceDB materializes windowPos per profile, so .point is what says the window was ever dragged.
	local pos = ns.db.profile.windowPos
	if pos.point then
		window:SetPoint(pos.point, UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
	elseif MailFrame then
		window:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, 0)
	else
		window:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
	end
	-- Only draw our own backdrop when the client has neither frame template.
	if FRAME_TEMPLATE == "BackdropTemplate" and window.SetBackdrop then
		window:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
	end
	window:Hide()

	--[[
		In the template's own title slot, "Distribution Window // Play It Forward" in branded colors: the
		title white, the separator gray, the add-on name blue. Only the backdrop fallback has no slot, and
		gets a font string.
	]]
	local titleText = GetColor("TEXT") .. L["WINDOW_TITLE"] .. "|r "
		.. GetColor("SEPARATOR") .. "//" .. "|r "
		.. GetColor("INFO") .. L["ADDON_TITLE"] .. "|r"
	if window.SetTitle then
		window:SetTitle(titleText)
	elseif window.TitleText then
		window.TitleText:SetText(titleText)
	else
		local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		title:SetPoint("TOP", 0, -10)
		title:SetText(titleText)
	end
	if window.SetPortraitToAsset then
		window:SetPortraitToAsset(PORTRAIT_ICON)
	end

	-- The templates supply CloseButton, so only build one when it did not.
	local close = window.CloseButton
	if not close then
		close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
	end
	close:SetScript("OnClick", function()
		UI:Close()
	end)

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
	consumables:SetPoint("TOPLEFT", CONTROLS_LEFT, -28)
	consumables:SetScript("OnClick", function(check)
		ns.db.profile.includeConsumables = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.consumablesToggle = consumables

	local gap = BuildDropdown(window, GAP_WIDTH)
	gap:SetPoint("LEFT", consumables.label, "RIGHT", 6, 0)
	gap:SetScript("OnClick", function(button)
		UI:OpenGapPicker(button)
	end)
	window.gapButton = gap

	-- Vertically centered on the ticks' line: a tick is 20 tall from -28, so its middle is -38.
	local rarity = BuildDropdown(window, RARITY_WIDTH)
	rarity:SetPoint("RIGHT", window, "TOPRIGHT", -12, -38)
	rarity:SetScript("OnClick", function(button)
		UI:OpenRarityPicker(button)
	end)
	window.rarityButton = rarity

	-- Right to left from the dropdown: caption, then its box.
	local gear = BuildToggle(window, L["WINDOW_GEAR_LABEL"], "TITLE", "OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION")
	gear.label:ClearAllPoints()
	gear.label:SetPoint("RIGHT", rarity, "LEFT", -6, 0)
	gear:SetPoint("RIGHT", gear.label, "LEFT", -2, 0)
	gear:SetScript("OnClick", function(check)
		ns.db.profile.includeGear = check:GetChecked() and true or false
		AfterToggle()
	end)
	window.gearToggle = gear

	--[[
		Disenchant Unmatched Items on the second line, under Gear and laid out the same way: its
		dropdown under the rarity cap at the same width, so the two right edges line up, and the
		tick and caption right to left from it. The middle of the kind ticks' line is -60.
	]]
	local enchanter = BuildDropdown(window, RARITY_WIDTH)
	enchanter:SetPoint("RIGHT", window, "TOPRIGHT", -12, -60)
	enchanter:SetScript("OnClick", function(button)
		UI:OpenDisenchanterPicker(button)
	end)
	window.disenchanterButton = enchanter

	local disenchant = BuildToggle(window, L["WINDOW_DISENCHANT_LABEL"], "TITLE", "OPTIONS_DISENCHANT_SEND_DESCRIPTION")
	disenchant.label:ClearAllPoints()
	disenchant.label:SetPoint("RIGHT", enchanter, "LEFT", -6, 0)
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
			toggle:SetPoint("LEFT", previous.label, "RIGHT", 10, 0)
		else
			toggle:SetPoint("TOPLEFT", consumables, "BOTTOMLEFT", 0, -2)
		end
		toggle:SetScript("OnClick", function(check)
			ns.db.profile.consumableKinds[kind] = check:GetChecked() and true or false
			AfterToggle()
		end)
		window.kindToggles[kind] = toggle
		previous = toggle
	end

	local inset = CreateFrame("Frame", nil, window, INSET_TEMPLATE)
	inset:SetPoint("TOPLEFT", INSET_LEFT, -74)
	inset:SetPoint("BOTTOMRIGHT", -6, 58)

	local scroll = CreateFrame("ScrollFrame", "PlayItForwardScroll", window, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 6)
	ns.SkinScrollFrame(scroll, "PlayItForwardScroll")
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	window.content = content
	window.rowWidth = width - ROW_INSET

	--[[
		An empty list says so, or a window with nothing left reads as broken or still working.
		The hint points at the top bar, the only thing that can list more.
	]]
	local emptyText = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	emptyText:SetPoint("CENTER", inset, "CENTER", 0, 8)
	emptyText:SetText(L["WINDOW_EMPTY"])
	emptyText:SetTextColor(ns.GetColorRGB("TEXT"))
	emptyText:Hide()
	window.emptyText = emptyText

	local emptyHint = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	emptyHint:SetPoint("TOP", emptyText, "BOTTOM", 0, -4)
	emptyHint:SetText(L["WINDOW_EMPTY_HINT"])
	emptyHint:SetTextColor(ns.GetColorRGB("HELP"))
	emptyHint:Hide()
	window.emptyHint = emptyHint

	--[[
		The next step in words, so a press of Find Recipients that changes nothing still says whether
		another will help. One line, cut short rather than wrapped down into the buttons.
	]]
	local status = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("BOTTOMLEFT", 15, 40)
	status:SetPoint("BOTTOMRIGHT", -15, 40)
	status:SetJustifyH("CENTER")
	status:SetWordWrap(false)
	status:SetTextColor(ns.GetColorRGB("HELP"))
	window.statusText = status

	local find = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	find:SetSize(BUTTON_WIDTH, 22)
	find:SetPoint("BOTTOMLEFT", 10, 10)
	find:SetText(L["BUTTON_FIND_RECIPIENTS"])
	find:SetScript("OnClick", function()
		UI:FindRecipients()
	end)
	ns.SkinWidget("Button", find)
	window.findButton = find

	-- Clear of the corner grip, which takes the bottom right corner.
	local dist = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	dist:SetSize(BUTTON_WIDTH, 22)
	dist:SetPoint("BOTTOMRIGHT", -24, 10)
	dist:SetText(L["BUTTON_DISTRIBUTE"])
	dist:SetScript("OnClick", function()
		UI:Distribute()
	end)
	ns.SkinWidget("Button", dist)
	window.distributeButton = dist

	--[[
		The corner grip. A child button, so it takes the mouse before the frame-wide drag-to-move
		handler sees it.
	]]
	local grip = CreateFrame("Button", nil, window)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -4, 4)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetScript("OnMouseDown", function()
		window:StartSizing("BOTTOMRIGHT")
	end)
	grip:SetScript("OnMouseUp", function()
		window:StopMovingOrSizing()
		UI:Relayout()
		UI:SaveGeometry()
	end)
	window.resizeGrip = grip

	--[[
		A loose ruler, because a font string with both anchors set reports the width it was given
		rather than the width it wants. Both buttons take the one width: sized to their own current
		labels they would sit mismatched and resize underfoot as the labels change.
	]]
	local ruler = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ruler:Hide()
	local widest = BUTTON_WIDTH
	for _, text in ipairs({
		L["BUTTON_FIND_RECIPIENTS"],
		L["BUTTON_SEARCHING"],
		L["BUTTON_DISTRIBUTE"],
		L["BUTTON_NEEDS_MAILBOX"],
		L["BUTTON_SENDING"],
	}) do
		ruler:SetText(text)
		widest = math.max(widest, ruler:GetStringWidth() + BUTTON_PAD)
	end
	widest = math.min(math.floor((FRAME_WIDTH - 34 - BUTTON_GAP) / 2), widest)
	find:SetSize(widest, 22)
	dist:SetSize(widest, 22)

	--[[
		Escape closes it, the way it closes every other window the game opens -- the one thing
		players reach for before the X and the only close this window did not answer.

		THE CLOSING WORK LIVES ON OnHide, not on the X. UISpecialFrames only calls Hide, so
		anything hung off the button alone would be skipped by Escape and the pairings, the query
		plan and a half-finished mail run would all outlive the window. Registered after the
		window:Hide() above, or building the frame would fire this before UI.frame exists.
		OnHide also fires when UIParent hides (Alt+Z); IsShown stays true then, and that is no close.
	]]
	tinsert(UISpecialFrames, "PlayItForwardMailFrame")
	window:SetScript("OnHide", function()
		if window:IsShown() then
			return
		end
		UI:OnClosed()
	end)

	UI.frame = window
	UI:SyncControls()
	return window
end

--[[
	Where the window is and how big, both kept per profile. Read back from the frame after a drag
	or a resize: sizing from the corner can move the frame's own anchor point, so the position is
	saved again whenever the size is.
]]
function UI:SaveGeometry()
	local window = self.frame
	if not window then
		return
	end
	local point, _, relativePoint, x, y = window:GetPoint()
	ns.db.profile.windowPos = { point = point, relativePoint = relativePoint, x = x, y = y }
	ns.db.profile.windowSize = { width = window:GetWidth(), height = window:GetHeight() }
end

-- The rows, bands and list follow the window's width; the item column takes whatever it gains.
function UI:Relayout()
	local window = self.frame
	if not (window and window.content) then
		return
	end
	local rowWidth = math.max(FRAME_WIDTH, window:GetWidth() or FRAME_WIDTH) - ROW_INSET
	window.rowWidth = rowWidth
	for _, row in ipairs(rows) do
		row:SetWidth(rowWidth)
		row.itemText:SetWidth(ItemWidth(rowWidth))
	end
	for _, header in ipairs(headers) do
		header:SetWidth(rowWidth)
	end
	window.content:SetWidth(rowWidth)
end

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

--------------------------------------------------------------------------------
-- Row rendering
--------------------------------------------------------------------------------

-- Section bands, styled like Connoisseur's: a subtle gold wash and gold caption.

local function GetHeader(i)
	if headers[i] then
		return headers[i]
	end
	local header = CreateFrame("Frame", nil, UI.frame.content)
	header:SetSize(UI.frame.rowWidth or 460, ROW_HEIGHT)

	local bg = header:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", 0, -2)
	bg:SetPoint("BOTTOMRIGHT", 0, 2)
	local red, green, blue = ns.GetColorRGB("TITLE")
	bg:SetColorTexture(red, green, blue, 0.10)

	header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header.text:SetTextColor(ns.GetColorRGB("TITLE"))
	header.text:SetPoint("LEFT", 8, 0)

	headers[i] = header
	return header
end

local function GetRow(i)
	if rows[i] then
		return rows[i]
	end
	local content = UI.frame.content
	local row = CreateFrame("Frame", nil, content)
	row:SetSize(UI.frame.rowWidth or 460, ROW_HEIGHT)

	row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	row.check:SetPoint("LEFT", 0, 0)
	row.check:SetSize(20, 20)
	row.check:SetScript("OnClick", function(self)
		UI:ToggleRow(row._item, self:GetChecked() and true or false)
	end)
	--[[
		Says what the tick does, which a row cannot show: on a bare row it decides whether the
		item is searched for at all. On a dimmed tick it says why nothing can go yet, which is
		why the box keeps its mouse scripts while disabled.
	]]
	row.check:SetMotionScriptsWhileDisabled(true)
	row.check:SetScript("OnEnter", function(self)
		local item = row._item
		local text
		if item and item.recipient then
			text = L["TOOLTIP_CHECK_SEND"]
		elseif item and item.state == ns.Matcher.GIFT then
			text = L["TOOLTIP_CHECK_WAITING"]
		elseif item and item.state == ns.Matcher.UNREADABLE then
			text = L["TOOLTIP_CHECK_UNREADABLE"]
		elseif item and item.state == ns.Matcher.LEFTOVER then
			text = (#(item.eligible or {}) > 0) and L["TOOLTIP_CHECK_PICK"] or L["TOOLTIP_RECIPIENT_KEPT"]
		end
		if not text then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(text, BODY_R, BODY_G, BODY_B, true)
		GameTooltip:Show()
	end)
	row.check:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	ns.SkinWidget("CheckBox", row.check)

	row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.itemText:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
	row.itemText:SetWidth(ItemWidth(UI.frame.rowWidth or FRAME_WIDTH - ROW_INSET))
	row.itemText:SetJustifyH("LEFT")
	-- Rows sit a fixed ROW_HEIGHT apart: a wrapped name would draw over the row below, not push it down.
	row.itemText:SetWordWrap(false)

	-- The top bar's dropdown, row height: its text is ellipsized, as a wrapped name draws over the row below.
	local button = BuildDropdown(row, RECIPIENT_WIDTH)
	button:SetHeight(ROW_HEIGHT - 4)
	button:SetPoint("LEFT", row.itemText, "RIGHT", 4, 0)

	button:SetScript("OnClick", function(self)
		UI:OpenPicker(self:GetParent())
	end)
	button:SetScript("OnEnter", function(self)
		local item = self:GetParent()._item
		if not item then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["TOOLTIP_RECIPIENT"])
		--[[
			An unreadable row, or a leftover no class is eligible for, can never be offered anyone:
			its count always reads zero and "Click to reassign" points at an empty picker. Say why
			instead. A leftover some class can take keeps the count, since a hand pick works there.
		]]
		-- A Kept row on its way to your enchanter says so, and still offers the picker's Keep Item.
		if item.recipient and item.recipient.disenchant then
			local who = ns.ColorName(item.recipient.name, item.recipient.class) .. GetColor("BODY")
			GameTooltip:AddLine(L["TOOLTIP_RECIPIENT_DISENCHANT"]:format(who), BODY_R, BODY_G, BODY_B, true)
			GameTooltip:AddLine(L["TOOLTIP_RECIPIENT_HINT"], HELP_R, HELP_G, HELP_B)
			GameTooltip:Show()
			return
		end
		local reason
		if item.state == ns.Matcher.UNREADABLE then
			reason = L["ITEM_STATS_UNREADABLE"]
		elseif item.state == ns.Matcher.LEFTOVER and #(item.eligible or {}) == 0 then
			reason = L["TOOLTIP_RECIPIENT_KEPT"]
		end
		if reason then
			GameTooltip:AddLine(reason, BODY_R, BODY_G, BODY_B, true)
			GameTooltip:Show()
			return
		end
		GameTooltip:AddLine(
			L["TOOLTIP_RECIPIENT_CANDIDATES"]:format(#UI:Candidates(item), item.bandLo or 0, item.bandHi or 0),
			BODY_R,
			BODY_G,
			BODY_B
		)
		local bestFit = UI:BestFitLine(item)
		if bestFit then
			GameTooltip:AddLine(bestFit, BODY_R, BODY_G, BODY_B, true)
		end
		GameTooltip:AddLine(L["TOOLTIP_RECIPIENT_HINT"], HELP_R, HELP_G, HELP_B)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row.recipButton = button

	row:SetScript("OnEnter", function(self)
		if not self._link then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(self._link)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	rows[i] = row
	return row
end

--[[
	Matched, then still-matchable, then unreadable, then kept: the list outruns the window, so
	rows worth acting on must not fall below the fold. Unreadable outranks kept: it wants a look.
]]
local function DisplayRank(item)
	if item.recipient then
		return 1
	end
	if item.state == ns.Matcher.GIFT then
		return 2 -- scored, just nobody in range yet
	end
	if item.state == ns.Matcher.UNREADABLE then
		return 3
	end
	return 4
end

local function DisplayOrder()
	local order = {}
	for index, item in ipairs(MatchList:Items()) do
		order[#order + 1] = { item = item, index = index }
	end
	table.sort(order, function(a, b)
		local ra, rb = DisplayRank(a.item), DisplayRank(b.item)
		if ra ~= rb then
			return ra < rb
		end
		if (a.item.score or 0) ~= (b.item.score or 0) then
			return (a.item.score or 0) > (b.item.score or 0)
		end
		return a.index < b.index -- stable: bag order within a group
	end)
	return order
end

local SECTION = {
	[1] = L["SECTION_MATCHED"],
	[2] = L["SECTION_NO_RECIPIENT"],
	[3] = L["SECTION_UNREADABLE"],
	-- One key with the row label below: both surfaces read the same single word. See Locales/enUS.lua.
	[4] = L["WINDOW_KEPT"],
}

--[[
	Each band carries its row count, so a list running past the fold says how much waits below.
	Counted first, since a band's header is placed before its rows.
]]
local function RenderList()
	local order = DisplayOrder()
	local counts = {}
	for _, entry in ipairs(order) do
		local rank = DisplayRank(entry.item)
		counts[rank] = (counts[rank] or 0) + 1
	end

	local out, lastRank = {}, nil
	for _, entry in ipairs(order) do
		local rank = DisplayRank(entry.item)
		if rank ~= lastRank then
			out[#out + 1] = { header = SECTION[rank], count = counts[rank] }
			lastRank = rank
		end
		out[#out + 1] = { item = entry.item }
	end
	return out
end

function UI:Refresh()
	local window = self:BuildFrame()
	for _, row in ipairs(rows) do
		row:Hide()
	end
	for _, header in ipairs(headers) do
		header:Hide()
	end

	local list = RenderList()
	local rowIndex, headerIndex = 0, 0

	for position, entry in ipairs(list) do
		local y = -((position - 1) * ROW_HEIGHT)

		if entry.header then
			headerIndex = headerIndex + 1
			local header = GetHeader(headerIndex)
			header:SetPoint("TOPLEFT", 0, y)
			header.text:SetText(("%s " .. GetColor("MUTED") .. "(%d)|r"):format(entry.header, entry.count))
			header:Show()
		else
			local item = entry.item
			rowIndex = rowIndex + 1
			local row = GetRow(rowIndex)
			row:SetPoint("TOPLEFT", 0, y)
			row:Show()
			row._link = item.link
			row._item = item
			-- Only above one: gear does not stack, so "x1" would say nothing on every gear row.
			local itemLabel = item.link
			if (item.count or 1) > 1 then
				itemLabel = ("%s " .. GetColor("MUTED") .. "x%d|r"):format(item.link, item.count)
			end
			row.itemText:SetText(itemLabel)

			if item.recipient then
				local who = item.recipient
				row.recipButton.text:SetText(
					("%s " .. GetColor("MUTED") .. "(%d)|r"):format(ns.ColorName(who.name, who.class), who.level)
				)
			else
				-- Gold reads as "still working on it", muted as "nothing to do here".
				local label
				if item.state == ns.Matcher.UNREADABLE then
					label = GetColor("TITLE") .. L["ROW_UNREADABLE"] .. "|r"
				elseif item.state == ns.Matcher.GIFT then
					label = GetColor("TITLE") .. L["ROW_NO_RECIPIENT"] .. "|r"
				else
					label = GetColor("MUTED") .. L["WINDOW_KEPT"] .. "|r"
				end
				row.recipButton.text:SetText(label)
			end
			--[[
				The row's own tick, live wherever it decides something: on a bare row, whether to
				search. A row Distribute can never mail draws it empty and dimmed, for display only:
				item.send is left alone, so a hand pick brings the live tick straight back.
			]]
			if UI:CanTick(item) then
				row.check:SetChecked(item.send and true or false)
				row.check:Enable()
				row.check:SetAlpha(1)
			else
				row.check:SetChecked(false)
				row.check:Disable()
				row.check:SetAlpha(0.45)
			end
		end
	end

	window.content:SetSize(window.rowWidth or 460, math.max(1, #list * ROW_HEIGHT))
	window.emptyText:SetShown(#list == 0)
	window.emptyHint:SetShown(#list == 0)
	self:SyncDistributeButton()
end

--[[
	Dead unless pressing it would send something: a mailbox open, because Mail-Sender cannot attach
	without Blizzard's Send Mail panel, and a row ticked with somebody on it. The mailbox is the
	one named on the button, being the condition the player fixes by walking.

	Reads ns.AtMailbox, never ns.mailboxOpen: MAIL_CLOSED does not fire on every way out, and a
	stale flag here is exactly the live button on a closed mailbox this guards against.
]]
function UI:SyncDistributeButton()
	if not (self.frame and self.frame.distributeButton) then
		return
	end
	-- Every change the button follows changes the status line too.
	self:SyncStatus()
	local button = self.frame.distributeButton

	if not ns.AtMailbox() then
		button:SetText(L["BUTTON_NEEDS_MAILBOX"])
		button:Disable()
		return
	end

	-- Back to Distribute at every pause, which is when the chat lines tell the player to press it.
	if ns.Distributor:IsRunning() then
		button:SetText(L["BUTTON_SENDING"])
		button:Disable()
		return
	end

	button:SetText(L["BUTTON_DISTRIBUTE"])
	local ready = false
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			ready = true
			break
		end
	end
	if ready then
		button:Enable()
	else
		button:Disable()
	end
end

-- False for an unreadable or leftover row nobody holds: a search never fills one, so its tick can send nothing.
function UI:CanTick(item)
	if item.recipient then
		return true
	end
	return item.state ~= ns.Matcher.UNREADABLE and item.state ~= ns.Matcher.LEFTOVER
end

-- A shortlist, never the whole field: past three names the line stops saying who it is for.
local BEST_FIT_MAX = 3

--[[
	The classes the verdict ranks highest for this item, best first, so a match shows its
	reasoning. Read from the contenders, never the eligible list: every class can wear cloth, but
	healing pants are a priest's. Gear ranks by fit and then by how close the class is to the
	armor type. A consumable has no ranking, so one that suits more than three classes equally
	shows no line rather than three picked at random. Class names come from the client.
]]
function UI:BestFitLine(item)
	local verdict = item.verdict
	local contenders = verdict and verdict.contenders or {}
	if #contenders == 0 then
		return nil
	end
	local ranked = {}
	for index, class in ipairs(contenders) do
		ranked[index] = class
	end
	if item.kind == "consumable" then
		if #ranked > BEST_FIT_MAX then
			return nil
		end
	else
		local order = {}
		for index, class in ipairs(contenders) do
			order[class] = index
		end
		local fits = verdict.fits or {}
		table.sort(ranked, function(a, b)
			if (a == verdict.best) ~= (b == verdict.best) then
				return a == verdict.best
			end
			if (fits[a] or 0) ~= (fits[b] or 0) then
				return (fits[a] or 0) > (fits[b] or 0)
			end
			local tierA, tierB = ns.Matcher:Priority(item, a), ns.Matcher:Priority(item, b)
			if tierA ~= tierB then
				return tierA < tierB
			end
			return order[a] < order[b]
		end)
	end
	local names = {}
	local body = GetColor("BODY")
	for index = 1, math.min(BEST_FIT_MAX, #ranked) do
		local class = ranked[index]
		local name = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
		names[#names + 1] = ns.ColorName(name, class) .. body
	end
	return L["TOOLTIP_RECIPIENT_BEST_FIT"]:format(table.concat(names, ", "))
end

--[[
	The status line's words, off the frame so Tests/Status-Line.lua can read them. The first case
	that holds wins: a run going out, then rows still waiting on a search, then rows ready to send.
	Unticked rows count for nothing: the player is keeping them.
]]
function UI:StatusLine()
	local mailer = ns.Distributor
	if mailer:IsRunning() then
		return L["STATUS_SENDING"]:format((mailer._done or 0) + 1, mailer._total or 0)
	end
	local waiting, ready = 0, 0
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			ready = ready + 1
		elseif item.send and item.state == ns.Matcher.GIFT then
			waiting = waiting + 1
		end
	end
	if waiting > 0 then
		if not self:HasSearched() then
			return L["STATUS_START"]:format(waiting)
		end
		local remaining = ns.Who:Remaining()
		if remaining > 0 then
			return L["STATUS_MORE"]:format(remaining)
		end
		return L["STATUS_DONE"]:format(waiting)
	end
	if ready > 0 then
		return (ns.AtMailbox() and L["STATUS_READY"] or L["STATUS_AWAY"]):format(ready)
	end
	return ""
end

function UI:SyncStatus()
	if self.frame and self.frame.statusText then
		self.frame.statusText:SetText(self:StatusLine())
	end
end

--------------------------------------------------------------------------------
-- Reading the match list
--------------------------------------------------------------------------------

-- The names Diagnostics/Manifests.lua and Tests/ call. The state is Features/Match-List.lua's.
function UI:Items()
	return MatchList:Items()
end

function UI:Pools()
	return MatchList:Pools()
end

function UI:Candidates(item)
	return MatchList:Candidates(item)
end
