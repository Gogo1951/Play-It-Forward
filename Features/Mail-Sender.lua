local _, ns = ...
local L = ns.L

ns.Distributor = {}
local Distributor = ns.Distributor

--[[
	Serialized, event-driven mailer. SendMail cannot be looped: one send goes out, then the run
	waits for MAIL_SUCCESS or MAIL_FAILED before advancing. Mailing a non-friend arms Blizzard's
	"might be someone you don't know" confirm, which is never auto-clicked.
]]

-- Display only: SendMail takes the bare name, and an escape sequence would address it to nobody.
local function RecipientOf(job)
	return ns.ColorName(job.recipient, job.class)
end

--[[
	The body box, under whichever name this client keeps it. SendMailBodyEditBox is the retail
	name; on Classic Era that global is nil and the body lives behind MailEditBox:GetEditBox(), so the
	To and Subject boxes fill while the body stays empty. Picked by availability, never by flavor.
]]
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
	Fill(SendMailSubjectEditBox, job.subject)
	Fill(MailBodyBox(), job.body)
end

local MAIL_COST = 30 -- copper per mail
local RESULT_TIMEOUT = 30 -- seconds to wait on a confirm/result before pausing
-- A refusal can arrive as both UI_ERROR_MESSAGE and MAIL_FAILED; the second must not land on the next send.
local FAILURE_SETTLE = 1
local SUBJECT_MAX = 31 -- what the mail window's own edit boxes accept
local BODY_MAX = 500

--[[
	Exposed so the Outgoing Mail preview and the Mailbox report in Diagnostics/Manifests.lua report
	the same numbers Features/Mail-Copy.lua enforces; a second copy there would disagree silently the
	day either changes.
]]
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

--[[
	Run-level, unlike busy, which covers one send in flight and drops during the failure settle.
	True from Start until the run finishes, stops, or pauses with jobs still queued: the moments
	the chat lines tell the player to press Distribute again.
]]
Distributor.running = false

function Distributor:IsRunning()
	return self.running
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

--[[
	Refusals a send can earn that do not carry the ERR_MAIL prefix. ERR_PLAYER_WRONG_FACTION
	("Target is unfriendly.") observed on Forever 1.60.1 (2026-10-06), mailing a /who result of
	the other faction: missed, it sat out the full timeout and blamed a confirm nobody was shown.
	Named, not quoted, so it matches in every locale; a name this client lacks adds nothing.
]]
local OTHER_MAIL_ERRORS = { "ERR_PLAYER_WRONG_FACTION" }

