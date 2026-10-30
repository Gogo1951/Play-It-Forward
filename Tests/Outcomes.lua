--[[
	Who gets what: every common stat roll on every kind of gear, at three levels, on every
	flavor, written down as the classes that lead and the classes that are only fallbacks.

	The table is the matcher's behavior as a reader sees it, rather than as its numbers do. It
	is the safety net for reworking the scoring: a change that moves any row fails here, and the
	diff of Tests/Outcomes/ says exactly which items now go somewhere else. A move that is meant
	is accepted by rewriting the files:

		cd Play-It-Forward && lua Tests/Write-Outcomes.lua

	Synthetic items, not real ones: a roll's stats at a fixed size, so the rows compare a stat mix
	against a stat mix and nothing else. Both factions' classes are in play, so a Classic table
	shows paladins and shamans side by side.
]]

local Harness = require("Harness")
local Stub = Harness.Stub

local Outcomes = {}

-- Folder name, and the season the stub reports for it.
Outcomes.FLAVORS = {
	{ name = "Vanilla" },
	{ name = "Discovery", flavor = "Vanilla", season = 2 },
	{ name = "Camelot" },
	{ name = "TBC" },
	{ name = "Wrath" },
	{ name = "Mists" },
	{ name = "Mainline" },
}

Outcomes.LEVELS = { 20, 35, 50 }

local MODERN = { Mists = true, Mainline = true }

local TBC_SUFFIXES = { TBC = true }

-- Wrath merged healing and spell damage into spell power; the two Classic lines before that.
local HEALING_IS_SPELL_POWER = { Wrath = true, Mists = true, Mainline = true }

