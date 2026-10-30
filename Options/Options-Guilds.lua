local _, ns = ...
local L = ns.L

local Help = ns.OptionsHelp

--------------------------------------------------------------------------------
-- My Guilds Panel
--------------------------------------------------------------------------------

--[[
	Every guild your characters are in, nested under Recipients. childGroups = "tree" splits the
	panel in two, Magic Eraser's list layout: the guilds down the left, the one picked on the right
	with a tick to include it, how fresh its roster is, and its active members, each with an Include
	tick to untick for a guild bank or anybody else who should not get mail. No Delete: a guild is saved
	again the next time one of your characters in it logs in, so unticking it is the lasting
	choice. The choices live on the saved entries themselves (ns.db.global.guilds), account-wide.

	REGISTERED AS A BUILDER FUNCTION, so the rows are read again each time the panel is drawn: a
	guild being saved adds a row without a reload.
]]

local DAY = 24 * 60 * 60
local MEMBER_LABEL_WIDTH = 1.8
local MEMBER_INCLUDE_WIDTH = ns.OPTIONS_TREE_ROW_WIDTH - MEMBER_LABEL_WIDTH

-- A change to who is offered what re-reads the bags, and redraws this panel.
local function Changed()
	ns.RefreshMailWindow()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(ns.OPTIONS_REGISTRY.Guilds)
end

local function SavedWhen(scanned)
	local days = math.floor((time() - (scanned or 0)) / DAY)
	if days <= 0 then
		return L["OPTIONS_GUILD_SAVED_TODAY"]
	end
	if days == 1 then
		return L["OPTIONS_GUILD_SAVED_YESTERDAY"]
	end
	return L["OPTIONS_GUILD_SAVED_DAYS"]:format(days)
end

local SKIPPED = {
	realm = "OPTIONS_GUILD_SKIPPED_REALM",
	faction = "OPTIONS_GUILD_SKIPPED_FACTION",
}

local function GuildStatus(key, guild)
	local text =
		L["OPTIONS_GUILD_STATUS"]:format(ns.Guild:ActiveCount(guild), SavedWhen(guild.scanned), guild.scannedBy or "?")
	if key == ns.Guild:CurrentKey() then
		return text .. " " .. L["OPTIONS_GUILD_CURRENT"]
	end
	local _, why = ns.Guild:Usable(guild)
	if SKIPPED[why] then
		text = text .. " " .. L[SKIPPED[why]]
	end
	return text
end

-- "<Name>", and the realm after it when the guild is not on this one.
local function GuildLabel(guild)
	local label = "<" .. (guild.name or "?") .. ">"
	if guild.realm ~= ns.PlayerRealm() then
		label = label .. " " .. Help(guild.realm or "")
	end
	return label
end

--[[
	"Name - Realm", as the My Alts tree writes a character. The realm is the roster's own suffix
	where it differs from the guild's realm (a connected one), else the guild's realm as the client
	names it, spaces and all, rather than the suffix's squashed form.
]]
local function MemberName(guild, member)
	local name, suffix = (member.name or "?"):match("^([^%-]+)%-?(.*)$")
	local realm = guild.realm or ""
	if suffix and suffix ~= "" and suffix ~= ns.NormalizeRealm(realm) then
		realm = suffix
	end
	return (name or "?") .. " - " .. realm
end

local function MemberRow(guild, member, order, Off)
	return {
		type = "group",
		name = "",
		inline = true,
		order = order,
		args = {
			label = {
				type = "description",
				name = ns.OptionsClassIcon(member.class)
					.. ns.ColorName(MemberName(guild, member), member.class)
					.. " "
					.. Help("(" .. (member.level or "?") .. ")"),
				fontSize = "medium",
				width = MEMBER_LABEL_WIDTH,
				order = 1,
			},
			-- Ticked unless ignored: the stored set is the ignores, so a new member starts included.
			include = {
				type = "toggle",
				name = L["OPTIONS_GUILD_MEMBER_INCLUDE"],
				desc = L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"],
				width = MEMBER_INCLUDE_WIDTH,
				order = 2,
				disabled = Off,
				get = function()
					return not ns.Guild:Ignored(guild, member.name)
				end,
				set = function(_, value)
					ns.Guild:SetIgnored(guild, member.name, not value)
					Changed()
				end,
			},
		},
	}
