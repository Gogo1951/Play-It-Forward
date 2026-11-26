local _, ns = ...
local L = ns.L

-- Captures Mail-Sender's Distributor and limits at load, so it follows Mail-Sender in the TOC.
local Distributor = ns.Distributor
local SUBJECT_MAX, BODY_MAX = Distributor.SUBJECT_MAX, Distributor.BODY_MAX

-- A custom body replaces the stock paragraph that names the add-on, so it carries this footer; a subject needs none.
local FOOTER = "\n\n" .. L["MAIL_POWERED_BY"]
local ELLIPSIS = "..."

-- What a custom body can run to before it is cut: the cap less the footer that follows it.
Distributor.CUSTOM_BODY_MAX = BODY_MAX - #FOOTER

-- The Mail Message Text editor reads this too, so editor and mailer share one limit.
Distributor.MAIL_FIELDS = {
	mailSubject = { stock = "MAIL_SUBJECT", max = SUBJECT_MAX },
	mailBody = { stock = "MAIL_BODY", max = Distributor.CUSTOM_BODY_MAX },
}

--[[
	Pipes stripped: a typed | comes back as ||, a broken escape either way. Trimmed so a box
	holding only a stray newline reads as empty and sends the stock copy.
]]
function Distributor:CleanText(text)
	if type(text) ~= "string" then
		return ""
	end
	text = text:gsub("\r\n?", "\n"):gsub("|", "")
	return (text:match("^%s*(.-)%s*$"))
end

-- Bytes, ellipsis inside the budget; a multi-byte character the cut would split is dropped whole.
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

-- Stored uncut and cut at build, so trimming later brings back the rest. Stock text stores "".
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
