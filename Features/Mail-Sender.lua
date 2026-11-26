local _, ns = ...
local L = ns.L

ns.Distributor = {}
local Distributor = ns.Distributor

-- One SendMail at a time, advanced by its result event. Blizzard's non-friend confirm is never auto-clicked.

-- Display only: SendMail takes the bare name, and an escape sequence would address it to nobody.
local function RecipientOf(job)
	return ns.ColorName(job.recipient, job.class)
end

-- Classic Era has no SendMailBodyEditBox; its body is MailEditBox:GetEditBox(). Picked by availability, never flavor.
local function MailBodyBox()
	if MailEditBox and MailEditBox.GetEditBox then
		local ok, box = pcall(MailEditBox.GetEditBox, MailEditBox)
		if ok and box then
			return box
		end
	end
	return SendMailBodyEditBox
end

local function FillMailPanel(job)
	local function Fill(box, text)
		if box and box.SetText then
			pcall(box.SetText, box, text or "")
		end
	end
	Fill(SendMailNameEditBox, job.recipient)
	-- A job with no subject (mail to your own alt) keeps the item name the attach wrote there.
	if job.subject then
		Fill(SendMailSubjectEditBox, job.subject)
	end
	Fill(MailBodyBox(), job.body)
end

-- Ours, else the item name the attach wrote, else the link's name: the server wants a subject.
local function SubjectOf(job)
	if job.subject then
		return job.subject
	end
	local box = SendMailSubjectEditBox
	if box and box.GetText then
		local ok, text = pcall(box.GetText, box)
		if ok and type(text) == "string" and text:match("%S") then
			return text
		end
	end
	return (job.link and job.link:match("%[(.-)%]")) or ""
end

-- Copper per one-item letter. CHECK IN GAME: wrong, it pauses a run the player could afford, or starts one they can't.
local MAIL_COST = 30
local RESULT_TIMEOUT = 30 -- seconds to wait on a confirm/result before pausing
-- A refusal can arrive as both UI_ERROR_MESSAGE and MAIL_FAILED; the second must not land on the next send.
local FAILURE_SETTLE = 1
local SUBJECT_MAX = 31 -- what the mail window's own edit boxes accept
local BODY_MAX = 500

-- Exposed so Mail-Copy and the Diagnostics reports read these, never a second copy that drifts.
Distributor.SUBJECT_MAX = SUBJECT_MAX
Distributor.BODY_MAX = BODY_MAX
Distributor.MAIL_COST = MAIL_COST

Distributor.busy = false
Distributor.queue = {}
Distributor.errors = 0
-- Bumped by Start and Stop, so a deferred advance from an earlier run never fires into a later one.
Distributor._run = 0
Distributor.onProgress = nil -- optional UI callback(done, total, job, ok)
Distributor.onDone = nil -- optional UI callback(done, total, skipped)
Distributor.onStateChange = nil -- optional UI callback(), whenever IsRunning flips

-- Run-level, unlike busy (one send in flight, false while a failure settles): true until the run finishes, stops or pauses.
Distributor.running = false

-- Stop lets the letter in hand finish; stopped keeps that run's count for the status line until the next run.
Distributor._stopRequested = false
Distributor.stopped = nil

-- The run's "Sent … to …" lines, held so the total prints first (Style Guide → MESSAGES).
Distributor._held = {}

-- Delivered letters for the window's Sent section; the window clears it on show and hide.
Distributor.sent = {}

function Distributor:IsRunning()
	return self.running
end

function Distributor:StopRequested()
	return self._stopRequested
end

function Distributor:Stopped()
	return self.stopped
end

function Distributor:Sent()
	return self.sent
end

function Distributor:ClearSent()
	wipe(self.sent)
end

-- Called once the line that heads them has printed.
function Distributor:FlushHeld()
	local held = self._held
	self._held = {}
	for _, line in ipairs(held) do
		ns:PrintMessage(line)
	end
end

function Distributor:SetRunning(value)
	if self.running == value then
		return
	end
	self.running = value
	if self.onStateChange then
		self.onStateChange()
	end
end

local function OnMailSuccess()
	Distributor:Result(true)
end
ns.On("MAIL_SUCCESS", OnMailSuccess)
local function OnMailFailed()
	-- The event carries no detail, so the reason slot says so rather than repeating "failed".
	Distributor:Result(false, L["MAIL_REASON_FAILED"])
end
ns.On("MAIL_FAILED", OnMailFailed)

-- Refusals without the ERR_MAIL prefix; a missed one sits out the full timeout. Named, not quoted, for every locale.
local OTHER_MAIL_ERRORS = { "ERR_PLAYER_WRONG_FACTION" }

