--[[
	Who the guild roster hands over, and who it holds back.

	The bug: your own characters were mailed your own gear. The own-alt check builds its keys
	as "Character-Realm" from UnitName and AceDB's profileKeys, but the roster names somebody
	on your own realm with a bare "Gogowarrior" -- the suffix appears only for a character from
	another realm in the cluster. A bare name matched no key, so the check passed your own alts
	straight through to the pool, and paying it forward to yourself is not paying it forward.

	A bare name means "on my realm", which is the client's own convention, so both sides are
	compared through ns.QualifyPlayerName rather than as raw strings.
]]

local Harness = require("Harness")
local Stub = Harness.Stub
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

-- Online, so the activity window answers yes without a case having to say so.
local function member(name, overrides)
	local row = { name = name, level = 19, class = "WARRIOR", online = true }
	for key, value in pairs(overrides or {}) do
		row[key] = value
	end
	return row
end

-- Failures name who got through, since "expected 0, got 1" alone does not say which rule leaked.
local function namesFrom(list)
	local out = {}
	for _, person in ipairs(list) do
		out[#out + 1] = tostring(person.name)
	end
	return #out > 0 and table.concat(out, ", ") or "nobody"
end

--------------------------------------------------------------------------------

test("your own character is filtered whichever way the roster spells it", function()
	local ns = load()
	-- The player is Tester on realm Test. Same character, both forms the roster can return.
	Stub.guild = { member("Tester"), member("Tester-Test") }

	local found = ns.Guild:Read()
	equal(#found, 0, "you are not a recipient, but through came: " .. namesFrom(found))
	equal(ns.Guild:Stats().ownAlts, 2, "both spellings counted as your own")
end)

test("an alt that has run the add-on is filtered under a bare roster name", function()
	local ns = load()
	-- AceDB writes profileKeys as "Character - Realm", spaces and all.
	ns.db.sv.profileKeys["Gogowarrior - Test"] = true
	Stub.guild = { member("Gogowarrior") }

	local found = ns.Guild:Read()
	equal(#found, 0, "your own alt is not a stranger to mail gear to, got: " .. namesFrom(found))
	equal(ns.Guild:Stats().ownAlts, 1, "counted as your own")
end)

--[[
	The other half of the rule: over-matching would empty the roster, which reads as an
	inactive guild rather than as a broken filter.
]]
test("a real guildmate still comes through", function()
	local ns = load()
	Stub.guild = { member("Someone") }

	local found = ns.Guild:Read()
	equal(#found, 1, "the guildmate is a candidate")
	equal(found[1].name, "Someone", "under the name the roster gave, which is the address")
	check(found[1].guild, "flagged as a guildmate for the ranking tiebreak")
	equal(ns.Guild:Stats().ownAlts, 0, "and not mistaken for one of yours")
end)

--[[
	A guildmate on another realm in the cluster keeps their suffix all the way to SendMail:
	the qualified form is the address there, not a comparison artifact.
]]
test("a connected-realm guildmate keeps the suffix the roster gave", function()
	local ns = load()
	Stub.guild = { member("Someone-Otherrealm") }

	local found = ns.Guild:Read()
	equal(#found, 1, "still a candidate")
	equal(found[1].name, "Someone-Otherrealm", "suffix intact")
end)
