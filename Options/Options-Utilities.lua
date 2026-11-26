local _, ns = ...
local L = ns.L

local Kit = ns.OptionsKit

--------------------------------------------------------------------------------
-- Options-Kit Setup
--------------------------------------------------------------------------------

-- No soundPreview key: no panel here plays a sound.
Kit.SetText({
	example = L["SAMPLE_EXAMPLE"],
	loading = L["LOADING_ITEM"],
	inCombat = L["CHAT_OPTIONS_IN_COMBAT"],
	reset = L["OPTIONS_RESET"],
})

ns.OptionsDesc = Kit.Desc
ns.OptionsSpacer = Kit.Spacer

--------------------------------------------------------------------------------
-- Shared Options Helpers
--------------------------------------------------------------------------------

-- Rescans with no window too: that marks the scan stale, or the next mailbox reuses a verdict judged the old way.
function ns.RefreshMailWindow()
	if ns.UI.frame then
		ns.UI:SyncControls()
	end
	ns.UI:Rescan()
end

function ns.OptionsProfileOff(key)
	return function()
		return not (ns.db and ns.db.profile[key])
	end
end

-- Only the Badge of Generosity page still uses this, until it moves onto Kit.FeatureSwitch.
function ns.OptionsProfileToggle(key, name, desc, order, width, onSet)
	return {
		type = "toggle",
		name = name,
		desc = desc,
		width = width or "full",
		order = order,
		get = Kit.Get("profile", key),
		set = Kit.Set("profile", key, onSet),
	}
end

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

--------------------------------------------------------------------------------
-- Features
--------------------------------------------------------------------------------

local function GiftSwitch(setting)
	return function(value)
		ns.db.profile[setting] = value
		ns.RefreshMailWindow()
	end
end

-- Kit.FeatureSwitch reads this list (Options-Kit.md → Features); no menu does, as the add-on has no mini-map button.
ns.FEATURES = {
	{
		store = "profile",
		setting = "includeGear",
		name = "OPTIONS_DISTRIBUTE_GEAR",
		caption = "OPTIONS_ENABLE_GEAR",
		desc = "OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION",
		apply = GiftSwitch("includeGear"),
	},
	{
		store = "profile",
		setting = "includeConsumables",
		name = "OPTIONS_DISTRIBUTE_CONSUMABLES",
		caption = "OPTIONS_ENABLE_CONSUMABLES",
		desc = "OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION",
		apply = GiftSwitch("includeConsumables"),
	},
	{
		store = "profile",
		setting = "shareStats",
		name = "OPTIONS_SHARE_STATS",
		caption = "OPTIONS_ENABLE_SHARE",
		desc = "OPTIONS_SHARE_STATS_DESCRIPTION",
	},
}
