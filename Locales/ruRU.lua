local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "ruRU")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "Окно раздачи"
L["CHAT_LOADED"] =
	"Версия %s. Настройки (включая отключение этого сообщения) находятся в разделе Настройки > Модификации > Play It Forward. Нравится эта модификация? Расскажите о ней другу, добавьте ее в избранное на CurseForge или поставьте Star на GitHub. (="
L["CHAT_OPTIONS_IN_COMBAT"] =
	"Из соображений безопасности окно настроек нельзя открыть в бою."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "Снаряжение"
L["WINDOW_CONSUMABLES_LABEL"] = "Расходуемые"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "Распыление"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "Выберите персонажа"
L["WINDOW_DISENCHANT_NONE"] =
	"Ваши персонажи появятся, как только каждый войдет в игру с Play It Forward."

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
L["BUTTON_NEEDS_MAILBOX"] = "Нужен почтовый ящик"
--[[
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "Отправка..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] =
	"Повторный поиск через %d сек. Попробуйте снова, когда на кнопке будет Найти получателей."
L["WHO_BLOCKED"] =
	"Нажмите Найти получателей еще раз. Blizzard разрешает этот поиск только напрямую по нажатию кнопки, а этот поиск что-то прервало."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "Показывает, что можно отдать из ваших сумок."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "Больше нечего отдавать."
L["WINDOW_EMPTY_HINT"] = "Измените настройки выше, чтобы показать больше."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "Нажмите Найти получателей. Предметов для поиска: %d."
L["STATUS_MORE"] =
	"Еще поисков: %d. Нажмите Найти получателей, чтобы продолжить."
L["STATUS_DONE"] =
	"Поиск завершен. Без получателя в диапазоне: %d. Попробуйте позже."
L["STATUS_READY"] = "Нажмите Раздать, чтобы отправить предметы: %d."
L["STATUS_AWAY"] = "Откройте почтовый ящик, чтобы отправить предметы: %d."
L["STATUS_SENDING"] = "Отправка %d из %d. Нажимайте Принять в каждом окне."

L["SECTION_MATCHED"] = "Подобрано"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "Ожидает подбора"
L["SECTION_UNREADABLE"] = "Характеристики не прочитаны"

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
L["WINDOW_KEPT"] = "Оставлено"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "Нет получателя"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "Ошибка чтения характеристик"

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
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"Уже назначен в другой строке. Ваш выбор важнее, а строка, которую вы не задавали сами, найдет кого-то другого."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"Письмо этому игроку вернулось ранее в этой сессии. Можно попробовать еще раз."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"Уже получил от вас подарок в этой сессии. Снова будет в приоритете, когда повысит уровень."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "Найти получателей для этого предмета"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "Ваши твинки"
L["PICKER_SECTION_GUILD"] = "Ваша гильдия"
L["PICKER_SECTION_STRANGERS"] = "Незнакомцы"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "Распыление"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "Получатель"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "Кандидатов: %d, уровни %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "Щелкните, чтобы переназначить."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "Лучше всего подходит: %s."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] =
	"Не удалось прочитать характеристики этого предмета, поэтому он не подобран."
L["TOOLTIP_RECIPIENT_KEPT"] =
	"Ни одному классу он не нужен, поэтому он остается в ваших сумках."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] =
	"Никому не подходит, поэтому отправляется персонажу %s на распыление."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] =
	"Отправляется при нажатии Раздать. Снимите галочку, чтобы оставить."
L["TOOLTIP_CHECK_WAITING"] =
	"Подбирается, как только поиск кого-нибудь найдет. Снимите галочку, чтобы оставить."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] =
	"Выберите получателя из списка, чтобы отправить этот предмет."
L["TOOLTIP_CHECK_UNREADABLE"] =
	"Этот предмет нельзя отправить, пока не прочитаны его характеристики."

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
L["MAIL_STILL_SENDING"] = "Еще отправляется. Секунду."
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
	"Если вы пользуетесь TSM, переключитесь для этого на стандартную панель отправки почты Blizzard. Почтовый ящик TSM не принимает вложения."
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
	"Отправляйте почтой снаряжение, которое становится персональным при надевании, еду, зелья, свитки, масла и камни, из которых вы выросли, своим твинкам, согильдийцам и игрокам, которые еще качаются. Каждый предмет достается классу, которому он подходит лучше всего, и хлам в сумках становится чьим-то следующим улучшением. Передайте добро дальше, по одной зеленой вещи за раз."
L["OPTIONS_WELCOME"] = "Включить приветственное сообщение"
L["OPTIONS_WELCOME_DESCRIPTION"] =
	"Выводить версию и напоминание о настройках при входе в игру."

L["OPTIONS_FEATURES_HEADER"] = "Функции"

