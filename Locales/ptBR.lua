local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "ptBR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Janela de distribuição"
L["CHAT_LOADED"] =
	"Versão %s. As configurações (incluindo a opção de desativar esta mensagem) ficam em Opções > AddOns > Play It Forward. Curtindo este add-on? Conte para um amigo, favorite-o no CurseForge ou dê uma Star no GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Por precaução, a interface de opções não pode ser aberta em combate."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Equipamento"
L["WINDOW_CONSUMABLES_LABEL"] = "Consumíveis"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Desencantar"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Escolha um personagem"
L["WINDOW_DISENCHANT_NONE"] = "Seus personagens aparecem depois que cada um entra no jogo com o Play It Forward."

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
L["WHO_WAIT"] = "Nova busca em %d s. Tente de novo quando o botão mostrar Buscar destinatários."
L["WHO_BLOCKED"] =
	"Pressione Buscar destinatários de novo. A Blizzard só permite essa busca diretamente ao pressionar um botão, e algo interrompeu esta."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Mostra o que você pode doar das suas bolsas."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Nada mais para doar."
L["WINDOW_EMPTY_HINT"] = "Altere as configurações acima para listar mais."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Pressione Buscar destinatários e ache jogadores para %d item(ns)."
L["STATUS_MORE"] = "Mais %d busca(s) prevista(s). Pressione Buscar destinatários para seguir."
L["STATUS_DONE"] = "Busca concluída. %d item(ns) sem ninguém na faixa de nível. Tente depois."
L["STATUS_READY"] = "Pressione Distribuir para enviar %d item(ns)."
L["STATUS_AWAY"] = "Abra uma caixa de correio para enviar %d item(ns)."
L["STATUS_SENDING"] = "Enviando %d de %d. Clique em Aceitar em cada janela."

L["SECTION_MATCHED"] = "Atribuídos"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Aguardando atribuição"
L["SECTION_UNREADABLE"] = "Atributos ilegíveis"

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
L["WINDOW_KEPT"] = "Mantido"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Sem destinatário"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Atributos não lidos"

L["PICKER_KEEP_OPTION"] = "Manter item"
L["PICKER_NONE_IN_RANGE"] = "Ninguém na faixa de nível. Pressione Buscar destinatários."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(já tem)"
L["PICKER_NOTE_REFUSED"] = "(recusou)"
L["PICKER_NOTE_RECENT"] = "(recente)"
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Já está em outra linha. Sua escolha prevalece, e uma linha que você não definiu procura outra pessoa."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Um correio para essa pessoa foi devolvido mais cedo nesta sessão. Você ainda pode tentar de novo."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Já recebeu um presente seu nesta sessão. Volta a ter prioridade quando subir de nível."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Buscar destinatários para este item"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Seus alts"
L["PICKER_SECTION_GUILD"] = "Sua guilda"
L["PICKER_SECTION_STRANGERS"] = "Desconhecidos"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Desencantar"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinatário"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidato(s), níveis %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Clique para reatribuir."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Mais indicado para %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Não foi possível ler os atributos deste item, então ele não é atribuído."
L["TOOLTIP_RECIPIENT_KEPT"] = "Nenhuma classe quer este, então ele fica nas suas bolsas."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "Ninguém pode usar isto, então vai para %s desencantar."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Enviado quando você pressiona Distribuir. Desmarque para mantê-lo."
L["TOOLTIP_CHECK_WAITING"] = "Atribuído assim que uma busca encontrar alguém. Desmarque para mantê-lo."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Escolha alguém da lista para enviar este."
L["TOOLTIP_CHECK_UNREADABLE"] = "Este não pode ser enviado até que seus atributos possam ser lidos."

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
L["MAIL_STILL_SENDING"] = "Ainda enviando. Só um instante."
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
	"Se você usa TSM, mude para o painel de envio de correio da Blizzard para isso. A caixa de correio do TSM não aceita anexos."
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
	"Envie pelo correio o equipamento vinculado ao equipar, a comida, as poções, os pergaminhos, os óleos e as pedras que você já superou para seus alts, colegas de guilda e jogadores que estão subindo de nível. Cada item vai para a classe que mais combina com ele, transformando a bagunça das suas bolsas na próxima melhoria de outra pessoa. Passe adiante, um item verde de cada vez."
L["OPTIONS_WELCOME"] = "Ativar mensagem de boas-vindas"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Exibe a versão e o lembrete de configurações ao entrar no jogo."

