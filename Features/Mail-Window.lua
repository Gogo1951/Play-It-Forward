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
local BUTTON_W = 150 -- Find Recipients and Distribute, matched

local FRAME_TEMPLATE = ns.PickTemplate("BasicFrameTemplate", "BackdropTemplate")
local INSET_TEMPLATE = ns.PickTemplate("InsetFrameTemplate3", "InsetFrameTemplate2", "InsetFrameTemplate")

local rows = {} -- reusable row frames

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

	--[[
		Anchoring to the mailbox puts a wide window off-screen when the mailbox sits right of
		center, so it is clamped, draggable, and remembers where it was put.
	]]
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

	--[[
		AceDB materializes windowPos per profile, so it always exists; its point field is what
		says whether the player has actually dragged the window.
	]]
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

	-- Sunken list area. Another stock template, another thing skins restyle.
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
	Matched, then what could still match, then unreadable, then the vendor pile: the list runs
	longer than the window, so rows worth acting on would otherwise fall below the fold.
	Unreadable sits above the vendor pile because it is the group that wants a human look.
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

-- Flatten the sorted items into rows with a section band at each group boundary.
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
			row.itemText:SetText(item.link)

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
	What one row's dropdown offers, split from opening it so Tests/Manual-Assignment.lua can
	read who is selectable without a frame. Nobody is hidden: an unavailable name is greyed with
	the reason beside it, because one that silently vanishes reads as the add-on losing them.
]]
function UI:_pickerOptions(item)
	local options = { {
		text = GetColor("MUTED") .. L["PICKER_VENDOR_OPTION"] .. "|r",
		clear = true,
	} }

	local anyGreyed = false
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
		--[[
			Two reasons a candidate cannot be picked, both the player's business: one item per
			person, enforced at the point of offering, and a name the server already refused.
		]]
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

		anyGreyed = anyGreyed or held or refused
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

	-- One line for the whole list rather than the same sentence on every greyed row.
	if anyGreyed then
		table.insert(options, {
			text = GetColor("MUTED") .. L["PICKER_HINT_GREYED"] .. "|r",
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
		_pickerOptions greys these out; this is the guard behind it.
	]]
	if who then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item then
			ns:PrintWarning(L["CHAT_ALREADY_HOLDS"]:format(ns.ColorName(who.name, who.class), other.link))
			return
		end
		if not ns.Fairness:IsReachable(who.name) then
			ns:PrintWarning(L["CHAT_CANNOT_RECEIVE"]:format(ns.ColorName(who.name, who.class)))
			return
		end
	end

	if item.recipient then
		MatchList:AssignedTo()[item.recipient.name] = nil
	end

	--[[
		Pinned because a player chose it. _assign rebuilds everything it decided itself, so this
		marks the row as not its to decide -- the vendor case included, where "nobody" is a
		choice.
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
	The row's tick, the other way to say "not this one". Pinned for the same reason: the tick is
	the last thing between an item and a stranger's mailbox, and a rebuild that re-ticks a row
	somebody unticked has overridden them.
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
	SendWho only fires from a real button press, so this is a stepper: one press, one query.
	Results are re-assigned after every step, so the list fills in as it goes.
]]
function UI:FindRecipients()
	Picker:Close()

	-- Mid-plan? This press just sends the next query.
	if ns.Who:Remaining() > 0 then
		return self:_step()
	end

	--[[
		Pools are deliberately not wiped: one query returns at most ~49 people, a thin sample of
		the realm, so pressing again adds to the roster. Only Clear History and Roster empties
		it.
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
		--[[
			nil results is a query that never answered and is back on the plan: nothing to fold
			in, but the button still has to resync.
		]]
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
	Dead for as long as the server will not answer another query: a press inside that window is
	not a slow search, it is nothing at all. Held for the full throttle rather than until the
	answer arrives, because a reply often lands in under a second and re-enabling then offers a
	press the server refuses for another four. Reads Who.THROTTLE rather than a five written
	here, so the lock cannot undercut the rule it reflects.
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
	Distribute is dead unless pressing it would send something, on two conditions the player
	cannot see from the button alone: a mailbox has to be open, because Mail-Sender cannot
	attach without Blizzard's Send Mail panel, and at least one row has to be ticked with
	somebody on it. A live button that answers with a warning lied about being ready.
]]
function UI:_syncDistributeButton()
	if not (self.frame and self.frame.distributeButton) then
		return
	end
	local ready = false
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			ready = true
			break
		end
	end
	if ready and ns.AtMailbox() then
		self.frame.distributeButton:Enable()
	else
		self.frame.distributeButton:Disable()
	end
