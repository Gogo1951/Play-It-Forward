local _, ns = ...

-- Stateless helpers used by more than one file. Anything used by exactly one file lives there.

--------------------------------------------------------------------------------
-- Item and Container APIs
--------------------------------------------------------------------------------

ns.GetItemLink = C_Container.GetContainerItemLink
-- A table, or nil for an empty slot.
ns.GetItemInfoC = C_Container.GetContainerItemInfo
ns.GetInfoInstant = C_Item.GetItemInfoInstant

-- Only WoW Forever ships C_Item.GetItemStats; Classic Era and TBC Anniversary keep the global.
ns.GetItemStats = C_Item.GetItemStats or GetItemStats

--------------------------------------------------------------------------------
-- Tooltip Text
--------------------------------------------------------------------------------

--[[
	A hyperlink's tooltip as { left, right } plain-text pairs, color escapes stripped so each line
	reads as its words, plus where it came from: "C_TooltipInfo", "scanning tooltip" or "none".
	Both paths are live: Classic Era has no C_TooltipInfo.GetHyperlink, so the hidden tooltip is not
	a legacy leftover. Shared by the stat reader (Features/Scan-Tooltip.lua) and Validate Data.
]]
local SCAN_TOOLTIP_NAME = "PlayItForwardScanTooltip"
local scanTooltip

local function PlainText(text)
	if type(text) ~= "string" then
		return nil
	end
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", ""))
end

-- A read with every left line empty is no read: it falls through rather than "succeeding" empty.
local function AnyText(lines)
	for _, pair in ipairs(lines) do
		if pair[1] ~= "" then
			return true
		end
	end
	return false
end

local function ReadTooltipData(hyperlink)
	-- A read can throw on an odd link; a throw is no data, and the scanning tooltip is tried.
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

--[[
	An item's or spell's tooltip as plain lines, a right-hand column kept after " >> ", for the
	Validate Data report. kind is "item" or "spell".
]]
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
	The first of the given template names this client has, falling back to the last. Stock Blizzard
	templates only: skinning add-ons restyle those and cannot touch a hand-rolled SetBackdrop.
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

--[[
	With ElvUI loaded, its Skins module dresses the add-on's own buttons, ticks, dropdowns and
	scrollbars as it dresses Blizzard's, so they match the rest of that UI, as Bags Buffs &
	Buttons' windows do. The module is another add-on's API, so every call is guarded: a change to
	it leaves a control in the default art rather than breaking the window. Without ElvUI this
	does nothing.
]]
local function ElvUISkins()
	local elv = ElvUI and ElvUI[1]
	return elv and elv.GetModule and elv:GetModule("Skins", true)
end

-- kind names one of the Skins module's handlers: "Button", "CheckBox" or "ScrollBar".
function ns.SkinWidget(kind, widget)
	local skins = ElvUISkins()
	local handler = skins and skins["Handle" .. kind]
	if handler and widget then
		pcall(handler, skins, widget)
	end
end

-- A UIPanelScrollFrameTemplate's bar, under whichever name this client gives it.
function ns.SkinScrollFrame(scroll, name)
	ns.SkinWidget("ScrollBar", scroll.ScrollBar or (name and _G[name .. "ScrollBar"]))
end

--------------------------------------------------------------------------------
-- Color Accessor
--------------------------------------------------------------------------------

-- Derived once from ns.PALETTE. Read colors through ns.GetColor; never hardcode a |cff.
local COLOR_PREFIX = "|cff"

local COLORS = {}
for key, hex in pairs(ns.PALETTE) do
	COLORS[key] = COLOR_PREFIX .. hex
end

function ns.GetColor(key)
	return COLORS[key] or COLORS.TEXT
end

-- The same palette as r, g, b, for APIs that take numbers rather than an escape.
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

--[[
	Honors a ClassColors or oUF-style override. Returns the bare "ffRRGGBB" form the |c escape
	takes, not a |cff prefix, which is why the fallback prepends "ff" itself. File-local: the
	colored name below is what the rest of the add-on asks for.
]]
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

-- The client's own ITEM_QUALITY_COLORS wins, so rarity matches every other item on screen.
local QUALITY_KEY = { [2] = "UNCOMMON", [3] = "RARE", [4] = "EPIC" }

local QUALITY_ESCAPE = {}
for quality, key in pairs(QUALITY_KEY) do
	QUALITY_ESCAPE[quality] = COLOR_PREFIX .. ns.ITEM_QUALITY_COLORS[key]
end

-- The game's own quality names, so every locale reads them as its item tooltips do.
local QUALITY_NAME_GLOBAL = { [2] = "ITEM_QUALITY2_DESC", [3] = "ITEM_QUALITY3_DESC", [4] = "ITEM_QUALITY4_DESC" }

