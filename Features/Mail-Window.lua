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
local function buildFrame()
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
		local item = row._item
		if not item or not item.recipient then
			self:SetChecked(false)
			return
		end
		UI:_setSend(item, self:GetChecked())
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
	Matched, then still-matchable, then unreadable, then vendor: the list outruns the window, so
	rows worth acting on must not fall below the fold. Unreadable outranks vendor: it wants a look.
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
	[4] = L["SECTION_VENDOR"],
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
	local f = buildFrame()
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
				row.check:Enable()
				row.check:SetChecked(item.send and true or false)
			else
				-- Gold reads as "still working on it", muted as "nothing to do here".
				local label
				if item.state == ns.Matcher.UNREADABLE then
					label = GetColor("TITLE") .. L["ROW_UNREADABLE"] .. "|r"
				elseif item.state == ns.Matcher.GIFT then
					label = GetColor("TITLE") .. L["ROW_NO_RECIPIENT"] .. "|r"
				else
					label = GetColor("MUTED") .. L["ROW_VENDOR"] .. "|r"
				end
				row.recipButton.text:SetText(label)
				row.check:SetChecked(false)
				row.check:Disable()
			end
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
	frame. Nobody is hidden: a name that silently vanishes reads as the add-on having lost them.
]]
function UI:_pickerOptions(item)
	local options = { {
		text = GetColor("MUTED") .. L["PICKER_VENDOR_OPTION"] .. "|r",
		clear = true,
	} }

	local anyGrayed = false
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

		anyGrayed = anyGrayed or held or refused
		table.insert(options, {
			text = ("%s " .. GetColor("MUTED") .. "(%d)|r " .. GetColor("MUTED") .. "%s|r%s"):format(
				ns.ColorName(p.name, p.class),
				p.level,
				ns.ClassName(p.class),
				note
			),
			pick = p,
			disabled = held or refused,
		})
	end

	-- One line for the whole list rather than the same sentence on every grayed row.
	if anyGrayed then
		table.insert(options, {
			text = GetColor("MUTED") .. L["PICKER_HINT_GRAYED"] .. "|r",
			disabled = true,
		})
	end

	return options
end

function UI:_openPicker(row)
	local item = row._item
	if not item then
		return
	end
	Picker:Open(row.recipButton, self:_pickerOptions(item), function(opt)
		UI:_setRecipient(item, opt.pick)
	end)
end

