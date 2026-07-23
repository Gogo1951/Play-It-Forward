local _, ns = ...

-- Stateless helpers used by more than one file. Anything used by exactly one file lives there.

--------------------------------------------------------------------------------
-- Container API Shims
--------------------------------------------------------------------------------

-- Picked by availability, never by truthy result. The bare globals are the pre-10.x fallback.
local C = C_Container
ns.GetNumSlots = (C and C.GetContainerNumSlots) or GetContainerNumSlots
ns.GetItemLink = (C and C.GetContainerItemLink) or GetContainerItemLink
ns.GetItemInfoC = (C and C.GetContainerItemInfo) or GetContainerItemInfo
ns.UseItem = (C and C.UseContainerItem) or UseContainerItem
ns.GetInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

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
-- Class Names and Colors
--------------------------------------------------------------------------------

-- Localized class name -> token, so /who results read locale-safely.
ns.classTokenByName = {}
do
	for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
		ns.classTokenByName[name] = token
	end
	for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
		ns.classTokenByName[name] = token
	end
end

--[[
	Honors a ClassColors or oUF-style override. Returns the bare "ffRRGGBB" form the |c escape
	takes, not a |cff prefix, which is why the fallback prepends "ff" itself.
]]
function ns.ClassColor(token)
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
	return ("|c%s%s|r"):format(ns.ClassColor(token), name or "?")
end

function ns.ClassName(token)
	return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token or ""
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

local QUALITY_NAME_KEY = { [2] = "QUALITY_UNCOMMON", [3] = "QUALITY_RARE", [4] = "QUALITY_EPIC" }

function ns.QualityColor(quality)
	local client = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	return (client and client.hex) or QUALITY_ESCAPE[quality] or ns.GetColor("TEXT")
end

function ns.QualityName(quality)
	local key = QUALITY_NAME_KEY[quality]
	return (key and ns.L[key]) or tostring(quality)
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
	the gate, and both shipped flavors have IsResting, so the fallback is unreachable in practice.
]]
function ns.AtRest()
	if not IsResting then
		return false
	end
	local ok, resting = pcall(IsResting)
	return (ok and resting) and true or false
end
