local _, ns = ...
local L = ns.L

local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

--[[
	The mailbox lifecycle: finding recipients, handing the list to the mailer, and the open/close
	behavior around a mailbox. Features/UI-Window.lua owns the frame itself and everything the
	player edits by hand; both halves extend the one ns.UI table, so this file loads after it.
]]

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
	One press of a targeted search over this item's band alone, from the bottom of its
	dropdown -- for when the names on offer are not good enough. It RETASKS the plan: whatever
	the previous plan still held is dropped for this item's attempts, and the next fresh press
	of Find Recipients rebuilds the full plan for every item. Runs off the picker click, which
	is the hardware event SendWho demands.
]]
function UI:FindRecipientsForItem(item)
	local verdict = item.verdict or ns.Matcher:VerdictFor(item)
	local eligible = (verdict and verdict.eligible) or {}
	if #eligible == 0 then
		return
	end
	ns.Who:Plan({
		{
			lo = item.bandLo,
			hi = item.bandHi,
			-- Admitted, not contenders: the point is more names to choose from by hand.
			classes = (#verdict.admitted > 0) and verdict.admitted or eligible,
		},
	})
	self:_step()
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
	UI:_buildFrame()
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
	local f = self:_buildFrame()
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
	NEVER HOOK MailFrame's OnHide TO CLOSE THIS WINDOW. TSM and other mail replacements hide
	MailFrame and show their own, killing this window the instant it opens -- and any UIPanel
	the client raises can swap MailFrame out from under it (the Who panel would, which is why
	Features/Recipients-Who.lua deafens it for the life of a query).

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