local function rolls(flavor)
	local S = function(name)
		return "ITEM_MOD_" .. name .. "_SHORT"
	end
	local out = {
		{ "Strength", { [S("STRENGTH")] = 10 } },
		{ "Agility", { [S("AGILITY")] = 10 } },
		{ "Stamina", { [S("STAMINA")] = 10 } },
		{ "Intellect", { [S("INTELLECT")] = 10 } },
		{ "Spirit", { [S("SPIRIT")] = 10 } },
		{ "Monkey: Agi Sta", { [S("AGILITY")] = 6, [S("STAMINA")] = 6 } },
		{ "Eagle: Int Sta", { [S("INTELLECT")] = 6, [S("STAMINA")] = 6 } },
		{ "Owl: Int Spi", { [S("INTELLECT")] = 6, [S("SPIRIT")] = 6 } },
		{ "Bear: Str Sta", { [S("STRENGTH")] = 6, [S("STAMINA")] = 6 } },
		{ "Boar: Str Spi", { [S("STRENGTH")] = 6, [S("SPIRIT")] = 6 } },
		{ "Tiger: Str Agi", { [S("STRENGTH")] = 6, [S("AGILITY")] = 6 } },
		{ "Gorilla: Str Int", { [S("STRENGTH")] = 6, [S("INTELLECT")] = 6 } },
		{ "Falcon: Agi Int", { [S("AGILITY")] = 6, [S("INTELLECT")] = 6 } },
		{ "Wolf: Agi Spi", { [S("AGILITY")] = 6, [S("SPIRIT")] = 6 } },
		{ "Whale: Sta Spi", { [S("STAMINA")] = 6, [S("SPIRIT")] = 6 } },
	}
	-- Classic and TBC suffixes Mists' gear no longer rolls.
	if not MODERN[flavor] then
		out[#out + 1] = { "Power: Attack Power", { [S("ATTACK_POWER")] = 20 } }
		out[#out + 1] = { "Concentration: MP5", { [S("MANA_REGENERATION")] = 4 } }
		out[#out + 1] = { "Defense", { [S("DEFENSE_SKILL_RATING")] = 8 } }
	end
	if HEALING_IS_SPELL_POWER[flavor] then
		out[#out + 1] = { "Spell Power", { [S("SPELL_POWER")] = 12 } }
		out[#out + 1] = { "Int Spell Power", { [S("INTELLECT")] = 6, [S("SPELL_POWER")] = 7 } }
	else
		out[#out + 1] = { "Healing", { [S("SPELL_HEALING_DONE")] = 20, [S("SPELL_DAMAGE_DONE")] = 7 } }
		out[#out + 1] = { "Int Healing", { [S("INTELLECT")] = 6, [S("SPELL_HEALING_DONE")] = 13 } }
		out[#out + 1] = { "Spell Damage", { [S("SPELL_DAMAGE_DONE")] = 12 } }
		out[#out + 1] = { "Int Spell Damage", { [S("INTELLECT")] = 6, [S("SPELL_DAMAGE_DONE")] = 7 } }
	end
	-- TBC's three-stat suffixes, as the 2.5 client's own data writes them.
	if TBC_SUFFIXES[flavor] then
		local T = {
			{ "Sorcerer: Sta Int SpDmg", { STAMINA = 8, INTELLECT = 5, SPELL_DAMAGE_DONE = 6 } },
			{ "Invoker: Int SpDmg SpCrit", { INTELLECT = 5, SPELL_DAMAGE_DONE = 6, CRIT_SPELL_RATING = 5 } },
			{ "Physician: Sta Int Heal", { STAMINA = 8, INTELLECT = 5, SPELL_HEALING_DONE = 12 } },
			{ "Prophet: Int Spi Heal", { INTELLECT = 5, SPIRIT = 5, SPELL_HEALING_DONE = 12 } },
			{ "Elder: Sta Int MP5", { STAMINA = 8, INTELLECT = 5, MANA_REGENERATION = 2 } },
			{ "Moon: Int Sta Spi", { INTELLECT = 5, STAMINA = 5, SPIRIT = 5 } },
			{ "Bandit: Agi Sta AP", { AGILITY = 5, STAMINA = 8, ATTACK_POWER = 10 } },
			{ "Hunt: AP Agi Int", { ATTACK_POWER = 14, AGILITY = 4, INTELLECT = 3 } },
			{ "Beast: Str Agi Sta", { STRENGTH = 5, AGILITY = 5, STAMINA = 8 } },
			{ "Soldier: Str Sta Crit", { STRENGTH = 5, STAMINA = 8, CRIT_RATING = 5 } },
			{ "Champion: Str Sta Def", { STRENGTH = 5, STAMINA = 8, DEFENSE_SKILL_RATING = 5 } },
			{ "Knight: Sta Def SpDmg", { STAMINA = 8, DEFENSE_SKILL_RATING = 5, SPELL_DAMAGE_DONE = 6 } },
		}
		for _, roll in ipairs(T) do
			local stats = {}
			for name, value in pairs(roll[2]) do
				stats[S(name)] = value
			end
			out[#out + 1] = { roll[1], stats }
		end
	end
	if MODERN[flavor] then
		-- Cataclysm-style suffixes: each secondary at two thirds of the primary, as the client rolls them.
		out[#out + 1] = { "Int Crit Haste", { [S("INTELLECT")] = 9, [S("CRIT_RATING")] = 6, [S("HASTE_RATING")] = 6 } }
		out[#out + 1] = { "Int Spi Haste", { [S("INTELLECT")] = 9, [S("SPIRIT")] = 6, [S("HASTE_RATING")] = 6 } }
		out[#out + 1] =
			{ "Int Hit Mastery", { [S("INTELLECT")] = 9, [S("HIT_RATING")] = 6, [S("MASTERY_RATING")] = 6 } }
		out[#out + 1] =
			{ "Agi Crit Mastery", { [S("AGILITY")] = 9, [S("CRIT_RATING")] = 6, [S("MASTERY_RATING")] = 6 } }
		out[#out + 1] =
			{ "Agi Hit Expertise", { [S("AGILITY")] = 9, [S("HIT_RATING")] = 6, [S("EXPERTISE_RATING")] = 6 } }
		out[#out + 1] =
			{ "Str Crit Mastery", { [S("STRENGTH")] = 9, [S("CRIT_RATING")] = 6, [S("MASTERY_RATING")] = 6 } }
		out[#out + 1] = { "Str Parry Dodge", { [S("STRENGTH")] = 9, [S("PARRY_RATING")] = 6, [S("DODGE_RATING")] = 6 } }
	end
	out[#out + 1] = { "No stats", {} }
	return out
end

-- name, equipLoc, classID, subclassID
Outcomes.SLOTS = {
	{ "Cloth chest", "INVTYPE_CHEST", 4, 1 },
	{ "Leather chest", "INVTYPE_CHEST", 4, 2 },
	{ "Mail chest", "INVTYPE_CHEST", 4, 3 },
	{ "Plate chest", "INVTYPE_CHEST", 4, 4 },
	{ "Cloak", "INVTYPE_CLOAK", 4, 1 },
	{ "Ring", "INVTYPE_FINGER", 4, 0 },
	{ "Shield", "INVTYPE_SHIELD", 4, 6 },
	{ "Held off-hand", "INVTYPE_HOLDABLE", 4, 0 },
	{ "Staff", "INVTYPE_2HWEAPON", 2, 10 },
	{ "Dagger", "INVTYPE_WEAPON", 2, 15 },
	{ "1H sword", "INVTYPE_WEAPON", 2, 7 },
	{ "1H mace", "INVTYPE_WEAPON", 2, 4 },
	{ "2H sword", "INVTYPE_2HWEAPON", 2, 8 },
	{ "2H mace", "INVTYPE_2HWEAPON", 2, 5 },
	{ "Polearm", "INVTYPE_2HWEAPON", 2, 6 },
	{ "Bow", "INVTYPE_RANGED", 2, 2 },
	{ "Wand", "INVTYPE_RANGEDRIGHT", 2, 19 },
}

local function sortedJoin(list)
	local out = {}
	for index, value in ipairs(list or {}) do
		out[index] = value
	end
	table.sort(out)
	return table.concat(out, " ")
end

--[[
	One line per item: level, slot, roll, then who leads and who is only a fallback. An item no
	class is admitted for says so rather than printing two empty columns.
]]
function Outcomes.Build(entry)
	Stub.flavor, Stub.season = entry.flavor or entry.name, entry.season
	local ok, ns = pcall(Harness.LoadAddon, ADDON_ROOT)
	Stub.flavor, Stub.season = "Vanilla", nil
	assert(ok, ns)

	-- Both factions: an unknown faction is every class either side can roll.
	local faction = UnitFactionGroup
	UnitFactionGroup = function()
		return nil
	end

	local lines = {}
	for _, level in ipairs(Outcomes.LEVELS) do
		for _, slot in ipairs(Outcomes.SLOTS) do
			for _, roll in ipairs(rolls(entry.name)) do
				local def = Stub.Item({
					name = slot[1] .. " " .. roll[1],
					reqLevel = level,
					itemLevel = level + 5,
					equipLoc = slot[2],
					classID = slot[3],
					subclassID = slot[4],
					stats = roll[2],
				})
				local item = ns.Scanner:Describe(def.link)
				local verdict = item and ns.Matcher:Verdict(item)
				local answer
				if not verdict then
					answer = "not described"
				elseif #verdict.admitted == 0 then
					answer = "nobody"
				else
					local lead = {}
					for _, class in ipairs(verdict.contenders) do
						lead[class] = true
					end
					local fallback = {}
					for _, class in ipairs(verdict.admitted) do
						if not lead[class] then
							fallback[#fallback + 1] = class
						end
					end
					answer = sortedJoin(verdict.contenders)
					if #fallback > 0 then
						answer = answer .. " | fallback: " .. sortedJoin(fallback)
					end
					if verdict.state ~= ns.Matcher.GIFT then
						answer = answer .. " (" .. tostring(verdict.state) .. ")"
					end
				end
				lines[#lines + 1] = ("L%d\t%s\t%s\t%s"):format(level, slot[1], roll[1], answer)
			end
		end
	end

	UnitFactionGroup = faction
	return lines
end

function Outcomes.Path(entry)
	return ("%s/Tests/Outcomes/%s.txt"):format(ADDON_ROOT, entry.name)
end

function Outcomes.Read(entry)
	local handle = io.open(Outcomes.Path(entry), "r")
	if not handle then
		return nil
	end
	local lines = {}
	for line in handle:lines() do
		lines[#lines + 1] = line
	end
	handle:close()
	return lines
end

--[[
	Every row that moved, not just the first: the point of the table is reviewing what a change
	did, and one row at a time hides the shape of it.
]]
for _, entry in ipairs(Outcomes.FLAVORS) do
	Harness.test("who gets what on " .. entry.name .. " matches Tests/Outcomes", function()
		local saved = Outcomes.Read(entry)
		Harness.check(saved ~= nil, "no saved table: run lua Tests/Write-Outcomes.lua")
		if not saved then
			return
		end
		local now = Outcomes.Build(entry)
		Harness.equal(#now, #saved, "row count")
		for index = 1, math.min(#now, #saved) do
			Harness.check(now[index] == saved[index], ("was  %s\n        now  %s"):format(saved[index], now[index]))
		end
	end)
end

return Outcomes
