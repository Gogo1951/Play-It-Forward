--[[
	The mail window under ElvUI, and its corner grip.

	With ElvUI loaded, its Skins module dresses the window's buttons, ticks, dropdowns and
	scrollbars; without it nothing changes, and a Skins module that throws leaves the window
	working. The grip resizes the window, and the size is kept per profile.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local function cloak()
	return Stub.Item({
		name = "Sentry Cloak",
		reqLevel = 19,
		equipLoc = "INVTYPE_CLOAK",
		classID = 4,
		subclassID = 1,
		stats = { ITEM_MOD_INTELLECT_SHORT = 5 },
	})
end

-- A stand-in for ElvUI's Skins module that counts what it was asked to dress.
local function fakeElvUI(throws)
	local calls = { Button = 0, CheckBox = 0, ScrollBar = 0 }
	local skins = {}
	for kind in pairs(calls) do
		skins["Handle" .. kind] = function()
			calls[kind] = calls[kind] + 1
			if throws then
				error("skin failed")
			end
		end
	end
	ElvUI = {
		{
			GetModule = function(_, name)
				return name == "Skins" and skins or nil
			end,
		},
	}
	return calls
end

--------------------------------------------------------------------------------

test("under ElvUI every kind of control is skinned", function()
	local calls = fakeElvUI()
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")
	ElvUI = nil

	check(ns.UI.frame ~= nil, "the window opened")
	-- Find Recipients, Distribute, two top-bar dropdowns and one row's recipient dropdown.
	check(calls.Button >= 5, ("buttons and dropdowns skinned, %d calls"):format(calls.Button))
	-- Gear, Consumables, five kinds and one row's tick.
	check(calls.CheckBox >= 8, ("ticks skinned, %d calls"):format(calls.CheckBox))
	check(calls.ScrollBar >= 1, "the list's scrollbar skinned")
end)

test("a Skins module that throws leaves the window working", function()
	fakeElvUI(true)
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")
	ElvUI = nil

	check(ns.UI.frame ~= nil and ns.UI.frame:IsShown(), "the window still opens")
	equal(#ns.UI:Items(), 1, "with its list")
end)

test("without ElvUI nothing is skinned and nothing breaks", function()
	ElvUI = nil
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")
	check(ns.UI.frame ~= nil and ns.UI.frame:IsShown(), "the window opens")
end)

--------------------------------------------------------------------------------
-- The corner grip
--------------------------------------------------------------------------------

test("resizing saves the size and position per profile", function()
	local ns = load()
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")
	ns.UI:Relayout()
	ns.UI:SaveGeometry()

	check(ns.db.profile.windowSize.width ~= nil, "a width saved")
	check(ns.db.profile.windowSize.height ~= nil, "and a height")
	check(ns.UI.frame.rowWidth > 0, "the rows follow the window's width")
end)

test("a saved size outside the grip's limits is held inside them", function()
	local ns = load()
	ns.db.profile.windowSize = { width = 5000, height = 10 }
	Stub.SetBackpack({ cloak() })
	ns.fire("MAIL_SHOW")
	check(ns.UI.frame ~= nil, "the window still opens")
end)
