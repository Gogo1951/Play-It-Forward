local ADDON_NAME, ns = ...
local L = ns.L

local GetColor = ns.GetColor

ns.UI = {}
local UI = ns.UI

local MatchList = ns.MatchList
local Kit = ns.MenuKit

-- Before Kit.WindowTitle, which draws the Short Name.
Kit.SetText({
	shortName = L["ADDON_SHORT_NAME"],
	loading = L["LOADING_ITEM"],
})

--[[
	On the Spacing Scale, except the 20-point item icon and row (the maintainer's numbers) and the
	title strip, fitted to the frame template's art.
]]
local EDGE = 16
local ROW_HEIGHT = 20
local ROW_GAP = 8
local GROUP_GAP = 16
-- Features/UI-Top-Bar.lua captures it at load.
local TICK_SIZE = 16
UI.TICK_SIZE = TICK_SIZE
local ICON_SIZE = 20
local ICON_GAP = 8
local NAME_GAP = 4
local FIELD_GAP = 16
local HEADING_GAP = 8
local FIELD_HEIGHT = 20
UI.FIELD_HEIGHT = FIELD_HEIGHT
local FIELD_PAD = 4
-- The menus' own highlight strength.
local HOVER_ALPHA = 0.16
-- Puts the hover glow 8 clear of the text, as a menu row's is.
local FIELD_GLOW = 4
local LIST_GAP = 16
local BUTTON_HEIGHT = 32
local BUTTON_STACK_GAP = 8
local BUTTONS_TOP = EDGE + 2 * BUTTON_HEIGHT + BUTTON_STACK_GAP
-- Sets the status's first line level with Find Recipients' label.
local STATUS_INSET = 8
local LIST_BOTTOM = BUTTONS_TOP + EDGE
-- The scrollbar and the wheel's step match Menu-Kit's menus.
local SCROLL_GUTTER = 8
local THUMB_WIDTH = 2
local THUMB_ALPHA = 0.6
local SCROLL_ROWS = 3
local FRAME_WIDTH = 720
local FRAME_HEIGHT = 512
-- No minimum width: FRAME_WIDTH is the narrowest, since the top bar is laid out for it.
local MIN_HEIGHT = 320
local MAX_WIDTH = 1200
local MAX_HEIGHT = 1008
local ROW_INSET = 2 * EDGE + SCROLL_GUTTER
--[[
	The item column takes all spare width: a random suffix ("of the Monkey") ends the name and says
	who the item is for. 208 fits a cross-realm name with its level.
]]
local RECIPIENT_WIDTH = 208
-- A floor: BuildFrame widens both buttons to the widest label.
local BUTTON_WIDTH = 160
local BUTTON_PAD = 32
local BUTTON_GAP = 16
local GRIP_SIZE = 16
local TITLE_BAR_HEIGHT = 24
local TITLE_BAR_RIGHT = 32

-- Bags Buffs & Buttons' portrait frame. Gift.tga keeps the gift centered, for this ring and the mailbox tab alike.
local FRAME_TEMPLATE = ns.PickTemplate("PortraitFrameTemplate", "BasicFrameTemplate", "BackdropTemplate")
local PORTRAIT_ICON = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Includes\\Images\\Gift"
local SENT_MARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- One type size: the title's. Kinds differ by color only (Style Guide → WINDOWS).
local FONT = "GameFontHighlight"
local FONT_HEADING = "GameFontNormal"

local rows = {}
local headers = {}

-- Unpacked once: ns.GetColorRGB mid-argument-list would keep only its first value.
local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")
local TITLE_R, TITLE_G, TITLE_B = ns.GetColorRGB("TITLE")
local THUMB_R, THUMB_G, THUMB_B = ns.GetColorRGB("SEPARATOR")

local SENT_RANK = 6

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

-- The one value field, top bar and rows alike. Text anchored on both sides, or a long value runs under the arrow.
function UI.BuildDropdown(parent, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, FIELD_HEIGHT)

	button.arrow = button:CreateFontString(nil, "OVERLAY", FONT)
	button.arrow:SetPoint("RIGHT", -FIELD_PAD, 0)
	button.arrow:SetText(Kit.SUBMENU_ARROW)

	button.text = button:CreateFontString(nil, "OVERLAY", FONT)
	button.text:SetPoint("LEFT", FIELD_PAD, 0)
	button.text:SetPoint("RIGHT", button.arrow, "LEFT", -FIELD_PAD, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetWordWrap(false)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetPoint("TOPLEFT", -FIELD_GLOW, FIELD_GLOW)
	highlight:SetPoint("BOTTOMRIGHT", FIELD_GLOW, -FIELD_GLOW)
	highlight:SetColorTexture(TITLE_R, TITLE_G, TITLE_B, HOVER_ALPHA)

	return button
end

-- Same placement as UI:Open (Features/UI-Mailbox.lua). The tab's file loads later, hence the guards.
local function PlaceAtFirst(window)
	window:ClearAllPoints()
	local host = (UI.MailboxTabHost and UI:MailboxTabHost()) or MailFrame
	if host then
		window:SetPoint("TOPLEFT", host, "TOPRIGHT", (UI.MAILBOX_TAB_SIZE or 0) + 8, 0)
	else
		window:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
	end
end

function UI:BuildFrame()
	if UI.frame then
		return UI.frame
	end

	-- A stock template, so ElvUI restyles it.
	local window = CreateFrame("Frame", "PlayItForwardMailFrame", UIParent, FRAME_TEMPLATE)
	-- Clamped: a saved size can predate the current limits.
	local size = ns.db.profile.windowSize
	local width = math.min(MAX_WIDTH, math.max(FRAME_WIDTH, size.width or FRAME_WIDTH))
	local height = math.min(MAX_HEIGHT, math.max(MIN_HEIGHT, size.height or FRAME_HEIGHT))
	window:SetSize(width, height)

	-- Clamped, or a mailbox right of center pushes it off-screen. Moved by the title bar only.
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:EnableMouse(true)

	-- Rows have fixed widths, so UI:Relayout resizes them; everything else follows its anchors.
	window:SetResizable(true)
	if window.SetResizeBounds then
		window:SetResizeBounds(FRAME_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
	end
	window:SetScript("OnSizeChanged", function()
		UI:Relayout()
	end)

	-- AceDB materializes windowPos per profile, so .point is what says the window was ever moved or resized.
	local pos = ns.db.profile.windowPos
	if pos.point then
		window:SetPoint(pos.point, UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
	elseif MailFrame then
		window:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", (UI.MAILBOX_TAB_SIZE or 0) + 8, 0)
	else
		window:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
	end
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

	local titleText = Kit.WindowTitle(L["WINDOW_TITLE"])
	if window.SetTitle then
		window:SetTitle(titleText)
	elseif window.TitleText then
		window.TitleText:SetText(titleText)
	else
		local title = window:CreateFontString(nil, "OVERLAY", FONT)
		title:SetPoint("TOP", 0, -10)
		title:SetText(titleText)
	end
	if window.SetPortraitToAsset then
		window:SetPortraitToAsset(PORTRAIT_ICON)
	end

	local close = window.CloseButton
	if not close then
		close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
	end
	close:SetScript("OnClick", function()
		UI:Close()
	end)

	local titleBar = CreateFrame("Frame", nil, window)
	titleBar:SetPoint("TOPLEFT", 0, 0)
	titleBar:SetPoint("TOPRIGHT", -TITLE_BAR_RIGHT, 0)
	titleBar:SetHeight(TITLE_BAR_HEIGHT)
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function()
		window:StartMoving()
	end)
	titleBar:SetScript("OnDragStop", function()
		window:StopMovingOrSizing()
		UI:SaveGeometry()
	end)
	window.titleBar = titleBar

	UI:BuildTopBar(window)

	-- The view reaches FIELD_GLOW into the gutter so a recipient field's glow isn't clipped.
	local scroll = CreateFrame("ScrollFrame", "PlayItForwardScroll", window)
	scroll:SetPoint("TOPLEFT", EDGE, -(UI.TOP_BAR_BOTTOM + LIST_GAP))
	scroll:SetPoint("BOTTOMRIGHT", -(EDGE + SCROLL_GUTTER - FIELD_GLOW), LIST_BOTTOM)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(_, delta)
		UI:ScrollList(-delta * SCROLL_ROWS * (ROW_HEIGHT + ROW_GAP))
	end)
	scroll:SetScript("OnSizeChanged", function()
		UI:ScrollList(0)
	end)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	window.scroll = scroll
	window.content = content
	window.rowWidth = width - ROW_INSET
	window.contentHeight = 0
	window.scrollOffset = 0

	local thumb = window:CreateTexture(nil, "ARTWORK")
	thumb:SetWidth(THUMB_WIDTH)
	thumb:SetColorTexture(THUMB_R, THUMB_G, THUMB_B, THUMB_ALPHA)
	thumb:Hide()
	window.scrollThumb = thumb

	local emptyText = window:CreateFontString(nil, "OVERLAY", FONT)
	emptyText:SetPoint("CENTER", scroll, "CENTER", 0, 8)
	emptyText:SetText(L["WINDOW_EMPTY"])
	emptyText:SetTextColor(ns.GetColorRGB("TEXT"))
	emptyText:Hide()
	window.emptyText = emptyText

	local emptyHint = window:CreateFontString(nil, "OVERLAY", FONT)
	emptyHint:SetPoint("TOP", emptyText, "BOTTOM", 0, -4)
	emptyHint:SetText(L["WINDOW_EMPTY_HINT"])
	emptyHint:SetTextColor(ns.GetColorRGB("HELP"))
	emptyHint:Hide()
	window.emptyHint = emptyHint

	local find = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	find:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	find:SetPoint("BOTTOMRIGHT", -EDGE, EDGE + BUTTON_HEIGHT + BUTTON_STACK_GAP)
	find:SetText(L["BUTTON_FIND_RECIPIENTS"])
	find:SetScript("OnClick", function()
		UI:FindRecipients()
	end)
	ns.SkinWidget("Button", find)
	window.findButton = find

	local dist = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	dist:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	dist:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
	dist:SetText(L["BUTTON_DISTRIBUTE"])
	dist:SetScript("OnClick", function()
		if ns.Distributor:IsRunning() then
			ns.Distributor:RequestStop()
			UI:SyncDistributeButton()
			return
		end
		UI:Distribute()
	end)
	ns.SkinWidget("Button", dist)
	window.distributeButton = dist

	-- Anchored to Distribute so it follows the buttons' width; wraps rather than clips.
	local status = window:CreateFontString(nil, "OVERLAY", FONT)
	status:SetPoint("TOPLEFT", window, "BOTTOMLEFT", EDGE, BUTTONS_TOP - STATUS_INSET)
	status:SetPoint("BOTTOMRIGHT", dist, "BOTTOMLEFT", -BUTTON_GAP, 0)
	status:SetJustifyH("LEFT")
	status:SetJustifyV("TOP")
	status:SetWordWrap(true)
	status:SetTextColor(ns.GetColorRGB("MUTED"))
	window.statusText = status

	local grip = CreateFrame("Button", nil, window)
	grip:SetSize(GRIP_SIZE, GRIP_SIZE)
	grip:SetPoint("BOTTOMRIGHT", 0, 0)
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
		A loose ruler: an anchored font string reports the width it was given. One width for both,
		or they resize underfoot as labels change; capped at half the room so the status keeps the rest.
	]]
	local ruler = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ruler:Hide()
	local widest = BUTTON_WIDTH
	for _, text in ipairs({
		L["BUTTON_FIND_RECIPIENTS"],
		L["BUTTON_SEARCHING"],
		L["BUTTON_DISTRIBUTE"],
		L["BUTTON_NEEDS_MAILBOX"],
		L["BUTTON_STOP"],
	}) do
		ruler:SetText(text)
		widest = math.max(widest, ruler:GetStringWidth() + BUTTON_PAD)
	end
	widest = math.min(math.floor((FRAME_WIDTH - 2 * EDGE - BUTTON_GAP) / 2), widest)
	find:SetSize(widest, BUTTON_HEIGHT)
	dist:SetSize(widest, BUTTON_HEIGHT)

	--[[
		Closing work lives on OnHide: Escape (UISpecialFrames) only calls Hide. Set after the
		window:Hide() above, which would otherwise fire it before UI.frame exists. Still IsShown means
		UIParent hid (Alt+Z), not a close. Sent clears on open too, for a send that landed after a close.
	]]
	tinsert(UISpecialFrames, "PlayItForwardMailFrame")
	window:SetScript("OnHide", function()
		if window:IsShown() then
			return
		end
		UI:OnClosed()
		ns.Distributor:ClearSent()
	end)
	window:SetScript("OnShow", function()
		ns.Distributor:ClearSent()
	end)

	UI.frame = window
	UI:SyncControls()
	return window
