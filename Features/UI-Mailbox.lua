local _, ns = ...
local L = ns.L

local UI = ns.UI

local MatchList = ns.MatchList
local Picker = ns.Picker

--[[
	The mailbox lifecycle: finding recipients, handing the list to the mailer, and the open/close
	behavior around a mailbox. Features/UI-Window.lua owns the frame itself and
	Features/UI-Assignment.lua everything the player edits by hand; all three extend the one
	ns.UI table, so this file loads after them.
]]

--------------------------------------------------------------------------------
-- Recipient Finding
--------------------------------------------------------------------------------

--[[
	Free candidates next to a /who -- no button press, and none of the /who throttle -- so this runs
	on its own rather than being spent from the search plan. The client throttles GuildRoster
	itself: a request it drops is answered by the next GUILD_ROSTER_UPDATE instead. The answer lands on GUILD_ROSTER_UPDATE some
	frames later, which is why it re-assigns rather than returning anything.
]]
local function PullGuild()
	-- Your other characters' guilds, as saved: no server round trip, so they join at once.
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

--[[
	Your own characters, read from what each recorded at its last login: no server round trip, so
	this assigns at once rather than waiting on an answer the way the roster does.
]]
local function PullAlts()
	if MatchList:AddResults(ns.Alts:Read()) > 0 then
		UI:Assign()
	end
end

--[[
	Whether Find Recipients has been pressed since the window opened. Until it has, nothing is
	matched: the roster found earlier in the session is kept, but a list opened on yesterday's
	pairings reads as a search that already happened. Cleared when the window closes.
]]
local matching = false

-- SendWho only fires from a real button press, so this is a stepper: one press, one query.
function UI:FindRecipients()
	Picker:Close()

	-- Mid-plan only once matching has started: a plan a rescan left standing is not a press.
	if matching and ns.Who:Remaining() > 0 then
		return self:Step()
	end
	matching = true

	--[[
		Only on a fresh plan, not on every press that steps one: the roster costs no press but does
		cost a walk of every member with a last-online call apiece, and cannot change much in five
		seconds.
	]]
	PullGuild()
	PullAlts()

	--[[
		Pools are deliberately not wiped: one query returns at most ~49 people, so pressing again
		adds to the roster. Nothing empties it inside a session; it dies with the session.

		The query goes out before anything is matched, so every press is a fresh search: matching
		first would prune the plan to whatever the saved names left uncovered, often nothing. Its
		answer matches against the whole roster, saved names included.
	]]
	local bands = MatchList:RescanBags()
	if #bands == 0 then
		self:Assign()
		return
	end

	ns.Who:Plan(bands)
	self:Step()
end

--[[
	Whether a query has gone out since the window opened, for the status line: before one, it says
	which button comes first. Cleared with the plan when the window closes.
]]
local searched = false

function UI:HasSearched()
	return searched
end

function UI:Step()
	local sent = ns.Who:Step(function(results)
		--[[
			nil results: a query that never answered, back on the plan. Matched anyway, from the
			names already found, so a lost answer does not leave the press showing nothing.
		]]
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
		-- Nothing went out, so no answer will match: match from the names already found.
		self:Assign()
	end
	self:SyncFindButton()
end

--[[
	Held for the full throttle rather than until the answer arrives: a reply often lands in under
	a second, and re-enabling then offers a press the server refuses for another four. Reads
	Who.THROTTLE rather than a five written here, so the lock cannot undercut the rule it reflects.
]]
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
	The first press of a targeted search for this item alone, from the bottom of its dropdown --
	for when the names on offer are not good enough. It asks who this item is actually for and
	goes looking for exactly them: the zones that fit the item's band first, then one class per
	press anywhere in the world, best fit first. Matcher:TargetedBands makes "of the Bear" plate
	a c-"Warrior" query before a c-"Paladin" one.

	It RETASKS the plan: whatever the previous plan still held is dropped for this item's
	attempts. Find Recipients steps the rest; every answer drops the attempts that could only turn
	up somebody who ties or loses to the row's holder, and the search ends when none is left
	(MatchList:Assign). The next fresh press rebuilds the full
	plan for every item. Runs off the picker click, which is the hardware event SendWho demands.
]]
function UI:FindRecipientsForItem(item)
	local verdict = item.verdict or ns.Matcher:VerdictFor(item)
	if #((verdict and verdict.eligible) or {}) == 0 then
		return
	end
	--[[
		Asked before retasking, never after: a press that cannot send now would drop the plan
		standing and cancel the query in flight, then sit silent until the next Find Recipients.
	]]
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
	Puts the button's one name back once the Searching lock is up. ONE NAME, whatever the plan
	holds: chat lines such as WHO_BLOCKED tell the player to press Find Recipients, so a second
	label for a mid-plan press would leave them looking for a button that is not on screen.

	Silent while the lock is up, or the callback would put a live-looking label on a dead button.
]]
function UI:SyncFindButton()
	-- Before the lock check: the line says how many searches are left even while the button waits.
	self:SyncStatus()
	if searchTimer then
		return
	end
	self.frame.findButton:SetText(L["BUTTON_FIND_RECIPIENTS"])
