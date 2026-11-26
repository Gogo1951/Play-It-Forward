local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

local UI = ns.UI
local MatchList = ns.MatchList
local Picker = ns.Picker

--------------------------------------------------------------------------------
-- Candidates + manual assignment
--------------------------------------------------------------------------------

--[[
	Nobody is hidden or gated: the notes beside names are information, and every candidate can be
	picked. Your Alts read alphabetically, being found by name; the other groups keep ranked order.
]]
local SECTIONS = {
	{ rank = 1, key = "PICKER_SECTION_ALTS", alphabetical = true },
	{ rank = 2, key = "PICKER_SECTION_GUILD" },
	{ rank = 3, key = "PICKER_SECTION_STRANGERS" },
}

-- Features/UI-Window.lua reads it at draw time; this file loads after it.
UI.DISENCHANT_ICON = "|TInterface\\Icons\\INV_Enchant_Disenchant:0|t"

local function ByName(a, b)
	if (a.name or "") ~= (b.name or "") then
		return (a.name or "") < (b.name or "")
	end
	return (a.level or 0) < (b.level or 0)
end

-- Any gear row, not only Kept: dust or upgrade is the player's call. Disabled, not hidden, with no enchanter.
local function DisenchantOption(item)
	if item.kind ~= "gear" then
		return nil
	end
	local enchanter = ns.Alts:DisenchantRecipient()
	if not enchanter then
		return {
			kind = "choice",
			text = UI.DISENCHANT_ICON .. " " .. ns.DisenchantName(),
			tooltip = L["PICKER_DISENCHANT_NONE_DESCRIPTION"],
			disabled = true,
			selected = false,
		}
	end
	return {
		kind = "choice",
		text = UI.DISENCHANT_ICON .. " " .. ns.DisenchantName(),
		tooltip = L["PICKER_DISENCHANT_DESCRIPTION"]:format(ns.ColorName(enchanter.name, enchanter.class)),
		pick = enchanter,
		selected = (item.recipient and item.recipient.disenchant) and true or false,
	}
end

--[[
	Strangers are ranked only from admitted classes, and an unreadable item admits nobody. Shared
	with UI:FindRecipientsForItem, so the entry and the press cannot disagree.
]]
function UI:RescanCanHelp(item)
	if item.state == ns.Matcher.UNREADABLE then
		return false
	end
	local verdict = item.verdict or ns.Matcher:VerdictFor(item)
	return #((verdict and verdict.admitted) or {}) > 0
end

-- Past three names the line stops saying who it is for.
local BEST_FIT_MAX = 3

