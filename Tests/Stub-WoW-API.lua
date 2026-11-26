--[[
	Enough of the WoW client to load the add-on outside the game. Not a mock framework: the
	smallest set of globals that lets the real files run unmodified, each answering in the real
	API's shape (C_Item.GetItemInfo's 14 positional values, a table from
	C_Container.GetContainerItemInfo, an item link with a real suffix field).
]]

local Stub = {}

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

--[[
	One stub answers to anything: a frame key is either a method or a child widget, and a
	callable table covers both. Methods that feed arithmetic must answer a number, so they are
	named here; a missing one fails as "attempt to perform arithmetic", never as a wrong result.
]]
local NUMERIC = {
	GetStringWidth = true,
	GetWidth = true,
	GetHeight = true,
	GetScale = true,
	GetTop = true,
	GetLeft = true,
	GetRight = true,
	GetBottom = true,
	GetCenter = true,
	GetEffectiveScale = true,
	GetStringHeight = true,
	GetFrameLevel = true,
}

local function newStub(numeric)
	local t = {}
	return setmetatable(t, {
		__index = function(self, key)
			-- SetText is kept, not swallowed: cases assert what the status line says.
			if key == "SetText" then
				local setter = function(this, text)
					rawset(this, "shownText", text)
					return this
				end
				rawset(self, key, setter)
				return setter
			end
			if key == "GetText" then
				local getter = function(this)
					return rawget(this, "shownText") or ""
				end
				rawset(self, key, getter)
				return getter
			end
			local child = newStub(NUMERIC[key])
			rawset(self, key, child)
			return child
		end,
		__call = function()
			if numeric then
				return 0
			end
			return newStub()
		end,
	})
end

-- Shown state is real: Tests/Mailbox-Gate.lua asserts on it, and a truthy catch-all would report it open.
local function newFrame()
	local f = newStub()
	local shown = false

	--[[
		OnShow and OnHide are real: Escape closes a window through UISpecialFrames, which only
		calls Hide. They fire only on a genuine change of state, as the client does.

		HookScript only records: cases fire MailFrame's hooks by name, and firing them from Show
		would open a mailbox twice.
	]]
	local scripts = {}
	rawset(f, "SetScript", function(self, name, fn)
		scripts[name] = fn
		return self
	end)
	rawset(f, "GetScript", function(_, name)
		return scripts[name]
	end)
	local function runScript(name)
		if scripts[name] then
			scripts[name](f)
		end
	end

	rawset(f, "Show", function()
		if shown then
			return
		end
		shown = true
		runScript("OnShow")
	end)
	rawset(f, "Hide", function()
		if not shown then
			return
		end
		shown = false
		runScript("OnHide")
	end)
	rawset(f, "IsShown", function()
		return shown
	end)
	rawset(f, "IsVisible", function()
		return shown
	end)

	-- Enabled state is real: cases assert Find Recipients locks for the /who throttle.
	local enabled = true
	rawset(f, "Enable", function()
		enabled = true
	end)
	rawset(f, "Disable", function()
		enabled = false
	end)
	rawset(f, "IsEnabled", function()
		return enabled
	end)
	-- Checked state is real: the mailbox tab is lit by it while the window is up.
	local checked = false
	rawset(f, "SetChecked", function(_, value)
		checked = value and true or false
	end)
	rawset(f, "GetChecked", function()
		return checked
	end)
	rawset(f, "hooks", {})
	rawset(f, "HookScript", function(self, script, fn)
		self.hooks[script] = fn
		return self
	end)

	--[[
		Event registration is real: /who unregisters WHO_LIST_UPDATE from the Blizzard frames for
		the life of a query, and cases check both halves.
	]]
	local registered = {}
	rawset(f, "RegisterEvent", function(_, event)
		if not registered[event] then
			Stub.listeners[event] = Stub.listeners[event] or {}
			table.insert(Stub.listeners[event], f)
		end
		registered[event] = true
	end)
	rawset(f, "UnregisterEvent", function(_, event)
		registered[event] = nil
		for index, frame in ipairs(Stub.listeners[event] or {}) do
			if frame == f then
				table.remove(Stub.listeners[event], index)
				break
			end
		end
	end)
	rawset(f, "IsEventRegistered", function(_, event)
		return registered[event] == true
	end)
	-- Real for the same reason: the catch-all would call every listener forbidden and every name a table.
	rawset(f, "IsForbidden", function()
		return false
	end)
	rawset(f, "GetName", function()
		return rawget(f, "_name")
	end)
	-- Real too: Menu-Kit walks a frame's parents until there are none, and a catch-all never ends.
	rawset(f, "GetParent", function()
		return rawget(f, "_parent")
	end)
	return f