L["OPTIONS_COMMANDS_HEADER"] = "/Команды"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "Открывает окно настроек этой модификации."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "Что отдавать"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"Выберите, что вы отдаете другим игрокам. Снаряжение и расходуемые предметы также можно в любой момент переключить в верхней части Окна раздачи."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"Наивысшая предлагаемая редкость. Все, что выше, никогда не показывается, поэтому хорошую добычу нельзя отправить случайно."
L["OPTIONS_DISTRIBUTE_GEAR"] = "Раздавать снаряжение"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] =
	"Предлагать оружие и доспехи, становящиеся персональными при надевании."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "Раздавать расходуемые предметы"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"Предлагать низкоуровневую еду, питье, зелья, свитки, масла и камни, из которых вы выросли."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "Масла и камни"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"Предлагать масла для оружия, точильные камни и грузила, из которых вы выросли. Волшебные масла достаются заклинателям, масла маны достаются всем, кто использует ману, а камни и прочие масла достаются бойцам ближнего боя."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "Распыление неподобранных предметов"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"Снаряжение, для которого никто не подобран, можно отправить одному из ваших персонажей на распыление, вместо того чтобы оставлять его в сумках. Включите эту функцию, затем выберите персонажа. Для каждого игрового мира и фракции выбор хранится отдельно."
L["OPTIONS_DISENCHANT_SEND"] =
	"Отправлять неподобранные предметы зачарователю"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"Снаряжение, которое никому не подходит, отправляется одному из ваших персонажей на распыление, а не остается в сумках. Расходуемые предметы не отправляются никогда."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"Ваш зачарователь. В списке ваши персонажи этой фракции в этом игровом мире и связанных с ним мирах, как только каждый войдет в игру с Play It Forward."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "Получатели"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"Кому достается ваше снаряжение и в каком порядке. Какие персонажи и гильдии учитываются, выберите ниже на страницах Мои твинки и Мои гильдии."

L["OPTIONS_PRIORITY_HEADER"] = "Кто в приоритете"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"Ваши персонажи и согильдийцы могут встать в начало очереди за всем, что подходит им так же хорошо, как незнакомцу. Снимите любую из галочек, и они будут соперничать со всеми остальными по уровню и местоположению."
L["OPTIONS_PRIORITIZE_ALTS"] =
	"Сначала Мои твинки, затем незнакомцы и Мои гильдии"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"Ваши персонажи первыми получают все, что подходит им не хуже, чем кому-либо другому. Без галочки они соперничают со всеми остальными по уровню и местоположению."
L["OPTIONS_PRIORITIZE_GUILDS"] = "Сначала Мои гильдии, затем незнакомцы"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"Ваши согильдийцы раньше незнакомцев получают все, что подходит им так же хорошо. Без галочки они соперничают с незнакомцами по уровню и местоположению."

L["OPTIONS_STRANGERS_HEADER"] = "При поиске незнакомцев"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"Как сравниваются между собой игроки, найденные через /who. Среди одинаково подходящих снаряжение сначала получает тот, кто, скорее всего, качается и пустит его в дело."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "Сначала незнакомцы в зонах своего уровня"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"Сначала предлагать снаряжение игрокам, выполняющим задания в зоне для их уровня, а не тем, кто стоит в городе. Именно такие игроки, скорее всего, оценят вашу доброту."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "Сначала незнакомцы вне подземелий"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"Предлагать снаряжение игрокам в подземелье или рейде, только если в открытом мире нет никого подходящего. Игроки в подземелье могут оказаться персонажами, которых прокачивают другие, и снаряжение им скоро не понадобится."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "Игнорировать чернокнижников %d-%d уровня"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"Никогда не предлагать снаряжение незнакомцам-чернокнижникам этого диапазона уровней. Чернокнижники учатся призыву на 20-м уровне, и многие игроки держат здесь твинка-чернокнижника только для призыва друзей, поэтому отправленное им снаряжение часто не используется. Ваших персонажей и согильдийцев это не касается."

L["OPTIONS_SPECS_HEADER"] = "Классы и специализации"
L["OPTIONS_SPECS_INTRO"] =
	"Никто не видит специализацию другого игрока, поэтому снаряжение раздается исходя из этих предположений. Для ваших персонажей используются специализации, заданные на странице Мои твинки."
L["OPTIONS_SPECS_RESET"] = "Вернуть по умолчанию"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] =
	"Вернуть все специализации к исходным настройкам модификации."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "Урон заклинаниями"
