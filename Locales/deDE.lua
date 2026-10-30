local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "deDE")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Verteilungsfenster"
L["CHAT_LOADED"] =
	"Version %s. Die Einstellungen (inklusive der Option, diese Nachricht abzuschalten) findest du unter Optionen > AddOns > Play It Forward. Gefällt dir dieses Add-on? Erzähl einem Freund davon, markiere es auf CurseForge als Favorit oder gib ihm auf GitHub einen Star. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Aus Sicherheitsgründen kann das Optionsmenü im Kampf nicht geöffnet werden."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Ausrüstung"
L["WINDOW_CONSUMABLES_LABEL"] = "Verbrauchsgüter"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Entzaubern"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Charakter wählen"
L["WINDOW_DISENCHANT_NONE"] = "Deine Charaktere erscheinen, sobald sich jeder mit Play It Forward einloggt."

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
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Versand läuft..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "Neue Suche in %d Sek. Versuch es erneut, sobald der Button Empfänger suchen anzeigt."
L["WHO_BLOCKED"] =
	"Drücke noch einmal Empfänger suchen. Blizzard erlaubt diese Suche nur direkt per Knopfdruck, und diesmal ist etwas dazwischengekommen."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Zeigt, was du aus deinen Taschen verschenken kannst."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Nichts mehr zu verschenken."
L["WINDOW_EMPTY_HINT"] = "Ändere die Einstellungen oben, um mehr anzuzeigen."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Drücke Empfänger suchen, um Spieler für %d Teil(e) zu finden."
L["STATUS_MORE"] = "%d weitere Suche(n) geplant. Drücke Empfänger suchen für mehr."
L["STATUS_DONE"] = "Suche beendet. Für %d Teil(e) noch niemand im Stufenbereich. Versuch es später."
L["STATUS_READY"] = "Drücke Verteilen, um %d Teil(e) zu verschicken."
L["STATUS_AWAY"] = "Öffne einen Briefkasten, um %d Teil(e) zu verschicken."
L["STATUS_SENDING"] = "Sende %d von %d. In jedem Fenster auf Annehmen klicken."

L["SECTION_MATCHED"] = "Zugeordnet"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Zuordnung ausstehend"
L["SECTION_UNREADABLE"] = "Werte nicht lesbar"

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
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Schon in einer anderen Zeile. Deine Wahl gewinnt, und eine Zeile, die du nicht selbst festgelegt hast, sucht sich jemand anderen."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Eine Post an diesen Spieler kam in dieser Sitzung schon zurück. Du kannst es trotzdem noch einmal versuchen."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Hat in dieser Sitzung schon ein Geschenk von dir bekommen. Ist wieder zuerst dran, sobald er eine Stufe aufsteigt."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Empfänger für diesen Gegenstand suchen"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Deine Twinks"
L["PICKER_SECTION_GUILD"] = "Deine Gilde"
L["PICKER_SECTION_STRANGERS"] = "Fremde"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Entzaubern"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Empfänger"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d Kandidat(en), Stufen %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Klicken, um neu zuzuweisen."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Am besten geeignet für %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] =
	"Die Werte dieses Gegenstands konnten nicht gelesen werden, daher wird er nicht zugeordnet."
L["TOOLTIP_RECIPIENT_KEPT"] = "Keine Klasse will diesen hier, also bleibt er in deinen Taschen."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "Niemand kann das nutzen, also geht es zum Entzaubern an %s."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Wird verschickt, wenn du Verteilen drückst. Haken entfernen, um ihn zu behalten."
L["TOOLTIP_CHECK_WAITING"] = "Wird zugeordnet, sobald eine Suche jemanden findet. Haken entfernen, um ihn zu behalten."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Wähle jemanden aus der Liste, um diesen hier zu verschicken."
L["TOOLTIP_CHECK_UNREADABLE"] = "Dieser hier kann erst verschickt werden, wenn seine Werte lesbar sind."

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
L["MAIL_STILL_SENDING"] = "Wird noch verschickt. Einen Moment."
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
	"Wenn du TSM nutzt, wechsle dafür zu Blizzards Fenster zum Verschicken von Post. Der Briefkasten von TSM nimmt keine Anhänge an."
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
	"Verschicke Ausrüstung, die beim Anlegen gebunden wird, sowie Essen, Tränke, Schriftrollen, Öle und Steine, aus denen du herausgewachsen bist, per Post an deine Twinks, Gildenmitglieder und Spieler, die noch leveln. Jeder Gegenstand geht an die Klasse, zu der er am besten passt, und so wird Taschenkram zum nächsten Upgrade für jemand anderen. Gib es weiter, ein grünes Teil nach dem anderen."
