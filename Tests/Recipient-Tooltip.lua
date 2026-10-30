--[[
	The recipient tooltip's Best fit line: the classes the verdict ranks highest for an item,
	best first and never more than three, so a match shows its reasoning. Read through
	UI:BestFitLine, the text the tooltip adds.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function names(ns, line)
	local found = {}
	for _, token in ipairs(ns.Matcher:Classes()) do
		local at = line:find(LOCALIZED_CLASS_NAMES_MALE[token], 1, true)
		if at then
			found[#found + 1] = { token = token, at = at }
		end
	end
	table.sort(found, function(a, b)
		return a.at < b.at
	end)
	local out = {}
	for index, entry in ipairs(found) do
		out[index] = entry.token
	end
	return out
end

--------------------------------------------------------------------------------

test("gear names the verdict's best class first", function()
	local ns = load()
	local line = ns.UI:BestFitLine({
		kind = "armor",
		verdict = {
			best = "PRIEST",
			contenders = { "DRUID", "PRIEST", "PALADIN" },
			fits = { DRUID = 5, PRIEST = 9, PALADIN = 7 },
		},
	})
	check(line ~= nil and line:find("^Best fit for ") ~= nil, "in the locale's words")
	local listed = names(ns, line)
	equal(listed[1], "PRIEST", "the best class leads")
	equal(listed[2], "PALADIN", "then the next best fit")
	equal(listed[3], "DRUID", "then the rest")
end)

test("never more than three classes", function()
	local ns = load()
	local line = ns.UI:BestFitLine({
		kind = "armor",
		verdict = {
			best = "WARRIOR",
			contenders = { "WARRIOR", "PALADIN", "ROGUE", "HUNTER", "DRUID" },
			fits = { WARRIOR = 9, PALADIN = 8, ROGUE = 7, HUNTER = 6, DRUID = 5 },
		},
	})
	equal(#names(ns, line), 3, "a shortlist of three")
end)

test("a consumable every class wants equally adds no line", function()
	local ns = load()
	local everyone = ns.Matcher:Classes()
	equal(ns.UI:BestFitLine({ kind = "consumable", verdict = { contenders = everyone } }), nil, "no random three")
	local line = ns.UI:BestFitLine({ kind = "consumable", verdict = { contenders = { "MAGE", "PRIEST" } } })
	equal(#names(ns, line), 2, "but a short field is named")
end)

test("no verdict or no contenders adds nothing", function()
	local ns = load()
	equal(ns.UI:BestFitLine({}), nil, "no verdict yet")
	equal(ns.UI:BestFitLine({ verdict = { contenders = {} } }), nil, "nobody in the running")
end)

-- The reported case: cloth anyone can wear must not read as suiting every class.
test("a real Intellect cloak names its casters, not everyone", function()
	local ns = load()
	Stub.SetBackpack({
		Stub.Item({
			name = "Sentry Cloak",
			reqLevel = 19,
			equipLoc = "INVTYPE_CLOAK",
			classID = 4,
			subclassID = 1,
			stats = { ITEM_MOD_INTELLECT_SHORT = 5 },
		}),
	})
	ns.fire("MAIL_SHOW")
	local item = ns.UI:Items()[1]
	local line = item and ns.UI:BestFitLine(item)
	check(line ~= nil, "a Best fit line")
	local listed = line and names(ns, line) or {}
	check(#listed >= 1 and #listed <= 3, ("one to three classes, got %d"):format(#listed))
	equal(listed[1], item and item.verdict.best, "the verdict's best leads")
end)

--------------------------------------------------------------------------------
-- The row's tick box
--------------------------------------------------------------------------------

test("rows Distribute can never mail have no live tick", function()
	local ns = load()
	local M = ns.Matcher
	equal(ns.UI:CanTick({ state = M.UNREADABLE }), false, "unreadable")
	equal(ns.UI:CanTick({ state = M.LEFTOVER }), false, "kept")
	equal(ns.UI:CanTick({ state = M.GIFT }), true, "waiting on a search")
	equal(ns.UI:CanTick({ state = M.LEFTOVER, recipient = { name = "Keefe" } }), true, "kept, then picked by hand")
end)
