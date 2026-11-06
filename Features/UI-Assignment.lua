local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

-- The recipient dropdown on each row and the choices the player makes in it. Extends ns.UI.
local UI = ns.UI
local MatchList = ns.MatchList
local Picker = ns.Picker

--------------------------------------------------------------------------------
-- Candidates + manual assignment
--------------------------------------------------------------------------------

--[[
	Split from opening the picker so Tests/Manual-Assignment.lua can read the options without a
	frame. Nobody is hidden and nobody is gated: the notes beside a name ("has one", "refused",
	"recent") are information for the player's judgment, and every candidate can be picked.

	THREE BLOCKS, divided by a hairline:
	  1. The names, grouped under Your Alts, Your Guild and Strangers and indented beneath each
	     heading, an empty group left out. Your alts read alphabetically: they are your own
	     characters, found by name. The other two keep ranked order, best match first.
	  2. What to do instead of giving it away: Disenchant, on any gear row, and Keep Item.
	  3. Rescan for Better Match, a targeted search for this one item.
]]
local SECTIONS = {
	{ rank = 1, key = "PICKER_SECTION_ALTS", alphabetical = true },
	{ rank = 2, key = "PICKER_SECTION_GUILD" },
	{ rank = 3, key = "PICKER_SECTION_STRANGERS" },
}

-- The disenchant icon, inline at the font's height: on a row's dropdown and on the picker's own Disenchant entry.
UI.DISENCHANT_ICON = "|TInterface\\Icons\\INV_Enchant_Disenchant:0|t"

local function ByName(a, b)
	if (a.name or "") ~= (b.name or "") then
		return (a.name or "") < (b.name or "")
	end
	return (a.level or 0) < (b.level or 0)
end

--[[
	The Disenchant entry. Any gear row, not only a Kept one: whether a green is worth more as
	dust than as somebody's upgrade is the player's call. Consumables never disenchant, so they
	get none. With no enchanter picked it still shows, disabled, saying where one is picked.
]]
local function DisenchantOption(item)
	if item.kind ~= "gear" then
		return nil
	end
	local enchanter = ns.Alts:DisenchantRecipient()
	if not enchanter then
		return {
			text = UI.DISENCHANT_ICON .. " " .. L["PICKER_DISENCHANT_OPTION"],
			tooltip = L["PICKER_DISENCHANT_NONE_DESCRIPTION"],
			disabled = true,
		}
	end
	return {
		text = UI.DISENCHANT_ICON .. " " .. L["PICKER_DISENCHANT_OPTION"],
		tooltip = L["PICKER_DISENCHANT_DESCRIPTION"]:format(ns.ColorName(enchanter.name, enchanter.class)),
		pick = enchanter,
	}
end

function UI:PickerOptions(item)
	local options = {}

	local candidates = self:Candidates(item)
	if #candidates == 0 then
		-- An empty list has two causes and only one is fixed by querying again, so say which.
		table.insert(options, {
			text = GetColor("TITLE")
				.. ((item.state == ns.Matcher.UNREADABLE) and L["ITEM_STATS_UNREADABLE"] or L["PICKER_NONE_IN_RANGE"])
				.. "|r",
			disabled = true,
		})
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
			table.insert(options, {
				text = GetColor("TITLE") .. L[section.key] .. "|r",
				header = true,
				disabled = true,
			})
			for _, person in ipairs(people) do
				self:AddCandidateOption(options, item, person)
			end
		end
	end

	table.insert(options, { separator = true, disabled = true })
	local disenchant = DisenchantOption(item)
	if disenchant then
		table.insert(options, disenchant)
	end
	-- Keep Item clears the name and unticks the row, the same as unticking its checkbox.
	table.insert(options, {
		text = L["PICKER_KEEP_OPTION"],
		clear = true,
	})

	table.insert(options, { separator = true, disabled = true })
	table.insert(options, {
		text = GetColor("INFO") .. L["PICKER_FIND_FOR_ITEM"] .. "|r",
		findForItem = true,
	})

	return options
end

-- One name in the picker: class-colored, its level, and the note that applies to it, if any.
function UI:AddCandidateOption(options, item, person)
	local held = not person.alt and MatchList:AssignedTo()[person.name] and MatchList:AssignedTo()[person.name] ~= item
	local refused = not ns.Fairness:IsReachable(person.name)

	-- The note stays short to fit the row; hovering the name says what it means.
	local noteKey
	if refused then
		noteKey = "PICKER_NOTE_REFUSED"
	elseif held then
		noteKey = "PICKER_NOTE_HAS_ONE"
	elseif not person.alt and not ns.Fairness:IsFresh(person.name, person.level) then
		noteKey = "PICKER_NOTE_RECENT"
	end
	local note = noteKey and (" " .. GetColor("MUTED") .. L[noteKey] .. "|r") or ""

	-- No class word: the name is already class-colored, and the color says it.
	table.insert(options, {
		text = ("%s " .. GetColor("MUTED") .. "(%d)|r%s"):format(
			ns.ColorName(person.name, person.class),
			person.level,
			note
		),
		tooltip = noteKey and L[noteKey .. "_DESCRIPTION"],
		pick = person,
		indent = true,
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
