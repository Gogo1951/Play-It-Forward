local ADDON_NAME, ns = ...
local L = ns.L

local GetColor = ns.GetColor

ns.UI = {}
local UI = ns.UI

local MatchList = ns.MatchList

--[[
	EVERY SIZE AND GAP HERE IS ON THE SPACING SCALE (2, 4, 8, 16, 32, 64, 128, then multiples of 16),
	except what fits Blizzard's own art: the 22-tall buttons, the 26-wide scrollbar gutter, and
	ROW_INSET and ITEM_SLACK, which are sums of those rather than gaps of their own.
]]
local ROW_HEIGHT = 32
-- A tick in the top bar and on every row. Features/UI-Top-Bar.lua reads it from here.
local TICK_SIZE = 16
UI.TICK_SIZE = TICK_SIZE
-- A dropdown's height, in the top bar and on every row.
local DROPDOWN_HEIGHT = 16
local LIST_GAP = 8
local LIST_BOTTOM = 64
local LIST_RIGHT = 4
local SCROLL_INSET = 8
local SCROLLBAR_GUTTER = 26 -- Blizzard's scrollbar art
local STATUS_SIDE = 16
local STATUS_BOTTOM = 32
local BUTTON_LEFT = 8
local BUTTON_RIGHT = 32 -- clear of the corner grip
local BUTTON_BOTTOM = 8
local FRAME_WIDTH = 656
local FRAME_HEIGHT = 512
--[[
	The corner grip's limits. The default width is also the narrowest, because the top bar is laid
	out for it; the shortest still shows a few rows between the top bar and the buttons.
]]
local MIN_HEIGHT = 320
local MAX_WIDTH = 1200
local MAX_HEIGHT = 1008
-- The row's width less the scrollbar and the frame's border, as the inset leaves it.
local ROW_INSET = 44
--[[
	The item column gets the room, and all of a wider window: a random suffix ("of the Monkey")
	ends the name and is what says who the item is for. The widest recipient label is a cross-realm
	name with its level, "Bubbafrances-Ashkandi (26)" shaped, which fits in 208. The tick and the
	gaps take ITEM_SLACK, so the two columns stay inside window.rowWidth, clear of the scrollbar.
]]
local RECIPIENT_WIDTH = 208
local ITEM_SLACK = 56

local function ItemWidth(rowWidth)
	return rowWidth - RECIPIENT_WIDTH - ITEM_SLACK
end
-- A floor, not the width: both buttons are sized to the widest label either can show.
local BUTTON_WIDTH = 160
local BUTTON_PAD = 32 -- room around the label
-- Neither button may pass half the space between the margins. A too-long label is clipped instead.
local BUTTON_GAP = 16