--[[
	From the client's own strings, so every locale matches; format-specifier strings arrive filled
	in and are skipped. On Distributor because the event-log filter must ask the handler's question.
]]
local mailErrors
function Distributor:IsMailError(message)
	if not message or message == "" then
		return false
	end
	if not mailErrors then
		mailErrors = {}
		for name, value in pairs(_G) do
			if type(name) == "string" and type(value) == "string" and name:find("^ERR_MAIL") then
				if not value:find("%%") then
					mailErrors[value] = name
				end
			end
		end
		for _, name in ipairs(OTHER_MAIL_ERRORS) do
			local value = _G[name]
			if type(value) == "string" and value ~= "" and not value:find("%%") then
				mailErrors[value] = name
			end
		end
	end
	return mailErrors[message] or false
end

-- Never counts toward the abort: it says nothing about the run, and an unplaced /who yields them back to back.
local RECIPIENT_ONLY_ERRORS = { ERR_PLAYER_WRONG_FACTION = true }

-- A refused alt is forgotten too, or a deleted one is offered first every session; a live one re-records at login.
local function MarkRefused(job)
	ns.Fairness:MarkUnreachable(job.recipient)
	if job.alt then
		ns.Alts:Forget(job.recipient)
	end
end

--[[
	SendMail can be refused with neither result event. Inside the settle window the UI error only
	marks the recipient: MAIL_FAILED already counted that failure.
]]
local function OnUiErrorMessage(_, message)
	local inFlight = Distributor.busy and Distributor._current
	local settling = not Distributor.busy and Distributor._settling
	if not (inFlight or settling) then
		return
	end
	local errorName = Distributor:IsMailError(message)
	if not errorName then
		return
	end
	-- Only once the job reached SendMail: a refusal during the attach is about the item.
	if inFlight then
		if inFlight._sent then
			MarkRefused(inFlight)
		end
		Distributor:Result(false, message, RECIPIENT_ONLY_ERRORS[errorName], inFlight._sent)
		return
	end
	if not settling._sent then
		return
	end
	MarkRefused(settling)
	Distributor:DropRepeats(settling)
	if Distributor.onProgress then
		Distributor.onProgress(Distributor._done or 0, Distributor._total or 0, settling, false)
	end
end
ns.On("UI_ERROR_MESSAGE", OnUiErrorMessage)

