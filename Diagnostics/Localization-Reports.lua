local _, ns = ...

local GetClientHeader = ns.GetDiagnosticClientHeader

--------------------------------------------------------------------------------
-- Locale Context
--------------------------------------------------------------------------------

-- What a player on a non-English client pastes first: which language the client and the add-on speak.
function ns:BuildLocaleContextReport()
	local lines = { GetClientHeader(), "" }
	lines[#lines + 1] = "GetLocale() = " .. tostring(GetLocale())
	lines[#lines + 1] = "textLocale CVar = " .. tostring(GetCVar("textLocale"))
	lines[#lines + 1] = "audioLocale CVar = " .. tostring(GetCVar("audioLocale"))
	lines[#lines + 1] = "keys ns.L defines = " .. ns.CountDiagnosticKeys(ns.L)
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Game Names
--------------------------------------------------------------------------------

local NAME_NIL = "NIL"

-- Tabs and newlines would break the TSV row; pipes are doubled so an escape shows as text.
local function Cell(value)
	return (tostring(value):gsub("[\t\n\r]", " "):gsub("|", "||"))
end

--[[
    One row per game record the add-on names, driven by ns.DIAGNOSTIC_NAME_LOOKUPS.
    Each entry expands into its rows here, at run time, through its own ids
    function, and each name is read with the entry's lookup, which is the exact
    call the add-on's features make. A lookup that throws or returns nothing or
    an empty string is flagged NIL.
]]
function ns:BuildGameNamesReport()
	local lines = { GetClientHeader(), "", table.concat({ "CONSTANT", "KIND", "ID", "NAME" }, "\t") }
	local missing = 0
	for _, entry in ipairs(ns.DIAGNOSTIC_NAME_LOOKUPS or {}) do
		local ok, ids = pcall(entry.ids)
		for _, id in ipairs(ok and ids or {}) do
			local read, name = pcall(entry.lookup, id)
			if not read or type(name) ~= "string" or name == "" then
				name = NAME_NIL
				missing = missing + 1
			end
			lines[#lines + 1] = table.concat({ Cell(entry.constant), Cell(entry.kind), Cell(id), Cell(name) }, "\t")
		end
		if not ok then
			lines[#lines + 1] = table.concat({ Cell(entry.constant), Cell(entry.kind), "ERROR", Cell(ids) }, "\t")
			missing = missing + 1
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("%d NIL", missing)
	return table.concat(lines, "\n")
end
