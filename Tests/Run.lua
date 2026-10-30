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
require("Status-Line")
require("Recipient-Tooltip")
require("Alts")
require("Disenchant")
require("Window-Skin")
require("Zone-Search")
require("Placement")
require("Recipient-Priority")
require("Stat-Scoring")
require("Talent-Trees")
require("Assignment")
require("Tooltip-Parsing")
require("Item-Identity")
require("Mail-Errors")
require("Manual-Assignment")
require("Query-Building")
require("Level-Band")
require("Options-Values")
require("Options-Open")
require("Mail-Contents")
require("Item-Rules")
require("Consumable-Rules")
require("Consumable-Kinds")
require("Scroll-Rules")
require("Oil-Stone-Rules")
require("Guild-Roster")
require("Reassignment")
require("Fallback-Search")
require("Weapon-Rules")
require("Armor-Proficiency")
require("Event-Log-Noise")
require("Giving-Tally")
require("Generosity-Broadcast")
require("Generosity-Tooltip")
require("Mists")
require("Spec-Choices")
require("Alts-And-Guilds")
require("Outcomes")

os.exit(Harness.run() == 0 and 0 or 1)
