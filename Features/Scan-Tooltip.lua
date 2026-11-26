local _, ns = ...

ns.Tooltip = {}
local Tooltip = ns.Tooltip

--[[
	GetItemStats misses random suffixes; the tooltip shows them. A read's source travels with its
	result, never parked on this table: a "most recent call" field is true only if read at once.
]]

local function TooltipLines(link)
	local pairsRead, source = ns.ReadTooltip(link)
	local out = {}
	for index, pair in ipairs(pairsRead) do
		out[index] = pair[1]
	end
	return out, source
end

-- Derived from STAT_MAP, never listed by hand: a hand list drops every other "+N Something" line.
local STAT_BY_NAME

--[[
	Names with no client global: Vanilla writes a suffix school roll as "+6 Nature Spell Damage" with
	no ITEM_MOD_ behind it. A non-English client misses these rather than misreading them.
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
	For name-first locales (koKR's "지능 %c%d"), which the "+N Name" reader cannot see. Only formats
	with a sign and an amount; rating and equip sentences stay with the English patterns.
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
	"Equip: ..." lines are English only by scope (README-Notes): vanilla builds them from spell text,
	so every locale would need its own set. ORDER MATTERS: the more specific pattern must win.
]]

-- English EU clients report enGB and carry the same tooltip text.
Tooltip.equipPatternsLocale = "enUS"
local gameLocale = GetLocale()
Tooltip.equipPatternsUsable = (gameLocale == Tooltip.equipPatternsLocale or gameLocale == "enGB")
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
	-- Vanilla writes "chance to block attacks with a shield by 1%"; no line names two stats, so the span is safe.
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
	Keeps text handed straight to StatsFromLines (Diagnostics probe, tests) reading like the live
	scan: a suffix roll arrives as "|cffffffff+15 Intellect|r\n", which fails the "^%s*%+" anchor.
]]
local function CleanLine(text)
	if not text or text == "" then
		return ""
	end
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- The trailing newline is part of the wrapped form and survives GetText.
	text = text:gsub("[\r\n]", " ")
	return strtrim(text)
end

--[[
	TBC's "+42 Healing Spells and +14 Damage Spells". A half's last word is dropped by position, not
	spelling, so a translated "and" goes too. Returns nil, or the tokens and whether every half read.
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

-- Use:, Chance on hit: and set-bonus lines only look like stats. Client prefixes, so every locale skips its own.
local function NonStatPrefixes()
	local prefixes = {}
	for _, text in ipairs({ ITEM_SPELL_TRIGGER_ONUSE, ITEM_SPELL_TRIGGER_ONPROC }) do
		if type(text) == "string" and text ~= "" then
			prefixes[#prefixes + 1] = text
		end
	end
	local setPrefix = type(ITEM_SET_BONUS) == "string" and ITEM_SET_BONUS:match("^(.-)%%s")
	if setPrefix and setPrefix ~= "" then
		prefixes[#prefixes + 1] = setPrefix
	end
	return prefixes
end

local function IsNonStatLine(text, prefixes)
	-- An inactive set bonus, ITEM_SET_BONUS_GRAY's "(2) Set: ..." shape.
	if text:find("^%(%d+%)") then
		return true
	end
	for _, prefix in ipairs(prefixes) do
		if text:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

-- Pure, so the API report and tests can feed it literal lines.
function Tooltip:StatsFromLines(lines)
	local out, unread = {}, {}
	local names = StatNames()
	local nonStat = NonStatPrefixes()
	for i = 2, #lines do -- line 1 is the item name
		local text = CleanLine(lines[i])
		if text ~= "" and not IsNonStatLine(text, nonStat) then
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

			-- Only a signed-number line counts as unread: reporting every prose line would bury it.
			if not read and (amount or text:find("[%+%-]%d+")) then
				unread[#unread + 1] = text
			end
		end
	end
	return out, unread
end

-- From ITEM_REQ_REPUTATION, so every locale finds its own line; false where the client has none.
local REPUTATION_PATTERN

local function ReputationPattern()
	if REPUTATION_PATTERN == nil then
		local format = ITEM_REQ_REPUTATION
		REPUTATION_PATTERN = false
		if type(format) == "string" and format:find("%%%d*%$?s") then
			local marked = format:gsub("%%%d*%$?s", "\001")
			local escaped = marked:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
			REPUTATION_PATTERN = "^" .. escaped:gsub("\001", ".+") .. "$"
		end
	end
	return REPUTATION_PATTERN
end

-- No API reports the requirement. Pure, like StatsFromLines.
function Tooltip:ReputationFromLines(lines)
	local pattern = ReputationPattern()
	if not pattern then
		return nil
	end
	for i = 2, #lines do -- line 1 is the item name
		local text = CleanLine(lines[i])
		if text:find(pattern) then
			return text
		end
	end
	return nil
end

-- An uncached item renders nothing, which is not the same as needing no standing.
function Tooltip:RequiredReputation(link)
	if not link then
		return nil, false
	end
	local lines = TooltipLines(link)
	return self:ReputationFromLines(lines), #lines > 0
end

--[[
	Lines come back because "text that did not parse" and "nothing returned" look alike, and the
	scanning tooltip is reused for the next item.
]]
function Tooltip:Stats(link)
	if not link then
		return {}, "none", {}, {}
	end
	local lines, source = TooltipLines(link)
	local stats, unread = self:StatsFromLines(lines)
	return stats, source, lines, unread
end