L["OPTIONS_WELCOME"] = "Willkommensnachricht aktivieren"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Beim Einloggen die Version und den Hinweis zu den Einstellungen ausgeben."

L["OPTIONS_FEATURES_HEADER"] = "Funktionen"

L["OPTIONS_COMMANDS_HEADER"] = "/Befehle"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Öffnet das Optionsmenü dieses Add-ons."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "Was verschenkt wird"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Wähle, was du an andere Spieler verschenkst. Ausrüstung und Verbrauchsgüter kannst du auch jederzeit oben im Verteilungsfenster ändern."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"Die höchste angebotene Seltenheit. Alles darüber wird nie aufgelistet, damit ein guter Fund nicht versehentlich verschickt wird."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Ausrüstung verteilen"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Beim Anlegen gebundene Waffen und Rüstung anbieten."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Verbrauchsgüter verteilen"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Niedrigstufiges Essen, Trinken, Tränke, Schriftrollen, Öle und Steine anbieten, aus denen du herausgewachsen bist."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "Öle & Steine"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Waffenöle, Wetzsteine und Gewichtssteine anbieten, aus denen du herausgewachsen bist. Zauberöle gehen an Zauberwirker, Manaöle an alle mit Mana, Steine und andere Öle an Nahkämpfer."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Nicht zugeordnete Gegenstände entzaubern"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"Ausrüstung, die niemandem zugeordnet wurde, kann per Post zum Entzaubern an einen deiner eigenen Charaktere gehen, statt in deinen Taschen zu bleiben. Schalte es ein und wähle dann, welcher Charakter sie bekommt. Jeder Realm und jede Fraktion merkt sich eine eigene Wahl."
L["OPTIONS_DISENCHANT_SEND"] = "Nicht zugeordnete Gegenstände an Verzauberer schicken"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"Ausrüstung, die niemand nutzen kann, geht zum Entzaubern an einen deiner Charaktere, statt in deinen Taschen zu bleiben. Verbrauchsgüter werden nie verschickt."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Dein Verzauberer. Listet deine Charaktere auf diesem Realm und seinen verbundenen Realms in dieser Fraktion auf, sobald sich jeder mit Play It Forward eingeloggt hat."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Empfänger"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"Wer deine Ausrüstung bekommt und in welcher Reihenfolge. Auf den Seiten Meine Twinks und Meine Gilden unten legst du fest, welche deiner Charaktere und Gilden zählen."

L["OPTIONS_PRIORITY_HEADER"] = "Wer zuerst dran ist"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Deine eigenen Charaktere und Gildenmitglieder dürfen sich vorne anstellen bei allem, was ihnen genauso gut passt wie einem Fremden. Entfernst du einen der Haken, konkurrieren diese mit allen anderen nach Stufe und Aufenthaltsort."
L["OPTIONS_PRIORITIZE_ALTS"] = "Meine Twinks zuerst beschenken, dann Fremde und Meine Gilden"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Deine eigenen Charaktere dürfen sich zuerst nehmen, was ihnen genauso gut passt wie jedem anderen. Ohne Haken konkurrieren sie mit allen anderen nach Stufe und Aufenthaltsort."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Meine Gilden zuerst beschenken, dann Fremde"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Deine Gildenmitglieder haben vor Fremden den Vortritt bei allem, was ihnen genauso gut passt. Ohne Haken konkurrieren sie mit Fremden nach Stufe und Aufenthaltsort."

