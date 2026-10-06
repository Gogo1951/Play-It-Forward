local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

-- Every message the add-on emits. Player-only: no target marker and no Announce helpers.

--------------------------------------------------------------------------------
-- Print Outs (Player Only)
--------------------------------------------------------------------------------

--[[
	ONE PRINT, ONE BODY COLOR, AND IT IS TEXT. There is no PrintWarning: the palette has no warning
	role, and a whole chat line of gold reads as shouting. Urgency is the copy's job -- a message
	that needs the player to do something says what to do in its first clause.
]]
--[[
	The branded line, built rather than printed, because chat is not the only place it appears:
	Features/Generosity-Tooltip.lua heads its block with the same line. One builder so the two can
	never brand the add-on differently, and so a locale body stays the body alone.
]]
-- Format: |cff[INFO]Add-on Name|r |cff[SEPARATOR]//|r |cff[TEXT]Message|r
function ns:BuildBrandedLine(message)
	return GetColor("INFO")
		.. L["ADDON_TITLE"]
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
