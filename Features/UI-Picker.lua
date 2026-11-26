local _, ns = ...

-- Every dropdown list in the window, as Menu-Kit dropdown entries built from the UI files' options.

local Kit = ns.MenuKit

-- Named, so the kit lists it in UISpecialFrames and Escape closes it.
local PICKER_NAME = "PlayItForwardRecipientPicker"

-- Must match the name Features/UI-Window.lua puts in UISpecialFrames.
local MAIN_WINDOW_NAME = "PlayItForwardMailFrame"

-- An entry's tooltip color, unpacked once: GetColorRGB mid-argument-list would keep only its first value.
local BODY_R, BODY_G, BODY_B = ns.GetColorRGB("BODY")

-- The kinds a click acts on. The rest (headings, lines, explanations) never take one.
local CLICKABLE = { choice = true, action = true, value = true }

--------------------------------------------------------------------------------
-- Recipient Picker
--------------------------------------------------------------------------------

ns.Picker = {}
local Picker = ns.Picker

--[[
	Escape hides every UISpecialFrames entry, and closing the window stops a run, so the window is
	off the list while a dropdown is open. Back a frame later: Escape's own walk would reach it.
]]
local function DropMainWindow()
	for index = #UISpecialFrames, 1, -1 do
		if UISpecialFrames[index] == MAIN_WINDOW_NAME then
			table.remove(UISpecialFrames, index)
		end
	end
end

local function RestoreMainWindow()
	C_Timer.After(0, function()
		-- Reopened in the same frame: the window stays off the list while it is open.
		if Picker.frame and Picker.frame:IsShown() then
			return
		end
		for _, name in ipairs(UISpecialFrames) do
			if name == MAIN_WINDOW_NAME then
				return
			end
		end
		tinsert(UISpecialFrames, MAIN_WINDOW_NAME)
	end)
end

function Picker:Build()
	if self.menu then
		return self.menu
	end
	self.menu = Kit.CreateDropdownMenu(PICKER_NAME)
	self.frame = _G[PICKER_NAME]
	return self.menu
end

-- An explicit kit kind, else the separator/header/info flags, else a choice.
local function KindOf(option)
	if option.kind then
		return option.kind
	end
	if option.separator then
		return "separator"
	end
	if option.header then
		return "section"
	end
	if option.info then
		return "description"
	end
	return "choice"
end

--[[
	A list setting any selected is taken at its word. The top bar's lists check the choice whose
	text is the button's, or starts with it and a space (the Disenchant list adds the level).
]]
local function PickedTest(anchor, options)
	for _, option in ipairs(options) do
		if option.selected ~= nil then
			return function(candidate)
				return candidate.selected == true
			end
		end
	end
	local label = anchor and anchor.text
	local shown = label and label.GetText and label:GetText()
	if type(shown) ~= "string" or shown == "" then
		return function()
			return false
		end
	end
	return function(candidate)
		local text = candidate.text
		return type(text) == "string" and (text == shown or text:sub(1, #shown + 1) == shown .. " ")
	end
end

--[[
	options = { { text = "...", tooltip = "..."|nil, kind = kit kind|nil, right = "..."|nil,
	rightColor = palette key|nil, leftColor = palette key|nil, selected = bool|nil,
	disabled/separator/header/info = bool, ...anything onSelect reads }, ... }
	A line between groups gets the spacer above it the guide puts there.
]]
function Picker:Entries(anchor, options, onSelect)
	local picked = PickedTest(anchor, options)
	local entries = {}
	for _, option in ipairs(options) do
		local kind = KindOf(option)
		local previous = entries[#entries]
		if kind == "separator" and previous and previous.kind ~= "spacer" then
			entries[#entries + 1] = { kind = "spacer" }
		end
		local entry = {
			kind = kind,
			left = option.text,
			right = option.right,
			leftColor = option.leftColor,
			rightColor = option.rightColor,
			option = option,
		}
		if CLICKABLE[kind] then
			entry.disabled = option.disabled or nil
			if kind == "choice" then
				entry.selected = picked(option)
			end
			if not option.disabled then
				--[[
					Pick, then close: on WoW Forever hiding the list first left Rescan for Better
					Match's SendWho blocked (issue #16). keepOpen stops the kit hiding it early.
				]]
				entry.keepOpen = true
				entry.onClick = function()
					onSelect(option)
					Picker:Close()
				end
			end
		end
		if option.tooltip then
			local text = option.tooltip
			entry.tooltip = function(tooltip)
				tooltip:AddLine(text, BODY_R, BODY_G, BODY_B, true)
			end
		end
		entries[#entries + 1] = entry
	end
	return entries
end

function Picker:Open(anchor, options, onSelect)
	local menu = self:Build()
	-- Opening the open list's button again closes it, and the window goes back on the Escape list.
	menu:Open(anchor, self:Entries(anchor, options, onSelect), RestoreMainWindow)
	if menu:IsOpenFor(anchor) then
		DropMainWindow()
	end
end

function Picker:Close()
	if self.menu then
		self.menu:Close()
	end
end
