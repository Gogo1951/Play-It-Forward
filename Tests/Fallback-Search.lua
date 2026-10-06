--[[
	A fallback pairing is a suggestion, never a send.

	The reported case: two main-hand swords, contenders WARRIOR and ROGUE by the one-hand
	rule, paired -- and TICKED -- with two level-18 paladins because no warrior or rogue
	was in the pool yet, while the plan cleared itself as though the search had finished.
	One press of Distribute and both swords mail to a class the verdict says they are not
	for.

	Two rules pin that shut. A gift held by a class outside the verdict's contenders
	still counts as searching: its band stays on the plan, narrowed to the contenders,
	and every later answer re-assigns, which is what flips the row the moment a warrior
	turns up. And a fallback pairing arrives unticked: the paladin shows on the row so
	the player can see who else could take it, but only their own hand ticks it. A
	pinned row is the player's decision and ends the search for that item as before.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Statless on purpose, like the reported item: nobody has a stat claim, so everyone is
	admitted and the one-hand rule alone names the warrior and the rogue. Requires 19,
	so the recipient band is 17-18.
]]
local function mainHandSword(ns)
	Stub.SetBackpack({
		Stub.Item({
			name = "Bluegill Kukri",
			quality = 2,
			reqLevel = 19,
			itemLevel = 24,
			equipLoc = "INVTYPE_WEAPONMAINHAND",
			classID = 2,
			subclassID = 7, -- 1H sword
			bindType = 2,
			stats = {},
		}),
	})
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

local PALADIN = { name = "Palario", level = 18, class = "PALADIN" }
local WARRIOR = { name = "Warry", level = 18, class = "WARRIOR" }

--------------------------------------------------------------------------------

test("a fallback pairing keeps the search alive", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })

	equal(ns.UI:Items()[1].recipient.name, "Palario", "the paladin is suggested meanwhile")
	equal(ns.UI:Items()[1].send, false, "but not ticked: a fallback sends only by the player's own hand")
	check(ns.Who:Remaining() > 0, "and the plan is still standing, not cleared")
end)

test("the surviving hunt asks only for the classes in contention", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })

	local label = tostring(ns.Who:Peek())
	check(label:find("Warrior", 1, true) ~= nil, "the next attempt names the warrior: " .. label)
	check(label:find("Paladin", 1, true) == nil, "and no longer asks for the class already holding it")
end)

test("a contender pairing still ends the search", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { WARRIOR })

	equal(ns.UI:Items()[1].recipient.name, "Warry", "the warrior takes it")
	equal(ns.UI:Items()[1].send, true, "ticked: a contender pairing is a real send")
	equal(ns.Who:Remaining(), 0, "and the search is done")
end)

test("the hunt upgrades the fallback when a contender turns up", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })
	search(ns, { WARRIOR })

	equal(ns.UI:Items()[1].recipient.name, "Warry", "the warrior takes it off the paladin")
	equal(ns.UI:Items()[1].send, true, "ticked on arrival")
	equal(ns.Who:Remaining(), 0, "and only then is the search over")
end)

test("an exhausted hunt leaves the fallback standing, still unticked", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })
	for _ = 1, 10 do
		if ns.Who:Remaining() == 0 then
			break
		end
		search(ns, {})
	end

	equal(ns.Who:Remaining(), 0, "the plan drained rather than looping")
	equal(ns.UI:Items()[1].recipient.name, "Palario", "the paladin still holds the suggestion")
	equal(ns.UI:Items()[1].send, false, "and sending it stays the player's call")
end)

test("a fallback ticked by hand is the player's decision", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })
	local item = ns.UI:Items()[1]
	ns.UI:_setSend(item, true)

	search(ns, { WARRIOR })

	equal(item.recipient.name, "Palario", "the ticked paladin keeps it even when a warrior turns up")
	equal(item.send, true, "and stays ticked")
end)

test("a hand-picked fallback ends the search for that item", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })
	ns.UI:_setRecipient(ns.UI:Items()[1], PALADIN)

	ns.MatchList:Assign()
	equal(ns.Who:Remaining(), 0, "the player's choice is final, so nothing is left to hunt")
end)

--------------------------------------------------------------------------------

--[[
	The reported diagnostic read "stats: (none) via none" for an item whose tooltip
	plainly showed +3 Strength -- because a bare id was pasted, and GetItemStats and
	SetHyperlink want a link form. The report normalizes the paste rather than printing
	an answer that looks like a broken scanner.
]]
test("the verdict report reads a pasted item id", function()
	local ns = load()
	local def = Stub.Item({
		name = "Bluegill Kukri",
		quality = 2,
		reqLevel = 19,
		itemLevel = 24,
		equipLoc = "INVTYPE_WEAPONMAINHAND",
		classID = 2,
		subclassID = 7,
		bindType = 2,
		stats = { ITEM_MOD_STRENGTH_SHORT = 3 },
	})

	local report = ns:BuildItemVerdictReport(tostring(def.id))

	check(report:find("Could not read") == nil, "the id resolved")
	check(report:find("STRENGTH 3", 1, true) ~= nil, "and its stats were read")
end)
