--[[
	Reading stats off a rendered tooltip.

	Tooltip:StatsFromLines is pure -- no tooltip, no item cache, no client state -- so
	the real lines a client produced can be fed straight to it. Every case below is a
	line copied out of a diagnostics dump from 1.15.8 rather than one written from
	memory, because the whole class of bug here is "the client words it differently
	than we guessed".
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Line 1 of a tooltip is the item name and is always skipped.
local function parse(ns, ...)
	return ns.Tooltip:StatsFromLines({ "Item Name", ... })
end

--------------------------------------------------------------------------------

test("a plain stat line still parses", function()
	local ns = load()
	local stats = parse(ns, "+9 Intellect", "+4 Spirit")

	equal(stats.INTELLECT, 9, "intellect")
	equal(stats.SPIRIT, 4, "spirit")
end)

--[[
	The color-wrapped, newline-terminated form a random suffix arrives in. Called out
	as load-bearing in Tooltip-Scanner.lua: without the cleanup every rolled green reads
	as statless.
]]
test("a color-wrapped suffix line still parses", function()
	local ns = load()
	local stats = parse(ns, "|cffffffff+15 Intellect|r\n")

	equal(stats.INTELLECT, 15, "intellect off a wrapped line")
end)

--[[
	THE BUG. "Battlesmasher of Nature's Wrath" on 1.15.8 rendered "+6 Nature Spell
	Damage" and the whole item parsed to nothing, so it was held back as unreadable --
	a one-hander a druid would have taken.

	The name table only knew five stats: strength, agility, stamina, intellect, spirit.
	Every other stat the client can write as "+N Something" fell through it, and the
	equip-effect patterns underneath only match the "increases ... by N" wording, never
	the "+N" one.
]]
test("a school damage line parses", function()
	local ns = load()

	equal(parse(ns, "+6 Nature Spell Damage").NATURE, 6, "nature")
	equal(parse(ns, "+11 Fire Spell Damage").FIRE, 11, "fire")
	equal(parse(ns, "+7 Arcane Spell Damage").ARCANE, 7, "arcane")
	equal(parse(ns, "+9 Frost Spell Damage").FROST, 9, "frost")
	equal(parse(ns, "+8 Shadow Spell Damage").SHADOW, 8, "shadow")
	equal(parse(ns, "+5 Holy Spell Damage").HOLY, 5, "holy")
end)

--[[
	Every stat with a localized _SHORT global should read off a "+N" line, not just the
	five that were listed by hand. The client owns those strings, so deriving the table
	from Data/Stat-Map.lua is what keeps it locale-safe and stops it drifting.
]]
test("stats beyond the core five parse from a plus line", function()
	local ns = load()

	equal(parse(ns, "+26 Attack Power").ATTACK_POWER, 26, "attack power")
	equal(parse(ns, "+12 Spell Damage").SPELL_DAMAGE, 12, "spell damage")
	equal(parse(ns, "+8 Healing").HEALING, 8, "healing")
end)

test("an equip-effect line still parses", function()
	local ns = load()
	local stats = parse(ns, "Equip: Increases damage done by Fire spells and effects by up to 11.")

	equal(stats.FIRE, 11, "fire off an equip line")
end)

test("two lines of the same stat add up", function()
	local ns = load()
	local stats = parse(ns, "+4 Intellect", "+3 Intellect")

	equal(stats.INTELLECT, 7, "summed")
end)

--------------------------------------------------------------------------------
-- Reporting what did not parse
--------------------------------------------------------------------------------

--[[
	A "+N Something" line is a stat line whatever the Something is, so one that does not
	resolve to a token is a gap in the name table rather than a line to ignore. Handing
	those back is what turns the next one of these into a one-line report instead of a
	silently unreadable item.
]]
test("an unrecognized plus line is reported rather than dropped", function()
	local ns = load()
	local stats, unread = ns.Tooltip:StatsFromLines({ "Item Name", "+9 Intellect", "+3 Mystery Stat" })

	equal(stats.INTELLECT, 9, "the readable stat still parsed")
	equal(#unread, 1, "one line went unread")
	check(unread[1]:find("Mystery Stat"), "and it says which: " .. tostring(unread[1]))
end)

test("nothing is reported when every line parsed", function()
	local ns = load()
	local _, unread = ns.Tooltip:StatsFromLines({ "Item Name", "+9 Intellect", "Binds when equipped" })

	equal(#unread, 0, "no unread stat lines")
end)
