local _, ns = ...
local L = ns.L

local UI = ns.UI
local MatchList = ns.MatchList

--[[
	The mail window's Distribute button and status line, and which rows can be ticked: what the
	player can do next, derived from the match list and the mailbox. Features/UI-Window.lua calls
	UI:SyncDistributeButton after every redraw.
]]

--[[
	Dead unless pressing it would send something: a mailbox open, because Mail-Sender cannot attach
	without Blizzard's Send Mail panel, and a row ticked with somebody on it. The mailbox is the
	one named on the button, being the condition the player fixes by walking.

	Reads ns.AtMailbox, never ns.mailboxOpen: MAIL_CLOSED does not fire on every way out, and a
	stale flag here is exactly the live button on a closed mailbox this guards against.
]]
function UI:SyncDistributeButton()
	if not (self.frame and self.frame.distributeButton) then
		return
	end
	-- Every change the button follows changes the status line too.
	self:SyncStatus()
	local button = self.frame.distributeButton

	if not ns.AtMailbox() then
		button:SetText(L["BUTTON_NEEDS_MAILBOX"])
		button:Disable()
		return
	end

	-- Back to Distribute at every pause, which is when the chat lines tell the player to press it.
	if ns.Distributor:IsRunning() then
		button:SetText(L["BUTTON_SENDING"])
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

-- False for an unreadable or leftover row nobody holds: a search never fills one, so its tick can send nothing.
function UI:CanTick(item)
	if item.recipient then
		return true
	end
	return item.state ~= ns.Matcher.UNREADABLE and item.state ~= ns.Matcher.LEFTOVER
end

--[[
	The status line's words, off the frame so Tests/Status-Line.lua can read them. The first case
	that holds wins: a run going out, then rows still waiting on a search, then rows ready to send,
	then Kept gear with Disenchant off, which only that switch can send anywhere. Unticked rows
	count for nothing: the player is keeping them, and a row they set to Keep Item by hand is
	never nagged about.
]]
function UI:StatusLine()
	local mailer = ns.Distributor
	if mailer:IsRunning() then
		return L["STATUS_SENDING"]:format((mailer._done or 0) + 1, mailer._total or 0)
	end
	local waiting, ready = 0, 0
	for _, item in ipairs(MatchList:Items()) do
		if item.send and item.recipient then
			ready = ready + 1
		elseif item.send and item.state == ns.Matcher.GIFT then
			waiting = waiting + 1
		end
	end
	if waiting > 0 then
		if not self:HasSearched() then
			return L["STATUS_START"]:format(waiting)
		end
		local remaining = ns.Who:Remaining()
		if remaining > 0 then
			return L["STATUS_MORE"]:format(remaining)
		end
		return L["STATUS_DONE"]:format(waiting)
	end
	if ready > 0 then
		return (ns.AtMailbox() and L["STATUS_READY"] or L["STATUS_AWAY"]):format(ready)
	end
	if not (ns.db and ns.db.profile.disenchantUnmatched) then
		for _, item in ipairs(MatchList:Items()) do
			if MatchList:Disenchantable(item) and not item.pinned then
				return L["STATUS_KEPT_DISENCHANT"]
			end
		end
	end
	return ""
end

function UI:SyncStatus()
	if self.frame and self.frame.statusText then
		self.frame.statusText:SetText(self:StatusLine())
	end
end
