local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "esES")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Versión %s. Los ajustes (incluida la opción de desactivar este mensaje) están en Opciones > Accesorios > Play It Forward. ¿Te gusta el accesorio? ¡Cuéntaselo a un amigo! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Por precaución, la interfaz de opciones no se puede abrir en combate."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipo"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumibles"

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
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Pulsa Buscar destinatarios otra vez. Blizzard solo permite esa búsqueda directamente al pulsar un botón, y algo interrumpió esta."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "No queda nada que regalar."
L["WINDOW_EMPTY_HINT"] = "Cambia Equipo o Consumibles arriba para ver más."

L["SECTION_MATCHED"] = "Asignados"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Pendientes de asignar"
L["SECTION_UNREADABLE"] = "Estadísticas no legibles"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

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
L["PICKER_NONE_IN_RANGE"] = "Nadie en el rango de niveles. Pulsa Buscar destinatarios."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(ya tiene)"
L["PICKER_NOTE_REFUSED"] = "(rechazado)"
L["PICKER_NOTE_RECENT"] = "(reciente)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Buscar destinatarios para este objeto"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatario"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato(s), niveles %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Haz clic para reasignar."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "No se pudieron leer las estadísticas de este objeto, así que no se asigna."
L["TOOLTIP_RECIPIENT_KEPT"] = "Ninguna clase lo quiere, así que se queda en tus bolsas."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Se envía al pulsar Repartir. Desmárcalo para conservarlo."
L["TOOLTIP_CHECK_WAITING"] = "Se asigna en cuanto una búsqueda encuentre a alguien. Desmárcalo para conservarlo."

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
L["MAIL_STILL_SENDING"] = "Aún enviando, dame un momento."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nada que repartir."
L["MAIL_DISTRIBUTING"] = "Haz clic en Aceptar en cada ventana de confirmación para enviar %d objeto(s)."
L["MAIL_ITEM_MOVED"] = "Pulsa Buscar destinatarios para volver a escanear. %s se movió en tus bolsas."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Elige a otra persona para %s. %s ya va a recibir uno."
L["MAIL_NOT_AT_MAILBOX"] = "Vuelve a un buzón y pulsa Repartir para enviar el resto."
L["MAIL_MAILBOX_CLOSED"] =
	"Abre un buzón y pulsa Repartir para enviar el resto. El buzón se cerró a mitad del envío."
L["MAIL_NO_POSTAGE"] = "Añade un poco de cobre para el franqueo y luego pulsa Repartir para enviar el resto."
L["MAIL_PANEL_CLOSED"] =
	"Abre el panel de envío de correo de Blizzard y pulsa Repartir otra vez. No se envió ni se tocó nada."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Si usas TSM, cambia a la interfaz de correo predeterminada para esto. El buzón de TSM no acepta adjuntos."
L["MAIL_ATTACH_FAILED"] = "No se pudo adjuntar %s, así que no se envió."
L["MAIL_AWAITING_CONFIRM"] = "Haz clic en Aceptar en la ventana de %s y luego pulsa Repartir para enviar el resto."
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
L["MAIL_SUBJECT_TOO_LONG"] = "El asunto tiene %d caracteres y el correo solo admite %d, así que se recortará."
L["MAIL_BODY_TOO_LONG"] = "El cuerpo tiene %d caracteres y el correo solo admite %d, así que se recortará."

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
	"Envía el equipo y los consumibles que ya has superado a compañeros de hermandad o desconocidos que sabrán apreciarlos. Cada objeto se asigna a la clase a la que mejor le va, y el desorden olvidado de tus bolsas se convierte en la próxima mejora de otra persona. Pásalo, un objeto verde cada vez."
L["OPTIONS_WELCOME"] = "Activar mensaje de bienvenida"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Muestra la versión y el recordatorio de ajustes al iniciar sesión."

L["OPTIONS_COMMANDS_HEADER"] = "/Comandos"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Abre la interfaz de opciones de este accesorio."

L["OPTIONS_GIVE_HEADER"] = "Qué regalar"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rareza más alta que se ofrece. Nada por encima aparece nunca, así que un buen botín no se puede enviar por accidente."
L["OPTIONS_INCLUDE_GEAR"] = "Incluir equipo"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Ofrece armas y armaduras que se ligan al equiparlas."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Incluir consumibles"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Ofrece comida, bebida, pociones y pergaminos de nivel bajo que ya has superado."
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
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Comida"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Ofrece la comida que ya has superado. La comida que también restaura maná se ofrece mientras Comida o Bebida esté activada."
L["OPTIONS_KIND_DRINK"] = "Bebida"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Ofrece agua, zumo y otras bebidas que ya has superado."
L["OPTIONS_KIND_POTIONS"] = "Pociones"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "Ofrece pociones de sanación, maná y rejuvenecimiento que ya has superado."
L["OPTIONS_KIND_SCROLLS"] = "Pergaminos"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Ofrece pergaminos de atributos que ya has superado. Cada uno va a las clases que usan su atributo."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Generosidad"
L["OPTIONS_GENEROSITY_GIFTS"] = "Regalos"
L["OPTIONS_GENEROSITY_ITEMS"] = "Objetos"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Niveles de objeto"
L["OPTIONS_GENEROSITY_VALUE"] = "Valor en oro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Activar descripciones de generosidad"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Los jugadores cerca de ti en ciudades y posadas pueden ver tus totales en tu descripción emergente. Al desactivarlo dejas de compartirlos, pero sigues viendo los suyos, y tus propios totales de abajo siguen sumando de todos modos."

L["OPTIONS_FEEDBACK_HEADER"] = "Comentarios y soporte"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Versión %s"
