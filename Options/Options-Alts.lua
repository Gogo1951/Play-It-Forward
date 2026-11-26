local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

local function Help(text)
	return Kit.Color("HELP", text)
end

--------------------------------------------------------------------------------
-- My Alts Panel
--------------------------------------------------------------------------------

-- A tree group draws its non-group args once, full width, above the tree: Send to Alts sits there.

local SPEC_WIDTH = 0.8

local function BelowValues()
	local out = {}
	for _, below in ipairs(ns.ALT_LEVELS_BELOW_ORDER) do
		out[below] = (below == 0) and L["OPTIONS_ALT_LEVEL_THEIRS"] or L["OPTIONS_ALT_LEVEL_BELOW"]:format(below)
	end
	return out
end

local function AboveValues()
	local out = {}
	for _, above in ipairs(ns.ALT_LEVELS_ABOVE_ORDER) do
		out[above] = (above == "ANY") and L["OPTIONS_ALT_LEVEL_ANY"] or L["OPTIONS_ALT_LEVEL_ABOVE"]:format(above)
	end
	return out
end

local function LevelSummary(alt)
	local low, high = ns.Alts:LevelRange(alt)
	if high == math.huge then
		return Help(L["OPTIONS_ALT_LEVELS_FROM"]:format(low))
	end
	return Help(L["OPTIONS_ALT_LEVELS_RANGE"]:format(low, high))
end

local function Changed()
	ns.RefreshMailWindow()
	ns.RefreshSettings()
end

local AltsOff = ns.OptionsProfileOff("sendToAlts")

-- Forever's "First Last" names are region-unique and its realm is an internal code ("CAMWOWUS1Realm1PvE"), so no realm shows.
local function HasSurname(alt)
	return (alt.name or ""):find(" ", 1, true) ~= nil
end

local function TreeLabel(alt)
	if HasSurname(alt) then
		return ns.ColorName(alt.name, alt.class)
	end
	return ns.ColorName((alt.name or "?") .. " - " .. (alt.realm or "?"), alt.class)
end

local function PaneTitle(alt)
	local label = ns.OptionsClassIcon(alt.class)
		.. ns.ColorName(alt.name or "?", alt.class)
		.. " "
		.. Help("(" .. (alt.level or "?") .. ")")
	if alt.realm ~= ns.PlayerRealm() and not HasSurname(alt) then
		label = label .. " " .. Help(alt.realm or "")
	end
	return label
end

local function AltsOffLine()
	if AltsOff() then
		return L["OPTIONS_ALTS_OFF"]
	end
end

local function LevelRow(order, caption, control)
	control.name = ""
	control.width = Kit.TREE_CONTROL_WIDTH
	return Kit.Row(order, nil, { Kit.Label(caption, nil, Kit.TREE_LABEL_WIDTH, control.desc), control })
end

