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
	An item's or spell's tooltip as plain lines, a right-hand column kept after " >> ", for the
	Validate Data report. kind is "item" or "spell". C_TooltipInfo hands the lines over as data
	where the client ships its GetItemByID and GetSpellByID getters (WoW Forever); elsewhere they
	are read off a hidden tooltip that is never shown. Color escapes are stripped so each line
	reads as its words. Resolved once at load. A read can throw on an odd id, so callers protect it.
]]
local DATA_TOOLTIP_NAME = "PlayItForwardDataTooltip"
local TOOLTIP_DATA_GETTERS = C_TooltipInfo
	and C_TooltipInfo.GetItemByID
	and C_TooltipInfo.GetSpellByID
	and { item = C_TooltipInfo.GetItemByID, spell = C_TooltipInfo.GetSpellByID }
local dataTooltip

local function PlainText(text)
	if type(text) ~= "string" then
		return nil
	end
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", ""))
end

local function JoinTooltipLine(left, right)
	left = PlainText(left) or ""
	right = PlainText(right)
	if right and right ~= "" then
		return left .. " >> " .. right
	end
	return left
end

local function ReadTooltipData(kind, id)
	local lines = {}
	local data = TOOLTIP_DATA_GETTERS[kind](id)
	for _, line in ipairs(data and data.lines or {}) do
		lines[#lines + 1] = JoinTooltipLine(line.leftText, line.rightText)
	end
	return lines
end

local function ReadHiddenTooltip(kind, id)
	if not dataTooltip then
		dataTooltip = CreateFrame("GameTooltip", DATA_TOOLTIP_NAME, nil, "GameTooltipTemplate")
	end
	dataTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	dataTooltip:ClearLines()
	dataTooltip:SetHyperlink(kind .. ":" .. id)
	local lines = {}
	for index = 1, dataTooltip:NumLines() do
		local left = _G[DATA_TOOLTIP_NAME .. "TextLeft" .. index]
		local right = _G[DATA_TOOLTIP_NAME .. "TextRight" .. index]
		lines[#lines + 1] = JoinTooltipLine(left and left:GetText(), right and right:IsShown() and right:GetText())
	end
	dataTooltip:Hide()
	return lines
end

ns.GetTooltipLines = TOOLTIP_DATA_GETTERS and ReadTooltipData or ReadHiddenTooltip

--------------------------------------------------------------------------------
-- Frame Templates
--------------------------------------------------------------------------------

--[[
	The first of the given template names this client has, falling back to the last. Stock Blizzard
	templates only: skinning add-ons restyle those and cannot touch a hand-rolled SetBackdrop.
]]
local function templateExists(name)
	if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo) then
		return nil
	end
	local ok, info = pcall(C_XMLUtil.GetTemplateInfo, name)
	return ok and info ~= nil
end

function ns.PickTemplate(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if name and templateExists(name) then
			return name
		end
	end
	return (select(select("#", ...), ...))
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
local function classColor(token)
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
	return ("|c%s%s|r"):format(classColor(token), name or "?")
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
-- Player Names
--------------------------------------------------------------------------------

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
	--[[
		PICKED BY AVAILABILITY, then retried on an unresolved answer. The second read is not a
		legacy fallback: every target has GetNormalizedRealmName, and it answers nil
		early in login before the realm resolves, which is the one case worth asking twice for.
	]]
	local realm
	if GetNormalizedRealmName then
		realm = GetNormalizedRealmName()
	end
	if (realm == nil or realm == "") and GetRealmName then
		realm = GetRealmName()
	end
	-- Suffixes carry no spaces, so "Blade's Edge" is "BladesEdge" in a qualified name.
	return name .. "-" .. ((realm or ""):gsub("%s+", ""))
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
	A whole number with thousands separators: 1234567 -> "1,234,567". Stateless, used by the General
	panel's Given Away display and Features/Generosity-Tooltip.lua. The tally counters are integers,
	so the fractional part is dropped rather than rounded; a stray negative keeps its sign.
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
