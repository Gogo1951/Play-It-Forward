local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

--------------------------------------------------------------------------------
-- Print Outs (Player Only)
--------------------------------------------------------------------------------

-- No PrintWarning on purpose: the palette has no warning role, and urgency is the copy's job.
function ns:BuildBrandedLine(message, nameKey)
	return GetColor("INFO")
		.. L[nameKey or "ADDON_TITLE"]
		.. "|r "
		.. GetColor("SEPARATOR")
		.. "//"
		.. "|r "
		.. GetColor("TEXT")
		.. tostring(message)
		.. "|r"
end

function ns:PrintMessage(message)
	print(ns:BuildBrandedLine(message))
end
