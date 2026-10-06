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
local function getScanner()
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
local function tooltipLines(link)
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

	local tip = getScanner()
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:ClearLines()
	if not pcall(tip.SetHyperlink, tip, link) then
		return {}, "none"
	end

	-- Same requirement as above: a line count with every font string empty is not a read.
	local out, anyText = {}, false
	for i = 1, tip:NumLines() do
		local fs = _G["PlayItForwardScanTooltipTextLeft" .. i]
		local text = (fs and fs:GetText()) or ""
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
}

local function statNames()
	if STAT_BY_NAME then
		return STAT_BY_NAME
	end
	STAT_BY_NAME = {}
	for globalName, token in pairs(ns.Data.StatMap) do
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
	"Equip: ..." lines, English clients only, and a scope decision rather than an oversight:
	vanilla builds these from spell text rather than the ITEM_MOD_* globals, so every locale would
	need its own pattern set. Plain "+9 Intellect" still parses anywhere, so an item misses a stat
	rather than scoring wrongly. ORDER MATTERS: the more specific pattern must win, which is why
	spell crit precedes crit.
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
local function schoolDamage(school, amount)
	return SCHOOLS[school], tonumber(amount)
end

local EQUIP_PATTERNS = {
	{ "ranged attack power by (%d+)", "RANGED_AP" },
	{ "attack power by (%d+)", "ATTACK_POWER" },
	-- Must precede the school pattern: this line reads "damage and healing done by".
	{ "damage and healing done by magical spells.-by up to (%d+)", "SPELL_POWER" },
	{ "healing done by spells and effects by up to (%d+)", "HEALING" },
	{ "damage done by (%a+) spells and effects by up to (%d+)", schoolDamage },
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
local function cleanLine(text)
	if not text or text == "" then
		return ""
	end
	-- Matched on shape: a surviving |r turns "Intellect" into "Intellect|r", matching no entry.
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- The trailing newline is part of the wrapped form and survives GetText.
	text = text:gsub("[\r\n]", " ")
	return strtrim(text)
end

-- Pure: no tooltip, no item cache, no client state, so the API report can feed it either format.
function Tooltip:StatsFromLines(lines)
	local out, unread = {}, {}
	local names = statNames()
	for i = 2, #lines do -- line 1 is the item name
		local text = cleanLine(lines[i])
		if text ~= "" then
			-- Plain stat line: "+9 Intellect"
			local amount, stat = text:match("^%s*%+(%d+)%s+(.+)$")
			local token = amount and names[strtrim(stat):lower()]
			local read = false
			if token then
				out[token] = (out[token] or 0) + tonumber(amount)
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

			--[[
				A "+N Something" that resolves to nothing is a gap in the name table, handed back
				for the Item Verdict report. Only that shape counts: reporting every prose line as
				unread would bury the one that matters.
			]]
			if amount and not read then
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
	local lines, source = tooltipLines(link)
	local stats, unread = self:StatsFromLines(lines)
	return stats, source, lines, unread
end
