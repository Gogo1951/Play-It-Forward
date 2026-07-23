local _, ns = ...

local D = ns.DiagnosticsStrings
local GetColor = ns.GetColor
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

--------------------------------------------------------------------------------
-- Diagnostic Tools Panel
--------------------------------------------------------------------------------

--[[
	One runtime toggle gates the whole panel: with it off, only the warning text and the
	toggle are visible. ns.OptionsHeader and ns.OptionsSpacer take no hidden argument,
	which is why the gated sections inline their header widgets.
]]

local function DiagnosticsOn()
	return ns.diagnostics and ns.diagnostics.enabled == true
end

local function Hidden()
	return not DiagnosticsOn()
end

local function Refresh()
	AceConfigRegistry:NotifyChange(ns.OPTIONS_REGISTRY.Diagnostics)
end

local function SectionHeader(text, order)
	return { type = "header", name = GetColor("TITLE") .. text .. "|r", order = order, hidden = Hidden }
end

local function ReportOutput(field, order)
	return {
		type = "input",
		name = "",
		multiline = 12,
		width = "full",
		order = order,
		hidden = Hidden,
		get = function()
			return ns.diagnostics[field] or ""
		end,
		set = function() end,
	}
end

local function ReportButton(label, order, builder, field)
	return {
		type = "execute",
		name = label,
		order = order,
		hidden = Hidden,
		func = function()
			ns.diagnostics[field] = builder()
			Refresh()
		end,
	}
end

-- Helper text, so HELP rather than BODY: silver is the palette's role for hints and pro tips.
local function HintText(text, order)
	return {
		type = "description",
		name = GetColor("HELP") .. text .. "|r",
		fontSize = "medium",
		order = order,
		hidden = Hidden,
	}
end

