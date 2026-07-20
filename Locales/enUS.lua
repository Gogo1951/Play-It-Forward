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

-- Rarity names shown on the cap control and in the options select.
L["QUALITY_UNCOMMON"] = "Green"
L["QUALITY_RARE"] = "Blue"
L["QUALITY_EPIC"] = "Purple"

L["BUTTON_FIND_RECIPIENTS"] = "Find Recipients"
L["BUTTON_SCAN_AGAIN"] = "Scan Again"
-- On the button while the /who throttle is up. Not a countdown: the button already says what it is doing.
L["BUTTON_SEARCHING"] = "Searching..."
L["BUTTON_DISTRIBUTE"] = "Distribute"

-- The labels naming where a query is looking surface only in the roster report, so they live in ns.DiagnosticsStrings.

L["SECTION_MATCHED"] = "Matched"
--[[
	"Pending Match", not "no recipient in range": the usual truth is that the search has
	not got there yet, and Scan Again is right underneath.
]]
L["SECTION_NO_RECIPIENT"] = "Pending Match"
L["SECTION_UNREADABLE"] = "Stats Couldn't Be Read"
L["SECTION_VENDOR"] = "Vendor / Disenchant"

L["ROW_VENDOR"] = "vendor / disenchant"
L["ROW_NO_RECIPIENT"] = "no recipient"
L["ROW_UNREADABLE"] = "stats unknown"

L["PICKER_VENDOR_OPTION"] = "vendor / disenchant (don't send)"
L["PICKER_NONE_IN_RANGE"] = "no one in range, run Find Recipients"
-- Names this as the add-on's failure rather than an empty realm, so Find Recipients is not pressed forever.
L["PICKER_UNREADABLE"] = "couldn't read this item's stats, so it isn't matched"
--[[
	Why a name in the dropdown cannot be picked, greyed rather than hidden: a name that
	vanishes reads as the add-on having lost them, where the reason is the useful part.

	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class,
	and anything longer is cut off. What to do about it belongs in the hint below.
]]
L["PICKER_NOTE_HAS_ONE"] = "(has one)"
L["PICKER_NOTE_REFUSED"] = "(refused)"
L["PICKER_NOTE_RECENT"] = "(recent)"
L["PICKER_HINT_GREYED"] = "Clear a row to free the name it holds."

L["TOOLTIP_RECIPIENT"] = "Recipient"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidate(s) at level %d-%d"
L["TOOLTIP_RECIPIENT_HINT"] = "Click to reassign."

--[[
	There is deliberately no status line, so no STATUS_* strings: the headings, the button
	and the chat report already say all of it. Features/Mail-Window.lua carries the
	reasoning.
]]
L["CHAT_ALREADY_HOLDS"] = "%s already has %s. Clear that row first if you want to give them something else."
L["CHAT_CANNOT_RECEIVE"] = "Mail to %s was refused earlier this session, so they were not set."
-- There is deliberately no CHAT_NOTHING_GIFTABLE: a mailbox visit with nothing spare is the ordinary case.

--------------------------------------------------------------------------------
-- Distributing
--------------------------------------------------------------------------------

L["MAIL_STILL_SENDING"] = "Still sending, give it a sec."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nothing to distribute."
L["MAIL_DISTRIBUTING"] = "Distributing %d item(s). Click Accept on each confirm popup."
L["MAIL_ITEM_MOVED"] = "%s moved in your bags, skipped. Press Find Recipients to re-scan."
--[[
	Two greens at once from a stranger reads as spam, so the second is held back. Named
	rather than dropped quietly: a silent skip looks like the row was never ticked.
]]
L["MAIL_ALREADY_HAS_ONE"] = "%s not sent: %s already has one this run. Pick somebody else for it."
L["MAIL_NOT_AT_MAILBOX"] = "Not at a mailbox, distribution paused. Walk back and press Distribute."
L["MAIL_NO_POSTAGE"] = "Not enough copper for postage. Paused."
L["MAIL_PANEL_CLOSED"] = "Blizzard's Send Mail panel isn't open, so nothing was sent or touched."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Open a mailbox with the default mail UI (TSM's mailbox doesn't accept attachments), then press Distribute again."
L["MAIL_ATTACH_FAILED"] = "Couldn't attach %s, nothing sent."
L["MAIL_AWAITING_CONFIRM"] = "Waiting on confirm for %s. Click Accept, then press Distribute to resume."
L["MAIL_SENT"] = "Sent %s to %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Mail to %s failed (%s)."
L["MAIL_ABORTED"] = "Multiple mail errors, aborting distribution."
L["MAIL_DONE"] = "Done. %d of %d delivered."
L["MAIL_DONE_WITH_SKIPS"] = "Done. %d of %d delivered, %d skipped (moved in your bags)."
-- There are deliberately no MAIL_PREVIEW_* strings: the Diagnostic Tools panel keeps the preview.
L["MAIL_SUBJECT_TOO_LONG"] = "Subject is %d characters and mail only takes %d, so it will be cut short."
L["MAIL_BODY_TOO_LONG"] = "Body is %d characters and mail only takes %d, so it will be cut short."

L["WHO_BLOCKED"] =
	"Blizzard blocked that /who. It only works when it comes straight from a button press, so click Find Recipients again."

--------------------------------------------------------------------------------
-- Default Mail Contents
--------------------------------------------------------------------------------

--[[
	THE MAIL A STRANGER RECEIVES. Fixed text, not a setting. It goes out cold to somebody
	who has never heard of you, and an editable version is a way to send something worse
	in the add-on's name. Nothing reads a saved subject or body.

	Straight apostrophes, not curly ones, matching the rest of this file.

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
	"Mail the gear and consumables you've outgrown to strangers who'll appreciate them. Every item is matched to the class it suits best, turning forgotten bag clutter into somebody else's next upgrade. Pay it forward, one green at a time."
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
--[[
	Caption and values, read together: "Outgrown By" over "20 levels". Without the caption
	the dropdown gives a number of levels and nothing about what they count from.
]]
L["OPTIONS_CONSUMABLE_GAP_LABEL"] = "Outgrown By"
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "%d levels"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"How many levels past a consumable you must be before it counts as spare. At 20, a level 35 water is offered once you reach 55."

-- No strings for a Finding Recipients, Matching or The Mail section: Data/Default-Settings.lua records where each went.

L["OPTIONS_FEEDBACK"] = "Feedback & Support"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Version %s"
