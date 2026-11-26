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
	Whether a targeted search could put a stranger on this row: Matcher:RankCandidates places
	strangers only from admitted classes, and an unreadable item admits nobody whatever it lists
	as eligible. Shared with UI:FindRecipientsForItem, so the entry and the press cannot disagree.
]]
function UI:RescanCanHelp(item)
	if item.state == ns.Matcher.UNREADABLE then
		return false
	end
	local verdict = item.verdict or ns.Matcher:VerdictFor(item)
	return #((verdict and verdict.admitted) or {}) > 0
end

-- A shortlist, never the whole field: past three names the line stops saying who it is for.
local BEST_FIT_MAX = 3

--[[
	The classes the verdict ranks highest for this item, best first, so a match shows its
	reasoning. Read from the contenders, never the eligible list: every class can wear cloth, but
	healing pants are a priest's. Gear ranks by fit and then by how close the class is to the
	armor type. A consumable has no ranking, so one that suits more than three classes equally
	shows no line rather than three picked at random. Class names come from the client.
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

--[[
	The list's opening lines, in the body color. A Kept row going to your enchanter, an unreadable
	row and a Kept row no class can take each say why in one line, since no count or class list
	applies to them. Every other row gives its candidate count and level band, then the classes
	it suits best, a row the player sent to Disenchant by hand included.
]]
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

--[[
	The line an empty list shows, or nil when the header already said why. Each cause names the one
	thing that can change it: a search for a row still waiting, the Rescan below for a Kept row
	some class could still take. Find Recipients never fills a Kept row, so a Kept row never
	points there.
]]
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
			-- The kit puts the spacer above each heading that sets a group apart.
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

	-- The list's only line, under a spacer, above what to do instead of giving it to a name.
	table.insert(options, { kind = "spacer", disabled = true })
	table.insert(options, { kind = "separator", separator = true, disabled = true })
	local disenchant = DisenchantOption(item)
	if disenchant then
		table.insert(options, disenchant)
	end
	-- Keep Item clears the name and unticks the row, the same as unticking its checkbox.
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

	-- Never Give Away puts the item on the never-give list (ns.Bags:NeverGive), which says so in chat.
	table.insert(options, {
		kind = "action",
		text = L["NEVER_GIVE_AWAY"],
		neverGive = true,
	})

	return options
end

-- The short note on a name's right, gray, and what hovering it says.
local NOTES = {
	refused = { tag = "PICKER_TAG_REFUSED", description = "PICKER_NOTE_REFUSED_DESCRIPTION" },
	held = { tag = "PICKER_TAG_HAS_ONE", description = "PICKER_NOTE_HAS_ONE_DESCRIPTION" },
	recent = { tag = "PICKER_TAG_RECENT", description = "PICKER_NOTE_RECENT_DESCRIPTION" },
}

-- One name in the picker: class-colored, its level, and on its right the note that applies to it, if any.
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

	--[[
		No class word: the name is already class-colored, and the color says it. Every name is a
		choice, so each keeps the check's room on the left and the names line up, noted or not. The
		note sits on the right, gray, except on the picked name; its tooltip still says what it means.
	]]
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

--[[
	What a row's dropdown reads once it holds somebody: the name class-colored, then its level. A
	row going to your enchanter leads with the disenchant icon, because the same character can
	also be an alt the item was matched to and the name alone cannot tell the two apart.
]]
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

-- What a picked entry does, off the frame so the tests can drive it.
function UI:PickerSelect(item, option)
	if option.findForItem then
		self:FindRecipientsForItem(item)
		return
	end
	if option.neverGive then
		-- The never-give list's helper, guarded so the entry is harmless on a build without it.
		if ns.Bags and ns.Bags.NeverGive then
			ns.Bags:NeverGive(item.itemID)
		end
		return
	end
	self:SetRecipient(item, option.pick)
end

function UI:SetRecipient(item, who)
	--[[
		THE PLAYER'S PICK IS NEVER REFUSED, AND IT ALWAYS STANDS. A name already on a row the
		allocator filled is taken from it; a name on another row the player set by hand stays
		there too, so both go to them. A name the server bounced earlier is theirs to retry. The
		picker's notes state these facts; they are not gates.
	]]
	if who and not who.alt then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item and not other.pinned then
			other.recipient, other.pinned = nil, false
		end
	end

	--[[
		Pinned because a player chose it: MatchList:Assign rebuilds only what it decided itself. Keep Item
		included, where "nobody" is the choice.
	]]
	item.pinned = true

	if who then
		item.recipient, item.send = who, true
	else
		item.recipient, item.send = nil, false
	end

	-- Every row the player has not set is decided again around the pick, so none is left empty.
	self:Assign()
end

--[[
	The checkbox, live on every row Distribute could mail (UI:CanTick); UI:Refresh dims the rest.
	Every row starts ticked by design: the tick means give this
	away, so no row needs ticking before it is searched for, and an untick is never undone by a
	search or rescan. Unticking is the player's keep: it pins the row, recipient and all,
	because the tick is the last thing between an item and a stranger's mailbox and a rebuild
	that re-ticks it has overridden them. Ticking a row with a name sends it to that name, still
	pinned; ticking a bare row unpins it and the allocator runs, so it is matched like any other.
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