L["OPTIONS_FEATURES_HEADER"] = "Recursos"

L["OPTIONS_COMMANDS_HEADER"] = "/Comandos"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Abre a interface de opções deste add-on."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "O que doar"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Escolha o que você doa para outros jogadores. Você também pode mudar equipamento e consumíveis a qualquer momento no topo da Janela de distribuição."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"A raridade mais alta oferecida. Nada acima disso é listado, então um bom drop não pode ser enviado por engano."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Distribuir equipamento"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Oferecer armas e armaduras vinculadas ao equipar."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Distribuir consumíveis"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Oferecer comida, bebida, poções, pergaminhos, óleos e pedras de nível baixo que você já superou."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "Óleos e pedras"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Oferecer óleos para armas, pedras de amolar e pedras de peso que você já superou. Os óleos de mago vão para os conjuradores, os óleos de mana para quem usa mana, e as pedras e os demais óleos para quem luta corpo a corpo."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Desencantar itens não atribuídos"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"Equipamento que ninguém recebeu pode ser enviado a um dos seus próprios personagens para desencantar, em vez de ficar nas suas bolsas. Ative a opção e escolha qual personagem recebe. Cada reino e facção guarda sua própria escolha."
L["OPTIONS_DISENCHANT_SEND"] = "Enviar itens não atribuídos para desencantar"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"Equipamento que ninguém pode usar vai para um dos seus personagens desencantar, em vez de ficar nas suas bolsas. Consumíveis nunca são enviados."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Seu encantador. Lista seus personagens neste reino e nos reinos conectados a ele, nesta facção, depois que cada um entra no jogo com o Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Destinatários"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"Para quem seu equipamento vai, e em que ordem. Escolha quais dos seus personagens e guildas contam nas páginas Meus alts e Minhas guildas abaixo."

L["OPTIONS_PRIORITY_HEADER"] = "Quem vem primeiro"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Seus próprios personagens e colegas de guilda podem passar à frente na fila por qualquer coisa que combine com eles tanto quanto com um desconhecido. Desmarque qualquer um dos dois e eles disputam com todos os outros por nível e localização."
L["OPTIONS_PRIORITIZE_ALTS"] = "Priorizar Meus alts acima de desconhecidos e Minhas guildas"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Seus próprios personagens escolhem primeiro qualquer coisa que combine com eles tanto quanto com qualquer outro. Desmarcado, eles disputam com todos os outros por nível e localização."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Priorizar Minhas guildas acima de desconhecidos"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Seus colegas de guilda escolhem antes dos desconhecidos qualquer coisa que combine com eles na mesma medida. Desmarcado, eles disputam com desconhecidos por nível e localização."

L["OPTIONS_STRANGERS_HEADER"] = "Ao buscar desconhecidos"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Como os jogadores encontrados com /who são comparados entre si. Entre opções igualmente boas, o equipamento vai primeiro para quem tem mais chance de estar subindo de nível e vai usá-lo."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Priorizar desconhecidos em zonas do nível deles"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Oferecer equipamento primeiro a jogadores fazendo missões numa zona feita para o nível deles, antes de jogadores numa cidade. São esses aventureiros que mais vão valorizar sua gentileza."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Priorizar desconhecidos fora de instâncias"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Oferecer equipamento a jogadores numa masmorra ou raide só quando não houver ninguém adequado pelo mundo. Jogadores numa masmorra podem ser personagens sendo carregados, que não vão precisar do equipamento por muito tempo."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Ignorar bruxos de nível %d-%d"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Nunca oferecer equipamento a desconhecidos que sejam bruxos nessa faixa de nível. Bruxos aprendem a invocar no nível 20, e muitos jogadores deixam um alt bruxo parado aqui só para invocar os amigos, então o equipamento enviado a eles muitas vezes fica sem uso. Seus próprios personagens e colegas de guilda não são afetados."

L["OPTIONS_SPECS_HEADER"] = "Classes e especializações"
L["OPTIONS_SPECS_INTRO"] =
	"Ninguém consegue ver a especialização de outro jogador, então o equipamento é enviado com base nestas suposições. Seus próprios personagens usam as especializações definidas em Meus alts."
