local _, ns = ...

-- Helpers used by more than one file; a one-file helper lives in that file.

--------------------------------------------------------------------------------
-- Item and Container APIs
--------------------------------------------------------------------------------

ns.GetItemLink = C_Container.GetContainerItemLink
ns.GetItemInfoC = C_Container.GetContainerItemInfo
ns.GetInfoInstant = C_Item.GetItemInfoInstant

-- Only WoW Forever ships C_Item.GetItemStats; Classic Era and TBC Anniversary keep the global.
ns.GetItemStats = C_Item.GetItemStats or GetItemStats

--------------------------------------------------------------------------------
-- Tooltip Text
--------------------------------------------------------------------------------

-- Both paths are live: Classic Era has no C_TooltipInfo.GetHyperlink, so the hidden tooltip is no leftover.
local SCAN_TOOLTIP_NAME = "PlayItForwardScanTooltip"
local scanTooltip

local function PlainText(text)
	if type(text) ~= "string" then
		return nil
	end
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", ""))
end

-- Every left line empty is no read: fall through rather than succeed empty.
local function AnyText(lines)
	for _, pair in ipairs(lines) do
		if pair[1] ~= "" then
			return true
		end
	end
	return false
end

local function ReadTooltipData(hyperlink)
	-- Can throw on an odd link; then the scanning tooltip is tried.
	local ok, data = pcall(C_TooltipInfo.GetHyperlink, hyperlink)
	if not ok or not data then
		return nil
	end
	-- Older 10.0.x builds hand back packed args that need surfacing first.
	if TooltipUtil and TooltipUtil.SurfaceArgs then
		TooltipUtil.SurfaceArgs(data)
		for _, line in ipairs(data.lines or {}) do
			TooltipUtil.SurfaceArgs(line)
		end
	end
	local out = {}
	for _, line in ipairs(data.lines or {}) do
		out[#out + 1] = { PlainText(line.leftText) or "", PlainText(line.rightText) }
	end
	return AnyText(out) and out or nil
end

local function ReadHiddenTooltip(hyperlink)
	-- No parent, and hidden after every read, so it never runs its template's OnUpdate in between.
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", SCAN_TOOLTIP_NAME, nil, "GameTooltipTemplate")
	end
	scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scanTooltip:ClearLines()
	if not pcall(scanTooltip.SetHyperlink, scanTooltip, hyperlink) then
		scanTooltip:Hide()
		return nil
	end
	local out = {}
	for index = 1, scanTooltip:NumLines() do
		local left = _G[SCAN_TOOLTIP_NAME .. "TextLeft" .. index]
		local right = _G[SCAN_TOOLTIP_NAME .. "TextRight" .. index]
		out[index] = {
			PlainText(left and left:GetText()) or "",
			PlainText(right and right:IsShown() and right:GetText() or nil),
		}
	end
	scanTooltip:Hide()
	return AnyText(out) and out or nil
end

function ns.ReadTooltip(hyperlink)
	if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
		local out = ReadTooltipData(hyperlink)
		if out then
			return out, "C_TooltipInfo"
		end
	end
	local out = ReadHiddenTooltip(hyperlink)
	if out then
		return out, "scanning tooltip"
	end
	return {}, "none"
end

function ns.GetTooltipLines(kind, id)
	local lines = {}
	for index, pair in ipairs((ns.ReadTooltip(kind .. ":" .. id))) do
		local right = pair[2]
		lines[index] = (right and right ~= "") and (pair[1] .. " >> " .. right) or pair[1]
	end
	return lines
end

--------------------------------------------------------------------------------
-- Frame Templates
--------------------------------------------------------------------------------

--[[
	Falls back to the last name. Stock Blizzard templates only: skinning add-ons restyle those and
	cannot touch a hand-rolled SetBackdrop.
]]
local function TemplateExists(name)
	if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo) then
		return nil
	end
	local ok, info = pcall(C_XMLUtil.GetTemplateInfo, name)
	return ok and info ~= nil
end

