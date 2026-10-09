local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "frFR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Version %s. Les paramètres (y compris l'option pour désactiver ce message) se trouvent dans Options > AddOns > Play It Forward. Vous aimez cet add-on ? Parlez-en à un ami ! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "Par mesure de sécurité, l'interface des options ne peut pas être ouverte en combat."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Équipement"
L["WINDOW_CONSUMABLES_LABEL"] = "Consommables"

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
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Appuyez de nouveau sur Chercher des destinataires. Blizzard n'autorise cette recherche que directement depuis un clic sur un bouton, et quelque chose a interrompu celle-ci."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Plus rien à donner."
L["WINDOW_EMPTY_HINT"] = "Modifiez Équipement ou Consommables ci-dessus pour en afficher plus."

L["SECTION_MATCHED"] = "Attribués"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "En attente d'attribution"
L["SECTION_UNREADABLE"] = "Caractéristiques illisibles"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Conservé"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Aucun destinataire"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Illisible"

L["PICKER_KEEP_OPTION"] = "Garder l'objet"
L["PICKER_NONE_IN_RANGE"] = "Personne dans la tranche de niveaux. Appuyez sur Chercher des destinataires."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(en a un)"
L["PICKER_NOTE_REFUSED"] = "(refusé)"
L["PICKER_NOTE_RECENT"] = "(récent)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Chercher des destinataires pour cet objet"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Destinataire"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d candidat(s), niveaux %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Cliquez pour réattribuer."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "Impossible de lire les caractéristiques de cet objet, il n'est donc pas attribué."
L["TOOLTIP_RECIPIENT_KEPT"] = "Aucune classe n'en veut, il reste donc dans vos sacs."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "Envoyé quand vous appuyez sur Distribuer. Décochez pour le garder."
L["TOOLTIP_CHECK_WAITING"] = "Attribué dès qu'une recherche trouve quelqu'un. Décochez pour le garder."

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
L["MAIL_STILL_SENDING"] = "Envoi en cours, un instant."
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
	"Si vous utilisez TSM, passez à l'interface de courrier par défaut pour cela. La boîte aux lettres de TSM n'accepte pas les pièces jointes."
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
L["MAIL_SUBJECT_TOO_LONG"] = "L'objet fait %d caractères et le courrier n'en accepte que %d, il sera donc tronqué."
L["MAIL_BODY_TOO_LONG"] = "Le message fait %d caractères et le courrier n'en accepte que %d, il sera donc tronqué."

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
	"Envoyez l'équipement et les consommables devenus trop faibles pour vous à des membres de votre guilde ou à des inconnus qui sauront les apprécier. Chaque objet est attribué à la classe à qui il convient le mieux, et le bazar oublié de vos sacs devient la prochaine amélioration de quelqu'un d'autre. Faites passer, un objet vert à la fois."
L["OPTIONS_WELCOME"] = "Activer le message de bienvenue"
L["OPTIONS_WELCOME_DESCRIPTION"] = "Affiche la version et le rappel des paramètres à la connexion."

L["OPTIONS_COMMANDS_HEADER"] = "/Commandes"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Ouvre l'interface des options de cet add-on."

L["OPTIONS_GIVE_HEADER"] = "Que donner"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"La rareté la plus élevée proposée. Rien au-dessus n'est jamais listé, pour qu'un bon butin ne parte pas par erreur."
L["OPTIONS_INCLUDE_GEAR"] = "Inclure l'équipement"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "Proposer les armes et armures liées quand équipées."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Inclure les consommables"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Proposer la nourriture, les boissons, les potions et les parchemins de bas niveau devenus trop faibles pour vous."
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
	One switch per kind, drawn under Include Consumables and again in the mail window from
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

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Générosité"
L["OPTIONS_GENEROSITY_GIFTS"] = "Cadeaux"
L["OPTIONS_GENEROSITY_ITEMS"] = "Objets"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Niveaux d'objet"
L["OPTIONS_GENEROSITY_VALUE"] = "Valeur en or"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Activer les infobulles de générosité"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Les joueurs proches de vous dans les villes et les auberges voient vos totaux dans votre infobulle. Le désactiver arrête le partage, mais vous voyez toujours les leurs, et vos propres totaux ci-dessous continuent de compter dans tous les cas."

L["OPTIONS_FEEDBACK_HEADER"] = "Retours et assistance"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Version %s"
