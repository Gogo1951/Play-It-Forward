local _, ns = ...

--------------------------------------------------------------------------------
-- Shared Options Helpers
--------------------------------------------------------------------------------

-- Header and Spacer take an optional last argument, so a gated section collapses whole.
local GetColor = ns.GetColor

function ns.OptionsHeader(text, order, hidden)
	return { type = "header", name = GetColor("TITLE") .. text .. "|r", order = order, hidden = hidden }
end

function ns.OptionsDesc(text, order)
	return { type = "description", name = text, fontSize = "medium", order = order }
end

function ns.OptionsSpacer(order, hidden)
	return { type = "description", name = " ", order = order, hidden = hidden }
end

--[[
	For a setting that changes what the bag scan returns: the open window is re-read. Rescan runs
	with no window too: it marks the scan stale, or the next mailbox reuses one judged the old way.
	Shared by every panel whose settings change who gets what.
]]
function ns.RefreshMailWindow()
	if ns.UI.frame then
		ns.UI:SyncControls()
	end
	ns.UI:Rescan()
end

--[[
	A toggle bound to one profile key. name and desc arrive already localized; onSet runs after
	every write, such as ns.RefreshMailWindow for a setting that changes what the bag scan returns.
]]
function ns.OptionsProfileToggle(key, name, desc, order, width, onSet)
	return {
		type = "toggle",
		name = name,
		desc = desc,
		width = width or "full",
		order = order,
		get = function()
			return ns.db and ns.db.profile[key]
		end,
		set = function(_, value)
			ns.db.profile[key] = value
			if onSet then
				onSet()
			end
		end,
	}
end

-- A hidden or disabled test that is true while this profile key is off.
function ns.OptionsProfileOff(key)
	return function()
		return not (ns.db and ns.db.profile[key])
	end
end

--[[
	The left half of a label-beside-control row. The control that follows carries name = "" and
	the remaining width, ordered one past this: a caption left on the control puts the label back
	above the widget and breaks the row in two.
]]
function ns.OptionsRowLabel(text, order, width)
	return {
		type = "description",
		name = text,
		fontSize = "medium",
		width = width or ns.OPTIONS_LABEL_WIDTH,
		order = order,
	}
end

-- A class's icon as an inline texture, for a label on the My Alts and My Guilds panels.
function ns.OptionsClassIcon(class)
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
	if not coords then
		return ""
	end
	return ("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t "):format(
		coords[1] * 256,
		coords[2] * 256,
		coords[3] * 256,
		coords[4] * 256
	)
end

-- Text in the helper color, for the details beside a name.
function ns.OptionsHelp(text)
	return GetColor("HELP") .. text .. "|r"
end
