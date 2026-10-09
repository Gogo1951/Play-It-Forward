local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "enUS", true)
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Version %s. Settings (including the option to disable this message) can be found under Options > AddOns > Play It Forward. Enjoying the add-on? Tell a friend about it! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "As a safety precaution, the Options Interface cannot be opened during combat."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Gear"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumables"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s & Lower"

L["BUTTON_FIND_RECIPIENTS"] = "Find Recipients"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Searching..."
L["BUTTON_DISTRIBUTE"] = "Distribute"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Requires Open Mailbox"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Press Find Recipients again. Blizzard only allows that search straight from a button press, and something interrupted this one."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Nothing left to give away."
L["WINDOW_EMPTY_HINT"] = "Change Gear or Consumables above to list more."

L["SECTION_MATCHED"] = "Matched"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Pending Match"
L["SECTION_UNREADABLE"] = "Stats Couldn't Be Read"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Kept"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "No Recipient"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Couldn't Read Stats"

L["PICKER_KEEP_OPTION"] = "Keep Item"
L["PICKER_NONE_IN_RANGE"] = "No one in range. Press Find Recipients."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(has one)"
L["PICKER_NOTE_REFUSED"] = "(refused)"
L["PICKER_NOTE_RECENT"] = "(recent)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Find Recipients for This Item"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Recipient"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidate(s), levels %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Click to reassign."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Couldn't read this item's stats, so it isn't matched."
L["TOOLTIP_RECIPIENT_KEPT"] = "No class wants this one, so it stays in your bags."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Sent when you press Distribute. Untick to keep it."
L["TOOLTIP_CHECK_WAITING"] = "Matched as soon as a search finds someone. Untick to keep it."

--------------------------------------------------------------------------------
-- Distributing
--------------------------------------------------------------------------------

--[[
	THE ACTION COMES FIRST: "Walk back to a mailbox and press Distribute", not "Not at a mailbox,
	distribution paused". These arrive in a chat frame already busy, where the first few words are
	all that gets read. Messages with no action for the player stay plain statements, and all of
	them print white; see the color note in Features/Announcements.lua.

	THE ACTION NAMES A BUTTON, SPELLED OUT. Nothing ties these mentions to the BUTTON_* keys above,
	so renaming a button here leaves the messages telling the player to press something that is no
	longer on screen. Change BUTTON_FIND_RECIPIENTS or BUTTON_DISTRIBUTE and read this block through,
	along with WHO_BLOCKED, PICKER_NONE_IN_RANGE, PICKER_FIND_FOR_ITEM and TOOLTIP_CHECK_SEND above,
	which name those buttons too.
]]
L["MAIL_STILL_SENDING"] = "Still sending, give it a sec."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nothing to distribute."
L["MAIL_DISTRIBUTING"] = "Click Accept on each confirmation popup to send %d item(s)."
L["MAIL_ITEM_MOVED"] = "Press Find Recipients to re-scan. %s moved in your bags."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Pick someone else for %s. %s is already getting one."
L["MAIL_NOT_AT_MAILBOX"] = "Walk back to a mailbox and press Distribute to send the rest."
L["MAIL_MAILBOX_CLOSED"] = "Open a mailbox and press Distribute to send the rest. The mailbox closed part-way through."
L["MAIL_NO_POSTAGE"] = "Add a little copper for postage, then press Distribute to send the rest."
L["MAIL_PANEL_CLOSED"] = "Open Blizzard's Send Mail panel and press Distribute again. Nothing was sent or touched."
L["MAIL_PANEL_CLOSED_HINT"] =
	"If you use TSM, switch to the default mail UI for this. TSM's mailbox doesn't accept attachments."
