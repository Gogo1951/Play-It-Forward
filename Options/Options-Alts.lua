local _, ns = ...
local L = ns.L

local Help = ns.OptionsHelp

--------------------------------------------------------------------------------
-- My Alts Panel
--------------------------------------------------------------------------------

--[[
	Your own characters, nested under Recipients. childGroups = "tree" splits the panel in two,
	Magic Eraser's list layout: every character down the left, the one picked on the right with a
	tick to include it, the lowest and highest gear levels it is mailed, the specs it is mailed
	gear for, and a Delete. The choices live on the saved entries themselves
	(ns.db.global.characters), account-wide, because alts are.

	The Send to Alts switch sits above the tree: a tree group draws its own non-group args once,
	full width, between the title and the tree.

	REGISTERED AS A BUILDER FUNCTION, so the rows are read again each time the panel is drawn: a
	character logging in adds a row without a reload.
]]

local SPEC_WIDTH = 0.8
-- The pane is narrower than a panel, so the gear level rows use their own label and control widths.
local LEVEL_LABEL_WIDTH = 1.2
local LEVEL_CONTROL_WIDTH = 1.4

-- The words for each stop, counted from the alt's own level so they read the same whatever it is.
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

-- The two dropdowns turned into real levels for this alt, so the player sees what they set.
local function LevelSummary(alt)
	local low, high = ns.Alts:LevelRange(alt)
	if high == math.huge then
		return Help(L["OPTIONS_ALT_LEVELS_FROM"]:format(low))
	end
	return Help(L["OPTIONS_ALT_LEVELS_RANGE"]:format(low, high))
end

-- A change to who is offered what re-reads the bags, and redraws this panel.
local function Changed()
	ns.RefreshMailWindow()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(ns.OPTIONS_REGISTRY.Alts)
end

local AltsOff = ns.OptionsProfileOff("sendToAlts")

-- The left column: the character as Magic Eraser lists one, "Name - Realm" in its class color.
local function TreeLabel(alt)
	return ns.ColorName((alt.name or "?") .. " - " .. (alt.realm or "?"), alt.class)
end

-- The right column's title: icon, name, level, and where it is when that is not here.
local function PaneTitle(alt)
	local label = ns.OptionsClassIcon(alt.class)
		.. ns.ColorName(alt.name or "?", alt.class)
		.. " "
		.. Help("(" .. (alt.level or "?") .. ")")
	if alt.realm ~= ns.PlayerRealm() then
		label = label .. " " .. Help(alt.realm or "")
	end
	return label
end

local function AltPane(key, alt)
	local function Off()
		return AltsOff() or not ns.Alts:Included(alt)
	end
	local args = {
		title = { type = "description", name = PaneTitle(alt), fontSize = "large", order = 1 },
		spacerTitle = ns.OptionsSpacer(2),
		include = {
			type = "toggle",
			name = L["OPTIONS_ALT_INCLUDE"],
			desc = L["OPTIONS_ALT_INCLUDE_DESCRIPTION"],
			width = "full",
			order = 3,
			disabled = AltsOff,
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
		--[[
			Gear Levels: the lowest and highest gear this alt is mailed, each a label beside its
			dropdown, a spacer between the rows and before the line turning both into real levels.
			Stored only off the default.
		]]
		spacerLevels = ns.OptionsSpacer(4),
		levelsLabel = {
			type = "description",
			name = ns.GetColor("TITLE") .. L["OPTIONS_ALT_LEVELS"] .. "|r",
			fontSize = "medium",
			order = 5,
		},
		levelsBelowLabel = ns.OptionsRowLabel(L["OPTIONS_ALT_LEVEL_LOWEST"], 6, LEVEL_LABEL_WIDTH),
		levelsBelow = {
			type = "select",
			name = "",
			desc = L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"],
			width = LEVEL_CONTROL_WIDTH,
			order = 7,
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
		},
		spacerLevelsBetween = ns.OptionsSpacer(8),
		levelsAboveLabel = ns.OptionsRowLabel(L["OPTIONS_ALT_LEVEL_HIGHEST"], 9, LEVEL_LABEL_WIDTH),
		levelsAbove = {
			type = "select",
			name = "",
			desc = L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"],
			width = LEVEL_CONTROL_WIDTH,
			order = 10,
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
		},
		spacerLevelsSummary = ns.OptionsSpacer(11),
		levelsSummary = {
			type = "description",
			name = function()
				return LevelSummary(alt)
			end,
			fontSize = "medium",
			order = 12,
		},
		spacerSpecs = ns.OptionsSpacer(13),
		specsLabel = {
			type = "description",
			name = ns.GetColor("TITLE") .. L["OPTIONS_ALT_SPECS"] .. "|r",
			fontSize = "medium",
			order = 14,
		},
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
	args.spacerDelete = ns.OptionsSpacer(50)
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
	return args
end

-- Alphabetical by name, then by realm for two characters sharing one.
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
		intro = ns.OptionsDesc(L["OPTIONS_ALTS_INTRO"], 1),
		spacerIntro = ns.OptionsSpacer(2),
		toggleSendToAlts = ns.OptionsProfileToggle(
			"sendToAlts",
			L["OPTIONS_SEND_TO_ALTS"],
			L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"],
			3,
			"full",
			Changed
		),
		spacerTree = ns.OptionsSpacer(4),
	}
	local panel = { type = "group", name = L["TAB_ALTS"], childGroups = "tree", args = args }
	if not ns.db then
		return panel
	end

	local alts = SortedAlts()
	if #alts == 0 then
		args.altsEmpty = ns.OptionsDesc(L["OPTIONS_ALTS_EMPTY"], 5)
	end
	--[[
		Keyed by the character's saved key, not its position: the tree remembers the selected node
		by its arg key, so a key that moved when a character appeared would reselect another one.
	]]
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
