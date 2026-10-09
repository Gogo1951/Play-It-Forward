local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "deDE")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Version %s. Die Einstellungen (inklusive der Option, diese Nachricht abzuschalten) findest du unter Optionen > AddOns > Play It Forward. Gefällt dir das Add-on? Erzähl einem Freund davon! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Aus Sicherheitsgründen kann das Optionsmenü im Kampf nicht geöffnet werden."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Ausrüstung"
L["WINDOW_CONSUMABLES_LABEL"] = "Verbrauchsgüter"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s und niedriger"

L["BUTTON_FIND_RECIPIENTS"] = "Empfänger suchen"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Suche läuft..."
L["BUTTON_DISTRIBUTE"] = "Verteilen"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Offener Briefkasten nötig"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Drücke noch einmal Empfänger suchen. Blizzard erlaubt diese Suche nur direkt per Knopfdruck, und diesmal ist etwas dazwischengekommen."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Nichts mehr zu verschenken."
L["WINDOW_EMPTY_HINT"] = "Ändere oben Ausrüstung oder Verbrauchsgüter, um mehr anzuzeigen."

L["SECTION_MATCHED"] = "Zugeordnet"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Zuordnung ausstehend"
L["SECTION_UNREADABLE"] = "Werte nicht lesbar"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Behalten"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Kein Empfänger"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Unlesbare Werte"

L["PICKER_KEEP_OPTION"] = "Gegenstand behalten"
L["PICKER_NONE_IN_RANGE"] = "Niemand im Stufenbereich. Drücke Empfänger suchen."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(hat eins)"
L["PICKER_NOTE_REFUSED"] = "(abgelehnt)"
L["PICKER_NOTE_RECENT"] = "(kürzlich)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Empfänger für diesen Gegenstand suchen"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Empfänger"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d Kandidat(en), Stufen %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Klicken, um neu zuzuweisen."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] =
	"Die Werte dieses Gegenstands konnten nicht gelesen werden, daher wird er nicht zugeordnet."
L["TOOLTIP_RECIPIENT_KEPT"] = "Keine Klasse will diesen hier, also bleibt er in deinen Taschen."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Wird verschickt, wenn du Verteilen drückst. Haken entfernen, um ihn zu behalten."
L["TOOLTIP_CHECK_WAITING"] = "Wird zugeordnet, sobald eine Suche jemanden findet. Haken entfernen, um ihn zu behalten."

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
L["MAIL_STILL_SENDING"] = "Wird noch verschickt, einen Moment."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nichts zu verteilen."
L["MAIL_DISTRIBUTING"] =
	"Klicke in jedem Bestätigungsfenster auf Annehmen, um %d Gegenstand/Gegenstände zu verschicken."
L["MAIL_ITEM_MOVED"] = "Drücke Empfänger suchen, um neu zu scannen. %s wurde in deinen Taschen verschoben."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Wähle jemand anderen für %s. %s bekommt schon eins."
L["MAIL_NOT_AT_MAILBOX"] = "Geh zurück zu einem Briefkasten und drücke Verteilen, um den Rest zu verschicken."
L["MAIL_MAILBOX_CLOSED"] =
	"Öffne einen Briefkasten und drücke Verteilen, um den Rest zu verschicken. Der Briefkasten wurde zwischendurch geschlossen."
L["MAIL_NO_POSTAGE"] = "Leg etwas Kupfer für das Porto bereit und drücke dann Verteilen, um den Rest zu verschicken."
L["MAIL_PANEL_CLOSED"] =
	"Öffne Blizzards Fenster zum Verschicken von Post und drücke erneut Verteilen. Nichts wurde verschickt oder verändert."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Wenn du TSM nutzt, wechsle dafür zur Standard-Postoberfläche. Der Briefkasten von TSM nimmt keine Anhänge an."
L["MAIL_ATTACH_FAILED"] = "%s konnte nicht angehängt werden und wurde daher nicht verschickt."
L["MAIL_AWAITING_CONFIRM"] =
	"Klicke im Fenster für %s auf Annehmen und drücke dann Verteilen, um den Rest zu verschicken."