L["OPTIONS_STRANGERS_HEADER"] = "Bei der Suche nach Fremden"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Wie per /who gefundene Spieler gegeneinander abgewogen werden. Bei gleich guter Eignung geht Ausrüstung zuerst an den, der am wahrscheinlichsten levelt und sie auch nutzen wird."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Fremde in stufengerechten Gebieten bevorzugen"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Biete Ausrüstung zuerst Spielern an, die in einem Gebiet für ihre Stufe questen, noch vor Spielern in einer Stadt. Gerade sie wissen deine Freundlichkeit am ehesten zu schätzen."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Fremde außerhalb von Instanzen bevorzugen"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Biete Spielern in einem Dungeon oder Schlachtzug nur dann Ausrüstung an, wenn draußen in der Welt niemand Passendes ist. Spieler in einem Dungeon werden oft nur durchgezogen und brauchen die Ausrüstung nicht lange."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Hexenmeister der Stufe %d-%d ignorieren"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Fremden Hexenmeistern in diesem Stufenbereich nie Ausrüstung anbieten. Hexenmeister lernen mit Stufe 20 das Beschwören, und viele Spieler parken hier einen Hexenmeister-Twink, nur um Freunde zu beschwören, daher bleibt an sie geschickte Ausrüstung oft ungenutzt. Deine eigenen Charaktere und Gildenmitglieder sind nicht betroffen."

L["OPTIONS_SPECS_HEADER"] = "Klassen & Spezialisierungen"
L["OPTIONS_SPECS_INTRO"] =
	"Niemand kann die Spezialisierung eines anderen Spielers sehen, daher wird Ausrüstung nach diesen Annahmen verschickt. Deine eigenen Charaktere nutzen die unter Meine Twinks eingestellten Spezialisierungen."
L["OPTIONS_SPECS_RESET"] = "Standards wiederherstellen"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "Setzt jede Spezialisierung auf den Auslieferungszustand des Add-ons zurück."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Zauberschaden"
L["ROLE_MELEE"] = "Nahkampfschaden"
L["ROLE_RANGED"] = "Fernkampfschaden"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Waffen"
L["SPEC_Fury"] = "Furor"
L["SPEC_Protection"] = "Schutz"
L["SPEC_Holy"] = "Heilig"
L["SPEC_Retribution"] = "Vergeltung"
L["SPEC_BeastMastery"] = "Tierherrschaft"
L["SPEC_Marksmanship"] = "Treffsicherheit"
L["SPEC_Survival"] = "Überleben"
L["SPEC_Assassination"] = "Meucheln"
L["SPEC_Combat"] = "Kampf"
L["SPEC_Subtlety"] = "Täuschung"
L["SPEC_Discipline"] = "Disziplin"
L["SPEC_Shadow"] = "Schatten"
L["SPEC_Elemental"] = "Elementar"
L["SPEC_Enhancement"] = "Verstärkung"
L["SPEC_Restoration"] = "Wiederherstellung"
L["SPEC_Arcane"] = "Arkan"
L["SPEC_Fire"] = "Feuer"
L["SPEC_Frost"] = "Frost"
L["SPEC_Affliction"] = "Gebrechen"
L["SPEC_Demonology"] = "Dämonologie"
L["SPEC_Destruction"] = "Zerstörung"
L["SPEC_Balance"] = "Gleichgewicht"
L["SPEC_Feral"] = "Wilder Kampf"
L["SPEC_Guardian"] = "Wächter"
L["SPEC_Blood"] = "Blut"
L["SPEC_Unholy"] = "Unheilig"
L["SPEC_Brewmaster"] = "Braumeister"
L["SPEC_Mistweaver"] = "Nebelwirker"
L["SPEC_Windwalker"] = "Windläufer"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Schutz"
L["SPEC_DRUID_Restoration"] = "Wiederherstellung"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Tank (Runen)"
L["SPEC_Healer"] = "Heiler (Runen)"
L["SPEC_Melee"] = "Nahkampf (Runen)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "Meine Twinks"
L["OPTIONS_ALTS_INTRO"] =
	"Deine eigenen Charaktere, jeweils hinzugefügt, sobald sie sich mit Play It Forward einloggen. Wähle links einen aus, um festzulegen, ob er Post bekommt und für welche Spezialisierungen er Ausrüstung erhält."
