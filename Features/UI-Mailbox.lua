local _, ns = ...
local L = ns.L

local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

--------------------------------------------------------------------------------
-- Recipient Finding
--------------------------------------------------------------------------------

-- No press and no /who throttle. The live roster lands frames later, so the callback re-assigns.
local function PullGuild()
	if MatchList:AddResults(ns.Guild:ReadSaved()) > 0 then
		UI:Assign()
	end
	ns.Guild:Request(function(members)
		if #members == 0 then
			return
		end
		if MatchList:AddResults(members) == 0 then
			return
		end
		if UI.frame and UI.frame:IsShown() then
			UI:Assign()
		end
	end)
end

local function PullAlts()
	if MatchList:AddResults(ns.Alts:Read()) > 0 then
		UI:Assign()
	end
end

--[[
	Nothing is matched until Find Recipients is pressed after opening: a list opened on old
	pairings reads as a search that already happened.
]]
local matching = false

-- SendWho fires only from a real press: one press, one query.
function UI:FindRecipients()
	Picker:Close()

	-- Mid-plan only once matching has started: a plan a rescan left standing is not a press.
	if matching and ns.Who:Remaining() > 0 then
		return self:Step()
	end
	matching = true

	-- Fresh plans only: the roster walk costs a last-online call per member.
	PullGuild()
	PullAlts()

	--[[
		Pools are never wiped in a session; each press adds. The query goes out before matching,
		which would prune the plan to whatever the saved names left uncovered.
	]]
	local bands = MatchList:RescanBags()
	if #bands == 0 then
		self:Assign()
		return
	end

	ns.Who:Plan(bands)
	self:Step()
end

-- For the status line: before any query, it says which button comes first.
local searched = false

function UI:HasSearched()
	return searched
end

function UI:Step()
	local sent = ns.Who:Step(function(results)
		-- nil: the query timed out and is back on the plan. Matched anyway from the names already found.
		if results then
			MatchList:AddResults(results)
		end
		self:Assign()
	end)

	-- Locked the moment the query goes out: the throttle runs from the send, not the answer.
	if sent then
		searched = true
		self:LockFindButton()
	else
		self:Assign()
	end
	self:SyncFindButton()
end

-- Held for the full Who.THROTTLE, not until the answer: a quick reply would offer a press the server refuses.
local searchTimer

function UI:LockFindButton()
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
			UI:SyncFindButton()
		end
	end)
end

--[[
	Retasks the plan to this item's attempts; Find Recipients steps the rest. Runs off the picker
	click, the hardware event SendWho demands.
]]
function UI:FindRecipientsForItem(item)
	if not self:RescanCanHelp(item) then
		return
	end
	-- Before retasking: a press that cannot send would drop the plan and cancel the query in flight.
	local inFlight = ns.Who:InFlight()
	local wait = ns.Who:ThrottleLeft()
	if inFlight or wait > 0 then
		ns:PrintMessage(L["WHO_WAIT"]:format(math.max(1, math.ceil(wait))))
		return
	end
	matching = true
	MatchList:Target(item)
	ns.Who:Plan(ns.Matcher:TargetedBands(item), true)
	self:Step()
end

--[[
	One label whatever the plan holds: chat lines such as WHO_BLOCKED name Find Recipients. Silent
	while locked, or a callback would put a live-looking label on a dead button.
]]
function UI:SyncFindButton()
	-- Before the lock check, so the status updates while the button waits.
	self:SyncStatus()
	if searchTimer then
		return
	end
	self.frame.findButton:SetText(L["BUTTON_FIND_RECIPIENTS"])
end

-- Before Find Recipients this only redraws: a hand pick or a rescan must not match the rest.
function UI:Assign()
	if matching then
		MatchList:Assign()
	end
	self:Refresh()
	self:SyncFindButton()
end

--[[
	Re-plans, since a giftability setting changes the bands. Plan before assigning: Assign clears a
	plan no gift still needs, and the other order would leave one standing.
]]
function UI:Rescan()
	if not self.frame then
		MatchList:MarkStale()
		return
	end
	local bands = MatchList:RescanBags()
	ns.Who:Plan(bands)
	self:Assign()