L["OPTIONS_SPECS_RESET"] = "Restaurar padrões"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "Volta todas as especializações à configuração original do add-on."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Dano mágico"
L["ROLE_MELEE"] = "Dano corpo a corpo"
L["ROLE_RANGED"] = "Dano à distância"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Armas"
L["SPEC_Fury"] = "Fúria"
L["SPEC_Protection"] = "Proteção"
L["SPEC_Holy"] = "Sagrado"
L["SPEC_Retribution"] = "Retribuição"
L["SPEC_BeastMastery"] = "Domínio das Feras"
L["SPEC_Marksmanship"] = "Precisão"
L["SPEC_Survival"] = "Sobrevivência"
L["SPEC_Assassination"] = "Assassinato"
L["SPEC_Combat"] = "Combate"
L["SPEC_Subtlety"] = "Subterfúgio"
L["SPEC_Discipline"] = "Disciplina"
L["SPEC_Shadow"] = "Sombra"
L["SPEC_Elemental"] = "Elemental"
L["SPEC_Enhancement"] = "Aperfeiçoamento"
L["SPEC_Restoration"] = "Restauração"
L["SPEC_Arcane"] = "Arcano"
L["SPEC_Fire"] = "Fogo"
L["SPEC_Frost"] = "Gélido"
L["SPEC_Affliction"] = "Suplício"
L["SPEC_Demonology"] = "Demonologia"
L["SPEC_Destruction"] = "Destruição"
L["SPEC_Balance"] = "Equilíbrio"
L["SPEC_Feral"] = "Feral"
L["SPEC_Guardian"] = "Guardião"
L["SPEC_Blood"] = "Sangue"
L["SPEC_Unholy"] = "Profano"
L["SPEC_Brewmaster"] = "Mestre Cervejeiro"
L["SPEC_Mistweaver"] = "Tecelão da Névoa"
L["SPEC_Windwalker"] = "Andarilho do Vento"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Proteção"
L["SPEC_DRUID_Restoration"] = "Restauração"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Tanque (runas)"
L["SPEC_Healer"] = "Curandeiro (runas)"
L["SPEC_Melee"] = "Corpo a corpo (runas)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "Meus alts"
L["OPTIONS_ALTS_INTRO"] =
	"Seus próprios personagens, cada um adicionado quando entra no jogo com o Play It Forward. Escolha um à esquerda para definir se ele recebe correio e para quais especializações recebe equipamento."
L["OPTIONS_SEND_TO_ALTS"] = "Enviar para alts"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Envie primeiro para seus próprios personagens, antes da sua guilda e de desconhecidos, mas só itens para os quais a classe deles é a mais indicada. Um personagem conta depois que entra no jogo com o Play It Forward neste reino ou em um reino conectado, nesta facção. Correio para seus alts não conta para os totais da sua Insígnia da Generosidade."
L["OPTIONS_ALTS_EMPTY"] =
	"Nenhum personagem ainda. Cada um dos seus personagens aparece aqui depois que entra no jogo com o Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Incluir este personagem"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Enviar equipamento para este personagem. Desmarcado, ele nunca recebe oferta de nada. Um personagem no nível máximo começa desmarcado."
L["OPTIONS_ALT_SPECS"] = "Enviar equipamento para"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Oferecer a este personagem equipamento para esta especialização. Começa com a especialização que o personagem jogou por último, ou com todas até que ele tenha uma."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Níveis do equipamento"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Mínimo"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"O equipamento de nível mais baixo enviado a este personagem. Nível do personagem não envia nada abaixo do nível dele; Nível do personagem -2 também envia equipamento de até dois níveis abaixo, que ele já pode usar."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Máximo"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"O equipamento de nível mais alto enviado a este personagem. Qualquer equipamento que possa usar envia tudo o que ele vai poder usar no futuro, então um caçador de nível 1 pode receber um arco de nível 50."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Nível do personagem"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Nível do personagem -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Nível do personagem +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Qualquer equipamento que possa usar"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Recebe equipamento dos níveis %d a %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Recebe equipamento a partir do nível %d."
L["OPTIONS_DELETE"] = "Excluir"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "Esquecer %s? Ele volta a ser adicionado na próxima vez que entrar no jogo."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] =
	"Esquecer este personagem. Ele volta a ser adicionado na próxima vez que entrar no jogo."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Minhas guildas"
L["OPTIONS_GUILDS_INTRO"] =
	"Todas as guildas em que seus personagens estão, salvas cada vez que um deles entra no jogo, para que o personagem que você estiver usando possa enviar correio aos colegas de guilda que estão subindo de nível."
