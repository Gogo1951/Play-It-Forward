local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "itIT")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Versione %s. Le impostazioni (inclusa l'opzione per disattivare questo messaggio) si trovano in Opzioni > AddOn > Play It Forward. Ti piace l'add-on? Parlane a un amico! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Per precauzione, l'interfaccia delle opzioni non può essere aperta in combattimento."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipaggiamento"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumabili"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s e inferiore"

L["BUTTON_FIND_RECIPIENTS"] = "Trova destinatari"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Ricerca..."
L["BUTTON_DISTRIBUTE"] = "Distribuisci"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Richiede cassetta postale aperta"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Premi di nuovo Trova destinatari. Blizzard consente questa ricerca solo direttamente dalla pressione di un pulsante, e qualcosa ha interrotto questa."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Non resta niente da regalare."
L["WINDOW_EMPTY_HINT"] = "Cambia Equipaggiamento o Consumabili qui sopra per vederne altri."

L["SECTION_MATCHED"] = "Assegnati"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "In attesa di assegnazione"
L["SECTION_UNREADABLE"] = "Statistiche illeggibili"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Tenuto"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Nessun destinatario"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Illeggibile"

L["PICKER_KEEP_OPTION"] = "Tieni oggetto"
L["PICKER_NONE_IN_RANGE"] = "Nessuno nella fascia di livello. Premi Trova destinatari."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(ne ha uno)"
L["PICKER_NOTE_REFUSED"] = "(rifiutato)"
L["PICKER_NOTE_RECENT"] = "(recente)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Trova destinatari per questo oggetto"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatario"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato/i, livelli %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Clicca per riassegnare."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Impossibile leggere le statistiche di questo oggetto, quindi non viene assegnato."
L["TOOLTIP_RECIPIENT_KEPT"] = "Nessuna classe lo vuole, quindi resta nelle tue borse."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Inviato quando premi Distribuisci. Togli la spunta per tenerlo."
L["TOOLTIP_CHECK_WAITING"] = "Assegnato appena una ricerca trova qualcuno. Togli la spunta per tenerlo."

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
L["MAIL_STILL_SENDING"] = "Invio in corso, un attimo."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Niente da distribuire."
L["MAIL_DISTRIBUTING"] = "Clicca Accetta in ogni finestra di conferma per inviare %d oggetto/i."
L["MAIL_ITEM_MOVED"] = "Premi Trova destinatari per ripetere la scansione. %s è stato spostato nelle tue borse."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Scegli qualcun altro per %s. %s ne riceve già uno."
L["MAIL_NOT_AT_MAILBOX"] = "Torna a una cassetta postale e premi Distribuisci per inviare il resto."
L["MAIL_MAILBOX_CLOSED"] =
	"Apri una cassetta postale e premi Distribuisci per inviare il resto. La cassetta postale si è chiusa a metà."
L["MAIL_NO_POSTAGE"] = "Aggiungi un po' di rame per l'affrancatura, poi premi Distribuisci per inviare il resto."
L["MAIL_PANEL_CLOSED"] =
	"Apri il pannello di invio posta di Blizzard e premi di nuovo Distribuisci. Non è stato inviato né toccato niente."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Se usi TSM, passa all'interfaccia di posta predefinita per questo. La cassetta postale di TSM non accetta allegati."
L["MAIL_ATTACH_FAILED"] = "Impossibile allegare %s, quindi non è stato inviato."
L["MAIL_AWAITING_CONFIRM"] = "Clicca Accetta nella finestra per %s, poi premi Distribuisci per inviare il resto."
L["MAIL_SENT"] = "%s inviato a %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Posta a %s non riuscita (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "nessun motivo indicato"
L["MAIL_REASON_ERROR"] = "errore del client"
L["MAIL_ABORTED"] = "Distribuzione interrotta dopo ripetuti errori di posta."
L["MAIL_DONE"] = "Fatto. %d di %d inviati."
L["MAIL_DONE_WITH_SKIPS"] = "Fatto. %d di %d inviati, %d saltati (spostati nelle tue borse)."
L["MAIL_SUBJECT_TOO_LONG"] = "L'oggetto è di %d caratteri e la posta ne accetta solo %d, quindi verrà troncato."
L["MAIL_BODY_TOO_LONG"] = "Il testo è di %d caratteri e la posta ne accetta solo %d, quindi verrà troncato."

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
	"Invia l'equipaggiamento e i consumabili che non ti servono più a compagni di gilda o a sconosciuti che sapranno apprezzarli. Ogni oggetto viene assegnato alla classe a cui si addice di più, trasformando il disordine dimenticato nelle tue borse nel prossimo potenziamento di qualcun altro. Passalo avanti, un oggetto verde alla volta."
L["OPTIONS_WELCOME"] = "Attiva messaggio di benvenuto"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Mostra la versione e il promemoria delle impostazioni all'accesso."

L["OPTIONS_COMMANDS_HEADER"] = "/Comandi"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Apre l'interfaccia delle opzioni di questo add-on."

L["OPTIONS_GIVE_HEADER"] = "Cosa regalare"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rarità più alta offerta. Niente al di sopra viene mai elencato, così un buon bottino non può essere spedito per sbaglio."
L["OPTIONS_INCLUDE_GEAR"] = "Includi equipaggiamento"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Offri armi e armature che si vincolano quando equipaggiate."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Includi consumabili"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Offri cibo, bevande, pozioni e pergamene di basso livello che hai superato."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Superati di %d+ livelli"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Tutti i consumabili"
L["OPTIONS_CONSUMABLE_GAP"] = "Regola di livello"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"Di quanti livelli devi superare un consumabile prima che conti come superfluo. Con 20 o più, un'acqua di livello 35 viene offerta quando raggiungi il livello 55. Tutti i consumabili offre ognuno di quelli nelle tue borse, qualunque sia il tuo livello."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Cibo"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Offri il cibo che hai superato. Il cibo che ripristina anche mana viene offerto finché Cibo o Bevande è attivo."
L["OPTIONS_KIND_DRINK"] = "Bevande"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Offri acqua, succhi e altre bevande che hai superato."
L["OPTIONS_KIND_POTIONS"] = "Pozioni"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "Offri pozioni di cura, mana e ringiovanimento che hai superato."
L["OPTIONS_KIND_SCROLLS"] = "Pergamene"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Offri pergamene di statistica che hai superato. Ognuna va alle classi che usano la sua statistica."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Generosità"
L["OPTIONS_GENEROSITY_GIFTS"] = "Regali"
L["OPTIONS_GENEROSITY_ITEMS"] = "Oggetti"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Livelli oggetto"
L["OPTIONS_GENEROSITY_VALUE"] = "Valore in oro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Attiva tooltip di generosità"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"I giocatori vicini a te in città e locande possono vedere i tuoi totali nel tuo tooltip. Disattivandolo smetti di condividerli, ma continui a vedere i loro, e i tuoi totali qui sotto continuano a contare in ogni caso."

L["OPTIONS_FEEDBACK_HEADER"] = "Feedback e supporto"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Versione %s"
