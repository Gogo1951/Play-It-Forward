local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "itIT")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Finestra di distribuzione"
L["CHAT_LOADED"] =
	"Versione %s. Le impostazioni (inclusa l'opzione per disattivare questo messaggio) si trovano in Opzioni > AddOn > Play It Forward. Ti piace questo add-on? Parlane a un amico, aggiungilo ai preferiti su CurseForge o dagli una Star su GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Per precauzione, l'interfaccia delle opzioni non può essere aperta in combattimento."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipaggiamento"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumabili"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Disincanta"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Scegli un personaggio"
L["WINDOW_DISENCHANT_NONE"] = "I tuoi personaggi compaiono quando ognuno accede con Play It Forward."

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
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Invio..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "Nuova ricerca tra %d s. Riprova quando il pulsante mostra Trova destinatari."
L["WHO_BLOCKED"] =
	"Premi di nuovo Trova destinatari. Blizzard consente questa ricerca solo direttamente dalla pressione di un pulsante, e qualcosa ha interrotto questa."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Mostra cosa puoi regalare dalle tue borse."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Non resta niente da regalare."
L["WINDOW_EMPTY_HINT"] = "Cambia le impostazioni qui sopra per vederne altri."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Premi Trova destinatari per cercare giocatori per %d oggetto/i."
L["STATUS_MORE"] = "%d ricerca/e in programma. Premi Trova destinatari per continuare."
L["STATUS_DONE"] = "Ricerca finita. Nessuno in fascia per %d oggetto/i. Riprova più tardi."
L["STATUS_READY"] = "Premi Distribuisci per inviare %d oggetto/i."
L["STATUS_AWAY"] = "Apri una cassetta postale per inviare %d oggetto/i."
L["STATUS_SENDING"] = "Invio %d di %d. Clicca Accetta in ogni finestra."

L["SECTION_MATCHED"] = "Assegnati"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "In attesa di assegnazione"
L["SECTION_UNREADABLE"] = "Statistiche illeggibili"

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
L["WINDOW_KEPT"] = "Tenuto"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Nessun destinatario"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Statistiche non lette"

L["PICKER_KEEP_OPTION"] = "Tieni oggetto"
L["PICKER_NONE_IN_RANGE"] = "Nessuno nella fascia di livello. Premi Trova destinatari."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(ne ha uno)"
L["PICKER_NOTE_REFUSED"] = "(rifiutato)"
L["PICKER_NOTE_RECENT"] = "(recente)"
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Già su un'altra riga. La tua scelta ha la precedenza, e una riga che non hai impostato tu trova qualcun altro."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Una posta inviata a questo giocatore è tornata indietro in questa sessione. Puoi comunque riprovare."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Ha già ricevuto un regalo da te in questa sessione. Torna in cima alla lista quando sale di livello."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Trova destinatari per questo oggetto"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "I tuoi alt"
L["PICKER_SECTION_GUILD"] = "La tua gilda"
L["PICKER_SECTION_STRANGERS"] = "Sconosciuti"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Disincanta"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatario"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato/i, livelli %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Clicca per riassegnare."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Più adatto a: %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Impossibile leggere le statistiche di questo oggetto, quindi non viene assegnato."
L["TOOLTIP_RECIPIENT_KEPT"] = "Nessuna classe lo vuole, quindi resta nelle tue borse."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "Nessuno può usarlo, quindi va a %s per essere disincantato."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Inviato quando premi Distribuisci. Togli la spunta per tenerlo."
L["TOOLTIP_CHECK_WAITING"] = "Assegnato appena una ricerca trova qualcuno. Togli la spunta per tenerlo."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Scegli qualcuno dalla lista per inviarlo."
L["TOOLTIP_CHECK_UNREADABLE"] = "Non può essere inviato finché le sue statistiche non sono leggibili."

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
L["MAIL_STILL_SENDING"] = "Invio in corso. Un attimo."
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
	"Se usi TSM, passa al pannello di invio posta di Blizzard per questo. La cassetta postale di TSM non accetta allegati."
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
	"Spedisci per posta l'equipaggiamento ancora scambiabile, il cibo, le pozioni, le pergamene, gli oli e le pietre che non ti servono più ai tuoi alt, ai compagni di gilda e ai giocatori che stanno salendo di livello. Ogni oggetto va alla classe a cui si addice di più, trasformando il disordine nelle tue borse nel prossimo potenziamento di qualcun altro. Passalo avanti, un oggetto verde alla volta."
L["OPTIONS_WELCOME"] = "Attiva messaggio di benvenuto"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Mostra la versione e il promemoria delle impostazioni all'accesso."

