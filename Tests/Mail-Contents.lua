--[[
	What a stranger actually receives.

	The stock copy lives in Locales/enUS.lua, and the player may replace either half on the
	Mail Message Text panel. So what is worth checking is that the mailer sends the stock text
	unchanged until they do, and sends their words once they have, with the one-line
	footer under them so the add-on is still named.

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

test("an untouched profile sends the stock subject", function()
	local ns = load()

	equal(ns.Distributor:BuildSubject(), "Play It Forward!", "the shipped subject")
	equal(ns.db.profile.mailSubject, "", "and nothing custom saved behind it")
end)

test("an untouched profile sends the stock body", function()
	local ns = load()

	equal(ns.Distributor:BuildBody(), ns.L["MAIL_BODY"], "the shipped body")
	equal(ns.db.profile.mailBody, "", "nothing custom saved behind it")
	equal(ns.db.profile.appendMessage, nil, "no toggle for including it")
	equal(ns.db.profile.appendLeftoverNote, nil, "and no disenchant note")
end)

--[[
	A value left by the earlier editor must not come back. The panel saves under new
	keys, so what a player wrote years ago and forgot does not reach a stranger now.
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

--------------------------------------------------------------------------------
-- Custom copy
--------------------------------------------------------------------------------

test("a custom subject is sent as written", function()
	local ns = load()
	ns.db.profile.mailSubject = "A gift from Gogo"

	equal(ns.Distributor:BuildSubject(), "A gift from Gogo", "the player's subject")
	equal(ns.Distributor:BuildBody(), ns.L["MAIL_BODY"], "and the stock body, untouched")
end)

--[[
	THE BRANDING IS NOT OPTIONAL. The stock body explains the add-on itself; a rewritten one
	loses that paragraph, so the short footer goes under it.
]]
test("a custom body ends with the footer", function()
	local ns = load()
	ns.db.profile.mailBody = "Enjoy, friend!"

	equal(
		ns.Distributor:BuildBody(),
		"Enjoy, friend!\n\n" .. ns.L["MAIL_POWERED_BY"],
		"the player's words, then the footer"
	)
	check(ns.L["MAIL_POWERED_BY"]:find("Play It Forward", 1, true) ~= nil, "and the footer names the add-on")
end)

test("the footer goes under a custom body only", function()
	local ns = load()
	local footer = ns.L["MAIL_POWERED_BY"]
	check(not ns.Distributor:BuildBody():find(footer, 1, true), "the stock mail carries no footer")
	check(ns.L["MAIL_BODY"]:find("Play It Forward", 1, true) ~= nil, "since it names the add-on itself")
	ns.db.profile.mailBody = ns.L["MAIL_BODY"]:gsub("level", "grow")
	equal(ns.Distributor:BuildBody():sub(-#footer), footer, "and a one-word edit gets one")
end)

test("a box holding only whitespace sends the stock copy", function()
	local ns = load()
	ns.db.profile.mailSubject = "   "
	ns.db.profile.mailBody = "\n\n  \n"

	equal(ns.Distributor:BuildSubject(), "Play It Forward!", "stock subject")
	equal(ns.Distributor:BuildBody(), ns.L["MAIL_BODY"], "the stock body")
end)

-- A typed pipe comes back from an edit box as ||, and either is a broken escape in a mail.
test("custom copy is trimmed and loses its pipes", function()
	local ns = load()
	ns.db.profile.mailSubject = "  Hi || there  "
	ns.db.profile.mailBody = "Line one\r\nLine | two\n"

	equal(ns.Distributor:BuildSubject(), "Hi  there", "subject trimmed, pipes gone")
	check(not ns.Distributor:BuildBody():find("|", 1, true), "body carries no pipes")
	check(not ns.Distributor:BuildBody():find("\r", 1, true), "and no carriage returns")
end)

--[[
	NO LIMIT WHILE TYPING. The editor stores whatever the player writes, and the mailer cuts
	an overlong copy three bytes early and ends it with "...", so it still arrives whole.
]]
test("a custom body that fits is sent whole", function()
	local ns = load()
	ns.db.profile.mailBody = string.rep("x", ns.Distributor.CUSTOM_BODY_MAX)

	local body = ns.Distributor:BuildBody()
	equal(#body, BODY_MAX, "exactly at the cap")
	check(not body:find("...", 1, true), "and nothing cut")
end)

test("an overlong custom body is cut with ... and keeps its footer", function()
	local ns = load()
	local footer = "\n\n" .. ns.L["MAIL_POWERED_BY"]
	ns.db.profile.mailBody = string.rep("x", 700)

	local body = ns.Distributor:BuildBody()
	equal(#body, BODY_MAX, "cut to the cap")
	equal(body:sub(-#footer), footer, "the footer survives whole")
	equal(
		body:sub(1, -#footer - 1),
		string.rep("x", ns.Distributor.CUSTOM_BODY_MAX - 3) .. "...",
		"the note ends in ..."
	)
	equal(ns.db.profile.mailBody, string.rep("x", 700), "and the saved text is not cut")
end)

test("an overlong custom subject is cut with ...", function()
	local ns = load()
	ns.db.profile.mailSubject = "Some really long title that keeps going"

	local subject = ns.Distributor:BuildSubject()
	check(#subject <= SUBJECT_MAX, ("%d bytes, cap %d"):format(#subject, SUBJECT_MAX))
	-- Three bytes early lands on the space after "that", which is trimmed before the ... goes on.
	equal(subject, "Some really long title that...", "cut, then ...")
end)

-- A cut that lands inside a multi-byte character drops the character, never half of it.
test("a cut never splits a character", function()
	local ns = load()
	-- 27 ASCII bytes, then a three-byte character straddling the 28-byte budget.
	ns.db.profile.mailSubject = string.rep("a", 27) .. "\227\129\130" .. "tail"

	equal(ns.Distributor:BuildSubject(), string.rep("a", 27) .. "...", "the split character is dropped")
end)

--------------------------------------------------------------------------------
-- Saving from the editor
--------------------------------------------------------------------------------

test("saving the stock copy back stores nothing custom", function()
	local ns = load()
	ns.Distributor:SaveCustomText("mailBody", ns.L["MAIL_BODY"] .. "\n")
	ns.Distributor:SaveCustomText("mailSubject", "  Play It Forward!  ")

	equal(ns.db.profile.mailBody, "", "body back to stock")
	equal(ns.db.profile.mailSubject, "", "subject back to stock")
end)

test("saving an edit stores it as typed, cleaned but never cut", function()
	local ns = load()
	ns.Distributor:SaveCustomText("mailBody", "Hi || there\r\n" .. string.rep("y", 600))

	equal(ns.db.profile.mailBody, "Hi  there\n" .. string.rep("y", 600), "pipes and carriage returns gone")
end)

test("the editor opens on the custom copy, else the stock copy", function()
	local ns = load()
	equal(ns.Distributor:EditableText("mailSubject"), "Play It Forward!", "stock to edit from")
	ns.db.profile.mailSubject = "Mine"
	equal(ns.Distributor:EditableText("mailSubject"), "Mine", "then the player's own")
end)

--[[
	Every locale file keeps its own copy of the stock mail, English in each (README-Notes), and a
	client sends whichever copy its locale loads. The checks above read enUS alone, so every copy
	is held under the caps here: a copy that drifts longer would otherwise reach a stranger cut short.
]]
local LOCALES = { "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

local function LocaleStrings(code)
	local strings = {}
	local chunk = assert(loadfile(ADDON_ROOT .. "/Locales/" .. code .. ".lua"))
	setfenv(
		chunk,
		setmetatable({
			LibStub = function()
				return {
					NewLocale = function()
						return strings
					end,
				}
			end,
		}, { __index = _G })
	)
	chunk("Play-It-Forward", {})
	return strings
end

test("every locale's stock mail fits the caps", function()
	for _, code in ipairs(LOCALES) do
		local strings = LocaleStrings(code)
		local subject, body = strings.MAIL_SUBJECT or "", strings.MAIL_BODY or ""
		check(#subject <= SUBJECT_MAX, ("%s subject is %d chars, cap %d"):format(code, #subject, SUBJECT_MAX))
		check(#body <= BODY_MAX, ("%s body is %d chars, cap %d"):format(code, #body, BODY_MAX))
	end
end)