L["ROLE_MELEE"] = "Урон в ближнем бою"
L["ROLE_RANGED"] = "Урон в дальнем бою"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "Оружие"
L["SPEC_Fury"] = "Неистовство"
L["SPEC_Protection"] = "Защита"
L["SPEC_Holy"] = "Свет"
L["SPEC_Retribution"] = "Воздаяние"
L["SPEC_BeastMastery"] = "Повелитель зверей"
L["SPEC_Marksmanship"] = "Стрельба"
L["SPEC_Survival"] = "Выживание"
L["SPEC_Assassination"] = "Ликвидация"
L["SPEC_Combat"] = "Бой"
L["SPEC_Subtlety"] = "Скрытность"
L["SPEC_Discipline"] = "Послушание"
L["SPEC_Shadow"] = "Тьма"
L["SPEC_Elemental"] = "Стихии"
L["SPEC_Enhancement"] = "Совершенствование"
L["SPEC_Restoration"] = "Исцеление"
L["SPEC_Arcane"] = "Тайная магия"
L["SPEC_Fire"] = "Огонь"
L["SPEC_Frost"] = "Лед"
L["SPEC_Affliction"] = "Колдовство"
L["SPEC_Demonology"] = "Демонология"
L["SPEC_Destruction"] = "Разрушение"
L["SPEC_Balance"] = "Баланс"
L["SPEC_Feral"] = "Сила зверя"
L["SPEC_Guardian"] = "Страж"
L["SPEC_Blood"] = "Кровь"
L["SPEC_Unholy"] = "Нечестивость"
L["SPEC_Brewmaster"] = "Хмелевар"
L["SPEC_Mistweaver"] = "Ткач туманов"
L["SPEC_Windwalker"] = "Танцующий с ветром"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "Защита"
L["SPEC_DRUID_Restoration"] = "Исцеление"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "Танк (руны)"
L["SPEC_Healer"] = "Лекарь (руны)"
L["SPEC_Melee"] = "Ближний бой (руны)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "Мои твинки"
L["OPTIONS_ALTS_INTRO"] =
	"Ваши персонажи, каждый добавляется, как только войдет в игру с Play It Forward. Выберите персонажа слева, чтобы решить, получает ли он почту и для каких специализаций ему отправляется снаряжение."
L["OPTIONS_SEND_TO_ALTS"] = "Отправлять твинкам"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"Отправлять почту вашим персонажам в первую очередь, раньше гильдии и незнакомцев, но только те предметы, для которых их класс подходит лучше всего. Персонаж учитывается, как только войдет в игру с Play It Forward в этом игровом мире или связанном с ним, за эту фракцию. Почта твинкам не учитывается в итогах Знака щедрости."
L["OPTIONS_ALTS_EMPTY"] =
	"Персонажей пока нет. Каждый ваш персонаж появится здесь, как только войдет в игру с Play It Forward."
L["OPTIONS_ALT_INCLUDE"] = "Включить этого персонажа"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"Отправлять снаряжение этому персонажу. Без галочки ему ничего не предлагается. У персонажа максимального уровня галочка изначально снята."
L["OPTIONS_ALT_SPECS"] = "Отправлять снаряжение для"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"Предлагать этому персонажу снаряжение для этой специализации. Изначально выбрана специализация, за которую персонаж играл последней, или все специализации, пока у него ее нет."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "Уровни снаряжения"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "Минимум"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"Снаряжение самого низкого уровня, которое отправляется этому персонажу. Уровень персонажа не отправляет ничего ниже его уровня; Уровень персонажа -2 отправляет также снаряжение до двух уровней ниже, которое он может носить уже сейчас."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "Максимум"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"Снаряжение самого высокого уровня, которое отправляется этому персонажу. Любое подходящее снаряжение отправляет все, до чего он дорастет, так что охотнику 1-го уровня можно отправить лук 50-го уровня."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "Уровень персонажа"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "Уровень персонажа -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "Уровень персонажа +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "Любое подходящее снаряжение"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "Отправляется снаряжение для уровней %d-%d."
L["OPTIONS_ALT_LEVELS_FROM"] = "Отправляется снаряжение от %d уровня и выше."
L["OPTIONS_DELETE"] = "Удалить"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] =
	"Забыть %s? Персонаж снова добавится при следующем входе в игру."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] =
	"Забыть этого персонажа. Он снова добавится при следующем входе в игру."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "Мои гильдии"
L["OPTIONS_GUILDS_INTRO"] =
	"Все гильдии, в которых состоят ваши персонажи. Они сохраняются при каждом входе одного из них, чтобы любой ваш персонаж мог отправлять почту качающимся согильдийцам."