end

--------------------------------------------------------------------------------
-- Distribute checked rows
--------------------------------------------------------------------------------

function UI:Distribute()
	Picker:Close()
	local jobs = {}
	local body = ns.Distributor:BuildBody()

	-- Enforced again though Assign holds to it: two parcels to one stranger read as spam and cannot be undone.
	local claimed = {}
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			local who = item.recipient.name
			local exempt = item.pinned or item.recipient.alt
			if claimed[who] and not exempt then
				ns:PrintMessage(L["MAIL_ALREADY_HAS_ONE"]:format(item.link, ns.ColorName(who, item.recipient.class)))
			else
				if not exempt then
					claimed[who] = true
				end
				table.insert(jobs, {
					bag = item.bag,
					slot = item.slot,
					uid = item.uid,
					link = item.link,
					recipient = who,
					level = item.recipient.level,
					class = item.recipient.class,
					alt = item.recipient.alt,
					-- No text to alts: a letter with text stays in the mailbox after its item is taken.
					subject = (not item.recipient.alt) and ns.Distributor:BuildSubject() or nil,
					body = (not item.recipient.alt) and body or nil,
				})
			end
		end
	end

	-- Off the list on confirmation, never a bag re-read: MAIL_SUCCESS lands before the slot empties.
	ns.Distributor.onProgress = function(_, _, job, ok)
		if ok then
			UI:Delivered(job)
		else
			UI:ReleaseRecipient(job)
		end
	end
	ns.Distributor.onDone = function()
		UI:AfterDelivery()
	end
	ns.Distributor.onStateChange = function()
		UI:SyncDistributeButton()
	end
	ns.Distributor:Start(jobs)
end

-- By uid: two copies of one green share a name and a link.
function UI:Delivered(job)
	local item, index = MatchList:FindByKey(job.uid or "")
	if item then
		if item.recipient then
			MatchList:AssignedTo()[item.recipient.name] = nil
		end
		table.remove(MatchList:Items(), index)
	end
	self:Refresh()
end

--[[
	Only when the name itself is the problem: a plain MAIL_FAILED can be a full mailbox, and the
	pairing may be a hand pick.
]]
function UI:ReleaseRecipient(job)
	local item = MatchList:FindByKey(job.uid or "")
	if item and item.recipient and not ns.Fairness:IsReachable(item.recipient.name) then
		-- Still ticked: the player never unticked it.
		MatchList:AssignedTo()[item.recipient.name] = nil
		item.recipient, item.send, item.pinned = nil, true, false
	end
	self:Refresh()
end

-- No bag re-read: the slots are still emptying, so a scan would put delivered items back.
function UI:AfterDelivery()
	if not self.frame then
		return
	end
	self:Assign()
end

--------------------------------------------------------------------------------
-- Opening and closing
--------------------------------------------------------------------------------

-- Does not scan: every caller reads the bags first.
function UI:Open()
	self:BuildFrame()
	-- Same placement as PlaceAtFirst (Features/UI-Window.lua); skipped once the player has moved it.
	local host = self:MailboxTabHost()
	if host and not ns.db.profile.windowPos.point then
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", host, "TOPRIGHT", self.MAILBOX_TAB_SIZE + 8, 0)
	end
	self.frame:Show()

	-- Read in for hand picks; UI:Assign leaves them unpaired until Find Recipients.
	PullGuild()
	PullAlts()
	self:Refresh()
	self:SyncMailboxTab()
end

-- Escape never reaches here: it hides the frame, and OnHide runs UI:OnClosed.
function UI:Close()
	Picker:Close()
	if not self.frame then
		return
	end
	self.frame:Hide()
	-- Also for a window closed without ever being shown, where OnHide never fires.
	self:OnClosed()
end

-- Idempotent: UI:Close runs it and so does OnHide.
function UI:OnClosed()
	if not self.frame then
		return
	end
	Picker:Close()
	ns.Distributor:Stop()
	ns.Who:Clear()
	MatchList:ReleaseAutomatic()
	matching = false
	searched = false
	self:SyncFindButton()
	self:SyncMailboxTab()
