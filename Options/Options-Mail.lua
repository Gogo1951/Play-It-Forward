local ADDON_NAME, ns = ...
local L = ns.L

local Kit = ns.OptionsKit
local GetColor = ns.GetColor
local Distributor = ns.Distributor
local AceGUI = LibStub("AceGUI-3.0")

--------------------------------------------------------------------------------
-- Mail Editor Widget
--------------------------------------------------------------------------------

--[[
	One custom widget, not two AceConfig inputs: an input's set redraws the panel, stealing the
	cursor every keystroke. Fed as a description row, whose only calls are SetText and SetFontObject.
]]
local WIDGET_TYPE, WIDGET_VERSION = ADDON_NAME .. "_MailEditor", 1

local HEADING_HEIGHT = 16
local COLUMN_GAP = 16
local BODY_LINES = 16
-- The subject EditBox's label sits above its input; the preview box lines up with the input.
local SUBJECT_LABEL_HEIGHT = 16
local PREVIEW_PADDING = 8
local BODY_GAP = 8

local PREVIEW_BACKDROP = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 },
}

local function Measure(key, text)
	local length, max = #Distributor:CleanText(text), Distributor.MAIL_FIELDS[key].max
	local color = (length > max) and GetColor("OFF") or GetColor("HELP")
	return length, max, color
end

-- As tall as the mail, never shorter than the editor: the footer is the line the preview most needs to show.
local function Fit(self)
	local text = self.previewSubject:GetStringHeight() + self.previewBody:GetStringHeight()
	local height = math.max(self.minPreviewHeight, text + PREVIEW_PADDING * 3)
	self.preview:SetHeight(height)

	local rowHeight = math.max(self.baseHeight, HEADING_HEIGHT + SUBJECT_LABEL_HEIGHT + height + 4)
	if rowHeight ~= self.rowHeight then
		self.rowHeight = rowHeight
		self:SetHeight(rowHeight)
		local parent = self.parent
		while parent and parent.DoLayout do
			parent:DoLayout()
			parent = parent.parent
		end
	end
end

--[[
	A FontString wraps only when its text is set, so text set before the width settles keeps the old
	line count: it is set again at each new width, cleared first. The width is set by hand: inside
	OnSizeChanged an anchored FontString still reports the old width.
]]
local function Wrap(self)
	local width = self.preview:GetWidth() - PREVIEW_PADDING * 2
	for fontString, text in pairs({
		[self.previewSubject] = Distributor:BuildSubject(),
		[self.previewBody] = Distributor:BuildBody(),
	}) do
		if width > 0 then
			fontString:SetWidth(width)
		end
		fontString:SetText("")
		fontString:SetText(text)
	end
	Fit(self)
end

local function Repaint(self)
	Wrap(self)

	local subjectLength, subjectMax, subjectColor = Measure("mailSubject", self.subject:GetText())
	local bodyLength, bodyMax, bodyColor = Measure("mailBody", self.body:GetText())
	self.count:SetText(
		subjectColor
			.. L["OPTIONS_MAIL_COUNT_SUBJECT"]:format(subjectLength, subjectMax)
			.. "|r   "
			.. bodyColor
			.. L["OPTIONS_MAIL_COUNT_BODY"]:format(bodyLength, bodyMax)
			.. "|r"
	)
end

local function Load(self)
	self.subject:SetText(Distributor:EditableText("mailSubject"))
	self.body:SetText(Distributor:EditableText("mailBody"))
	Repaint(self)
end

local function OnChanged(self, key)
	return function(_, _, text)
		Distributor:SaveCustomText(key, text)
		Repaint(self)
	end
end

-- AceGUI widgets placed by hand: owned by this one for life, so never released back to the pool.
local function Adopt(child, parent)
	child.frame:SetParent(parent)
	child.frame:ClearAllPoints()
	child.frame:Show()
	return child
end