L["OPTIONS_FEATURES_HEADER"] = "Funzionalità"

L["OPTIONS_COMMANDS_HEADER"] = "/Comandi"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Apre l'interfaccia delle opzioni di questo add-on."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "Cosa regalare"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Scegli cosa regalare agli altri giocatori. Puoi anche cambiare equipaggiamento e consumabili in qualsiasi momento in cima alla Finestra di distribuzione."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rarità più alta offerta. Niente al di sopra viene mai elencato, così un buon bottino non può essere spedito per sbaglio."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Distribuisci equipaggiamento"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Offri armi e armature che si vincolano quando equipaggiate."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Distribuisci consumabili"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Offri cibo, bevande, pozioni, pergamene, oli e pietre di basso livello che hai superato."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "Oli e pietre"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Offri oli per armi, pietre per affilare e pietre per appesantire che hai superato. Gli oli da mago vanno a chi lancia incantesimi, gli oli di mana a chi usa il mana, e le pietre e gli altri oli a chi combatte in mischia."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Disincanta oggetti non assegnati"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"L'equipaggiamento non assegnato a nessuno può essere spedito a uno dei tuoi personaggi per essere disincantato, invece di restare nelle tue borse. Attivalo, poi scegli quale personaggio lo riceve. Ogni reame e fazione ha la sua scelta."
L["OPTIONS_DISENCHANT_SEND"] = "Invia oggetti non assegnati all'incantatore"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"L'equipaggiamento che nessuno può usare va a uno dei tuoi personaggi per essere disincantato, invece di restare nelle tue borse. I consumabili non vengono mai inviati."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Il tuo incantatore. Elenca i tuoi personaggi di questo reame e dei reami connessi, di questa fazione, una volta che ognuno ha effettuato l'accesso con Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Destinatari"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"A chi va il tuo equipaggiamento, e in che ordine. Scegli quali dei tuoi personaggi e delle tue gilde contano nelle pagine I miei alt e Le mie gilde qui sotto."

L["OPTIONS_PRIORITY_HEADER"] = "Chi viene prima"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"I tuoi personaggi e i compagni di gilda possono passare in testa alla fila per tutto ciò che si addice a loro quanto a uno sconosciuto. Togli la spunta a uno dei due e competeranno con tutti gli altri per livello e posizione."
L["OPTIONS_PRIORITIZE_ALTS"] = "Dai priorità a I miei alt rispetto agli sconosciuti e a Le mie gilde"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"I tuoi personaggi hanno la prima scelta su tutto ciò che si addice a loro quanto a chiunque altro. Senza spunta, competono con tutti gli altri per livello e posizione."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Dai priorità a Le mie gilde rispetto agli sconosciuti"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"I tuoi compagni di gilda hanno la precedenza sugli sconosciuti per tutto ciò che si addice a loro altrettanto bene. Senza spunta, competono con gli sconosciuti per livello e posizione."

L["OPTIONS_STRANGERS_HEADER"] = "Quando cerchi sconosciuti"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Come vengono confrontati tra loro i giocatori trovati con /who. A parità di idoneità, l'equipaggiamento va prima a chi molto probabilmente sta salendo di livello e lo userà davvero."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Dai priorità agli sconosciuti in zone adatte al loro livello"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Offri l'equipaggiamento prima ai giocatori che fanno missioni in una zona pensata per il loro livello, rispetto a quelli in città. Sono loro i più propensi ad apprezzare la tua gentilezza."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Dai priorità agli sconosciuti fuori dalle istanze"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Offri l'equipaggiamento ai giocatori in una spedizione o in un'incursione solo quando non c'è nessuno adatto in giro per il mondo. I giocatori in spedizione possono essere personaggi che si fanno trascinare da altri, e l'equipaggiamento non servirà loro a lungo."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Ignora stregoni di livello %d-%d"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Non offrire mai equipaggiamento a sconosciuti che sono stregoni in questa fascia di livello. Gli stregoni imparano a evocare al livello 20, e molti giocatori parcheggiano qui uno stregone alt solo per evocare gli amici, quindi l'equipaggiamento inviato loro spesso resta inutilizzato. I tuoi personaggi e i compagni di gilda non sono interessati."

L["OPTIONS_SPECS_HEADER"] = "Classi e specializzazioni"
L["OPTIONS_SPECS_INTRO"] =
	"Nessuno può vedere la specializzazione di un altro giocatore, quindi l'equipaggiamento viene inviato in base a queste ipotesi. I tuoi personaggi usano le specializzazioni impostate in I miei alt."