end

-- Every frame registered for an event, in registration order: what GetFramesRegisteredForEvent reads.
Stub.listeners = {}

Stub.NewFrame = newFrame

--------------------------------------------------------------------------------
-- Items and bags
--------------------------------------------------------------------------------

Stub.itemsByLink = {}
Stub.bags = {}

--[[
	Generated ids start at seven figures: Features/Scan-Bags.lua looks every scanned item up in
	the consumable index, so an id colliding with a real Scan-* row turns a green chest into
	water, and only once enough earlier cases have pushed the counter that far.

	The counter never resets per Install. Fixtures are built as arguments, before the load inside
	readyToDistribute({ cloak() }, ...), so a restarted counter would hand a later fixture the
	same id and link and overwrite the earlier one.
]]
local ID_BASE = 9000000
local nextItemID = ID_BASE

--[[
	One item in the client's shape; defaults are a plain bind-on-equip green. stats is what
	GetItemStats answers, tooltipLines what the item renders: a random-suffix roll has its stats
	only in the second, the case Features/Scan-Tooltip.lua exists for.
]]
function Stub.Item(fields)
	nextItemID = nextItemID + 1
	local def = {
		id = fields.id or nextItemID,
		name = fields.name or ("Test Item " .. nextItemID),
		quality = fields.quality or 2,
		reqLevel = fields.reqLevel or 1,
		equipLoc = fields.equipLoc or "",
		classID = fields.classID or 4, -- Armor
		subclassID = fields.subclassID or 1, -- Cloth
		bindType = fields.bindType or 2, -- Bind on Equip
		isBound = fields.isBound or false,
		count = fields.count or 1,
		sellPrice = fields.sellPrice or 0, -- copper; C_Item.GetItemInfo's 11th value
		stats = fields.stats or {},
		tooltipLines = fields.tooltipLines,
		suffix = fields.suffix,
	}
	def.itemLevel = fields.itemLevel or def.reqLevel
	def.link = ("|cff1eff00|Hitem:%d::::::%s|h[%s]|h|r"):format(
		def.id,
		def.suffix and tostring(def.suffix) or "",
		def.name
	)
	Stub.itemsByLink[def.link] = def
	-- The live client resolves "item:ID" strings too; the verdict report leans on that for pasted ids.
	Stub.itemsByLink["item:" .. def.id] = def
	return def
end

-- Bags 1-4 stay empty, as on an unbagged alt.
function Stub.SetBackpack(defs)
	Stub.bags = { [0] = { slots = 16, items = {} } }
	for index, def in ipairs(defs) do
		Stub.bags[0].items[index] = def
	end
end

local function slotItem(bag, slot)
	local container = Stub.bags[bag]
	return container and container.items[slot]
end

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