function ns.PickTemplate(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if name and TemplateExists(name) then
			return name
		end
	end
	return (select(select("#", ...), ...))
end

--------------------------------------------------------------------------------
-- ElvUI
--------------------------------------------------------------------------------

-- ElvUI's Skins module is another add-on's API, so every call is guarded: a change there leaves default art.
local function ElvUISkins()
	local elv = ElvUI and ElvUI[1]
	return elv and elv.GetModule and elv:GetModule("Skins", true)
end

function ns.SkinWidget(kind, widget)
	local skins = ElvUISkins()
	local handler = skins and skins["Handle" .. kind]
	if handler and widget then
		pcall(handler, skins, widget)
	end
end

-- The bar's key or global name differs by client.
function ns.SkinScrollFrame(scroll, name)
	ns.SkinWidget("ScrollBar", scroll.ScrollBar or (name and _G[name .. "ScrollBar"]))
end

--------------------------------------------------------------------------------
-- Color Accessor
--------------------------------------------------------------------------------

-- Read colors through ns.GetColor; never hardcode a |cff.
local COLOR_PREFIX = "|cff"

local COLORS = {}
for key, hex in pairs(ns.PALETTE) do
	COLORS[key] = COLOR_PREFIX .. hex
end

function ns.GetColor(key)
	return COLORS[key] or COLORS.TEXT
end

local COLORS_RGB = {}
for key, hex in pairs(ns.PALETTE) do
	COLORS_RGB[key] = {
		tonumber(hex:sub(1, 2), 16) / 255,
		tonumber(hex:sub(3, 4), 16) / 255,
		tonumber(hex:sub(5, 6), 16) / 255,
	}
end

function ns.GetColorRGB(key)
	local rgb = COLORS_RGB[key] or COLORS_RGB.TEXT
	return rgb[1], rgb[2], rgb[3]
end

--------------------------------------------------------------------------------
-- Class Colors
--------------------------------------------------------------------------------

-- Returns the bare "ffRRGGBB" the |c escape takes, not a |cff prefix.
local function ClassColor(token)
	local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[token]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[token])
	if not c then
		return "ff" .. (ns.CLASS_COLORS[token] or ns.PALETTE.TEXT)
	end
	if c.colorStr then
		return c.colorStr
	end
	return ("ff%02x%02x%02x"):format(
		math.floor((c.r or 1) * 255),
		math.floor((c.g or 1) * 255),
		math.floor((c.b or 1) * 255)
	)
end

function ns.ColorName(name, token)
	return ("|c%s%s|r"):format(ClassColor(token), name or "?")
end

--------------------------------------------------------------------------------
-- Item Quality
--------------------------------------------------------------------------------

-- The client's ITEM_QUALITY_COLORS wins, so rarity matches every other item on screen.
local QUALITY_KEY = { [2] = "UNCOMMON", [3] = "RARE", [4] = "EPIC" }

local QUALITY_ESCAPE = {}
for quality, key in pairs(QUALITY_KEY) do
	QUALITY_ESCAPE[quality] = COLOR_PREFIX .. ns.ITEM_QUALITY_COLORS[key]
end

local QUALITY_NAME_GLOBAL = { [2] = "ITEM_QUALITY2_DESC", [3] = "ITEM_QUALITY3_DESC", [4] = "ITEM_QUALITY4_DESC" }

function ns.QualityColor(quality)
	local client = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	return (client and client.hex) or QUALITY_ESCAPE[quality] or ns.GetColor("TEXT")
end

-- A cap's label: "X and lower", except at ns.Data.MIN_RARITY, where nothing is lower.
function ns.QualityName(quality)
	local global = QUALITY_NAME_GLOBAL[quality]
	local name = global and _G[global]
	if not name then
		return tostring(quality)
	end
	if quality > ns.Data.MIN_RARITY then
		return ns.L["QUALITY_AND_LOWER"]:format(name)
	end
	return name
end

function ns.DisenchantName()
	return C_Spell.GetSpellName(ns.Data.SPELL_IDS.DISENCHANT) or ""
end

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

ns.CONSUMABLE_GAP_VALUES = {}
for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
	ns.CONSUMABLE_GAP_VALUES[gap] = (gap == 0) and ns.L["OPTIONS_CONSUMABLE_GAP_ALL"]
		or ns.L["OPTIONS_CONSUMABLE_GAP_VALUE"]:format(gap)
end

--[[
	A select whose value is not in its list renders blank. Display only: the stored number keeps
	driving the scan until the player picks.
]]
function ns.NearestConsumableGap(value)
	local stored = tonumber(value) or 0
	local best, bestDistance = ns.CONSUMABLE_GAP_ORDER[1], math.huge
	for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
		local distance = math.abs(stored - gap)
		if distance < bestDistance then
			best, bestDistance = gap, distance
		end
	end
	return best
end

--------------------------------------------------------------------------------
-- Spec Names
--------------------------------------------------------------------------------

local classIDs

local function ClassID(token)
	if not classIDs then
		classIDs = {}
		local classInfo = C_CreatureInfo and C_CreatureInfo.GetClassInfo
		for classID = 1, 20 do
			local file
			if classInfo then
				local info = classInfo(classID)
				file = info and info.classFile
			elseif GetClassInfo then
				file = select(2, GetClassInfo(classID))
			end
			if file then
				classIDs[file] = classID
			end
		end
	end
	return classIDs[token]
end

-- Classic Era returns the name first, later clients an id first.
local function OwnTreeName(class, index)
	local _, playerClass = UnitClass("player")
	if class ~= playerClass or not GetTalentTabInfo then
		return nil
	end
	local ok, first, second = pcall(GetTalentTabInfo, index)
	if not ok then
		return nil
	end
	return (type(first) == "number") and second or first
