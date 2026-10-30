local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "enUS", true)
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Distribution Window"
L["CHAT_LOADED"] =
	"Version %s. Settings (including the option to disable this message) are under Options > AddOns > Play It Forward. Enjoying this add-on? Tell a friend, Favorite it on CurseForge, or Star it on GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "As a safety precaution, the Options Interface cannot be opened during combat."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Gear"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumables"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Disenchant"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Pick a Character"
L["WINDOW_DISENCHANT_NONE"] = "Your characters appear once each logs in with Play It Forward."

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
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Sending..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "Searching again in %d sec. Try again once the button reads Find Recipients."
L["WHO_BLOCKED"] =
	"Press Find Recipients again. Blizzard only allows that search straight from a button press, and something interrupted this one."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Shows what you can give away from your bags."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Nothing left to give away."
L["WINDOW_EMPTY_HINT"] = "Change the settings above to list more."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Press Find Recipients to look for players for %d item(s)."
L["STATUS_MORE"] = "%d more search(es) planned. Press Find Recipients to keep looking."
L["STATUS_DONE"] = "Search finished. %d item(s) still have no one in range. Try again later."
L["STATUS_READY"] = "Press Distribute to send %d item(s)."
L["STATUS_AWAY"] = "Open a mailbox to send %d item(s)."
L["STATUS_SENDING"] = "Sending %d of %d. Click Accept on each popup."

L["SECTION_MATCHED"] = "Matched"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Pending Match"
L["SECTION_UNREADABLE"] = "Stats Couldn't Be Read"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.
	A Kept gear row only goes to be disenchanted when the player turned on Disenchant Unmatched
	Items, and then it shows under Matched with the enchanter's name.

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
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Already on another row. Your pick wins, and a row you didn't set yourself finds someone else."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] = "A mail to them bounced earlier this session. You can still try again."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Already got a gift from you this session. They come first again once they level up."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Find Recipients for This Item"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Your Alts"
L["PICKER_SECTION_GUILD"] = "Your Guild"
L["PICKER_SECTION_STRANGERS"] = "Strangers"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Disenchant"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Recipient"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidate(s), levels %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Click to reassign."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Best fit for %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Couldn't read this item's stats, so it isn't matched."
L["TOOLTIP_RECIPIENT_KEPT"] = "No class wants this one, so it stays in your bags."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "No one can use this, so it goes to %s to disenchant."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Sent when you press Distribute. Untick to keep it."
L["TOOLTIP_CHECK_WAITING"] = "Matched as soon as a search finds someone. Untick to keep it."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Pick someone from the list to send this one."
L["TOOLTIP_CHECK_UNREADABLE"] = "This one can't be sent until its stats can be read."

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
	along with WHO_WAIT, WHO_BLOCKED, STATUS_START, STATUS_MORE, STATUS_READY, PICKER_NONE_IN_RANGE,
	PICKER_FIND_FOR_ITEM and TOOLTIP_CHECK_SEND above, which name those buttons too.
]]
L["MAIL_STILL_SENDING"] = "Still sending. Give it a sec."
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
	"If you use TSM, switch to Blizzard's Send Mail panel for this. TSM's mailbox doesn't accept attachments."
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

--------------------------------------------------------------------------------
-- Default Mail Contents
--------------------------------------------------------------------------------

--[[
	THE MAIL A STRANGER RECEIVES, unless the player writes their own on the Mail Message Text panel.
	MAIL_BODY carries its own paragraph on where the gift came from; a custom body loses that, so
	it goes out with the one-line MAIL_POWERED_BY after it instead. See Features/Mail-Copy.lua.

	LENGTH: 500 characters, confirmed against a live mailbox. Past it the mail is cut short,
	sign-off first, and Tests/Mail-Contents.lua fails on it, reading every locale file's copy of this
	English text.
]]
L["MAIL_SUBJECT"] = "Play It Forward!"

L["MAIL_BODY"] = "Just a little something to help you level. (=\n\n"
	.. "No strings attached. Use it if you can, or sell it. "
	.. "Don't want it? Hit Return and it'll find a new home.\n\n"
	.. "This came through Play It Forward, an add-on that automatically passes unwanted gear "
	.. "and leftover consumables to players who can still use them. Find it on CurseForge and Wago.\n\n"
	.. "Happy adventuring!"

-- Ends every custom body: the add-on's name, kept on a gift whose note the player rewrote.
L["MAIL_POWERED_BY"] = "Powered by Play It Forward, on CurseForge and Wago."

--------------------------------------------------------------------------------
-- Options: General Panel
--------------------------------------------------------------------------------

L["OPTIONS_DESCRIPTION"] =
	"Mail outgrown BoE gear, food, potions, scrolls, oils, and stones to your alts, guildmates, and leveling players. Every item goes to the class it suits best, turning bag clutter into somebody else's next upgrade. Pay it forward, one green at a time."
L["OPTIONS_WELCOME"] = "Enable Welcome Message"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Print the version and settings reminder when you log in."

L["OPTIONS_FEATURES_HEADER"] = "Features"