L["MAIL_SENT"] = "%s an %s verschickt (%d/%d)."
L["MAIL_SEND_FAILED"] = "Post an %s fehlgeschlagen (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "kein Grund angegeben"
L["MAIL_REASON_ERROR"] = "Client-Fehler"
L["MAIL_ABORTED"] = "Verteilen nach wiederholten Postfehlern abgebrochen."
L["MAIL_DONE"] = "Fertig. %d von %d verschickt."
L["MAIL_DONE_WITH_SKIPS"] = "Fertig. %d von %d verschickt, %d übersprungen (in deinen Taschen verschoben)."
L["MAIL_SUBJECT_TOO_LONG"] = "Der Betreff hat %d Zeichen, Post erlaubt aber nur %d, daher wird er gekürzt."
L["MAIL_BODY_TOO_LONG"] = "Der Text hat %d Zeichen, Post erlaubt aber nur %d, daher wird er gekürzt."

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
	"Schicke Ausrüstung und Verbrauchsgüter, aus denen du herausgewachsen bist, an Gildenmitglieder oder Fremde, die sich darüber freuen. Jeder Gegenstand wird der Klasse zugeordnet, zu der er am besten passt, und so wird vergessener Taschenkram zum nächsten Upgrade für jemand anderen. Gib es weiter, ein grünes Teil nach dem anderen."
L["OPTIONS_WELCOME"] = "Willkommensnachricht aktivieren"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Beim Einloggen die Version und den Hinweis zu den Einstellungen ausgeben."

L["OPTIONS_COMMANDS_HEADER"] = "/Befehle"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Öffnet das Optionsmenü dieses Add-ons."

L["OPTIONS_GIVE_HEADER"] = "Was verschenkt wird"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"Die höchste angebotene Seltenheit. Alles darüber wird nie aufgelistet, damit ein guter Fund nicht versehentlich verschickt wird."
L["OPTIONS_INCLUDE_GEAR"] = "Ausrüstung einbeziehen"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Beim Anlegen gebundene Waffen und Rüstung anbieten."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Verbrauchsgüter einbeziehen"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Niedrigstufiges Essen, Trinken, Tränke und Schriftrollen anbieten, aus denen du herausgewachsen bist."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Um %d+ Stufen überholt"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Alle Verbrauchsgüter"
L["OPTIONS_CONSUMABLE_GAP"] = "Stufenregel"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"Wie viele Stufen du über einem Verbrauchsgut liegen musst, bevor es als übrig gilt. Bei 20 oder mehr wird ein Wasser der Stufe 35 angeboten, sobald du Stufe 55 erreichst. Alle Verbrauchsgüter bietet jedes in deinen Taschen an, egal welche Stufe du hast."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Essen"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Essen anbieten, aus dem du herausgewachsen bist. Essen, das auch Mana wiederherstellt, wird angeboten, solange Essen oder Trinken aktiv ist."
L["OPTIONS_KIND_DRINK"] = "Trinken"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Wasser, Saft und andere Getränke anbieten, aus denen du herausgewachsen bist."
L["OPTIONS_KIND_POTIONS"] = "Tränke"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] =
	"Heil-, Mana- und Verjüngungstränke anbieten, aus denen du herausgewachsen bist."
L["OPTIONS_KIND_SCROLLS"] = "Schriftrollen"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Werte-Schriftrollen anbieten, aus denen du herausgewachsen bist. Jede geht an die Klassen, die ihren Wert nutzen."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Großzügigkeit"
L["OPTIONS_GENEROSITY_GIFTS"] = "Geschenke"
L["OPTIONS_GENEROSITY_ITEMS"] = "Gegenstände"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Gegenstandsstufen"
L["OPTIONS_GENEROSITY_VALUE"] = "Goldwert"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Großzügigkeits-Tooltips aktivieren"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Spieler in deiner Nähe in Städten und Gasthäusern sehen deine Summen in deinem Tooltip. Ausschalten beendet das Teilen, du siehst ihre aber weiterhin, und deine eigenen Summen unten zählen so oder so weiter."

L["OPTIONS_FEEDBACK_HEADER"] = "Feedback & Unterstützung"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Version %s"
