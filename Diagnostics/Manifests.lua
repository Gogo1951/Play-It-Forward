local _, ns = ...

local GetClientHeader = ns.GetDiagnosticClientHeader

--------------------------------------------------------------------------------
-- API Endpoints
--------------------------------------------------------------------------------

--[[
	Existence and shape checks only: read-only, no side effects, no protected calls. One row per
	API reached through a compatibility guard, plus the load-bearing calls the scan, search and
	mail loops depend on. Where the add-on picks between two, both halves are rows, and a FAIL on
	one half is the report saying which branch that client took.
]]
ns.DIAGNOSTIC_API_CHECKS = {
	-- { label, testFunction }
	{
		"C_AddOns.GetAddOnMetadata",
		function()
			return type(C_AddOns) == "table" and type(C_AddOns.GetAddOnMetadata) == "function"
		end,
	},
	{
		"C_Container.GetContainerNumSlots",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerNumSlots) == "function"
		end,
	},
	{
		"C_Container.GetContainerItemLink",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerItemLink) == "function"
		end,
	},
	{
		"C_Container.GetContainerItemInfo",
		function()
			return type(C_Container) == "table" and type(C_Container.GetContainerItemInfo) == "function"
		end,
	},
	{
		"C_Container.UseContainerItem",
		function()
			return type(C_Container) == "table" and type(C_Container.UseContainerItem) == "function"
		end,
	},
	--[[
		No rows for the bare GetContainerNumSlots/GetContainerItemInfo globals: every target ships
		C_Container. The C_TooltipInfo rows are Features/Scan-Tooltip.lua's runtime branch, and
		Classic Era lacks them, so a FAIL there is the report saying which path that client takes.
	]]
	{
		"C_Item.GetItemInfoInstant",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemInfoInstant) == "function"
		end,
	},
	{
		"C_Item.GetItemInfo",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemInfo) == "function"
		end,
	},
	{
		"C_Item.IsEquippableItem",
		function()
			return type(C_Item) == "table" and type(C_Item.IsEquippableItem) == "function"
		end,
	},
	-- Both halves of ns.GetItemStats: only WoW Forever ships C_Item.GetItemStats.
	{
		"C_Item.GetItemStats",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemStats) == "function"
		end,
	},
	{
		"GetItemStats (legacy)",
		function()
			return type(GetItemStats) == "function"
		end,
	},
	{
		"C_TooltipInfo.GetHyperlink",
		function()
			return type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetHyperlink) == "function"
		end,
	},
	{
		"TooltipUtil.SurfaceArgs",
		function()
			return type(TooltipUtil) == "table" and type(TooltipUtil.SurfaceArgs) == "function"
		end,
	},
	--[[
		The stat-name globals the locale-safe "+9 Intellect" path reads, probed one at a time:
		a missing one falls back to the English name and that stat silently never parses.
	]]
	{
		"ITEM_MOD_STRENGTH_SHORT",
		function()
			return type(ITEM_MOD_STRENGTH_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_AGILITY_SHORT",
		function()
			return type(ITEM_MOD_AGILITY_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_STAMINA_SHORT",
		function()
			return type(ITEM_MOD_STAMINA_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_INTELLECT_SHORT",
		function()
			return type(ITEM_MOD_INTELLECT_SHORT) == "string"
		end,
	},
	{
		"ITEM_MOD_SPIRIT_SHORT",
		function()
			return type(ITEM_MOD_SPIRIT_SHORT) == "string"
		end,
	},
	--[[
		English-only by decision for the initial release, so this row fails on any other locale on
		purpose: a known limitation, rather than items quietly scoring low for no visible reason.
	]]
	{
		"Equip-effect parsing available (English clients only)",
		function()
			return ns.Tooltip.equipPatternsUsable == true
		end,
	},
	--[[
		Both of Blizzard's line formats, fed literal strings so these rows need no item, no cache
		and no tooltip and cannot flake. The second is the regression guard: a random-suffix roll
		arrives color-wrapped rather than bare, and when that form stops parsing every rolled green
		reads as statless and lands in the vendor pile while fixed-stat items carry on working. The
		escapes are built from parts because this label is printed into a font string unescaped,
		where a literal color code would be swallowed as formatting.
	]]
	{
		"Tooltip stat parsing, plain line",
		function()
			local stats = ns.Tooltip:StatsFromLines({ "Item Name", "+4 Intellect" })
			return stats.INTELLECT == 4
		end,
	},
	{
		"Tooltip stat parsing, color-wrapped line (random suffix and enchants)",
		function()
			local wrapped = "|" .. "cffffffff+15 Intellect|" .. "r\n"
			local stats = ns.Tooltip:StatsFromLines({ "Item Name", wrapped })
			return stats.INTELLECT == 15
		end,
	},
	--[[
		The third line format, and the one with no GetItemStats key behind it: a per-school damage
		roll exists only as tooltip text, so nothing covers it when this stops parsing.
	]]
	{
		"Tooltip stat parsing, equip-effect line",
		function()
			if not ns.Tooltip.equipPatternsUsable then
				return false
			end
			local stats = ns.Tooltip:StatsFromLines({
				"Item Name",
				"Equip: Increases damage done by Nature spells and effects by up to 7.",
			})
			return stats.NATURE == 7
		end,
	},
	--[[
		End to end on a real item: the rows above prove the parser understands the formats, this
		proves the client still hands back lines at all. Reports which path the read took, observed
		rather than inferred from whether the API exists, and separates the two ways this fails --
		a naked character, and a client that stopped handing back lines.
	]]
	{
		"Tooltip readable for a real item (needs something equipped)",
		function()
			for slot = 1, 19 do
				local link = GetInventoryItemLink("player", slot)
				if link then
					local _, source = ns.Tooltip:Stats(link)
					return source ~= "none", "read via " .. source
				end
			end
			return false, "nothing equipped to read"
		end,
	},
	--[[
		Load-bearing for routing, not display: the eligible class list is built from the client
		flavor and this answer, so a nil faction silently widens every item's candidate list.
	]]
	{
		"UnitFactionGroup returns this player's faction",
		function()
			local faction = UnitFactionGroup("player")
			return faction == "Alliance" or faction == "Horde"
		end,
	},
	--[[
		Load-bearing for identity. ns.QualifyPlayerName is what tells two sightings of one player
		apart from two players -- /who answers bare where the guild roster qualifies the same
		character -- and pooling one person twice means two parcels in one mailbox. Reports which
		read answered, since the second is a retry on an unresolved realm rather than a fallback.
	]]
	{
		"Realm name for the identity key",
		function()
			local normalized = GetNormalizedRealmName and GetNormalizedRealmName()
			if normalized and normalized ~= "" then
				return true, "via GetNormalizedRealmName: " .. normalized
			end
			local plain = GetRealmName and GetRealmName()
			if plain and plain ~= "" then
				return true, "via GetRealmName: " .. plain
			end
			return false, "neither GetNormalizedRealmName nor GetRealmName answered"
		end,
	},
	{
		"C_FriendList.SendWho",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.SendWho) == "function"
		end,
	},
	{
		"C_FriendList.SetWhoToUi",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.SetWhoToUi) == "function"
		end,
	},
	{
		"C_FriendList.GetWhoInfo",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.GetWhoInfo) == "function"
		end,
	},
	{
		"C_FriendList.GetNumWhoResults",
		function()
			return type(C_FriendList) == "table" and type(C_FriendList.GetNumWhoResults) == "function"
		end,
	},
	--[[
		The race-to-faction table Features/Recipients-Who.lua drops other-faction results by. Without
		either reader it drops nobody, so on Forever, which answers /who with both factions, every
		send to the other side is refused.
	]]
	{
		"C_CreatureInfo.GetRaceInfo",
		function()
			return type(C_CreatureInfo) == "table" and type(C_CreatureInfo.GetRaceInfo) == "function"
		end,
	},
	{
		"C_CreatureInfo.GetFactionInfo",
		function()
			return type(C_CreatureInfo) == "table" and type(C_CreatureInfo.GetFactionInfo) == "function"
		end,
	},
	--[[
		The class names /who filters on and results are read back by. A missing table drops every
		result the client sends without a class token as an unreadable class.
	]]
	{
		"LOCALIZED_CLASS_NAMES_MALE",
		function()
			return type(LOCALIZED_CLASS_NAMES_MALE) == "table"
		end,
	},
	{
		"LOCALIZED_CLASS_NAMES_FEMALE",
		function()
			return type(LOCALIZED_CLASS_NAMES_FEMALE) == "table"
		end,
	},
	--[[
		The Blizzard frames Features/Recipients-Who.lua quiets for the life of a query, so the Who
		panel never opens over the mailbox and closes it.
	]]
	{
		"Who panel frames quieted during a query",
		function()
			local found = {}
			for _, name in ipairs({ "FriendsFrame", "WhoFrame", "HideUIPanel" }) do
				if _G[name] ~= nil then
					found[#found + 1] = name
				end
			end
			local detail = #found > 0 and ("present: " .. table.concat(found, ", ")) or "none present"
			return type(FriendsFrame) == "table" and type(FriendsFrame.IsEventRegistered) == "function", detail
		end,
	},
	--[[
		GetGuildRosterLastOnline is the one to watch: the activity window in
		Features/Recipients-Guild.lua is built entirely on it, and without it every offline member
		reads as too stale to mail, leaving the guild to contribute only whoever is logged in.
	]]
	{
		"GetGuildRosterInfo",
		function()
			return type(GetGuildRosterInfo) == "function"
		end,
	},
	{
		"GetGuildRosterLastOnline",
		function()
			return type(GetGuildRosterLastOnline) == "function"
		end,
	},
	-- The only roster request Guild:Request makes; it has no fallback, so neither does this row.
	{
		"C_GuildInfo.GuildRoster",
		function()
			return type(C_GuildInfo) == "table" and type(C_GuildInfo.GuildRoster) == "function"
		end,
	},
	{
		"IsInGuild",
		function()
			return type(IsInGuild) == "function"
		end,
	},
	{
		"GetNumGuildMembers",
		function()
			return type(GetNumGuildMembers) == "function"
		end,
	},
	{
		"C_PlayerInteractionManager.IsInteractingWithNpcOfType",
		function()
			return type(C_PlayerInteractionManager) == "table"
				and type(C_PlayerInteractionManager.IsInteractingWithNpcOfType) == "function"
		end,
	},
	{
		"Enum.PlayerInteractionType.MailInfo",
		function()
			return type(Enum) == "table"
				and type(Enum.PlayerInteractionType) == "table"
				and Enum.PlayerInteractionType.MailInfo ~= nil
		end,
	},
	{
		"SendMail",
		function()
			return type(SendMail) == "function"
		end,
	},
	{
		"GetSendMailItem",
		function()
			return type(GetSendMailItem) == "function"
		end,
	},
	--[[
		The Blizzard mail frames the Distribute path touches, each guarded in
		Features/Mail-Sender.lua. A mail add-on that replaces them shows here: with SendMailFrame
		missing, every run ends as "the mail panel is closed" before an item is touched.
	]]
	{
		"MailFrame",
		function()
			return type(MailFrame) == "table"
		end,
	},
	{
		"SendMailFrame",
		function()
			return type(SendMailFrame) == "table"
		end,
	},
	{
		"SendMailNameEditBox",
		function()
			return type(SendMailNameEditBox) == "table"
		end,
	},
	{
		"SendMailSubjectEditBox",
		function()
			return type(SendMailSubjectEditBox) == "table"
		end,
	},
	{
		"MailFrameTab_OnClick",
		function()
			return type(MailFrameTab_OnClick) == "function"
		end,
	},
	{
		"ClearSendMail",
		function()
			return type(ClearSendMail) == "function"
		end,
	},
	--[[
		The body box Features/Mail-Sender.lua picks by availability: SendMailBodyEditBox is the retail
		name, and on Classic Era the body lives behind MailEditBox:GetEditBox(). With neither resolving,
		the To and Subject boxes still fill and SendMail posts a letter with an empty body and reports
		success, so a stranger receives a bare item with no note and nothing surfaces an error. One
		of the two answers on every target, and the row says which.
	]]
	{
		"Mail body edit box",
		function()
			if type(MailEditBox) == "table" and type(MailEditBox.GetEditBox) == "function" then
				return true, "via MailEditBox:GetEditBox()"
			end
			if SendMailBodyEditBox ~= nil then
				return true, "via SendMailBodyEditBox"
			end
			return false, "neither MailEditBox:GetEditBox() nor SendMailBodyEditBox"
		end,
	},
	--[[
		The Given Away broadcast in Features/Generosity-Broadcast.lua. Every target ships
		C_ChatInfo, so a FAIL means sharing cannot register or send at all.
	]]
	{
		"C_ChatInfo.SendAddonMessage",
		function()
			return type(C_ChatInfo) == "table" and type(C_ChatInfo.SendAddonMessage) == "function"
		end,
	},
	{
		"C_ChatInfo.RegisterAddonMessagePrefix",
		function()
			return type(C_ChatInfo) == "table" and type(C_ChatInfo.RegisterAddonMessagePrefix) == "function"
		end,
	},
	--[[
		Load-bearing for sharing, not display: ns.AtRest gates every send and the tooltip block on it,
		and answers false when the API is missing, so a FAIL here means sharing is off everywhere.
	]]
	{
		"IsResting",
		function()
			return type(IsResting) == "function"
		end,
	},
	--[[
		The client's own money formatter, which renders the coin icons in the Generosity block.
		ns.MoneyString falls back to a plain "Xg Ys Zc" without it, so this failing is cosmetic --
		but a fallback nothing reports is a fallback nobody knows they took.
	]]
	{
		"Money formatting for the Generosity totals",
		function()
			if type(GetCoinTextureString) == "function" then
				return true, "via GetCoinTextureString, with coin icons"
			end
			return false, "falling back to a plain gold/silver/copper string"
		end,
	},
	{
		"C_XMLUtil.GetTemplateInfo",
		function()
			return type(C_XMLUtil) == "table" and type(C_XMLUtil.GetTemplateInfo) == "function"
		end,
	},
	--[[
		Where /pif actually lands. The failing case is silent by design -- the panel opens, just as
		a standalone window rather than the add-on's page in the Options interface.

		Reports the route rather than the APIs behind it: which of AddToBlizOptions' identifiers a
		client honors is not something the presence of Settings.OpenToCategory answers.
	]]
	{
		"Options panel opens inside the Blizzard interface",
		function()
			local _, inOptions, description = ns:OptionsPanelRoute()
			return inOptions, description
		end,
	},
	{
		"C_Item.RequestLoadItemDataByID",
		function()
			return type(C_Item) == "table" and type(C_Item.RequestLoadItemDataByID) == "function"
		end,
	},
	{
		"C_Item.DoesItemExistByID",
		function()
			return type(C_Item) == "table" and type(C_Item.DoesItemExistByID) == "function"
		end,
	},
	-- Validate Data's extra reads; one a client lacks leaves its columns blank.
	{
		"C_Item.GetItemSpell",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemSpell) == "function"
		end,
	},
	{
		"C_Item.GetDetailedItemLevelInfo",
		function()
			return type(C_Item) == "table" and type(C_Item.GetDetailedItemLevelInfo) == "function"
		end,
	},
	{
		"C_Item.GetItemClassInfo",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemClassInfo) == "function"
		end,
	},
	{
		"C_Item.GetItemSubClassInfo",
		function()
			return type(C_Item) == "table" and type(C_Item.GetItemSubClassInfo) == "function"
		end,
	},
	{
		"C_Spell.GetSpellDescription",
		function()
			return type(C_Spell) == "table" and type(C_Spell.GetSpellDescription) == "function"
		end,
	},
	{
		"C_Spell.RequestLoadSpellData",
		function()
			return type(C_Spell) == "table" and type(C_Spell.RequestLoadSpellData) == "function"
		end,
	},
	-- Both halves of ns.GetTooltipLines, which Validate Data reads each item's tooltip through.
	{
		"C_TooltipInfo.GetItemByID",
		function()
			return type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetItemByID) == "function"
		end,
	},
	{
		"C_TooltipInfo.GetSpellByID",
		function()
			return type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetSpellByID) == "function"
		end,
	},
	{
		"Hidden scan tooltip (legacy)",
		function()
			return type(CreateFrame) == "function"
				and type(GameTooltip) == "table"
				and type(GameTooltip.SetHyperlink) == "function"
				and type(GameTooltip.NumLines) == "function"
		end,
	},
	-- The Generosity tooltip block: the unit post-call, the older script hook, and the secret check before both.
	{
		"TooltipDataProcessor.AddTooltipPostCall",
		function()
			return type(TooltipDataProcessor) == "table" and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
		end,
	},
	{
		"Enum.TooltipDataType.Unit",
		function()
			return type(Enum) == "table" and type(Enum.TooltipDataType) == "table" and Enum.TooltipDataType.Unit ~= nil
		end,
	},
	{
		"GameTooltip OnTooltipSetUnit script (legacy)",
		function()
			return type(GameTooltip) == "table" and GameTooltip:HasScript("OnTooltipSetUnit") == true
		end,
	},
	{
		"C_Secrets.ShouldUnitIdentityBeSecret",
		function()
			return type(C_Secrets) == "table" and type(C_Secrets.ShouldUnitIdentityBeSecret) == "function"
		end,
	},
	-- The /who zone filter asks the client for each area's name.
	{
		"C_Map.GetAreaInfo",
		function()
			return type(C_Map) == "table" and type(C_Map.GetAreaInfo) == "function"
		end,
	},
	{
		"C_Seasons.GetActiveSeason",
		function()
			return type(C_Seasons) == "table" and type(C_Seasons.GetActiveSeason) == "function"
		end,
	},
	{
		"Enum.SeasonID.SeasonOfDiscovery",
		function()
			return type(Enum) == "table" and type(Enum.SeasonID) == "table" and Enum.SeasonID.SeasonOfDiscovery ~= nil
		end,
	},
	{
		"Settings.OpenToCategory",
		function()
			return type(Settings) == "table" and type(Settings.OpenToCategory) == "function"
		end,
	},
	{
		"C_EventUtils.IsEventValid",
		function()
			return type(C_EventUtils) == "table" and type(C_EventUtils.IsEventValid) == "function"
		end,
	},
	{
		"GetCVar",
		function()
			return type(GetCVar) == "function"
		end,
	},
	{
		"SetCVar",
		function()
			return type(SetCVar) == "function"
		end,
	},
}