L["OPTIONS_COMMANDS_HEADER"] = "/Commands"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Opens the Options Interface for this add-on."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "What to Give Away"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Choose what you give away to other players. You can also change gear and consumables anytime at the top of the Distribution Window."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"The highest rarity offered. Anything above this is never listed, so a good drop cannot be mailed off by accident."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Distribute Gear"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Offer bind-on-equip weapons and armor."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Distribute Consumables"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Offer low-level food, drink, potions, scrolls, oils, and stones you have outgrown."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "Oils & Stones"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Offer weapon oils, sharpening stones, and weightstones you have outgrown. Wizard oils go to spellcasters, mana oils to anyone with mana, and stones and other oils to melee fighters."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Disenchant Unmatched Items"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"Gear no one matched can be mailed to one of your own characters to disenchant, instead of staying in your bags. Turn it on, then choose which character gets it. Each realm and faction keeps its own choice."
L["OPTIONS_DISENCHANT_SEND"] = "Send Unmatched Items to Disenchanter"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"Gear no one can use goes to one of your characters to disenchant, instead of staying in your bags. Consumables are never sent."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Your enchanter. Lists your characters on this realm and its connected realms, on this faction, once each has logged in with Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Recipients"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"Who your gear goes to, and in what order. Pick which of your characters and guilds count on the My Alts and My Guilds pages below."

L["OPTIONS_PRIORITY_HEADER"] = "Who Comes First"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Your own characters and guildmates can go to the front of the line for anything that suits them as well as it suits a stranger. Untick either and they compete with everyone else on level and location."
L["OPTIONS_PRIORITIZE_ALTS"] = "Prioritize My Alts over Strangers and My Guilds"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Your own characters get first pick of anything that suits them as well as anyone else. Unticked, they compete with everyone else on level and location."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Prioritize My Guilds over Strangers"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Your guildmates get first pick over strangers of anything that suits them as well. Unticked, they compete with strangers on level and location."

L["OPTIONS_STRANGERS_HEADER"] = "When Searching for Strangers"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"How players found with /who are weighed against each other. Among equally good fits, gear goes first to whoever is most likely leveling and will put it to use."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Prioritize Strangers in Level-Appropriate Zones"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Offer gear first to players questing in a zone made for their level, ahead of players in a city. These questers are the ones most likely to appreciate your kindness."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Prioritize Strangers Not in Instances"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Offer gear to players in a dungeon or raid only when nobody suitable is out in the world. Players in a dungeon can be characters who are being boosted, and won't need the gear for long."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Ignore Warlocks Level %d-%d"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Never offer gear to strangers who are warlocks in this level range. Warlocks learn to summon at 20, and many players park a warlock alt here just to summon friends, so gear sent to them often goes unused. Your own characters and guildmates aren't affected."

L["OPTIONS_SPECS_HEADER"] = "Classes & Specs"
L["OPTIONS_SPECS_INTRO"] =
	"Nobody can see another player's spec, so gear goes out on these assumptions. Your own characters use the specs set on My Alts."
L["OPTIONS_SPECS_RESET"] = "Restore Defaults"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "Put every spec back to how the add-on ships."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Spell damage"
L["ROLE_MELEE"] = "Melee damage"
L["ROLE_RANGED"] = "Ranged damage"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Arms"
L["SPEC_Fury"] = "Fury"
L["SPEC_Protection"] = "Protection"
L["SPEC_Holy"] = "Holy"
L["SPEC_Retribution"] = "Retribution"
L["SPEC_BeastMastery"] = "Beast Mastery"
L["SPEC_Marksmanship"] = "Marksmanship"
L["SPEC_Survival"] = "Survival"
L["SPEC_Assassination"] = "Assassination"
L["SPEC_Combat"] = "Combat"
L["SPEC_Subtlety"] = "Subtlety"
L["SPEC_Discipline"] = "Discipline"
L["SPEC_Shadow"] = "Shadow"
L["SPEC_Elemental"] = "Elemental"
L["SPEC_Enhancement"] = "Enhancement"
L["SPEC_Restoration"] = "Restoration"
L["SPEC_Arcane"] = "Arcane"
L["SPEC_Fire"] = "Fire"
L["SPEC_Frost"] = "Frost"
L["SPEC_Affliction"] = "Affliction"
L["SPEC_Demonology"] = "Demonology"
L["SPEC_Destruction"] = "Destruction"
L["SPEC_Balance"] = "Balance"
L["SPEC_Feral"] = "Feral"
L["SPEC_Guardian"] = "Guardian"
L["SPEC_Blood"] = "Blood"
L["SPEC_Unholy"] = "Unholy"
L["SPEC_Brewmaster"] = "Brewmaster"
L["SPEC_Mistweaver"] = "Mistweaver"
L["SPEC_Windwalker"] = "Windwalker"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Protection"
L["SPEC_DRUID_Restoration"] = "Restoration"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Tank (runes)"
L["SPEC_Healer"] = "Healer (runes)"
L["SPEC_Melee"] = "Melee (runes)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "My Alts"
L["OPTIONS_ALTS_INTRO"] =
	"Your own characters, each added once it logs in with Play It Forward. Pick one on the left to choose whether it gets mail and which specs it's sent gear for."