function UI:_setRecipient(item, who)
	--[[
		Checked before anything is written, so a refusal leaves the row as the player found it.
		_pickerOptions grays these out; this is the guard behind it.
	]]
	if who then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item then
			ns:PrintMessage(L["CHAT_ALREADY_HOLDS"]:format(ns.ColorName(who.name, who.class), other.link))
			return
		end
		if not ns.Fairness:IsReachable(who.name) then
			ns:PrintMessage(L["CHAT_CANNOT_RECEIVE"]:format(ns.ColorName(who.name, who.class)))
			return
		end
	end

	if item.recipient then
		MatchList:AssignedTo()[item.recipient.name] = nil
	end

	--[[
		Pinned because a player chose it: _assign rebuilds only what it decided itself. The vendor
		case included, where "nobody" is a choice.
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

--------------------------------------------------------------------------------
-- Recipient Finding
--------------------------------------------------------------------------------

--[[
	Free candidates next to a /who -- no button press, no throttle -- so this runs on its own
	rather than being spent from the search plan. The answer lands on GUILD_ROSTER_UPDATE some
	frames later, which is why it re-assigns rather than returning anything.
]]
local function pullGuild()
	ns.Guild:Request(function(members)
		if #members == 0 then
			return
		end
		if MatchList:AddResults(members) == 0 then
			return
		end
		if UI.frame and UI.frame:IsShown() then
			UI:_assign()
		end
	end)
end

-- SendWho only fires from a real button press, so this is a stepper: one press, one query.
function UI:FindRecipients()
	Picker:Close()

	if ns.Who:Remaining() > 0 then
		return self:_step()
	end

	--[[
		Only on a fresh search, not on every Scan Again: the roster costs no press but does cost a
		walk of every member with a last-online call apiece, and cannot change much in five seconds.
	]]
	pullGuild()

	--[[
		Pools are deliberately not wiped: one query returns at most ~49 people, so pressing again
		adds to the roster. Only Clear History and Roster empties it.
	]]
	local bands = MatchList:RescanBags()
	if #bands == 0 then
		self:Refresh()
		return
	end

	ns.Who:Plan(bands)
	self:_step()
end

function UI:_step()
	local sent = ns.Who:Step(function(results)
		-- nil results: a query that never answered, back on the plan. The button still resyncs.
		if results then
			MatchList:AddResults(results)
			self:_assign()
		end
		self:_syncFindButton()
	end)

	-- Locked the moment the query goes out: the throttle runs from the send, not the answer.
	if sent then
		self:_lockFindButton()
	end
	self:_syncFindButton()
end

--[[
	Held for the full throttle rather than until the answer arrives: a reply often lands in under
	a second, and re-enabling then offers a press the server refuses for another four. Reads
	Who.THROTTLE rather than a five written here, so the lock cannot undercut the rule it reflects.
]]
local searchTimer

function UI:_lockFindButton()
	if not (self.frame and self.frame.findButton) then
		return
	end
	self.frame.findButton:Disable()
	self.frame.findButton:SetText(L["BUTTON_SEARCHING"])

	if searchTimer then
		searchTimer:Cancel()
	end
	searchTimer = C_Timer.NewTimer(ns.Who.THROTTLE, function()
		searchTimer = nil
		if UI.frame and UI.frame.findButton then
			UI.frame.findButton:Enable()
			UI:_syncFindButton()
		end
	end)
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

--[[
	Whether there is somewhere left to look, never how many: the count moves in both directions,
	since an unanswered query goes back on the plan and an assignment prunes bands it finished.

	Silent while the lock is up, or the callback would put a live-looking label on a dead button.
]]
function UI:_syncFindButton()
	if searchTimer then
		return
	end
	self.frame.findButton:SetText((ns.Who:Remaining() > 0) and L["BUTTON_SCAN_AGAIN"] or L["BUTTON_FIND_RECIPIENTS"])
end

-- The allocation is Features/Match-List.lua's; putting it on screen is what belongs here.
function UI:_assign()
	MatchList:Assign()
	self:Refresh()
	self:_syncFindButton()
end

--[[
	A rescan must re-plan: the level bands the plan was built from are exactly what a giftability
	setting changes. Pools are untouched, so nobody already found is lost.

	Plan before assigning. Assign clears the plan once no gift is left unmatched, so this order
	lets it drop a plan that turned out unnecessary; the other leaves it standing and puts Scan
	Again on the button with nothing to scan for.

	Guarded on the frame: a setting can change before the window has ever been built.
]]
function UI:Rescan()
	if not self.frame then
		return
	end
	local bands = MatchList:RescanBags()
	ns.Who:Plan(bands)
	self:_assign()
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

--------------------------------------------------------------------------------
-- Distribute checked rows
--------------------------------------------------------------------------------
function UI:Distribute()
	Picker:Close()
	local jobs = {}
	local body = ns.Distributor:BuildBody()

	--[[
		One mail per person per run, enforced rather than merely intended: _assign already holds to
		it, but two greens in one stranger's mailbox reads as spam and cannot be taken back.
	]]
	local claimed = {}
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			local who = item.recipient.name
			if claimed[who] then
				ns:PrintMessage(L["MAIL_ALREADY_HAS_ONE"]:format(item.link, ns.ColorName(who, item.recipient.class)))
			else
				claimed[who] = true
				table.insert(jobs, {
					bag = item.bag,
					slot = item.slot,
					uid = item.uid,
					link = item.link,
					recipient = who,
					level = item.recipient.level,
					class = item.recipient.class,
					subject = ns.Distributor:BuildSubject(),
					body = body,
				})
			end
		end
	end

	--[[
		Off the list on confirmation, never from a re-read of the bags: MAIL_SUCCESS lands before
		the client empties the slot, so a scan then finds the item still there and re-pairs it.
	]]
	ns.Distributor.onProgress = function(_, _, job, ok)
		if ok then
			UI:_delivered(job)
		else
			UI:_releaseRecipient(job)
		end
	end
	ns.Distributor.onDone = function()
		UI:_afterDelivery()
	end
	ns.Distributor:Start(jobs)
end

--[[
	By the uid it was mailed under: two copies of one green share a name and a link, so matching
	on anything less removes whichever the loop reached first.
]]
function UI:_delivered(job)
	for index, item in ipairs(MatchList:Items()) do
		if MatchList:SlotKey(item) == (job.uid or "") then
			if item.recipient then
				MatchList:AssignedTo()[item.recipient.name] = nil
			end
			table.remove(MatchList:Items(), index)
			break
		end
	end
	self:Refresh()
end

--[[
	ONLY WHEN THE NAME ITSELF IS THE PROBLEM. A plain MAIL_FAILED can be a full mailbox or a bad
	moment on the server, and the pairing may have been set by hand: discarding that choice because
	one send bounced is a second failure. The item stays on the list either way.
]]
function UI:_releaseRecipient(job)
	for _, item in ipairs(MatchList:Items()) do
		if MatchList:SlotKey(item) == (job.uid or "") then
			if item.recipient and not ns.Fairness:IsReachable(item.recipient.name) then
				MatchList:AssignedTo()[item.recipient.name] = nil
				item.recipient, item.send = nil, false
			end
			break
		end
	end
	self:Refresh()
end

--[[
	Deliberately does not re-read the bags: the client is still emptying the slots, so a scan here
	could only put delivered items back. BAG_UPDATE marks the scan stale and the next mailbox picks
	them up. Re-assigning is worth it: every recipient just went on cooldown.
]]
function UI:_afterDelivery()
	if not self.frame then
		return
	end
	self:_assign()
end

--------------------------------------------------------------------------------
-- Auto-open at the mailbox (MAIL_SHOW / MAIL_CLOSED everywhere, interaction manager off Era)
--------------------------------------------------------------------------------
-- It does not scan: every caller had to read the bags to decide whether to call this at all.
local function openWindow()
	buildFrame()
	UI.frame:Show()

	pullGuild()
	UI:Refresh()
end

--[[
	"No window appeared" has two causes wanting opposite responses: off-screen, or nothing to show.
	This drops the saved position, re-centers, and reports what the scan found.
]]
function UI:ForceShow()
	ns.db.profile.windowPos = {}
	MatchList:EnsureScan()
	local f = buildFrame()
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:Show()
	UI:Refresh()

	local giftable = 0
	for _, item in ipairs(MatchList:Items()) do
		if item.state == ns.Matcher.GIFT then
			giftable = giftable + 1
		end
	end

	-- Read at call time, not aliased at file scope: Features/Diagnostics.lua loads after this file.
	local D = ns.DiagnosticsStrings
	ns:PrintMessage(
		D.WINDOW_FORCED:format(
			tostring(f:IsShown()),
			math.floor(f:GetWidth() or 0),
			math.floor(f:GetHeight() or 0),
			#MatchList:Items(),
			giftable
		)
	)
end

-- Closing is manual, via the X. Nothing else hides this window.
function UI:Close()
	Picker:Close()
	if not self.frame then
		return
	end
	self.frame:Hide()
	ns.Distributor:Stop()
	ns.Who:Clear() -- a half-finished query plan is stale; pairings are not
	self:_syncFindButton()
end

--[[
	NEVER HOOK MailFrame's OnHide TO CLOSE THIS WINDOW. It breaks twice over: TSM and other mail
	replacements hide MailFrame and show their own, killing this window the instant it opens; and
	SendWho raises the Who panel, which the UIPanel system swaps in over MailFrame, so pressing
	Find Recipients would close this window mid-query.

	So it opens on the mailbox and never auto-closes. Match-List holds items, roster and pairings
	at file scope, so matches survive walking away.
]]
local function haveSomethingToDo()
	for _, item in ipairs(MatchList:Items()) do
		if item.recipient or item.state == ns.Matcher.GIFT then
			return true
		end
	end
	return false
end

--[[
	Nothing to hand out means nothing happens, and nothing is said: no spare gear is the ordinary
	state of a mailbox visit. A shut window also looks broken, which Force the Window Open answers.
]]
local function mailboxOpened()
	ns.mailboxOpen = true
	MatchList:EnsureScan()
	if haveSomethingToDo() then
		openWindow()
	end
end

--[[
	The window outlives the mailbox, so the button follows the mailbox, not the window.

	Deferred a frame rather than read inline: the mailbox closing and the interaction manager
	reporting it ended are not guaranteed to land in that order, and _syncDistributeButton asks the
	manager. Reading it too early answers for the mailbox that is still closing and leaves the
	button live -- the exact state this exists to clear.
]]
local function recheckDistribute()
	C_Timer.After(0, function()
		--[[
			A run cannot survive the mailbox closing: nothing else clears Distributor.busy before
			its full RESULT_TIMEOUT, so Distribute answers "still sending" until then. Asked of the
			interaction manager, never of MailFrame, which hides spuriously under TSM and while the
			Who panel is up -- killing a live run on one of those is worse than the hang.
		]]
		if not ns.AtMailbox() and (ns.Distributor.busy or ns.Distributor.queue[1]) then
			ns.Distributor:Stop()
			ns:PrintMessage(L["MAIL_MAILBOX_CLOSED"])
		end
		if UI.frame and UI.frame:IsShown() then
			UI:_syncDistributeButton()
		end
	end)
end

local function mailboxClosed()
	ns.mailboxOpen = false
	recheckDistribute()
end

--[[
	Track the mailbox, not its frame: MailFrame:IsShown reports wrongly under TSM and while the
	Who panel is up, and this flag is what Distributor gates on.
]]
ns.on("PLAYER_LOGIN", function()
	if MailFrame then
		MailFrame:HookScript("OnShow", mailboxOpened)
		--[[
			A prompt to re-check, NOT a claim the mailbox closed, and deliberately not
			mailboxClosed: this frame hides spuriously, and flipping ns.mailboxOpen on that would
			lie to the Distributor.

			Here because MAIL_CLOSED does not fire on every way out -- Escape and another add-on
			closing the frame both skip it, and on Era the interaction-manager events are not
			registered. A spurious hide costs one re-check that changes nothing.
		]]
		MailFrame:HookScript("OnHide", recheckDistribute)
	end
end)

-- From the client's own enum, literal as fallback: a bare 17 in two files is two places to be wrong.
local MAILBOX_INTERACTION = (Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo) or 17

ns.on("MAIL_SHOW", mailboxOpened)
ns.on("MAIL_CLOSED", mailboxClosed)

if not ns.isEra then
	-- BCC / retail-style: the interaction manager reports the mailbox as well.
	ns.on("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(t)
		if t == MAILBOX_INTERACTION then
			mailboxOpened()
		end
	end)
	ns.on("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(t)
		if t == MAILBOX_INTERACTION then
			mailboxClosed()
		end
	end)
end