function ns.BuildDiagnosticsOptions()
	return {
		type = "group",
		name = D.TAB,
		args = {
			descWarning = ns.OptionsDesc(D.WARNING, 1),
			spaceEnable = ns.OptionsSpacer(2),
			toggleEnable = {
				type = "toggle",
				name = D.ENABLE,
				width = "full",
				order = 3,
				get = function()
					return DiagnosticsOn()
				end,
				set = function(_, value)
					ns:SetDiagnosticsEnabled(value)
					Refresh()
				end,
			},

			-- Bag Scan, the export that answers "why isn't this item listed"
			headerBags = SectionHeader(D.BAGS_TITLE, 5),
			buttonBags = ReportButton(D.BAGS_BUTTON, 6, function()
				return ns:BuildBagScanReport()
			end, "bagReport"),
			outputBags = ReportOutput("bagReport", 7),
			descBagsHint = HintText(D.BAGS_HINT, 8),

			headerRoster = SectionHeader(D.ROSTER_TITLE, 10),
			buttonRoster = ReportButton(D.ROSTER_BUTTON, 11, function()
				return ns:BuildRosterReport()
			end, "rosterReport"),
			outputRoster = ReportOutput("rosterReport", 12),
			descRosterHint = HintText(D.ROSTER_HINT, 13),

			headerVerdict = SectionHeader(D.VERDICT_TITLE, 15),
			inputVerdict = {
				type = "input",
				name = D.VERDICT_INPUT,
				width = "double",
				order = 16,
				hidden = Hidden,
				get = function()
					return ns.diagnostics.verdictLink or ""
				end,
				set = function(_, value)
					ns.diagnostics.verdictLink = value
				end,
			},
			descVerdictHint = HintText(D.VERDICT_INPUT_HINT, 17),
			buttonVerdict = ReportButton(D.VERDICT_BUTTON, 18, function()
				return ns:BuildItemVerdictReport(ns.diagnostics.verdictLink)
			end, "verdictReport"),
			outputVerdict = ReportOutput("verdictReport", 19),

			headerGroups = SectionHeader(D.GROUPS_TITLE, 21),
			inputGroupLevel = {
				type = "input",
				name = D.GROUPS_INPUT,
				width = "half",
				order = 22,
				hidden = Hidden,
				get = function()
					return tostring(ns.diagnostics.groupLevel or "")
				end,
				set = function(_, value)
					ns.diagnostics.groupLevel = tonumber(value)
				end,
			},
			buttonArmorGroups = ReportButton(D.GROUPS_ARMOR_BUTTON, 23, function()
				return ns:BuildArmorGroupsReport(ns.diagnostics.groupLevel)
			end, "groupsReport"),
			buttonWeaponGroups = ReportButton(D.GROUPS_WEAPON_BUTTON, 24, function()
				return ns:BuildWeaponGroupsReport(ns.diagnostics.groupLevel)
			end, "groupsReport"),
			outputGroups = ReportOutput("groupsReport", 25),

			headerMail = SectionHeader(D.MAIL_TITLE, 27),
			buttonMail = ReportButton(D.MAIL_BUTTON, 28, function()
				return ns:BuildMailPreviewReport()
			end, "mailReport"),
			outputMail = ReportOutput("mailReport", 29),

			headerWindow = SectionHeader(D.WINDOW_TITLE, 31),
			buttonWindow = {
				type = "execute",
				name = D.WINDOW_BUTTON,
				order = 32,
				hidden = Hidden,
				func = function()
					ns.UI:ForceShow()
				end,
			},
			descWindowHint = HintText(D.WINDOW_HINT, 33),

			-- Given Away sharing probe: the last context probe before the shared framework sections.
			headerGenerosity = SectionHeader(D.GENEROSITY_TITLE, 35),
			buttonGenerosity = ReportButton(D.GENEROSITY_BUTTON, 36, function()
				return ns:BuildGenerosityReport()
			end, "generosityReport"),
			outputGenerosity = ReportOutput("generosityReport", 37),
			descGenerosityHint = HintText(D.GENEROSITY_HINT, 38),

			headerEventLog = SectionHeader(D.EVENT_LOG_TITLE, 40),
			buttonStartLog = {
				type = "execute",
				name = D.EVENT_LOG_START,
				order = 41,
				hidden = Hidden,
				func = function()
					ns:StartEventLog()
					Refresh()
				end,
			},
			buttonStopLog = {
				type = "execute",
				name = D.EVENT_LOG_STOP,
				order = 42,
				hidden = Hidden,
				func = function()
					ns:StopEventLog()
					Refresh()
				end,
			},
			buttonShowLog = ReportButton(D.EVENT_LOG_SHOW, 43, function()
				return ns:BuildEventLogReport()
			end, "eventLogReport"),
			outputEventLog = ReportOutput("eventLogReport", 44),
			descEventLogHint = HintText(D.EVENT_LOG_HINT, 45),

			headerEvents = SectionHeader(D.EVENTS_TITLE, 47),
			buttonEvents = ReportButton(D.EVENTS_BUTTON, 48, function()
				return ns:RunEventChecks()
			end, "eventsReport"),
			outputEvents = ReportOutput("eventsReport", 49),

			headerApi = SectionHeader(D.API_TITLE, 51),
			buttonApi = ReportButton(D.API_BUTTON, 52, function()
				return ns:RunApiChecks()
			end, "apiReport"),
			outputApi = ReportOutput("apiReport", 53),

			headerDisplay = SectionHeader(D.DISPLAY_TITLE, 55),
			buttonDisplay = ReportButton(D.DISPLAY_BUTTON, 56, function()
				return ns:BuildDisplayReport()
			end, "displayReport"),
			outputDisplay = ReportOutput("displayReport", 57),

			headerAddons = SectionHeader(D.ADDONS_TITLE, 59),
			buttonAddons = ReportButton(D.ADDONS_BUTTON, 60, function()
				return ns:BuildAddOnReport()
			end, "addOnReport"),
			outputAddons = ReportOutput("addOnReport", 61),

			headerSaved = SectionHeader(D.SAVED_TITLE, 63),
			buttonSaved = ReportButton(D.SAVED_BUTTON, 64, function()
				return ns:BuildSavedVariablesReport()
			end, "savedReport"),
			outputSaved = ReportOutput("savedReport", 65),

			headerLibs = SectionHeader(D.LIBS_TITLE, 67),
			buttonLibs = ReportButton(D.LIBS_BUTTON, 68, function()
				return ns:BuildLibraryReport()
			end, "libraryReport"),
			outputLibs = ReportOutput("libraryReport", 69),

			headerTaint = SectionHeader(D.TAINT_TITLE, 71),
			descTaintState = {
				type = "description",
				name = function()
					return GetColor("BODY") .. string.format(D.TAINT_STATE, ns:GetTaintLogState()) .. "|r"
				end,
				fontSize = "medium",
				order = 72,
				hidden = Hidden,
			},
			buttonTaintOn = {
				type = "execute",
				name = D.TAINT_ON,
				order = 73,
				hidden = Hidden,
				func = function()
					ns:SetTaintLog(true)
					Refresh()
				end,
			},
			buttonTaintOff = {
				type = "execute",
				name = D.TAINT_OFF,
				order = 74,
				hidden = Hidden,
				func = function()
					ns:SetTaintLog(false)
					Refresh()
				end,
			},
			descTaintHint = HintText(D.TAINT_HINT, 75),

			-- External Tools (point at mature tools rather than reimplement them)
			headerTools = SectionHeader(D.TOOLS_TITLE, 77),
			descToolsErrors = {
				type = "description",
				name = GetColor("BODY") .. string.format(
					D.TOOLS_ERRORS,
					GetColor("INFO") .. "/console scriptErrors 1|r" .. GetColor("BODY")
				) .. "|r",
				fontSize = "medium",
				order = 78,
				hidden = Hidden,
			},
			descToolsEtrace = {
				type = "description",
				name = GetColor("BODY")
					.. string.format(D.TOOLS_ETRACE, GetColor("INFO") .. "/etrace|r" .. GetColor("BODY"))
					.. "|r",
				fontSize = "medium",
				order = 79,
				hidden = Hidden,
			},
		},
	}
end
