--[[
	Telling two copies of one item apart.

	Two "Ivycloth Robe" in different bag slots are two items, and a name is not enough
	to say which is which. The window's rows, the diagnostics listings and the mail jobs
	all need to name a specific one, and a report that prints the name twice cannot say
	whether they went to two people or to one.

	The reported symptom was duplicates being sent to the same person. It could not be
	reproduced -- assignment is keyed on the recipient and holds across over-subscribed
	bags, multi-round searching, rescans and part-completed runs. So what is pinned here
	is the invariant itself, enforced where it would do damage rather than merely
	intended: Distributor never receives two jobs for one recipient, whatever the list
	says.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- One item definition in several bag slots: identical links, as the client reports them.
local function copies(ns, count)
	local robe = Stub.Item({
		name = "Ivycloth Robe",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1,
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
	})
	local bag = {}
	for index = 1, count do
		bag[index] = robe
	end
	Stub.SetBackpack(bag)
	ns.fire("MAIL_SHOW")
	return robe
end

local ROSTER = {
	{ name = "Mage1", level = 18, class = "MAGE" },
	{ name = "Mage2", level = 19, class = "MAGE" },
	{ name = "Priest1", level = 18, class = "PRIEST" },
}

--------------------------------------------------------------------------------

test("copies of one item each get their own identity", function()
	local ns = load()
	copies(ns, 3)

	local seen = {}
	for _, item in ipairs(ns.UI:Items()) do
		check(item.uid ~= nil, "the item has a uid")
		check(not seen[item.uid], "and it is unique: " .. tostring(item.uid))
		seen[item.uid] = true
	end
end)

test("an identity survives a rescan of the same bag", function()
	local ns = load()
	copies(ns, 3)

	local before = {}
	for _, item in ipairs(ns.UI:Items()) do
		before[#before + 1] = item.uid
	end

	--[[
		A rescan rebuilds every record from scratch, so an identity that came from the
		record rather than from the slot would change under it -- and pairings are
		restored by exactly this key.
	]]
	ns.fire("BAG_UPDATE", 0)
	for _, timer in ipairs(Stub.timers) do
		if timer.fn and not timer.canceled then
			timer.fn()
		end
	end

	for index, item in ipairs(ns.UI:Items()) do
		equal(item.uid, before[index], "identity held across the rescan")
	end
end)

test("copies are handed to different people", function()
	local ns = load()
	copies(ns, 3)
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local seen = {}
	for _, item in ipairs(ns.UI:Items()) do
		if item.recipient then
			check(not seen[item.recipient.name], item.recipient.name .. " holds only one copy")
			seen[item.recipient.name] = true
		end
	end
end)

--[[
	The guard, tested by forcing the state it defends against. Nothing in the add-on
	produces this pairing on its own -- that is what could not be reproduced -- so it is
	written in by hand here. What matters is that mail cannot go out on it.
]]
test("two items pointing at one person only produce one mail job", function()
	local ns = load()
	copies(ns, 2)
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local items = ns.UI:Items()
	items[2].recipient, items[2].send = items[1].recipient, true

	ns.UI:Distribute()

	equal(#Stub.sent, 1, "only one mail went out")
	local warned = false
	for _, message in ipairs(Stub.printed) do
		if tostring(message):find("already") then
			warned = true
		end
	end
	check(warned, "and it said so rather than dropping the item silently")
end)

test("a legitimate second recipient is not mistaken for a duplicate", function()
	local ns = load()
	copies(ns, 2)
	Stub.whoResults = ROSTER
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	ns.UI:Distribute()
	ns.fire("MAIL_SUCCESS")
	ns.fire("MAIL_SUCCESS")

	equal(#Stub.sent, 2, "both copies went")
	check(Stub.sent[1].recipient ~= Stub.sent[2].recipient, "to two different people")
end)

--[[
	The listing half of the ask. A roster report naming "Ivycloth Robe" twice cannot say
	whether one person is a candidate for both copies or the report is repeating itself.
]]
test("the roster report distinguishes copies of one item", function()
	local ns = load()
	copies(ns, 2)
	Stub.whoResults = { ROSTER[1] }
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	local report = ns:BuildRosterReport()
	local first, second = report:match("Ivycloth Robe%s*%(([^)]+)%)"), nil
	local count = 0
	for label in report:gmatch("Ivycloth Robe%s*%(([^)]+)%)") do
		count = count + 1
		if count == 2 then
			second = label
		end
	end

	equal(count, 2, "both copies are listed")
	check(first ~= second, ("and they are labelled apart: %s vs %s"):format(tostring(first), tostring(second)))
end)