L["MAIL_ATTACH_FAILED"] = "Couldn't attach %s, so it wasn't sent."
L["MAIL_AWAITING_CONFIRM"] = "Click Accept on the popup for %s, then press Distribute to send the rest."
L["MAIL_SENT"] = "Sent %s to %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Mail to %s failed (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "no reason given"
L["MAIL_REASON_ERROR"] = "client error"
L["MAIL_ABORTED"] = "Stopped distributing after repeated mail errors."
L["MAIL_DONE"] = "Done. %d of %d sent."
L["MAIL_DONE_WITH_SKIPS"] = "Done. %d of %d sent, %d skipped (moved in your bags)."
L["MAIL_SUBJECT_TOO_LONG"] = "Subject is %d characters and mail only takes %d, so it will be cut short."
L["MAIL_BODY_TOO_LONG"] = "Body is %d characters and mail only takes %d, so it will be cut short."

--------------------------------------------------------------------------------
-- Default Mail Contents
--------------------------------------------------------------------------------

--[[
	THE MAIL A STRANGER RECEIVES. Fixed text, not a setting: an editable version is a way to send
	something worse in the add-on's name. Nothing reads a saved subject or body.

	LENGTH: 500 characters, confirmed against a live mailbox. Past it the mail is cut short,
	sign-off first, and Tests/Mail-Contents.lua fails on it. The runtime warning in
	Features/Mail-Sender.lua stays even so, because the test only measures this locale.
]]
L["MAIL_SUBJECT"] = "Play It Forward!"

L["MAIL_BODY"] = "Just a little something to help you level. (=\n\n"
	.. "No strings attached. Use it if you can, or sell it. "
	.. "Don't want it? Hit Return and it'll find a new home.\n\n"
	.. "This came through Play It Forward, an add-on that automatically passes unwanted gear "
	.. "and leftover consumables to players who can still use them. Find it on CurseForge and Wago.\n\n"
	.. "Happy adventuring!"

--------------------------------------------------------------------------------
-- Options Panel
--------------------------------------------------------------------------------

L["OPTIONS_DESCRIPTION"] =
	"Send the gear and consumables you've outgrown to guildies or strangers who'll appreciate them. Every item is matched to the class it suits best, turning forgotten bag clutter into somebody else's next upgrade. Pay it forward, one green at a time."
L["OPTIONS_WELCOME"] = "Enable Welcome Message"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Print the version and settings reminder when you log in."

L["OPTIONS_COMMANDS_HEADER"] = "/Commands"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Opens the Options Interface for this add-on."

L["OPTIONS_GIVE_HEADER"] = "What to Give Away"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"The highest rarity offered. Anything above this is never listed, so a good drop cannot be mailed off by accident."
L["OPTIONS_INCLUDE_GEAR"] = "Include Gear"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Offer bind-on-equip weapons and armor."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Include Consumables"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] = "Offer low-level food, drink, potions, and scrolls you have outgrown."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Outgrown by %d+ Levels"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "All Consumables"
L["OPTIONS_CONSUMABLE_GAP"] = "Level Rule"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"How far past a consumable you must be before it counts as spare. At 20 or more, a level 35 water is offered once you reach 55. All Consumables offers every one in your bags, whatever your level."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Food"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Offer food you have outgrown. Food that restores mana too is offered while Food or Drink is on."
L["OPTIONS_KIND_DRINK"] = "Drink"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Offer water, juice, and other drinks you have outgrown."
L["OPTIONS_KIND_POTIONS"] = "Potions"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "Offer healing, mana, and rejuvenation potions you have outgrown."
L["OPTIONS_KIND_SCROLLS"] = "Scrolls"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Offer stat scrolls you have outgrown. Each goes to the classes that use its stat."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Generosity"
L["OPTIONS_GENEROSITY_GIFTS"] = "Gifts"
L["OPTIONS_GENEROSITY_ITEMS"] = "Items"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Item Levels"
L["OPTIONS_GENEROSITY_VALUE"] = "Gold Value"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Enable Generosity Tooltips"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Players near you in cities and inns can see your totals on your tooltip. Turning this off stops sharing, but you still see theirs, and your own totals below keep counting either way."

L["OPTIONS_FEEDBACK_HEADER"] = "Feedback & Support"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Version %s"