--[[
	From the contenders, never the eligible list: every class can wear cloth, but healing pants are
	a priest's. Consumables are unranked, so past three equal classes there is no line, not a random three.
]]
function UI:BestFitLine(item)
	local verdict = item.verdict
	local contenders = verdict and verdict.contenders or {}
	if #contenders == 0 then
		return nil
	end
	local ranked = {}
	for index, class in ipairs(contenders) do
		ranked[index] = class
	end
	if item.kind == "consumable" then
		if #ranked > BEST_FIT_MAX then
			return nil
		end
	else
		local order = {}
		for index, class in ipairs(contenders) do
			order[class] = index
		end
		local fits = verdict.fits or {}
		table.sort(ranked, function(a, b)
			if (a == verdict.best) ~= (b == verdict.best) then
				return a == verdict.best
			end
			if (fits[a] or 0) ~= (fits[b] or 0) then
				return (fits[a] or 0) > (fits[b] or 0)
			end
			local tierA, tierB = ns.Matcher:Priority(item, a), ns.Matcher:Priority(item, b)
			if tierA ~= tierB then
				return tierA < tierB
			end
			return order[a] < order[b]
		end)
	end
	local names = {}
	local body = GetColor("BODY")
	for index = 1, math.min(BEST_FIT_MAX, #ranked) do
		local class = ranked[index]
		local name = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
		names[#names + 1] = ns.ColorName(name, class) .. body
	end
	return L["TOOLTIP_RECIPIENT_BEST_FIT"]:format(table.concat(names, ", "))
end

function UI:PickerHeader(item)
	local body = GetColor("BODY")
	if item.recipient and item.recipient.disenchant and item.state == ns.Matcher.LEFTOVER then
		local who = ns.ColorName(item.recipient.name, item.recipient.class) .. body
		return { L["TOOLTIP_RECIPIENT_DISENCHANT"]:format(who) }
	end
	if item.state == ns.Matcher.UNREADABLE then
		return { L["ITEM_STATS_UNREADABLE"] }
	end
	if item.state == ns.Matcher.LEFTOVER and not self:RescanCanHelp(item) then
		return { L["TOOLTIP_RECIPIENT_KEPT"] }
	end
	local lines = {
		L["TOOLTIP_RECIPIENT_CANDIDATES"]:format(#self:Candidates(item), item.bandLo or 0, item.bandHi or 0),
	}
	local bestFit = self:BestFitLine(item)
	if bestFit then
		lines[#lines + 1] = bestFit
	end
	return lines
end

-- nil when the header already said why. A Kept row never points at Find Recipients, which never fills one.
local function EmptyLine(item)
	if item.state == ns.Matcher.UNREADABLE then
		return nil
	end
	if item.state == ns.Matcher.LEFTOVER then
		return UI:RescanCanHelp(item) and L["PICKER_NONE_KEPT"] or nil
	end
	return L["PICKER_NONE_IN_RANGE"]
end

function UI:PickerOptions(item)
	local options = {}

	for _, line in ipairs(self:PickerHeader(item)) do
		table.insert(options, { kind = "description", text = line, info = true, disabled = true })
	end

	local candidates = self:Candidates(item)
	local empty = (#candidates == 0) and EmptyLine(item)
	if empty then
		table.insert(options, { kind = "note", text = empty, info = true, disabled = true })
	end

	local bySection = {}
	for _, person in ipairs(candidates) do
		local rank = ns.Matcher:Source(person)
		bySection[rank] = bySection[rank] or {}
		table.insert(bySection[rank], person)
	end

	for _, section in ipairs(SECTIONS) do
		local people = bySection[section.rank]
		if people then
			if section.alphabetical then
				-- A copy: Candidates hands out the cached ranked list, which must keep its order.
				local sorted = {}
				for index, person in ipairs(people) do
					sorted[index] = person
				end
				table.sort(sorted, ByName)
				people = sorted
			end
			-- No spacer: the kit puts one above each heading.
			table.insert(options, {
				kind = "section",
				text = L[section.key],
				header = true,
				disabled = true,
			})
			for _, person in ipairs(people) do
				self:AddCandidateOption(options, item, person)
			end
		end
	end

	table.insert(options, { kind = "spacer", disabled = true })
	table.insert(options, { kind = "separator", separator = true, disabled = true })
	local disenchant = DisenchantOption(item)
	if disenchant then
		table.insert(options, disenchant)
	end
	table.insert(options, {
		kind = "choice",
		text = L["PICKER_KEEP_OPTION"],
		clear = true,
		selected = (item.pinned and not item.recipient) and true or false,
	})

	if self:RescanCanHelp(item) then
		table.insert(options, {
			kind = "action",
			text = L["PICKER_FIND_FOR_ITEM"],
			findForItem = true,
		})
	end

	table.insert(options, {
		kind = "action",
		text = L["NEVER_GIVE_AWAY"],
		neverGive = true,
	})

	return options
end

local NOTES = {
	refused = { tag = "PICKER_TAG_REFUSED", description = "PICKER_NOTE_REFUSED_DESCRIPTION" },
	held = { tag = "PICKER_TAG_HAS_ONE", description = "PICKER_NOTE_HAS_ONE_DESCRIPTION" },
	recent = { tag = "PICKER_TAG_RECENT", description = "PICKER_NOTE_RECENT_DESCRIPTION" },
}

function UI:AddCandidateOption(options, item, person)
	local held = not person.alt and MatchList:AssignedTo()[person.name] and MatchList:AssignedTo()[person.name] ~= item
	local refused = not ns.Fairness:IsReachable(person.name)

	local note
	if refused then
		note = NOTES.refused
	elseif held then
		note = NOTES.held
	elseif not person.alt and not ns.Fairness:IsFresh(person.name, person.level) then
		note = NOTES.recent
	end

	local current = item.recipient
	local selected = (current and not current.disenchant and current.name == person.name) and true or false

	-- No class word: the color says it. The note hides on the picked name; its tooltip still explains.
	table.insert(options, {
		kind = "choice",
		text = ("%s " .. GetColor("MUTED") .. "(%d)|r"):format(ns.ColorName(person.name, person.class), person.level),
		right = (note and not selected) and L[note.tag] or nil,
		rightColor = "MUTED",
		tooltip = note and L[note.description],
		pick = person,
		indent = true,
		selected = selected,
	})
end

-- The disenchant icon tells dust from a gift: the enchanter can also be the alt an item was matched to.
function UI:RecipientLabel(who)
	local label = ("%s " .. GetColor("MUTED") .. "(%d)|r"):format(ns.ColorName(who.name, who.class), who.level or 0)
	if who.disenchant then
		return self.DISENCHANT_ICON .. " " .. label
	end
	return label
end

function UI:OpenPicker(row)
	local item = row._item
	if not item then
		return
	end
	Picker:Open(row.recipButton, self:PickerOptions(item), function(option)
		UI:PickerSelect(item, option)
	end)
end

-- Off the frame, so Tests/ can drive it.
function UI:PickerSelect(item, option)
	if option.findForItem then
		self:FindRecipientsForItem(item)
		return
	end
	if option.neverGive then
		if ns.Bags and ns.Bags.NeverGive then
			ns.Bags:NeverGive(item.itemID)
		end
		return
	end
	self:SetRecipient(item, option.pick)
end

function UI:SetRecipient(item, who)
	--[[
		The pick is never refused. It takes its name off an allocator-filled row, but a name on another
		hand-set row stays there too: both go.
	]]
	if who and not who.alt then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item and not other.pinned then
			other.recipient, other.pinned = nil, false
		end
	end

	-- MatchList:Assign rebuilds only what it decided; Keep Item pins too, "nobody" being the choice.
	item.pinned = true

	if who then
		item.recipient, item.send = who, true
	else
		item.recipient, item.send = nil, false
	end

	self:Assign()
end

--[[
	Unticking pins the row, recipient and all: the tick is the last thing between an item and a
	stranger's mailbox, so no rebuild may re-tick it.
]]
function UI:ToggleRow(item, checked)
	if not item then
		return
	end
	item.send = checked and true or false
	if not checked or item.recipient then
		item.pinned = true
		self:Refresh()
		return
	end
	item.pinned = false
	self:Assign()
end
