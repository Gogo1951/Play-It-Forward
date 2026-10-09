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
	"recent") are information for the player's judgment, and every candidate can be picked. The
	list ends with a divider and a targeted search for this one item.
]]
function UI:_pickerOptions(item)
	local options = { {
		text = GetColor("MUTED") .. L["PICKER_KEEP_OPTION"] .. "|r",
		clear = true,
	} }

	local candidates = self:_candidates(item)
	if #candidates == 0 then
		-- An empty list has two causes and only one is fixed by querying again, so say which.
		table.insert(options, {
			text = GetColor("TITLE")
				.. ((item.state == ns.Matcher.UNREADABLE) and L["ITEM_STATS_UNREADABLE"] or L["PICKER_NONE_IN_RANGE"])
				.. "|r",
			disabled = true,
		})
	end

	for _, person in ipairs(candidates) do
		local held = MatchList:AssignedTo()[person.name] and MatchList:AssignedTo()[person.name] ~= item
		local refused = not ns.Fairness:IsReachable(person.name)

		local note = ""
		if refused then
			note = L["PICKER_NOTE_REFUSED"]
		elseif held then
			note = L["PICKER_NOTE_HAS_ONE"]
		elseif not ns.Fairness:IsFresh(person.name, person.level) then
			note = L["PICKER_NOTE_RECENT"]
		end
		if note ~= "" then
			note = " " .. GetColor("MUTED") .. note .. "|r"
		end

		-- No class word: the name is already class-colored, and the color says it.
		table.insert(options, {
			text = ("%s " .. GetColor("MUTED") .. "(%d)|r%s"):format(
				ns.ColorName(person.name, person.class),
				person.level,
				note
			),
			pick = person,
		})
	end

	table.insert(options, { separator = true, disabled = true })
	table.insert(options, {
		text = GetColor("INFO") .. L["PICKER_FIND_FOR_ITEM"] .. "|r",
		findForItem = true,
	})

	return options
end

function UI:_openPicker(row)
	local item = row._item
	if not item then
		return
	end
	Picker:Open(row.recipButton, self:_pickerOptions(item), function(opt)
		UI:_pickerSelect(item, opt)
	end)
end

-- What a picked entry does, off the frame so the tests can drive it.
function UI:_pickerSelect(item, opt)
	if opt.findForItem then
		self:FindRecipientsForItem(item)
		return
	end
	self:_setRecipient(item, opt.pick)
end

function UI:_setRecipient(item, who)
	--[[
		THE PLAYER'S PICK IS NEVER REFUSED. A name already
		holding another row is taken from it, and the freed row drops back to auto-assignment
		-- unpinned, or it would read as a deliberate keep. A name the server bounced earlier
		is theirs to retry. The picker's notes state these facts; they are not gates.
	]]
	if who then
		local other = MatchList:AssignedTo()[who.name]
		if other and other ~= item then
			other.recipient, other.send, other.pinned = nil, true, false
		end
	end

	if item.recipient then
		MatchList:AssignedTo()[item.recipient.name] = nil
	end

	--[[
		Pinned because a player chose it: _assign rebuilds only what it decided itself. Keep Item
		included, where "nobody" is the choice.
	]]
	item.pinned = true

	if who then
		item.recipient, item.send = who, true
		MatchList:AssignedTo()[who.name] = item
	else
		item.recipient, item.send = nil, false
	end

	self:Refresh()
end

--[[
	The checkbox, which is always live. A tick means "give this away", and every row starts
	ticked (README-Notes.md). Unticking is the player's keep: it pins the row, recipient and all,
	because the tick is the last thing between an item and a stranger's mailbox and a rebuild
	that re-ticks it has overridden them. Ticking a row with a name sends it to that name, still
	pinned; ticking a bare row unpins it and the allocator runs, so it is matched like any other.
]]
function UI:_toggleRow(item, checked)
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
	self:_assign()
end
