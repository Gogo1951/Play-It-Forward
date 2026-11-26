local ADDON_NAME, ns = ...
local L = ns.L

local UI = ns.UI
local Kit = ns.MenuKit

--------------------------------------------------------------------------------
-- Mailbox Tab
--------------------------------------------------------------------------------

--[[
	Parented to UIParent, only anchored beside the mail window: a frame parented to a Blizzard panel
	stays protected for good, and writing to the panel taints it.
]]

UI.MAILBOX_TAB_SIZE = 40 -- Features/UI-Window.lua opens the window clear of it
local ICON_SIZE = 32
local TAB_TOP = 48 -- clear of the mail frame's title
local EDGE_SIZE = 16
local INSET = 4
local REST_DIM = 0.55

local GIFT_TEXTURE = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Includes\\Images\\Gift"
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local tab, menu

local function WindowShown()
	return UI.frame ~= nil and UI.frame:IsShown() == true
end

local function OpenWindow()
	-- UI:Open does not scan.
	ns.MatchList:EnsureScan()
	UI:Open()
end

local function ResetWindowPosition()
	if UI.ResetWindowPosition then
		UI:ResetWindowPosition()
	end
end

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

-- Laid out as Good to Go's tab menu (Style Guide → MENUS). Frame-free, so Tests/ can read the rows.
function UI:MailboxTabMenuEntries()
	local entries = {
		{ kind = "header", left = L["WINDOW_TITLE"], right = L["ADDON_SHORT_NAME"] },
		Kit.Spacer(),
		{ kind = "action", left = L["REOPEN_MENU_OPEN"], closes = true, onClick = OpenWindow },
		{ kind = "action", left = L["REOPEN_MENU_RESET_POSITION"], closes = true, onClick = ResetWindowPosition },
	}
	Kit.OptionsRow(entries, L["REOPEN_MENU_OPTIONS"]:format(L["ADDON_SHORT_NAME"]))
	return entries
end

local function BuildMenu()
	menu = Kit.CreateMenu({
		name = "PlayItForwardMailboxTabMenu",
		-- Not a mini-map menu, so it leaves ns.ShowMenu and the rest unset.
		publish = false,
		build = function()
			return UI:MailboxTabMenuEntries()
		end,
	})
end

local function ShowMenu()
	if not menu then
		BuildMenu()
	end
	menu:Show(tab, "hover")
end

-- Whether the menu is open now. For the Mailbox diagnostics report and Tests/.
function UI:MailboxTabMenuShown()
	return menu ~= nil and menu:IsShown() == true
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

-- The menu hides first: the window opens where it sits.
local function OnTabClick()
	if menu then
		menu:Hide()
	end
	if WindowShown() then
		UI:Close()
	else
		OpenWindow()
	end
	-- A check button flips itself on every click; this puts it back to what the window says.
	UI:SyncMailboxTab()
end

local function Build()
	tab = CreateFrame("CheckButton", "PlayItForwardMailboxTab", UIParent, BACKDROP_TEMPLATE)
	tab:SetSize(UI.MAILBOX_TAB_SIZE, UI.MAILBOX_TAB_SIZE)
	if tab.SetBackdrop then
		tab:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = EDGE_SIZE,
			insets = { left = INSET, right = INSET, top = INSET, bottom = INSET },
		})
		tab:SetBackdropColor(0, 0, 0, 0.9)
	end

	local icon = tab:CreateTexture(nil, "ARTWORK")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("CENTER")
	icon:SetTexture(GIFT_TEXTURE)

	local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(icon)
	highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlight:SetBlendMode("ADD")
	local checked = tab:CreateTexture(nil, "OVERLAY")
	checked:SetAllPoints(icon)
	checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	checked:SetBlendMode("ADD")
	tab:SetCheckedTexture(checked)

	tab:RegisterForClicks("LeftButtonUp")
	tab:SetScript("OnClick", OnTabClick)
	tab:SetScript("OnEnter", ShowMenu)
	tab:Hide()
end

