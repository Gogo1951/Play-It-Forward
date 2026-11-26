local _, ns = ...
local L = ns.L

local UI = ns.UI
local MatchList = ns.MatchList

--[[
	The mailbox is the condition named on the button, the one the player fixes by walking. Reads
	ns.AtMailbox, never ns.mailboxOpen: MAIL_CLOSED does not fire on every way out.
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

	-- A pressed Stop stays dead while the letter in hand finishes.
	if ns.Distributor:IsRunning() then
		button:SetText(L["BUTTON_STOP"])
		if ns.Distributor:StopRequested() then
			button:Disable()
		else
			button:Enable()
		end
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
	Frame-free for Tests/Status-Line.lua; the first case that holds wins. Unticked rows count for
	nothing, so a row set to Keep Item by hand is never nagged about.
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
	local stopped = mailer:Stopped()
	if stopped and ready > 0 then
		return L["MAIL_STOPPED"]:format(stopped.done, stopped.total)
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
		if not ns.AtMailbox() then
			return L["STATUS_AWAY"]:format(ready)
		end
		return L["STATUS_READY"]:format(ready)
	end
	if not (ns.db and ns.db.profile.disenchantUnmatched) then
		for _, item in ipairs(MatchList:Items()) do
			if MatchList:Disenchantable(item) and not item.pinned then
				return L["STATUS_KEPT_DISENCHANT"]
			end
		end
	end
	local sent = mailer:Sent()
	if #sent > 0 then
		return L["MAIL_DONE"]:format(#sent, #sent)
	end
	return ""
end

function UI:SyncStatus()
	if self.frame and self.frame.statusText then
		self.frame.statusText:SetText(self:StatusLine())
	end
end