end

-- Position saved with every size: sizing from the corner can move the frame's anchor point.
function UI:SaveGeometry()
	local window = self.frame
	if not window then
		return
	end
	local point, _, relativePoint, x, y = window:GetPoint()
	ns.db.profile.windowPos = { point = point, relativePoint = relativePoint, x = x, y = y }
	ns.db.profile.windowSize = { width = window:GetWidth(), height = window:GetHeight() }
end

-- No .point and no size, so the next build places and sizes it as the first did.
function UI:ResetWindowPosition()
	ns.db.profile.windowPos = {}
	ns.db.profile.windowSize = {}
	local window = self.frame
	if not window then
		return
	end
	window:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	PlaceAtFirst(window)
	self:Relayout()
end

function UI:Relayout()
	local window = self.frame
	if not (window and window.content) then
		return
	end
	local rowWidth = math.max(FRAME_WIDTH, window:GetWidth() or FRAME_WIDTH) - ROW_INSET
	window.rowWidth = rowWidth
	for _, row in ipairs(rows) do
		row:SetWidth(rowWidth)
	end
	for _, header in ipairs(headers) do
		header:SetWidth(rowWidth)
	end
	window.content:SetWidth(rowWidth)
	self:ScrollList(0)
end

-- The offset is kept here, not read back from the scroll frame, so a list that shrank is pulled back into range.
function UI:ScrollList(delta)
	local window = self.frame
	if not (window and window.scroll) then
		return
	end
	local view = window.scroll:GetHeight() or 0
	local content = window.contentHeight or 0
	local range = math.max(0, content - view)
	local offset = math.max(0, math.min(range, (window.scrollOffset or 0) + (delta or 0)))
	window.scrollOffset = offset
	window.scroll:SetVerticalScroll(offset)

	local thumb = window.scrollThumb
	if range <= 0 or view <= 0 then
		thumb:Hide()
		return
	end
	local height = math.max(ROW_HEIGHT, view * view / content)
	local top = (view - height) * offset / range
	thumb:ClearAllPoints()
	thumb:SetPoint("TOPRIGHT", window.scroll, "TOPRIGHT", (SCROLL_GUTTER + THUMB_WIDTH) / 2 - FIELD_GLOW, -top)
	thumb:SetHeight(height)
	thumb:Show()
