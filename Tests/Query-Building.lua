--[[
	Getting a whole bag's worth of recipients out of one press.

	One query per zone was leaving fifteen-odd presses on the table for a bag that is
	usually one tight level band -- somebody who just finished a boost with five items
	for levels 15-25. Every zone that band touches goes in one query now, and the
	character budget is the real constraint: chunking exists because one query is not
	always enough.

	CLASS FILTERS ARE ONE PER QUERY, NEVER A LIST. The client honors a single c-"..."
	and quietly drops the rest of an OR'd set -- observed live on 1.15.9 (2026-07-23),
	where a Warrior/Paladin/Rogue query answered with paladins alone, the first filter
	alphabetically. A zoned query carries the filter only when exactly one class is
	wanted; otherwise the zones do the narrowing and the class filter is spent one
	class per query in the widened stage.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

--[[
	Send every planned query and hand back the raw filter strings. Every answer reads as
	capped: one under the cap ends the search for its levels, and these cases are about the
	whole ladder.
]]
local function drain(ns, limit)
	local out = {}
	Stub.whoTotal = 999
	while ns.Who:Remaining() > 0 and #out < (limit or 40) do
		ns.Who:Step(function() end)
		out[#out + 1] = Stub.whoQueries[#Stub.whoQueries]
		Stub.now = Stub.now + 60
		ns.fire("WHO_LIST_UPDATE")
	end
	return out
end

local function countOf(text, needle)
	local n = 0
	for _ in text:gmatch(needle) do
		n = n + 1
	end
	return n
end

local function firstZoned(queries)
	for _, query in ipairs(queries) do
		if query:find('z%-"') then
			return query
		end
	end
end

--------------------------------------------------------------------------------

test("every zone for a band goes in one query", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })

	local first = firstZoned(drain(ns)) or ""
	check(countOf(first, 'z%-"') > 1, "several zones in one query: " .. first)
	check(first:find("16%-19"), "carrying the band's levels")
end)

--[[
	The invariant pinned to the observed bug: a query listing several classes silently
	narrows to one, so no query may ever carry more than one class filter.
]]
test("no query ever carries more than one class filter", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })

	for _, query in ipairs(drain(ns)) do
		check(countOf(query, 'c%-"') <= 1, "at most one class filter: " .. query)
	end
end)

test("each wanted class is asked for by name, one query apiece", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })

	local queries = drain(ns)
	local zoned = firstZoned(queries) or ""
	check(not zoned:find('c%-"'), "the zoned press is unfiltered, zones do the narrowing: " .. zoned)

	local askedWarrior, askedPaladin, askedMage = false, false, false
	for _, query in ipairs(queries) do
		askedWarrior = askedWarrior or query:find('c%-"Warrior"') ~= nil
		askedPaladin = askedPaladin or query:find('c%-"Paladin"') ~= nil
		askedMage = askedMage or query:find('c%-"Mage"') ~= nil
	end
	check(askedWarrior, "warriors asked for by name")
	check(askedPaladin, "paladins asked for by name")
	check(not askedMage, "and nobody who cannot receive anything")
end)

--[[
	In German, French, Spanish, Portuguese and Russian a woman's class name is its own word
	("Kriegerin" beside "Krieger"). If /who matches the name a character displays, a filter in
	the male form never finds her, so a single-class query is asked again in the female form,
	straight after. Unverified in game: needs a /who on such a client.
]]
local function loadWithFemaleWarrior()
	return Harness.LoadAddon(ADDON_ROOT, function()
		local female = {}
		for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			female[token] = name
		end
		female.WARRIOR = "Kriegerin"
		LOCALIZED_CLASS_NAMES_FEMALE = female
	end)
end