--[[
	Every mail refusal the client knows about, collected from its own ERR_MAIL* strings rather than
	listed, since a hardcoded English sentence would never fire on another locale. Strings carrying
	a format specifier are skipped -- they arrive with the placeholder filled in, so an exact
	comparison never matches. A skipped error is a missed catch, never a wrong one.

	ON THE DISTRIBUTOR RATHER THAN FILE-LOCAL, because the diagnostics event-log filter classifies
	UI_ERROR_MESSAGE with it: the filter has to ask the same question the live handler asks, or the
	log suppresses a firing this file acted on and says nothing about it.
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

--[[
	A refusal the server reports as a UI error rather than MAIL_FAILED: SendMail can be rejected
	without either result event, leaving the run to sit out its full timeout over an item that
	never left the bag. Guarded on a send being in flight and on the message being one of the
	client's own mail errors, since UI_ERROR_MESSAGE carries everything from standing too far away.

	Inside the settle window after a failure, the same refusal's UI error only marks that send's
	recipient: the failure was already counted and printed when MAIL_FAILED resolved it.

	A wrong-faction refusal skips that one recipient without counting toward the two-error abort:
	it says nothing about the run, and a /who the faction filter could not place produces them
	back to back.

	A refused alt is forgotten as well as marked: a deleted or renamed character stays recorded
	for good otherwise, and is offered first every session after. One that still exists records
	itself again at its next login.
]]
local RECIPIENT_ONLY_ERRORS = { ERR_PLAYER_WRONG_FACTION = true }

local function MarkRefused(job)
	ns.Fairness:MarkUnreachable(job.recipient)
	if job.alt then
		ns.Alts:Forget(job.recipient)
	end
end

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
	--[[
		A name the server will not take now will not start working later in the same session. Only
		once the job reached SendMail: a refusal during the attach is about the item.
	]]
	if inFlight then
		if inFlight._sent then
			MarkRefused(inFlight)
		end
		Distributor:Result(false, message, RECIPIENT_ONLY_ERRORS[errorName])
		return
	end
	if not settling._sent then
		return
	end
	MarkRefused(settling)
	if Distributor.onProgress then
		Distributor.onProgress(Distributor._done or 0, Distributor._total or 0, settling, false)
	end
end
ns.On("UI_ERROR_MESSAGE", OnUiErrorMessage)

-- job = { bag, slot, uid, link, recipient, level, class, alt, subject, body }
function Distributor:Start(jobs)
	--[[
		A send still awaiting its result holds the next run back, or that result would be credited
		to the new run's first job. For one more RESULT_TIMEOUT only: a send the player never
		confirmed produces no result at all, and must not lock Distribute until the mailbox closes.
	]]
	if self.busy or (self._awaiting and GetTime() - (self._awaitingSince or 0) < RESULT_TIMEOUT) then
		ns:PrintMessage(L["MAIL_STILL_SENDING"])
		return
	end
	self._awaiting = nil
	self._run = self._run + 1
	self._settling = nil
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
	--[[
		A send already in flight still lands, so its result event is still coming. Holding the job
		is what lets Result put its recipient on cooldown after the run is over.
	]]
	if self.busy then
		self._awaiting, self._awaitingSince = self._current, GetTime()
	end
	self.busy = false
	self._run = self._run + 1
	self._settling = nil
	wipe(self.queue)
	if self._timer then
		self._timer:Cancel()
		self._timer = nil
	end
	self:SetRunning(false)
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
		self:SetRunning(false)
		return
	end
	if GetMoney() < MAIL_COST then
		ns:PrintMessage(L["MAIL_NO_POSTAGE"])
		self:SetRunning(false)
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
		CHECK BEFORE TOUCHING THE ITEM, and never move this below the call. UseContainerItem
		only attaches while Blizzard's own Send Mail panel is visible; with it closed the
		identical call uses the item instead -- a green raises "you must be level X", and a
		consumable is simply drunk. Verifying after the call can only report the damage.
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

	--[[
		Stack size captured here, through the same shim Features/Scan-Bags.lua reads: by MAIL_SUCCESS
		the slot is stale, so a stack of 20 waters would tally as one item. It travels with the job
		to Generosity:RecordSend.
	]]
	local slotInfo = ns.GetItemInfoC(job.bag, job.slot)
	job._count = (slotInfo and slotInfo.stackCount) or 1

	--[[
		GUARDED LIKE EVERY OTHER CLIENT CALL IN THIS FUNCTION. Between busy going true and the
		result timer being armed below, a throw unwinds with busy still set and no timer to clear
		it -- a state no event recovers from, so the run is stuck until a reload. A failed attach
		and a thrown attach are the same outcome to the player, so they share one exit.
	]]
	local attached = pcall(C_Container.UseContainerItem, job.bag, job.slot) -- attaches to first open mail slot

	--[[
		A refusal can arrive as a UI error inside that call, and OnUiErrorMessage has already
		failed the job and armed the settle step that moves the run on. Carrying on here would
		finish the run a second time.
	]]
	if not self.busy or self._current ~= job then
		return
	end

	-- An attach can fail with the panel up, and SendMail posts an empty letter and reports success.
	if not attached or not (GetSendMailItem and GetSendMailItem(1)) then
		self.busy = false
		ns:PrintMessage(L["MAIL_ATTACH_FAILED"]:format(job.link))
		return self:Finish()
	end

	--[[
		AFTER THE ATTACH, NEVER BEFORE. Attaching writes the item's name into an empty subject box,
		overwriting a subject set earlier. Cosmetic only -- each box is guarded on its own, because
		a cosmetic touch must never be the thing that breaks a send.
	]]
	FillMailPanel(job)

	--[[
		Guarded for the reason the attach above is, and the attachment is released on the way out:
		the item is on the panel by this point, and abandoning the run with it still there leaves
		the player to work out why a slot looks empty.
	]]
	--[[
		From here a refusal is about the recipient, not the item: OnUiErrorMessage marks a name
		unreachable only for a job that got this far. The same in-call refusal as the attach's is
		checked for straight after.
	]]
	job._sent = true
	local sent = pcall(SendMail, job.recipient, job.subject or "", job.body or "")
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
		self:SetRunning(false)
	end)
end

--[[
	Everything else queued for a recipient who just refused a parcel: they will refuse the rest,
	and those repeats would count toward the two-error abort, so one bad name -- an alt deleted
	since it was recorded, holding every item that suits its class -- stopped the whole run.
	Released like a failure, so the rows stay listed. Not counted as skips, which Finish reports
	as items that moved in the bags; they are simply among those not sent.
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

--[[
	A delivered send: its recipient goes on cooldown and the account tally is credited, never for
	your own alt, since mailing yourself is not giving anything away.
]]
local function Credit(job)
	ns.Fairness:Record(job.recipient, job.level or 0)
	if not job.alt then
		ns.Generosity:RecordSend(job.link, job._count)
	end
end

function Distributor:Result(ok, reason, recipientOnly)
	-- A stopped or timed-out run can still have a send in flight: record it, then stay stopped.
	if not self.busy then
		local pending = self._awaiting
		self._awaiting = nil
		if pending and ok then
			Credit(pending)
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
		--[[
			Trust MAIL_SUCCESS; do not re-read the slot to "verify". MAIL_SUCCESS fires before the
			bag update, so the slot still holds the old link and every delivery reads as a skip.
		]]
		Credit(job)
		self._done = (self._done or 0) + 1
		ns:PrintMessage(L["MAIL_SENT"]:format(job.link, RecipientOf(job), self._done, self._total))
		table.remove(self.queue, 1)
		self.errors = 0
	else
		if not recipientOnly then
			self.errors = self.errors + 1
		end
		ns:PrintMessage(L["MAIL_SEND_FAILED"]:format(RecipientOf(job), reason or "?"))
		-- Before the abort check, so only a failure to somebody else can end the run.
		self:DropRepeats(job)
		if not recipientOnly and self.errors > 1 then
			ns:PrintMessage(L["MAIL_ABORTED"])
			return self:Finish()
		end
		table.remove(self.queue, 1) -- skip the problem item
	end

	if self.onProgress then
		self.onProgress(self._done, self._total, job, ok)
	end
	if ok then
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
		if not self.busy then
			self:Next()
		end
	end)
end

function Distributor:Finish()
	self.busy = false
	self:SetRunning(false)
	local done, total, skipped = self._done or 0, self._total or 0, self._skipped or 0
	-- Skips are items that moved in the bags, not failures, so they are counted apart.
	if skipped > 0 then
		ns:PrintMessage(L["MAIL_DONE_WITH_SKIPS"]:format(done, total, skipped))
	else
		ns:PrintMessage(L["MAIL_DONE"]:format(done, total))
	end
	if self.onDone then
		self.onDone(done, total, skipped)
	end
	--[[
		Push the fresh totals to nearby players right after giving. The broadcast self-throttles, so a
		run finishing soon after a login broadcast simply no-ops.
	]]
	ns.Generosity:Broadcast()
end
