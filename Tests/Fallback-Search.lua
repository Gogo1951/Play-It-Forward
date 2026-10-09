--[[
	A fallback pairing is a placeholder, never the end of the search.

	The reported case: two main-hand swords, contenders WARRIOR and ROGUE by the one-hand
	rule, paired -- and TICKED -- with two level-18 paladins because no warrior or rogue
	was in the pool yet, while the plan cleared itself as though the search had finished.
	One press of Distribute and both swords mail to a class the verdict says they are not
	for.

	Two rules pin that shut. A gift held by a class outside the verdict's contenders
	still counts as searching: its band stays on the plan, narrowed to the contenders,
	and every later answer re-assigns, which is what flips the row the moment a warrior
	turns up. It arrives ticked like any match -- a named row with its box off read as a
	failed match (2026-10-09) -- but unpinned, so the upgrade can still take it. Only
	the player's own hand pins it, and a pinned row ends the search for that item.
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

--[[
	One press of Find Recipients, answered with the given roster -- as a capped answer, so
	the server is understood to have more people than it sent and the hunt goes on.
]]
local function search(ns, results)
	Stub.now = Stub.now + 60
	Stub.whoResults = results
	Stub.whoTotal = 999
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
	equal(ns.UI:Items()[1].send, true, "ticked, like any match")
	check(not ns.UI:Items()[1].pinned, "but not pinned, so a contender can still take it")
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

test("an exhausted hunt leaves the fallback standing", function()
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
	equal(ns.UI:Items()[1].send, true, "ticked to send")
end)

test("a fallback ticked by hand is the player's decision", function()
	local ns = load()
	mainHandSword(ns)

	search(ns, { PALADIN })
	local item = ns.UI:Items()[1]
	ns.UI:_toggleRow(item, true)

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