L["OPTIONS_SPECS_RESET"] = "Ripristina predefiniti"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "Riporta ogni specializzazione alle impostazioni originali dell'add-on."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Danni magici"
L["ROLE_MELEE"] = "Danni in mischia"
L["ROLE_RANGED"] = "Danni a distanza"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Armi"
L["SPEC_Fury"] = "Furia"
L["SPEC_Protection"] = "Protezione"
L["SPEC_Holy"] = "Sacro"
L["SPEC_Retribution"] = "Castigo"
L["SPEC_BeastMastery"] = "Affinità Animale"
L["SPEC_Marksmanship"] = "Precisione di Tiro"
L["SPEC_Survival"] = "Sopravvivenza"
L["SPEC_Assassination"] = "Assassinio"
L["SPEC_Combat"] = "Combattimento"
L["SPEC_Subtlety"] = "Scaltrezza"
L["SPEC_Discipline"] = "Disciplina"
L["SPEC_Shadow"] = "Ombra"
L["SPEC_Elemental"] = "Elementale"
L["SPEC_Enhancement"] = "Potenziamento"
L["SPEC_Restoration"] = "Rigenerazione"
L["SPEC_Arcane"] = "Arcano"
L["SPEC_Fire"] = "Fuoco"
L["SPEC_Frost"] = "Gelo"
L["SPEC_Affliction"] = "Afflizione"
L["SPEC_Demonology"] = "Demonologia"
L["SPEC_Destruction"] = "Distruzione"
L["SPEC_Balance"] = "Equilibrio"
L["SPEC_Feral"] = "Aggressore"
L["SPEC_Guardian"] = "Guardiano"
L["SPEC_Blood"] = "Sangue"
L["SPEC_Unholy"] = "Empietà"
L["SPEC_Brewmaster"] = "Mastro Birraio"
L["SPEC_Mistweaver"] = "Misticismo"
L["SPEC_Windwalker"] = "Impeto"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Protezione"
L["SPEC_DRUID_Restoration"] = "Rigenerazione"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Difensore (rune)"
L["SPEC_Healer"] = "Guaritore (rune)"
L["SPEC_Melee"] = "Mischia (rune)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "I miei alt"
L["OPTIONS_ALTS_INTRO"] =
	"I tuoi personaggi, ognuno aggiunto quando accede con Play It Forward. Scegline uno a sinistra per decidere se riceve posta e per quali specializzazioni gli viene inviato equipaggiamento."
L["OPTIONS_SEND_TO_ALTS"] = "Invia agli alt"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Spedisci innanzitutto ai tuoi personaggi, davanti alla tua gilda e agli sconosciuti, ma solo gli oggetti per cui la loro classe è la più adatta. Un personaggio conta una volta che ha effettuato l'accesso con Play It Forward su questo reame o su uno connesso, di questa fazione. La posta ai tuoi alt non conta per i totali della Medaglia della Generosità."
L["OPTIONS_ALTS_EMPTY"] =
	"Ancora nessun personaggio. Ognuno dei tuoi personaggi compare qui quando accede con Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Includi questo personaggio"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Spedisci equipaggiamento a questo personaggio. Senza spunta, non gli viene mai offerto niente. Un personaggio al livello massimo parte senza spunta."
L["OPTIONS_ALT_SPECS"] = "Spedisci equipaggiamento per"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Offri a questo personaggio equipaggiamento per questa specializzazione. All'inizio è attiva l'ultima specializzazione giocata, oppure tutte finché non ne ha una."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Livelli dell'equipaggiamento"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Minimo"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"L'equipaggiamento di livello più basso spedito a questo personaggio. Il suo livello non invia nulla sotto il suo livello; Il suo livello -2 invia anche equipaggiamento fino a due livelli sotto, che può già indossare."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Massimo"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"L'equipaggiamento di livello più alto spedito a questo personaggio. Qualsiasi equipaggiamento utilizzabile invia tutto ciò che potrà usare crescendo, così a un cacciatore di livello 1 può arrivare un arco di livello 50."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Il suo livello"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Il suo livello -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Il suo livello +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Qualsiasi equipaggiamento utilizzabile"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Equipaggiamento spedito per i livelli da %d a %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Equipaggiamento spedito dal livello %d in su."
L["OPTIONS_DELETE"] = "Elimina"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "Dimenticare %s? Verrà aggiunto di nuovo al prossimo accesso."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "Dimentica questo personaggio. Verrà aggiunto di nuovo al prossimo accesso."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Le mie gilde"
L["OPTIONS_GUILDS_INTRO"] =
	"Ogni gilda in cui si trovano i tuoi personaggi, salvata ogni volta che uno di loro accede, così qualunque personaggio tu stia usando può spedire ai compagni di gilda che stanno salendo di livello."
