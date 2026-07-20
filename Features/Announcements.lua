local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

--[[
	Every message the add-on emits. Player-only: it prints to the sender and mails items, never
	group or whisper chat, so there is no target marker and no Announce helpers.
]]

--------------------------------------------------------------------------------
-- Print Outs (Player Only)
--------------------------------------------------------------------------------

-- Format: |cff[INFO]Add-on Name|r |cff[SEPARATOR]//|r |cff[TEXT]Message|r
local function Emit(bodyColor, message)
	print(
		GetColor("INFO")
			.. L["ADDON_TITLE"]
			.. "|r "
			.. GetColor("SEPARATOR")
			.. "//"
			.. "|r "
			.. bodyColor
			.. tostring(message)
			.. "|r"
	)
end

function ns:PrintMessage(message)
	Emit(GetColor("TEXT"), message)
end

--[[
	Gold body for the mail run's operational warnings. The palette has no warning role, so TITLE
	carries the attention weight.
]]
function ns:PrintWarning(message)
	Emit(GetColor("TITLE"), message)
end
