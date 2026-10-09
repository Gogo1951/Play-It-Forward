local _, ns = ...

-- The recipient dropdown, reused by the rarity and level-rule controls. The UI files call in through ns.Picker.

local ENTRY_H = 18
local PICKER_MIN_WIDTH = 190
local PICKER_MAX = 240 -- max picker height before the list scrolls
-- Wider runs off the screen, and SetClampedToScreen shoves the list back over its own button.
local PICKER_MAX_WIDTH = 360

local POPUP_TEMPLATE = ns.PickTemplate("TooltipBorderedFrameTemplate", "BackdropTemplate")

--------------------------------------------------------------------------------
-- Recipient Picker
--------------------------------------------------------------------------------

-- A rolled dropdown: one /who returns ~49 names, more than UIDropDownMenu handles gracefully.
ns.Picker = { entries = {} }
local Picker = ns.Picker

function Picker:Build()
	if self.frame then
		return self.frame
	end
	-- Click-anywhere-else dismisses. Sits in the same strata, one level below.
	local catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("DIALOG")
	catcher:SetFrameLevel(1)
	catcher:RegisterForClicks("AnyUp")
	catcher:SetScript("OnClick", function()
		Picker:Close()
	end)
	catcher:Hide()
	self.catcher = catcher

	local f = CreateFrame("Frame", "PlayItForwardRecipientPicker", UIParent, POPUP_TEMPLATE)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(20)
	f:SetClampedToScreen(true)
	-- Backdrop only on the fallback: the bordered template brings its own, and skins restyle that.
	if POPUP_TEMPLATE == "BackdropTemplate" and f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
	end

	--[[
		On Classic Era TooltipBorderedFrameTemplate paints a border with nothing behind it, so the list
		opens see-through. A texture rather than an unconditional SetBackdrop, so a skinning add-on
		still wins; BACKGROUND so entries and highlights sit above.
	]]
	local fill = f:CreateTexture(nil, "BACKGROUND")
	fill:SetPoint("TOPLEFT", 3, -3)
	fill:SetPoint("BOTTOMRIGHT", -3, 3)
	fill:SetColorTexture(0.05, 0.05, 0.05, 0.95)

	f:Hide()

	local scroll = CreateFrame("ScrollFrame", "PlayItForwardPickerScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", -26, 8)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	f.content = content

	tinsert(UISpecialFrames, "PlayItForwardRecipientPicker")
	f:SetScript("OnHide", function()
		catcher:Hide()
	end)

	self.frame = f
	return f
end

function Picker:GetEntry(i)
	if self.entries[i] then
		return self.entries[i]
	end
	local entry = CreateFrame("Button", nil, self.frame.content)
	entry:SetHeight(ENTRY_H)
	entry:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
	entry:SetPoint("TOPRIGHT", 0, -((i - 1) * ENTRY_H))

	--[[
		Anchored on both sides: with only a LEFT anchor a font string draws at whatever width its
		text wants and runs out of the list. SetWordWrap(false) ellipsizes rather than wrapping into
		a second line inside an 18-pixel row.
	]]
	entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	entry.text:SetPoint("LEFT", 4, 0)
	entry.text:SetPoint("RIGHT", -4, 0)
	entry.text:SetJustifyH("LEFT")
	entry.text:SetWordWrap(false)

	-- A divider row draws this instead of text: one hairline across the entry, nothing clickable.
	entry.line = entry:CreateTexture(nil, "OVERLAY")
	entry.line:SetPoint("LEFT", 4, 0)
	entry.line:SetPoint("RIGHT", -4, 0)
	entry.line:SetHeight(1)
	local red, green, blue = ns.GetColorRGB("SEPARATOR")
	entry.line:SetColorTexture(red, green, blue, 0.6)
	entry.line:Hide()

	local highlight = entry:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.12)

	self.entries[i] = entry
	return entry
end

-- options = { { text = "...", pick = candidate|nil, clear/disabled/separator/findForItem = bool }, ... }
function Picker:Open(anchor, options, onSelect)
	local f = self:Build()
	for _, entry in ipairs(self.entries) do
		entry:Hide()
	end

	-- Never narrower than the button it drops from, whichever control that is.
	local width = math.max(PICKER_MIN_WIDTH, anchor:GetWidth() or 0)
	-- A font string with both anchors set reports the width it was given, not the width it wants.
	for _, opt in ipairs(options) do
		if not self.ruler then
			self.ruler = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			self.ruler:Hide() -- never drawn; it exists only to be measured
		end
		self.ruler:SetText(opt.text or "")
		width = math.max(width, self.ruler:GetStringWidth() + 24)
	end
	width = math.min(PICKER_MAX_WIDTH, width)

	for i, opt in ipairs(options) do
		local entry = self:GetEntry(i)
		entry.text:SetText(opt.text or "")
		if opt.separator then
			entry.line:Show()
		else
			entry.line:Hide()
		end
		-- An entry that will not respond to a click has to look like it; a divider is furniture.
		entry:SetAlpha((opt.disabled and not opt.separator) and 0.45 or 1)
		entry:SetScript("OnClick", function()
			if opt.disabled then
				return
			end
			Picker:Close()
			onSelect(opt)
		end)
		entry:Show()
	end

	local listH = #options * ENTRY_H
	f.content:SetSize(width, math.max(1, listH))
	f:SetSize(width + 40, math.min(PICKER_MAX, listH) + 16)

	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	self.catcher:Show()
	f:Show()
end

function Picker:Close()
	if self.frame then
		self.frame:Hide()
	end
	if self.catcher then
		self.catcher:Hide()
	end
end
