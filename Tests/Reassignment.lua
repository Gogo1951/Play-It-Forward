--[[
	Re-matching everything the add-on chose, every time the roster grows.

	Assignments used to be kept: a pass filled the items that had nobody and left the
	rest alone. That is wrong the moment a rule is soft. An "of the Owl" staff prefers a
	priest, a mage or a druid and falls back to a hunter, so a first press that finds
	only a hunter gives him the staff -- and a second press that finds a priest never
	revisits it. The item stays with its fallback because it is no longer "unassigned".

	So every pass now clears what the add-on decided and decides again against the whole
	roster. What it never touches is what the player decided: a row kept by
	hand, a recipient picked by hand, a tick taken off by hand. Those are pinned, and
	rebuilding over them is the reassignment-behind-your-back this add-on already got
	wrong once.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Intellect and Spirit: priests, mages and druids, with everyone else behind them.
local function owlStaff(ns, extra)
	local bag = {
		Stub.Item({
			name = "Dwarven Magestaff of the Owl",
			quality = 2,
			reqLevel = 20,
			itemLevel = 24,
			equipLoc = "INVTYPE_2HWEAPON",
			classID = 2,
			subclassID = 10,
			bindType = 2,
			stats = { ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_SPIRIT_SHORT = 6 },
		}),
	}
	for _, item in ipairs(extra or {}) do
		bag[#bag + 1] = item
	end
	Stub.SetBackpack(bag)
	ns.fire("MAIL_SHOW")
end

-- One press of Find Recipients, answered with the given roster.
local function search(ns, results)
	Stub.now = Stub.now + 60
	Stub.whoResults = results
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")
	Stub.FireTimers()
end

local function recipientOf(ns, name)
	for _, item in ipairs(ns.UI:Items()) do
		if item.name == name then
			return item.recipient and item.recipient.name
		end
	end
end

local HUNTER = { name = "Hunty", level = 18, class = "HUNTER" }
local PRIEST = { name = "Pri", level = 18, class = "PRIEST" }

--------------------------------------------------------------------------------

--[[
	The reported case, end to end.
]]
test("a fallback is reconsidered when a better class turns up", function()
	local ns = load()
	owlStaff(ns)

	search(ns, { HUNTER })
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), "Hunty", "the hunter takes it when he is all there is")

	search(ns, { PRIEST })
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), "Pri", "and loses it the moment a priest turns up")
end)

test("nobody ends up holding two items after a rebuild", function()
	local ns = load()
	owlStaff(ns, {
		Stub.Item({
			name = "Ivycloth Robe",
			quality = 2,
			reqLevel = 20,
			itemLevel = 24,
			equipLoc = "INVTYPE_CHEST",
			classID = 4,
			subclassID = 1,
			bindType = 2,
			stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
		}),
	})

	search(ns, { HUNTER, PRIEST })

	local seen = {}
	for _, item in ipairs(ns.UI:Items()) do
		if item.recipient then
			check(not seen[item.recipient.name], item.recipient.name .. " holds only one")
			seen[item.recipient.name] = true
		end
	end
end)

--------------------------------------------------------------------------------
-- What the player decided is never rebuilt
--------------------------------------------------------------------------------

test("a row kept by hand stays kept", function()
	local ns = load()
	owlStaff(ns)
	search(ns, { HUNTER })

	ns.UI:_setRecipient(ns.UI:Items()[1], nil) -- the Keep Item option
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), nil, "cleared")

	--[[
		A priest arriving is exactly the case that would otherwise reclaim it, since the
		rule says the staff is his.
	]]
	search(ns, { PRIEST })
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), nil, "and a later search does not undo it")
end)

test("a recipient picked by hand is not replaced by a better one", function()
	local ns = load()
	owlStaff(ns)
	search(ns, { HUNTER })

	ns.UI:_setRecipient(ns.UI:Items()[1], HUNTER)
	search(ns, { PRIEST })

	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), "Hunty", "the hand-picked hunter keeps it")
end)

test("a tick taken off by hand stays off", function()
	local ns = load()
	owlStaff(ns)
	search(ns, { HUNTER })

	local staff = ns.UI:Items()[1]
	ns.UI:_toggleRow(staff, false)
	equal(staff.send, false, "unticked")

	search(ns, { PRIEST })
	equal(ns.UI:Items()[1].send, false, "and a later search leaves it unticked")
end)

--[[
	Every row starts ticked, so a search needs nothing from the player. The untick is the
	one thing that holds a row back, and nothing but the player's own tick undoes it: not
	three presses of Find Recipients, and not a bag rescan that rebuilds every record.
]]
test("a row unticked before any search stays out of matching until it is ticked again", function()
	local ns = load()
	owlStaff(ns)

	local staff = ns.UI:Items()[1]
	equal(staff.send, true, "every row starts ticked")
	ns.UI:_toggleRow(staff, false)

	for _ = 1, 3 do
		search(ns, { PRIEST, HUNTER })
	end
	ns.UI:Rescan()

	staff = ns.UI:Items()[1]
	equal(staff.send, false, "still unticked after three searches and a rescan")
	equal(staff.recipient, nil, "and nobody was handed it")

	ns.UI:_toggleRow(staff, true)
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), "Pri", "ticked again, it is matched from the pool")
	equal(staff.send, true, "and ticked to send")
end)

--[[
	A rescan throws every item record away and builds new ones from the bags, so a pin
	that lived only on the old record would not survive one -- and Find Recipients
	rescans on every new plan.
]]
test("a hand-set row survives a bag rescan", function()
	local ns = load()
	owlStaff(ns)
	search(ns, { HUNTER })
	ns.UI:_setRecipient(ns.UI:Items()[1], nil)

	ns.fire("BAG_UPDATE", 0)
	Stub.FireTimers()

	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), nil, "still cleared after the rescan")
	search(ns, { PRIEST })
	equal(recipientOf(ns, "Dwarven Magestaff of the Owl"), nil, "and still cleared after another search")
end)

--[[
	A gift puts its recipient on cooldown until they are next seen at a higher level, so a
	later sighting has to carry its level into the pool. A pool entry frozen at the level it
	was first found at would keep the cooldown for the whole session.
]]
test("a recipient seen at a higher level is fresh again", function()
	local ns = load()
	local found = { name = "Levelling", level = 20, class = "MAGE" }
	ns.MatchList:AddResults({ found })
	ns.Fairness:Record("Levelling", 20)
	check(not ns.Fairness:IsFresh("Levelling", found.level), "on cooldown right after the gift")

	equal(
		ns.MatchList:AddResults({ { name = "Levelling", level = 20, class = "MAGE" } }),
		0,
		"a re-sighting at the same level changes nothing"
	)

	local changed = ns.MatchList:AddResults({ { name = "Levelling", level = 21, class = "MAGE" } })
	equal(changed, 1, "a re-sighting a level higher counts as a change")
	equal(ns.MatchList:Pools().MAGE[1].level, 21, "the pool entry reads the new level")
	check(ns.Fairness:IsFresh("Levelling", ns.MatchList:Pools().MAGE[1].level), "and the cooldown is over")
end)