--[[
	The portrait frame Bags Buffs & Buttons' windows use, the gold gift in its portrait. A client
	without it gets the plain frame and no portrait. The gift sits 4px left and 1px up of Gift.tga's
	center on purpose: the template's ring is centered there, not on the portrait texture.
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

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

--[[
	A dropdown: its current value, an arrow and a hover highlight. The top bar's and every row's
	are built from this, so they cannot drift apart the way hand-rolled copies would. It carries no
	caption: in the top bar the tick beside it names what it governs, as the toggle does in the
	options panel.

	The caller anchors it. The value text is anchored on both sides and ellipsized, or a long one
	runs under the arrow.
]]
function UI.BuildDropdown(parent, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, DROPDOWN_HEIGHT)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetPoint("LEFT", 4, 0)
	button.text:SetPoint("RIGHT", -16, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetWordWrap(false)

	local arrow = button:CreateTexture(nil, "OVERLAY")
	arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	arrow:SetSize(16, 16)
	arrow:SetPoint("RIGHT", 0, 0)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.10)

	ns.SkinWidget("Button", button)
	return button
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
	local titleText = GetColor("TEXT")
		.. L["WINDOW_TITLE"]
		.. "|r "
		.. GetColor("SEPARATOR")
		.. "//"
		.. "|r "
		.. GetColor("INFO")
		.. L["ADDON_TITLE"]
		.. "|r"
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

	-- The giftability controls along the top, Features/UI-Top-Bar.lua's.
	UI:BuildTopBar(window)

	-- The list hangs LIST_GAP under the kind ticks, so it moves with the top bar rather than a number of its own.
	local inset = CreateFrame("Frame", nil, window, INSET_TEMPLATE)
	inset:SetPoint("TOPLEFT", INSET_LEFT, -(UI.TOP_BAR_BOTTOM + LIST_GAP))
	inset:SetPoint("BOTTOMRIGHT", -LIST_RIGHT, LIST_BOTTOM)

	local scroll = CreateFrame("ScrollFrame", "PlayItForwardScroll", window, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", SCROLL_INSET, -SCROLL_INSET)
	scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -SCROLLBAR_GUTTER, SCROLL_INSET)
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
	status:SetPoint("BOTTOMLEFT", STATUS_SIDE, STATUS_BOTTOM)
	status:SetPoint("BOTTOMRIGHT", -STATUS_SIDE, STATUS_BOTTOM)
	status:SetJustifyH("CENTER")
	status:SetWordWrap(false)
	status:SetTextColor(ns.GetColorRGB("HELP"))
	window.statusText = status

	local find = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	find:SetSize(BUTTON_WIDTH, 22)
	find:SetPoint("BOTTOMLEFT", BUTTON_LEFT, BUTTON_BOTTOM)
	find:SetText(L["BUTTON_FIND_RECIPIENTS"])
	find:SetScript("OnClick", function()
		UI:FindRecipients()
	end)
	ns.SkinWidget("Button", find)
	window.findButton = find

	-- Clear of the corner grip, which takes the bottom right corner.
	local dist = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	dist:SetSize(BUTTON_WIDTH, 22)
	dist:SetPoint("BOTTOMRIGHT", -BUTTON_RIGHT, BUTTON_BOTTOM)
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
	widest = math.min(math.floor((FRAME_WIDTH - BUTTON_LEFT - BUTTON_RIGHT - BUTTON_GAP) / 2), widest)
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
	row.check:SetSize(TICK_SIZE, TICK_SIZE)
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

	-- The top bar's dropdown at its own DROPDOWN_HEIGHT: its text is ellipsized, as a wrapped name
	-- draws over the row below.
	local button = UI.BuildDropdown(row, RECIPIENT_WIDTH)
	button:SetHeight(DROPDOWN_HEIGHT)
	button:SetPoint("LEFT", row.itemText, "RIGHT", 4, 0)

	button:SetScript("OnClick", function(self)
		UI:OpenPicker(self:GetParent())
	end)
	--[[
		No hover tooltip: the list it opens leads with the candidate count and best fit, or why
		nobody can be offered the row, beside the names it explains, so a tooltip would say it twice.
	]]
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
	Matched, then disenchant, then still-matchable, then unreadable, then kept: the list outruns
	the window, so rows worth acting on must not fall below the fold. Unreadable outranks kept: it
	wants a look.

	DISENCHANT IS ITS OWN SECTION. Your enchanter is often an alt as well, and a gift to Gogomage
	and dust for Gogomage would otherwise sit side by side under Matched, the same name on both.
	Its rows carry the disenchant icon on their dropdowns too (UI:RecipientLabel).
]]
local function DisplayRank(item)
	if item.recipient then
		return item.recipient.disenchant and 2 or 1
	end
	if item.state == ns.Matcher.GIFT then
		return 3 -- scored, just nobody in range yet
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
		return a.index < b.index -- stable: bag order within a group
	end)
	return order
end

local SECTION = {
	[1] = L["SECTION_MATCHED"],
	[2] = ns.DisenchantName(),
	[3] = L["SECTION_NO_RECIPIENT"],
	[4] = L["SECTION_UNREADABLE"],
	-- One key with the row label below: both surfaces read the same single word. See Locales/enUS.lua.
	[5] = L["WINDOW_KEPT"],
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
			-- The Disenchant band wears the same icon as its rows' dropdowns.
			local header = (rank == 2) and (UI.DISENCHANT_ICON .. " " .. SECTION[rank]) or SECTION[rank]
			out[#out + 1] = { header = header, count = counts[rank] }
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
				row.recipButton.text:SetText(UI:RecipientLabel(item.recipient))
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
