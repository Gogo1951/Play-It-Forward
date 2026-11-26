local ADDON_NAME, ns = ...
local L = ns.L

local UI = ns.UI
local Kit = ns.MenuKit

--------------------------------------------------------------------------------
-- Mailbox Tab
--------------------------------------------------------------------------------

--[[
	A square tab with the add-on's gift on the right edge of Blizzard's mail frame, or of TSM's mail
	window in its place, at every mailbox, the way Recipe Master hangs one off the profession window. The window never opens by
	itself: a click on the tab opens it beside the tab, a second click closes it, and the tab is lit
	while the window is up. With nothing to give, the tab is still there, and the window says so.

	PARENTED TO UIParent AND ANCHORED BESIDE the mail window, never parented to it and never
	writing to it: a frame parented to a Blizzard panel stays protected for good, and anything
	written to the panel taints it. Shown only while that window is, since it reads as part of it.
]]

UI.MAILBOX_TAB_SIZE = 40 -- Features/UI-Window.lua opens the window clear of it
local ICON_SIZE = 32
local TAB_TOP = 48 -- down from the mail frame's top, clear of its title
local EDGE_SIZE = 16
local INSET = 4
-- The border at rest: the title gold, dimmed, so the lit tab stands out against it.
local REST_DIM = 0.55

local GIFT_TEXTURE = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Includes\\Images\\Gift"
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local tab, menu

local function WindowShown()
	return UI.frame ~= nil and UI.frame:IsShown() == true
end

local function OpenWindow()
	-- UI:Open does not read the bags itself; every other caller already had.
	ns.MatchList:EnsureScan()
	UI:Open()
end

-- Back beside the mail frame at its first size. Features/UI-Window.lua owns the window's place.
local function ResetWindowPosition()
	if UI.ResetWindowPosition then
		UI:ResetWindowPosition()
	end
end

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

--[[
	The mouse over the tab opens a small Menu-Kit menu off its corner (Style Guide → MENUS), laid out
	as Good to Go's tab menu is: the window it opens as the header, gold, with the Short Name muted on
	the right; the row that opens the window and the one that puts it back in its first place; then
	the footer naming whose options open ("Play It Forward Options"). Read by Tests/ through
	UI:MailboxTabMenuEntries, so the rows can be checked without a frame.
]]
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

-- A click opens the window, or closes it when it is up. The menu goes first: the window opens where it sits.
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

	-- The game's own square highlight under the mouse, and its gold glow while the window is up.
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

-- The border lights up with the window: full gold while it is up, dimmed at rest.
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
	TSM's mail window replaces Blizzard's and hides it, and it has no name: TSM's public API
	(TSM_API) says only whether it is up, and hands out its crafting window alone, which is how
	Recipe Master's tab finds TSM. So the tab finds TSM's window the way /fstack does, by the file
	that created it: the direct child of UIParent, shown, made from a TradeSkillMaster file, the
	largest if there are several. Only asked while TSM says its mail window is up.

	GetSourceLocation is the client's own answer to where a frame was made. A client without it
	finds nothing here, and the tab stays off TSM's window there.
]]
local TSM_SOURCE = "TradeSkillMaster"

local tsmFrame -- the last TSM window found, kept while it is shown
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
		--[[
			IsForbidden FIRST: UIParent holds frames the game locks away from add-ons (the shop,
			Edit Mode's dialogs), and any other call on one of those is an error.
		]]
		if not child:IsForbidden() and MadeByTSM(child) and child:IsShown() then
			local area = (child:GetWidth() or 0) * (child:GetHeight() or 0)
			if best == nil or area > bestArea then
				best, bestArea = child, area
			end
		end
	end
	if best and not hooked[best] then
		-- Follows TSM's window shown and hidden, its WoW UI and TSM buttons included, without asking again.
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

--[[
	The mailbox window the tab sits on now: Blizzard's while it is up, else TSM's, else none. On
	the module so Features/UI-Mailbox.lua opens the window beside the same one, and for the
	Mailbox diagnostics report.
]]
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

--[[
	A mail add-on can put its own window up a frame or two after the mailbox reports itself, so
	the tab asks again next frame and once more a moment later. Each pass is cheap once a window
	is found.
]]
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
