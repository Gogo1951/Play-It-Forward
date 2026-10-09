local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

ns.UI = {}
local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

local ROW_H = 24
local FRAME_W = 600
local FRAME_H = 470
--[[
	The item column gets the room: a random suffix ("of the Monkey") ends the name and is what says
	who the item is for. The widest recipient label is a cross-realm name with its level,
	"Bubbafrances-Ashkandi (26)" shaped, which fits in 200. The two plus the box and gaps stay
	inside f.rowWidth, clear of the scrollbar.
]]
local ITEM_W = 300
local RECIP_W = 200
-- A floor, not the width: both buttons are sized to the widest label either can show.
local BUTTON_W = 150
local BUTTON_PAD = 24 -- room around the label, matching the picker's ruler allowance
-- Neither button may pass half the space between the margins. A too-long label is clipped instead.
local BUTTON_GAP = 20

local FRAME_TEMPLATE = ns.PickTemplate("BasicFrameTemplate", "BackdropTemplate")
local INSET_TEMPLATE = ns.PickTemplate("InsetFrameTemplate3", "InsetFrameTemplate2", "InsetFrameTemplate")

local rows = {}

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
local function buildDropdown(parent, width)
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

	return button
end

--[[
	A top-bar tick: a checkbox with its caption to the right, the caption clickable too. Its
	tooltip is the options panel's own description for the same setting, so the window and the
	panel never explain one switch two ways. The caller anchors it and sets its OnClick.
]]
local function buildToggle(parent, text, colorKey, tooltipKey)
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
		GameTooltip:AddLine(L[tooltipKey], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	check:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return check
end

--[[
	A tick or dropdown in the window writes the same profile key its twin in the options panel
	does, so an open panel is told to redraw as well as the bags being re-read against it. The
	/who pool already found is kept.
]]
local function afterToggle()
	UI:_syncControls()
	UI:Rescan()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(ns.OPTIONS_REGISTRY.General)
end

function UI:_buildFrame()
	if UI.frame then
		return UI.frame
	end

	-- BasicFrameTemplate brings the chrome and, the point of using it, gets restyled by ElvUI.
	local f = CreateFrame("Frame", "PlayItForwardMailFrame", UIParent, FRAME_TEMPLATE)
	f:SetSize(FRAME_W, FRAME_H)

	-- A mailbox right of center would put a wide window off-screen, so it is clamped and draggable.
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		local point, _, relativePoint, x, y = frame:GetPoint()
		ns.db.profile.windowPos = { point = point, relativePoint = relativePoint, x = x, y = y }
	end)

	-- AceDB materializes windowPos per profile, so .point is what says the window was ever dragged.
	local pos = ns.db.profile.windowPos
	if pos.point then
		f:SetPoint(pos.point, UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
	elseif MailFrame then
		f:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
	end
	-- Only draw our own backdrop if this client lacked BasicFrameTemplate.
	if FRAME_TEMPLATE == "BackdropTemplate" and f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
	end
	f:Hide()

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	if f.TitleBg then
		title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
	else
		title:SetPoint("TOP", 0, -10)
	end
	title:SetText(L["ADDON_TITLE"])
	-- Gold, as every title the add-on draws is: the template's own font string is white.
	title:SetTextColor(ns.GetColorRGB("TITLE"))

	-- BasicFrameTemplate supplies CloseButton, so only build one when it did not.
	local close = f.CloseButton
	if not close then
		close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
	end
	close:SetScript("OnClick", function()
		UI:Close()
	end)

	--[[
		The giftability controls, the same set the options panel carries and drawing the same
		locale strings. Consumables leads on the left with its level rule beside it and its four
		kind ticks beneath; Gear sits on the right with its rarity cap (README-Notes.md). Each
		dropdown value states what it means ("Rare & Lower", "Outgrown by 20+ Levels"), so the
		window cannot word a setting differently to the panel. A dropdown hides while its tick is
		off, as its select does in the panel.
	]]
	local consumables =
		buildToggle(f, L["WINDOW_CONSUMABLES_LABEL"], "TITLE", "OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION")
	consumables:SetPoint("TOPLEFT", 12, -28)
	consumables:SetScript("OnClick", function(check)
		ns.db.profile.includeConsumables = check:GetChecked() and true or false
		afterToggle()
	end)
	f.consumablesToggle = consumables

	local gap = buildDropdown(f, GAP_WIDTH)
	gap:SetPoint("LEFT", consumables.label, "RIGHT", 6, 0)
	gap:SetScript("OnClick", function(button)
		UI:_openGapPicker(button)
	end)
	f.gapButton = gap

	-- Vertically centered on the ticks' line: a tick is 20 tall from -28, so its middle is -38.
	local rarity = buildDropdown(f, RARITY_WIDTH)
	rarity:SetPoint("RIGHT", f, "TOPRIGHT", -12, -38)
	rarity:SetScript("OnClick", function(button)
		UI:_openRarityPicker(button)
	end)
	f.rarityButton = rarity

	-- Right to left from the dropdown: caption, then its box.
	local gear = buildToggle(f, L["WINDOW_GEAR_LABEL"], "TITLE", "OPTIONS_INCLUDE_GEAR_DESCRIPTION")
	gear.label:ClearAllPoints()
	gear.label:SetPoint("RIGHT", rarity, "LEFT", -6, 0)
	gear:SetPoint("RIGHT", gear.label, "LEFT", -2, 0)
	gear:SetScript("OnClick", function(check)
		ns.db.profile.includeGear = check:GetChecked() and true or false
		afterToggle()
	end)
	f.gearToggle = gear

	f.kindToggles = {}
	local previous
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		local strings = ns.CONSUMABLE_KIND_STRINGS[kind]
		local toggle = buildToggle(f, L[strings.label], "TEXT", strings.description)
		if previous then
			toggle:SetPoint("LEFT", previous.label, "RIGHT", 10, 0)
		else
			toggle:SetPoint("TOPLEFT", consumables, "BOTTOMLEFT", 0, -2)
		end
		toggle:SetScript("OnClick", function(check)
			ns.db.profile.consumableKinds[kind] = check:GetChecked() and true or false
			afterToggle()
		end)
		f.kindToggles[kind] = toggle
		previous = toggle
	end

	local inset = CreateFrame("Frame", nil, f, INSET_TEMPLATE)
	inset:SetPoint("TOPLEFT", 6, -74)
	inset:SetPoint("BOTTOMRIGHT", -6, 36)

	local scroll = CreateFrame("ScrollFrame", "PlayItForwardScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 6)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	f.content = content
	f.rowWidth = FRAME_W - 12 - 32

	--[[
		An empty list says so, or a window with nothing left reads as broken or still working.
		The hint points at the top bar, the only thing that can list more.
	]]
	local emptyText = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	emptyText:SetPoint("CENTER", inset, "CENTER", 0, 8)
	emptyText:SetText(L["WINDOW_EMPTY"])
	emptyText:SetTextColor(ns.GetColorRGB("TEXT"))
	emptyText:Hide()
	f.emptyText = emptyText

	local emptyHint = inset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	emptyHint:SetPoint("TOP", emptyText, "BOTTOM", 0, -4)
	emptyHint:SetText(L["WINDOW_EMPTY_HINT"])
	emptyHint:SetTextColor(ns.GetColorRGB("HELP"))
	emptyHint:Hide()
	f.emptyHint = emptyHint

	local find = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	find:SetSize(BUTTON_W, 22)
	find:SetPoint("BOTTOMLEFT", 10, 10)
	find:SetText(L["BUTTON_FIND_RECIPIENTS"])
	find:SetScript("OnClick", function()
		UI:FindRecipients()
	end)
	f.findButton = find

	local dist = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	dist:SetSize(BUTTON_W, 22)
	dist:SetPoint("BOTTOMRIGHT", -10, 10)
	dist:SetText(L["BUTTON_DISTRIBUTE"])
	dist:SetScript("OnClick", function()
		UI:Distribute()
	end)
	f.distributeButton = dist

	--[[
		A loose ruler, because a font string with both anchors set reports the width it was given
		rather than the width it wants. Both buttons take the one width: sized to their own current
		labels they would sit mismatched and resize underfoot as the labels change.
	]]
	local ruler = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ruler:Hide()
	local widest = BUTTON_W
	for _, text in ipairs({
		L["BUTTON_FIND_RECIPIENTS"],
		L["BUTTON_SEARCHING"],
		L["BUTTON_DISTRIBUTE"],
		L["BUTTON_NEEDS_MAILBOX"],
	}) do
		ruler:SetText(text)
		widest = math.max(widest, ruler:GetStringWidth() + BUTTON_PAD)
	end
	widest = math.min(math.floor((FRAME_W - 20 - BUTTON_GAP) / 2), widest)
	find:SetSize(widest, 22)
	dist:SetSize(widest, 22)

	--[[
		Escape closes it, the way it closes every other window the game opens -- the one thing
		players reach for before the X and the only close this window did not answer.

		THE CLOSING WORK LIVES ON OnHide, not on the X. UISpecialFrames only calls Hide, so
		anything hung off the button alone would be skipped by Escape and the pairings, the query
		plan and a half-finished mail run would all outlive the window. Registered after the
		f:Hide() above, or building the frame would fire this before UI.frame exists.
	]]
	tinsert(UISpecialFrames, "PlayItForwardMailFrame")
	f:SetScript("OnHide", function()
		UI:_onClosed()
	end)

	UI.frame = f
	UI:_syncControls()
	return f
end

--[[
	The whole top bar at once. The one entry point, so a caller that changes any setting cannot
	refresh half the bar: Features/Core.lua's profile hook, the options panel's own setters and
	the window's ticks all come through here.
]]
function UI:_syncControls()
	self:_syncToggles()
	self:_syncRarityButton()
	self:_syncGapButton()
end

--[[
	The kind ticks are disabled and dimmed, never hidden, while Consumables is off, so the row
	keeps its shape and the player can see what will come back with it.
]]
function UI:_syncToggles()
	local f = self.frame
	if not f or not f.gearToggle then
		return
	end
	local profile = ns.db.profile
	f.gearToggle:SetChecked(profile.includeGear)
	f.rarityButton:SetShown(profile.includeGear)
	f.consumablesToggle:SetChecked(profile.includeConsumables)
	f.gapButton:SetShown(profile.includeConsumables)
	for kind, toggle in pairs(f.kindToggles) do
		toggle:SetChecked(profile.consumableKinds[kind])
		toggle:SetEnabled(profile.includeConsumables)
		toggle.label:SetTextColor(ns.GetColorRGB(profile.includeConsumables and toggle.colorKey or "MUTED"))
	end
end

function UI:_syncRarityButton()
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
function UI:_syncGapButton()
	if not self.frame or not self.frame.gapButton then
		return
	end
	local gap = ns.NearestConsumableGap(ns.db.profile.consumableLevelGap)
	self.frame.gapButton.text:SetText(GetColor("TEXT") .. (ns.CONSUMABLE_GAP_VALUES[gap] or "") .. "|r")
end

--[[
	The option lists are split from opening the pickers so Tests/Options-Values.lua can read them
	without a frame, the same split Tests/Manual-Assignment.lua relies on for the recipient list.
	Both draw the panel's own strings rather than wording anything a second time.
]]
function UI:_rarityPickerOptions()
	local options = {}
	for _, quality in ipairs({ 2, 3, 4 }) do
		options[#options + 1] = {
			text = ("%s%s|r"):format(ns.QualityColor(quality), ns.QualityName(quality)),
			quality = quality,
		}
	end
	return options
end

function UI:_gapPickerOptions()
	local options = {}
	for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
		options[#options + 1] = {
			text = GetColor("TEXT") .. (ns.CONSUMABLE_GAP_VALUES[gap] or "") .. "|r",
			gap = gap,
		}
	end
	return options
end

function UI:_openRarityPicker(anchor)
	Picker:Open(anchor, self:_rarityPickerOptions(), function(opt)
		if not opt.quality then
			return
		end
		ns.db.profile.maxRarity = opt.quality
		afterToggle()
	end)
end

function UI:_openGapPicker(anchor)
	Picker:Open(anchor, self:_gapPickerOptions(), function(opt)
		-- Compared against nil, never truthiness: the All Consumables stop is a zero.
		if opt.gap == nil then
			return
		end
		ns.db.profile.consumableLevelGap = opt.gap
		afterToggle()
	end)
end

--------------------------------------------------------------------------------
-- Row rendering
--------------------------------------------------------------------------------

-- Section bands, styled like Connoisseur's: a subtle gold wash and gold caption.
local headers = {}

local function getHeader(i)
	if headers[i] then
		return headers[i]
	end
	local h = CreateFrame("Frame", nil, UI.frame.content)
	h:SetSize(UI.frame.rowWidth or 460, ROW_H)

	local bg = h:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", 0, -2)
	bg:SetPoint("BOTTOMRIGHT", 0, 2)
	local red, green, blue = ns.GetColorRGB("TITLE")
	bg:SetColorTexture(red, green, blue, 0.10)

	h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	h.text:SetTextColor(ns.GetColorRGB("TITLE"))
	h.text:SetPoint("LEFT", 8, 0)

	headers[i] = h
	return h
end

local function getRow(i)
	if rows[i] then
		return rows[i]
	end
	local content = UI.frame.content
	local row = CreateFrame("Frame", nil, content)
	row:SetSize(UI.frame.rowWidth or 460, ROW_H)

	row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	row.check:SetPoint("LEFT", 0, 0)
	row.check:SetSize(20, 20)
	row.check:SetScript("OnClick", function(self)
		UI:_toggleRow(row._item, self:GetChecked() and true or false)
	end)
	--[[
		Says what the tick does, which a row cannot show: on a bare row it decides whether the
		item is searched for at all. Nothing on unreadable or leftover rows, whose recipient
		tooltip explains them.
	]]
	row.check:SetScript("OnEnter", function(self)
		local item = row._item
		local text
		if item and item.recipient then
			text = L["TOOLTIP_CHECK_SEND"]
		elseif item and item.state == ns.Matcher.GIFT then
			text = L["TOOLTIP_CHECK_WAITING"]
		end
		if not text then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(text, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	row.check:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.itemText:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
	row.itemText:SetWidth(ITEM_W)
	row.itemText:SetJustifyH("LEFT")
	-- Rows sit a fixed ROW_H apart: a wrapped name would draw over the row below, not push it down.
	row.itemText:SetWordWrap(false)

	local button = CreateFrame("Button", nil, row)
	button:SetPoint("LEFT", row.itemText, "RIGHT", 4, 0)
	button:SetSize(RECIP_W, ROW_H - 4)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetPoint("LEFT", 3, 0)
	button.text:SetPoint("RIGHT", -14, 0)
	button.text:SetJustifyH("LEFT")
	-- Ellipsized for the same reason itemText is: a wrapped name draws over the row below.
	button.text:SetWordWrap(false)

	button.arrow = button:CreateTexture(nil, "OVERLAY")
	button.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	button.arrow:SetSize(14, 14)
	button.arrow:SetPoint("RIGHT", 0, 0)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.10)

	button:SetScript("OnClick", function(self)
		UI:_openPicker(self:GetParent())
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
		local reason
		if item.state == ns.Matcher.UNREADABLE then
			reason = L["ITEM_STATS_UNREADABLE"]
		elseif item.state == ns.Matcher.LEFTOVER and #(item.eligible or {}) == 0 then
			reason = L["TOOLTIP_RECIPIENT_KEPT"]
		end
		if reason then
			GameTooltip:AddLine(reason, 1, 1, 1, true)
			GameTooltip:Show()
			return
		end
		GameTooltip:AddLine(
			L["TOOLTIP_RECIPIENT_CANDIDATES"]:format(#UI:_candidates(item), item.bandLo or 0, item.bandHi or 0),
			1,
			1,
			1
		)
		GameTooltip:AddLine(L["TOOLTIP_RECIPIENT_HINT"], 0.6, 0.6, 0.6)
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
local function displayRank(item)
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

local function displayOrder()
	local order = {}
	for index, item in ipairs(MatchList:Items()) do
		order[#order + 1] = { item = item, index = index }
	end
	table.sort(order, function(a, b)
		local ra, rb = displayRank(a.item), displayRank(b.item)
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
local function renderList()
	local order = displayOrder()
	local counts = {}
	for _, entry in ipairs(order) do
		local rank = displayRank(entry.item)
		counts[rank] = (counts[rank] or 0) + 1
	end

	local out, lastRank = {}, nil
	for _, entry in ipairs(order) do
		local rank = displayRank(entry.item)
		if rank ~= lastRank then
			out[#out + 1] = { header = SECTION[rank], count = counts[rank] }
			lastRank = rank
		end
		out[#out + 1] = { item = entry.item }
	end
	return out
end

function UI:Refresh()
	local f = self:_buildFrame()
	for _, row in ipairs(rows) do
		row:Hide()
	end
	for _, h in ipairs(headers) do
		h:Hide()
	end

	local list = renderList()
	local rowIndex, headerIndex = 0, 0

	for position, entry in ipairs(list) do
		local y = -((position - 1) * ROW_H)

		if entry.header then
			headerIndex = headerIndex + 1
			local header = getHeader(headerIndex)
			header:SetPoint("TOPLEFT", 0, y)
			header.text:SetText(("%s " .. GetColor("MUTED") .. "(%d)|r"):format(entry.header, entry.count))
			header:Show()
		else
			local item = entry.item
			rowIndex = rowIndex + 1
			local row = getRow(rowIndex)
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
			-- Always live and always the row's own tick: on a bare row it decides whether to search.
			row.check:SetChecked(item.send and true or false)
			row.check:Enable()
		end
	end

	f.content:SetSize(f.rowWidth or 460, math.max(1, #list * ROW_H))
	f.emptyText:SetShown(#list == 0)
	f.emptyHint:SetShown(#list == 0)
	self:_syncDistributeButton()
end

--[[
	Dead unless pressing it would send something: a mailbox open, because Mail-Sender cannot attach
	without Blizzard's Send Mail panel, and a row ticked with somebody on it. The mailbox is the
	one named on the button, being the condition the player fixes by walking.

	Reads ns.AtMailbox, never ns.mailboxOpen: MAIL_CLOSED does not fire on every way out, and a
	stale flag here is exactly the live button on a closed mailbox this guards against.
]]
function UI:_syncDistributeButton()
	if not (self.frame and self.frame.distributeButton) then
		return
	end
	local button = self.frame.distributeButton

	if not ns.AtMailbox() then
		button:SetText(L["BUTTON_NEEDS_MAILBOX"])
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

function UI:_candidates(item)
	return MatchList:Candidates(item)
end
