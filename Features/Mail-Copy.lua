local _, ns = ...
local L = ns.L

-- The mail's subject and body, stock or the player's own. Features/Mail-Sender.lua sends what these build.
local Distributor = ns.Distributor
local SUBJECT_MAX, BODY_MAX = Distributor.SUBJECT_MAX, Distributor.BODY_MAX

--[[
	The stock body explains the add-on in its own paragraph. A custom body replaces that, so it
	goes out with MAIL_POWERED_BY under it: one short line, enough that a stranger still knows
	where the gift came from. A custom subject needs nothing added, because the body under it
	carries the name either way.
]]
local FOOTER = "\n\n" .. L["MAIL_POWERED_BY"]
local ELLIPSIS = "..."

-- What a custom body can run to before it is cut: the cap less the footer that follows it.
Distributor.CUSTOM_BODY_MAX = BODY_MAX - #FOOTER

--[[
	Which profile key holds which half, the stock text it replaces, and how long it may run. Read
	by the Mail Message Text panel too, so the editor and the mailer cannot disagree on a limit.
]]
Distributor.MAIL_FIELDS = {
	mailSubject = { stock = "MAIL_SUBJECT", max = SUBJECT_MAX },
	mailBody = { stock = "MAIL_BODY", max = Distributor.CUSTOM_BODY_MAX },
}

--[[
	Pipes stripped rather than refused: an edit box hands a typed | back escaped as ||, and either
	form in a mail is a broken escape code. Line endings to \n, and outer whitespace trimmed, so
	a box holding nothing but a stray newline reads as empty and sends the stock copy.
]]
function Distributor:CleanText(text)
	if type(text) ~= "string" then
		return ""
	end
	text = text:gsub("\r\n?", "\n"):gsub("|", "")
	return (text:match("^%s*(.-)%s*$"))
end

--[[
	Cut to max bytes, with ELLIPSIS inside that budget to show it was cut. Never mid-character: a
	multi-byte character the cut would split is dropped whole, or the mail ends in a broken byte.
]]
local function Shorten(text, max)
	if #text <= max then
		return text
	end
	text = text:sub(1, max - #ELLIPSIS)
	local lead = text:find("[\192-\255][\128-\191]*$")
	if lead then
		local byte = text:byte(lead)
		local size = (byte >= 240 and 4) or (byte >= 224 and 3) or 2
		if #text - lead + 1 < size then
			text = text:sub(1, lead - 1)
		end
	end
	return (text:gsub("%s+$", "")) .. ELLIPSIS
end

-- The saved custom text under this profile key, or nil when the stock copy stands.
function Distributor:CustomText(key)
	local text = self:CleanText(ns.db and ns.db.profile[key])
	if text ~= "" then
		return text
	end
	return nil
end

-- What a Mail Message box opens on: the player's words, else the stock copy to edit from.
function Distributor:EditableText(key)
	return self:CustomText(key) or self:CleanText(L[self.MAIL_FIELDS[key].stock])
end

--[[
	Stored as typed, never cut: the length rule is applied when the mail is built, so trimming a
	paragraph later brings back what was past the limit. The stock text, or nothing, stores "".
]]
function Distributor:SaveCustomText(key, text)
	text = self:CleanText(text)
	if text == self:CleanText(L[self.MAIL_FIELDS[key].stock]) then
		text = ""
	end
	ns.db.profile[key] = text
end

function Distributor:BuildSubject()
	local custom = self:CustomText("mailSubject")
	if custom then
		return Shorten(custom, SUBJECT_MAX)
	end
	return L["MAIL_SUBJECT"]
end

function Distributor:BuildBody()
	local custom = self:CustomText("mailBody")
	if custom then
		return Shorten(custom, self.CUSTOM_BODY_MAX) .. FOOTER
	end
	return L["MAIL_BODY"]
end