end

--[[
	Where the client cannot name a tree, the add-on's SPEC_* string (README-Notes). A key two classes
	share whose name differs in some locale reads its class-qualified string instead.
]]
local CLASS_QUALIFIED_SPECS = {
	SPEC_PALADIN_Protection = true,
	SPEC_DRUID_Restoration = true,
}

function ns.SpecName(class, index, spec)
	local name
	if not spec.rune then
		if GetSpecializationInfoForClassID then
			local classID = ClassID(class)
			name = classID and select(2, GetSpecializationInfoForClassID(classID, index))
		else
			name = OwnTreeName(class, index)
		end
	end
	if type(name) ~= "string" or name == "" then
		local qualified = "SPEC_" .. tostring(class) .. "_" .. spec.key
		return ns.L[CLASS_QUALIFIED_SPECS[qualified] and qualified or "SPEC_" .. spec.key]
	end
	return name
end

--------------------------------------------------------------------------------
-- Player Names
--------------------------------------------------------------------------------

-- As GetNormalizedRealmName writes it: "Azjol-Nerub" is "AzjolNerub".
function ns.NormalizeRealm(realm)
	return ((realm or ""):gsub("[%s%-]", ""))
end

-- GetNormalizedRealmName answers nil early in login; the second read is that retry, not a legacy fallback.
function ns.PlayerRealm()
	local realm
	if GetNormalizedRealmName then
		realm = GetNormalizedRealmName()
	end
	if (realm == nil or realm == "") and GetRealmName then
		realm = GetRealmName()
	end
	return ns.NormalizeRealm(realm)
end

-- WoW Forever: addresses are "First Last" with no realm, and UnitName("player") answers the first name alone.
function ns.UsesSurnames()
	return (RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled()) and true or false
end

-- UnitNameUnmodified, exactly as AceDB builds its profile key there.
function ns.PlayerName()
	if ns.UsesSurnames() and UnitNameUnmodified then
		local name, surname = UnitNameUnmodified("player")
		if name and surname and surname ~= "" then
			return name .. " " .. surname
		end
		return name
	end
	return UnitName("player")
end

--[[
	An identity, never an address: SendMail gets the name the client handed us, kept verbatim. Never
	filter or branch on the suffix either: every name in reach is mailable.
]]
function ns.QualifyPlayerName(name)
	if not name or name == "" then
		return nil
	end
	if name:find("-", 1, true) then
		return name
	end
	return name .. "-" .. ns.PlayerRealm()
end

--------------------------------------------------------------------------------
-- Item Links
--------------------------------------------------------------------------------

-- Field 7 (item:id:enchant:g1:g2:g3:g4:suffix). Fields are often empty, so count separators, not digits.
function ns.ItemSuffixID(link)
	local payload = link and link:match("|Hitem:([^|]+)")
	if not payload then
		return nil
	end
	local index = 0
	for field in (payload .. ":"):gmatch("([^:]*):") do
		index = index + 1
		if index == 7 then
			local suffix = tonumber(field)
			return (suffix and suffix ~= 0) and suffix or nil
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Number Formatting
--------------------------------------------------------------------------------

function ns.CommaNumber(n)
	local number = tostring(math.floor(tonumber(n) or 0))
	local sign = ""
	if number:sub(1, 1) == "-" then
		sign, number = "-", number:sub(2)
	end
	while true do
		local replaced
		number, replaced = number:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return sign .. number
end

-- The same, under the name the Diagnostics framework copied from Magic Eraser calls.
function ns:FormatCommaNumber(number)
	return ns.CommaNumber(number)
end

-- The plain fallback is for the headless tests.
function ns.MoneyString(copper)
	copper = math.floor(tonumber(copper) or 0)
	if GetCoinTextureString then
		return GetCoinTextureString(copper)
	end
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	local bronze = copper % 100
	return ("%sg %ds %dc"):format(ns.CommaNumber(gold), silver, bronze)
end

--------------------------------------------------------------------------------
-- Game State
--------------------------------------------------------------------------------

-- The interaction manager first: ns.mailboxOpen goes stale, since MAIL_CLOSED does not fire on every way out.
function ns.AtMailbox()
	local manager = C_PlayerInteractionManager
	local kind = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
	if manager and manager.IsInteractingWithNpcOfType and kind then
		local ok, interacting = pcall(manager.IsInteractingWithNpcOfType, kind)
		if ok then
			return interacting and true or false
		end
	end
	return ns.mailboxOpen == true
end

-- The proxy for "in town". False without the API: staying out of the way is the point of the gate.
function ns.AtRest()
	if not IsResting then
		return false
	end
	local ok, resting = pcall(IsResting)
	return (ok and resting) and true or false
end
