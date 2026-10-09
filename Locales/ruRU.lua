local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "ruRU")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"Версия %s. Настройки (включая отключение этого сообщения) находятся в разделе Настройки > Модификации > Play It Forward. Нравится модификация? Расскажите о ней другу! (="
L["CHAT_OPTIONS_IN_COMBAT"] =
	"Из соображений безопасности окно настроек нельзя открыть в бою."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "Снаряжение"
L["WINDOW_CONSUMABLES_LABEL"] = "Расходуемые"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s и ниже"

L["BUTTON_FIND_RECIPIENTS"] = "Найти получателей"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "Поиск..."
L["BUTTON_DISTRIBUTE"] = "Раздать"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "Нужен открытый почтовый ящик"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"Нажмите Найти получателей еще раз. Blizzard разрешает этот поиск только напрямую по нажатию кнопки, а этот поиск что-то прервало."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "Больше нечего отдавать."
L["WINDOW_EMPTY_HINT"] =
	"Измените Снаряжение или Расходуемые выше, чтобы показать больше."

L["SECTION_MATCHED"] = "Подобрано"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Ожидает подбора"
L["SECTION_UNREADABLE"] = "Характеристики не прочитаны"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "Оставлено"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Нет получателя"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Не прочитано"

L["PICKER_KEEP_OPTION"] = "Оставить предмет"
L["PICKER_NONE_IN_RANGE"] =
	"Никого в диапазоне уровней. Нажмите Найти получателей."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(уже есть)"
L["PICKER_NOTE_REFUSED"] = "(отказ)"
L["PICKER_NOTE_RECENT"] = "(недавно)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Найти получателей для этого предмета"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Получатель"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "Кандидатов: %d, уровни %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Щелкните, чтобы переназначить."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] =
	"Не удалось прочитать характеристики этого предмета, поэтому он не подобран."
L["TOOLTIP_RECIPIENT_KEPT"] =
	"Ни одному классу он не нужен, поэтому он остается в ваших сумках."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] =
	"Отправляется при нажатии Раздать. Снимите галочку, чтобы оставить."
L["TOOLTIP_CHECK_WAITING"] =
	"Подбирается, как только поиск кого-нибудь найдет. Снимите галочку, чтобы оставить."

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
L["MAIL_STILL_SENDING"] = "Еще отправляется, секунду."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "Нечего раздавать."
L["MAIL_DISTRIBUTING"] =
	"Нажмите Принять в каждом окне подтверждения, чтобы отправить предметы: %d."
L["MAIL_ITEM_MOVED"] =
	"Нажмите Найти получателей, чтобы пересканировать. %s перемещен в ваших сумках."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] =
	"Выберите кого-нибудь другого для %s. %s уже получает такой."
L["MAIL_NOT_AT_MAILBOX"] =
	"Вернитесь к почтовому ящику и нажмите Раздать, чтобы отправить остальное."
L["MAIL_MAILBOX_CLOSED"] =
	"Откройте почтовый ящик и нажмите Раздать, чтобы отправить остальное. Почтовый ящик закрылся на полпути."
L["MAIL_NO_POSTAGE"] =
	"Добавьте немного меди на почтовый сбор, затем нажмите Раздать, чтобы отправить остальное."
L["MAIL_PANEL_CLOSED"] =
	"Откройте стандартную панель отправки почты Blizzard и снова нажмите Раздать. Ничего не отправлено и не затронуто."
L["MAIL_PANEL_CLOSED_HINT"] =
	"Если вы пользуетесь TSM, переключитесь для этого на стандартный интерфейс почты. Почтовый ящик TSM не принимает вложения."
L["MAIL_ATTACH_FAILED"] = "Не удалось вложить %s, поэтому он не отправлен."
L["MAIL_AWAITING_CONFIRM"] =
	"Нажмите Принять во всплывающем окне для %s, затем нажмите Раздать, чтобы отправить остальное."
L["MAIL_SENT"] = "%s отправлен игроку %s (%d/%d)."
L["MAIL_SEND_FAILED"] = "Не удалось отправить почту игроку %s (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "причина не указана"
L["MAIL_REASON_ERROR"] = "ошибка клиента"
L["MAIL_ABORTED"] = "Раздача остановлена после повторных ошибок почты."
L["MAIL_DONE"] = "Готово. Отправлено %d из %d."
L["MAIL_DONE_WITH_SKIPS"] =
	"Готово. Отправлено %d из %d, пропущено %d (перемещены в сумках)."
L["MAIL_SUBJECT_TOO_LONG"] =
	"В теме %d символов, а почта принимает только %d, поэтому она будет обрезана."
L["MAIL_BODY_TOO_LONG"] =
	"В тексте %d символов, а почта принимает только %d, поэтому он будет обрезан."

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
	"Отправляйте снаряжение и расходуемые предметы, из которых вы выросли, согильдийцам или незнакомцам, которые их оценят. Каждый предмет подбирается для класса, которому он подходит лучше всего, и забытый хлам в сумках становится чьим-то следующим улучшением. Передайте добро дальше, по одной зеленой вещи за раз."
L["OPTIONS_WELCOME"] = "Включить приветственное сообщение"
L["OPTIONS_WELCOME_DESCRIPTION"] =
	"Выводить версию и напоминание о настройках при входе в игру."

L["OPTIONS_COMMANDS_HEADER"] = "/Команды"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Открывает окно настроек этой модификации."

L["OPTIONS_GIVE_HEADER"] = "Что отдавать"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"Наивысшая предлагаемая редкость. Все, что выше, никогда не показывается, поэтому хорошую добычу нельзя отправить случайно."
L["OPTIONS_INCLUDE_GEAR"] = "Включить снаряжение"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] =
	"Предлагать оружие и доспехи, становящиеся персональными при надевании."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "Включить расходуемые"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"Предлагать низкоуровневую еду, питье, зелья и свитки, из которых вы выросли."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "Устарело на %d+ уровней"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "Все расходуемые"
L["OPTIONS_CONSUMABLE_GAP"] = "Правило уровня"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"На сколько уровней вы должны обогнать расходуемый предмет, чтобы он считался лишним. При 20 и более вода 35-го уровня предлагается, когда вы достигнете 55-го уровня. Все расходуемые предлагает все такие предметы в ваших сумках, независимо от вашего уровня."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "Еда"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"Предлагать еду, из которой вы выросли. Еда, которая также восполняет ману, предлагается, пока включено Еда или Питье."
L["OPTIONS_KIND_DRINK"] = "Питье"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] =
	"Предлагать воду, сок и другие напитки, из которых вы выросли."
L["OPTIONS_KIND_POTIONS"] = "Зелья"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] =
	"Предлагать зелья исцеления, маны и омоложения, из которых вы выросли."
L["OPTIONS_KIND_SCROLLS"] = "Свитки"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"Предлагать свитки характеристик, из которых вы выросли. Каждый достается классам, которые используют его характеристику."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Щедрость"
L["OPTIONS_GENEROSITY_GIFTS"] = "Подарки"
L["OPTIONS_GENEROSITY_ITEMS"] = "Предметы"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Уровни предметов"
L["OPTIONS_GENEROSITY_VALUE"] = "Стоимость в золоте"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Включить подсказки щедрости"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Игроки рядом с вами в городах и тавернах видят ваши итоги в вашей подсказке. Если отключить, вы перестанете делиться, но по-прежнему будете видеть их итоги, а ваши собственные итоги ниже продолжат считаться в любом случае."

L["OPTIONS_FEEDBACK_HEADER"] = "Отзывы и поддержка"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "Версия %s"
