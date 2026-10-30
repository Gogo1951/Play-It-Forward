local _, ns = ...
local L = ns.L

local GetColor = ns.GetColor

--------------------------------------------------------------------------------
-- Feedback & Support Panel
--------------------------------------------------------------------------------

-- The Level Up note, one paragraph per key, in display order.
local PARAGRAPHS = {
	"OPTIONS_LEVEL_UP_INTRO",
	"OPTIONS_LEVEL_UP_WAYS",
	"OPTIONS_LEVEL_UP_FEEDBACK",
	"OPTIONS_LEVEL_UP_FRIEND",
	"OPTIONS_LEVEL_UP_CURSEFORGE",
	"OPTIONS_LEVEL_UP_GITHUB",
	"OPTIONS_LEVEL_UP_THANKS",
}

-- { captionKey, linkKey }, in display order.
local LINKS = {
	{ "OPTIONS_DISCORD", "DISCORD" },
	{ "OPTIONS_CURSEFORGE", "CURSEFORGE" },
	{ "OPTIONS_WAGO", "WAGO" },
	{ "OPTIONS_GITHUB", "GITHUB" },
}

-- A one-word caption against a full URL, the two still totalling one row.
local LINK_LABEL_WIDTH = 0.6

function ns.BuildFeedbackSupportOptions()
	local args = {}
	local order = 1

	for index, key in ipairs(PARAGRAPHS) do
		args["desc" .. index] = ns.OptionsDesc(L[key], order)
		order = order + 1
		args["spacerDesc" .. index] = ns.OptionsSpacer(order)
		order = order + 1
	end

	args.headerLinks = ns.OptionsHeader(L["OPTIONS_FEEDBACK_LINKS_HEADER"], order)
	args.spacerLinks = ns.OptionsSpacer(order + 1)
	order = order + 2

	--[[
		A full-width spacer is what ends a label-beside-value row, so one follows every pair,
		the last included: it is also the blank line above the copy hint.
	]]
	for _, link in ipairs(LINKS) do
		local captionKey, linkKey = link[1], link[2]
		args["label" .. linkKey] =
			ns.OptionsRowLabel(GetColor("TITLE") .. L[captionKey] .. "|r", order, LINK_LABEL_WIDTH)
		args["link" .. linkKey] = {
			type = "input",
			name = "",
			width = ns.OPTIONS_ROW_WIDTH - LINK_LABEL_WIDTH,
			order = order + 1,
			get = function()
				return ns.LINKS[linkKey]
			end,
			set = function() end,
		}
		args["spacer" .. linkKey] = ns.OptionsSpacer(order + 2)
		order = order + 3
	end

	args.copyHint = ns.OptionsDesc(GetColor("HELP") .. L["OPTIONS_COPY_LINK"] .. "|r", order)

	args.spacerVersion = {
		type = "description",
		name = " ",
		width = "full",
		order = 998,
	}
	args.versionLine = {
		type = "description",
		name = GetColor("INFO") .. L["OPTIONS_VERSION"]:format(ns.Version) .. "|r",
		fontSize = "medium",
		order = 999,
	}

	return {
		type = "group",
		name = L["OPTIONS_LEVEL_UP_TITLE"],
		args = args,
	}
end