L["OPTIONS_SEND_TO_ALTS"] = "An Twinks schicken"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Schicke zuerst an deine eigenen Charaktere, noch vor deiner Gilde und Fremden, aber nur Gegenstände, für die ihre Klasse am besten geeignet ist. Ein Charakter zählt, sobald er sich auf diesem Realm oder einem verbundenen Realm in dieser Fraktion mit Play It Forward eingeloggt hat. Post an deine Twinks zählt nicht für deine Summen im Abzeichen der Großzügigkeit."
L["OPTIONS_ALTS_EMPTY"] =
	"Noch keine Charaktere. Jeder deiner Charaktere erscheint hier, sobald er sich mit Play It Forward einloggt."
L["OPTIONS_ALT_INCLUDE"] = "Diesen Charakter einbeziehen"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Diesem Charakter Ausrüstung schicken. Ohne Haken wird ihm nie etwas angeboten. Ein Charakter auf der Höchststufe startet ohne Haken."
L["OPTIONS_ALT_SPECS"] = "Ausrüstung schicken für"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Diesem Charakter Ausrüstung für diese Spezialisierung anbieten. Anfangs ist die zuletzt gespielte Spezialisierung gewählt, oder jede, solange er noch keine hat."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Ausrüstungsstufen"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Niedrigste"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"Die niedrigste Ausrüstungsstufe, die dieser Charakter per Post bekommt. Bei Charakterstufe kommt nichts unter seiner Stufe; bei Charakterstufe -2 auch Ausrüstung bis zu zwei Stufen darunter, die er jetzt schon tragen kann."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Höchste"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"Die höchste Ausrüstungsstufe, die dieser Charakter per Post bekommt. Bei Alles Nutzbare kommt alles, in das er noch hineinwächst, sodass ein Jäger der Stufe 1 einen Bogen der Stufe 50 bekommen kann."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Charakterstufe"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Charakterstufe -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Charakterstufe +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Alles Nutzbare"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Bekommt Ausrüstung für Stufe %d bis %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Bekommt Ausrüstung ab Stufe %d."
L["OPTIONS_DELETE"] = "Löschen"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "%s vergessen? Der Charakter wird beim nächsten Einloggen wieder hinzugefügt."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] =
	"Diesen Charakter vergessen. Er wird beim nächsten Einloggen wieder hinzugefügt."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Meine Gilden"
L["OPTIONS_GUILDS_INTRO"] =
	"Jede Gilde deiner Charaktere, gespeichert, sobald sich einer von ihnen einloggt. So kannst du mit jedem Charakter den Gildenmitgliedern Post schicken, die noch leveln."
L["OPTIONS_GUILD_OFFLINE"] = "Offline-Gildenmitglieder ignorieren"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Überspringe Gildenmitglieder, die länger als hier eingestellt nicht online waren, in deiner aktuellen Gilde und in deinen gespeicherten. Wähle Nie, um alle einzubeziehen, egal wie lange sie weg waren."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Länger als 1 Woche"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Länger als 2 Wochen"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Nie"
L["OPTIONS_GUILDS_EMPTY"] =
	"Noch keine Gilden. Eine Gilde erscheint hier, sobald sich einer deiner Charaktere darin einloggt."