L["OPTIONS_GUILD_OFFLINE"] = "Игнорировать согильдийцев не в сети"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"Пропускать согильдийцев, которые не заходили в игру дольше указанного срока, в текущей гильдии и в сохраненных. Выберите Никогда, чтобы учитывать всех, сколько бы они ни отсутствовали."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "Дольше 1 недели"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "Дольше 2 недель"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "Никогда"
L["OPTIONS_GUILDS_EMPTY"] =
	"Гильдий пока нет. Гильдия появится здесь, как только в игру войдет один из ваших персонажей, состоящих в ней."
L["OPTIONS_GUILD_INCLUDE"] = "Отправлять почту членам этой гильдии"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] =
	"Отправлять снаряжение членам этой гильдии."
L["OPTIONS_GUILD_MEMBERS"] = "Активные участники"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] =
	"Никто в этом составе не был активен достаточно недавно, чтобы получать предметы."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "Включить"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"Отправлять снаряжение этому согильдийцу. Снимите галочку для гильдбанка или персонажа-ремесленника, и ему никогда ничего не будет предложено."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "Активных участников: %d. Сохранено %s персонажем %s."
L["OPTIONS_GUILD_SAVED_TODAY"] = "сегодня"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "вчера"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d дн. назад"
L["OPTIONS_GUILD_CURRENT"] =
	"Ваша текущая гильдия, данные обновляются у почтового ящика."
L["OPTIONS_GUILD_SKIPPED_REALM"] =
	"В другом игровом мире, поэтому почта отсюда не дойдет."
L["OPTIONS_GUILD_SKIPPED_FACTION"] =
	"В другой фракции, поэтому почта отсюда не дойдет."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "Текст письма"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"Записка, которая уходит с каждым подарком. Напишите свою слева, а справа видно, что именно будет отправлено. Изменения сохраняются по мере ввода; очистите поле, чтобы вернуть текст по умолчанию."
L["OPTIONS_MAIL_SUBJECT"] = "Тема"
L["OPTIONS_MAIL_BODY"] = "Текст"
L["OPTIONS_MAIL_YOURS"] = "Ваше письмо"
L["OPTIONS_MAIL_PREVIEW"] = "Что получат"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "Тема %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "Текст %d/%d"
L["OPTIONS_MAIL_RESET"] = "Вернуть по умолчанию"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "Вернуть тему и текст по умолчанию."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "Знак щедрости"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"Ваши итоги раздачи со всех персонажей учетной записи. Они видны в вашей подсказке игрока в городах и тавернах, где другие пользователи Play It Forward видят их, наводя на вас курсор, а вы видите их итоги. В подземельях, рейдах и в открытом мире они скрыты."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "Знак щедрости"
L["OPTIONS_GENEROSITY_GIFTS"] = "Подарки"
L["OPTIONS_GENEROSITY_ITEMS"] = "Предметы"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "Уровни предметов"
L["OPTIONS_GENEROSITY_VALUE"] = "Стоимость в золоте"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "Включить Знак щедрости в подсказках игрока"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"Игроки рядом с вами в городах и тавернах видят ваши итоги в вашей подсказке. Если отключить, вы перестанете делиться, но по-прежнему будете видеть их итоги, а ваши собственные итоги продолжат считаться в любом случае."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Помогите Play It Forward повысить уровень"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"Эту модификацию создали игроки, которые любят эту игру и хотят сделать ее как можно интереснее для всех. Мы никогда не будем просить пожертвований. Самое большое удовлетворение мы получаем, зная, что наша работа делает игру для вас чуточку лучше. Если это так, мы будем рады об этом услышать!"
L["OPTIONS_LEVEL_UP_WAYS"] =
	"Вот несколько способов помочь нам охватить больше игроков."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• Поделитесь отзывом: Нашли ошибку или есть идея? Сообщите нам в Discord. Ваши отзывы помогают нам улучшать модификацию, а пул-реквесты всегда приветствуются."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• Расскажите другу: Знаете кого-то, кому может понравиться эта модификация? Расскажите ему о ней. Сарафанное радио помогает большему числу игроков находить отличные модификации."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• Избранное на CurseForge: Откройте ссылку на CurseForge ниже, войдите в аккаунт и нажмите на звезду под кнопкой Download. Избранное помогает большему числу игроков найти модификацию."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• Star на GitHub: Откройте ссылку на GitHub ниже, войдите в аккаунт и нажмите Star в правом верхнем углу. Звезды помогают проекту получить доступ к большему числу бесплатных инструментов для разработчиков."
L["OPTIONS_LEVEL_UP_THANKS"] = "Спасибо, что выбрали Play It Forward!"

L["OPTIONS_FEEDBACK"] = "Отзывы и поддержка"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "Ссылки для отзывов и поддержки"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] =
	"Чтобы скопировать ссылку, щелкните по ее полю, затем нажмите Ctrl+A и Ctrl+C."
L["OPTIONS_VERSION"] = "Версия %s"
