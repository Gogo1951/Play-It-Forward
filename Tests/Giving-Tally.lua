--[[
	The account-wide giving tally. RecordSend is the mailer's one writer, called on each
	successful send, so this drives it directly with the two shapes it has to tell apart: an
	equippable, which counts toward item levels, and a consumable stack, which does not but whose
	whole stack counts toward the item total. The four counters are the read the options panel and
	Features/Generosity-Broadcast.lua both make through Get.
]]

local Harness = require("Harness")
local test, equal = Harness.test, Harness.equal
local Stub = Harness.Stub

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--------------------------------------------------------------------------------

test("RecordSend tallies an equippable and a consumable stack", function()
	local ns = load()

	-- A green cloak: equippable, item level 40, vendor value 500 copper.
	local cloak = Stub.Item({ name = "Test Cloak", equipLoc = "INVTYPE_CLOAK", itemLevel = 40, sellPrice = 500 })
	-- A stack of 20 waters: not equippable, 5 copper each.
	local water = Stub.Item({ name = "Test Water", classID = 0, equipLoc = "", sellPrice = 5 })

	ns.Generosity:RecordSend(cloak.link, 1)
	ns.Generosity:RecordSend(water.link, 20)

	local gifts, items, itemLevels, value = ns.Generosity:Get()
	equal(gifts, 2, "two mailings")
	equal(items, 21, "one cloak plus twenty waters")
	equal(itemLevels, 40, "only the equippable adds item level")
	equal(value, 500 * 1 + 5 * 20, "vendor price times quantity, summed")
end)

--[[
	quantity defaults to one, the same fallback the mailer uses when the captured stack size comes
	back empty, so a gift with no count still lands as a single item.
]]
test("RecordSend counts one item when quantity is omitted", function()
	local ns = load()
	local ring = Stub.Item({ name = "Test Ring", equipLoc = "INVTYPE_FINGER", itemLevel = 15, sellPrice = 100 })

	ns.Generosity:RecordSend(ring.link)

	local gifts, items, itemLevels, value = ns.Generosity:Get()
	equal(gifts, 1, "one mailing")
	equal(items, 1, "defaults to a single item")
	equal(itemLevels, 15, "item level counted")
	equal(value, 100, "value counted once")
end)

-- A fresh load starts the account tally at zero, so one case never reads another's total.
test("the tally starts empty", function()
	local ns = load()
	local gifts, items, itemLevels, value = ns.Generosity:Get()
	equal(gifts, 0, "no gifts")
	equal(items, 0, "no items")
	equal(itemLevels, 0, "no item levels")
	equal(value, 0, "no value")
end)
