--[[
	Enough of the WoW client to load the add-on outside the game.

	This is deliberately not a mock framework. It is the smallest set of globals that
	lets the real files run unmodified, because a test that exercises a paraphrase of
	the code proves nothing about the code. Every stub here answers in the shape the
	real API answers in: GetItemInfo returns its 14 positional values in the client's
	order, GetContainerItemInfo returns the C_Container table, and an item link carries
	a real suffix field so ns.ItemSuffixID has something to parse.

	Run with: lua Tests/Run.lua
]]

local Stub = {}

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

--[[
	One stub object answers to anything, because a frame key is either a method or a
	child widget and there is no way to tell which from the name. Returning a callable
	table covers both: f:SetPoint() calls it, f.CloseButton:SetScript() indexes it.

	Methods that feed arithmetic have to answer with a number rather than a table, so
	the few the add-on does that with are named here. A missing name shows up as an
	"attempt to perform arithmetic" the moment it is used, never as a wrong result.
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
}

local function newStub(numeric)
	local t = {}
	return setmetatable(t, {
		__index = function(self, key)
			--[[
				SetText is the one call that is kept rather than swallowed. The status line
				is half of what the window says for itself, so a test that could only see
				whether the frame is up would pass on a window reporting the wrong count.
			]]
			if key == "SetText" then
				local setter = function(this, text)
					rawset(this, "shownText", text)
					return this
				end
				rawset(self, key, setter)
				return setter
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

--[[
	Shown state is real. It is the single thing every test in Tests/Mailbox-Gate.lua
	asserts on, so it cannot come from the catch-all above: a stub that answers every
	call truthily would report the window open in exactly the case the fix is about.
]]
local function newFrame()
	local f = newStub()
	local shown = false
	rawset(f, "Show", function()
		shown = true
	end)
	rawset(f, "Hide", function()
		shown = false
	end)
	rawset(f, "IsShown", function()
		return shown
	end)
	rawset(f, "IsVisible", function()
		return shown
	end)

	--[[
		Enabled state is real for the same reason shown state is: the Find Recipients
		button locking itself for the length of the /who throttle is a thing a case
		asserts on, and the catch-all above would report every button as live.
	]]
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
	rawset(f, "hooks", {})
	rawset(f, "HookScript", function(self, script, fn)
		self.hooks[script] = fn
		return self
	end)

	--[[
		Event registration is real rather than swallowed: the /who code unregisters
		WHO_LIST_UPDATE from the Blizzard frames for the life of a query, and a catch-all
		IsEventRegistered answering truthily would hide both halves of that contract.
	]]
	local registered = {}
	rawset(f, "RegisterEvent", function(_, event)
		registered[event] = true
	end)
	rawset(f, "UnregisterEvent", function(_, event)
		registered[event] = nil
	end)
	rawset(f, "IsEventRegistered", function(_, event)
		return registered[event] == true
	end)
	return f
end

Stub.NewFrame = newFrame

--------------------------------------------------------------------------------
-- Items and bags
--------------------------------------------------------------------------------

Stub.itemsByLink = {}
Stub.bags = {}

--[[
	Where generated item ids start, and why it is up here rather than at 1.

	An id is not just a number to a fixture: Features/Scan-Bags.lua looks every scanned
	item up in the consumable index, so a generated id that collides with a real row in
	Data/Scan-Potions.lua or Data/Scan-Food.lua turns a green chest into a bottle of
	water. That happened. Ids began at 20000, 20074 is a real consumable, and the counter
	ran on across the whole suite -- so a case that passed alone failed once enough
	earlier cases had been added to push the counter past it. A test whose result depends
	on how many tests ran before it is worse than a failing one.

	Nothing in this add-on's data comes near seven figures, so nothing here can collide
	with a real row however long the suite runs.

	The counter deliberately does NOT reset per Install. Fixtures are built as arguments
	-- readyToDistribute({ cloak() }, ...) -- so they exist before the load inside that
	call, and a counter that restarted would hand a later fixture the same id, the same
	link, and overwrite the earlier one in the registry below. Ids that only ever go up
	are what makes a link a stable key.
]]
local ID_BASE = 9000000
local nextItemID = ID_BASE

--[[
	One item, in the shape the client would report it. Defaults describe a plain
	bind-on-equip green so a fixture only states the fields it is actually about.

	tooltipLines is separate from stats on purpose: stats is what GetItemStats answers,
	tooltipLines is what the item renders as, and a random-suffix roll has all of its
	stats in the second and none in the first. That split is the difference between an
	item with no stats and one whose stats could not be read, which is a distinction the
	matcher makes and the reason Features/Scan-Tooltip.lua exists.
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
		sellPrice = fields.sellPrice or 0, -- copper; GetItemInfo's 11th value
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

-- Lay out the backpack. Bags 1-4 stay empty, which is what an unbagged alt looks like.
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

	--[[
		Bags start empty every load, so a case that never lays one out sees an empty
		backpack rather than whatever the case before it left behind.

		itemsByLink is deliberately not cleared. Fixtures are built as arguments, before
		the load they are passed into, so wiping the registry here would orphan the very
		items the case is about -- their links would resolve to nothing and every one
		would scan as NOT_CACHED.
	]]
	Stub.bags = {}

	WOW_PROJECT_CLASSIC = 2
	WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
	WOW_PROJECT_ID = WOW_PROJECT_CLASSIC

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

	--[[
		A clock the tests drive. It starts well past zero so the /who throttle, which
		compares against a lastSent of 0, does not reject the very first query of a case
		as too soon. Advance it to get a second query out.
	]]
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
	}
	LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_MALE

	--[[
		Alliance, so Matcher's absent-class filter has something to do: on Era it drops
		shamans for this faction and death knights for the whole client. A stub that
		reported no faction would memoize nothing and quietly test the unfiltered list.
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

	--[[
		Resting gates the Given Away broadcast and its tooltip block, so it starts true: the sharing
		cases are about sharing, not about standing in the right place. A case that wants the gate
		shut sets Stub.resting = false, which is the raid and open-world state.
	]]
	Stub.resting = true
	IsResting = function()
		return Stub.resting
	end
	GetRealmName = function()
		return "Test"
	end
	GetNormalizedRealmName = GetRealmName

	--[[
		A named frame lands in _G, because that is how Features/Scan-Tooltip.lua reads
		its scanning tooltip back: it indexes _G["PlayItForwardScanTooltipTextLeft"..i]
		rather than holding the font strings. A GameTooltip additionally renders a
		fixture's tooltipLines, so the suffix-parsing path can be driven end to end
		instead of stubbed at the answer.
	]]
	CreateFrame = function(kind, name, _, _)
		local frame = newFrame()
		if name then
			_G[name] = frame
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

	GetLocale = function()
		return "enUS"
	end
	-- The header every diagnostics report opens with, in the client's four-value shape.
	GetBuildInfo = function()
		return "1.15.8", "67156", "Jan 1 2026", 11508
	end

	--[[
		The client's own stat names. Features/Scan-Tooltip.lua reads a "+N Something"
		line by looking Something up against these, which is what keeps it locale-safe,
		so a stub that defined only a few would test a name table narrower than the real
		one. Every key Data/Scan-Stats.lua uses is here.
	]]
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

	--[[
		The client's mail refusals, as UI_ERROR_MESSAGE delivers them. Real strings, so
		Features/Mail-Sender.lua matches against the same text the client sends rather
		than a paraphrase; ERR_MAIL_DATABASE_ERROR is the one observed on 1.15.8.
	]]
	ERR_MAIL_DATABASE_ERROR = "Internal mail database error!"
	ERR_MAIL_TARGET_NOT_FOUND = "Player not found."
	ERR_MAIL_TO_SELF = "You cannot send mail to yourself."
	ERR_MAIL_RECEPIENT_CANT_RECEIVE_MAIL = "Recipient cannot receive mail."

	--[[
		A cold item cache answers nil, exactly as the client does for an item it has not
		resolved yet. Setting cached = false on a fixture is how a test reaches the
		scanner's NOT_CACHED branch, which is otherwise unreachable outside the game.
	]]
	GetItemInfo = function(link)
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

	--[[
		True when the item has an equip slot, the way the client answers it. Generosity:RecordSend
		leans on this to count item level for gear only, so a consumable (equipLoc "") must come
		back false rather than being told apart some other way.
	]]
	IsEquippableItem = function(link)
		local def = Stub.itemsByLink[link]
		return def ~= nil and def.equipLoc ~= nil and def.equipLoc ~= ""
	end

	GetItemStats = function(link)
		local def = Stub.itemsByLink[link]
		return def and def.stats or {}
	end

	C_Item = {
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
			Attaches to the letter. Two things the real call does that matter here.

			It does not empty the slot: the item is reserved by the open mail and the bag
			only reports it gone once the server confirms the send.

			And it writes the item's name into an empty subject box, which is why the mail
			panel showed "Lesser Healing Potion (2)" as a subject nobody typed. Anything
			filling that box has to do it after this, and modelling it here is what lets a
			case prove the ordering rather than assume it.
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
		The panel's own boxes, which the sender fills so the player can see what is going.

		The body is deliberately the CLASSIC shape and only that. On 1.15.8 there is no
		SendMailBodyEditBox -- that name arrives with Dragonflight -- and the body lives
		behind MailEditBox:GetEditBox(). Defining both here would let a resolver that only
		knows the retail name pass a test it fails in the game, which is exactly what
		happened: To and Subject filled, the body stayed empty.
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
		THE ITEM STAYS IN THE BAG, AND THAT IS THE POINT.

		The client removes it only when the server confirms, which lands after
		MAIL_SUCCESS -- Features/Mail-Sender.lua depends on that ordering and says so in
		as many words. So a test firing MAIL_SUCCESS sees exactly what the add-on sees at
		that instant: a delivered item still sitting in its slot. Emptying the slot here
		would quietly repair the race the post-delivery refresh has to survive.

		Tests/Mailbox-Gate.lua drives the bag catching up by hand, with SetBackpack and a
		BAG_UPDATE, which is the client's real second step.
	]]
	SendMail = function(recipient, subject, body)
		table.insert(Stub.sent, { recipient = recipient, subject = subject, body = body, link = Stub.attached })
		Stub.attached = nil
	end

	--[[
		Timers never fire on their own. Every one the add-on sets is a deadline for
		something a test drives directly, so a timer that ran would race the case rather
		than support it; Stub.FireTimers is there for a case that wants them run.
	]]
	Stub.timers = {}
	--[[
		Runs every timer waiting, once. Taken off the list first, so a timer that sets
		another -- the Find Recipients lock does, on every press -- does not run inside
		this call and spin.
	]]
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
		Queries go in, seeded results come out. SendWho only records: the answer arrives
		on WHO_LIST_UPDATE, which the case fires when it is ready, because that is the
		shape of the real thing and the add-on's stepper is built around the gap.

		Stub.whoResults is what the *next* answer will contain, whatever was asked. A
		case that cares which zone was queried reads Stub.whoQueries.
	]]
	Stub.whoQueries = {}
	Stub.whoResults = {}
	FriendsFrame = newFrame()
	-- FrameXML's FriendsFrame_OnLoad registers this; opening on an answer is what the add-on suppresses.
	FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
	HideUIPanel = function(panel)
		panel:Hide()
	end

	--[[
		Addon messaging for the Given Away broadcast. RegisterAddonMessagePrefix answers true, as the
		client does when the prefix table has room; SendAddonMessage records rather than sends, so a
		case can read Stub.addonMessages to see what went over YELL and with which prefix.
	]]
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

	--[[
		Unit reads for the tooltip block. The player is "Tester" on realm "Test"; other units are
		looked up in Stub.unitsByToken, which a tooltip case seeds. Absent that table, only "player"
		resolves, which is all the loaded files touch at load time.
	]]
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

	C_FriendList = {
		SendWho = function(filter)
			table.insert(Stub.whoQueries, filter)
		end,
		SetWhoToUi = function() end,
		GetNumWhoResults = function()
			return #Stub.whoResults
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
				area = person.area or "Somewhere",
			}
		end,
	}

	--[[
		AceLocale, reduced to what the add-on asks of it. GetLocale hands back a table
		that errors on an unknown key rather than answering nil, so a status line
		referring to a string nobody added fails in the test that renders it instead of
		printing "nil" in the game.
	]]
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
		error("no stub for LibStub library " .. tostring(name), 2)
	end
end

return Stub