L["OPTIONS_GUILD_OFFLINE"] = "Ignorar membros da guilda offline"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Pular colegas de guilda que não entram no jogo há mais tempo que isso, na guilda em que você está agora e nas salvas. Escolha Nunca para incluir todos, não importa há quanto tempo estejam ausentes."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Há mais de 1 semana"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Há mais de 2 semanas"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Nunca"
L["OPTIONS_GUILDS_EMPTY"] =
	"Nenhuma guilda ainda. Uma guilda aparece aqui depois que um dos seus personagens nela entra no jogo."
L["OPTIONS_GUILD_INCLUDE"] = "Enviar aos membros desta guilda"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Enviar equipamento aos membros desta guilda."
L["OPTIONS_GUILD_MEMBERS"] = "Membros ativos"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "Ninguém nesta lista esteve ativo recentemente o bastante para receber itens."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Incluir"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Enviar equipamento a este colega de guilda. Desmarque para um banco de guilda ou um alt de profissão, e ele nunca receberá oferta de nada."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d membros ativos, lista salva %s por %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "hoje"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "ontem"
L["OPTIONS_GUILD_SAVED_DAYS"] = "há %d dias"
L["OPTIONS_GUILD_CURRENT"] = "Sua guilda atual, lida na hora na caixa de correio."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "Em outro reino, então o correio não chega até ela daqui."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "Na outra facção, então o correio não chega até ela daqui."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Texto da mensagem do correio"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"O bilhete que acompanha cada presente. Escreva o seu à esquerda e veja à direita exatamente o que será enviado. As alterações são salvas enquanto você digita; esvazie um campo para voltar ao texto padrão."
L["OPTIONS_MAIL_SUBJECT"] = "Assunto"
L["OPTIONS_MAIL_BODY"] = "Corpo"
L["OPTIONS_MAIL_YOURS"] = "Sua mensagem"
L["OPTIONS_MAIL_PREVIEW"] = "O que eles recebem"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Assunto %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Corpo %d/%d"
L["OPTIONS_MAIL_RESET"] = "Restaurar padrão"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Voltar ao assunto e corpo padrão."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Insígnia da Generosidade"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Seus totais de doações, somando todos os personagens da sua conta. Eles aparecem na dica do seu personagem em cidades e estalagens, onde outros usuários do Play It Forward os veem ao passar o mouse sobre você, e você vê os deles. Ficam ocultos em masmorras, raides e pelo mundo afora."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Insígnia da Generosidade"
L["OPTIONS_GENEROSITY_GIFTS"] = "Presentes"
L["OPTIONS_GENEROSITY_ITEMS"] = "Itens"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Níveis de item"
L["OPTIONS_GENEROSITY_VALUE"] = "Valor em ouro"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Ativar dicas de jogador da Insígnia da Generosidade"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Jogadores perto de você em cidades e estalagens podem ver seus totais na sua dica. Desativar interrompe o compartilhamento, mas você continua vendo os deles, e seus próprios totais continuam contando de qualquer forma."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Ajude o Play It Forward a subir de nível"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Este add-on foi criado por jogadores que amam este jogo e querem deixá-lo o mais divertido possível para todos. Nunca vamos pedir doações. A verdadeira satisfação é saber que nosso trabalho deixa o jogo um pouco melhor para você. Se for o caso, adoraríamos saber!"
L["OPTIONS_LEVEL_UP_WAYS"] = "Aqui estão algumas formas de nos ajudar a alcançar mais jogadores."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Envie feedback: Encontrou um bug ou tem uma ideia? Conte para a gente no Discord. Seu feedback nos ajuda a melhorar o add-on, e pull requests são sempre bem-vindos."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Conte para um amigo: Conhece alguém que pode gostar deste add-on? Conte para essa pessoa. O boca a boca ajuda mais jogadores a descobrir ótimos add-ons."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Favorite no CurseForge: Abra o link do CurseForge abaixo, entre na sua conta e clique na estrela abaixo do botão Download. Os favoritos ajudam mais jogadores a descobrir o add-on."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star no GitHub: Abra o link do GitHub abaixo, entre na sua conta e clique em Star no canto superior direito. As estrelas ajudam o projeto a se qualificar para mais ferramentas gratuitas para desenvolvedores."
L["OPTIONS_LEVEL_UP_THANKS"] = "Obrigado por escolher o Play It Forward!"

L["OPTIONS_FEEDBACK"] = "Feedback e suporte"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Links de feedback e suporte"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "Para copiar um link, clique na caixa dele e pressione Ctrl+A e Ctrl+C."
L["OPTIONS_VERSION"] = "Versão %s"
