local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

--------------------------------------------------------------------------------
-- Recipients Panel
--------------------------------------------------------------------------------

-- Every switch reorders or filters the candidate sort, so each setter rescans: a cached ranking keeps the old order.

--------------------------------------------------------------------------------
-- Ordering Switches
--------------------------------------------------------------------------------

-- A name passed in replaces L[label], for a label filled from constants so it never drifts from them.
local function Toggle(key, label, order, name)
	return {
		type = "toggle",
		name = name or L[label],
		desc = L[label .. "_DESCRIPTION"],
		width = "full",
		order = order,
		get = Kit.Get("profile", key),
		set = Kit.Set("profile", key, ns.RefreshMailWindow),
	}
end

--------------------------------------------------------------------------------
-- Classes & Specs
--------------------------------------------------------------------------------

local CLASS_ORDER = {
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
	"WARLOCK",
	"MONK",
	"DRUID",
}

local CLASS_WIDTH = 0.8

-- At least three, so a four-spec class (Season of Discovery's rune roles, the Mists druid) fits on one line.
local function SpecWidth()
	local most = 3
	for _, specs in pairs(ns.Data.SPECS or {}) do
		most = math.max(most, #specs)
	end
	return (ns.OPTIONS_ROW_WIDTH - CLASS_WIDTH) / most
end

local function Rollable()
	local out = {}
	for _, classes in pairs(ns.Data.FACTION_CLASSES or {}) do
		for _, class in ipairs(classes) do
			out[class] = true
		end
	end
	return out
end

-- Weights first: the rescan judges against them.
local function SpecsChanged()
	ns.Data.RebuildStatWeights()
	ns.RefreshMailWindow()
end

local function SpecsAtDefault()
	for _, saved in pairs(ns.db and ns.db.profile.specs or {}) do
		if next(saved) ~= nil then
			return false
		end
	end
	return true
end

local ROLE_LABELS = {
	TANK = TANK,
	HEALER = HEALER,
	CASTER = L["ROLE_CASTER"],
	MELEE = L["ROLE_MELEE"],
	RANGED = L["ROLE_RANGED"],
}

local function ClassRow(class, order)
	local args = {
		label = {
			type = "description",
			name = ns.ColorName(LOCALIZED_CLASS_NAMES_MALE[class] or class, class),
			fontSize = "medium",
			width = CLASS_WIDTH,
			order = 0,
		},
	}
	for index, spec in ipairs(ns.Data.SPECS[class]) do
		args["spec" .. index] = {
			type = "toggle",
			name = ns.SpecName(class, index, spec),
			desc = ROLE_LABELS[spec.role],
			width = SpecWidth(),
			order = index,
			get = function()
				return ns.Data.SpecEnabled(class, spec)
			end,
			set = function(_, value)
				-- Only differences from the default are stored, so a default changed in a release still reaches this spec.
				local saved = ns.db.profile.specs
				saved[class] = saved[class] or {}
				if value == not spec.off then
					saved[class][spec.key] = nil
				else
					saved[class][spec.key] = value
				end
				SpecsChanged()
				ns.RefreshSettings()
			end,
		}
	end
	return { type = "group", name = "", inline = true, order = order, args = args }
end

--------------------------------------------------------------------------------
-- The Panel
--------------------------------------------------------------------------------

function ns.BuildRecipientsOptions()
	local args = {
		descIntro = Kit.Desc(L["OPTIONS_RECIPIENTS_INTRO"], 1),
	}

	Kit.Section(args, "priority", 10, L["OPTIONS_PRIORITY_HEADER"], L["OPTIONS_PRIORITY_DESCRIPTION"])
	args.prioritizeAlts = Toggle("prioritizeAlts", "OPTIONS_PRIORITIZE_ALTS", 15)
	args.spacerPriority3 = Kit.Spacer(16)
	args.prioritizeGuilds = Toggle("prioritizeGuilds", "OPTIONS_PRIORITIZE_GUILDS", 17)

	Kit.Section(args, "strangers", 20, L["OPTIONS_STRANGERS_HEADER"], L["OPTIONS_STRANGERS_DESCRIPTION"])
	args.prioritizeLevelingZones = Toggle("prioritizeLevelingZones", "OPTIONS_PRIORITIZE_LEVELING_ZONES", 25)
	args.spacerStrangers3 = Kit.Spacer(26)
	args.prioritizeOutsideInstances = Toggle("prioritizeOutsideInstances", "OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES", 27)
	args.spacerStrangers4 = Kit.Spacer(28)
	args.ignoreSummonerWarlocks = Toggle(
		"ignoreSummonerWarlocks",
		"OPTIONS_IGNORE_SUMMONER_WARLOCKS",
		29,
		L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"]:format(ns.Data.SUMMONER_MIN_LEVEL, ns.Data.SUMMONER_MAX_LEVEL)
	)

	Kit.Section(args, "specs", 30, L["OPTIONS_SPECS_HEADER"], L["OPTIONS_SPECS_INTRO"])
	local rollable = Rollable()
	local order = 40
	for _, class in ipairs(CLASS_ORDER) do
		if rollable[class] and ns.Data.SPECS[class] then
			args["class" .. class] = ClassRow(class, order)
			order = order + 1
		end
	end
	-- Many hand-set choices, so it asks first (README-Notes: Spec reset).
	args.spacerReset = Kit.Spacer(order)
	args.reset = Kit.ResetRow(
		order + 1,
		nil,
		L["OPTIONS_SPECS_HEADER"],
		L["OPTIONS_SPECS_RESET_DESCRIPTION"],
		SpecsAtDefault,
		function()
			wipe(ns.db.profile.specs)
			SpecsChanged()
		end,
		L["OPTIONS_SPECS_RESET_CONFIRM"]
	)
	return {
		type = "group",
		name = L["TAB_RECIPIENTS"],
		args = args,
	}
end