end

--------------------------------------------------------------------------------
-- Row rendering
--------------------------------------------------------------------------------

local function ItemIcon(link)
	if not (link and ns.GetInfoInstant) then
		return UNKNOWN_ICON
	end
	local ok, _, _, _, _, icon = pcall(ns.GetInfoInstant, link)
	return (ok and icon) or UNKNOWN_ICON
end

local function CountSuffix(count)
	if (count or 1) > 1 then
		return (" " .. GetColor("MUTED") .. "x%d|r"):format(count)
	end
	return ""
end

local function GetHeader(i)
	if headers[i] then
		return headers[i]
	end
	local header = CreateFrame("Frame", nil, UI.frame.content)
	header:SetSize(UI.frame.rowWidth or FRAME_WIDTH - ROW_INSET, ROW_HEIGHT)

	header.check = CreateFrame("CheckButton", nil, header, "UICheckButtonTemplate")
	header.check:SetPoint("LEFT", 0, 0)
	header.check:SetSize(TICK_SIZE, TICK_SIZE)
	header.check:SetScript("OnClick", function(self)
		UI:ToggleSection(header.rank, self:GetChecked() and true or false)
	end)
	ns.SkinWidget("CheckBox", header.check)

	header.text = header:CreateFontString(nil, "OVERLAY", FONT_HEADING)
	header.text:SetTextColor(TITLE_R, TITLE_G, TITLE_B)

	headers[i] = header
	return header
