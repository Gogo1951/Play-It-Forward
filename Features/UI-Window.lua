local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

ns.UI = {}
local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

local ROW_H = 24
local FRAME_W = 540
local FRAME_H = 470
local ITEM_W = 250
local RECIP_W = 190
-- A floor, not the width: both buttons are sized to the widest label either can show.
local BUTTON_W = 150
local BUTTON_PAD = 24 -- room around the label, matching the picker's ruler allowance
-- Neither button may pass half the space between the margins. A too-long label is clipped instead.
local BUTTON_GAP = 20

local FRAME_TEMPLATE = ns.PickTemplate("BasicFrameTemplate", "BackdropTemplate")
local INSET_TEMPLATE = ns.PickTemplate("InsetFrameTemplate3", "InsetFrameTemplate2", "InsetFrameTemplate")

local rows = {}

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------
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
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relativePoint, x, y = self:GetPoint()
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

	-- BasicFrameTemplate supplies CloseButton, so only build one when it did not.
	local close = f.CloseButton
	if not close then
		close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
	end
	close:SetScript("OnClick", function()
		UI:Close()
	end)

	-- Rarity cap. Default green, so a blue drop can't be mailed off by accident.
	local rarityLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	rarityLabel:SetPoint("TOPLEFT", 12, -30)
	rarityLabel:SetText(L["WINDOW_RARITY_LABEL"])

	local rarity = CreateFrame("Button", nil, f)
	rarity:SetPoint("LEFT", rarityLabel, "RIGHT", 4, 0)
	rarity:SetSize(110, 18)
	rarity.text = rarity:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	rarity.text:SetPoint("LEFT", 3, 0)
	rarity.text:SetJustifyH("LEFT")
	local rarityArrow = rarity:CreateTexture(nil, "OVERLAY")
	rarityArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	rarityArrow:SetSize(14, 14)
	rarityArrow:SetPoint("RIGHT", 0, 0)
	local rarityHL = rarity:CreateTexture(nil, "HIGHLIGHT")
	rarityHL:SetAllPoints()
	rarityHL:SetColorTexture(1, 1, 1, 0.10)
	rarity:SetScript("OnClick", function(self)
		UI:_openRarityPicker(self)
	end)
	f.rarityButton = rarity

	local inset = CreateFrame("Frame", nil, f, INSET_TEMPLATE)
	inset:SetPoint("TOPLEFT", 6, -52)
	inset:SetPoint("BOTTOMRIGHT", -6, 36)

	local scroll = CreateFrame("ScrollFrame", "PlayItForwardScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 6)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	f.content = content
	f.rowWidth = FRAME_W - 12 - 32

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
		L["BUTTON_SCAN_AGAIN"],
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

	UI.frame = f
	UI:_syncRarityButton()
	return f
end

function UI:_syncRarityButton()
	if not self.frame or not self.frame.rarityButton then
		return
	end
	local cap = ns.db.profile.maxRarity
	self.frame.rarityButton.text:SetText(("%s%s|r"):format(ns.QualityColor(cap), ns.QualityName(cap)))
end

function UI:_openRarityPicker(anchor)
	local options = {}
	for _, quality in ipairs({ 2, 3, 4 }) do
		options[#options + 1] = {
			text = ("%s%s|r"):format(ns.QualityColor(quality), ns.QualityName(quality)),
			quality = quality,
		}
	end
	Picker:Open(anchor, options, function(opt)
		if not opt.quality then
			return
		end
		ns.db.profile.maxRarity = opt.quality
		UI:_syncRarityButton()
		-- Re-read the bags against the new cap, reusing the /who pool we already have.
		UI:Rescan()
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
	local r, g, b = ns.GetColorRGB("TITLE")
	bg:SetColorTexture(r, g, b, 0.10)

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

	row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.itemText:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
	row.itemText:SetWidth(ITEM_W)
	row.itemText:SetJustifyH("LEFT")
	-- Rows sit a fixed ROW_H apart: a wrapped name would draw over the row below, not push it down.
	row.itemText:SetWordWrap(false)

	local btn = CreateFrame("Button", nil, row)
	btn:SetPoint("LEFT", row.itemText, "RIGHT", 4, 0)
	btn:SetSize(RECIP_W, ROW_H - 4)
	btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	btn.text:SetPoint("LEFT", 3, 0)
	btn.text:SetPoint("RIGHT", -14, 0)
	btn.text:SetJustifyH("LEFT")

	btn.arrow = btn:CreateTexture(nil, "OVERLAY")
	btn.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	btn.arrow:SetSize(14, 14)
	btn.arrow:SetPoint("RIGHT", 0, 0)

	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.10)

	btn:SetScript("OnClick", function(self)
		UI:_openPicker(self:GetParent())
	end)
	btn:SetScript("OnEnter", function(self)
		local item = self:GetParent()._item
		if not item then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["TOOLTIP_RECIPIENT"])
		GameTooltip:AddLine(
			L["TOOLTIP_RECIPIENT_CANDIDATES"]:format(#UI:_candidates(item), item.bandLo or 0, item.bandHi or 0),
			1,
			1,
			1
		)
		GameTooltip:AddLine(L["TOOLTIP_RECIPIENT_HINT"], 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row.recipButton = btn

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
	[4] = L["SECTION_KEPT"],
}

local function renderList()
	local out, lastRank = {}, nil
	for _, entry in ipairs(displayOrder()) do
		local rank = displayRank(entry.item)
		if rank ~= lastRank then
			out[#out + 1] = { header = SECTION[rank] }
			lastRank = rank
		end
		out[#out + 1] = { item = entry.item }
	end
	return out
end

function UI:Refresh()
	local f = self:_buildFrame()
	for _, r in ipairs(rows) do
		r:Hide()
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
			header.text:SetText(entry.header)
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
				row.check:SetChecked(item.send and true or false)
			else
				-- Gold reads as "still working on it", muted as "nothing to do here".
				local label
				if item.state == ns.Matcher.UNREADABLE then
					label = GetColor("TITLE") .. L["ROW_UNREADABLE"] .. "|r"
				elseif item.state == ns.Matcher.GIFT then
					label = GetColor("TITLE") .. L["ROW_NO_RECIPIENT"] .. "|r"
				else
					label = GetColor("MUTED") .. L["ROW_KEPT"] .. "|r"
				end
				row.recipButton.text:SetText(label)
				row.check:SetChecked(false)
			end
			-- Always live: on a bare row a tick means "match this again", never a dead control.
			row.check:Enable()
		end
	end

	f.content:SetSize(f.rowWidth or 460, math.max(1, #list * ROW_H))
	self:_syncDistributeButton()
end

--------------------------------------------------------------------------------
-- Candidates + manual assignment
--------------------------------------------------------------------------------
--[[
	Split from opening the picker so Tests/Manual-Assignment.lua can read the options without a
	frame. Nobody is hidden and nobody is gated: the notes beside a name ("has one", "refused",
	"recent") are information for the player's judgment, and every candidate can be picked. The
	list ends with a divider and a targeted search for this one item.
]]
function UI:_pickerOptions(item)
	local options = { {
		text = GetColor("MUTED") .. L["PICKER_KEEP_OPTION"] .. "|r",
		clear = true,
	} }

	local candidates = self:_candidates(item)
	if #candidates == 0 then
		-- An empty list has two causes and only one is fixed by querying again, so say which.
		table.insert(options, {
			text = GetColor("TITLE")
				.. ((item.state == ns.Matcher.UNREADABLE) and L["PICKER_UNREADABLE"] or L["PICKER_NONE_IN_RANGE"])
				.. "|r",
			disabled = true,
		})
	end

	for _, p in ipairs(candidates) do
		local held = MatchList:AssignedTo()[p.name] and MatchList:AssignedTo()[p.name] ~= item
		local refused = not ns.Fairness:IsReachable(p.name)

		local note = ""
		if refused then
			note = L["PICKER_NOTE_REFUSED"]
		elseif held then
			note = L["PICKER_NOTE_HAS_ONE"]
		elseif not ns.Fairness:IsFresh(p.name, p.level) then
			note = L["PICKER_NOTE_RECENT"]
		end
		if note ~= "" then
			note = " " .. GetColor("MUTED") .. note .. "|r"
		end

		-- No class word: the name is already class-colored, and the color says it.
		table.insert(options, {
			text = ("%s " .. GetColor("MUTED") .. "(%d)|r%s"):format(ns.ColorName(p.name, p.class), p.level, note),
			pick = p,
		})
	end

	table.insert(options, { separator = true, disabled = true })
	table.insert(options, {
		text = GetColor("INFO") .. L["PICKER_FIND_FOR_ITEM"] .. "|r",
		findForItem = true,
	})

	return options
end

function UI:_openPicker(row)
	local item = row._item
	if not item then
		return
	end
	Picker:Open(row.recipButton, self:_pickerOptions(item), function(opt)
		UI:_pickerSelect(item, opt)
	end)
end

-- What a picked entry does, off the frame so the tests can drive it.
function UI:_pickerSelect(item, opt)
	if opt.findForItem then
		self:FindRecipientsForItem(item)
		return
	end
	self:_setRecipient(item, opt.pick)
end

function UI:_setRecipient(item, who)
	--[[
		THE PLAYER'S PICK IS NEVER REFUSED (maintainer ruling, 2026-07-23). A name already
		holding another row is taken from it, and the freed row drops back to auto-assignment
		-- unpinned, or it would read as a deliberate keep. A name the server bounced earlier
		is theirs to retry. The picker's notes state these facts; they are not gates.
	]]
	if who then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item then
			other.recipient, other.send, other.pinned = nil, false, false
		end
	end

	if item.recipient then
		MatchList:AssignedTo()[item.recipient.name] = nil
	end

	--[[
		Pinned because a player chose it: _assign rebuilds only what it decided itself. Keep Item
		included, where "nobody" is the choice.
	]]
	item.pinned = true

	if who then
		item.recipient, item.send = who, true
		MatchList:AssignedTo()[who.name] = item
	else
		item.recipient, item.send = nil, false
	end

	self:Refresh()
end

--[[
	Pinned for the same reason: the tick is the last thing between an item and a stranger's
	mailbox, and a rebuild that re-ticks a row somebody unticked has overridden them.
]]
function UI:_setSend(item, send)
	if not item.recipient then
		item.send = false
		return
	end
	item.pinned = true
	item.send = send and true or false
end

--[[
	The checkbox, which is always live. On a row with a recipient it is the send switch; on a
	kept or unmatched row a tick means "match this again" -- the pin comes off and the allocator
	runs, and the box then shows whatever that produced: a contender arrives ticked, a fallback
	as an unticked suggestion, nobody at all snaps the box back off. The Refresh is what keeps
	the box and the Distribute button honest either way.
]]
function UI:_toggleRow(item, checked)
	if not item then
		return
	end
	if item.recipient then
		self:_setSend(item, checked)
		self:Refresh()
		return
	end
	if checked then
		item.pinned = false
		self:_assign()
	end
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

-- The names Features/Diagnostics.lua and Tests/ call. The state is Features/Match-List.lua's.
function UI:Items()
	return MatchList:Items()
end

function UI:Pools()
	return MatchList:Pools()
end

function UI:ClearPools()
	MatchList:ClearPools()
end

function UI:_candidates(item)
	return MatchList:Candidates(item)
end