function ns.QualityColor(quality)
	local client = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	return (client and client.hex) or QUALITY_ESCAPE[quality] or ns.GetColor("TEXT")
end

--[[
	The cap a quality sets: that quality and everything beneath it. Uncommon stands alone because
	nothing is ever beneath it -- ns.Data.MIN_RARITY floors the gear scan at uncommon.
]]
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

--------------------------------------------------------------------------------
-- Consumable Level Gap
--------------------------------------------------------------------------------

--[[
	The stops are data, in Data/Data.lua; the words are here, shared by the options panel and the
	mail window. Zero is the "All Consumables" stop and lifts the level rule outright (see
	Features/Scan-Bags.lua), so it reads as itself rather than as a gap of nothing.
]]
ns.CONSUMABLE_GAP_VALUES = {}
for _, gap in ipairs(ns.CONSUMABLE_GAP_ORDER) do
	ns.CONSUMABLE_GAP_VALUES[gap] = (gap == 0) and ns.L["OPTIONS_CONSUMABLE_GAP_ALL"]
		or ns.L["OPTIONS_CONSUMABLE_GAP_VALUE"]:format(gap)
end

--[[
	A select whose value is not in its list renders blank, reading as a setting that failed to
	load. Display only: the stored number keeps driving the scan until the player picks.
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

-- Class token -> the client's classID, built on first use.
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

-- The logged-in class's own tree name; Classic Era leads with the name, later clients with an id.
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
	A spec's name as the game writes it (GAME NAMES), by its index in the flavor folder's
	Match-Specs file: every class's on a client with GetSpecializationInfoForClassID, the
	logged-in class's own trees elsewhere. Where the client has none -- another class's trees on
	Classic Era, TBC Anniversary and WoW Forever, and Season of Discovery's rune roles -- the
	add-on's own SPEC_* string (README-Notes). A tree whose key another class shares, but whose
	name differs from it in some locale, reads its class-qualified string instead.
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

--[[
	A realm as a name suffix writes it: no spaces or hyphens, so "Blade's Edge" is "Blade'sEdge"
	and "Azjol-Nerub" is "AzjolNerub", as GetNormalizedRealmName gives them.
]]
function ns.NormalizeRealm(realm)
	return ((realm or ""):gsub("[%s%-]", ""))
end

--[[
	This character's realm in that form. PICKED BY AVAILABILITY, then retried on an unresolved
	answer. The second read is not a legacy fallback: every target has GetNormalizedRealmName, and
	it answers nil early in login before the realm resolves, which is the one case worth asking
	twice for.
]]
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

--[[
	One character's identity as "Name-Realm", for telling two sightings of the same player
	apart from two players. /who answers with a bare name for somebody on your own realm where
	the guild roster qualifies them, so the raw strings differ for one person and only this
	form matches them up.

	AN IDENTITY, NEVER AN ADDRESS. What reaches SendMail is the name the client handed us,
	kept verbatim wherever it is stored; a string assembled here was never given by any API.
	Never filter or branch on the suffix either: Classic realms are all connected, so every
	name in reach is mailable.
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

--[[
	The random-suffix id from an item link, or nil, which separates an item carrying no stats from
	one whose stats were not read. Field 7 of the payload is the suffix id
	(item:id:enchant:g1:g2:g3:g4:suffix); fields are frequently empty, so this counts separators
	rather than matching digits.
]]
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

--[[
	A whole number with thousands separators: 1234567 -> "1,234,567". Stateless, used by
	Generosity:BlockLines, which the tooltip and the Badge of Generosity panel share. The tally counters
	are integers, so the fractional part is dropped rather than rounded; a stray negative keeps its
	sign.
]]
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

--[[
	Copper as a gold/silver/copper string. GetCoinTextureString is the client's own formatter and
	renders the coin icons; where it is absent -- the headless tests, an unexpectedly stripped
	client -- fall back to a plain "Xg Ys Zc" so a money value always has something to show.
]]
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

--[[
	The interaction manager knows for certain. Our own ns.mailboxOpen tracking goes stale, since
	MAIL_CLOSED does not fire on every way out.
]]
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

--[[
	In a rest area: a city or an inn. The Given Away broadcast and its tooltip block are both gated
	on this, so no addon traffic goes out and no tooltip clutter appears while a player is in a raid,
	a dungeon or a fight out in the world -- resting is the cheap, reliable proxy for "in town".

	Absent the API this answers false rather than true: staying out of the way is the whole point of
	the gate, and every target has IsResting, so the fallback is unreachable in practice.
]]
function ns.AtRest()
	if not IsResting then
		return false
	end
	local ok, resting = pcall(IsResting)
	return (ok and resting) and true or false
end