end

local function GetRow(i)
	if rows[i] then
		return rows[i]
	end
	local content = UI.frame.content
	local row = CreateFrame("Frame", nil, content)
	row:SetSize(UI.frame.rowWidth or FRAME_WIDTH - ROW_INSET, ROW_HEIGHT)

	row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	row.check:SetPoint("LEFT", 0, 0)
	row.check:SetSize(TICK_SIZE, TICK_SIZE)
	row.check:SetScript("OnClick", function(self)
		UI:ToggleRow(row._item, self:GetChecked() and true or false)
	end)
	-- Keeps its tooltip while disabled: a dimmed tick says why nothing can go yet.
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

	row.sentMark = row:CreateTexture(nil, "OVERLAY")
	row.sentMark:SetSize(TICK_SIZE, TICK_SIZE)
	row.sentMark:SetPoint("LEFT", 0, 0)
	row.sentMark:SetTexture(SENT_MARK)
	row.sentMark:Hide()

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", TICK_SIZE + ICON_GAP, 0)

	local button = UI.BuildDropdown(row, RECIPIENT_WIDTH)
	button:SetPoint("RIGHT", 0, 0)
	button:SetScript("OnClick", function(self)
		UI:OpenPicker(self:GetParent())
	end)
	-- No hover tooltip on purpose: the list it opens leads with the same reasoning.
	row.recipButton = button

	row.sentTo = row:CreateFontString(nil, "OVERLAY", FONT)
	row.sentTo:SetPoint("LEFT", button, "LEFT", FIELD_PAD, 0)
	row.sentTo:SetPoint("RIGHT", button, "RIGHT", -FIELD_PAD, 0)
	row.sentTo:SetJustifyH("LEFT")
	row.sentTo:SetWordWrap(false)
	row.sentTo:Hide()

	-- Rows sit a fixed pitch apart: a wrapped name would draw over the row below, not push it down.
	row.itemText = row:CreateFontString(nil, "OVERLAY", FONT)
	row.itemText:SetPoint("LEFT", row.icon, "RIGHT", NAME_GAP, 0)
	row.itemText:SetPoint("RIGHT", button, "LEFT", -FIELD_GAP, 0)
	row.itemText:SetJustifyH("LEFT")
	row.itemText:SetWordWrap(false)

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
	Actionable rows first: the list outruns the window. Disenchant is its own section because the
	enchanter is often also an alt, and the same name would sit twice under Matched.
]]
local function DisplayRank(item)
	if item.recipient then
		return item.recipient.disenchant and 2 or 1
	end
	if item.state == ns.Matcher.GIFT then
		return 3
	end
	if item.state == ns.Matcher.UNREADABLE then
		return 4
	end
	return 5
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
		return a.index < b.index -- table.sort is not stable
	end)
	return order
