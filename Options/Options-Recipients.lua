local _, ns = ...
local L = ns.L

--------------------------------------------------------------------------------
-- Recipients Panel
--------------------------------------------------------------------------------

--[[
	Who gets your gear, in three parts: who comes first among your alts, your guilds and strangers;
	how strangers found by /who are weighed; and the classes and specs gear goes to. My Alts and My
	Guilds nest beneath this panel and pick the people themselves.

	Every switch here reorders the candidate sort (Features/Match-Ranking.lua) or, for the
	warlock rule, drops strangers from it, so each setter re-reads the bags: a cached ranking would
	otherwise keep the old order until the next scan.
]]

--------------------------------------------------------------------------------
-- Ordering Switches
--------------------------------------------------------------------------------

-- A name passed in replaces L[label], for a label filled from constants so it never drifts from them.
local function Toggle(key, label, order, name)
	return ns.OptionsProfileToggle(
		key,
		name or L[label],
		L[label .. "_DESCRIPTION"],
		order,
		"full",
		ns.RefreshMailWindow
	)
end

--------------------------------------------------------------------------------
-- Classes & Specs
--------------------------------------------------------------------------------

--[[
	One row per class this client can roll, either faction, and one switch per spec. A spec that
	is off counts for nothing when an item is matched: a paladin with Retribution off is never
	offered Strength plate. Protection paladins, Enhancement shamans, Arms and Balance start off.

	Stored only where the player differs from the default (Data/Default-Settings.lua), so a
	default changed in a release still reaches everyone who left it alone.
]]
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

local SPEC_WIDTH = 0.85
local CLASS_WIDTH = 0.8

local function Rollable()
	local out = {}
	for _, classes in pairs(ns.Data.FACTION_CLASSES or {}) do
		for _, class in ipairs(classes) do
			out[class] = true
		end
	end
	return out
end

-- A spec change rebuilds the weights, then re-reads the bags so no verdict is judged the old way.
local function SpecsChanged()
	ns.Data.RebuildStatWeights()
	ns.RefreshMailWindow()
end

-- Each spec's tooltip. Tank and Healer are the game's own role labels; the damage roles are ours.
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
			width = SPEC_WIDTH,
			order = index,
			get = function()
				return ns.Data.SpecEnabled(class, spec)
			end,
			set = function(_, value)
				-- Back to unset when it matches the default, so the default stays in charge of it.
				local saved = ns.db.profile.specs
				saved[class] = saved[class] or {}
				if value == not spec.off then
					saved[class][spec.key] = nil
				else
					saved[class][spec.key] = value
				end
				SpecsChanged()
			end,
		}
	end
	return { type = "group", name = "", inline = true, order = order, args = args }
end

--------------------------------------------------------------------------------
-- The Panel
--------------------------------------------------------------------------------

function ns.BuildRecipientsOptions()
	--[[
		The standard section shape: spacer, header, spacer, what the section does, spacer, then
		the switches with a spacer between each. The why behind each switch is its tooltip.
	]]
	local args = {
		descIntro = ns.OptionsDesc(L["OPTIONS_RECIPIENTS_INTRO"], 1),

		spacerPriority0 = ns.OptionsSpacer(10),
		headerPriority = ns.OptionsHeader(L["OPTIONS_PRIORITY_HEADER"], 11),
		spacerPriority1 = ns.OptionsSpacer(12),
		descPriority = ns.OptionsDesc(L["OPTIONS_PRIORITY_DESCRIPTION"], 13),
		spacerPriority2 = ns.OptionsSpacer(14),
		prioritizeAlts = Toggle("prioritizeAlts", "OPTIONS_PRIORITIZE_ALTS", 15),
		spacerPriority3 = ns.OptionsSpacer(16),
		prioritizeGuilds = Toggle("prioritizeGuilds", "OPTIONS_PRIORITIZE_GUILDS", 17),

		spacerStrangers0 = ns.OptionsSpacer(20),
		headerStrangers = ns.OptionsHeader(L["OPTIONS_STRANGERS_HEADER"], 21),
		spacerStrangers1 = ns.OptionsSpacer(22),
		descStrangers = ns.OptionsDesc(L["OPTIONS_STRANGERS_DESCRIPTION"], 23),
		spacerStrangers2 = ns.OptionsSpacer(24),
		prioritizeLevelingZones = Toggle("prioritizeLevelingZones", "OPTIONS_PRIORITIZE_LEVELING_ZONES", 25),
		spacerStrangers3 = ns.OptionsSpacer(26),
		prioritizeOutsideInstances = Toggle("prioritizeOutsideInstances", "OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES", 27),
		spacerStrangers4 = ns.OptionsSpacer(28),
		ignoreSummonerWarlocks = Toggle(
			"ignoreSummonerWarlocks",
			"OPTIONS_IGNORE_SUMMONER_WARLOCKS",
			29,
			L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"]:format(ns.Data.SUMMONER_MIN_LEVEL, ns.Data.SUMMONER_MAX_LEVEL)
		),

		spacerSpecs0 = ns.OptionsSpacer(30),
		headerSpecs = ns.OptionsHeader(L["OPTIONS_SPECS_HEADER"], 31),
		spacerSpecs1 = ns.OptionsSpacer(32),
		descSpecs = ns.OptionsDesc(L["OPTIONS_SPECS_INTRO"], 33),
		spacerSpecs2 = ns.OptionsSpacer(34),
	}
	local rollable = Rollable()
	local order = 40
	for _, class in ipairs(CLASS_ORDER) do
		if rollable[class] and ns.Data.SPECS[class] then
			args["class" .. class] = ClassRow(class, order)
			order = order + 1
		end
	end
	args.spacerReset = ns.OptionsSpacer(order)
	args.reset = {
		type = "execute",
		name = L["OPTIONS_SPECS_RESET"],
		desc = L["OPTIONS_SPECS_RESET_DESCRIPTION"],
		order = order + 1,
		func = function()
			wipe(ns.db.profile.specs)
			SpecsChanged()
		end,
	}
	return {
		type = "group",
		name = L["TAB_RECIPIENTS"],
		args = args,
	}
end
