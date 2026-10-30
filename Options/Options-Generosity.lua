local _, ns = ...
local L = ns.L

local AceGUI = LibStub("AceGUI-3.0")
local GetColor = ns.GetColor

--[[
	Your totals drawn as the unit tooltip draws them, so the panel shows exactly what other players
	see when they hover over you: a tooltip backdrop, the top of your own tooltip, the branded
	header, and each label left with its value right. AceConfig cannot right-align a description, so this is a small AceGUI widget
	the panel's one description row names as its dialogControl. The lines come from
	Generosity:BlockLines, the tooltip's own, and are read again on every redraw of the panel.

	It answers the calls AceConfig makes on a description's Label (SetText, SetFontObject, the
	image setters) and sizes itself to its lines, as a tooltip does.
]]
local WIDGET = "PlayItForwardBadgePreview"
local PAD = 8
local COLUMN_GAP = 20
local LINE_GAP = 2

local BACKDROP_TEMPLATE = ns.PickTemplate("TooltipBackdropTemplate", "BackdropTemplate")

local function NewLine(box, justify, font)
	local line = box:CreateFontString(nil, "OVERLAY", font or "GameTooltipText")
	line:SetJustifyH(justify)
	line:SetWordWrap(false)
	return line
end

--[[
	The top of your own unit tooltip, read when the panel draws so it is the character you are on:
	your name in your class color, with your PvP title where the client gives one, then your level,
	race and class.
]]
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
		self.header:SetText(header)
		local lineHeight = self.header:GetStringHeight() + LINE_GAP
		local width =
			math.max(self.nameLine:GetStringWidth(), self.infoLine:GetStringWidth(), self.header:GetStringWidth())

		-- Name, then level, race and class, then a blank line, as the tooltip spaces its own block.
		local y = -PAD
		self.nameLine:SetPoint("TOPLEFT", PAD, y)
		y = y - self.nameLine:GetStringHeight() - LINE_GAP
		self.infoLine:SetPoint("TOPLEFT", PAD, y)
		y = y - lineHeight * 2
		self.header:ClearAllPoints()
		self.header:SetPoint("TOPLEFT", PAD, y)
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
		descIntro = ns.OptionsDesc(L["OPTIONS_GENEROSITY_DESCRIPTION"], 1),
		spacerIntro = ns.OptionsSpacer(2),

		--[[
			The intro, the toggle, then the totals as the tooltip shows them. It is proximity-scoped sharing: nearby players
			running the add-on see these totals on your tooltip, and you see theirs on the same
			terms. Off stops your own broadcasts but not your view of theirs, and the totals below
			keep counting either way, which is why they are not gated on it.
		]]
		toggleShareStats = ns.OptionsProfileToggle(
			"shareStats",
			L["OPTIONS_SHARE_STATS"],
			L["OPTIONS_SHARE_STATS_DESCRIPTION"],
			3
		),
		spacerShare = ns.OptionsSpacer(4),
		-- Your totals as other players see them on your tooltip; the name changes so a redraw refreshes it.
		preview = {
			type = "description",
			name = function()
				return tostring((ns.Generosity:Get()))
			end,
			dialogControl = WIDGET,
			width = "full",
			order = 5,
		},
	}

	return {
		type = "group",
		name = L["TAB_GENEROSITY"],
		args = args,
	}
end