-- job = { bag, slot, uid, link, recipient, level, class, alt, subject, body }
function Distributor:Start(jobs)
	--[[
		A held send's late result would credit the new run's first job. One more RESULT_TIMEOUT
		only: an unconfirmed send never answers, and must not lock Distribute.
	]]
	if self.busy or (self._awaiting and GetTime() - (self._awaitingSince or 0) < RESULT_TIMEOUT) then
		ns:PrintMessage(L["MAIL_STILL_SENDING"])
		return
	end
	self._awaiting = nil
	self._run = self._run + 1
	self._settling = nil
	self._stopRequested = false
	self.stopped = nil
	self._held = {}
	self.queue = jobs or {}
	self.errors = 0
	self._total = #self.queue
	self._done = 0
	self._skipped = 0
	if #self.queue == 0 then
		ns:PrintMessage(L["MAIL_NOTHING_TO_DISTRIBUTE"])
		return
	end
	ns:PrintMessage(L["MAIL_DISTRIBUTING"]:format(#self.queue))
	self:SetRunning(true)
	self:Next()
end

function Distributor:Stop()
	-- A send in flight still lands; holding it lets Result credit it after the stop.
	if self.busy then
		self._awaiting, self._awaitingSince = self._current, GetTime()
	end
	self.busy = false
	self._run = self._run + 1
	self._settling = nil
	self._stopRequested = false
	self.stopped = nil
	wipe(self.queue)
	if self._timer then
		self._timer:Cancel()
		self._timer = nil
	end
	self:FlushHeld()
	self:SetRunning(false)
end

-- With a letter in hand or a refusal settling, the run halts once that resolves; otherwise at once.
function Distributor:RequestStop()
	if not self.running then
		return
	end
	self._stopRequested = true
	if not self.busy and not self._settling then
		self:Halt()
	end
end

-- Prints like a finished run: the Stopped count, then the held lines.
function Distributor:Halt()
	self._stopRequested = false
	self.busy = false
	self._run = self._run + 1
	self._settling = nil
	wipe(self.queue)
	if self._timer then
		self._timer:Cancel()
		self._timer = nil
	end
	local done, total, skipped = self._done or 0, self._total or 0, self._skipped or 0
	self.stopped = { done = done, total = total }
	ns:PrintMessage(L["MAIL_STOPPED"]:format(done, total))
	self:FlushHeld()
	self:SetRunning(false)
	if self.onDone then
		self.onDone(done, total, skipped)
	end
	ns.Generosity:Broadcast()
end

function Distributor:Next()
	if self.busy then
		return
	end

	-- Bag slots shift between matching and sending; a stranger receives whatever slid in.
	while self.queue[1] do
		local candidate = self.queue[1]
		if ns.GetItemLink(candidate.bag, candidate.slot) == candidate.link then
			break
		end
		ns:PrintMessage(L["MAIL_ITEM_MOVED"]:format(candidate.link))
		self._skipped = (self._skipped or 0) + 1
		table.remove(self.queue, 1)
	end

	local job = self.queue[1]
	if not job then
		return self:Finish()
	end

	-- Gate on the mailbox, not MailFrame:IsShown(): TSM and the Who panel swap MailFrame out.
	if not ns.AtMailbox() then
		ns:PrintMessage(L["MAIL_NOT_AT_MAILBOX"])
		self:Pause()
		return
	end
	if GetMoney() < MAIL_COST then
		ns:PrintMessage(L["MAIL_NO_POSTAGE"])
		self:Pause()
		return
	end

	self.busy = true
	self._current = job

	-- The tab helpers are FrameXML; a mail add-on may own them, so a missing one must not abort.
	if MailFrame and not MailFrame:IsShown() then
		pcall(MailFrame.Show, MailFrame)
	end
	if MailFrameTab_OnClick then
		pcall(MailFrameTab_OnClick, nil, 2)
	end -- 2 = Send Mail

	--[[
		CHECK BEFORE TOUCHING THE ITEM: with the Send Mail panel closed, UseContainerItem uses the
		item instead of attaching it (a consumable is drunk). Checking after can only report the damage.
	]]
	if not (SendMailFrame and SendMailFrame:IsShown()) then
		self.busy = false
		ns:PrintMessage(L["MAIL_PANEL_CLOSED"])
		ns:PrintMessage(L["MAIL_PANEL_CLOSED_HINT"])
		return self:Finish()
	end

	if ClearSendMail then
		pcall(ClearSendMail)
	end
	-- Emptied so the attach writes this item's name; a stale subject would carry onto an alt's letter.
	if SendMailSubjectEditBox and SendMailSubjectEditBox.SetText then
		pcall(SendMailSubjectEditBox.SetText, SendMailSubjectEditBox, "")
	end

	-- Stack size now: by MAIL_SUCCESS the slot is stale, and a stack of 20 would tally as one.
	local slotInfo = ns.GetItemInfoC(job.bag, job.slot)
	job._count = (slotInfo and slotInfo.stackCount) or 1

	-- Guarded: a throw before the timer is armed leaves busy set with nothing to clear it until a reload.
	local attached = pcall(C_Container.UseContainerItem, job.bag, job.slot) -- attaches to first open mail slot

	-- An in-call UI error may already have failed the job and armed the settle; carrying on would finish twice.
	if not self.busy or self._current ~= job then
		return
	end

	-- An attach can fail with the panel up, and SendMail posts an empty letter and reports success.
	if not attached or not (GetSendMailItem and GetSendMailItem(1)) then
		self.busy = false
		ns:PrintMessage(L["MAIL_ATTACH_FAILED"]:format(job.link))
		return self:Finish()
	end

	-- After the attach, which writes into the subject box. Cosmetic, so each box is guarded on its own.
	FillMailPanel(job)

	-- From here a refusal is about the recipient. A throw clears the panel so the item isn't left attached.
	job._sent = true
	local sent = pcall(SendMail, job.recipient, SubjectOf(job), job.body or "")
	if not self.busy or self._current ~= job then
		return
	end
	if not sent then
		self.busy = false
		if ClearSendMail then
			pcall(ClearSendMail)
		end
		ns:PrintMessage(L["MAIL_SEND_FAILED"]:format(RecipientOf(job), L["MAIL_REASON_ERROR"]))
		return self:Finish()
	end

	-- Wait for MAIL_SUCCESS/FAILED, or pause if the player hasn't confirmed.
	if self._timer then
		self._timer:Cancel()
	end
	self._timer = C_Timer.NewTimer(RESULT_TIMEOUT, function()
		self._timer = nil
		-- SendMail has already fired, so a late Accept still delivers: hold the job as Stop does.
		self._awaiting, self._awaitingSince = self._current, GetTime()
		self.busy = false
		ns:PrintMessage(L["MAIL_AWAITING_CONFIRM"]:format(RecipientOf(job)))
		self:Pause()
	end)
end

-- After the line saying why: the held lines follow it, and a pending Stop has nothing left to stop.
function Distributor:Pause()
	self._stopRequested = false
	self:FlushHeld()
	self:SetRunning(false)
end

--[[
	A refused name refuses the rest, and the repeats would trip the two-error abort. Released like
	failures so the rows stay; not skips, which Finish reports as items that moved in the bags.
]]
function Distributor:DropRepeats(job)
	for index = #self.queue, 1, -1 do
		local queued = self.queue[index]
		if queued ~= job and queued.recipient == job.recipient then
			table.remove(self.queue, index)
			if self.onProgress then
				self.onProgress(self._done or 0, self._total or 0, queued, false)
			end
		end
	end
end

-- Never tallied for your own alt: mailing yourself gives nothing away.
local function Credit(job)
	ns.Fairness:Record(job.recipient, job.level or 0)
	if not job.alt then
		ns.Generosity:RecordSend(job.link, job._count)
	end
end

function Distributor:Result(ok, reason, recipientOnly, refused)
	-- A stopped or timed-out run can still have a send in flight: record it, then stay stopped.
	if not self.busy then
		local pending = self._awaiting
		self._awaiting = nil
		if pending and ok then
			Credit(pending)
			table.insert(self.sent, pending)
			-- It delivered, so drop it before a resume retries an already-empty slot.
			if self.queue[1] == pending then
				table.remove(self.queue, 1)
			end
			-- Without this the row stays matched and ticked, and Distribute earns a "moved" skip.
			if self.onProgress then
				self.onProgress(self._done or 0, self._total or 0, pending, true)
			end
		end
		return
	end
	if self._timer then
		self._timer:Cancel()
		self._timer = nil
	end
	self.busy = false

	local job = self._current
	if ok then
		-- Trust MAIL_SUCCESS: it fires before the bag update, so a re-read still sees the old link.
		Credit(job)
		self._done = (self._done or 0) + 1
		table.insert(self._held, L["MAIL_SENT"]:format(job.link, RecipientOf(job), self._done, self._total))
		table.insert(self.sent, job)
		table.remove(self.queue, 1)
		self.errors = 0
	else
		if not recipientOnly then
			self.errors = self.errors + 1
		end
		ns:PrintMessage(L["MAIL_SEND_FAILED"]:format(RecipientOf(job), reason or "?"))
		-- Before the abort check, so only a failure to somebody else can end the run.
		if refused then
			self:DropRepeats(job)
		end
		if not recipientOnly and self.errors > 1 then
			-- The failed item is still on Blizzard's panel with the name in To: one Send would re-mail it.
			if ClearSendMail then
				pcall(ClearSendMail)
			end
			ns:PrintMessage(L["MAIL_ABORTED"])
			return self:Finish()
		end
		table.remove(self.queue, 1)
	end

	if self.onProgress then
		self.onProgress(self._done, self._total, job, ok)
	end
	if ok then
		-- The letter in hand is done: a Stop pressed during it halts here, unless that was the last.
		if self._stopRequested and self.queue[1] then
			return self:Halt()
		end
		return self:Next()
	end

	-- Not busy while settling, so a second signal for this refusal is absorbed rather than counted.
	self._settling = job
	local run = self._run
	C_Timer.After(FAILURE_SETTLE, function()
		if self._run ~= run then
			return
		end
		self._settling = nil
		if self._stopRequested and self.queue[1] then
			return self:Halt()
		end
		if not self.busy then
			self:Next()
		end
	end)
end

function Distributor:Finish()
	-- A run that ends early is over: anything left must not read as cut off by the mailbox closing.
	wipe(self.queue)
	self.busy = false
	self._stopRequested = false
	self:SetRunning(false)
	local done, total, skipped = self._done or 0, self._total or 0, self._skipped or 0
	-- Skips are items that moved in the bags, not failures, so they are counted apart.
	if skipped > 0 then
		ns:PrintMessage(L["MAIL_DONE_WITH_SKIPS"]:format(done, total, skipped))
	else
		ns:PrintMessage(L["MAIL_DONE"]:format(done, total))
	end
	-- The total first, then what went where (Style Guide → MESSAGES).
	self:FlushHeld()
	if self.onDone then
		self.onDone(done, total, skipped)
	end
	-- Self-throttled, so one soon after the login broadcast no-ops.
	ns.Generosity:Broadcast()
end
