local _, ns = ...
local L = ns.L

ns.Distributor = {}
local Dist = ns.Distributor

--[[
	Serialized, event-driven mailer. SendMail cannot be looped: one send goes out, then the run
	waits for MAIL_SUCCESS or MAIL_FAILED before advancing. Mailing a non-friend arms
	Blizzard's "might be someone you don't know" confirm, the anti-spam guard for mailing
	strangers, and it is never auto-clicked.
]]

--[[
	Display only. Never for the SendMail call itself: that takes the bare name, and an escape
	sequence in it would address the letter to nobody.
]]
local function recipientOf(job)
	return ns.ColorName(job.recipient, job.class)
end

--[[
	The body box, under whichever name this client keeps it. SendMailBodyEditBox is the retail
	name; Classic keeps the body behind MailEditBox:GetEditBox(), and on 1.15.8 the retail
	global is nil, so the To and Subject boxes fill while the body stays empty. Picked by
	availability, never by flavour. Display only -- SendMail never reads these boxes.
]]
local function mailBodyBox()
	if MailEditBox and MailEditBox.GetEditBox then
		local ok, box = pcall(MailEditBox.GetEditBox, MailEditBox)
		if ok and box then
			return box
		end
	end
	return SendMailBodyEditBox
end

local function fillMailPanel(job)
	local function fill(box, text)
		if box and box.SetText then
			pcall(box.SetText, box, text or "")
		end
	end
	fill(SendMailNameEditBox, job.recipient)
	fill(SendMailSubjectEditBox, job.subject)
	fill(mailBodyBox(), job.body)
end

local MAIL_COST = 30 -- copper per mail
local RESULT_TIMEOUT = 30 -- seconds to wait on a confirm/result before pausing
local SUBJECT_MAX = 31 -- what the mail window's own edit boxes accept
local BODY_MAX = 500

Dist.busy = false
Dist.queue = {}
Dist.errors = 0
Dist.onProgress = nil -- optional UI callback(done, total, job, ok)
Dist.onDone = nil -- optional UI callback(done, total, skipped)

ns.on("MAIL_SUCCESS", function()
	Dist:_result(true)
end)
ns.on("MAIL_FAILED", function()
	Dist:_result(false, "failed")
end)

--[[
	Every mail refusal the client knows about, collected from its own ERR_MAIL* strings rather
	than listed, because a list would be a guess and a hardcoded English sentence would never
	fire on another locale. Strings carrying a format specifier are skipped -- they arrive with
	the placeholder filled in, so an exact comparison never matches. A skipped error is a
	missed catch, never a wrong one.
]]
local mailErrors
local function isMailError(message)
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
	end
	return mailErrors[message] ~= nil
end

--[[
	A refusal the server reports as a UI error rather than MAIL_FAILED: SendMail can be
	rejected without either result event, leaving the run to sit out its full timeout over an
	item that never left the bag. Guarded on a send being in flight and on the message being
	one of the client's own mail errors, since UI_ERROR_MESSAGE carries everything from
	standing too far away to a full inventory.
]]
ns.on("UI_ERROR_MESSAGE", function(_, message)
	if not Dist.busy or not Dist._current then
		return
	end
	if not isMailError(message) then
		return
	end
	-- A name the server will not take now will not start working later in the same session.
	ns.Fairness:MarkUnreachable(Dist._current.recipient)
	Dist:_result(false, message)
end)

