local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

--------------------------------------------------------------------------------
-- Feedback & Support Panel
--------------------------------------------------------------------------------

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

function ns.BuildFeedbackSupportOptions()
	local args = {}
	local order = 1

	for index, key in ipairs(PARAGRAPHS) do
		args["desc" .. index] = Kit.Desc(L[key], order)
		order = order + 1
		args["spacerDesc" .. index] = Kit.Spacer(order)
		order = order + 1
	end

	args.headerLinks = Kit.Header(L["OPTIONS_FEEDBACK_LINKS_HEADER"], order)
	order = order + 1

	for _, link in ipairs(LINKS) do
		local captionKey, linkKey = link[1], link[2]
		args["spacer" .. linkKey] = Kit.Spacer(order)
		args["link" .. linkKey] = Kit.LinkRow(order + 1, L[captionKey], ns.LINKS[linkKey])
		order = order + 2
	end

	args.spacerCopyHint = Kit.Spacer(order)
	args.copyHint = Kit.Desc(Kit.Color("HELP", L["OPTIONS_COPY_LINK"]), order + 1)

	args.spacerVersion = {
		type = "description",
		name = " ",
		width = "full",
		order = 998,
	}
	args.versionLine = {
		type = "description",
		name = Kit.Color("INFO", L["OPTIONS_VERSION"]:format(ns.Version)),
		fontSize = "medium",
		order = 999,
	}

	return {
		type = "group",
		name = L["OPTIONS_LEVEL_UP_TITLE"],
		args = args,
	}
end
