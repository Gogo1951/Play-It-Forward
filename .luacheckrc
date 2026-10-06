std = "lua51"
max_line_length = false -- StyLua owns formatting
ignore = { "212/self", "611", "612", "613", "614", "621" } -- implicit self (house ns: methods) + whitespace — StyLua owns the latter
exclude_files = { "Includes/", ".claude/" } -- vendored or session-local, never linted

-- The WoW API surface this add-on reads and never writes.
read_globals = {
	"C_AddOns",
	"C_ChatInfo",
	"C_Container",
	"C_EventUtils",
	"C_FriendList",
	"C_GuildInfo",
	"C_Item",
	"C_PlayerInteractionManager",
	"C_Timer",
	"C_TooltipInfo",
	"C_XMLUtil",
	"ClearSendMail",
	"CreateFrame",
	"CUSTOM_CLASS_COLORS",
	"Enum",
	"FriendsFrame",
	"GameTooltip",
	"GetAddOnInfo",
	"GetAddOnMetadata",
	"GetBuildInfo",
	"GetCoinTextureString",
	"GetContainerItemInfo",
	"GetContainerItemLink",
	"GetContainerNumSlots",
	"GetCVar",
	"GetGuildRosterInfo",
	"GetGuildRosterLastOnline",
	"GetInventoryItemLink",
	"GetItemInfo",
	"GetItemInfoInstant",
	"GetItemStats",
	"GetLocale",
	"GetMoney",
	"GetNormalizedRealmName",
	"GetNumAddOns",
	"GetNumGuildMembers",
	"GetPhysicalScreenSize",
	"GetRealmName",
	"GetSendMailItem",
	"GetTime",
	"GuildRoster",
	"HideUIPanel",
	"InCombatLockdown",
	"InterfaceOptionsFrame_OpenToCategory",
	"IsEquippableItem",
	"IsInGuild",
	"IsResting",
	"ITEM_MOD_AGILITY_SHORT",
	"ITEM_MOD_INTELLECT_SHORT",
	"ITEM_MOD_SPIRIT_SHORT",
	"ITEM_MOD_STAMINA_SHORT",
	"ITEM_MOD_STRENGTH_SHORT",
	"ITEM_QUALITY_COLORS",
	"LibStub",
	"LOCALIZED_CLASS_NAMES_FEMALE",
	"LOCALIZED_CLASS_NAMES_MALE",
	"MailEditBox",
	"MailFrame",
	"MailFrameTab_OnClick",
	"RAID_CLASS_COLORS",
	"RegisterAddonMessagePrefix",
	"SendAddonMessage",
	"SendMail",
	"SendMailBodyEditBox",
	"SendMailFrame",
	"SendMailNameEditBox",
	"SendMailSubjectEditBox",
	"SetCVar",
	"Settings",
	"strtrim",
	"tinsert",
	"TooltipUtil",
	"UIParent",
	"UISpecialFrames",
	"UnitFactionGroup",
	"UnitIsPlayer",
	"UnitLevel",
	"UnitName",
	"UseContainerItem",
	"WhoFrame",
	"wipe",
	"WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
	"WOW_PROJECT_CLASSIC",
	"WOW_PROJECT_ID",
	-- AceDB owns the saved table; the add-on only reads it raw, for the Diagnostics dump.
	"PlayItForwardDB",
	--[[
		Blizzard's table, so it is read-only apart from the one key the add-on
		registers its slash command under. Declared as a field rather than by listing
		the table under globals, which would sanction writing over the whole thing.
	]]
	SlashCmdList = { fields = { PLAYITFORWARD = { read_only = false } } },
}

-- The one global the add-on defines: its slash command's name.
globals = {
	"SLASH_PLAYITFORWARD1",
}

--[[
	The offline suites stand in for the client: Stub-WoW-API.lua defines the WoW globals
	the config above treats as read-only, and the suites read them back. Defining,
	setting and reading those globals is the point there, so those warnings are off.
]]
files["Tests/"] = { ignore = { "111", "112", "113", "121", "122", "131", "143" } }