local function AltPane(key, alt)
	local function Off()
		return not ns.Alts:Included(alt)
	end
	local args = {
		altsOff = Kit.StatusLine(AltsOffLine, 0),
		title = { type = "description", name = PaneTitle(alt), fontSize = "large", order = 1 },
		spacerTitle = Kit.Spacer(2),
		include = {
			type = "toggle",
			name = L["OPTIONS_ALT_INCLUDE"],
			desc = L["OPTIONS_ALT_INCLUDE_DESCRIPTION"],
			width = "full",
			order = 3,
			get = function()
				return ns.Alts:Included(alt)
			end,
			set = function(_, value)
				-- Stored only off the default, so a character reaching the level cap unticks itself.
				if value == ns.Alts:IncludedByDefault(alt) then
					alt.include = nil
				else
					alt.include = value
				end
				Changed()
			end,
		},
		spacerLevels = Kit.Spacer(4),
		levelsLabel = Kit.Header(L["OPTIONS_ALT_LEVELS"], 5),
		levelsBelow = LevelRow(7, L["OPTIONS_ALT_LEVEL_LOWEST"], {
			type = "select",
			desc = L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"],
			disabled = Off,
			values = BelowValues,
			sorting = ns.ALT_LEVELS_BELOW_ORDER,
			get = function()
				return ns.Alts:LevelsBelow(alt)
			end,
			set = function(_, value)
				alt.levelsBelow = (value ~= ns.ALT_LEVELS_BELOW_ORDER[1]) and value or nil
				Changed()
			end,
		}),
		spacerLevelsBetween = Kit.Spacer(8),
		levelsAbove = LevelRow(10, L["OPTIONS_ALT_LEVEL_HIGHEST"], {
			type = "select",
			desc = L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"],
			disabled = Off,
			values = AboveValues,
			sorting = ns.ALT_LEVELS_ABOVE_ORDER,
			get = function()
				return ns.Alts:LevelsAbove(alt)
			end,
			set = function(_, value)
				alt.levelsAbove = (value ~= "ANY") and value or nil
				Changed()
			end,
		}),
		spacerLevelsSummary = Kit.Spacer(11),
		levelsSummary = {
			type = "description",
			name = function()
				return LevelSummary(alt)
			end,
			fontSize = "medium",
			order = 12,
		},
		spacerSpecs = Kit.Spacer(13),
		specsLabel = Kit.Header(L["OPTIONS_ALT_SPECS"], 14),
	}
	for index, spec in ipairs(ns.Data.SPECS[alt.class] or {}) do
		args["spec" .. index] = {
			type = "toggle",
			name = ns.SpecName(alt.class, index, spec),
			desc = L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"],
			width = SPEC_WIDTH,
			order = 20 + index,
			disabled = Off,
			get = function()
				return ns.Alts:SpecsFor(alt)[spec.key] == true
			end,
			set = function(_, value)
				-- The first change writes the whole set down, so the others keep what they showed.
				local specs = ns.Alts:SpecsFor(alt)
				specs[spec.key] = value or nil
				alt.specs = specs
				Changed()
			end,
		}
	end
	args.spacerDelete = Kit.Spacer(50)
	args.delete = {
		type = "execute",
		name = L["OPTIONS_DELETE"],
		desc = L["OPTIONS_ALT_DELETE_DESCRIPTION"],
		order = 51,
		confirm = true,
		confirmText = L["OPTIONS_ALT_DELETE_CONFIRM"]:format(alt.name or "?"),
		func = function()
			ns.db.global.characters[key] = nil
			Changed()
		end,
	}
	Kit.HideAllExcept(args, AltsOff, { "altsOff" })
	return args
end

local function SortedAlts()
	local out = {}
	for key, alt in pairs(ns.db.global.characters) do
		out[#out + 1] = { key = key, alt = alt }
	end
	table.sort(out, function(a, b)
		if (a.alt.name or "") ~= (b.alt.name or "") then
			return (a.alt.name or "") < (b.alt.name or "")
		end
		return (a.alt.realm or "") < (b.alt.realm or "")
	end)
	return out
end

--------------------------------------------------------------------------------
-- The Panel
--------------------------------------------------------------------------------

function ns.BuildAltsOptions()
	local args = {
		intro = Kit.Desc(L["OPTIONS_ALTS_INTRO"], 1),
		spacerIntro = Kit.Spacer(2),
		toggleSendToAlts = {
			type = "toggle",
			name = L["OPTIONS_SEND_TO_ALTS"],
			desc = L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"],
			width = "full",
			order = 3,
			get = Kit.Get("profile", "sendToAlts"),
			set = Kit.Set("profile", "sendToAlts", ns.RefreshMailWindow),
		},
		spacerTree = Kit.Spacer(4),
	}
	local panel = {
		type = "group",
		name = Kit.SubPanelTitle(L["TAB_RECIPIENTS"], L["TAB_ALTS"]),
		childGroups = "tree",
		args = args,
	}
	if not ns.db then
		return panel
	end

	local alts = SortedAlts()
	if #alts == 0 then
		args.altsEmpty = Kit.Desc(L["OPTIONS_ALTS_EMPTY"], 5)
	end
	-- Keyed by saved key, not position: the tree remembers its selection by arg key, and Kit.PrepareTree's home returns this key.
	for index, row in ipairs(alts) do
		args[row.key] = {
			type = "group",
			name = TreeLabel(row.alt),
			order = 20 + index,
			args = AltPane(row.key, row.alt),
		}
	end
	return panel
end
