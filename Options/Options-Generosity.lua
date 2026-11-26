local _, ns = ...
local L = ns.L

local AceGUI = LibStub("AceGUI-3.0")
local GetColor = ns.GetColor
local Kit = ns.OptionsKit

-- AceConfig cannot right-align a description, so the preview is an AceGUI widget the row names as its dialogControl.
local WIDGET = "PlayItForwardBadgePreview"
local PAD = 8
local COLUMN_GAP = 16
local LINE_GAP = 2

local BACKDROP_TEMPLATE = ns.PickTemplate("TooltipBackdropTemplate", "BackdropTemplate")

local function NewLine(box, justify, font)
	local line = box:CreateFontString(nil, "OVERLAY", font or "GameTooltipText")
	line:SetJustifyH(justify)
	line:SetWordWrap(false)
	return line
end

local function PlayerLines()
	local className, classToken = UnitClass("player")
	local race = UnitRace("player") or ""
	local level = UnitLevel("player") or 0
	local name = (UnitPVPName and UnitPVPName("player")) or UnitName("player")
	local levelText = GetColor("TITLE") .. level .. "|r"
	local raceText = GetColor("TEXT") .. race .. "|r"
	local classText = ns.ColorName(className or "", classToken)
	return ns.ColorName(name, classToken), levelText .. " " .. raceText .. " " .. classText
end

local methods = {
	OnAcquire = function(self)
		self:Refresh()
	end,
	SetText = function(self)
		self:Refresh()
	end,
	SetFontObject = function() end,
	SetImage = function() end,
	SetImageSize = function() end,

	Refresh = function(self)
		local header, rows = ns.Generosity:BlockLines(ns.Generosity:Get())
		local box = self.box
		local name, info = PlayerLines()
		self.nameLine:SetText(name)
		self.infoLine:SetText(info)
		self.header:SetText(header[1])
		self.headerRight:SetText(header[2])
		local lineHeight = self.header:GetStringHeight() + LINE_GAP
		local width = math.max(
			self.nameLine:GetStringWidth(),
			self.infoLine:GetStringWidth(),
			self.header:GetStringWidth() + COLUMN_GAP + self.headerRight:GetStringWidth()
		)

		-- The unit's own lines, then a blank line, as the tooltip spaces its block.
		local y = -PAD
		self.nameLine:SetPoint("TOPLEFT", PAD, y)
		y = y - self.nameLine:GetStringHeight() - LINE_GAP
		self.infoLine:SetPoint("TOPLEFT", PAD, y)
		y = y - lineHeight * 2
		self.header:ClearAllPoints()
		self.header:SetPoint("TOPLEFT", PAD, y)
		self.headerRight:ClearAllPoints()
		self.headerRight:SetPoint("TOPRIGHT", -PAD, y)
		y = y - lineHeight
		for index, row in ipairs(rows) do
			local left, right = self.lefts[index], self.rights[index]
			if not left then
				left, right = NewLine(box, "LEFT"), NewLine(box, "RIGHT")
				self.lefts[index], self.rights[index] = left, right
			end
			left:SetText(row[1])
			right:SetText(row[2])
			left:ClearAllPoints()
			left:SetPoint("TOPLEFT", PAD, y)
			right:ClearAllPoints()
			right:SetPoint("TOPRIGHT", -PAD, y)
			width = math.max(width, left:GetStringWidth() + COLUMN_GAP + right:GetStringWidth())
			y = y - lineHeight
		end
		local height = -y + PAD - LINE_GAP
		box:SetSize(width + PAD * 2, height)
		self:SetHeight(height)
	end,
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local box = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE)
	box:SetPoint("TOPLEFT")
	-- Without the tooltip template, the client's own tooltip look by hand.
	if BACKDROP_TEMPLATE == "BackdropTemplate" and box.SetBackdrop then
		box:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		box:SetBackdropColor(0, 0, 0, 0.9)
		box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	end

	local widget = {
		frame = frame,
		type = WIDGET,
		box = box,
		nameLine = NewLine(box, "LEFT", "GameTooltipHeaderText"),
		infoLine = NewLine(box, "LEFT"),
		header = NewLine(box, "LEFT"),
		headerRight = NewLine(box, "RIGHT"),
		lefts = {},
		rights = {},
	}
	for name, method in pairs(methods) do
		widget[name] = method
	end
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(WIDGET, Constructor, 1)

--------------------------------------------------------------------------------
-- Generosity Panel
--------------------------------------------------------------------------------

function ns.BuildGenerosityOptions()
	local args = {
		descIntro = Kit.Desc(L["OPTIONS_GENEROSITY_DESCRIPTION"], 1),
		spacerIntro = Kit.Spacer(2),

		-- Off stops only your broadcasts: theirs still show and the totals still count, so the preview isn't gated on it.
		toggleShareStats = ns.OptionsProfileToggle(
			"shareStats",
			L["OPTIONS_SHARE_STATS"],
			L["OPTIONS_SHARE_STATS_DESCRIPTION"],
			3
		),
		spacerShare = Kit.Spacer(4),
		-- Kit.Example's shape built from kit pieces: Kit.Example draws text, and the preview is a widget.
		exampleLabel = Kit.Desc(Kit.Color("HELP", L["SAMPLE_EXAMPLE"]), 5),
		example = Kit.SubRow(6, nil, {
			-- The name changes with the gift count, so a gift forces a redraw.
			{
				type = "description",
				name = function()
					return tostring((ns.Generosity:Get()))
				end,
				dialogControl = WIDGET,
				width = Kit.ROW_WIDTH - Kit.SUB_INDENT_WIDTH,
			},
		}),
	}

	return {
		type = "group",
		name = L["BADGE_OF_GENEROSITY"],
		args = args,
	}
end