end

--[[
	Says whether there is somewhere left to look, never how many: the plan grows whenever a
	query comes back capped, and a search that stops at the first match has no total anyway.
	Silent while the lock is up -- this runs from the query callback and from _assign, both
	inside the throttle window, and either would put a live-looking label on a dead button.
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
	A rescan re-plans the search, and it has to: the level bands the plan was built from are
	exactly what a giftability setting changes, so a plan left standing after one is a search
	for the items that used to be on the list. Pools are untouched, so nobody already found is
	lost, and Who:Plan cancels an in-flight query rather than forgetting it.

	Plan before assigning. Assign clears the plan itself once no gift is left unmatched, so
	planning first lets it drop a plan that turned out to be unnecessary; the other order
	leaves that plan standing and puts Scan Again on the button with nothing to scan for.

	Guarded on the frame, because a setting can change before the window has ever been built.
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
		One mail per person per run, enforced rather than merely intended: _assign already holds
		to it, but two greens in one stranger's mailbox reads as spam and cannot be taken back.
		A dropped row is said out loud, since a silent drop looks like it was never ticked.
	]]
	local claimed = {}
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			local who = item.recipient.name
			if claimed[who] then
				ns:PrintWarning(L["MAIL_ALREADY_HAS_ONE"]:format(item.link, ns.ColorName(who, item.recipient.class)))
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
		A delivered item comes off the list when its send is confirmed, never from a re-read of
		the bags: MAIL_SUCCESS lands before the client empties the slot, so a scan then finds
		the item still there and restores the pairing it was just sent under.
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
	Let go of a recipient the server will not deliver to. The item stays on the list either
	way, and _afterDelivery re-assigns whatever came loose.

	ONLY WHEN THE NAME ITSELF IS THE PROBLEM. A plain MAIL_FAILED can be a full mailbox or a
	bad moment on the server, the same person may work on the next press, and the pairing may
	have been set by hand: discarding that choice because one send bounced is a second failure.
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
	The end of a run. It deliberately does not re-read the bags: the client is still emptying
	the slots, so a scan here could only put delivered items back. The deliveries raise
	BAG_UPDATE, which marks the scan stale, and the next mailbox picks them up for real.
	Re-assigning is worth doing: every recipient just went on cooldown, so whatever is left
	spreads to new faces on its own.
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

	UI:Refresh()
end

--[[
	"No window appeared" has two causes wanting opposite responses: it is off-screen, or there
	was nothing to show. This drops the saved position, re-centers, and reports what the scan
	found -- a forced window holding only the vendor pile answers the question on sight.
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

	--[[
		A diagnostic command must never be the thing that errors.

		Read from ns.DiagnosticsStrings at call time rather than aliased at file scope, because
		Features/Diagnostics.lua loads after this file.
	]]
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
	replacements hide MailFrame and show their own, killing this window the instant it opens;
	and SendWho raises the Who panel, which the UIPanel system swaps in over MailFrame, so
	pressing Find Recipients would close this window mid-query.

	So it opens on the mailbox and never auto-closes. Match-List holds the items, roster and
	pairings at file scope, so matches survive walking away. Whether it is worth showing is the
	scan's answer, read off the verdict each item carries; a recipient counts on its own, since
	auto-assignment places leftovers too.
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
	Nothing to hand out means nothing happens, and nothing is said either: no spare gear is the
	ordinary state of a mailbox visit, and announcing ordinary states talks over the game. A
	shut window is also what a broken add-on looks like, which is what Force the Window Open is
	for.
]]
local function mailboxOpened()
	ns.mailboxOpen = true
	MatchList:EnsureScan()
	if haveSomethingToDo() then
		openWindow()
	end
end
local function mailboxClosed()
	ns.mailboxOpen = false
	-- The window outlives the mailbox, so the button follows the mailbox, not the window.
	if UI.frame and UI.frame:IsShown() then
		UI:_syncDistributeButton()
	end
end

--[[
	Track the mailbox, not its frame: MailFrame:IsShown reports wrongly under TSM and while the
	Who panel is up, and this flag is what Distributor gates on.
]]
ns.on("PLAYER_LOGIN", function()
	if MailFrame then
		MailFrame:HookScript("OnShow", mailboxOpened)
	end
end)

--[[
	Which interaction type is a mailbox, read from the client's own enum with the literal as
	the fallback. A bare 17 in two files is two places to be wrong if Blizzard renumbers it.
]]
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