function Stub.Install()
	Stub.printed = {}
	Stub.listeners = {}
	GetFramesRegisteredForEvent = function(event)
		return (table.unpack or unpack)(Stub.listeners[event] or {})
	end

	--[[
		itemsByLink is not cleared: fixtures are built before the load they are passed into, so
		wiping it would leave their links scanning as NOT_CACHED.
	]]
	Stub.bags = {}

	-- Each mail is { sender, subject, hasItem, wasRead, wasReturned, link }.
	Stub.inbox = {}
	GetInboxNumItems = function()
		return #Stub.inbox, #Stub.inbox
	end
	GetInboxHeaderInfo = function(index)
		local mail = Stub.inbox[index]
		if not mail then
			return nil
		end
		return nil, nil, mail.sender, mail.subject, 0, 0, 30, mail.hasItem, mail.wasRead, mail.wasReturned
	end
	GetInboxItemLink = function(index)
		local mail = Stub.inbox[index]
		return mail and mail.link
	end
	Ambiguate = function(name)
		return (name:gsub("%-.*$", ""))
	end

	--[[
		Data/Flavor.lua reads the flavor here: Classic Era unless a case sets Stub.flavor before
		it loads. No Version field, so the add-on reads itself as a dev copy.
	]]
	Stub.flavor = Stub.flavor or "Vanilla"
	C_AddOns = {
		GetAddOnMetadata = function(_, field)
			if field == "X-Flavor" then
				return Stub.flavor
			end
			return nil
		end,
	}
	Enum = {
		SeasonID = { SeasonOfDiscovery = 2 },
		TooltipDataType = { Unit = 2 },
		PlayerInteractionType = { MailInfo = 17 },
	}

	--[[
		With no processor the add-on hooks OnTooltipSetUnit; a case wanting the processor sets
		Stub.useTooltipProcessor before it loads and reads the post-call from Stub.tooltipPostCalls.
	]]
	Stub.tooltipPostCalls = {}
	if Stub.useTooltipProcessor then
		TooltipDataProcessor = {
			AddTooltipPostCall = function(dataType, fn)
				Stub.tooltipPostCalls[dataType] = fn
			end,
		}
	else
		TooltipDataProcessor = nil
	end

	-- Unit identity reads as secret on WoW Forever in combat; a case wanting that sets the flag.
	Stub.identitySecret = false
	C_Secrets = {
		ShouldUnitIdentityBeSecret = function()
			return Stub.identitySecret
		end,
	}
	C_Seasons = {
		GetActiveSeason = function()
			return Stub.season or 0
		end,
	}

	UISpecialFrames = {}
	tinsert = table.insert
	wipe = function(t)
		for key in pairs(t) do
			t[key] = nil
		end
		return t
	end
	strtrim = function(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end
	-- WoW exposes this as a bare global; standalone Lua keeps it behind os.
	time = os.time

	-- Starts well past zero so the /who throttle, comparing against a lastSent of 0, lets a first query out.
	Stub.now = 100000
	GetTime = function()
		return Stub.now
	end

	LOCALIZED_CLASS_NAMES_MALE = {
		WARRIOR = "Warrior",
		PALADIN = "Paladin",
		HUNTER = "Hunter",
		ROGUE = "Rogue",
		PRIEST = "Priest",
		SHAMAN = "Shaman",
		MAGE = "Mage",
		WARLOCK = "Warlock",
		DRUID = "Druid",
		DEATHKNIGHT = "Death Knight",
		MONK = "Monk",
	}
	LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_MALE

	--[[
		Alliance, so the absent-class filter has work: on Classic Era data it drops shamans for
		this faction and death knights for the whole client.
	]]
	UnitFactionGroup = function()
		return "Alliance"
	end
	UnitClass = function()
		return "Mage", "MAGE"
	end
	Stub.playerLevel = 60
	UnitLevel = function()
		return Stub.playerLevel
	end

	-- Resting gates the Given Away broadcast and its tooltip block, so it starts true.
	Stub.resting = true
	IsResting = function()
		return Stub.resting
	end
	-- A case that wants the combat lockdown sets it.
	Stub.inCombat = false
	InCombatLockdown = function()
		return Stub.inCombat
	end
	GetRealmName = function()
		return "Test"
	end
	GetNormalizedRealmName = GetRealmName
	-- The Americas, so the data files pick the US realm clusters. "Test" is in none of them.
	GetCurrentRegion = function()
		return 1
	end

	--[[
		A named frame lands in _G: Features/Scan-Tooltip.lua reads its lines back by name. A
		GameTooltip renders a fixture's tooltipLines, so suffix parsing runs end to end.
	]]
	CreateFrame = function(kind, name, parent, _)
		local frame = newFrame()
		rawset(frame, "_parent", parent)
		if name then
			_G[name] = frame
			rawset(frame, "_name", name)
		end
		if kind == "GameTooltip" then
			local rendered = {}
			rawset(frame, "ClearLines", function()
				rendered = {}
			end)
			rawset(frame, "SetHyperlink", function(_, link)
				local def = Stub.itemsByLink[link]
				rendered = (def and def.tooltipLines) or {}
				for index, text in ipairs(rendered) do
					_G[(name or "") .. "TextLeft" .. index] = {
						GetText = function()
							return text
						end,
					}
				end
			end)
			rawset(frame, "NumLines", function()
				return #rendered
			end)
		end
		return frame
	end
	UIParent = newFrame()
	MailFrame = newFrame()
	GameTooltip = newFrame()
	-- Its owner is real, so a menu closing can ask whether the tooltip is one of its own.
	rawset(GameTooltip, "SetOwner", function(self, owner)
		rawset(self, "_owner", owner)
	end)
	rawset(GameTooltip, "GetOwner", function(self)
		return rawget(self, "_owner")
	end)
	--[[
		WoW Forever's GameTooltip runs on tooltip data; the Classic clients expose the processor
		but keep the legacy scripts. A case wanting the Classic shape sets Stub.legacyTooltipFrames.
	]]
	if Stub.useTooltipProcessor and not Stub.legacyTooltipFrames then
		rawset(GameTooltip, "GetPrimaryTooltipData", function()
			return {}
		end)
	end

	GetLocale = function()
		return "enUS"
	end
	-- The header every diagnostics report opens with, in the client's four-value shape.
	GetBuildInfo = function()
		return "1.15.8", "67156", "Jan 1 2026", 11508
	end

	-- The game's quality names, which the gear cap's dropdown reads.
	ITEM_QUALITY2_DESC = "Uncommon"
	ITEM_QUALITY3_DESC = "Rare"
	ITEM_QUALITY4_DESC = "Epic"
	-- The prefixes the stat reader skips: a use, a proc or a set bonus is not a stat.
	ITEM_SPELL_TRIGGER_ONUSE = "Use:"
	ITEM_SPELL_TRIGGER_ONPROC = "Chance on hit:"
	ITEM_SET_BONUS = "Set: %s"
	-- The faction-standing line Features/Scan-Tooltip.lua holds a consumable back on.
	ITEM_REQ_REPUTATION = "Requires %s - %s"

	-- Features/Scan-Tooltip.lua reads "+N Something" against these; every Scan-Stats key is here.
	ITEM_MOD_STRENGTH_SHORT = "Strength"
	ITEM_MOD_AGILITY_SHORT = "Agility"
	ITEM_MOD_INTELLECT_SHORT = "Intellect"
	ITEM_MOD_SPIRIT_SHORT = "Spirit"
	ITEM_MOD_STAMINA_SHORT = "Stamina"
	ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power"
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged Attack Power"
	ITEM_MOD_SPELL_POWER_SHORT = "Spell Power"
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Damage"
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing"
	ITEM_MOD_HEALING_DONE_SHORT = "Healing"
	ITEM_MOD_HIT_RATING_SHORT = "Hit Rating"
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "Spell Hit Rating"
	ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike Rating"
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "Spell Critical Strike Rating"
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense Rating"
	ITEM_MOD_DODGE_RATING_SHORT = "Dodge Rating"
	ITEM_MOD_BLOCK_RATING_SHORT = "Block Rating"
	ITEM_MOD_MANA_REGENERATION_SHORT = "Mana Regen"
	-- Mists' own wording: the short names lost "Rating" in Cataclysm.
	ITEM_MOD_HASTE_RATING_SHORT = "Haste"
	ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise"
	ITEM_MOD_MASTERY_RATING_SHORT = "Mastery"
	ITEM_MOD_PARRY_RATING_SHORT = "Parry"
	ITEM_MOD_RESILIENCE_RATING_SHORT = "PvP Resilience"
	ITEM_MOD_PVP_POWER_SHORT = "PvP Power"

	-- The client's real mail refusals, so Features/Mail-Sender.lua matches the text it sends.
	ERR_MAIL_DATABASE_ERROR = "Internal mail database error!"
	ERR_MAIL_TARGET_NOT_FOUND = "Player not found."
	ERR_MAIL_TO_SELF = "You cannot send mail to yourself."
	ERR_MAIL_RECEPIENT_CANT_RECEIVE_MAIL = "Recipient cannot receive mail."
	-- No ERR_MAIL prefix, but a mail refusal all the same: observed on Forever 1.60.1.
	ERR_PLAYER_WRONG_FACTION = "Target is unfriendly."

	-- Enough races for the /who faction filter; Pandaren is under both factions, as in the client.
	local RACES = {
		[1] = { "Human", "Alliance" },
		[2] = { "Orc", "Horde" },
		[3] = { "Dwarf", "Alliance" },
		[4] = { "Night Elf", "Alliance" },
		[5] = { "Undead", "Horde" },
		[6] = { "Tauren", "Horde" },
		[25] = { "Pandaren", "Alliance" },
		[26] = { "Pandaren", "Horde" },
	}
	C_CreatureInfo = {
		GetRaceInfo = function(raceID)
			local race = RACES[raceID]
			return race and { raceName = race[1], raceID = raceID } or nil
		end,
		GetFactionInfo = function(raceID)
			local race = RACES[raceID]
			return race and { name = race[2], groupTag = race[2] } or nil
		end,
	}

	-- A cold cache answers nil, as the client does; cached = false on a fixture reaches NOT_CACHED.
	local function getItemInfo(link)
		local def = Stub.itemsByLink[link]
		if not def or def.cached == false then
			return nil
		end
		return def.name,
			def.link,
			def.quality,
			def.itemLevel,
			def.reqLevel,
			"",
			"",
			1,
			def.equipLoc,
			"",
			def.sellPrice or 0,
			def.classID,
			def.subclassID,
			def.bindType
	end

	-- Generosity:RecordSend counts item level for gear only through this, so a consumable answers false.
	local function isEquippableItem(link)
		local def = Stub.itemsByLink[link]
		return def ~= nil and def.equipLoc ~= nil and def.equipLoc ~= ""
	end

	-- The Classic Era shape: the stats reader is a bare global, and C_Item has no GetItemStats.
	GetItemStats = function(link)
		local def = Stub.itemsByLink[link]
		return def and def.stats or {}
	end

	-- The Diagnostics validator resolves its spell and quest readers at load; absent ones leave blank cells.
	-- The one spell the add-on names, by the ID in each flavor folder's Game-IDs file.
	C_Spell = {
		GetSpellName = function(spellID)
			return ({ [13262] = "Disenchant" })[spellID]
		end,
	}
	C_QuestLog = {}

	C_Item = {
		GetItemInfo = getItemInfo,
		IsEquippableItem = isEquippableItem,
		GetItemInfoInstant = function(link)
			local def = Stub.itemsByLink[link]
			return def and def.id
		end,
	}

	C_Container = {
		GetContainerNumSlots = function(bag)
			local container = Stub.bags[bag]
			return container and container.slots or 0
		end,
		GetContainerItemLink = function(bag, slot)
			local def = slotItem(bag, slot)
			return def and def.link
		end,
		GetContainerItemInfo = function(bag, slot)
			local def = slotItem(bag, slot)
			if not def then
				return nil
			end
			return { stackCount = def.count, isBound = def.isBound }
		end,
		--[[
			As the real call does, this leaves the item in its slot until the send confirms, and
			writes the item's name into an empty subject box, so anything filling that box must
			do it after.
		]]
		UseContainerItem = function(bag, slot)
			local def = slotItem(bag, slot)
			Stub.attached = def and def.link
			if def and SendMailSubjectEditBox and (SendMailSubjectEditBox.shownText or "") == "" then
				SendMailSubjectEditBox:SetText(def.name)
			end
		end,
	}

	--------------------------------------------------------------------------------
	-- Outgoing mail
	--------------------------------------------------------------------------------

	Stub.sent = {}
	Stub.attached = nil

	GetMoney = function()
		return 10000
	end
	MailFrameTab_OnClick = function() end
	SendMailFrame = newFrame()
	SendMailFrame:Show()
	--[[
		The body is the Classic shape only: on 1.15.8 there is no SendMailBodyEditBox (it arrives
		with Dragonflight) and the body lives behind MailEditBox:GetEditBox(). Defining both would
		let a resolver knowing only the retail name pass here and fail in the game.
	]]
	SendMailNameEditBox = newFrame()
	SendMailSubjectEditBox = newFrame()
	SendMailBodyEditBox = nil

	local bodyBox = newFrame()
	MailEditBox = newFrame()
	rawset(MailEditBox, "GetEditBox", function()
		return bodyBox
	end)
	Stub.MailBodyBox = bodyBox
	ClearSendMail = function()
		Stub.attached = nil
	end
	GetSendMailItem = function(index)
		return index == 1 and Stub.attached or nil
	end

	--[[
		The item stays in the bag: the client removes it only when the server confirms, after
		MAIL_SUCCESS, and Features/Mail-Sender.lua depends on that order. Emptying the slot here
		would hide the race the post-delivery refresh must survive. Cases catch the bag up with
		SetBackpack and a BAG_UPDATE.
	]]
	SendMail = function(recipient, subject, body)
		table.insert(Stub.sent, { recipient = recipient, subject = subject, body = body, link = Stub.attached })
		Stub.attached = nil
	end

	--[[
		Timers never fire on their own: each is a deadline for something a case drives directly.
		FireTimers runs the waiting ones once, taking them off first so a timer that sets another
		(the Find Recipients lock does) cannot spin.
	]]
	Stub.timers = {}
	Stub.FireTimers = function()
		local pending = Stub.timers
		Stub.timers = {}
		for _, timer in ipairs(pending) do
			if timer.fn and not timer.canceled then
				timer.fn()
			end
		end
	end
	C_Timer = {
		NewTimer = function(delay, fn)
			local timer = { delay = delay, fn = fn, canceled = false }
			timer.Cancel = function()
				timer.canceled = true
			end
			table.insert(Stub.timers, timer)
			return timer
		end,
		After = function(delay, fn)
			table.insert(Stub.timers, { delay = delay, fn = fn, Cancel = function() end })
		end,
	}

	--------------------------------------------------------------------------------
	-- /who
	--------------------------------------------------------------------------------

	--[[
		SendWho only records; the case fires WHO_LIST_UPDATE when ready, as the real answer comes
		later. Stub.whoResults is the next answer, whatever was asked. Stub.whoTotal is how many the
		server says matched (nil: exactly what was sent); set it above the count for a capped query.
	]]
	Stub.whoQueries = {}
	Stub.whoResults = {}
	Stub.whoTotal = nil
	FriendsFrame = newFrame()
	rawset(FriendsFrame, "_name", "FriendsFrame")
	-- FrameXML's FriendsFrame_OnLoad registers this; opening on an answer is what the add-on suppresses.
	FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
	--[[
		On Forever's Retail-based UI the panel opened with both named frames deaf, so something else
		hears the answer. Anonymous on purpose: no name to look it up by.
	]]
	Stub.otherWhoListener = newFrame()
	Stub.otherWhoListener:RegisterEvent("WHO_LIST_UPDATE")
	HideUIPanel = function(panel)
		panel:Hide()
	end

	-- SendAddonMessage records into Stub.addonMessages rather than sending.
	Stub.addonMessages = {}
	C_ChatInfo = {
		RegisterAddonMessagePrefix = function()
			return true
		end,
		SendAddonMessage = function(prefix, message, channel, target)
			table.insert(Stub.addonMessages, {
				prefix = prefix,
				message = message,
				channel = channel,
				target = target,
			})
		end,
	}

	-- Units other than "player" come from Stub.unitsByToken, which a tooltip case seeds.
	UnitName = function(unit)
		if unit == "player" then
			return "Tester"
		end
		local person = Stub.unitsByToken and Stub.unitsByToken[unit]
		if person then
			return person.name, person.realm
		end
		return nil
	end
	UnitIsPlayer = function(unit)
		if unit == "player" then
			return true
		end
		local person = Stub.unitsByToken and Stub.unitsByToken[unit]
		return person ~= nil and person.isPlayer ~= false
	end

	-- enUS names for every area the zone tables name, so cases read zones in English.
	local AREA_NAMES = {
		[1] = "Dun Morogh",
		[3] = "Badlands",
		[4] = "Blasted Lands",
		[8] = "Swamp of Sorrows",
		[10] = "Duskwood",
		[11] = "Wetlands",
		[12] = "Elwynn Forest",
		[14] = "Durotar",
		[15] = "Dustwallow Marsh",
		[16] = "Azshara",
		[17] = "The Barrens",
		[28] = "Western Plaguelands",
		[33] = "Stranglethorn Vale",
		[36] = "Alterac Mountains",
		[38] = "Loch Modan",
		[40] = "Westfall",
		[41] = "Deadwind Pass",
		[44] = "Redridge Mountains",
		[45] = "Arathi Highlands",
		[46] = "Burning Steppes",
		[47] = "The Hinterlands",
		[51] = "Searing Gorge",
		[65] = "Dragonblight",
		[66] = "Zul'Drak",
		[67] = "The Storm Peaks",
		[85] = "Tirisfal Glades",
		[130] = "Silverpine Forest",
		[139] = "Eastern Plaguelands",
		[141] = "Teldrassil",
		[148] = "Darkshore",
		[210] = "Icecrown",
		[215] = "Mulgore",
		[267] = "Hillsbrad Foothills",
		[331] = "Ashenvale",
		[357] = "Feralas",
		[361] = "Felwood",
		[394] = "Grizzly Hills",
		[400] = "Thousand Needles",
		[405] = "Desolace",
		[406] = "Stonetalon Mountains",
		[440] = "Tanaris",
		[490] = "Un'Goro Crater",
		[495] = "Howling Fjord",
		[618] = "Winterspring",
		[1377] = "Silithus",
		[3430] = "Eversong Woods",
		[3433] = "Ghostlands",
		[3483] = "Hellfire Peninsula",
		[3518] = "Nagrand",
		[3519] = "Terokkar Forest",
		[3520] = "Shadowmoon Valley",
		[3521] = "Zangarmarsh",
		[3522] = "Blade's Edge Mountains",
		[3523] = "Netherstorm",
		[3524] = "Azuremyst Isle",
		[3525] = "Bloodmyst Isle",
		[3537] = "Borean Tundra",
		[3711] = "Sholazar Basin",
		[16004] = "Mount Hyjal",
		[16591] = "Riverglades",
		[16593] = "Zephras Isle",
		-- Two instances from the flavor folders' INSTANCE_AREAS, enough for Who:Placement to tell a dungeon from a capital.
		[1581] = "The Deadmines",
		[718] = "Wailing Caverns",
	}
	C_Map = {
		GetAreaInfo = function(areaID)
			return AREA_NAMES[areaID]
		end,
	}

	C_FriendList = {
		SendWho = function(filter)
			table.insert(Stub.whoQueries, filter)
		end,
		SetWhoToUi = function() end,
		GetNumWhoResults = function()
			return #Stub.whoResults, Stub.whoTotal or #Stub.whoResults
		end,
		GetWhoInfo = function(index)
			local person = Stub.whoResults[index]
			if not person then
				return nil
			end
			return {
				fullName = person.name,
				level = person.level,
				filename = person.class,
				classStr = person.class,
				raceStr = person.race,
				--[[
					Unset unless the case sets it: an unlisted area ranks as a capital or a dungeon
					(Who:PlacementRank) and keeps the search going, which only placement cases want.
				]]
				area = person.area,
				fullGuildName = person.guild,
			}
		end,
	}

	--[[
		Stub.guild nil means no guild. GetGuildRosterInfo's eleventh return is the class token, so
		a row with no class models the gap the reader treats as unreadable. GetGuildRosterLastOnline
		answers nothing for somebody online and four duration parts otherwise, never a total.
	]]
	Stub.guild = nil
	Stub.guildRosterRequests = 0
	IsInGuild = function()
		return Stub.guild ~= nil
	end
	Stub.guildName = nil
	GetGuildInfo = function(unit)
		if unit ~= "player" or Stub.guild == nil then
			return nil
		end
		return Stub.guildName or "Test Guild", "Member", 1
	end
	GetNumGuildMembers = function()
		return Stub.guild and #Stub.guild or 0
	end
	GetGuildRosterInfo = function(index)
		local member = Stub.guild and Stub.guild[index]
		if not member then
			return nil
		end
		return member.name,
			"Member",
			1,
			member.level,
			member.class and member.class:lower():gsub("^%l", string.upper) or "Warrior",
			member.zone, -- unset unless the case sets it, as /who's area above
			"",
			"",
			member.online or false,
			0,
			member.class
	end
	GetGuildRosterLastOnline = function(index)
		local member = Stub.guild and Stub.guild[index]
		if not member or member.online then
			return nil
		end
		return member.years or 0, member.months or 0, member.daysAgo or 0, member.hours or 0
	end
	C_GuildInfo = {
		GuildRoster = function()
			Stub.guildRosterRequests = Stub.guildRosterRequests + 1
		end,
	}

	SlashCmdList = {}

	--[[
		OpenToCategory reaches the protected OpenSettingsPanel(), which the client blocks in combat,
		so the stub raises ADDON_ACTION_BLOCKED rather than recording an open that never happens.
	]]
	Stub.settingsOpened = {}
	Settings = {
		OpenToCategory = function(categoryID)
			if Stub.inCombat then
				error("ADDON_ACTION_BLOCKED: OpenSettingsPanel()")
			end
			table.insert(Stub.settingsOpened, categoryID)
		end,
	}

	-- GetLocale's table errors on an unknown key, so a missing string fails the case that renders it.
	local locales = {}
	LibStub = function(name)
		if name == "AceLocale-3.0" then
			return {
				NewLocale = function(_, addon)
					locales[addon] = locales[addon] or {}
					return locales[addon]
				end,
				GetLocale = function(_, addon)
					return setmetatable({}, {
						__index = function(_, key)
							local value = locales[addon] and locales[addon][key]
							if value == nil then
								error(("no locale string for %q"):format(tostring(key)), 2)
							end
							return value
						end,
					})
				end,
			}
		end
		-- Catch-alls: the options files only need their file-scope LibStub calls to land somewhere.

		if
			name == "AceConfig-3.0"
			or name == "AceConfigDialog-3.0"
			or name == "AceConfigRegistry-3.0"
			or name == "AceGUI-3.0"
		then
			return newFrame()
		end
		error("no stub for LibStub library " .. tostring(name), 2)
	end
end

return Stub