-- job = { bag, slot, link, recipient, level, class, subject, body }
function Dist:Start(jobs)
	if self.busy then
		ns:PrintWarning(L["MAIL_STILL_SENDING"])
		return
	end
	self.queue = jobs or {}
	self.errors = 0
	self._total = #self.queue
	self._done = 0
	self._skipped = 0
	self._awaiting = nil
	if #self.queue == 0 then
		ns:PrintMessage(L["MAIL_NOTHING_TO_DISTRIBUTE"])
		return
	end
	ns:PrintMessage(L["MAIL_DISTRIBUTING"]:format(#self.queue))
	self:WarnIfOversized()
	self:_next()
end

function Dist:Stop()
	--[[
		A send already in flight still lands, so its result event is still coming. Holding the
		job is what lets _result put its recipient on cooldown even though the run is over.
	]]
	if self.busy then
		self._awaiting = self._current
	end
	self.busy = false
	wipe(self.queue)
	if self._timer then
		self._timer:Cancel()
		self._timer = nil
	end
end

function Dist:_next()
	if self.busy then
		return
	end

	-- Bag slots shift between matching and sending; a stranger receives whatever slid in.
	while self.queue[1] do
		local candidate = self.queue[1]
		if ns.GetItemLink(candidate.bag, candidate.slot) == candidate.link then
			break
		end
		ns:PrintWarning(L["MAIL_ITEM_MOVED"]:format(candidate.link))
		self._skipped = (self._skipped or 0) + 1
		table.remove(self.queue, 1)
	end

	local job = self.queue[1]
	if not job then
		return self:_finish()
	end

	--[[
		Gate on the mailbox, never on MailFrame being visible: TSM replaces the mail UI and the
		Who panel swaps MailFrame out, so IsShown reports "closed" at a live mailbox.
	]]
	if not ns.AtMailbox() then
		ns:PrintWarning(L["MAIL_NOT_AT_MAILBOX"])
		return
	end
	if GetMoney() < MAIL_COST then
		ns:PrintWarning(L["MAIL_NO_POSTAGE"])
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
		ns:PrintWarning(L["MAIL_PANEL_CLOSED"])
		ns:PrintWarning(L["MAIL_PANEL_CLOSED_HINT"])
		return self:_finish()
	end

	if ClearSendMail then
		pcall(ClearSendMail)
	end
	ns.UseItem(job.bag, job.slot) -- attaches to first open mail slot

	--[[
		An attach can fail with the panel up, and SendMail does not care: it posts an empty
		letter and reports success. Never send without a confirmed attachment.
	]]
	if not (GetSendMailItem and GetSendMailItem(1)) then
		self.busy = false
		ns:PrintWarning(L["MAIL_ATTACH_FAILED"]:format(job.link))
		return self:_finish()
	end

	--[[
		Cosmetic: the panel cannot be hidden (see the check above), and an empty To field over
		an empty body reads as a form waiting to be typed into rather than a mail being sent.

		AFTER THE ATTACH, NEVER BEFORE. Attaching writes the item's name into an empty subject
		box, overwriting a subject set earlier. Each box is guarded on its own, because a
		cosmetic touch must never be the thing that breaks a send.
	]]
	fillMailPanel(job)

	SendMail(job.recipient, job.subject or "", job.body or "")

	-- Wait for MAIL_SUCCESS/FAILED, or pause if the player hasn't confirmed.
	self._timer = C_Timer.NewTimer(RESULT_TIMEOUT, function()
		self._timer = nil
		-- SendMail has already fired, so a late Accept still delivers: hold the job as Stop does.
		self._awaiting = self._current
		self.busy = false
		ns:PrintWarning(L["MAIL_AWAITING_CONFIRM"]:format(recipientOf(job)))
	end)
end

function Dist:_result(ok, reason)
	--[[
		A stopped or timed-out run can still have one send in flight, arriving with busy already
		false. Record that recipient, then stay stopped.
	]]
	if not self.busy then
		local pending = self._awaiting
		self._awaiting = nil
		if pending and ok then
			ns.Fairness:Record(pending.recipient, pending.level or 0)
			-- It delivered, so drop it before a resume retries an already-empty slot.
			if self.queue[1] == pending then
				table.remove(self.queue, 1)
			end
			--[[
				And tell the window: without this the row sits there matched and ticked, and
				pressing Distribute again only earns a "moved in your bags" skip.
			]]
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
			Trust MAIL_SUCCESS: the attachment was confirmed before sending. Do not re-read the
			slot to "verify" -- MAIL_SUCCESS fires before the bag update, so the slot still
			holds the old link and every delivery would read as a skip that never reaches
			Record.
		]]
		ns.Fairness:Record(job.recipient, job.level or 0)
		self._done = (self._done or 0) + 1
		ns:PrintMessage(L["MAIL_SENT"]:format(job.link, recipientOf(job), self._done, self._total))
		table.remove(self.queue, 1)
		self.errors = 0
	else
		self.errors = self.errors + 1
		ns:PrintWarning(L["MAIL_SEND_FAILED"]:format(recipientOf(job), reason or "?"))
		if self.errors > 1 then
			ns:PrintWarning(L["MAIL_ABORTED"])
			return self:_finish()
		end
		table.remove(self.queue, 1) -- skip the problem item
	end

	if self.onProgress then
		self.onProgress(self._done, self._total, job, ok)
	end
	self:_next()
end

function Dist:_finish()
	self.busy = false
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
end

--[[
	No chat preview: the text is fixed in Locales/enUS.lua and nobody can have changed it. The
	Diagnostic Tools panel has "Preview What Strangers Receive" on demand instead. This check
	cannot fire on the shipped English, which Tests/Mail-Contents.lua holds under the cap, but
	a translation of the same paragraphs can run longer.
]]
function Dist:WarnIfOversized()
	local subject, body = self:BuildSubject(), self:BuildBody()

	-- Silent truncation would mean sending something nobody has read.
	if #subject > SUBJECT_MAX then
		ns:PrintWarning(L["MAIL_SUBJECT_TOO_LONG"]:format(#subject, SUBJECT_MAX))
	end
	if #body > BODY_MAX then
		ns:PrintWarning(L["MAIL_BODY_TOO_LONG"]:format(#body, BODY_MAX))
	end
end

--[[
	Fixed text from Locales/enUS.lua rather than saved settings, so what a stranger receives
	cannot drift per profile or be rewritten into something this add-on would not have sent.
]]
function Dist:BuildSubject()
	return L["MAIL_SUBJECT"]
end

function Dist:BuildBody()
	return L["MAIL_BODY"]
end
