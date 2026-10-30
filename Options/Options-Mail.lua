local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor
local Distributor = ns.Distributor
local AceGUI = LibStub("AceGUI-3.0")

--------------------------------------------------------------------------------
-- Mail Editor Widget
--------------------------------------------------------------------------------

--[[
	The player's subject and body on the left, the mail exactly as it will be sent on the right.

	ONE CUSTOM WIDGET, NOT TWO AceConfig INPUTS. An input saves through AceConfigDialog, which
	redraws the whole panel after every set, so saving on each keystroke would take the cursor out
	of the box mid-word. This widget writes the profile itself on every change and repaints only
	its own preview, and AceConfigDialog never hears about the typing. It is fed as a description
	row, the one control type whose only calls are SetText and SetFontObject.

	No length limit while typing: Distributor:BuildSubject and BuildBody cut an overlong copy and
	end it with "...", and the preview shows that cut as it happens.
]]
local WIDGET_TYPE, WIDGET_VERSION = "PlayItForward-MailEditor", 1

local HEADING_HEIGHT = 22
local COLUMN_GAP = 16
local BODY_LINES = 16
-- The subject EditBox's label sits above its input; the preview box lines up with the input.
local SUBJECT_LABEL_HEIGHT = 18
local PREVIEW_PADDING = 10

local PREVIEW_BACKDROP = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 },
}

-- "16/31", red once it runs past the limit and will be cut.
local function Measure(key, text)
	local length, max = #Distributor:CleanText(text), Distributor.MAIL_FIELDS[key].max
	local color = (length > max) and GetColor("OFF") or GetColor("HELP")
	return length, max, color
end

--[[
	The preview is as tall as the mail it shows, never shorter than the editor beside it. A custom
	body gets MAIL_POWERED_BY appended, so a box sized to the editor cut that off the moment the
	player wrote near the limit -- the one line the preview most needs to show. When the box
	grows the row grows with it, and the panel is laid out again so nothing below overlaps it.
]]
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
	A FontString wraps its text, and sizes itself to it, only when the text is set. Text set before
	the panel settles the box's width (every redraw, Restore Default included) kept the line count
	of the old width and drew the rest as "...". So the text is set again at each new width, and
	cleared first, since setting the same string again does not wrap it again.

	The width is set by hand, not left to anchors: inside the box's OnSizeChanged an anchored
	FontString still reports the old width, so the stock mail opened cut off at its last line.
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

-- Every redraw of the panel, and a Restore Default or profile switch is one, re-reads the profile.
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
	--[[
		NOT self.height: AceGUI's Release clears that field on every recycled widget, so a second
		visit to the panel would call SetHeight(nil), throw inside Create and leave the page blank.
		Every visit starts from the editor's own extent and wraps again at the width it is given.
	]]
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
	body.frame:SetPoint("TOPLEFT", subject.frame, "BOTTOMLEFT", 0, -6)
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

	--[[
		Open at the bottom: the box is sized to the text (Fit), never the text clipped to the box.
		A run with no spaces wraps mid-word, as in the editor beside it: left unwrapped, it ran past
		the edge, ended in "...", and took every line after it, the footer included.
	]]
	local previewBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	previewBody:SetPoint("TOPLEFT", previewSubject, "BOTTOMLEFT", 0, -PREVIEW_PADDING)
	previewBody:SetJustifyH("LEFT")
	previewBody:SetJustifyV("TOP")
	previewBody:SetNonSpaceWrap(true)

	widget.subject, widget.body, widget.count = subject, body, count
	widget.preview, widget.previewSubject, widget.previewBody = preview, previewSubject, previewBody
	-- The editor's own extent: the shortest the row, and the box, are ever drawn.
	widget.baseHeight = HEADING_HEIGHT + subject.frame:GetHeight() + 6 + body.frame:GetHeight() + 24
	widget.minPreviewHeight = subject.frame:GetHeight() + 6 + body.frame:GetHeight() - SUBJECT_LABEL_HEIGHT - 4
	widget.rowHeight = widget.baseHeight

	--[[
		Wrapped height depends on width, which the panel sets only after the text is in. Fit's own
		height change lands here too, so only a new width wraps again.
	]]
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
		descIntro = ns.OptionsDesc(L["OPTIONS_MAIL_DESCRIPTION"], 1),
		spacerIntro = ns.OptionsSpacer(2),

		editor = {
			type = "description",
			name = "",
			dialogControl = WIDGET_TYPE,
			width = "full",
			order = 3,
		},
		spacerReset = ns.OptionsSpacer(4),

		--[[
			Never disabled: the panel is not redrawn while the player types, so a gate would go stale.
			No confirm either: the popup blanked the panel behind it, and the default is one press
			from being typed over again.
		]]
		buttonReset = {
			type = "execute",
			name = L["OPTIONS_MAIL_RESET"],
			desc = L["OPTIONS_MAIL_RESET_DESCRIPTION"],
			order = 5,
			func = function()
				ns.db.profile.mailSubject = ""
				ns.db.profile.mailBody = ""
				LibStub("AceConfigRegistry-3.0"):NotifyChange(ns.OPTIONS_REGISTRY.Mail)
			end,
		},
	}

	return {
		type = "group",
		name = L["TAB_MAIL_MESSAGE"],
		args = args,
	}
end