end

local function GuildPane(key, guild)
	local function Off()
		return not ns.Guild:Included(guild)
	end
	local args = {
		title = { type = "description", name = GuildLabel(guild), fontSize = "large", order = 1 },
		spacerTitle = ns.OptionsSpacer(2),
		include = {
			type = "toggle",
			name = L["OPTIONS_GUILD_INCLUDE"],
			desc = L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"],
			width = "full",
			order = 3,
			get = function()
				return ns.Guild:Included(guild)
			end,
			set = function(_, value)
				if value then
					guild.include = nil
				else
					guild.include = false
				end
				Changed()
			end,
		},
		status = { type = "description", name = Help(GuildStatus(key, guild)), fontSize = "medium", order = 4 },
		spacerMembers = ns.OptionsSpacer(5),
		membersLabel = {
			type = "description",
			name = ns.GetColor("TITLE") .. L["OPTIONS_GUILD_MEMBERS"] .. "|r",
			fontSize = "medium",
			order = 6,
		},
		spacerMemberRows = ns.OptionsSpacer(8),
	}
	local members = ns.Guild:ListedMembers(guild)
	if #members == 0 then
		args.membersEmpty =
			{ type = "description", name = L["OPTIONS_GUILD_MEMBERS_EMPTY"], fontSize = "medium", order = 9 }
	end
	for index, member in ipairs(members) do
		args["member" .. index] = MemberRow(guild, member, 10 + index, Off)
	end
	return args
end

local function SortedGuilds()
	local out = {}
	for key, guild in pairs(ns.db.global.guilds) do
		out[#out + 1] = { key = key, guild = guild }
	end
	table.sort(out, function(a, b)
		return (a.guild.name or "") < (b.guild.name or "")
	end)
	return out
end

--------------------------------------------------------------------------------
-- The Panel
--------------------------------------------------------------------------------

function ns.BuildGuildsOptions()
	local args = {
		intro = ns.OptionsDesc(L["OPTIONS_GUILDS_INTRO"], 1),
		spacerIntro = ns.OptionsSpacer(2),
		guildOfflineLabel = ns.OptionsRowLabel(L["OPTIONS_GUILD_OFFLINE"], 3),
		guildOffline = {
			type = "select",
			name = "",
			desc = L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"],
			width = ns.OPTIONS_CONTROL_WIDTH,
			order = 4,
			values = function()
				local out = {}
				for _, key in ipairs(ns.GUILD_OFFLINE_ORDER) do
					out[key] = L["OPTIONS_GUILD_OFFLINE_" .. key]
				end
				return out
			end,
			sorting = ns.GUILD_OFFLINE_ORDER,
			get = function()
				return ns.db and ns.db.profile.guildOfflineLimit
			end,
			set = function(_, value)
				ns.db.profile.guildOfflineLimit = value
				Changed()
			end,
		},
		spacerTree = ns.OptionsSpacer(5),
	}
	local panel = { type = "group", name = L["TAB_GUILDS"], childGroups = "tree", args = args }
	if not ns.db then
		return panel
	end

	local guilds = SortedGuilds()
	if #guilds == 0 then
		args.guildsEmpty = ns.OptionsDesc(L["OPTIONS_GUILDS_EMPTY"], 6)
	end
	-- Keyed by the guild's saved key, so the selected node holds when a guild is added.
	for index, row in ipairs(guilds) do
		args[row.key] = {
			type = "group",
			name = GuildLabel(row.guild),
			order = 10 + index,
			args = GuildPane(row.key, row.guild),
		}
	end
	return panel
end