end

--[[
	The allocation is Features/Match-List.lua's; putting it on screen is what belongs here. Before
	Find Recipients this window only redraws: a hand pick or a rescan must not match the rest.
]]
function UI:Assign()
	if matching then
		MatchList:Assign()
	end
	self:Refresh()
	self:SyncFindButton()
end

--[[
	A rescan must re-plan: the level bands the plan was built from are exactly what a giftability
	setting changes. Pools are untouched, so nobody already found is lost.

	Plan before assigning. Assign clears the plan once no gift is left unmatched, so this order
	lets it drop a plan that turned out unnecessary; the other would leave a plan standing that
	nothing is searching for.

	With no frame built there is nothing to re-read into, so the scan is only marked stale for
	the next mailbox -- or, standing at one that opened on nothing, read now and the window
	opened if the new setting turned something up.
]]
function UI:Rescan()
	if not self.frame then
		MatchList:MarkStale()
		self:OpenIfWaiting()
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

	--[[
		One mail per person per run, enforced rather than merely intended: MatchList:Assign already holds to
		it, but two greens in one stranger's mailbox reads as spam and cannot be taken back. Your own
		alts are exempt, and so is a row the player set by hand: their choice always stands.
	]]
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
					-- Your own alt: no Generosity credit for mailing yourself.
					alt = item.recipient.alt,
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

--[[
	By the uid it was mailed under: two copies of one green share a name and a link, so matching
	on anything less removes whichever the loop reached first.
]]
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
	ONLY WHEN THE NAME ITSELF IS THE PROBLEM. A plain MAIL_FAILED can be a full mailbox or a bad
	moment on the server, and the pairing may have been set by hand: discarding that choice because
	one send bounced is a second failure. The item stays on the list either way.
]]
function UI:ReleaseRecipient(job)
	local item = MatchList:FindByKey(job.uid or "")
	if item and item.recipient and not ns.Fairness:IsReachable(item.recipient.name) then
		-- Still ticked and back to auto-assignment: the player never unticked it.
		MatchList:AssignedTo()[item.recipient.name] = nil
		item.recipient, item.send, item.pinned = nil, true, false
	end
	self:Refresh()
end

--[[
	Deliberately does not re-read the bags: the client is still emptying the slots, so a scan here
	could only put delivered items back. BAG_UPDATE marks the scan stale and the next mailbox picks
	them up. Re-assigning is worth it: every recipient just went on cooldown.
]]
function UI:AfterDelivery()
	if not self.frame then
		return
	end
	self:Assign()
end

--------------------------------------------------------------------------------
-- Auto-open at the mailbox
--------------------------------------------------------------------------------

--[[
	Set when a mailbox opens on nothing to give, cleared when the window opens or the mailbox
	closes. The window opens at most once a visit by this route: a player who closed it at the
	mailbox has answered, and a bag change must not put it back.
]]
local waitingToOpen = false

-- It does not scan: every caller had to read the bags to decide whether to call this at all.
function UI:Open()
	waitingToOpen = false
	self:BuildFrame()
	self.frame:Show()

	--[[
		Not matched on open: closing let the automatic names go (UI:OnClosed), and they come back
		only on Find Recipients, matched from everyone found this session plus whoever that press
		finds. The status line asks for the press. Hand picks are pinned and show as they were.

		The guild and your alts are still read in, since they cost no press: the dropdown offers
		them for a hand pick, and UI:Assign leaves them unpaired until the press.
	]]
	PullGuild()
	PullAlts()
	self:Refresh()
	self:SyncReopenButton()
end

--[[
	Closing is manual: the X, or Escape. Nothing else hides this window.

	Both routes land in UI:OnClosed rather than here, because Escape reaches the frame through
	UISpecialFrames and never touches this function -- see the registration in
	Features/UI-Window.lua. This is left as the name every caller already knows.
]]
function UI:Close()
	Picker:Close()
	if not self.frame then
		return
	end
	self.frame:Hide()
	-- Called here as well as from OnHide, for the window that was closed without ever being shown.
	self:OnClosed()
end

--[[
	Everything that has to stop when the window goes away, wherever the close came from. Every line
	is idempotent, which is what lets both routes call it: Escape arrives through OnHide, the X
	through UI:Close, and a press of the X runs both.
]]
function UI:OnClosed()
	if not self.frame then
		return
	end
	Picker:Close()
	ns.Distributor:Stop()
	ns.Who:Clear() -- a half-finished query plan is stale
	--[[
		The automatic names go too, and nothing is matched again until the next Find Recipients;
		the roster behind them is kept for the session, and so is every hand pick.
	]]
	MatchList:ReleaseAutomatic()
	matching = false
	searched = false
	self:SyncFindButton()
	self:SyncReopenButton()
