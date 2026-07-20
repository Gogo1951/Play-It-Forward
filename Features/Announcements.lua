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
-- Format: |cff[INFO]Add-on Name|r |cff[SEPARATOR]//|r |cff[TEXT]Message|r
function ns:PrintMessage(message)
	print(
		GetColor("INFO")
			.. L["ADDON_TITLE"]
			.. "|r "
			.. GetColor("SEPARATOR")
			.. "//"
			.. "|r "
			.. GetColor("TEXT")
			.. tostring(message)
			.. "|r"
	)
end
