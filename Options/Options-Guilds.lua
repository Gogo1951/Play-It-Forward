local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

local function Help(text)
	return Kit.Color("HELP", text)
end

--------------------------------------------------------------------------------
-- My Guilds Panel
--------------------------------------------------------------------------------

local DAY = 24 * 60 * 60
local REMOVE_ICON = "Interface/Buttons/UI-GroupLoot-Pass-Up"
local MEMBER_LABEL_WIDTH = 1.8
local MEMBER_INCLUDE_WIDTH = Kit.TREE_ROW_WIDTH - MEMBER_LABEL_WIDTH

-- RecheckGuildmates first: the pool reads guild state only when a player enters it.
local function Changed()
	ns.MatchList:RecheckGuildmates()
	ns.RefreshMailWindow()
	ns.RefreshSettings()
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
	local _, why = ns.Guild:Usable(guild)
	if ns.Guild:ByNameOnly(guild) then
		if SKIPPED[why] then
			return L["OPTIONS_GUILD_ADDED"] .. " " .. L[SKIPPED[why]]
		end
		return L["OPTIONS_GUILD_ADDED"]
	end
	local text =
		L["OPTIONS_GUILD_STATUS"]:format(ns.Guild:ActiveCount(guild), SavedWhen(guild.scanned), guild.scannedBy or "?")
	if key == ns.Guild:CurrentKey() then
		return text .. " " .. L["OPTIONS_GUILD_CURRENT"]
	end
	if SKIPPED[why] then
		text = text .. " " .. L[SKIPPED[why]]
	end
	return text
end

local function GuildLabel(guild)
	local label = "<" .. (guild.name or "?") .. ">"
	if guild.realm ~= ns.PlayerRealm() then
		label = label .. " " .. Help(guild.realm or "")
	end
	return label
end

-- A connected realm's roster suffix wins; otherwise the guild's realm as the client spells it, spaces and all.
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
		hidden = Off,
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
		title = {
			type = "group",
			name = "",
			inline = true,
			order = 1,
			args = {
				name = {
					type = "description",
					name = GuildLabel(guild),
					fontSize = "large",
					width = Kit.TREE_ROW_WIDTH - Kit.REMOVE_ICON_WIDTH,
					order = 1,
				},
				remove = {
					type = "execute",
					name = "",
					desc = L["OPTIONS_GUILD_REMOVE"],
					image = REMOVE_ICON,
					imageWidth = 16,
					imageHeight = 16,
					width = Kit.REMOVE_ICON_WIDTH,
					order = 2,
					-- Asks first: it discards the guild's member ticks.
					confirm = true,
					confirmText = L["OPTIONS_GUILD_REMOVE_CONFIRM"]:format("<" .. (guild.name or "?") .. ">"),
					func = function()
						ns.Guild:Remove(key)
						Changed()
					end,
				},
			},
		},
		spacerTitle = Kit.Spacer(2),
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
	}
	-- Added by name: no roster, so its members are found by /who.
	if ns.Guild:ByNameOnly(guild) then
		return args
	end
	local memberArgs = {
		spacerMembers = Kit.Spacer(5, Off),
		membersLabel = Kit.Header(L["OPTIONS_GUILD_MEMBERS"], 6, Off),
		spacerMemberRows = Kit.Spacer(8, Off),
	}
	for name, option in pairs(memberArgs) do
		args[name] = option
	end
	local members = ns.Guild:ListedMembers(guild)
	if #members == 0 then
		args.membersEmpty = Kit.Desc(L["OPTIONS_GUILD_MEMBERS_EMPTY"], 9, Off)
	end
	for index, member in ipairs(members) do
		args["member" .. index] = MemberRow(guild, member, 10 + index, Off)
	end
	return args
end

local function SortedGuilds()
	local out = {}
	for key, guild in pairs(ns.db.global.guilds) do
		if not guild.removed then
			out[#out + 1] = { key = key, guild = guild }
		end
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
		intro = Kit.Desc(L["OPTIONS_GUILDS_INTRO"], 1),
		spacerIntro = Kit.Spacer(2),
		guildOffline = Kit.LabelRow(4, nil, L["OPTIONS_GUILD_OFFLINE"], {
			type = "select",
			desc = L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"],
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
		}),
		spacerAdd = Kit.Spacer(4.5),
		add = Kit.LabelRow(4.7, nil, L["OPTIONS_GUILD_ADD"], {
			type = "input",
			desc = L["OPTIONS_GUILD_ADD_DESCRIPTION"],
			get = function()
				return ""
			end,
			set = function(_, value)
				if ns.Guild:Add(value) > 0 then
					Changed()
				else
					ns.RefreshSettings()
				end
			end,
		}),
		spacerTree = Kit.Spacer(5),
	}
	local panel = {
		type = "group",
		name = Kit.SubPanelTitle(L["TAB_RECIPIENTS"], L["TAB_GUILDS"]),
		childGroups = "tree",
		args = args,
	}
	if not ns.db then
		return panel
	end

	local guilds = SortedGuilds()
	if #guilds == 0 then
		args.guildsEmpty = Kit.Desc(L["OPTIONS_GUILDS_EMPTY"], 6)
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
