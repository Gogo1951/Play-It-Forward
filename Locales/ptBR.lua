local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "ptBR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Versão %s. As configurações (incluindo a opção de desativar esta mensagem) ficam em Opções > AddOns > Play It Forward. Curtindo o add-on? Conte para um amigo! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Por precaução, a interface de opções não pode ser aberta em combate."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipamento"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumíveis"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s e inferior"

L["BUTTON_FIND_RECIPIENTS"] = "Buscar destinatários"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Buscando..."
L["BUTTON_DISTRIBUTE"] = "Distribuir"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Requer caixa de correio aberta"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Pressione Buscar destinatários de novo. A Blizzard só permite essa busca diretamente ao pressionar um botão, e algo interrompeu esta."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Nada mais para doar."
L["WINDOW_EMPTY_HINT"] = "Altere Equipamento ou Consumíveis acima para listar mais."

L["SECTION_MATCHED"] = "Atribuídos"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Aguardando atribuição"
L["SECTION_UNREADABLE"] = "Atributos ilegíveis"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Mantido"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Sem destinatário"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Ilegível"

L["PICKER_KEEP_OPTION"] = "Manter item"
L["PICKER_NONE_IN_RANGE"] = "Ninguém na faixa de nível. Pressione Buscar destinatários."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(já tem)"
L["PICKER_NOTE_REFUSED"] = "(recusou)"
L["PICKER_NOTE_RECENT"] = "(recente)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Buscar destinatários para este item"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatário"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato(s), níveis %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Clique para reatribuir."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Não foi possível ler os atributos deste item, então ele não é atribuído."
L["TOOLTIP_RECIPIENT_KEPT"] = "Nenhuma classe quer este, então ele fica nas suas bolsas."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Enviado quando você pressiona Distribuir. Desmarque para mantê-lo."
L["TOOLTIP_CHECK_WAITING"] = "Atribuído assim que uma busca encontrar alguém. Desmarque para mantê-lo."

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
L["MAIL_STILL_SENDING"] = "Ainda enviando, só um instante."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Nada para distribuir."
L["MAIL_DISTRIBUTING"] = "Clique em Aceitar em cada janela de confirmação para enviar %d item(ns)."
L["MAIL_ITEM_MOVED"] = "Pressione Buscar destinatários para escanear de novo. %s foi movido nas suas bolsas."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Escolha outra pessoa para %s. %s já vai receber um."
L["MAIL_NOT_AT_MAILBOX"] = "Volte a uma caixa de correio e pressione Distribuir para enviar o resto."
L["MAIL_MAILBOX_CLOSED"] =
	"Abra uma caixa de correio e pressione Distribuir para enviar o resto. A caixa de correio fechou no meio do caminho."
L["MAIL_NO_POSTAGE"] = "Adicione um pouco de cobre para a postagem e pressione Distribuir para enviar o resto."
L["MAIL_PANEL_CLOSED"] =
	"Abra o painel de envio de correio da Blizzard e pressione Distribuir de novo. Nada foi enviado ou mexido."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Se você usa TSM, mude para a interface de correio padrão para isso. A caixa de correio do TSM não aceita anexos."
L["MAIL_ATTACH_FAILED"] = "Não foi possível anexar %s, então não foi enviado."
L["MAIL_AWAITING_CONFIRM"] = "Clique em Aceitar na janela de %s e pressione Distribuir para enviar o resto."
L["MAIL_SENT"] = "%s enviado para %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Falha no correio para %s (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "nenhum motivo informado"
L["MAIL_REASON_ERROR"] = "erro do cliente"
L["MAIL_ABORTED"] = "Distribuição interrompida após erros de correio repetidos."
L["MAIL_DONE"] = "Pronto. %d de %d enviados."
L["MAIL_DONE_WITH_SKIPS"] = "Pronto. %d de %d enviados, %d ignorados (movidos nas suas bolsas)."
L["MAIL_SUBJECT_TOO_LONG"] = "O assunto tem %d caracteres e o correio só aceita %d, então ele será cortado."
L["MAIL_BODY_TOO_LONG"] = "O corpo tem %d caracteres e o correio só aceita %d, então ele será cortado."

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
	"Envie o equipamento e os consumíveis que você já superou para colegas de guilda ou desconhecidos que vão gostar deles. Cada item é atribuído à classe que mais combina com ele, transformando a bagunça esquecida das suas bolsas na próxima melhoria de outra pessoa. Passe adiante, um item verde de cada vez."
L["OPTIONS_WELCOME"] = "Ativar mensagem de boas-vindas"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Exibe a versão e o lembrete de configurações ao entrar no jogo."

L["OPTIONS_COMMANDS_HEADER"] = "/Comandos"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Abre a interface de opções deste add-on."

L["OPTIONS_GIVE_HEADER"] = "O que doar"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"A raridade mais alta oferecida. Nada acima disso é listado, então um bom drop não pode ser enviado por engano."
L["OPTIONS_INCLUDE_GEAR"] = "Incluir equipamento"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Oferecer armas e armaduras vinculadas ao equipar."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Incluir consumíveis"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Oferecer comida, bebida, poções e pergaminhos de nível baixo que você já superou."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Superados por %d+ níveis"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Todos os consumíveis"
L["OPTIONS_CONSUMABLE_GAP"] = "Regra de nível"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"Quantos níveis você precisa estar acima de um consumível para ele contar como sobra. Com 20 ou mais, uma água de nível 35 é oferecida quando você chega ao nível 55. Todos os consumíveis oferece todos das suas bolsas, seja qual for o seu nível."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Comida"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Oferecer comida que você já superou. Comida que também restaura mana é oferecida enquanto Comida ou Bebida estiver ativada."
L["OPTIONS_KIND_DRINK"] = "Bebida"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Oferecer água, suco e outras bebidas que você já superou."
L["OPTIONS_KIND_POTIONS"] = "Poções"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "Oferecer poções de cura, mana e rejuvenescimento que você já superou."
L["OPTIONS_KIND_SCROLLS"] = "Pergaminhos"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Oferecer pergaminhos de atributo que você já superou. Cada um vai para as classes que usam o atributo dele."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Generosidade"
L["OPTIONS_GENEROSITY_GIFTS"] = "Presentes"
L["OPTIONS_GENEROSITY_ITEMS"] = "Itens"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Níveis de item"
L["OPTIONS_GENEROSITY_VALUE"] = "Valor em ouro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Ativar dicas de generosidade"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Jogadores perto de você em cidades e estalagens podem ver seus totais na sua dica. Desativar para o compartilhamento, mas você continua vendo os deles, e seus próprios totais abaixo continuam contando de qualquer forma."

L["OPTIONS_FEEDBACK_HEADER"] = "Feedback e suporte"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Versão %s"