--------------------------------------------------------------------------------
-- Play It Forward Context
--------------------------------------------------------------------------------

-- The add-on's own example reports, appended to the shared Event Log intro.
ns.DiagnosticsStrings.EVENT_LOG_EXAMPLES = "Best for 'the window never opened' or 'nothing was sent' reports."

--[[
	Item links are display escapes: pasted raw they render as a colored swatch, hiding the link
	data the report exists to show. Doubling the pipes shows them verbatim.
]]
local function EscapePipes(text)
	return (tostring(text or "?"):gsub("|", "||"))
end

local function FormatStats(stats)
	local keys = {}
	for token in pairs(stats or {}) do
		keys[#keys + 1] = token
	end
	if #keys == 0 then
		return "(none)"
	end
	table.sort(keys)
	local parts = {}
	for _, token in ipairs(keys) do
		parts[#parts + 1] = string.format("%s %s", token, tostring(stats[token]))
	end
	return table.concat(parts, ", ")
end

-- The internal state tokens spelled out for someone reading why an item stayed put.
local VERDICT_TEXT = {
	gift = "gift",
	leftover = "kept, nobody to send it to",
	unreadable = "STATS UNREADABLE, held back rather than matched or kept",
}

-- Shared by the bag export and the single-item verdict, so the two cannot disagree.
local function AppendVerdict(lines, item, indent)
	-- The same verdict the window acts on, never a second opinion computed here.
	local verdict = ns.Matcher:VerdictFor(item)
	local eligible = verdict.eligible
	local bandLo, bandHi = ns.Matcher:LevelBand(item)

	-- What the item IS: equipLoc and subclass route it down the weapon matrix or the armor one.
	lines[#lines + 1] = string.format(
		"%skind: %s, equip %s, class %s/%s (%s), ilvl %s, requires %s, quality %s",
		indent,
		tostring(item.kind or "?"),
		tostring(item.equipLoc ~= "" and item.equipLoc or "none"),
		tostring(item.classID),
		tostring(item.subclassID),
		ns.Data.UsesWeaponMatrix(item) and ("weapon matrix: " .. tostring(ns.Data.WeaponKey(item) or "no key"))
			or ("armor: " .. tostring(ns.Data.ARMOR_SUBCLASS[item.subclassID] or "universal, stats alone decide")),
		tostring(item.itemLevel or "?"),
		tostring(item.reqLevel or "?"),
		tostring(item.quality or "?")
	)

	--[[
		All three lines matter separately: the merge takes the max per stat, so GetItemStats
		covering fixed-stat items while the tooltip returns nothing looks like both working.
	]]
	local read = item.statRead or {}
	lines[#lines + 1] = indent .. "stats: " .. FormatStats(item.stats)
	lines[#lines + 1] = indent .. "  GetItemStats: " .. FormatStats(read.api)
	lines[#lines + 1] = indent
		.. "  tooltip: "
		.. FormatStats(read.tooltip)
		.. " (via "
		.. tostring(read.source or "not recorded")
		.. ")"

	-- Without this, an item that reads three stats cleanly and drops a fourth shows nothing amiss.
	if read.unread and #read.unread > 0 then
		lines[#lines + 1] = indent .. "  NOT UNDERSTOOD, these look like stat lines and matched no rule:"
		for _, text in ipairs(read.unread) do
			lines[#lines + 1] = indent .. "    | " .. text
		end
	end

	-- A suffixed item with nothing parsed is a read failure, not a plain item. Say so outright.
	local suffix = ns.ItemSuffixID(item.link)
	if suffix then
		local parsed = next(item.stats or {}) ~= nil
		lines[#lines + 1] = string.format(
			"%srandom suffix %d: %s",
			indent,
			suffix,
			parsed and "stats read" or "NO STATS READ, this item is a parse failure and stays unmatched"
		)
		--[[
			What the client actually rendered, failure case only: an uncovered line and no stat
			line at all both print as an empty list, and only the raw lines tell them apart.
		]]
		if not parsed and read.lines then
			lines[#lines + 1] = indent .. "  tooltip as rendered, since nothing parsed:"
			for _, text in ipairs(read.lines) do
				if text ~= "" then
					lines[#lines + 1] = indent .. "    | " .. text
				end
			end
		end
	end

	if #eligible == 0 then
		lines[#lines + 1] = indent .. "eligible: none, no class can use this"
	else
		--[[
			"use" is the share of the item's scoreable stats this class ranks. Two classes can
			print an identical claim, and only this column says which one takes the item.
		]]
		local parts = {}
		for _, class in ipairs(eligible) do
			--[[
				Floored rather than handed to %d as a fraction: a remainder truncates silently on
				this client's Lua and errors on a stricter one.
			]]
			parts[#parts + 1] = string.format(
				"%s claim %.2f fit %.2f use %d%% g%d",
				class,
				ns.Matcher:SpecScore(item, class),
				ns.Matcher:Score(item, class),
				math.floor(ns.Matcher:Coverage(item, class) * 100),
				ns.Matcher:Priority(item, class)
			)
		end
		table.sort(parts)
		lines[#lines + 1] = indent .. "eligible: " .. table.concat(parts, " | ")
	end

	-- Eligible is who could wear it, admitted is who may receive it: the gap answers "why not sent".
	local admitted = (#verdict.admitted > 0) and table.concat(verdict.admitted, ", ")
		or "nobody, so this item has no possible recipient"
	lines[#lines + 1] = indent .. "admitted: " .. admitted

	lines[#lines + 1] = string.format(
		"%sbest fit: %s score %.2f threshold %.2f -> %s",
		indent,
		tostring(verdict.best or "nobody"),
		verdict.score or 0,
		ns.Data.LEFTOVER_THRESHOLD,
		VERDICT_TEXT[verdict.state] or verdict.state
	)

	--[[
		"best fit" is one class picked on score and group; the recipient is picked on level
		proximity across everyone in contention, and the two disagree constantly.
	]]
	local contenders = verdict.contenders or {}
	if #verdict.admitted > 1 then
		if #contenders == 1 then
			lines[#lines + 1] = string.format("%sin contention: %s alone", indent, contenders[1])
		else
			lines[#lines + 1] = string.format(
				"%sin contention: %s -- level proximity to %d decides between them",
				indent,
				table.concat(contenders, ", "),
				bandHi
			)
		end
	end

	--[[
		Admitted but not in contention, with the reason per class: "uses 50%" lost on breadth, a
		claim figure means it wanted the item less.
	]]
	local inContention = {}
	for _, class in ipairs(contenders) do
		inContention[class] = true
	end
	local demoted = {}
	for _, class in ipairs(verdict.admitted) do
		if not inContention[class] then
			local used = (verdict.coverage or {})[class] or 1
			demoted[#demoted + 1] = (used <= ns.Data.COVERAGE_MAJORITY)
					and string.format("%s (uses %d%% of it)", class, used * 100)
				or string.format("%s (claim %.2f)", class, verdict.claims[class] or 0)
		end
	end
	if #demoted > 0 then
		table.sort(demoted)
		lines[#lines + 1] = indent
			.. "fallback only: "
			.. table.concat(demoted, ", ")
			.. " -- offered when nobody above is in range"
	end

	--[[
		Printed with the two constants that produced it: without them "level band: 18 to 18"
		reads as a fact about the item when it is a fact about the gaps.
	]]
	local low, high = ns.Data.LEVEL_GAP_WIDEST, ns.Data.LEVEL_GAP_CLOSEST
	lines[#lines + 1] = string.format(
		"%slevel band: %d to %d, preferring %d (requires %d, minus gaps of %d and %d)",
		indent,
		bandLo,
		bandHi,
		bandHi,
		item.reqLevel or 1,
		low,
		high
	)
	--[[
		The classes searching somewhere else, and why. A hunter trains mail at 40, so a level 36
		mail belt looks for him at 38 and 39 while the paladin beside him is looked for at 34 and
		35 -- two searches under one band line, and invisible without this.
	]]
	local shifted = {}
	for _, class in ipairs(verdict.admitted) do
		local lo, hi = ns.Matcher:LevelBand(item, class)
		if lo ~= bandLo or hi ~= bandHi then
			shifted[#shifted + 1] = string.format("%s %d to %d", class, lo, hi)
		end
	end
	if #shifted > 0 then
		table.sort(shifted)
		lines[#lines + 1] = string.format(
			"%s  trains the armor later, so it is searched for higher up: %s (reach %d)",
			indent,
			table.concat(shifted, ", "),
			ns.Data.PROFICIENCY_REACH
		)
	end

	-- WIDEST at or below CLOSEST collapses the band to one level, which is drastic and invisible.
	if bandLo == bandHi then
		lines[#lines + 1] = string.format(
			"%s  ONE LEVEL ONLY. LEVEL_GAP_WIDEST (%d) is not above LEVEL_GAP_CLOSEST (%d) in Data/Data.lua, "
				.. "so the band collapsed: this item will only ever match somebody at exactly level %d.",
			indent,
			low,
			high,
			bandHi
		)
	end
end

--------------------------------------------------------------------------------
-- Mailbox
--------------------------------------------------------------------------------

-- Who a mail job is addressed to, or "none" for an empty slot on the Distributor.
local function JobRecipient(job)
	return job and tostring(job.recipient) or "none"
end

--[[
	Answers "the window never opened" and "Distribute did nothing": whether the add-on believes
	the mailbox is open, whether it believes there is anything to give, and where a mail run
	stands. Reads only. Nothing here scans, refreshes or touches the Distributor, so running it
	cannot change the answer it reports.
]]
function ns:BuildMailboxReport()
	local lines = { GetClientHeader(), "" }

	--[[
		ns.AtMailbox asks the interaction manager where the client has one and falls back to the
		flag the mailbox events keep; printing both, and which one answered, shows a stale flag.
	]]
	local manager = C_PlayerInteractionManager
	local managerAnswers = type(manager) == "table"
		and type(manager.IsInteractingWithNpcOfType) == "function"
		and type(Enum) == "table"
		and type(Enum.PlayerInteractionType) == "table"
		and Enum.PlayerInteractionType.MailInfo ~= nil
	lines[#lines + 1] = "mailbox open flag = " .. tostring(ns.mailboxOpen == true)
	lines[#lines + 1] = "at mailbox = " .. tostring(ns.AtMailbox())
	lines[#lines + 1] = "answered by = "
		.. (managerAnswers and "the interaction manager" or "the mailbox open flag (no interaction manager)")
	lines[#lines + 1] = "MailFrame exists = " .. tostring(MailFrame ~= nil)
	lines[#lines + 1] = "MailFrame hooks installed at login = " .. tostring((ns.UI and ns.UI.mailFrameHooked) == true)
	lines[#lines + 1] = "SendMailFrame exists = " .. tostring(SendMailFrame ~= nil)
	lines[#lines + 1] = "SendMailFrame shown = " .. tostring(SendMailFrame ~= nil and SendMailFrame:IsShown() == true)
	lines[#lines + 1] = ""

	local frame = ns.UI and ns.UI.frame
	lines[#lines + 1] = "window built = " .. tostring(frame ~= nil)
	lines[#lines + 1] = "window shown = " .. tostring(frame ~= nil and frame:IsShown() == true)
	-- The question the mailbox itself asks before opening the window, against the list as it stands.
	lines[#lines + 1] = "window would open at a mailbox now = " .. tostring(ns.UI:HasSomethingToDo())
	lines[#lines + 1] = ""

	local byState, holding, ticked = {}, 0, 0
	local items = ns.MatchList:Items()
	for _, item in ipairs(items) do
		local state = item.state or "unscored"
		byState[state] = (byState[state] or 0) + 1
		if item.recipient then
			holding = holding + 1
		end
		if item.send and item.recipient then
			ticked = ticked + 1
		end
	end
	lines[#lines + 1] = string.format(
		"items listed = %d (gift %d, leftover %d, unreadable %d)",
		#items,
		byState[ns.Matcher.GIFT] or 0,
		byState[ns.Matcher.LEFTOVER] or 0,
		byState[ns.Matcher.UNREADABLE] or 0
	)
	lines[#lines + 1] = "items holding a recipient = " .. holding
	lines[#lines + 1] = "items ticked to send = " .. ticked
	lines[#lines + 1] = "list is stale, rescans at the next mailbox = " .. tostring(ns.MatchList:IsStale() == true)
	lines[#lines + 1] = ""

	local mailer = ns.Distributor
	lines[#lines + 1] = "mail run busy = " .. tostring(mailer.busy == true)
	lines[#lines + 1] = "mail run queue = " .. #mailer.queue
	lines[#lines + 1] = "mail run errors in a row = " .. tostring(mailer.errors)
	lines[#lines + 1] = "sending to = " .. JobRecipient(mailer.busy and mailer._current or nil)
	lines[#lines + 1] = "awaiting a late result for = " .. JobRecipient(mailer._awaiting)
	lines[#lines + 1] = "settling a refusal for = " .. JobRecipient(mailer._settling)
	lines[#lines + 1] =
		string.format("money = %d copper, postage per mail = %d copper", GetMoney() or 0, mailer.MAIL_COST)
	lines[#lines + 1] = ""

	--[[
		The settings Bag Scan's rejection codes are decided against, so a pasted Bag Scan reads
		with them beside it: GEAR_DISABLED, KIND_DISABLED, ABOVE_MAX_RARITY and LEVEL_GAP mean
		nothing alone.
	]]
	local profile = ns.db and ns.db.profile or {}
	local kindsOn = {}
	for _, kind in ipairs(ns.CONSUMABLE_KIND_ORDER) do
		if profile.consumableKinds and profile.consumableKinds[kind] then
			kindsOn[#kindsOn + 1] = kind
		end
	end
	lines[#lines + 1] = string.format(
		"settings: includeGear=%s includeConsumables=%s consumableKinds=%s maxRarity=%s (%s) consumableLevelGap=%s MIN_RARITY=%s playerLevel=%s",
		tostring(profile.includeGear),
		tostring(profile.includeConsumables),
		(#kindsOn > 0) and table.concat(kindsOn, ",") or "none",
		tostring(profile.maxRarity),
		profile.maxRarity and ns.QualityName(profile.maxRarity) or "?",
		tostring(profile.consumableLevelGap),
		tostring(ns.Data.MIN_RARITY),
		tostring(UnitLevel("player"))
	)
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Bag Scan Export
--------------------------------------------------------------------------------

--[[
	The rejected rows are the point: "why is this green not in the list" is answered here and
	nowhere else. Re-runs the same Scanner:Classify the window uses, so the two cannot disagree.
]]
function ns:BuildBagScanReport()
	local lines = { GetClientHeader(), "" }
	local rows = ns.Scanner:ScanAll()

	if #rows == 0 then
		lines[#lines + 1] = "(no items in bags)"
		return table.concat(lines, "\n")
	end

	--[[
		Accepted is not giftable: passing the hard filter only means the slot holds a tradeable
		green. Whether anyone wants it is the verdict, counted separately below.
	]]
	local accepted, byState, byReason = 0, {}, {}
	for _, row in ipairs(rows) do
		local name, _, quality, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID, bindType =
			C_Item.GetItemInfo(row.link)
		lines[#lines + 1] = string.format(
			"bag %d slot %d | %s | id %s | quality %s | req %s | %s | class %s/%s | bind %s",
			row.bag,
			row.slot,
			tostring(name or "uncached"),
			tostring(ns.GetInfoInstant(row.link)),
			tostring(quality),
			tostring(reqLevel),
			tostring(equipLoc ~= "" and equipLoc or "(none)"),
			tostring(classID),
			tostring(subclassID),
			tostring(bindType)
		)
		lines[#lines + 1] = "    link: " .. EscapePipes(row.link)

		if row.item then
			accepted = accepted + 1
			local state = ns.Matcher:VerdictFor(row.item).state
			byState[state] = (byState[state] or 0) + 1
			lines[#lines + 1] = "    ACCEPTED as " .. tostring(row.item.kind)
			if row.item.kind == "gear" then
				AppendVerdict(lines, row.item, "    ")
			else
				local lo, hi = ns.Matcher:LevelBand(row.item)
				lines[#lines + 1] =
					string.format("    consumable, recipient levels %s to %s", tostring(lo), tostring(hi))
			end
		else
			byReason[row.reason] = (byReason[row.reason] or 0) + 1
			lines[#lines + 1] = "    REJECTED: " .. tostring(row.reason)
		end
		lines[#lines + 1] = ""
	end

	-- ScanAll leaves empty slots out, so this counts occupied slots, never bag size.
	lines[#lines + 1] =
		string.format("%d occupied slot(s), %d accepted, %d rejected.", #rows, accepted, #rows - accepted)
	lines[#lines + 1] = string.format(
		"Of the %d accepted: %d to gift, %d kept (nobody to send to), %d with unreadable stats.",
		accepted,
		byState[ns.Matcher.GIFT] or 0,
		byState[ns.Matcher.LEFTOVER] or 0,
		byState[ns.Matcher.UNREADABLE] or 0
	)
	local reasons = {}
	for reason, count in pairs(byReason) do
		reasons[#reasons + 1] = string.format("%s x%d", reason, count)
	end
	table.sort(reasons)
	if #reasons > 0 then
		lines[#lines + 1] = "Rejections: " .. table.concat(reasons, ", ")
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Recipient Roster Export
--------------------------------------------------------------------------------

--[[
	Everyone the /who stepper has found, with fairness state and what the parser discarded: a thin
	roster is usually unresolvable class tokens, not an empty realm.
]]
function ns:BuildRosterReport()
	local lines = { GetClientHeader(), "" }
	local pools = (ns.UI and ns.UI.Pools and ns.UI:Pools()) or {}
	local items = (ns.UI and ns.UI.Items and ns.UI:Items()) or {}

	--[[
		Labeled by slot, not name alone: two copies of one green share a name, so "Ivycloth
		Robe, Ivycloth Robe" cannot say whether that is two items or a repeated line.
	]]
	local candidateFor = {}
	for _, item in ipairs(items) do
		if item.eligible then
			local label =
				string.format("%s (bag %s slot %s)", item.name or item.link, tostring(item.bag), tostring(item.slot))
			for _, person in ipairs(ns.Matcher:RankCandidates(item, pools)) do
				candidateFor[person.name] = candidateFor[person.name] or {}
				table.insert(candidateFor[person.name], label)
			end
		end
	end

	local classes, total = {}, 0
	for class, list in pairs(pools) do
		classes[#classes + 1] = class
		total = total + #list
	end
	table.sort(classes)

	lines[#lines + 1] = string.format("%d player(s) known across %d class(es).", total, #classes)
	for _, class in ipairs(classes) do
		lines[#lines + 1] = string.format("  %s: %d", class, #pools[class])
	end
	lines[#lines + 1] = ""

	local stats = ns.Who:ResultStats()
	lines[#lines + 1] = string.format(
		"Who results seen %d, kept %d, of which %d from a connected realm. Dropped %d for an unreadable class.",
		stats.seen,
		stats.seen - stats.unknownClass,
		stats.connectedRealm,
		stats.unknownClass
	)
	-- Conditional like the cap row below: only Forever answers /who with the other faction.
	if stats.otherFaction > 0 then
		lines[#lines + 1] =
			string.format("Dropped %d from the other faction, who cannot be mailed.", stats.otherFaction)
	end
	-- Only once an answer has been truncated: a permanent "capped 0" row trains the eye to skip it.
	if stats.capped > 0 then
		lines[#lines + 1] = string.format(
			"%d quer(ies) came back full at the %d-result cap, so the server had more to send. "
				.. "Chased only by the class and zone queries already planned, never by splitting.",
			stats.capped,
			ns.Who.RESULT_CAP
		)
	end
	local searchLine = string.format(
		"Search: %d place(s) left to look of %d, next %s.",
		ns.Who:Remaining(),
		ns.Who:Planned(),
		tostring(ns.Who:Peek() or "none")
	)
	--[[
		Only once something has been pruned, for the same reason the cap row above is conditional.
		Without it the two numbers do not reconcile: places-left drops without a press whenever an
		assignment finishes off a band, which otherwise reads as queries going missing.
	]]
	if stats.pruned > 0 then
		searchLine = searchLine
			.. string.format(" %d dropped once nothing in their band was still searching.", stats.pruned)
	end
	if stats.exhausted > 0 then
		searchLine = searchLine
			.. string.format(" %d skipped, already answered by a query that came back under the cap.", stats.exhausted)
	end
	lines[#lines + 1] = searchLine

	--[[
		Why a press of Find Recipients did nothing visible. A query still out, the throttle, a
		press the client refused and a query that never answered all look like "nobody found".
		Printed every time: here a zero is the answer, not noise.
	]]
	local label, canceled, age = ns.Who:InFlight()
	if label then
		lines[#lines + 1] = string.format(
			"  In flight: %s, sent %.1fs ago%s.",
			tostring(label),
			age,
			canceled and ", canceled, its answer will only be tidied up" or ""
		)
	else
		lines[#lines + 1] = "  In flight: none."
	end
	lines[#lines + 1] = string.format("  Throttle: %.1fs before the next query can go out.", ns.Who:ThrottleLeft())
	lines[#lines + 1] = string.format(
		"  Timed out: %d, put back on the plan. Blocked: %d, SendWho refused because the press did not count as a click.",
		stats.timedOut,
		stats.blocked
	)
	local quieted = ns.Who:QuietedFrames()
	lines[#lines + 1] = string.format(
		"  Who panel frames quieted: %d%s",
		quieted,
		(quieted > 0 and not label) and ", with nothing in flight: the player's own /who is broken until a reload."
			or "."
	)
	if #ns.Who.plan > 0 then
		lines[#lines + 1] = "  Still planned, in order:"
		for index, attempt in ipairs(ns.Who.plan) do
			lines[#lines + 1] = string.format("    %d. %s", index, tostring(attempt.label))
		end
	end

	--[[
		"The guild added nobody" and "the guild has nobody active" look identical from the match
		list, and only one of them is a bug worth chasing. Not being in a guild, and a request the
		server never answered, are printed first for the same reason.
	]]
	local guild = ns.Guild:Stats()
	lines[#lines + 1] = string.format(
		"Guild: in a guild %s, roster request waiting %s.",
		tostring(IsInGuild and IsInGuild() and true or false),
		tostring(ns.Guild:Pending())
	)
	if guild.rows > 0 then
		-- Reads the window off ns.Guild rather than naming it here, which would drift the day it changes.
		lines[#lines + 1] = string.format("  %d of %d eligible, %d online.", guild.eligible, guild.rows, guild.online)
		lines[#lines + 1] = string.format(
			"  Dropped: %d not on in %d day(s), %d summoning alts, %d of your own characters, %d unreadable.",
			guild.stale,
			ns.Guild.ACTIVE_DAYS,
			guild.summonAlts,
			guild.ownAlts,
			guild.unreadable
		)
	end

	--[[
		Reported once for both sources because it is enforced once for both, and only when it has
		actually turned somebody away, on the same reasoning as the cap row above.
	]]
	local tooLow = ns.MatchList:TooLowCount()
	if tooLow > 0 then
		lines[#lines + 1] = string.format(
			"Level floor: %d candidate(s) turned away below level %d, from every source.",
			tooLow,
			ns.Data.MIN_RECIPIENT_LEVEL
		)
	end
	lines[#lines + 1] = ""

	if total == 0 then
		lines[#lines + 1] = "(no players found yet, press Find Recipients)"
		return table.concat(lines, "\n")
	end

	for _, class in ipairs(classes) do
		for _, person in ipairs(pools[class]) do
			local fresh = ns.Fairness:IsFresh(person.name, person.level)
			local wanted = candidateFor[person.name]
			--[[
				Unreachable outranks fresh: the server refused a mail to this name, so
				Fairness:PickFrom never picks them however fresh they are.
			]]
			local standing = (not ns.Fairness:IsReachable(person.name)) and "unreachable"
				or (fresh and "fresh" or "on cooldown")
			lines[#lines + 1] = string.format(
				"%s | level %s | %s | %s | %s | candidate for: %s",
				tostring(person.name),
				tostring(person.level),
				tostring(person.class),
				tostring(person.area or "?"),
				standing,
				wanted and EscapePipes(table.concat(wanted, ", ")) or "nothing"
			)
		end
	end

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Item Verdict
--------------------------------------------------------------------------------

-- One pasted link, both stat sources side by side so a parse failure is visible as one.
function ns:BuildItemVerdictReport(link)
	local lines = { GetClientHeader(), "" }
	if not link or link == "" then
		lines[#lines + 1] = "Paste an item link into the box above first."
		return table.concat(lines, "\n")
	end

	--[[
		A bare item id is a common paste, and the APIs behind Describe want a link form:
		handed the digits, GetItemStats and SetHyperlink return nothing and the report reads
		as a broken scanner rather than a malformed input.
	]]
	local id = link:match("^%s*(%d+)%s*$")
	if id then
		link = "item:" .. id
	end

	local item = ns.Scanner:Describe(link)
	if not item then
		lines[#lines + 1] = "Could not read that item. Paste a real item link."
		return table.concat(lines, "\n")
	end

	lines[#lines + 1] = "item: " .. EscapePipes(item.link)

	if not ns.Tooltip.equipPatternsUsable then
		lines[#lines + 1] = string.format(
			'NOTE: equip-effect parsing is English-only and this client is %s, so any stat written as an "Equip: ..." line is not counted above.',
			GetLocale()
		)
	end
	AppendVerdict(lines, item, "")
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Class Groups
--------------------------------------------------------------------------------

--[[
	Both reports print only classes that can exist for this player, the same list the matcher
	routes on: the full ten would make a phantom class look like a real routing decision.
]]
local function AvailableClasses()
	local set = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		set[class] = true
	end
	return set
end

local function GroupedByTier(byClass, maxTier, available)
	local byTier = {}
	for class, tier in pairs(byClass) do
		if not available or available[class] then
			byTier[tier] = byTier[tier] or {}
			table.insert(byTier[tier], class)
		end
	end
	local parts = {}
	for tier = 1, maxTier do
		if byTier[tier] then
			table.sort(byTier[tier])
			parts[#parts + 1] = table.concat(byTier[tier], ", ")
		end
	end
	return #parts > 0 and table.concat(parts, " / ") or "(nobody)"
end

-- Names the resolved class list, so a wrong flavor or faction gate is visible at a glance.
local function AppendClassLine(lines)
	local classes = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		classes[#classes + 1] = class
	end
	table.sort(classes)
	lines[#lines + 1] = string.format(
		"Classes on this client and faction (%s): %s",
		tostring(UnitFactionGroup("player") or "unknown"),
		table.concat(classes, ", ")
	)
	lines[#lines + 1] = ""
end

local function AppendArmorGroups(lines, level)
	local available = AvailableClasses()
	lines[#lines + 1] = string.format("Armor groups for an item requiring level %d:", level)
	for _, armorType in ipairs({ "CLOTH", "LEATHER", "MAIL", "PLATE" }) do
		lines[#lines + 1] = string.format(
			"  %-8s %s",
			armorType:lower(),
			GroupedByTier(ns.Data.ArmorPriorityFor(armorType, level) or {}, 9, available)
		)
	end
end

local WEAPON_ORDER = {
	"1H_SWORD",
	"2H_SWORD",
	"1H_MACE",
	"2H_MACE",
	"1H_AXE",
	"2H_AXE",
	"DAGGER",
	"FIST",
	"POLEARM",
	"STAFF",
	"BOW",
	"GUN",
	"CROSSBOW",
	"THROWN",
	"WAND",
	"SHIELD",
	"HELD",
	"LIBRAM",
	"IDOL",
	"TOTEM",
}

local function AppendWeaponGroups(lines, level)
	lines[#lines + 1] =
		string.format("Weapon priority for an item requiring level %d (group 1 = every spec wants it):", level)
	for _, weaponKey in ipairs(WEAPON_ORDER) do
		local byClass = {}
		for _, class in ipairs(ns.Matcher:Classes()) do
			local group = ns.Data.WeaponPriorityFor(weaponKey, class, level)
			if group then
				byClass[class] = group
			end
		end
		lines[#lines + 1] = string.format("  %-9s %s", weaponKey:lower(), GroupedByTier(byClass, 3))
	end
end

-- Both matrices for an item requiring this level, or the player's own when none was entered.
function ns:BuildClassGroupsReport(level)
	level = tonumber(level) or UnitLevel("player") or 60
	local lines = { GetClientHeader(), "" }
	AppendClassLine(lines)
	AppendArmorGroups(lines, level)
	lines[#lines + 1] = ""
	AppendWeaponGroups(lines, level)
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Outgoing Mail Preview
--------------------------------------------------------------------------------

function ns:BuildMailPreviewReport()
	local lines = { GetClientHeader(), "" }
	local subject = ns.Distributor:BuildSubject()
	local body = ns.Distributor:BuildBody()

	lines[#lines + 1] = string.format("subject (%d/%d): %s", #subject, ns.Distributor.SUBJECT_MAX, subject)
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("body (%d/%d):", #body, ns.Distributor.BODY_MAX)
	if body == "" then
		lines[#lines + 1] = "  (empty)"
	else
		for line in (body .. "\n"):gmatch("([^\n]*)\n") do
			lines[#lines + 1] = "  " .. line
		end
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Given Away Sharing
--------------------------------------------------------------------------------

--[[
	Answers "why don't I see anyone": are we sharing, did the prefix register, what are our own
	totals, which tooltip hook drew the block, where the send throttles stand, and who nearby have
	we heard from and how long ago. Inline literals like every other
	builder; the panel labels live in ns.DiagnosticsStrings.
]]
function ns:BuildGenerosityReport()
	local lines = { GetClientHeader(), "" }

	local sharing = (ns.db and ns.db.profile.shareStats) and true or false
	lines[#lines + 1] = "shareStats = " .. tostring(sharing)
	--[[
		Usually the answer. Sharing is town-only, so a player asking why nobody shows up is most often
		standing somewhere they are not resting; printed second, right under the setting itself.
	]]
	lines[#lines + 1] = "resting (in a city or inn, required to send) = " .. tostring(ns.AtRest())
	lines[#lines + 1] = string.format(
		"prefix %q registered = %s",
		ns.ADDON_MESSAGE_PREFIX,
		tostring((ns.Generosity and ns.Generosity.prefixRegistered) or false)
	)

	local gifts, items, itemLevels, value = ns.Generosity:Get()
	lines[#lines + 1] =
		string.format("my totals: gifts=%d items=%d itemLevels=%d value=%d", gifts, items, itemLevels, value)
	lines[#lines + 1] = ""

	--[[
		Which unit-tooltip hook this client took, and whether the secret-identity check it runs
		first exists here. Either missing means no block on anybody's tooltip.
	]]
	lines[#lines + 1] = "tooltip hook = " .. tostring(ns.Generosity.tooltipHook or "none installed")
	lines[#lines + 1] = "C_Secrets.ShouldUnitIdentityBeSecret present = "
		.. tostring(type(C_Secrets) == "table" and type(C_Secrets.ShouldUnitIdentityBeSecret) == "function")

	--[[
		The throttles, as they stand. A broadcast refused by the interval and one never sent look the
		same from outside; so do a peer who never answered and one we were too recently pinged by.
	]]
	local now = GetTime()
	local function Since(stamp)
		return (stamp or 0) > 0 and string.format("%ds ago", math.floor(now - stamp)) or "never"
	end
	local lastBroadcast, lastPingAnswer = ns.Generosity:LastSends()
	lines[#lines + 1] = "last broadcast = " .. Since(lastBroadcast)
	lines[#lines + 1] = string.format(
		"next broadcast allowed in = %ds",
		math.max(0, math.ceil(ns.Generosity.BROADCAST_MIN_INTERVAL - (now - lastBroadcast)))
	)
	lines[#lines + 1] = "last ping answered = " .. Since(lastPingAnswer)
	lines[#lines + 1] = "last hover ping sent = " .. Since(ns.Generosity:LastHoverPing())
	lines[#lines + 1] = ""

	local peers = ns.Generosity:AllPeers()
	local names = {}
	for key in pairs(peers) do
		names[#names + 1] = key
	end
	table.sort(names)
	if #names == 0 then
		lines[#lines + 1] = "no nearby players heard from yet"
	else
		lines[#lines + 1] = string.format("%d nearby player(s) heard from:", #names)
		for _, key in ipairs(names) do
			local peer = peers[key]
			local age = math.floor(now - (peer.t or now))
			lines[#lines + 1] = string.format(
				"  %s: gifts=%d items=%d itemLevels=%d value=%d (%ds ago%s)",
				key,
				peer.gifts,
				peer.items,
				peer.itemLevels,
				peer.value,
				age,
				age > ns.Generosity.PEER_MAX_AGE and ", expired, the tooltip treats them as unheard" or ""
			)
		end
	end
	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Game Names
--------------------------------------------------------------------------------

--[[
	Every game name the add-on matches against what the client shows, each read through the same
	call its feature makes, so a NIL here is a name that feature cannot match on this client.
	Each entry's ids expand at run time from the add-on's own data, so a stat, class or zone added
	there gets its row without an edit here, and the faction-gated class list is read when it is
	known rather than at load. The add-on names no items by ID, so nothing here waits on a load.
]]
local function SortedKeys(map)
	local keys = {}
	for key in pairs(map or {}) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function SortedClasses()
	local classes = {}
	for _, class in ipairs(ns.Matcher:Classes()) do
		classes[#classes + 1] = class
	end
	table.sort(classes)
	return classes
end

local function GlobalString(name)
	return _G[name]
end

ns.DIAGNOSTIC_NAME_LOOKUPS = {
	-- { constant, kind, ids, lookup }
	-- The stat names Features/Scan-Tooltip.lua reads a "+9 Intellect" line by.
	{
		constant = "ns.Data.STAT_MAP",
		kind = "Blizzard UI label",
		ids = function()
			return SortedKeys(ns.Data.STAT_MAP)
		end,
		lookup = GlobalString,
	},
	-- The refusal Features/Mail-Sender.lua recognizes when a send crosses factions.
	{
		constant = "ERR_PLAYER_WRONG_FACTION",
		kind = "Blizzard UI label",
		ids = function()
			return { "ERR_PLAYER_WRONG_FACTION" }
		end,
		lookup = GlobalString,
	},
	--[[
		The name a /who class filter goes out with. The planner falls back to the token itself,
		which /who cannot match, so a fallback counts as NIL here.
	]]
	{
		constant = "LOCALIZED_CLASS_NAMES_MALE",
		kind = "class",
		ids = SortedClasses,
		lookup = function(token)
			local name = ns.Who.ClassName(token)
			return name ~= token and name or nil
		end,
	},
	-- The other half of reading a /who result's class back to its token.
	{
		constant = "LOCALIZED_CLASS_NAMES_FEMALE",
		kind = "class",
		ids = SortedClasses,
		lookup = function(token)
			return LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]
		end,
	},
	-- The zone names the /who search sends; an unnamed zone is never searched.
	{
		constant = "ns.Data.ZONES",
		kind = "zone (AreaTable)",
		ids = function()
			local ids = {}
			for _, zone in ipairs(ns.Data.ZONES or {}) do
				ids[#ids + 1] = zone[ns.Data.ZONE_COLUMNS.AREA_ID]
			end
			return ids
		end,
		lookup = ns.Who.AreaName,
	},
}

--------------------------------------------------------------------------------
-- Validate Data Sources
--------------------------------------------------------------------------------

--[[
	One entry per flavor-folder file, and one report row per entry on the Data tab. The label is the table-name part of the file name, so
	ns.DataSourceFileName names the file this client's folder built. Food, potions and scrolls
	are positional rows, { itemId, quality, useLevel, restores or buffs }, so the id is the first
	field. Recipients-Zones rows are { areaId, min level, max level, faction }, checked by the
	name C_Map.GetAreaInfo gives each one, since that name is what the /who zone filter sends.

	Match-Stat-Budget, Match-Weapons, Match-Armor and Match-Classes are keyed by tokens and
	subclass numbers no client API looks up, so they are "other" rows: each table's row count,
	and TABLE MISSING when this client's folder never built it.
]]
local function FirstField(_, row)
	return type(row) == "table" and row[1] or nil
end

local function RowField(position)
	return function(_, row)
		return type(row) == "table" and row[position] or nil
	end
end

local CONSUMABLE_COLUMNS = {
	{ "DATA_QUALITY", RowField(2) },
	{ "DATA_USE_LEVEL", RowField(3) },
	{ "DATA_RESTORES", RowField(4) },
}

local SCROLL_COLUMNS = {
	{ "DATA_QUALITY", RowField(2) },
	{ "DATA_USE_LEVEL", RowField(3) },
	{ "DATA_BUFFS", RowField(4) },
}

-- A zone with no faction is searched by both, so its cell says so rather than printing blank.
local ZONE_COLUMNS = {
	{ "DATA_MIN_LEVEL", RowField(2) },
	{ "DATA_MAX_LEVEL", RowField(3) },
	{
		"DATA_FACTION",
		function(_, row)
			return type(row) == "table" and (row[4] or "Both") or nil
		end,
	},
}

ns.DIAGNOSTIC_DATA_SOURCES = {
	-- { label, sources = { { table, kind, rowId or collect, dataColumns } } }
	{
		label = "Scan-Food",
		sources = {
			{ table = "FOOD_AND_WATER", kind = "item", rowId = FirstField, dataColumns = CONSUMABLE_COLUMNS },
		},
	},
	{
		label = "Scan-Potions",
		sources = {
			{ table = "POTIONS", kind = "item", rowId = FirstField, dataColumns = CONSUMABLE_COLUMNS },
		},
	},
	{
		label = "Scan-Scrolls",
		sources = {
			{ table = "SCROLLS", kind = "item", rowId = FirstField, dataColumns = SCROLL_COLUMNS },
		},
	},
	{
		label = "Recipients-Zones",
		sources = {
			{ table = "ZONES", kind = "area", rowId = FirstField, dataColumns = ZONE_COLUMNS },
		},
	},
	{
		label = "Match-Stat-Budget",
		sources = {
			{ table = "STAT_BUDGET", kind = "other" },
		},
	},
	{
		label = "Match-Weapons",
		sources = {
			{ table = "WEAPON_SUBCLASS", kind = "other" },
			{ table = "RELIC_SUBCLASS", kind = "other" },
			{ table = "WEAPON_CLASS_ORDER", kind = "other" },
			{ table = "WEAPON_SPECS", kind = "other" },
		},
	},
	{
		label = "Match-Armor",
		sources = {
			{ table = "ARMOR_SUBCLASS", kind = "other" },
			{ table = "NATIVE_ARMOR", kind = "other" },
		},
	},
	{
		label = "Match-Classes",
		sources = {
			{ table = "FACTION_CLASSES", kind = "other" },
		},
	},
}