L["OPTIONS_SEND_TO_ALTS"] = "Send to Alts"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Mail your own characters first, ahead of your guild and strangers, but only items their class is a best fit for. A character counts once it has logged in with Play It Forward on this realm or a connected one, on this faction. Mail to your alts doesn't count toward your Badge of Generosity totals."
L["OPTIONS_ALTS_EMPTY"] =
	"No characters yet. Each of your characters appears here once it logs in with Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Include This Character"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Mail gear to this character. Unticked, it's never offered anything. A character at the level cap starts unticked."
L["OPTIONS_ALT_SPECS"] = "Mail Gear For"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Offer this character gear for this spec. It starts on the spec the character last played, or every spec until it has one."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Gear Levels"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Lowest"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"The lowest-level gear this character is mailed. Their Level sends nothing below its level; Their Level -2 also sends gear up to two levels below, which it can wear now."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Highest"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"The highest-level gear this character is mailed. Any Gear They Could Use sends anything it will grow into, so a level 1 hunter can be sent a level 50 bow."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Their Level"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Their Level -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Their Level +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Any Gear They Could Use"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Mailed gear for levels %d to %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Mailed gear from level %d up."
L["OPTIONS_DELETE"] = "Delete"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "Forget %s? It's added back the next time it logs in."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "Forget this character. It's added back the next time it logs in."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "My Guilds"
L["OPTIONS_GUILDS_INTRO"] =
	"Every guild your characters are in, saved each time one of them logs in, so whichever character you're on can mail their leveling guildmates."
L["OPTIONS_GUILD_OFFLINE"] = "Ignore Offline Guild Members"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Skip guildmates who haven't logged in for longer than this, in the guild you're in now and in your saved ones. Choose Never to include everyone, however long they've been away."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Longer than 1 Week"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Longer than 2 Weeks"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Never"
L["OPTIONS_GUILDS_EMPTY"] = "No guilds yet. A guild appears here once one of your characters in it logs in."
L["OPTIONS_GUILD_INCLUDE"] = "Mail This Guild's Members"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Mail gear to this guild's members."
L["OPTIONS_GUILD_MEMBERS"] = "Active Members"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "Nobody in this roster was active recently enough to get items."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Include"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Mail gear to this guildmate. Untick it for a guild bank or a profession alt, and they're never offered anything."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d active members, saved %s by %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "today"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "yesterday"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d days ago"
L["OPTIONS_GUILD_CURRENT"] = "Your current guild, read fresh at the mailbox."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "On another realm, so mail can't reach it from here."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "On the other faction, so mail can't reach it from here."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Mail Message Text"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"The note that goes out with every gift. Write your own on the left and see exactly what's sent on the right. Changes save as you type; clear a box to go back to the default."
L["OPTIONS_MAIL_SUBJECT"] = "Subject"
L["OPTIONS_MAIL_BODY"] = "Body"
L["OPTIONS_MAIL_YOURS"] = "Your Message"
L["OPTIONS_MAIL_PREVIEW"] = "What They Receive"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Subject %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Body %d/%d"
L["OPTIONS_MAIL_RESET"] = "Restore Default"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Go back to the default subject and body."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Badge of Generosity"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Your giving totals, from every character on your account. They show on your player tooltip in cities and inns, where other Play It Forward users see them when they hover over you, and you see theirs. They're hidden in dungeons, raids, and out in the world."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Badge of Generosity"
L["OPTIONS_GENEROSITY_GIFTS"] = "Gifts"
L["OPTIONS_GENEROSITY_ITEMS"] = "Items"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Item Levels"
L["OPTIONS_GENEROSITY_VALUE"] = "Gold Value"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Enable Badge of Generosity Player Tooltips"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Players near you in cities and inns can see your totals on your tooltip. Turning this off stops sharing, but you still see theirs, and your own totals keep counting either way."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Help Play It Forward Level Up"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"This add-on was built by players who love this game and want to make it as fun as possible for everyone. We'll never ask for donations. The real satisfaction comes from knowing our work makes the game a little better for you. If it does, we'd love to hear about it!"
L["OPTIONS_LEVEL_UP_WAYS"] = "Here are a few ways you can help us reach more players."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Share Feedback: Found a bug or have an idea? Let us know on Discord. Your feedback helps us improve the add-on, and pull requests are always welcome."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Tell a Friend: Know someone who might enjoy this add-on? Tell them about it. Word of mouth helps more players discover great add-ons."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Favorite on CurseForge: Open the CurseForge link below, sign in, and click the star beneath the Download button. Favorites help more players discover the add-on."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star on GitHub: Open the GitHub link below, sign in, and click Star in the top right. Stars help the project qualify for more free developer tools."
L["OPTIONS_LEVEL_UP_THANKS"] = "Thanks for choosing Play It Forward!"

L["OPTIONS_FEEDBACK"] = "Feedback & Support"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Feedback & Support Links"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "To copy a link, click its box, then press Ctrl+A and Ctrl+C."
L["OPTIONS_VERSION"] = "Version %s"
