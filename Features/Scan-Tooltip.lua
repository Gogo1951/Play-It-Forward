local _, ns = ...

ns.Tooltip = {}
local Tooltip = ns.Tooltip

--[[
	Why this file exists. GetItemStats resolves the base item and ignores the random-suffix half of
	a link ("of the Eagle"), so a levelling green -- which carries all its stats in that suffix --
	comes back statless and lands in the vendor pile. The tooltip renders the item as the player
	sees it, suffix included. Where a read came from travels with its result rather than being
	parked on this table: a "most recent call" field is only true for a caller reading it at once.
]]
local scanner
local function GetScanner()
	if scanner then
		return scanner
	end
	scanner = CreateFrame("GameTooltip", "PlayItForwardScanTooltip", UIParent, "GameTooltipTemplate")
	scanner:SetOwner(UIParent, "ANCHOR_NONE")
	return scanner
end

--[[
	An item's tooltip as a list of left-hand text lines. Both paths are live: Classic Era
	has no C_TooltipInfo.GetHyperlink, so the scanning tooltip below is not a legacy leftover.
]]
local function TooltipLines(link)
	if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
		local data = C_TooltipInfo.GetHyperlink(link)
		if data then
			-- Older 10.0.x builds hand back packed args that need surfacing first.
			if TooltipUtil and TooltipUtil.SurfaceArgs then
				TooltipUtil.SurfaceArgs(data)
				for _, line in ipairs(data.lines or {}) do
					TooltipUtil.SurfaceArgs(line)
				end
			end
			--[[
				Require actual text, not just line objects: with SurfaceArgs missing every leftText
				is nil, so counting lines would "succeed" empty and never fall through below.
			]]
			local out, anyText = {}, false
			for _, line in ipairs(data.lines or {}) do
				out[#out + 1] = line.leftText or ""
				if line.leftText and line.leftText ~= "" then
					anyText = true
				end
			end
			if anyText then
				return out, "C_TooltipInfo"
			end
		end
	end

	local tooltip = GetScanner()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:ClearLines()
	if not pcall(tooltip.SetHyperlink, tooltip, link) then
		return {}, "none"
	end

	-- Same requirement as above: a line count with every font string empty is not a read.
	local out, anyText = {}, false
	for i = 1, tooltip:NumLines() do
		local fontString = _G["PlayItForwardScanTooltipTextLeft" .. i]
		local text = (fontString and fontString:GetText()) or ""
		out[i] = text
		if text ~= "" then
			anyText = true
		end
	end
	return out, (anyText and "scanning tooltip" or "none")
end

--[[
	Localized stat name ("Intellect") to the internal token, for a "+N Something" line. DERIVED
	FROM Data/Scan-Stats.lua, NOT LISTED HERE: naming stats by hand drops every other "+N Something"
	the client writes, since the equip patterns below only match the "increases ... by N" wording.
]]
local STAT_BY_NAME

--[[
	English names for what the client has no global for. Vanilla renders a random-suffix school
	roll as "+6 Nature Spell Damage" with no ITEM_MOD_ global behind it, so the name is hardcoded
	or the line is unreadable. A non-English client misses these rather than misreading them.
]]
local ENUS_FALLBACK = {
	strength = "STRENGTH",
	agility = "AGILITY",
	stamina = "STAMINA",
	intellect = "INTELLECT",
	spirit = "SPIRIT",

	["arcane spell damage"] = "ARCANE",
	["fire spell damage"] = "FIRE",
	["frost spell damage"] = "FROST",
	["nature spell damage"] = "NATURE",
	["shadow spell damage"] = "SHADOW",
	["holy spell damage"] = "HOLY",
	["spell damage"] = "SPELL_DAMAGE",
	["spell damage and healing"] = "SPELL_POWER",
	["healing spells"] = "HEALING",
	-- The second half of TBC's "+42 Healing Spells and +14 Damage Spells".
	["damage spells"] = "SPELL_DAMAGE",
}

local function StatNames()
	if STAT_BY_NAME then
		return STAT_BY_NAME
	end
	STAT_BY_NAME = {}
	for globalName, token in pairs(ns.Data.STAT_MAP) do
		local localized = _G[globalName]
		if type(localized) == "string" and localized ~= "" then
			STAT_BY_NAME[localized:lower()] = token
		end
	end
	for name, token in pairs(ENUS_FALLBACK) do
		STAT_BY_NAME[name] = STAT_BY_NAME[name] or token
	end
	return STAT_BY_NAME
end

--[[
	A stat line in the client's own word order, read through the long ITEM_MOD_* format the client
	renders it from ("%c%d Intellect", koKR's "지능 %c%d"). The "+N Name" reader above cannot see a
	name-first line, and on koKR every stat line is one. Only formats carrying a sign and an amount
	are used; the rating and equip sentences have no sign and stay with the English patterns below.
]]
local FORMAT_READERS

local function EscapePattern(text)
	return (text:lower():gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- The format as an anchored pattern and its capture kinds in order, or nil for any other shape.
local function FormatReader(format)
	local pattern, captures, literal, position = "^%s*", {}, "", 1
	while position <= #format do
		local char = format:sub(position, position)
		if char ~= "%" then
			literal = literal .. char
			position = position + 1
		elseif format:sub(position + 1, position + 1) == "%" then
			literal = literal .. "%"
			position = position + 2
		else
			local _, finish, kind = format:find("^%%%d*%$?([cds])", position)
			if not kind then
				return nil
			end
			pattern = pattern .. EscapePattern(literal)
			literal = ""
			if kind == "c" then
				pattern = pattern .. "([%+%-])"
				captures[#captures + 1] = "sign"
			else
				pattern = pattern .. "(%d+)"
				captures[#captures + 1] = "amount"
			end
			position = finish + 1
		end
	end
	pattern = pattern .. EscapePattern(literal) .. "%s*$"
	if #captures ~= 2 or captures[1] == captures[2] then
		return nil
	end
	return pattern, captures[1] == "sign"
end

local function FormatReaders()
	if FORMAT_READERS then
		return FORMAT_READERS
	end
	FORMAT_READERS = {}
	for globalName, token in pairs(ns.Data.STAT_MAP) do
		local format = globalName:find("_SHORT$") and _G[globalName:gsub("_SHORT$", "")]
		if type(format) == "string" and format:find("%%%d*%$?c") then
			local pattern, signFirst = FormatReader(format)
			if pattern then
				FORMAT_READERS[#FORMAT_READERS + 1] = { pattern = pattern, token = token, signFirst = signFirst }
			end
		end
	end
	return FORMAT_READERS
end

local function ReadFormatted(text)
	local lower = text:lower()
	for _, reader in ipairs(FormatReaders()) do
		local first, second = lower:match(reader.pattern)
		if first then
			local sign, amount = first, second
			if not reader.signFirst then
				sign, amount = second, first
			end
			local value = tonumber(amount)
			if value then
				return reader.token, (sign == "-") and -value or value
			end
		end
	end
	return nil
end

--[[
	"Equip: ..." lines, English clients only, and a scope decision rather than an oversight
	(README-Notes): vanilla builds these from spell text rather than the ITEM_MOD_* globals, so every
	locale would need its own pattern set. Plain stat lines are read in every locale, through the
	"+N Name" reader and the client's own formats above, so an item misses a stat rather than
	scoring wrongly. ORDER MATTERS: the more specific pattern must win, which is why spell crit
	precedes crit.
]]

-- Read once: the locale cannot change without a restart, which reloads this file anyway.
Tooltip.equipPatternsLocale = "enUS"
Tooltip.equipPatternsUsable = (GetLocale() == Tooltip.equipPatternsLocale)
local SCHOOLS = {
	arcane = "ARCANE",
	fire = "FIRE",
	frost = "FROST",
	nature = "NATURE",
	shadow = "SHADOW",
	holy = "HOLY",
	magical = "SPELL_DAMAGE", -- "by magical spells" = generic, not a school
}
local function SchoolDamage(school, amount)
	return SCHOOLS[school], tonumber(amount)
end

local EQUIP_PATTERNS = {
	{ "ranged attack power by (%d+)", "RANGED_AP" },
	-- Must precede plain attack power, which would hand a feral staff to the rogue.
	{ "attack power by (%d+) in cat", "FERAL_AP" },
	{ "attack power by (%d+)", "ATTACK_POWER" },
	-- Must precede the school pattern: this line reads "damage and healing done by".
	{ "damage and healing done by magical spells.-by up to (%d+)", "SPELL_POWER" },
	{ "healing done by spells and effects by up to (%d+)", "HEALING" },
	{ "damage done by (%a+) spells and effects by up to (%d+)", SchoolDamage },
	{ "restores (%d+) mana per 5 sec", "MP5" },
	{ "chance to hit with spells by (%d+)", "SPELL_HIT" },
	{ "critical strike with spells by (%d+)", "SPELL_CRIT" },
	{ "chance to get a critical strike by (%d+)", "CRIT" },
	{ "chance to hit by (%d+)", "HIT" },
	{ "defense by (%d+)", "DEFENSE" },
	--[[
		Vanilla spells the target out -- "chance to block attacks with a shield by 1%" -- so
		"chance to block by" matches nothing. The non-greedy span cannot over-reach, since no
		tooltip line names two stats.
	]]
	{ "chance to block.-by (%d+)", "BLOCK" },
	{ "chance to dodge.-by (%d+)", "DODGE" },
	-- A few items word a flat stat as an equip effect instead of a "+N" line.
	{ "increases your strength by (%d+)", "STRENGTH" },
	{ "increases your agility by (%d+)", "AGILITY" },
	{ "increases your stamina by (%d+)", "STAMINA" },
	{ "increases your intellect by (%d+)", "INTELLECT" },
	{ "increases your spirit by (%d+)", "SPIRIT" },
}

--[[
	Strips the display escapes Blizzard wraps some stat lines in. LOAD-BEARING: removing it
	puts every rolled green back in the vendor pile. A base stat is a bare "+4 Intellect", but
	a random-suffix roll or an enchant arrives color-wrapped and newline-terminated:

	  base            +4 Intellect
	  "of the Owl"    |cffffffff+15 Intellect|r\n

	The stat pattern anchors on "^%s*%+", so the wrapped form fails at the anchor and the stat
	is silently dropped -- and the suffix carries every stat those greens have.
]]
local function CleanLine(text)
	if not text or text == "" then
		return ""
	end
	-- Matched on shape: a surviving |r turns "Intellect" into "Intellect|r", matching no entry.
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- The trailing newline is part of the wrapped form and survives GetText.
	text = text:gsub("[\r\n]", " ")
	return strtrim(text)
end

--[[
	"+42 Healing Spells and +14 Damage Spells": a TBC suffix writes two stats on one line, so the
	whole tail names no stat. Split at each "+N"; a half that still names nothing is retried with
	its last word dropped, by position rather than spelling, so a translated "and" goes too.
	Returns nil when nothing resolved, else the tokens and whether every half did.
]]
local function SplitStats(text, names)
	local parts = {}
	for amount, stat in text:gmatch("%+(%d+)%s+([^%+]+)") do
		parts[#parts + 1] = { tonumber(amount), (strtrim(stat):gsub("[%p%s]+$", "")) }
	end
	if #parts < 2 then
		return nil
	end
	local out, any, complete = {}, false, true
	for _, part in ipairs(parts) do
		local name = part[2]:lower()
		local token = names[name] or names[name:match("^(.-)%s+%S+$") or ""]
		if token then
			out[token] = (out[token] or 0) + part[1]
			any = true
		else
			complete = false
		end
	end
	if not any then
		return nil
	end
	return out, complete
end

-- Pure: no tooltip, no item cache, no client state, so the API report can feed it either format.
function Tooltip:StatsFromLines(lines)
	local out, unread = {}, {}
	local names = StatNames()
	for i = 2, #lines do -- line 1 is the item name
		local text = CleanLine(lines[i])
		if text ~= "" then
			-- Plain stat line: "+9 Intellect"
			local amount, stat = text:match("^%s*%+(%d+)%s+(.+)$")
			local token = amount and names[strtrim(stat):lower()]
			local read = false
			if token then
				out[token] = (out[token] or 0) + tonumber(amount)
				read = true
			else
				local split, complete
				if amount then
					split, complete = SplitStats(text, names)
				end
				local formatToken, formatValue
				if not split then
					formatToken, formatValue = ReadFormatted(text)
				end
				if split then
					-- A half left unresolved keeps read false, so the line is still reported below.
					for splitToken, value in pairs(split) do
						out[splitToken] = (out[splitToken] or 0) + value
					end
					read = complete
				elseif formatToken then
					out[formatToken] = (out[formatToken] or 0) + formatValue
					read = true
				elseif Tooltip.equipPatternsUsable then
					local lower = text:lower()
					for _, pattern in ipairs(EQUIP_PATTERNS) do
						local first, second = lower:match(pattern[1])
						if first then
							local statToken, value
							if type(pattern[2]) == "function" then
								statToken, value = pattern[2](first, second)
							else
								statToken, value = pattern[2], tonumber(first)
							end
							if statToken and value then
								out[statToken] = (out[statToken] or 0) + value
								read = true
							end
							break
						end
					end
				end
			end

			--[[
				A line carrying a signed number that resolves to nothing is a gap in the name
				table, handed back for the Item Verdict report, whichever side of the name the
				number sits on. Only that shape counts: reporting every prose line as unread would
				bury the one that matters.
			]]
			if not read and (amount or text:find("[%+%-]%d+")) then
				unread[#unread + 1] = text
			end
		end
	end
	return out, unread
end

--[[
	One item's stats off its rendered tooltip: tokens, source and raw lines in one result. The
	lines come back because "returned text that did not parse" and "returned nothing" are
	different failures with the same symptom, and the scanning tooltip is reused for the next
	item, so now is the only time a caller can tell them apart.
]]
function Tooltip:Stats(link)
	if not link then
		return {}, "none", {}, {}
	end
	local lines, source = TooltipLines(link)
	local stats, unread = self:StatsFromLines(lines)
	return stats, source, lines, unread
end
