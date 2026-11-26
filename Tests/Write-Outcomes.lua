--[[
	Rewrites Tests/Outcomes/, accepting every row that moved; the diff is the change in who gets what.

		cd Play-It-Forward && lua5.1 Tests/Write-Outcomes.lua
]]


local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path

ADDON_ROOT = here:match("^(.*)/[^/]*$") or "."

local Outcomes = require("Outcomes")

for _, entry in ipairs(Outcomes.FLAVORS) do
	local lines = Outcomes.Build(entry)
	local handle = assert(io.open(Outcomes.Path(entry), "w"))
	handle:write(table.concat(lines, "\n"), "\n")
	handle:close()
	print(("%-10s %d rows"):format(entry.name, #lines))
end