L["OPTIONS_GUILD_OFFLINE"] = "Ignora membri della gilda offline"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Salta i compagni di gilda che non accedono da più di questo tempo, nella gilda in cui sei ora e in quelle salvate. Scegli Mai per includere tutti, per quanto tempo siano stati assenti."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Da più di 1 settimana"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Da più di 2 settimane"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Mai"
L["OPTIONS_GUILDS_EMPTY"] =
	"Ancora nessuna gilda. Una gilda compare qui quando accede uno dei tuoi personaggi che ne fa parte."
L["OPTIONS_GUILD_INCLUDE"] = "Spedisci ai membri di questa gilda"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Spedisci equipaggiamento ai membri di questa gilda."
L["OPTIONS_GUILD_MEMBERS"] = "Membri attivi"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "Nessuno in questo elenco è stato attivo abbastanza di recente da ricevere oggetti."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Includi"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Spedisci equipaggiamento a questo compagno di gilda. Togli la spunta per una banca di gilda o un alt per le professioni, e non gli verrà mai offerto niente."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d membri attivi, salvati %s da %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "oggi"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "ieri"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d giorni fa"
L["OPTIONS_GUILD_CURRENT"] = "La tua gilda attuale, aggiornata ogni volta alla cassetta postale."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "Su un altro reame, quindi la posta non può raggiungerla da qui."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "Nell'altra fazione, quindi la posta non può raggiungerla da qui."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Testo del messaggio"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"Il biglietto che accompagna ogni regalo. Scrivi il tuo a sinistra e guarda a destra esattamente cosa viene inviato. Le modifiche si salvano mentre scrivi; svuota un campo per tornare al testo predefinito."
L["OPTIONS_MAIL_SUBJECT"] = "Oggetto"
L["OPTIONS_MAIL_BODY"] = "Testo"
L["OPTIONS_MAIL_YOURS"] = "Il tuo messaggio"
L["OPTIONS_MAIL_PREVIEW"] = "Cosa ricevono"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Oggetto %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Testo %d/%d"
L["OPTIONS_MAIL_RESET"] = "Ripristina predefinito"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Torna all'oggetto e al testo predefiniti."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Medaglia della Generosità"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"I tuoi totali di donazioni, da tutti i personaggi del tuo account. Compaiono nel tuo tooltip del giocatore in città e locande, dove gli altri utenti di Play It Forward li vedono passando il cursore su di te, e tu vedi i loro. Sono nascosti in spedizioni, incursioni e in giro per il mondo."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Medaglia della Generosità"
L["OPTIONS_GENEROSITY_GIFTS"] = "Regali"
L["OPTIONS_GENEROSITY_ITEMS"] = "Oggetti"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Livelli oggetto"
L["OPTIONS_GENEROSITY_VALUE"] = "Valore in oro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Attiva i tooltip della Medaglia della Generosità"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"I giocatori vicini a te in città e locande possono vedere i tuoi totali nel tuo tooltip. Disattivandolo smetti di condividerli, ma continui a vedere i loro, e i tuoi totali continuano a contare in ogni caso."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Aiuta Play It Forward a salire di livello"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Questo add-on è stato creato da giocatori che amano questo gioco e vogliono renderlo il più divertente possibile per tutti. Non chiederemo mai donazioni. La vera soddisfazione è sapere che il nostro lavoro rende il gioco un po' migliore per te. Se è così, ci farebbe piacere saperlo!"
L["OPTIONS_LEVEL_UP_WAYS"] = "Ecco alcuni modi in cui puoi aiutarci a raggiungere più giocatori."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Condividi il tuo feedback: Hai trovato un bug o hai un'idea? Faccelo sapere su Discord. Il tuo feedback ci aiuta a migliorare l'add-on, e le pull request sono sempre benvenute."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Parlane a un amico: Conosci qualcuno a cui potrebbe piacere questo add-on? Parlagliene. Il passaparola aiuta più giocatori a scoprire ottimi add-on."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Preferito su CurseForge: Apri il link di CurseForge qui sotto, accedi e clicca sulla stella sotto il pulsante Download. I preferiti aiutano più giocatori a scoprire l'add-on."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star su GitHub: Apri il link di GitHub qui sotto, accedi e clicca su Star in alto a destra. Le stelle aiutano il progetto a ottenere più strumenti gratuiti per sviluppatori."
L["OPTIONS_LEVEL_UP_THANKS"] = "Grazie per aver scelto Play It Forward!"

L["OPTIONS_FEEDBACK"] = "Feedback e supporto"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Link di feedback e supporto"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "Per copiare un link, clicca sulla sua casella, poi premi Ctrl+A e Ctrl+C."
L["OPTIONS_VERSION"] = "Versione %s"
