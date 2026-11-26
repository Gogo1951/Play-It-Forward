--[[
	Never Give Away: items the player picked off a row's list are never offered again, until they
	take one back on What to Give Away. Kept per profile, by item ID, so every stack of it goes.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- A potion the scan would list on its merits: the level rule lifted, at the level cap.
local function potion(ns, count)
	local Stub = Harness.Stub
	Stub.playerLevel = 60
	ns.db.profile.consumableLevelGap = 0
	local data = ns.Data.POTIONS[1]
	return Stub.Item({ id = data[1], name = "Never Test", quality = 1, classID = 0, bindType = 0, count = count })
end

--------------------------------------------------------------------------------

test("the list starts empty", function()
	local ns = load()
	equal(next(ns.db.profile.neverGive), nil, "nothing on it")
	equal(#ns.Bags:NeverGiveList(), 0, "and nothing listed")
end)

test("an item on the list is never offered, with its own reason", function()
	local ns = load()
	local def = potion(ns, 5)
	Harness.Stub.SetBackpack({ def })
	equal(#ns.Scanner:Scan(), 1, "offered before")

	ns.Bags:NeverGive(def.id, def.link)
	equal(#ns.Scanner:Scan(), 0, "not offered once on the list")
	local record, reason = ns.Scanner:Classify(0, 1)
	equal(record, nil, "no record")
	equal(reason, ns.Scanner.REJECT.NEVER_GIVE, "and the reason says why")
end)

test("every stack of the item goes, since the list is by item ID", function()
	local ns = load()
	local first, second = potion(ns, 5), potion(ns, 3)
	Harness.Stub.SetBackpack({ first, second })
	equal(#ns.Scanner:Scan(), 2, "both stacks offered before")

	ns.Bags:NeverGive(first.id, first.link)
	equal(#ns.Scanner:Scan(), 0, "neither stack offered after")
end)

test("gear on the list is held back too", function()
	local ns = load()
	local Stub = Harness.Stub
	local robe = Stub.Item({ name = "Never Robe", equipLoc = "INVTYPE_ROBE", reqLevel = 20 })
	Stub.SetBackpack({ robe })

	ns.Bags:NeverGive(robe.id, robe.link)
	local record, reason = ns.Scanner:Classify(0, 1)
	equal(record, nil, "no record")
	equal(reason, ns.Scanner.REJECT.NEVER_GIVE, "held back as never given")
end)

test("putting it on the list says so, and where to bring it back", function()
	local ns = load()
	local Stub = Harness.Stub
	local def = potion(ns, 5)
	Stub.SetBackpack({ def })

	ns.Bags:NeverGive(def.id, def.link)
	local line = Stub.printed[#Stub.printed]
	equal(line, ns.L["CHAT_NEVER_GIVE"]:format(def.link, ns.L["TAB_GIVE_AWAY"]), "the chat line")
	check(line:find(def.link, 1, true) ~= nil, "names the item by its link")
end)

test("taking it back offers it again", function()
	local ns = load()
	local def = potion(ns, 5)
	Harness.Stub.SetBackpack({ def })

	ns.Bags:NeverGive(def.id, def.link)
	equal(#ns.Bags:NeverGiveList(), 1, "listed on What to Give Away")
	ns.Bags:GiveAgain(def.id)
	equal(#ns.Bags:NeverGiveList(), 0, "off the list")
	equal(#ns.Scanner:Scan(), 1, "offered again")
end)

test("the list is the profile's, so a profile without it offers the item", function()
	local ns = load()
	local def = potion(ns, 5)
	Harness.Stub.SetBackpack({ def })

	ns.Bags:NeverGive(def.id, def.link)
	ns.db.profile.neverGive = {}
	equal(#ns.Scanner:Scan(), 1, "offered under a profile with an empty list")
end)
