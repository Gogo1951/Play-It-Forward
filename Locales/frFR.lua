local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "frFR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Fenêtre de distribution"
L["CHAT_LOADED"] =
	"Version %s. Les paramètres (y compris l'option pour désactiver ce message) se trouvent dans Options > AddOns > Play It Forward. Vous aimez cet add-on ? Parlez-en à un ami, ajoutez-le à vos favoris sur CurseForge ou donnez-lui une Star sur GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Par mesure de sécurité, l'interface des options ne peut pas être ouverte en combat."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Équipement"
L["WINDOW_CONSUMABLES_LABEL"] = "Consommables"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Désenchanter"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Choisir un personnage"
L["WINDOW_DISENCHANT_NONE"] = "Vos personnages apparaissent dès que chacun se connecte avec Play It Forward."

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s et inférieur"

L["BUTTON_FIND_RECIPIENTS"] = "Chercher des destinataires"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Recherche..."
L["BUTTON_DISTRIBUTE"] = "Distribuer"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Boîte aux lettres requise"
--[[
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Envoi..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "Nouvelle recherche dans %d s. Réessayez quand le bouton affiche Chercher des destinataires."
L["WHO_BLOCKED"] =
	"Appuyez de nouveau sur Chercher des destinataires. Blizzard n'autorise cette recherche que directement depuis un clic sur un bouton, et quelque chose a interrompu celle-ci."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Affiche ce que vous pouvez donner depuis vos sacs."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Plus rien à donner."
L["WINDOW_EMPTY_HINT"] = "Modifiez les paramètres ci-dessus pour en afficher plus."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Appuyez sur Chercher des destinataires pour %d objet(s)."
L["STATUS_MORE"] = "Encore %d recherche(s) prévue(s). Appuyez sur Chercher des destinataires."
L["STATUS_DONE"] = "Recherche finie. %d objet(s) sans destinataire adapté. Réessayez plus tard."
L["STATUS_READY"] = "Appuyez sur Distribuer pour envoyer %d objet(s)."
L["STATUS_AWAY"] = "Ouvrez une boîte aux lettres pour envoyer %d objet(s)."
L["STATUS_SENDING"] = "Envoi de %d sur %d. Cliquez sur Accepter dans chaque fenêtre."

L["SECTION_MATCHED"] = "Attribués"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "En attente d'attribution"
L["SECTION_UNREADABLE"] = "Caractéristiques illisibles"

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
L["WINDOW_KEPT"] = "Conservé"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Aucun destinataire"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Caractéristiques non lues"

L["PICKER_KEEP_OPTION"] = "Garder l'objet"
L["PICKER_NONE_IN_RANGE"] = "Personne dans la tranche de niveaux. Appuyez sur Chercher des destinataires."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(en a un)"
L["PICKER_NOTE_REFUSED"] = "(refusé)"
L["PICKER_NOTE_RECENT"] = "(récent)"
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Déjà sur une autre ligne. Votre choix l'emporte, et une ligne que vous n'avez pas réglée vous-même trouve quelqu'un d'autre."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Un courrier à ce joueur a été retourné plus tôt dans cette session. Vous pouvez quand même réessayer."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"A déjà reçu un cadeau de votre part dans cette session. Repasse en priorité dès qu'il gagne un niveau."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Chercher des destinataires pour cet objet"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Vos rerolls"
L["PICKER_SECTION_GUILD"] = "Votre guilde"
L["PICKER_SECTION_STRANGERS"] = "Inconnus"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Désenchanter"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinataire"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidat(s), niveaux %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Cliquez pour réattribuer."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Idéal pour %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Impossible de lire les caractéristiques de cet objet, il n'est donc pas attribué."
L["TOOLTIP_RECIPIENT_KEPT"] = "Aucune classe n'en veut, il reste donc dans vos sacs."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "Personne ne peut l'utiliser, il part donc chez %s pour être désenchanté."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Envoyé quand vous appuyez sur Distribuer. Décochez pour le garder."
L["TOOLTIP_CHECK_WAITING"] = "Attribué dès qu'une recherche trouve quelqu'un. Décochez pour le garder."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "Choisissez quelqu'un dans la liste pour envoyer celui-ci."
L["TOOLTIP_CHECK_UNREADABLE"] = "Celui-ci ne peut pas être envoyé tant que ses caractéristiques sont illisibles."

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
L["MAIL_STILL_SENDING"] = "Envoi en cours. Un instant."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Rien à distribuer."
L["MAIL_DISTRIBUTING"] = "Cliquez sur Accepter dans chaque fenêtre de confirmation pour envoyer %d objet(s)."
L["MAIL_ITEM_MOVED"] =
	"Appuyez sur Chercher des destinataires pour relancer l'analyse. %s a été déplacé dans vos sacs."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "Choisissez quelqu'un d'autre pour %s. %s en reçoit déjà un."
L["MAIL_NOT_AT_MAILBOX"] = "Retournez à une boîte aux lettres et appuyez sur Distribuer pour envoyer le reste."
L["MAIL_MAILBOX_CLOSED"] =
	"Ouvrez une boîte aux lettres et appuyez sur Distribuer pour envoyer le reste. La boîte aux lettres s'est fermée en cours de route."
L["MAIL_NO_POSTAGE"] =
	"Ajoutez un peu de cuivre pour l'affranchissement, puis appuyez sur Distribuer pour envoyer le reste."
L["MAIL_PANEL_CLOSED"] =
	"Ouvrez le panneau d'envoi de courrier de Blizzard et appuyez de nouveau sur Distribuer. Rien n'a été envoyé ni modifié."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Si vous utilisez TSM, passez au panneau d'envoi de courrier de Blizzard pour cela. La boîte aux lettres de TSM n'accepte pas les pièces jointes."
L["MAIL_ATTACH_FAILED"] = "Impossible de joindre %s, il n'a donc pas été envoyé."
L["MAIL_AWAITING_CONFIRM"] =
	"Cliquez sur Accepter dans la fenêtre pour %s, puis appuyez sur Distribuer pour envoyer le reste."
L["MAIL_SENT"] = "%s envoyé à %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Échec du courrier à %s (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "aucune raison donnée"
L["MAIL_REASON_ERROR"] = "erreur du client"
L["MAIL_ABORTED"] = "Distribution arrêtée après des erreurs de courrier répétées."
L["MAIL_DONE"] = "Terminé. %d sur %d envoyés."
L["MAIL_DONE_WITH_SKIPS"] = "Terminé. %d sur %d envoyés, %d ignorés (déplacés dans vos sacs)."

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
	"Envoyez par courrier l'équipement lié quand équipé, la nourriture, les potions, les parchemins, les huiles et les pierres devenus trop faibles pour vous à vos rerolls, aux membres de votre guilde et aux joueurs en pleine montée de niveau. Chaque objet va à la classe à qui il convient le mieux, et le bazar de vos sacs devient la prochaine amélioration de quelqu'un d'autre. Faites passer, un objet vert à la fois."
L["OPTIONS_WELCOME"] = "Activer le message de bienvenue"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Affiche la version et le rappel des paramètres à la connexion."

L["OPTIONS_FEATURES_HEADER"] = "Fonctionnalités"

L["OPTIONS_COMMANDS_HEADER"] = "/Commandes"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Ouvre l'interface des options de cet add-on."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "Que donner"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Choisissez ce que vous donnez aux autres joueurs. Vous pouvez aussi modifier l'équipement et les consommables à tout moment en haut de la Fenêtre de distribution."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rareté la plus élevée proposée. Rien au-dessus n'est jamais listé, pour qu'un bon butin ne parte pas par erreur."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Distribuer l'équipement"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "Proposer les armes et armures liées quand équipées."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Distribuer les consommables"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Proposer la nourriture, les boissons, les potions, les parchemins, les huiles et les pierres de bas niveau devenus trop faibles pour vous."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Dépassés de %d+ niveaux"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Tous les consommables"
L["OPTIONS_CONSUMABLE_GAP"] = "Règle de niveau"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"De combien de niveaux vous devez dépasser un consommable avant qu'il compte comme superflu. À 20 ou plus, une eau de niveau 35 est proposée dès que vous atteignez le niveau 55. Tous les consommables propose tous ceux de vos sacs, quel que soit votre niveau."

--[[
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Nourriture"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Proposer la nourriture devenue trop faible pour vous. La nourriture qui rend aussi du mana est proposée tant que Nourriture ou Boisson est activé."
L["OPTIONS_KIND_DRINK"] = "Boisson"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "Proposer l'eau, les jus et les autres boissons devenus trop faibles pour vous."
L["OPTIONS_KIND_POTIONS"] = "Potions"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] =
	"Proposer les potions de soins, de mana et de rajeunissement devenues trop faibles pour vous."
L["OPTIONS_KIND_SCROLLS"] = "Parchemins"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Proposer les parchemins de caractéristique devenus trop faibles pour vous. Chacun va aux classes qui utilisent sa caractéristique."
L["OPTIONS_KIND_OILS_STONES"] = "Huiles et pierres"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Proposer les huiles d'arme, pierres à aiguiser et pierres de lest devenues trop faibles pour vous. Les huiles de sorcier vont aux lanceurs de sorts, les huiles de mana à ceux qui utilisent du mana, et les pierres et autres huiles aux combattants au corps à corps."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Désenchanter les objets non attribués"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"L'équipement que personne n'a obtenu peut être envoyé à l'un de vos propres personnages pour être désenchanté, au lieu de rester dans vos sacs. Activez l'option, puis choisissez le personnage qui le reçoit. Chaque royaume et chaque faction garde son propre choix."
L["OPTIONS_DISENCHANT_SEND"] = "Envoyer les objets non attribués à l'enchanteur"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"L'équipement que personne ne peut utiliser part chez l'un de vos personnages pour être désenchanté, au lieu de rester dans vos sacs. Les consommables ne sont jamais envoyés."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Votre enchanteur. Liste vos personnages de ce royaume et de ses royaumes connectés, dans cette faction, dès que chacun s'est connecté avec Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Destinataires"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"À qui va votre équipement, et dans quel ordre. Choisissez quels personnages et quelles guildes comptent sur les pages Mes rerolls et Mes guildes ci-dessous."

L["OPTIONS_PRIORITY_HEADER"] = "Qui passe en premier"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Vos propres personnages et vos camarades de guilde peuvent passer en tête de file pour tout ce qui leur convient aussi bien qu'à un inconnu. Décochez l'un ou l'autre et ils sont mis en concurrence avec tout le monde selon le niveau et la zone."
L["OPTIONS_PRIORITIZE_ALTS"] = "Prioriser Mes rerolls avant les inconnus et Mes guildes"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Vos propres personnages se servent en premier pour tout ce qui leur convient aussi bien qu'à n'importe qui d'autre. Décochés, ils sont en concurrence avec tout le monde selon le niveau et la zone."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Prioriser Mes guildes avant les inconnus"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Vos camarades de guilde passent avant les inconnus pour tout ce qui leur convient aussi bien. Décochés, ils sont en concurrence avec les inconnus selon le niveau et la zone."

L["OPTIONS_STRANGERS_HEADER"] = "Lors de la recherche d'inconnus"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Comment les joueurs trouvés avec /who sont départagés. À pertinence égale, l'équipement va d'abord à celui qui est le plus susceptible d'être en pleine montée de niveau et de s'en servir."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Prioriser les inconnus dans des zones de leur niveau"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Proposer l'équipement d'abord aux joueurs qui font des quêtes dans une zone adaptée à leur niveau, avant ceux qui sont en ville. Ce sont eux qui apprécieront le plus votre gentillesse."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Prioriser les inconnus hors des instances"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Proposer l'équipement aux joueurs en donjon ou en raid seulement si personne d'adapté ne se trouve dans le monde. Les joueurs en donjon sont parfois des personnages qui se font booster, et n'auront pas besoin de l'équipement bien longtemps."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Ignorer les démonistes de niveau %d-%d"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Ne jamais proposer d'équipement aux inconnus qui sont démonistes dans cette tranche de niveaux. Les démonistes apprennent à invoquer au niveau 20, et beaucoup de joueurs laissent un reroll démoniste à ce niveau juste pour invoquer leurs amis, si bien que l'équipement qu'on leur envoie reste souvent inutilisé. Vos propres personnages et vos camarades de guilde ne sont pas concernés."

L["OPTIONS_SPECS_HEADER"] = "Classes et spécialisations"
L["OPTIONS_SPECS_INTRO"] =
	"Personne ne peut voir la spécialisation d'un autre joueur, donc l'équipement est attribué selon ces hypothèses. Vos propres personnages utilisent les spécialisations définies dans Mes rerolls."
L["OPTIONS_SPECS_RESET"] = "Rétablir par défaut"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "Remettre chaque spécialisation comme à l'installation de l'add-on."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Dégâts des sorts"
L["ROLE_MELEE"] = "Dégâts en mêlée"
L["ROLE_RANGED"] = "Dégâts à distance"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Armes"
L["SPEC_Fury"] = "Fureur"
L["SPEC_Protection"] = "Protection"
L["SPEC_Holy"] = "Sacré"
L["SPEC_Retribution"] = "Vindicte"
L["SPEC_BeastMastery"] = "Maîtrise des bêtes"
L["SPEC_Marksmanship"] = "Précision"
L["SPEC_Survival"] = "Survie"
L["SPEC_Assassination"] = "Assassinat"
L["SPEC_Combat"] = "Combat"
L["SPEC_Subtlety"] = "Finesse"
L["SPEC_Discipline"] = "Discipline"
L["SPEC_Shadow"] = "Ombre"
L["SPEC_Elemental"] = "Élémentaire"
L["SPEC_Enhancement"] = "Amélioration"
L["SPEC_Restoration"] = "Restauration"
L["SPEC_Arcane"] = "Arcanes"
L["SPEC_Fire"] = "Feu"
L["SPEC_Frost"] = "Givre"
L["SPEC_Affliction"] = "Affliction"
L["SPEC_Demonology"] = "Démonologie"
L["SPEC_Destruction"] = "Destruction"
L["SPEC_Balance"] = "Équilibre"
L["SPEC_Feral"] = "Combat farouche"
L["SPEC_Guardian"] = "Gardien"
L["SPEC_Blood"] = "Sang"
L["SPEC_Unholy"] = "Impie"
L["SPEC_Brewmaster"] = "Maître brasseur"
L["SPEC_Mistweaver"] = "Tisse-brume"
L["SPEC_Windwalker"] = "Marche-vent"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Protection"
L["SPEC_DRUID_Restoration"] = "Restauration"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Tank (runes)"
L["SPEC_Healer"] = "Soigneur (runes)"
L["SPEC_Melee"] = "Mêlée (runes)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "Mes rerolls"
L["OPTIONS_ALTS_INTRO"] =
	"Vos propres personnages, chacun ajouté dès qu'il se connecte avec Play It Forward. Choisissez-en un à gauche pour décider s'il reçoit du courrier et pour quelles spécialisations on lui envoie de l'équipement."
L["OPTIONS_SEND_TO_ALTS"] = "Envoyer aux rerolls"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Envoyer d'abord à vos propres personnages, avant votre guilde et les inconnus, mais uniquement les objets pour lesquels leur classe est idéale. Un personnage compte dès qu'il s'est connecté avec Play It Forward sur ce royaume ou un royaume connecté, dans cette faction. Les envois à vos rerolls ne comptent pas dans les totaux de votre Insigne de générosité."
L["OPTIONS_ALTS_EMPTY"] =
	"Aucun personnage pour l'instant. Chacun de vos personnages apparaît ici dès qu'il se connecte avec Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Inclure ce personnage"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Envoyer de l'équipement à ce personnage. Décoché, on ne lui propose jamais rien. Un personnage au niveau maximum commence décoché."
L["OPTIONS_ALT_SPECS"] = "Envoyer de l'équipement pour"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Proposer à ce personnage de l'équipement pour cette spécialisation. Au départ, c'est la dernière spécialisation jouée, ou toutes tant qu'il n'en a aucune."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Niveaux d'équipement"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Minimum"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"L'équipement du niveau le plus bas envoyé à ce personnage. Son niveau n'envoie rien en dessous de son niveau ; Son niveau -2 envoie aussi l'équipement jusqu'à deux niveaux en dessous, qu'il peut porter dès maintenant."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Maximum"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"L'équipement du niveau le plus élevé envoyé à ce personnage. Tout ce qu'il pourra utiliser envoie tout ce qu'il finira par pouvoir porter, si bien qu'un chasseur de niveau 1 peut recevoir un arc de niveau 50."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Son niveau"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Son niveau -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Son niveau +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Tout ce qu'il pourra utiliser"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Équipement envoyé pour les niveaux %d à %d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Équipement envoyé à partir du niveau %d."
L["OPTIONS_DELETE"] = "Supprimer"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "Oublier %s ? Il sera rajouté à sa prochaine connexion."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "Oublier ce personnage. Il sera rajouté à sa prochaine connexion."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Mes guildes"
L["OPTIONS_GUILDS_INTRO"] =
	"Chaque guilde dont vos personnages font partie, enregistrée chaque fois que l'un d'eux se connecte, pour que le personnage que vous jouez puisse envoyer du courrier à leurs camarades de guilde en pleine montée de niveau."
L["OPTIONS_GUILD_OFFLINE"] = "Ignorer les membres de guilde hors ligne"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Ignorer les camarades de guilde qui ne se sont pas connectés depuis plus longtemps que cela, dans votre guilde actuelle comme dans celles enregistrées. Choisissez Jamais pour inclure tout le monde, quelle que soit la durée de leur absence."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Depuis plus d'une semaine"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Depuis plus de 2 semaines"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Jamais"
L["OPTIONS_GUILDS_EMPTY"] =
	"Aucune guilde pour l'instant. Une guilde apparaît ici dès que l'un de vos personnages qui en fait partie se connecte."
L["OPTIONS_GUILD_INCLUDE"] = "Envoyer aux membres de cette guilde"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "Envoyer de l'équipement aux membres de cette guilde."
L["OPTIONS_GUILD_MEMBERS"] = "Membres actifs"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] =
	"Personne dans cette liste n'a été actif assez récemment pour recevoir des objets."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Inclure"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Envoyer de l'équipement à ce camarade de guilde. Décochez-le pour une banque de guilde ou un reroll métier, et on ne lui proposera jamais rien."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d membres actifs, enregistrés %s par %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "aujourd'hui"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "hier"
L["OPTIONS_GUILD_SAVED_DAYS"] = "il y a %d jours"
L["OPTIONS_GUILD_CURRENT"] = "Votre guilde actuelle, actualisée à la boîte aux lettres."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "Sur un autre royaume, le courrier ne peut donc pas l'atteindre d'ici."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "Dans l'autre faction, le courrier ne peut donc pas l'atteindre d'ici."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Texte du courrier"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"Le mot qui accompagne chaque cadeau. Écrivez le vôtre à gauche et voyez à droite exactement ce qui sera envoyé. Les modifications sont enregistrées pendant la saisie ; videz un champ pour revenir au texte par défaut."
L["OPTIONS_MAIL_SUBJECT"] = "Objet"
L["OPTIONS_MAIL_BODY"] = "Message"
L["OPTIONS_MAIL_YOURS"] = "Votre message"
L["OPTIONS_MAIL_PREVIEW"] = "Ce qu'ils reçoivent"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Objet %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Message %d/%d"
L["OPTIONS_MAIL_RESET"] = "Rétablir par défaut"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Revenir à l'objet et au message par défaut."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Insigne de générosité"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Vos totaux de dons, cumulés sur tous les personnages de votre compte. Ils s'affichent dans votre infobulle de joueur dans les villes et les auberges, où les autres utilisateurs de Play It Forward les voient en vous survolant, et vous voyez les leurs. Ils sont masqués en donjon, en raid et ailleurs dans le monde."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Insigne de générosité"
L["OPTIONS_GENEROSITY_GIFTS"] = "Cadeaux"
L["OPTIONS_GENEROSITY_ITEMS"] = "Objets"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Niveaux d'objet"
L["OPTIONS_GENEROSITY_VALUE"] = "Valeur en or"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Activer les infobulles de joueur de l'Insigne de générosité"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Les joueurs proches de vous dans les villes et les auberges peuvent voir vos totaux dans votre infobulle. Le désactiver arrête le partage, mais vous voyez toujours les leurs, et vos propres totaux continuent de compter dans tous les cas."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Aidez Play It Forward à monter de niveau"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Cet add-on a été créé par des joueurs qui adorent ce jeu et veulent le rendre aussi amusant que possible pour tout le monde. Nous ne demanderons jamais de dons. La vraie satisfaction, c'est de savoir que notre travail rend le jeu un peu meilleur pour vous. Si c'est le cas, nous serions ravis de le savoir !"
L["OPTIONS_LEVEL_UP_WAYS"] = "Voici quelques façons de nous aider à toucher plus de joueurs."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Donnez votre avis : Vous avez trouvé un bug ou avez une idée ? Dites-le-nous sur Discord. Vos retours nous aident à améliorer l'add-on, et les pull requests sont toujours les bienvenues."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Parlez-en à un ami : Vous connaissez quelqu'un qui pourrait aimer cet add-on ? Parlez-lui-en. Le bouche-à-oreille aide plus de joueurs à découvrir de super add-ons."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Favori sur CurseForge : Ouvrez le lien CurseForge ci-dessous, connectez-vous et cliquez sur l'étoile sous le bouton Download. Les favoris aident plus de joueurs à découvrir l'add-on."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star sur GitHub : Ouvrez le lien GitHub ci-dessous, connectez-vous et cliquez sur Star en haut à droite. Les stars aident le projet à obtenir plus d'outils de développement gratuits."
L["OPTIONS_LEVEL_UP_THANKS"] = "Merci d'avoir choisi Play It Forward !"

L["OPTIONS_FEEDBACK"] = "Retours et assistance"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Liens de retours et d'assistance"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "Pour copier un lien, cliquez dans sa case, puis appuyez sur Ctrl+A et Ctrl+C."
L["OPTIONS_VERSION"] = "Version %s"