L["OPTIONS_GUILD_INCLUDE"] = "Mitgliedern dieser Gilde schicken"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Den Mitgliedern dieser Gilde Ausrüstung schicken."
L["OPTIONS_GUILD_MEMBERS"] = "Aktive Mitglieder"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "Niemand in dieser Liste war kürzlich genug aktiv, um Gegenstände zu bekommen."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Einbeziehen"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Diesem Gildenmitglied Ausrüstung schicken. Entferne den Haken bei einer Gildenbank oder einem Berufe-Twink, dann wird ihm nie etwas angeboten."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d aktive Mitglieder, gespeichert %s von %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "heute"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "gestern"
L["OPTIONS_GUILD_SAVED_DAYS"] = "vor %d Tagen"
L["OPTIONS_GUILD_CURRENT"] = "Deine aktuelle Gilde, frisch am Briefkasten eingelesen."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "Auf einem anderen Realm, daher kann Post sie von hier nicht erreichen."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "In der anderen Fraktion, daher kann Post sie von hier nicht erreichen."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Text der Postnachricht"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"Die Nachricht, die jedem Geschenk beiliegt. Schreibe links deine eigene und sieh rechts genau, was verschickt wird. Änderungen werden beim Tippen gespeichert; leere ein Feld, um zum Standardtext zurückzukehren."
L["OPTIONS_MAIL_SUBJECT"] = "Betreff"
L["OPTIONS_MAIL_BODY"] = "Text"
L["OPTIONS_MAIL_YOURS"] = "Deine Nachricht"
L["OPTIONS_MAIL_PREVIEW"] = "Was sie erhalten"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Betreff %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Text %d/%d"
L["OPTIONS_MAIL_RESET"] = "Standard wiederherstellen"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Zum Standardbetreff und -text zurückkehren."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Abzeichen der Großzügigkeit"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Deine Summen an Geschenken, von allen Charakteren deines Accounts. Sie erscheinen in Städten und Gasthäusern in deinem Spieler-Tooltip, wo andere Nutzer von Play It Forward sie sehen, wenn sie mit der Maus über dich fahren, und du siehst ihre. In Dungeons, Schlachtzügen und draußen in der Welt sind sie verborgen."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Abzeichen der Großzügigkeit"
L["OPTIONS_GENEROSITY_GIFTS"] = "Geschenke"
L["OPTIONS_GENEROSITY_ITEMS"] = "Gegenstände"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Gegenstandsstufen"
L["OPTIONS_GENEROSITY_VALUE"] = "Goldwert"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Spieler-Tooltips für Abzeichen der Großzügigkeit aktivieren"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Spieler in deiner Nähe in Städten und Gasthäusern sehen deine Summen in deinem Tooltip. Ausschalten beendet das Teilen, du siehst ihre aber weiterhin, und deine eigenen Summen zählen so oder so weiter."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Hilf Play It Forward beim Leveln"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Dieses Add-on wurde von Spielern entwickelt, die dieses Spiel lieben und es für alle so unterhaltsam wie möglich machen wollen. Wir werden nie um Spenden bitten. Die wahre Belohnung ist das Wissen, dass unsere Arbeit das Spiel für dich ein bisschen besser macht. Wenn das so ist, würden wir uns freuen, davon zu hören!"
L["OPTIONS_LEVEL_UP_WAYS"] = "Hier sind ein paar Möglichkeiten, wie du uns helfen kannst, mehr Spieler zu erreichen."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Feedback geben: Einen Fehler gefunden oder eine Idee? Sag es uns auf Discord. Dein Feedback hilft uns, das Add-on zu verbessern, und Pull Requests sind immer willkommen."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Einem Freund erzählen: Kennst du jemanden, dem dieses Add-on gefallen könnte? Erzähl ihm davon. Mundpropaganda hilft mehr Spielern, großartige Add-ons zu entdecken."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Favorit auf CurseForge: Öffne unten den CurseForge-Link, melde dich an und klicke auf den Stern unter dem Download-Button. Favoriten helfen mehr Spielern, das Add-on zu entdecken."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star auf GitHub: Öffne unten den GitHub-Link, melde dich an und klicke oben rechts auf Star. Stars helfen dem Projekt, sich für mehr kostenlose Entwicklerwerkzeuge zu qualifizieren."
L["OPTIONS_LEVEL_UP_THANKS"] = "Danke, dass du dich für Play It Forward entschieden hast!"

L["OPTIONS_FEEDBACK"] = "Feedback & Unterstützung"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Links für Feedback & Unterstützung"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "Um einen Link zu kopieren, klicke in sein Feld und drücke dann Strg+A und Strg+C."
L["OPTIONS_VERSION"] = "Version %s"