local methods = {
	-- rowHeight, not self.height: AceGUI's Release clears that, so a second visit would SetHeight(nil) and blank the page.
	OnAcquire = function(self)
		self.rowHeight = self.baseHeight
		self.previewWidth = nil
		self:SetHeight(self.baseHeight)
	end,

	OnRelease = function(self)
		-- AceGUI leaves the old container here, and Fit would lay out a page that is no longer shown.
		self.parent = nil
		self.subject:ClearFocus()
		self.body:ClearFocus()
	end,

	-- AceConfigDialog hands a description row its name; this row draws its own text instead.
	SetText = function(self)
		Load(self)
	end,

	SetFontObject = function() end,
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local widget = { frame = frame, type = WIDGET_TYPE }

	local yours = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	yours:SetPoint("TOPLEFT")
	yours:SetText(GetColor("TITLE") .. L["OPTIONS_MAIL_YOURS"] .. "|r")

	local subject = Adopt(AceGUI:Create("EditBox"), frame)
	subject:SetLabel(L["OPTIONS_MAIL_SUBJECT"])
	subject:DisableButton(true)
	subject:SetMaxLetters(0)
	subject.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -HEADING_HEIGHT)
	subject.frame:SetPoint("RIGHT", frame, "CENTER", -COLUMN_GAP / 2, 0)
	subject:SetCallback("OnTextChanged", OnChanged(widget, "mailSubject"))

	local body = Adopt(AceGUI:Create("MultiLineEditBox"), frame)
	body:SetLabel(L["OPTIONS_MAIL_BODY"])
	body:DisableButton(true)
	body:SetNumLines(BODY_LINES)
	body.frame:SetPoint("TOPLEFT", subject.frame, "BOTTOMLEFT", 0, -BODY_GAP)
	body.frame:SetPoint("RIGHT", frame, "CENTER", -COLUMN_GAP / 2, 0)
	body:SetCallback("OnTextChanged", OnChanged(widget, "mailBody"))

	local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	count:SetPoint("TOPLEFT", body.frame, "BOTTOMLEFT", 0, -4)
	count:SetJustifyH("LEFT")

	local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	heading:SetPoint("TOPLEFT", frame, "TOP", COLUMN_GAP / 2, 0)
	heading:SetText(GetColor("TITLE") .. L["OPTIONS_MAIL_PREVIEW"] .. "|r")

	local preview = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	preview:SetPoint("TOPLEFT", frame, "TOP", COLUMN_GAP / 2, -(HEADING_HEIGHT + SUBJECT_LABEL_HEIGHT))
	preview:SetPoint("RIGHT", frame, "RIGHT")
	if preview.SetBackdrop then
		preview:SetBackdrop(PREVIEW_BACKDROP)
		preview:SetBackdropColor(0, 0, 0, 0.5)
		preview:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end

	local previewSubject = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	previewSubject:SetPoint("TOPLEFT", PREVIEW_PADDING, -PREVIEW_PADDING)
	previewSubject:SetJustifyH("LEFT")
	previewSubject:SetNonSpaceWrap(true)

	-- Non-space wrap: an unbroken run otherwise ends in "..." and drops every line after it, footer included.
	local previewBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	previewBody:SetPoint("TOPLEFT", previewSubject, "BOTTOMLEFT", 0, -PREVIEW_PADDING)
	previewBody:SetJustifyH("LEFT")
	previewBody:SetJustifyV("TOP")
	previewBody:SetNonSpaceWrap(true)

	widget.subject, widget.body, widget.count = subject, body, count
	widget.preview, widget.previewSubject, widget.previewBody = preview, previewSubject, previewBody
	-- The editor's own extent: the shortest the row, and the box, are ever drawn.
	widget.baseHeight = HEADING_HEIGHT + subject.frame:GetHeight() + BODY_GAP + body.frame:GetHeight() + 24
	widget.minPreviewHeight = subject.frame:GetHeight() + BODY_GAP + body.frame:GetHeight() - SUBJECT_LABEL_HEIGHT - 4
	widget.rowHeight = widget.baseHeight

	-- Fit's own height change fires this too, so only a new width rewraps.
	preview:SetScript("OnSizeChanged", function(_, width)
		if width and width > 0 and width ~= widget.previewWidth then
			widget.previewWidth = width
			Wrap(widget)
		end
	end)
	for name, method in pairs(methods) do
		widget[name] = method
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(WIDGET_TYPE, Constructor, WIDGET_VERSION)

--------------------------------------------------------------------------------
-- Mail Message Panel
--------------------------------------------------------------------------------

function ns.BuildMailOptions()
	local args = {
		descIntro = Kit.Desc(L["OPTIONS_MAIL_DESCRIPTION"], 1),
		spacerIntro = Kit.Spacer(2),

		editor = {
			type = "description",
			name = "",
			dialogControl = WIDGET_TYPE,
			width = "full",
			order = 3,
		},
		spacerReset = Kit.Spacer(4),

		-- One Reset for both (README-Notes: One mail reset), so it asks; never grayed, since a gate goes stale while typing.
		reset = Kit.ResetRow(
			5,
			nil,
			L["OPTIONS_MAIL_RESET_CAPTION"],
			L["OPTIONS_MAIL_RESET_DESCRIPTION"],
			nil,
			function()
				ns.db.profile.mailSubject = ""
				ns.db.profile.mailBody = ""
			end,
			L["OPTIONS_MAIL_RESET_CONFIRM"]
		),
	}

	return {
		type = "group",
		name = L["TAB_MAIL_MESSAGE"],
		args = args,
	}
end