end

--[[
	Never close the window from MailFrame hiding: TSM and the Who panel hide it at a mailbox. Not
	redrawn mid-run: the sender's own MailFrame:Show reports the mailbox again.
]]
local function MailboxOpened()
	ns.mailboxOpen = true
	if UI.frame and UI.frame:IsShown() and not ns.Distributor.busy then
		UI:Refresh()
	end
	UI:SyncMailboxTabSoon()
end

--[[
	Deferred a frame: the close and the interaction manager's report can land in either order, and
	read too early ns.AtMailbox() still answers for the closing mailbox.
]]
local function RecheckDistribute()
	C_Timer.After(0, function()
		--[[
			Stopped here, or Distributor.busy holds for a full RESULT_TIMEOUT. Never gated on MailFrame,
			which hides spuriously under TSM and the Who panel.
		]]
		if not ns.AtMailbox() and (ns.Distributor.busy or ns.Distributor.queue[1]) then
			ns.Distributor:Stop()
			ns:PrintMessage(L["MAIL_MAILBOX_CLOSED"])
		end
		-- The next visit never waits on a send still awaiting its result.
		if not ns.AtMailbox() then
			ns.Distributor._awaiting = nil
		end
		if UI.frame and UI.frame:IsShown() then
			UI:SyncDistributeButton()
		end
		UI:SyncMailboxTab()
	end)
end

local function MailboxClosed()
	ns.mailboxOpen = false
	RecheckDistribute()
end

local function OnPlayerLogin()
	if MailFrame then
		MailFrame:HookScript("OnShow", MailboxOpened)
		--[[
			A re-check, not MailboxClosed: this frame hides spuriously. Needed because MAIL_CLOSED
			skips some ways out, and Era has no interaction-manager events.
		]]
		MailFrame:HookScript("OnHide", RecheckDistribute)
		-- For the Mailbox diagnostics report: no MailFrame at login means no hooks all session.
		UI.mailFrameHooked = true
	end
end
ns.On("PLAYER_LOGIN", OnPlayerLogin)

local function OnMailShow()
	MailboxOpened()
end
ns.On("MAIL_SHOW", OnMailShow)

local function OnMailClosed()
	MailboxClosed()
end
ns.On("MAIL_CLOSED", OnMailClosed)

-- Returned gifts, said once a session each. Headers only: reading a body would mark the mail read.
local returnedSaid = {}

local function IsGiftSubject(subject)
	return subject == ns.Distributor:BuildSubject() or subject == L["MAIL_SUBJECT"]
end

local function OnMailInboxUpdate()
	if not ns.AtMailbox() then
		return
	end
	for index = 1, (GetInboxNumItems()) do
		local _, _, sender, subject, _, _, _, hasItem, _, wasReturned = GetInboxHeaderInfo(index)
		if wasReturned and hasItem and sender and subject and IsGiftSubject(subject) then
			local link = GetInboxItemLink(index, 1)
			local key = sender .. "\0" .. tostring(link)
			if link and not returnedSaid[key] then
				returnedSaid[key] = true
				ns:PrintMessage(L["MAIL_RETURNED"]:format(link, Ambiguate(sender, "short")))
			end
		end
	end
end
ns.On("MAIL_INBOX_UPDATE", OnMailInboxUpdate)

if ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot" then
	-- TBC and later, and Forever's Retail client.
	local MAILBOX_INTERACTION = Enum.PlayerInteractionType.MailInfo
	local function OnPlayerInteractionManagerFrameShow(t)
		if t == MAILBOX_INTERACTION then
			MailboxOpened()
		end
	end
	ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnPlayerInteractionManagerFrameShow)
	local function OnPlayerInteractionManagerFrameHide(t)
		if t == MAILBOX_INTERACTION then
			MailboxClosed()
		end
	end
	ns.On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", OnPlayerInteractionManagerFrameHide)
end
