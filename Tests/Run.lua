--[[
	Runs every case in Tests/ against the stubbed client.

		cd Play-It-Forward && lua Tests/Run.lua

	Exits non-zero when anything failed, so it can be wired to a hook or a build step.
]]

local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path

ADDON_ROOT = here:match("^(.*)/[^/]*$") or "."

local Harness = require("Harness")

require("Mailbox-Gate")
require("Delivery-Refresh")
require("Zone-Search")
require("Stat-Scoring")
require("Assignment")
require("Tooltip-Parsing")
require("Item-Identity")
require("Mail-Errors")
require("Manual-Assignment")
require("Query-Building")
require("Level-Band")
require("Options-Values")
require("Mail-Contents")
require("Item-Rules")
require("Consumable-Rules")
require("Reassignment")
require("Weapon-Rules")

os.exit(Harness.run() == 0 and 0 or 1)