local function Light(lit)
	tab:SetChecked(lit)
	if tab.SetBackdropBorderColor then
		local red, green, blue = ns.GetColorRGB("TITLE")
		local dim = lit and 1 or REST_DIM
		tab:SetBackdropBorderColor(red * dim, green * dim, blue * dim, 1)
	end
end

--------------------------------------------------------------------------------
-- Which mailbox window
--------------------------------------------------------------------------------

--[[
	TSM's mail window has no name and TSM_API hands out only its crafting window, so it is found by
	the file that made it (GetSourceLocation). A client without that gets no tab on TSM's window.
]]
local TSM_SOURCE = "TradeSkillMaster"

local tsmFrame
local hooked = setmetatable({}, { __mode = "k" })

local function TSMMailUp()
	if not (TSM_API and TSM_API.IsUIVisible) then
		return false
	end
	local ok, visible = pcall(TSM_API.IsUIVisible, "MAILING")
	return ok and visible == true
end

local function MadeByTSM(frame)
	if not frame.GetSourceLocation then
		return false
	end
	local ok, source = pcall(frame.GetSourceLocation, frame)
	return ok and type(source) == "string" and source:find(TSM_SOURCE, 1, true) ~= nil
end

local function FindTSMFrame()
	if tsmFrame and tsmFrame:IsShown() then
		return tsmFrame
	end
	tsmFrame = nil
	local best, bestArea = nil, 0
	for _, child in ipairs({ UIParent:GetChildren() }) do
		-- IsForbidden first: any other call on a forbidden child of UIParent is an error.
		if not child:IsForbidden() and MadeByTSM(child) and child:IsShown() then
			local area = (child:GetWidth() or 0) * (child:GetHeight() or 0)
			if best == nil or area > bestArea then
				best, bestArea = child, area
			end
		end
	end
	if best and not hooked[best] then
		-- Catches TSM's own switch to the stock mail UI and back.
		hooked[best] = true
		best:HookScript("OnShow", function()
			UI:SyncMailboxTab()
		end)
		best:HookScript("OnHide", function()
			UI:SyncMailboxTab()
		end)
	end
	tsmFrame = best
	return best
end

-- Shared so UI:Open and PlaceAtFirst put the window beside the same host, and for the Mailbox report.
function UI:MailboxTabHost()
	if not ns.AtMailbox() then
		return nil
	end
	if MailFrame and MailFrame:IsShown() then
		return MailFrame
	end
	if TSMMailUp() then
		return FindTSMFrame()
	end
	return nil
end

-- Which window the tab sits on, in words, for the Mailbox diagnostics report.
function UI:MailboxTabHostName()
	local host = self:MailboxTabHost()
	if host == nil then
		return "none"
	end
	return host == MailFrame and "Blizzard's mail window" or "TSM's mail window"
end

-- Whether the tab belongs on screen now: at a mailbox, whatever the window is doing. For the Mailbox diagnostics report.
function UI:WantsMailboxTab()
	return self:MailboxTabHost() ~= nil
end

local anchoredTo

function UI:SyncMailboxTab()
	local host = self:MailboxTabHost()
	if not tab then
		if not host then
			return
		end
		Build()
	end
	if host then
		if anchoredTo ~= host then
			tab:ClearAllPoints()
			tab:SetPoint("TOPLEFT", host, "TOPRIGHT", 0, -TAB_TOP)
			anchoredTo = host
		end
		tab:Show()
		Light(WindowShown())
	else
		tab:Hide()
	end
end

-- A mail add-on can show its window a frame or more after the mailbox reports itself.
local SETTLE = 0.5
function UI:SyncMailboxTabSoon()
	self:SyncMailboxTab()
	C_Timer.After(0, function()
		UI:SyncMailboxTab()
	end)
	C_Timer.After(SETTLE, function()
		UI:SyncMailboxTab()
	end)
end

function UI:MailboxTabShown()
	return tab ~= nil and tab:IsShown() == true
end

-- Whether the tab is lit for an open window. For Tests/.
function UI:MailboxTabLit()
	return tab ~= nil and tab:GetChecked() == true
end
