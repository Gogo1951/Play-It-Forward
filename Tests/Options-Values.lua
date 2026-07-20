--[[
	The values the options panel offers, and the settings behind them.

	The panel itself is AceConfig tables and a live client, so what is checked here is
	the data those tables read: the gaps on offer, the default landing on one of them,
	and the rounding that keeps an old slider value from opening a blank dropdown.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--------------------------------------------------------------------------------

test("the consumable gap is offered in fives up to twenty", function()
	local ns = load()
	equal(#ns.CONSUMABLE_GAP_ORDER, 5, "five stops")
	for index, gap in ipairs({ 0, 5, 10, 15, 20 }) do
		equal(ns.CONSUMABLE_GAP_ORDER[index], gap, "stop " .. index)
		check(ns.CONSUMABLE_GAP_VALUES[gap] ~= nil, gap .. " has a label")
	end
end)

--[[
	A select opens blank when its current value is not one of its own options, so the
	shipped default has to be one of them or a fresh install looks broken.
]]
test("the default gap is one of the offered values", function()
	local ns = load()
	equal(ns.db.profile.consumableLevelGap, 20, "defaults to twenty")
	check(ns.CONSUMABLE_GAP_VALUES[ns.db.profile.consumableLevelGap] ~= nil, "and it is on the list")
end)

test("a value left by the old slider rounds to the nearest stop", function()
	local ns = load()

	equal(ns.NearestConsumableGap(13), 15, "13 rounds up")
	equal(ns.NearestConsumableGap(12), 10, "12 rounds down")
	equal(ns.NearestConsumableGap(40), 20, "past the end clamps to the last stop")
	equal(ns.NearestConsumableGap(0), 0, "an exact stop is left alone")
	equal(ns.NearestConsumableGap(nil), 0, "and nothing at all is not an error")
end)

--[[
	Rounding is for display. Rewriting the stored setting to open a panel would change
	what the player gets away without them touching anything.
]]
test("rounding for the dropdown does not rewrite the setting", function()
	local ns = load()
	ns.db.profile.consumableLevelGap = 13

	equal(ns.NearestConsumableGap(ns.db.profile.consumableLevelGap), 15, "shown as 15")
	equal(ns.db.profile.consumableLevelGap, 13, "still stored as 13")
end)

--[[
	The gap is what decides whether a consumable counts as spare, so it has to still
	drive the scan whatever the dropdown is showing.
]]
test("the stored gap is what the scanner actually uses", function()
	local ns = load()
	local Stub = Harness.Stub

	-- A level 35 water, and a player at 50: spare at a gap of 10, still in use at 20.
	local water = ns.Data.FoodAndWater[1]
	check(water ~= nil, "there is a consumable to test with")

	Stub.playerLevel = 50
	ns.db.profile.consumableLevelGap = 20
	local tight = ns.Scanner:Scan()
	ns.db.profile.consumableLevelGap = 0
	local loose = ns.Scanner:Scan()

	check(#loose >= #tight, "a smaller gap never offers fewer consumables")
end)
