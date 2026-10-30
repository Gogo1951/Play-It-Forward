local _, ns = ...
local L = ns.L

local UI = ns.UI

--------------------------------------------------------------------------------
-- Reopen Button
--------------------------------------------------------------------------------

--[[
	A button hanging off the top right of Blizzard's mail frame while a mailbox is open and the
	window is not: the way back for a player who closed the window here, or whose mailbox listed
	nothing, without walking away and opening the mailbox again.

	PARENTED TO UIParent AND ANCHORED BESIDE MailFrame, never parented to it and never writing to
	it: a frame parented to a Blizzard panel stays protected for good, and anything written to the
	panel taints it. Shown only while MailFrame is, since it reads as part of that frame.
]]

local PADDING = 24

local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")

local button

local function Build()
	button = CreateFrame("Button", "PlayItForwardReopenButton", UIParent, "UIPanelButtonTemplate")
	button:SetText(L["ADDON_TITLE"])
	button:SetSize(button:GetFontString():GetStringWidth() + PADDING, 22)
	button:GetFontString():SetTextColor(ns.GetColorRGB("TITLE"))
	button:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, -4)
	button:SetScript("OnClick", function()
		-- UI:Open does not read the bags itself; every other caller already had.
		ns.MatchList:EnsureScan()
		UI:Open()
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["ADDON_TITLE"], ns.GetColorRGB("TITLE"))
		GameTooltip:AddLine(L["REOPEN_TOOLTIP"], BODY_R, BODY_G, BODY_B, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	ns.SkinWidget("Button", button)
	button:Hide()
end

-- Whether the button belongs on screen now. On the module for the Mailbox diagnostics report.
function UI:WantsReopenButton()
	if not (MailFrame and MailFrame:IsShown()) then
		return false
	end
	if not ns.AtMailbox() then
		return false
	end
	return not (self.frame and self.frame:IsShown())
end

function UI:SyncReopenButton()
	local wanted = self:WantsReopenButton()
	if not button then
		if not wanted then
			return
		end
		Build()
	end
	if wanted then
		button:Show()
	else
		button:Hide()
	end
end

function UI:ReopenButtonShown()
	return button ~= nil and button:IsShown() == true
end
