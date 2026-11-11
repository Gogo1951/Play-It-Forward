local ADDON_NAME, ns = ...
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

local PADDING = 32

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

--[[
	The mouse over the button opens a small menu under it, laid out as Pretty Wide Quest Log's Quest
	Arrow menu is (Menus, Not Tooltips): a dark plate with angled corners, a header with the menu's
	name on the left in the title color, then a row for each thing to do. The header's right side
	would carry the add-on's Short Name, muted, but here the menu is named for the add-on itself, so
	it is left empty rather than saying the same words twice. A click on the button still opens the
	window. The menu stays while the mouse is on the button or the menu, closes CLOSE_DELAY after it
	leaves both, and closes on Escape or whenever the button hides.
]]

local PLATE_TEXTURE = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Includes\\Images\\Menu-Plate"
local PLATE_SIZE = 128
local PLATE_MARGIN = { left = 12, right = 12, top = 10, bottom = 14 }
local PLATE_CORNER = 32
local PLATE_SCALE = 0.5
local PLATE_ALPHA = 0.8

local LINE = 4 -- above and below a row's text
local NEAR = 8 -- the plate's own padding, a divider's height, and the gap under the button
local GROUP = 16 -- between a row's two sides
local CLOSE_DELAY = 0.25
local MIN_WIDTH = 128
local HIGHLIGHT_ALPHA = 0.16

local button, menu

-- Nine pieces: the corners at their own size, keeping the angle and shadow, the edges and middle stretched.
local function AddPlate(panel)
	local plate = CreateFrame("Frame", nil, panel)
	plate:SetPoint("TOPLEFT", -PLATE_MARGIN.left * PLATE_SCALE, PLATE_MARGIN.top * PLATE_SCALE)
	plate:SetPoint("BOTTOMRIGHT", PLATE_MARGIN.right * PLATE_SCALE, -PLATE_MARGIN.bottom * PLATE_SCALE)
	plate:SetFrameLevel(panel:GetFrameLevel())
	plate:SetAlpha(PLATE_ALPHA)

	local near, far = PLATE_CORNER / PLATE_SIZE, 1 - PLATE_CORNER / PLATE_SIZE
	local corner = PLATE_CORNER * PLATE_SCALE
	local function Piece(left, right, top, bottom)
		local texture = plate:CreateTexture(nil, "BACKGROUND")
		texture:SetTexture(PLATE_TEXTURE)
		texture:SetTexCoord(left, right, top, bottom)
		return texture
	end

	local topLeft = Piece(0, near, 0, near)
	topLeft:SetSize(corner, corner)
	topLeft:SetPoint("TOPLEFT")
	local topRight = Piece(far, 1, 0, near)
	topRight:SetSize(corner, corner)
	topRight:SetPoint("TOPRIGHT")
	local bottomLeft = Piece(0, near, far, 1)
	bottomLeft:SetSize(corner, corner)
	bottomLeft:SetPoint("BOTTOMLEFT")
	local bottomRight = Piece(far, 1, far, 1)
	bottomRight:SetSize(corner, corner)
	bottomRight:SetPoint("BOTTOMRIGHT")

	-- An edge or the middle: from one corner piece's inner point to the opposite one's.
	local function Between(piece, fromA, pointA, fromB, pointB)
		piece:SetPoint("TOPLEFT", fromA, pointA)
		piece:SetPoint("BOTTOMRIGHT", fromB, pointB)
	end
	Between(Piece(near, far, 0, near), topLeft, "TOPRIGHT", topRight, "BOTTOMLEFT")
	Between(Piece(near, far, far, 1), bottomLeft, "TOPRIGHT", bottomRight, "BOTTOMLEFT")
	Between(Piece(0, near, near, far), topLeft, "BOTTOMLEFT", bottomLeft, "TOPRIGHT")
	Between(Piece(far, 1, near, far), topRight, "BOTTOMLEFT", bottomRight, "TOPRIGHT")
	Between(Piece(near, far, near, far), topLeft, "BOTTOMRIGHT", bottomRight, "TOPLEFT")
end

local function OpenWindow()
	-- UI:Open does not read the bags itself; every other caller already had.
	ns.MatchList:EnsureScan()
	UI:Open()
end