end

--[[
	NEVER HOOK MailFrame's OnHide TO CLOSE THIS WINDOW. TSM and other mail replacements hide
	MailFrame and show their own, killing this window the instant it opens -- and any UIPanel
	the client raises can swap MailFrame out from under it (the Who panel would, which is why
	Features/Recipients-Who.lua deafens it for the life of a query).

	So it opens on the mailbox and never auto-closes. Match-List holds items, roster and pairings
	at file scope, so matches survive walking away. On the module so the Mailbox diagnostics report
	asks the same question the mailbox does. Unticked rows do not count: a mailbox holding only
	rows the player is keeping opens nothing. Kept gear counts while Disenchant Unmatched Items has
	an enchanter to send it to.
]]
function UI:HasSomethingToDo()
	local enchanter = ns.db.profile.disenchantUnmatched and ns.Alts:Disenchanter()
	for _, item in ipairs(MatchList:Items()) do
		local disenchant = enchanter and MatchList:Disenchantable(item)
		if item.send and (item.recipient or item.state == ns.Matcher.GIFT or disenchant) then
			return true
		end
	end
	return false
end

--[[
	Nothing to hand out means nothing happens, and nothing is said: no spare gear is the ordinary
	state of a mailbox visit.
]]
--[[
	ONCE A VISIT. MAIL_SHOW, MailFrame's OnShow and the interaction manager all report one
	mailbox, and the sender's own MailFrame:Show mid-run reports it again; a mail add-on handing
	the frame back is one more. Handled once, a player who closed the window at this mailbox is
	not handed it back, and the roster is asked for once. Cleared when the mailbox is gone.
]]
local visitHandled = false

local function MailboxOpened()
	ns.mailboxOpen = true
	if visitHandled or ns.Distributor.busy then
		UI:SyncReopenButton()
		return
	end
	visitHandled = true
	MatchList:EnsureScan()
	if UI:HasSomethingToDo() then
		UI:Open()
	elseif not (UI.frame and UI.frame:IsShown()) then
		waitingToOpen = true
	end
	UI:SyncReopenButton()
end

--[[
	Asked of the interaction manager as well as the flag: MAIL_CLOSED skips Escape on Era, so the
	flag alone could outlive the mailbox and open the window on a loot out in the world.
]]
function UI:WaitingToOpen()
	return waitingToOpen and ns.AtMailbox()
end

-- A late answer for a mailbox that opened on nothing: an item resolving, or a setting changing.
function UI:OpenIfWaiting()
	if not self:WaitingToOpen() then
		return
	end
	MatchList:EnsureScan()
	if self:HasSomethingToDo() then
		UI:Open()
	end
end

--[[
	The window outlives the mailbox, so the button follows the mailbox, not the window.

	Deferred a frame rather than read inline: the mailbox closing and the interaction manager
	reporting it ended are not guaranteed to land in that order, and UI:SyncDistributeButton asks the
	manager. Reading it too early answers for the mailbox that is still closing and leaves the
	button live -- the exact state this exists to clear.
]]
local function RecheckDistribute()
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
		--[[
			Gone from the mailbox, whether or not MAIL_CLOSED said so: a send still awaiting its
			result is not one the next visit waits on, and the next open is a new visit.
		]]
		if not ns.AtMailbox() then
			ns.Distributor._awaiting = nil
			visitHandled = false
		end
		if UI.frame and UI.frame:IsShown() then
			UI:SyncDistributeButton()
		end
		UI:SyncReopenButton()
	end)
end

local function MailboxClosed()
	ns.mailboxOpen = false
	waitingToOpen = false
	visitHandled = false
	RecheckDistribute()
end

--[[
	Track the mailbox, not its frame: MailFrame:IsShown reports wrongly under TSM and while the
	Who panel is up, and this flag is what Distributor gates on.
]]
local function OnPlayerLogin()
	if MailFrame then
		MailFrame:HookScript("OnShow", MailboxOpened)
		--[[
			A prompt to re-check, NOT a claim the mailbox closed, and deliberately not
			MailboxClosed: this frame hides spuriously, and flipping ns.mailboxOpen on that would
			lie to the Distributor.

			Here because MAIL_CLOSED does not fire on every way out -- Escape and another add-on
			closing the frame both skip it, and on Era the interaction-manager events are not
			registered. A spurious hide costs one re-check that changes nothing.
		]]
		MailFrame:HookScript("OnHide", RecheckDistribute)
		-- Read by the Mailbox diagnostics report: no MailFrame at login means no hooks all session.
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

if ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot" then
	-- TBC and later, and Forever's Retail client: the interaction manager reports the mailbox as well.
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