local function planned(ns)
	local out = {}
	for _, attempt in ipairs(ns.Who.plan) do
		out[#out + 1] = attempt.query
	end
	return out
end

local function indexOf(queries, pattern)
	for index, query in ipairs(queries) do
		if query:find(pattern) then
			return index
		end
	end
end

test("a class with its own female name is asked in both forms, one after the other", function()
	local ns = loadWithFemaleWarrior()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })
	local queries = planned(ns)

	local male = indexOf(queries, '^16%-19 c%-"Warrior"$')
	check(male ~= nil, "the male form is asked")
	equal(male and queries[male + 1], '16-19 c-"Kriegerin"', "and the female form straight after")
	for _, query in ipairs(queries) do
		check(countOf(query, 'c%-"') <= 1, "still one class filter per query: " .. query)
	end
	equal(countOf(table.concat(queries, "|"), 'c%-"Paladin"'), 1, "a class whose names match is asked once")
end)

test("a locale whose class names all match asks each class once", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })
	local all = table.concat(planned(ns), "|")
	equal(countOf(all, 'c%-"Warrior"'), 1, "warriors once")
	equal(countOf(all, 'c%-"Paladin"'), 1, "paladins once")
end)

test("a warrior found under either form ends both", function()
	local ns = loadWithFemaleWarrior()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })
	ns.Who:Prune({ { lo = 16, hi = 19, classes = { "PALADIN" } } })
	local all = table.concat(planned(ns), "|")
	check(not all:find('c%-"Warrior"'), "the male form is dropped: " .. all)
	check(not all:find('c%-"Kriegerin"'), "and so is the female: " .. all)
end)

test("an answer under the cap for one form leaves the other form planned", function()
	local ns = loadWithFemaleWarrior()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })
	local male
	for _, attempt in ipairs(ns.Who.plan) do
		if attempt.query == '16-19 c-"Warrior"' then
			male = attempt
		end
	end
	ns.Who:Exhausted(male)
	check(indexOf(planned(ns), 'c%-"Kriegerin"') ~= nil, "the female form is still to be asked")

	local bare
	for _, attempt in ipairs(ns.Who.plan) do
		if attempt.query == "16-19" then
			bare = attempt
		end
	end
	ns.Who:Exhausted(bare)
	check(indexOf(planned(ns), 'c%-"Kriegerin"') == nil, "but an answer for everybody ends it")
end)

--[[
	A filter naming every class the client has excludes nobody, so it is pure length --
	and length is the one budget a query has.
]]
test("no class filter when every class is wanted", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = ns.Matcher:Classes() } })

	for _, query in ipairs(drain(ns)) do
		check(not query:find('c%-"'), "no class filter at all: " .. query)
	end
end)

--[[
	/who is sent as a chat filter string and there is a limit on how long one can be.
	Going over it is not a truncated result, it is a query the server does not answer.
]]
test("no query exceeds the filter length budget", function()
	local ns = load()
	ns.Who:Plan({ { lo = 1, hi = 60, classes = { "WARRIOR", "PALADIN", "PRIEST", "MAGE" } } })

	for _, query in ipairs(drain(ns)) do
		check(#query <= ns.Who.FILTER_MAX, ("%d chars, budget %d: %s"):format(#query, ns.Who.FILTER_MAX, query))
	end
end)

test("a wide band is split rather than truncated", function()
	local ns = load()
	ns.Who:Plan({ { lo = 1, hi = 60, classes = { "WARRIOR" } } })

	local queries = drain(ns)
	local zoned = 0
	for _, query in ipairs(queries) do
		if query:find('z%-"') then
			zoned = zoned + 1
		end
	end
	check(zoned > 1, "more than one zone query, so the list was chunked not dropped")
end)

--[[
	The typical bag: one tight band, a couple of classes. This is the case the whole
	rewrite is for.
]]
test("a single tight band is one zone query", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })

	local queries = drain(ns)
	local zoned = 0
	for _, query in ipairs(queries) do
		if query:find('z%-"') then
			zoned = zoned + 1
		end
	end
	equal(zoned, 1, "one press covers every zone for the band")
end)

