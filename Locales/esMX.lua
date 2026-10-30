local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "esMX")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Ventana de reparto"
L["CHAT_LOADED"] =
	"Versión %s. Los ajustes (incluida la opción de desactivar este mensaje) están en Opciones > Accesorios > Play It Forward. ¿Te gusta este accesorio? Cuéntaselo a un amigo, márcalo como favorito en CurseForge o dale una Star en GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Por precaución, la interfaz de opciones no se puede abrir en combate."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipo"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumibles"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Desencantar"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Elige un personaje"
L["WINDOW_DISENCHANT_NONE"] = "Tus personajes aparecen en cuanto cada uno inicia sesión con Play It Forward."

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s e inferior"

L["BUTTON_FIND_RECIPIENTS"] = "Buscar destinatarios"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Buscando..."
L["BUTTON_DISTRIBUTE"] = "Repartir"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Requiere buzón abierto"
--[[
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Enviando..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "Nueva búsqueda en %d s. Vuelve a intentarlo cuando el botón diga Buscar destinatarios."
L["WHO_BLOCKED"] =
	"Presiona Buscar destinatarios otra vez. Blizzard solo permite esa búsqueda directamente al presionar un botón, y algo interrumpió esta."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Muestra lo que puedes regalar de tus bolsas."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "No queda nada que regalar."
L["WINDOW_EMPTY_HINT"] = "Cambia los ajustes de arriba para ver más."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Presiona Buscar destinatarios para buscar jugadores para %d objeto(s)."
L["STATUS_MORE"] = "%d búsqueda(s) más prevista(s). Presiona Buscar destinatarios para seguir."
L["STATUS_DONE"] = "Búsqueda terminada. %d objeto(s) siguen sin nadie en rango. Reinténtalo luego."
L["STATUS_READY"] = "Presiona Repartir para enviar %d objeto(s)."
L["STATUS_AWAY"] = "Abre un buzón para enviar %d objeto(s)."
L["STATUS_SENDING"] = "Enviando %d de %d. Haz clic en Aceptar en cada ventana."

L["SECTION_MATCHED"] = "Asignados"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Pendientes de asignar"
L["SECTION_UNREADABLE"] = "Estadísticas no legibles"

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
L["WINDOW_KEPT"] = "Conservado"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Sin destinatario"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Estadísticas ilegibles"

L["PICKER_KEEP_OPTION"] = "Conservar objeto"
L["PICKER_NONE_IN_RANGE"] = "Nadie en el rango de niveles. Presiona Buscar destinatarios."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(ya tiene)"
L["PICKER_NOTE_REFUSED"] = "(rechazado)"
L["PICKER_NOTE_RECENT"] = "(reciente)"
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Ya está en otra fila. Tu elección manda, y una fila que no hayas fijado tú buscará a otra persona."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Un correo para esta persona fue devuelto antes en esta sesión. Aún puedes volver a intentarlo."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Ya recibió un regalo tuyo en esta sesión. Vuelve a tener prioridad en cuanto suba de nivel."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Buscar destinatarios para este objeto"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Tus alts"
L["PICKER_SECTION_GUILD"] = "Tu hermandad"
L["PICKER_SECTION_STRANGERS"] = "Desconocidos"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Desencantar"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatario"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato(s), niveles %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Haz clic para reasignar."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Ideal para %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "No se pudieron leer las estadísticas de este objeto, así que no se asigna."
L["TOOLTIP_RECIPIENT_KEPT"] = "Ninguna clase lo quiere, así que se queda en tus bolsas."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "Nadie puede usarlo, así que va a %s para desencantarlo."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Se envía al presionar Repartir. Desmárcalo para conservarlo."
L["TOOLTIP_CHECK_WAITING"] = "Se asigna en cuanto una búsqueda encuentre a alguien. Desmárcalo para conservarlo."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Elige a alguien de la lista para enviar este objeto."
L["TOOLTIP_CHECK_UNREADABLE"] = "No se puede enviar hasta que se puedan leer sus estadísticas."

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
L["MAIL_STILL_SENDING"] = "Aún enviando. Dame un segundo."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nada que repartir."
L["MAIL_DISTRIBUTING"] = "Haz clic en Aceptar en cada ventana de confirmación para enviar %d objeto(s)."
L["MAIL_ITEM_MOVED"] = "Presiona Buscar destinatarios para volver a escanear. %s se movió en tus bolsas."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Elige a otra persona para %s. %s ya va a recibir uno."
L["MAIL_NOT_AT_MAILBOX"] = "Vuelve a un buzón y presiona Repartir para enviar el resto."
L["MAIL_MAILBOX_CLOSED"] =
	"Abre un buzón y presiona Repartir para enviar el resto. El buzón se cerró a mitad del envío."
L["MAIL_NO_POSTAGE"] = "Agrega un poco de cobre para el franqueo y luego presiona Repartir para enviar el resto."
L["MAIL_PANEL_CLOSED"] =
	"Abre el panel de envío de correo de Blizzard y presiona Repartir otra vez. No se envió ni se tocó nada."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Si usas TSM, cambia al panel de envío de correo de Blizzard para esto. El buzón de TSM no acepta adjuntos."
L["MAIL_ATTACH_FAILED"] = "No se pudo adjuntar %s, así que no se envió."
L["MAIL_AWAITING_CONFIRM"] = "Haz clic en Aceptar en la ventana de %s y luego presiona Repartir para enviar el resto."
L["MAIL_SENT"] = "Enviado %s a %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Falló el correo a %s (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "sin motivo indicado"
L["MAIL_REASON_ERROR"] = "error del cliente"
L["MAIL_ABORTED"] = "Se detuvo el reparto tras varios errores de correo."
L["MAIL_DONE"] = "Listo. %d de %d enviados."
L["MAIL_DONE_WITH_SKIPS"] = "Listo. %d de %d enviados, %d omitidos (movidos en tus bolsas)."

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
	"Envía por correo el equipo que se liga al equiparse, la comida, las pociones, los pergaminos, los aceites y las piedras que ya has superado a tus alts, a los miembros de tu hermandad y a jugadores que están subiendo de nivel. Cada objeto va a la clase a la que mejor le va, y el desorden de tus bolsas se convierte en la próxima mejora de otra persona. Pásalo, un objeto verde cada vez."
L["OPTIONS_WELCOME"] = "Activar mensaje de bienvenida"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Muestra la versión y el recordatorio de ajustes al iniciar sesión."

L["OPTIONS_FEATURES_HEADER"] = "Funciones"

L["OPTIONS_COMMANDS_HEADER"] = "/Comandos"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Abre la interfaz de opciones de este accesorio."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "Qué regalar"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Elige lo que regalas a otros jugadores. También puedes cambiar el equipo y los consumibles en cualquier momento en la parte superior de la Ventana de reparto."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rareza más alta que se ofrece. Nada por encima aparece nunca, así que un buen botín no se puede enviar por accidente."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Repartir equipo"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Ofrece armas y armaduras que se ligan al equiparlas."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Repartir consumibles"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Ofrece comida, bebida, pociones, pergaminos, aceites y piedras de nivel bajo que ya has superado."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Superados por %d+ niveles"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Todos los consumibles"
L["OPTIONS_CONSUMABLE_GAP"] = "Regla de nivel"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"Cuántos niveles debes superar a un consumible para que cuente como sobrante. Con 20 o más, un agua de nivel 35 se ofrece al llegar al nivel 55. Todos los consumibles ofrece todos los de tus bolsas, sea cual sea tu nivel."

--[[
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Comida"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Ofrece la comida que ya has superado. La comida que también restaura maná se ofrece mientras Comida o Bebida esté activada."
L["OPTIONS_KIND_DRINK"] = "Bebida"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Ofrece agua, jugo y otras bebidas que ya has superado."
L["OPTIONS_KIND_POTIONS"] = "Pociones"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "Ofrece pociones de sanación, maná y rejuvenecimiento que ya has superado."
L["OPTIONS_KIND_SCROLLS"] = "Pergaminos"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Ofrece pergaminos de atributos que ya has superado. Cada uno va a las clases que usan su atributo."
L["OPTIONS_KIND_OILS_STONES"] = "Aceites y piedras"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Ofrece aceites para armas, piedras de afilar y piedras de peso que ya has superado. Los aceites de zahorí van a los hechiceros, los aceites de maná a quien use maná, y las piedras y los demás aceites a los luchadores cuerpo a cuerpo."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Desencantar objetos sin asignar"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"El equipo sin asignar puede enviarse a uno de tus propios personajes para desencantarlo, en lugar de quedarse en tus bolsas. Actívalo y luego elige qué personaje lo recibe. Cada reino y facción guarda su propia elección."
L["OPTIONS_DISENCHANT_SEND"] = "Enviar objetos sin asignar al encantador"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"El equipo que nadie puede usar va a uno de tus personajes para desencantarlo, en lugar de quedarse en tus bolsas. Los consumibles nunca se envían."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Tu encantador. Muestra tus personajes de este reino y de sus reinos conectados, de esta facción, en cuanto cada uno ha iniciado sesión con Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Destinatarios"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"A quién va tu equipo y en qué orden. Elige qué personajes y hermandades cuentan en las páginas Mis alts y Mis hermandades de abajo."

L["OPTIONS_PRIORITY_HEADER"] = "Quién va primero"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Tus propios personajes y compañeros de hermandad pueden pasar al principio de la cola para todo lo que les vaya tan bien como a un desconocido. Desmarca cualquiera de las dos opciones y competirán con todos los demás por nivel y ubicación."
L["OPTIONS_PRIORITIZE_ALTS"] = "Priorizar Mis alts sobre desconocidos y Mis hermandades"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Tus propios personajes eligen primero entre todo lo que les vaya tan bien como a cualquier otro. Si lo desmarcas, compiten con todos los demás por nivel y ubicación."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Priorizar Mis hermandades sobre desconocidos"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Tus compañeros de hermandad eligen antes que los desconocidos entre todo lo que les vaya igual de bien. Si lo desmarcas, compiten con los desconocidos por nivel y ubicación."

L["OPTIONS_STRANGERS_HEADER"] = "Al buscar desconocidos"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Cómo se comparan entre sí los jugadores encontrados con /who. Entre candidatos igual de adecuados, el equipo va primero a quien más probablemente esté subiendo de nivel y vaya a darle uso."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Priorizar desconocidos en zonas de su nivel"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Ofrece equipo primero a jugadores que hacen misiones en una zona pensada para su nivel, antes que a jugadores en una ciudad. Son quienes más probablemente agradecerán tu gesto."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Priorizar desconocidos fuera de instancias"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Ofrece equipo a jugadores en un calabozo o banda solo cuando no hay nadie adecuado por el mundo. Los jugadores en un calabozo pueden ser personajes a los que otros están subiendo de nivel a toda prisa, y no necesitarán el equipo mucho tiempo."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Ignorar brujos de nivel %d-%d"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Nunca ofrece equipo a desconocidos que sean brujos en este rango de niveles. Los brujos aprenden a invocar a nivel 20, y muchos jugadores dejan un alt brujo en ese nivel solo para invocar a sus amigos, así que el equipo que reciben suele quedarse sin usar. Tus propios personajes y compañeros de hermandad no se ven afectados."

L["OPTIONS_SPECS_HEADER"] = "Clases y especializaciones"
L["OPTIONS_SPECS_INTRO"] =
	"Nadie puede ver la especialización de otro jugador, así que el equipo se reparte según estas suposiciones. Tus propios personajes usan las especializaciones fijadas en Mis alts."
L["OPTIONS_SPECS_RESET"] = "Restablecer predeterminados"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] =
	"Devuelve todas las especializaciones a la configuración original del accesorio."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Daño con hechizos"
L["ROLE_MELEE"] = "Daño cuerpo a cuerpo"
L["ROLE_RANGED"] = "Daño a distancia"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Armas"
L["SPEC_Fury"] = "Furia"
L["SPEC_Protection"] = "Protección"
L["SPEC_Holy"] = "Sagrado"
L["SPEC_Retribution"] = "Reprensión"
L["SPEC_BeastMastery"] = "Dominio de bestias"
L["SPEC_Marksmanship"] = "Puntería"
L["SPEC_Survival"] = "Supervivencia"
L["SPEC_Assassination"] = "Asesinato"
L["SPEC_Combat"] = "Combate"
L["SPEC_Subtlety"] = "Sutileza"
L["SPEC_Discipline"] = "Disciplina"
L["SPEC_Shadow"] = "Sombra"
L["SPEC_Elemental"] = "Elemental"
L["SPEC_Enhancement"] = "Mejora"
L["SPEC_Restoration"] = "Restauración"
L["SPEC_Arcane"] = "Arcano"
L["SPEC_Fire"] = "Fuego"
L["SPEC_Frost"] = "Escarcha"
L["SPEC_Affliction"] = "Aflicción"
L["SPEC_Demonology"] = "Demonología"
L["SPEC_Destruction"] = "Destrucción"
L["SPEC_Balance"] = "Equilibrio"
L["SPEC_Feral"] = "Combate feral"
L["SPEC_Guardian"] = "Guardián"
L["SPEC_Blood"] = "Sangre"
L["SPEC_Unholy"] = "Profano"
L["SPEC_Brewmaster"] = "Maestro cervecero"
L["SPEC_Mistweaver"] = "Tejedor de niebla"
L["SPEC_Windwalker"] = "Viajero del viento"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Protección"
L["SPEC_DRUID_Restoration"] = "Restauración"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Tanque (runas)"
L["SPEC_Healer"] = "Sanador (runas)"
L["SPEC_Melee"] = "Cuerpo a cuerpo (runas)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "Mis alts"
L["OPTIONS_ALTS_INTRO"] =
	"Tus propios personajes, cada uno agregado en cuanto inicia sesión con Play It Forward. Elige uno a la izquierda para decidir si recibe correo y para qué especializaciones se le envía equipo."
L["OPTIONS_SEND_TO_ALTS"] = "Enviar a alts"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Envía primero a tus propios personajes, antes que a tu hermandad y a los desconocidos, pero solo objetos para los que su clase sea la más adecuada. Un personaje cuenta en cuanto ha iniciado sesión con Play It Forward en este reino o en uno conectado, de esta facción. Los correos a tus alts no cuentan para los totales de tu Insignia de generosidad."
L["OPTIONS_ALTS_EMPTY"] =
	"Aún no hay personajes. Cada uno de tus personajes aparece aquí en cuanto inicia sesión con Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Incluir este personaje"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Envía equipo a este personaje. Si lo desmarcas, nunca se le ofrece nada. Un personaje en el nivel máximo empieza desmarcado."
L["OPTIONS_ALT_SPECS"] = "Enviar equipo para"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Ofrece a este personaje equipo para esta especialización. Empieza con la última especialización que jugó el personaje, o con todas hasta que tenga una."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Niveles de equipo"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Mínimo"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"El equipo de nivel más bajo que recibe este personaje. Su nivel no envía nada por debajo de su nivel; Su nivel -2 también envía equipo de hasta dos niveles menos, que ya puede llevar."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Máximo"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"El equipo de nivel más alto que recibe este personaje. Cualquier equipo que pueda usar envía todo lo que podrá llevar más adelante, así que un cazador de nivel 1 puede recibir un arco de nivel 50."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Su nivel"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Su nivel -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Su nivel +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Cualquier equipo que pueda usar"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Recibe equipo para los niveles %d a %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Recibe equipo a partir del nivel %d."
L["OPTIONS_DELETE"] = "Eliminar"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "¿Olvidar a %s? Se volverá a agregar la próxima vez que inicie sesión."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "Olvida este personaje. Se volverá a agregar la próxima vez que inicie sesión."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Mis hermandades"
L["OPTIONS_GUILDS_INTRO"] =
	"Todas las hermandades de tus personajes, guardadas cada vez que uno de ellos inicia sesión, para que cualquier personaje con el que juegues pueda enviar correo a sus compañeros de hermandad que están subiendo de nivel."
L["OPTIONS_GUILD_OFFLINE"] = "Ignorar miembros desconectados de la hermandad"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Omite a los compañeros de hermandad que lleven sin iniciar sesión más de este tiempo, en tu hermandad actual y en las guardadas. Elige Nunca para incluir a todos, lleven el tiempo que lleven fuera."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Más de 1 semana"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Más de 2 semanas"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Nunca"
L["OPTIONS_GUILDS_EMPTY"] =
	"Aún no hay hermandades. Una hermandad aparece aquí en cuanto uno de tus personajes que pertenece a ella inicia sesión."
L["OPTIONS_GUILD_INCLUDE"] = "Enviar a los miembros de esta hermandad"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Envía equipo a los miembros de esta hermandad."
L["OPTIONS_GUILD_MEMBERS"] = "Miembros activos"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] =
	"Nadie de esta lista estuvo activo lo bastante recientemente como para recibir objetos."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Incluir"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Envía equipo a este compañero de hermandad. Desmárcalo para un banco de hermandad o un alt de profesión, y nunca se le ofrecerá nada."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d miembros activos, guardado %s por %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "hoy"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "ayer"
L["OPTIONS_GUILD_SAVED_DAYS"] = "hace %d días"
L["OPTIONS_GUILD_CURRENT"] = "Tu hermandad actual, leída al momento en el buzón."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "En otro reino, así que el correo no puede llegar desde aquí."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "En la otra facción, así que el correo no puede llegar desde aquí."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Texto del correo"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"La nota que acompaña a cada regalo. Escribe la tuya a la izquierda y mira a la derecha exactamente lo que se envía. Los cambios se guardan al escribir; vacía un campo para volver al texto predeterminado."
L["OPTIONS_MAIL_SUBJECT"] = "Asunto"
L["OPTIONS_MAIL_BODY"] = "Cuerpo"
L["OPTIONS_MAIL_YOURS"] = "Tu mensaje"
L["OPTIONS_MAIL_PREVIEW"] = "Lo que reciben"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Asunto %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Cuerpo %d/%d"
L["OPTIONS_MAIL_RESET"] = "Restablecer predeterminado"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Volver al asunto y cuerpo predeterminados."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Insignia de generosidad"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Tus totales de donaciones, de todos los personajes de tu cuenta. Aparecen en tu descripción emergente de jugador en ciudades y posadas, donde otros usuarios de Play It Forward los ven al pasar el cursor sobre ti, y tú ves los suyos. Se ocultan en calabozos, bandas y por el mundo."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Insignia de generosidad"
L["OPTIONS_GENEROSITY_GIFTS"] = "Regalos"
L["OPTIONS_GENEROSITY_ITEMS"] = "Objetos"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Niveles de objeto"
L["OPTIONS_GENEROSITY_VALUE"] = "Valor en oro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Activar Insignia de generosidad en descripciones de jugador"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Los jugadores cerca de ti en ciudades y posadas pueden ver tus totales en tu descripción emergente. Al desactivarlo dejas de compartirlos, pero sigues viendo los suyos, y tus propios totales siguen sumando de todos modos."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Ayuda a Play It Forward a subir de nivel"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Este accesorio lo crearon jugadores que aman este juego y quieren hacerlo lo más divertido posible para todos. Nunca pediremos donaciones. La verdadera satisfacción es saber que nuestro trabajo hace el juego un poco mejor para ti. Si es así, ¡nos encantaría saberlo!"
L["OPTIONS_LEVEL_UP_WAYS"] = "Estas son algunas formas de ayudarnos a llegar a más jugadores."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Comparte tu opinión: ¿Encontraste un error o tienes una idea? Avísanos en Discord. Tus comentarios nos ayudan a mejorar el accesorio, y los pull requests siempre son bienvenidos."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Cuéntaselo a un amigo: ¿Conoces a alguien a quien le podría gustar este accesorio? Háblale de él. El boca a boca ayuda a más jugadores a descubrir grandes accesorios."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Favorito en CurseForge: Abre el enlace de CurseForge de abajo, inicia sesión y haz clic en la estrella debajo del botón Download. Los favoritos ayudan a más jugadores a descubrir el accesorio."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star en GitHub: Abre el enlace de GitHub de abajo, inicia sesión y haz clic en Star arriba a la derecha. Las estrellas ayudan al proyecto a calificar para más herramientas gratuitas para desarrolladores."
L["OPTIONS_LEVEL_UP_THANKS"] = "¡Gracias por elegir Play It Forward!"

L["OPTIONS_FEEDBACK"] = "Comentarios y soporte"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Enlaces de comentarios y soporte"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "Para copiar un enlace, haz clic en su casilla y presiona Ctrl+A y Ctrl+C."
L["OPTIONS_VERSION"] = "Versión %s"