end

local SECTION = {
	[1] = L["SECTION_MATCHED"],
	[2] = ns.DisenchantName(),
	[3] = L["SECTION_NO_RECIPIENT"],
	[4] = L["SECTION_UNREADABLE"],
	-- Shared with the row label on purpose (Locales/enUS.lua).
	[5] = L["WINDOW_KEPT"],
	[SENT_RANK] = L["SECTION_SENT"],
}

function UI:SectionItems(rank)
	local out = {}
	for _, entry in ipairs(DisplayOrder()) do
		if DisplayRank(entry.item) == rank then
			out[#out + 1] = entry.item
		end
	end
	return out
end

function UI:SectionTick(rank)
	local tickable, ticked = 0, 0
	for _, item in ipairs(self:SectionItems(rank)) do
		if self:CanTick(item) then
			tickable = tickable + 1
			if item.send then
				ticked = ticked + 1
			end
		end
	end
	return tickable, tickable > 0 and ticked == tickable
end

--[[
	UI:ToggleRow's rules, row by row. Rows already as asked are skipped, so a tick a row already had
	does not pin the allocator's pairing.
]]
function UI:ToggleSection(rank, checked)
	checked = checked and true or false
	local reassign = false
	for _, item in ipairs(self:SectionItems(rank)) do
		if self:CanTick(item) and (item.send and true or false) ~= checked then
			item.send = checked
			if not checked or item.recipient then
				item.pinned = true
			else
				item.pinned = false
				reassign = true
			end
		end
	end
	if reassign then
		self:Assign()
	else
		self:Refresh()
	end
end

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
			local header = (rank == 2) and (UI.DISENCHANT_ICON .. " " .. SECTION[rank]) or SECTION[rank]
			out[#out + 1] = { header = header, count = counts[rank], rank = rank }
			lastRank = rank
		end
		out[#out + 1] = { item = entry.item }
	end

	local sent = ns.Distributor:Sent()
	if #sent > 0 then
		out[#out + 1] = { header = SECTION[SENT_RANK], count = #sent, rank = SENT_RANK }
		for _, job in ipairs(sent) do
			out[#out + 1] = { sent = job }
		end
	end
	return out
end

local function ShowHeader(header, entry)
	header.rank = entry.rank
	header.text:ClearAllPoints()
	if entry.rank == SENT_RANK then
		header.check:Hide()
		header.text:SetPoint("LEFT", 0, 0)
	else
		header.check:Show()
		header.text:SetPoint("LEFT", TICK_SIZE + HEADING_GAP, 0)
		local tickable, all = UI:SectionTick(entry.rank)
		header.check:SetChecked(all)
		if tickable > 0 then
			header.check:Enable()
			header.check:SetAlpha(1)
		else
			header.check:Disable()
			header.check:SetAlpha(0.45)
		end
	end
	header.text:SetText(("%s " .. GetColor("MUTED") .. "(%d)|r"):format(entry.header, entry.count))
	header:Show()
end

local function ShowItemRow(row, item)
	row._link = item.link
	row._item = item
	row.check:Show()
	row.sentMark:Hide()
	row.recipButton:Show()
	row.sentTo:Hide()
	row.icon:SetTexture(ItemIcon(item.link))
	row.icon:SetDesaturated(false)
	row.itemText:SetText(item.link .. CountSuffix(item.count))

	if item.recipient then
		row.recipButton.text:SetText(UI:RecipientLabel(item.recipient))
	else
		local label
		if item.state == ns.Matcher.UNREADABLE then
			label = L["ROW_UNREADABLE"]
		elseif item.state == ns.Matcher.GIFT then
			label = L["ROW_NO_RECIPIENT"]
		else
			label = L["WINDOW_KEPT"]
		end
		row.recipButton.text:SetText(GetColor("MUTED") .. label .. "|r")
	end
	-- The dimmed tick is display only: item.send is left alone, so a hand pick brings the live tick back.
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

local function ShowSentRow(row, job)
	row._link = job.link
	row._item = nil
	row.check:Hide()
	row.sentMark:Show()
	row.recipButton:Hide()
	row.sentTo:Show()
	row.icon:SetTexture(ItemIcon(job.link))
	row.icon:SetDesaturated(true)
	local name = (job.link and job.link:match("|h(%[.-%])|h")) or job.link or ""
	row.itemText:SetText(GetColor("MUTED") .. name .. "|r" .. CountSuffix(job._count))
	row.sentTo:SetText(("%s%s (%d)|r"):format(GetColor("MUTED"), job.recipient or "", job.level or 0))
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
	local y = 0

	for position, entry in ipairs(list) do
		if entry.header then
			if position > 1 then
				y = y + GROUP_GAP
			end
			headerIndex = headerIndex + 1
			local header = GetHeader(headerIndex)
			header:SetPoint("TOPLEFT", 0, -y)
			ShowHeader(header, entry)
		else
			y = y + ROW_GAP
			rowIndex = rowIndex + 1
			local row = GetRow(rowIndex)
			row:SetPoint("TOPLEFT", 0, -y)
			row:Show()
			if entry.sent then
				ShowSentRow(row, entry.sent)
			else
				ShowItemRow(row, entry.item)
			end
		end
		y = y + ROW_HEIGHT
	end

	-- Room under the last row for its field's glow.
	window.contentHeight = y + FIELD_GLOW
	window.content:SetSize(window.rowWidth or FRAME_WIDTH - ROW_INSET, math.max(1, y))
	self:ScrollList(0)
	window.emptyText:SetShown(#list == 0)
	window.emptyHint:SetShown(#list == 0)
	self:SyncDistributeButton()
end

--------------------------------------------------------------------------------
-- Reading the match list
--------------------------------------------------------------------------------

-- Pass-throughs for Diagnostics/Manifests.lua and Tests/; the state is Features/Match-List.lua's.
function UI:Items()
	return MatchList:Items()
end

function UI:Pools()
	return MatchList:Pools()
end

function UI:Candidates(item)
	return MatchList:Candidates(item)
end
