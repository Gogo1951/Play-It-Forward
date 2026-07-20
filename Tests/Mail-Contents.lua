--[[
	What a stranger actually receives.

	Fixed text now, not a setting: Locales/enUS.lua holds the subject and body and the
	options panel that edited them is gone. So what is worth checking is that the mailer
	sends that text, unchanged, and that its length is reported rather than discovered
	by a recipient.

	LENGTH IS ENFORCED. 500 characters, confirmed against a live mailbox: past it the
	mail arrives cut short, and what goes missing is the end -- the sign-off first. This
	failing is the only thing standing between an edit to the copy and a stranger
	receiving three and a half paragraphs.
]]

local Harness = require("Harness")
local test, check, equal = Harness.test, Harness.check, Harness.equal

local function load()
	return Harness.LoadAddon(ADDON_ROOT)
end

local SUBJECT_MAX = 31
local BODY_MAX = 500

--------------------------------------------------------------------------------

test("the subject is fixed text, not a setting", function()
	local ns = load()

	equal(ns.Distributor:BuildSubject(), "Play It Forward!", "the shipped subject")
	equal(ns.db.profile.subject, nil, "and nothing saved behind it")
end)

test("the body is fixed text, not a setting", function()
	local ns = load()

	equal(ns.Distributor:BuildBody(), ns.L["MAIL_BODY"], "sent exactly as written")
	equal(ns.db.profile.message, nil, "nothing saved behind it")
	equal(ns.db.profile.appendMessage, nil, "no toggle for including it")
	equal(ns.db.profile.appendLeftoverNote, nil, "and no disenchant note")
end)

--[[
	A value left in an old profile must not come back. This is the whole reason the text
	moved out of saved variables rather than the panel merely being hidden.
]]
test("a subject and body left in an old profile are ignored", function()
	local ns = load()
	ns.db.profile.subject = "Something Else"
	ns.db.profile.message = "Some other body entirely."

	equal(ns.Distributor:BuildSubject(), "Play It Forward!", "the fixed subject still wins")
	equal(ns.Distributor:BuildBody(), ns.L["MAIL_BODY"], "and the fixed body")
end)

test("the subject fits the client's subject box", function()
	local ns = load()
	local subject = ns.Distributor:BuildSubject()

	check(#subject <= SUBJECT_MAX, ("%d chars, cap %d: %q"):format(#subject, SUBJECT_MAX, subject))
end)

test("the body fits what a mailbox will carry", function()
	local ns = load()
	local body = ns.Distributor:BuildBody()

	check(#body <= BODY_MAX, ("%d chars, cap %d -- the sign-off is what gets cut"):format(#body, BODY_MAX))
end)

--[[
	Headroom, not just a pass. Sitting four characters under the cap means the next
	wording change breaks it, and the person making that change is reading the copy
	rather than counting it.
]]
test("the body has room for an edit", function()
	local ns = load()
	local body = ns.Distributor:BuildBody()

	check(#body <= BODY_MAX - 50, ("%d chars leaves %d spare"):format(#body, BODY_MAX - #body))
end)

test("the body is four paragraphs separated by blank lines", function()
	local ns = load()
	local paragraphs = {}
	for part in (ns.Distributor:BuildBody() .. "\n\n"):gmatch("(.-)\n\n") do
		if part ~= "" then
			paragraphs[#paragraphs + 1] = part
		end
	end

	equal(#paragraphs, 4, "four paragraphs")
	check(paragraphs[1]:find("^Just a little something"), "opens by saying it is a gift")
	check(paragraphs[2]:find("No strings attached"), "then what to do with it")
	check(paragraphs[3]:find("CurseForge and Wago"), "then where the add-on lives")
	equal(paragraphs[4], "Happy adventuring!", "signs off")
end)

test("the text carries no display escapes", function()
	local ns = load()

	--[[
		Mail is plain text. A color escape or an item link arrives as literal pipe
		characters, and nothing in the send path strips them.
	]]
	check(not ns.Distributor:BuildSubject():find("|", 1, true), "subject carries no pipes")
	check(not ns.Distributor:BuildBody():find("|", 1, true), "body carries no pipes")
end)

test("apostrophes are the plain ASCII kind", function()
	local ns = load()
	local body = ns.Distributor:BuildBody()

	--[[
		Checked by character rather than by word. Pinning a specific contraction ties this
		case to the copy, and the copy is the thing most likely to change.
	]]
	check(not body:find("\226\128\153"), "no curly apostrophes")
	check(body:find("'", 1, true), "and the straight ones are there")
end)