--[[
	The ladder, in order. The levelling zones first, because somebody out there at their own
	level is who a gift is for; then bare levels, the fallback that fills a press but reaches
	the capitals and dungeons too; then a class at a time, for a class the cap crowded out.
]]
test("the search asks the zones first, then falls back", function()
	local ns = load()
	ns.Who:Plan({ { lo = 16, hi = 19, classes = { "WARRIOR", "PALADIN" } } })

	local queries = drain(ns)
	check(queries[1]:find('z%-"') ~= nil, "starts in the zones: " .. queries[1])
	local bare
	for index, query in ipairs(queries) do
		if query == "16-19" then
			bare = index
		end
	end
	check(bare ~= nil, "bare levels are asked")
	for index = 1, (bare or 1) - 1 do
		check(queries[index]:find('z%-"') ~= nil, "only zones before them: " .. queries[index])
	end
	local last = queries[#queries]
	check(last:find('c%-"') and not last:find('z%-"'), "and it ends on a class by name: " .. last)
end)

test("bands still take turns", function()
	local ns = load()
	ns.Who:Plan({
		{ lo = 16, hi = 19, classes = { "WARRIOR" } },
		{ lo = 45, hi = 47, classes = { "MAGE" } },
	})

	local queries = drain(ns)
	check(queries[1]:find("16%-19"), "first press on the first band")
	check(queries[2]:find("45%-47"), "second press on the other: " .. queries[2])
end)

--------------------------------------------------------------------------------
-- End to end
--------------------------------------------------------------------------------

test("a bag of one level band is searched in a single press", function()
	local ns = load()
	local robe = Stub.Item({
		name = "Ivycloth Robe",
		quality = 2,
		reqLevel = 20,
		itemLevel = 24,
		equipLoc = "INVTYPE_CHEST",
		classID = 4,
		subclassID = 1,
		bindType = 2,
		stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
	})
	Stub.SetBackpack({ robe, robe, robe })
	ns.fire("MAIL_SHOW")

	Stub.whoResults = {
		{ name = "Mage1", level = 18, class = "MAGE" },
		{ name = "Mage2", level = 19, class = "MAGE" },
		{ name = "Priest1", level = 18, class = "PRIEST" },
	}
	ns.UI:FindRecipients()
	ns.fire("WHO_LIST_UPDATE")

	equal(#Stub.whoQueries, 1, "one press")
	equal(ns.Who:Remaining(), 0, "and the search is done")
	for _, item in ipairs(ns.UI:Items()) do
		check(item.recipient ~= nil, item.name .. " found somebody")
	end
end)

--[[
	The class filters still come from what is in the bag -- one per query, in the widened
	stage. Cloth with Intellect on it is nobody's business but the casters', so a warrior
	is never asked for by name anywhere in its plan.
]]
test("the plan's class queries come from the bag's items", function()
	local ns = load()
	Stub.SetBackpack({
		Stub.Item({
			name = "Ivycloth Robe",
			quality = 2,
			reqLevel = 20,
			itemLevel = 24,
			equipLoc = "INVTYPE_CHEST",
			classID = 4,
			subclassID = 1,
			bindType = 2,
			stats = { ITEM_MOD_INTELLECT_SHORT = 9 },
		}),
	})
	ns.fire("MAIL_SHOW")
	Stub.whoTotal = 999
	ns.UI:FindRecipients()

	local askedMage, askedWarrior, askedRogue = false, false, false
	while ns.Who:Remaining() > 0 and #Stub.whoQueries < 40 do
		Stub.now = Stub.now + 60
		ns.fire("WHO_LIST_UPDATE")
		ns.UI:FindRecipients()
	end
	for _, query in ipairs(Stub.whoQueries) do
		check(countOf(query, 'c%-"') <= 1, "at most one class filter: " .. query)
		askedMage = askedMage or query:find('c%-"Mage"') ~= nil
		askedWarrior = askedWarrior or query:find('c%-"Warrior"') ~= nil
		askedRogue = askedRogue or query:find('c%-"Rogue"') ~= nil
	end
	check(askedMage, "mages asked for by name somewhere in the plan")
	check(not askedWarrior, "warriors never asked for")
	check(not askedRogue, "nor rogues")
end)