--[[
	The menu's rows, each { kind, left, action }: "header", "separator" or "action". Read by
	Tests/ through UI:ReopenMenuEntries, so the rows can be checked without a frame.
]]
function UI:ReopenMenuEntries()
	return {
		{ kind = "header", left = L["ADDON_TITLE"] },
		{ kind = "separator" },
		{ kind = "action", left = L["REOPEN_MENU_OPEN"], action = OpenWindow },
		{ kind = "separator" },
		{
			kind = "action",
			left = L["REOPEN_MENU_OPTIONS"],
			action = function()
				ns:OpenOptionsPanel()
			end,
		},
	}
end

local function BuildMenu()
	menu = CreateFrame("Frame", "PlayItForwardReopenMenu", UIParent)
	menu:SetFrameStrata("DIALOG")
	menu:SetClampedToScreen(true)
	menu:EnableMouse(true)
	menu:Hide()
	AddPlate(menu)
	tinsert(UISpecialFrames, "PlayItForwardReopenMenu")

	local width, y = MIN_WIDTH, NEAR
	for _, entry in ipairs(UI:ReopenMenuEntries()) do
		local row = CreateFrame("Button", nil, menu)
		local height
		if entry.kind == "separator" then
			local line = row:CreateTexture(nil, "ARTWORK")
			line:SetHeight(1)
			line:SetPoint("LEFT", NEAR, 0)
			line:SetPoint("RIGHT", -NEAR, 0)
			local red, green, blue = ns.GetColorRGB("SEPARATOR")
			line:SetColorTexture(red, green, blue, 0.35)
			row:EnableMouse(false)
			height = NEAR
		else
			local header = entry.kind == "header"
			local text = row:CreateFontString(nil, "OVERLAY", header and "GameFontNormal" or "GameFontHighlight")
			text:SetPoint("LEFT", NEAR, 0)
			text:SetJustifyH("LEFT")
			text:SetWordWrap(false)
			text:SetText(entry.left)
			text:SetTextColor(ns.GetColorRGB(header and "TITLE" or "TEXT"))
			local _, size = text:GetFont()
			height = (size or 12) + 2 * LINE
			width = math.max(width, (text:GetStringWidth() or 0) + GROUP + 2 * NEAR)
			if header then
				row:EnableMouse(false)
			else
				local highlight = row:CreateTexture(nil, "HIGHLIGHT")
				highlight:SetAllPoints()
				local red, green, blue = ns.GetColorRGB("TITLE")
				highlight:SetColorTexture(red, green, blue, HIGHLIGHT_ALPHA)
				row:RegisterForClicks("LeftButtonUp")
				row:SetScript("OnClick", function()
					menu:Hide()
					entry.action()
				end)
			end
		end
		row:SetHeight(height)
		row:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -y)
		row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, -y)
		y = y + height
	end
	menu:SetSize(math.ceil(width), y + NEAR)

	local lastOver = 0
	menu:SetScript("OnUpdate", function(self)
		if not (button and button:IsVisible()) then
			self:Hide()
			return
		end
		local now = GetTime()
		if self:IsMouseOver() or button:IsMouseOver() then
			lastOver = now
		elseif now - lastOver > CLOSE_DELAY then
			self:Hide()
		end
	end)
	menu:SetScript("OnShow", function()
		lastOver = GetTime()
	end)
end

local function ShowMenu()
	if not menu then
		BuildMenu()
	end
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -NEAR)
	menu:Show()
end

local function Build()
	button = CreateFrame("Button", "PlayItForwardReopenButton", UIParent, "UIPanelButtonTemplate")
	button:SetText(L["ADDON_TITLE"])
	button:SetSize(button:GetFontString():GetStringWidth() + PADDING, 22)
	button:GetFontString():SetTextColor(ns.GetColorRGB("TITLE"))
	button:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, -4)
	button:SetScript("OnClick", OpenWindow)
	button:SetScript("OnEnter", ShowMenu)
	button:SetScript("OnHide", function()
		if menu then
			menu:Hide()
		end
	end)
	ns.SkinWidget("Button", button)
	button:Hide()
end

-- Whether the menu is open now. For the Mailbox diagnostics report and Tests/.
function UI:ReopenMenuShown()
	return menu ~= nil and menu:IsShown() == true
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
