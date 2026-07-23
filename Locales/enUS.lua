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

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

L["WINDOW_RARITY_LABEL"] = "Give Away Up To:"

L["QUALITY_UNCOMMON"] = "Green"
L["QUALITY_RARE"] = "Blue"
L["QUALITY_EPIC"] = "Purple"

L["BUTTON_FIND_RECIPIENTS"] = "Find Recipients"
L["BUTTON_SCAN_AGAIN"] = "Scan Again"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Searching..."
L["BUTTON_DISTRIBUTE"] = "Distribute"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Requires Open Mailbox"

-- Labels for where a query is looking live in ns.DiagnosticsStrings: roster report only.

L["SECTION_MATCHED"] = "Matched"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Pending Match"
L["SECTION_UNREADABLE"] = "Stats Couldn't Be Read"
--[[
	"Kept", never "vendor / disenchant" (maintainer ruling, 2026-07-23): the add-on does not
	tell the player what to do with what stays. Covers both the rows nobody was found for and
	the rows the player chose to keep.
]]
L["SECTION_KEPT"] = "Kept"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_KEPT"] = "Kept"
L["ROW_NO_RECIPIENT"] = "No Recipient"
L["ROW_UNREADABLE"] = "Stats Unknown"

L["PICKER_KEEP_OPTION"] = "Keep Item"
L["PICKER_NONE_IN_RANGE"] = "No one in range, run Find Recipients"
-- The add-on's failure, not an empty realm, so Find Recipients is not pressed forever.
L["PICKER_UNREADABLE"] = "Couldn't read this item's stats, so it isn't matched"
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(has one)"
L["PICKER_NOTE_REFUSED"] = "(refused)"
L["PICKER_NOTE_RECENT"] = "(recent)"
-- Below the divider at the bottom of the list: one targeted /who press for this item's band.
L["PICKER_FIND_FOR_ITEM"] = "Find Recipients for This Item"

L["TOOLTIP_RECIPIENT"] = "Recipient"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidate(s) at level %d-%d"
L["TOOLTIP_RECIPIENT_HINT"] = "Click to reassign."

--[[
	Deliberately no status line, so no STATUS_* strings: the headings and chat report say it all.
	And no CHAT_NOTHING_GIFTABLE: a visit with nothing spare is the ordinary case.
]]

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
	longer on screen. Change BUTTON_FIND_RECIPIENTS or BUTTON_DISTRIBUTE and read this block through.
]]
L["MAIL_STILL_SENDING"] = "Still sending, give it a sec."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nothing to distribute."
L["MAIL_DISTRIBUTING"] = "Distributing %d item(s). Click Accept on each confirm popup."
L["MAIL_ITEM_MOVED"] = "Press Find Recipients to re-scan, %s moved in your bags."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Pick somebody else for %s, %s already has one this run."
L["MAIL_NOT_AT_MAILBOX"] = "Walk back to a mailbox and press Distribute to send the rest."
-- The run is dropped, not paused, so this says re-tick rather than "press Distribute to send the rest".
L["MAIL_MAILBOX_CLOSED"] = "Open a mailbox and tick the rows again, the mailbox closed part-way through."
L["MAIL_NO_POSTAGE"] = "Add a little copper for postage, then press Distribute to send the rest."
L["MAIL_PANEL_CLOSED"] = "Open Blizzard's Send Mail panel and press Distribute again. Nothing was sent or touched."
L["MAIL_PANEL_CLOSED_HINT"] =
	"If you use TSM, switch to the default mail UI for this. Its mailbox doesn't accept attachments."
L["MAIL_ATTACH_FAILED"] = "Couldn't attach %s, nothing sent."
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
L["MAIL_ABORTED"] = "Multiple mail errors, aborting distribution."
L["MAIL_DONE"] = "Done. %d of %d delivered."
L["MAIL_DONE_WITH_SKIPS"] = "Done. %d of %d delivered, %d skipped (moved in your bags)."
-- Deliberately no MAIL_PREVIEW_* strings: the Diagnostic Tools panel keeps the preview.
L["MAIL_SUBJECT_TOO_LONG"] = "Subject is %d characters and mail only takes %d, so it will be cut short."
L["MAIL_BODY_TOO_LONG"] = "Body is %d characters and mail only takes %d, so it will be cut short."

L["WHO_BLOCKED"] =
	"Press Find Recipients again. Blizzard only allows that search straight from a button press, and something interrupted this one."

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
	.. "No strings attached. Use it if you can, or disenchant or vendor it. "
	.. "Don't want it? Just hit Return and it'll find a new home.\n\n"
	.. "This came through Play It Forward, an add-on that automatically passes unwanted gear "
	.. "and leftover consumables to players who can still use them. Find it on CurseForge and Wago.\n\n"
	.. "Happy adventuring!"

--------------------------------------------------------------------------------
-- Options Panel
--------------------------------------------------------------------------------

L["OPTIONS_DESCRIPTION"] =
	"Mail the gear and consumables you've outgrown to guildies or strangers who'll appreciate them. Every item is matched to the class it suits best, turning forgotten bag clutter into somebody else's next upgrade. Pay it forward, one green at a time."
L["OPTIONS_WELCOME"] = "Enable Welcome Message"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Print the version and settings reminder when you log in."

L["OPTIONS_COMMANDS_HEADER"] = "/Commands"
L["OPTIONS_COMMAND_PIF"] = "/pif"
L["OPTIONS_COMMAND_PIF_DESCRIPTION"] = "Opens this options panel."

L["OPTIONS_GIVE_HEADER"] = "What to Give Away"
L["OPTIONS_MAX_RARITY"] = "Give Away Up To"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"The highest rarity offered. Anything above this is never listed, so a good drop cannot be mailed off by accident."
L["OPTIONS_INCLUDE_GEAR"] = "Include Gear"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Offer bind-on-equip weapons and armor."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Include Consumables"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] = "Offer low-level food, drink and potions you have outgrown."
-- Read together: "Outgrown By" over "20 levels", or the number says nothing about what it counts from.
L["OPTIONS_CONSUMABLE_GAP_LABEL"] = "Outgrown By"
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "%d levels"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"How many levels past a consumable you must be before it counts as spare. At 20, a level 35 water is offered once you reach 55."

L["OPTIONS_HISTORY_HEADER"] = "Recipient History"
L["OPTIONS_HISTORY_BUTTON"] = "Clear History and Roster"
L["OPTIONS_HISTORY_CONFIRM"] = "Clear every recipient cooldown and the known-player roster? This cannot be undone."
L["OPTIONS_HISTORY_DESCRIPTION"] = "Everyone previously gifted becomes eligible again immediately."

-- Account-wide giving tally, read-only here. Item Levels counts equippable gear only.
L["OPTIONS_GIVEN_HEADER"] = "Given Away"
L["OPTIONS_GIVEN_GIFTS"] = "Gifts"
L["OPTIONS_GIVEN_ITEMS"] = "Items"
L["OPTIONS_GIVEN_ITEM_LEVELS"] = "Item Levels"
L["OPTIONS_GIVEN_VALUE"] = "Gold Value"

-- Sharing the tally with nearby players. The four labels above are reused on the tooltip.
L["OPTIONS_SHARE_STATS"] = "Share My Giving Stats"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Players near you in cities and inns can see your Given Away totals on your tooltip; turning this off stops sharing but you still see theirs."
L["TOOLTIP_GIVEN_HEADER"] = "Play It Forward // Given Away"

-- No Finding Recipients, Matching or The Mail sections: Data/Default-Settings.lua records why.

L["OPTIONS_FEEDBACK"] = "Feedback & Support"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Version %s"
