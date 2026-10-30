local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "zhTW")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "分發視窗"
L["CHAT_LOADED"] =
	"版本 %s。設定（包括關閉此訊息的選項）位於 選項 > 插件 > Play It Forward。喜歡這個插件嗎？告訴朋友，在 CurseForge 上收藏它，或在 GitHub 上給它一顆 Star。(="
L["CHAT_OPTIONS_IN_COMBAT"] = "基於安全考量，戰鬥中無法開啟設定介面。"

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "裝備"
L["WINDOW_CONSUMABLES_LABEL"] = "消耗品"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "分解"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "選擇角色"
L["WINDOW_DISENCHANT_NONE"] = "你的每個角色使用 Play It Forward 登入後就會出現在這裡。"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s及以下"

L["BUTTON_FIND_RECIPIENTS"] = "尋找收件者"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "搜尋中..."
L["BUTTON_DISTRIBUTE"] = "分發"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "需要開啟信箱"
--[[
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "寄送中..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] = "%d 秒後再次搜尋。等按鈕顯示為尋找收件者時再試。"
L["WHO_BLOCKED"] =
	"請再按一次尋找收件者。暴雪只允許直接透過點擊按鈕發起這種搜尋，而這次被打斷了。"

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "顯示你背包裡可以贈送的物品。"

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "沒有可贈送的物品了。"
L["WINDOW_EMPTY_HINT"] = "變更上方的設定以列出更多。"

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "按下尋找收件者，為 %d 件物品尋找玩家。"
L["STATUS_MORE"] = "還預計進行 %d 次搜尋。按下尋找收件者繼續尋找。"
L["STATUS_DONE"] = "搜尋完畢。仍有 %d 件物品在範圍內無人可收。請稍後再試。"
L["STATUS_READY"] = "按下分發以寄出 %d 件物品。"
L["STATUS_AWAY"] = "開啟信箱以寄出 %d 件物品。"
L["STATUS_SENDING"] = "正在寄出第 %d 件，共 %d 件。請在每個彈出視窗中點擊接受。"

L["SECTION_MATCHED"] = "已配對"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "等待配對"
L["SECTION_UNREADABLE"] = "無法讀取屬性"

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
L["WINDOW_KEPT"] = "保留"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "無收件者"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "屬性讀取失敗"

L["PICKER_KEEP_OPTION"] = "保留物品"
L["PICKER_NONE_IN_RANGE"] = "等級範圍內沒有人。請按尋找收件者。"
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(已有)"
L["PICKER_NOTE_REFUSED"] = "(已拒絕)"
L["PICKER_NOTE_RECENT"] = "(最近)"
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"已在另一列中。以你的選擇為準，不是你親自設定的那一列會另找他人。"
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"本次登入期間寄給對方的郵件曾被退回。你仍可以再試一次。"
L["PICKER_NOTE_RECENT_DESCRIPTION"] = "本次登入期間已經收過你的禮物。對方升級後會再次優先。"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "為此物品尋找收件者"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "你的分身"
L["PICKER_SECTION_GUILD"] = "你的公會"
L["PICKER_SECTION_STRANGERS"] = "陌生人"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "分解"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "收件者"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d 名候選人，等級 %d-%d。"
L["TOOLTIP_RECIPIENT_HINT"] = "點擊以重新指派。"
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "最適合%s。"
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "無法讀取此物品的屬性，因此不進行配對。"
L["TOOLTIP_RECIPIENT_KEPT"] = "沒有職業需要它，所以它會留在你的背包裡。"
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "沒有人能使用它，所以會寄給 %s 分解。"

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "按下分發時寄出。取消勾選即可保留。"
L["TOOLTIP_CHECK_WAITING"] = "搜尋一找到人就會配對。取消勾選即可保留。"
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "從清單中選擇一個人來寄出此物品。"
L["TOOLTIP_CHECK_UNREADABLE"] = "在能讀取其屬性之前，此物品無法寄出。"

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
L["MAIL_STILL_SENDING"] = "仍在寄送。請稍等一下。"
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "沒有可分發的物品。"
L["MAIL_DISTRIBUTING"] = "在每個確認視窗中點擊接受，以寄出 %d 件物品。"
L["MAIL_ITEM_MOVED"] = "請按尋找收件者重新掃描。%s 在你的背包中被移動了。"
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "請為 %s 另選他人。%s 已經會收到一件。"
L["MAIL_NOT_AT_MAILBOX"] = "回到信箱並按下分發以寄出剩餘物品。"
L["MAIL_MAILBOX_CLOSED"] = "開啟信箱並按下分發以寄出剩餘物品。信箱在途中關閉了。"
L["MAIL_NO_POSTAGE"] = "放入一點銅幣作為郵資，然後按下分發以寄出剩餘物品。"
L["MAIL_PANEL_CLOSED"] =
	"開啟暴雪的寄送郵件面板，然後再按一次分發。沒有寄出或變動任何東西。"
L["MAIL_PANEL_CLOSED_HINT"] =
	"如果你使用 TSM，請為此切換到暴雪的寄送郵件面板。TSM 的信箱不接受附件。"
L["MAIL_ATTACH_FAILED"] = "無法附加 %s，因此未寄出。"
L["MAIL_AWAITING_CONFIRM"] = "在 %s 的確認視窗中點擊接受，然後按下分發以寄出剩餘物品。"
L["MAIL_SENT"] = "已將 %s 寄給 %s (%d/%d)。"
L["MAIL_SEND_FAILED"] = "寄給 %s 的郵件失敗 (%s)。"
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "未提供原因"
L["MAIL_REASON_ERROR"] = "用戶端錯誤"
L["MAIL_ABORTED"] = "郵件多次出錯，已停止分發。"
L["MAIL_DONE"] = "完成。已寄出 %d/%d。"
L["MAIL_DONE_WITH_SKIPS"] = "完成。已寄出 %d/%d，略過 %d (在背包中被移動)。"

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
	"把你用不到的裝綁裝備、食物、藥水、卷軸、油和磨石，郵寄給你的分身、公會成員和正在練功的玩家。每件物品都會送給最適合它的職業，把背包裡的雜物變成別人的下一次升級。傳遞善意，一次一件綠裝。"
L["OPTIONS_WELCOME"] = "啟用歡迎訊息"
L["OPTIONS_WELCOME_DESCRIPTION"] = "登入時顯示版本和設定提醒。"

L["OPTIONS_FEATURES_HEADER"] = "功能"

L["OPTIONS_COMMANDS_HEADER"] = "/指令"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "開啟此插件的設定介面。"

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "贈送內容"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"選擇要贈送給其他玩家的物品。你也可以隨時在分發視窗頂端變更裝備和消耗品。"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"提供的最高品質。高於此品質的物品永遠不會列出，因此好東西不會被誤寄出去。"
L["OPTIONS_DISTRIBUTE_GEAR"] = "分發裝備"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "提供裝備後綁定的武器和護甲。"
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "分發消耗品"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"提供你已用不到的低等級食物、飲料、藥水、卷軸、武器油和磨石。"
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "超出 %d+ 級"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "所有消耗品"
L["OPTIONS_CONSUMABLE_GAP"] = "等級規則"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"你需要比消耗品高出多少級，它才算作多餘。設為 20 或以上時，35 級的水會在你達到 55 級時提供。所有消耗品會提供背包裡的每一件，無論你的等級為何。"

--[[
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "食物"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"提供你已用不到的食物。同時恢復法力的食物會在食物或飲料開啟時提供。"
L["OPTIONS_KIND_DRINK"] = "飲料"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "提供你已用不到的水、果汁和其他飲料。"
L["OPTIONS_KIND_POTIONS"] = "藥水"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "提供你已用不到的治療、法力和恢復藥水。"
L["OPTIONS_KIND_SCROLLS"] = "卷軸"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"提供你已用不到的屬性卷軸。每張都會給使用該屬性的職業。"
L["OPTIONS_KIND_OILS_STONES"] = "油和磨石"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"提供你已用不到的武器油、磨刀石和平衡石。巫師之油給施法者，法力之油給使用法力的職業，磨刀石、平衡石和其他武器油給近戰職業。"

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "分解未配對物品"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"無人配對的裝備可以寄給你自己的某個角色進行分解，而不是留在你的背包裡。開啟此功能，然後選擇由哪個角色接收。每個伺服器和陣營會分別保存各自的選擇。"
L["OPTIONS_DISENCHANT_SEND"] = "將未配對物品寄給附魔師"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"無人能用的裝備會寄給你的某個角色進行分解，而不是留在你的背包裡。消耗品永遠不會被寄出。"
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"你的附魔師。列出你在此伺服器及其連結伺服器上、同一陣營的角色，每個角色需先使用 Play It Forward 登入過。"

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "收件者"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"你的裝備寄給誰，以及按什麼順序。在下方的我的分身和我的公會頁面中，選擇哪些角色和公會計入其中。"

L["OPTIONS_PRIORITY_HEADER"] = "誰優先"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"對於同樣適合陌生人的物品，你自己的角色和公會成員可以排到隊伍最前面。取消勾選任一項，他們就會和其他人一樣依等級和所在位置競爭。"
L["OPTIONS_PRIORITIZE_ALTS"] = "我的分身優先於陌生人和我的公會"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"對於同樣適合其他人的物品，你自己的角色可以優先挑選。取消勾選後，他們會和其他人一樣依等級和所在位置競爭。"
L["OPTIONS_PRIORITIZE_GUILDS"] = "我的公會優先於陌生人"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"對於同樣適合的物品，你的公會成員可以先於陌生人挑選。取消勾選後，他們會和陌生人一樣依等級和所在位置競爭。"

L["OPTIONS_STRANGERS_HEADER"] = "搜尋陌生人時"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"如何比較透過 /who 找到的玩家。在同樣合適的人選中，裝備會優先給最有可能正在練功、而且會用上它的人。"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "優先等級適合區域中的陌生人"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"優先把裝備提供給在適合其等級的區域中解任務的玩家，排在城市中的玩家之前。這些解任務的玩家最有可能感激你的好意。"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "優先不在副本中的陌生人"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"只有在野外沒有合適人選時，才把裝備提供給地城或團隊副本中的玩家。地城中的玩家可能是正在被別人帶著升級的角色，不會長期需要這些裝備。"
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "忽略 %d-%d 級的術士"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"永遠不把裝備提供給此等級範圍內身為術士的陌生人。術士在 20 級學會召喚，許多玩家會把術士分身停在這個等級專門用來召喚朋友，所以寄給他們的裝備往往用不到。你自己的角色和公會成員不受影響。"

L["OPTIONS_SPECS_HEADER"] = "職業和專精"
L["OPTIONS_SPECS_INTRO"] =
	"沒有人能看到其他玩家的專精，所以裝備會依以下假設寄出。你自己的角色使用我的分身中設定的專精。"
L["OPTIONS_SPECS_RESET"] = "恢復預設"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "將所有專精恢復為插件的預設設定。"
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "法術傷害"
L["ROLE_MELEE"] = "近戰傷害"
L["ROLE_RANGED"] = "遠程傷害"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "武器"
L["SPEC_Fury"] = "狂怒"
L["SPEC_Protection"] = "防護"
L["SPEC_Holy"] = "神聖"
L["SPEC_Retribution"] = "懲戒"
L["SPEC_BeastMastery"] = "野獸控制"
L["SPEC_Marksmanship"] = "射擊"
L["SPEC_Survival"] = "生存"
L["SPEC_Assassination"] = "刺殺"
L["SPEC_Combat"] = "戰鬥"
L["SPEC_Subtlety"] = "敏銳"
L["SPEC_Discipline"] = "戒律"
L["SPEC_Shadow"] = "暗影"
L["SPEC_Elemental"] = "元素"
L["SPEC_Enhancement"] = "增強"
L["SPEC_Restoration"] = "恢復"
L["SPEC_Arcane"] = "秘法"
L["SPEC_Fire"] = "火焰"
L["SPEC_Frost"] = "冰霜"
L["SPEC_Affliction"] = "痛苦"
L["SPEC_Demonology"] = "惡魔學識"
L["SPEC_Destruction"] = "毀滅"
L["SPEC_Balance"] = "平衡"
L["SPEC_Feral"] = "野性"
L["SPEC_Guardian"] = "守護者"
L["SPEC_Blood"] = "血魄"
L["SPEC_Unholy"] = "穢邪"
L["SPEC_Brewmaster"] = "釀酒"
L["SPEC_Mistweaver"] = "織霧"
L["SPEC_Windwalker"] = "御風"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "防護"
L["SPEC_DRUID_Restoration"] = "恢復"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "坦克 (符文)"
L["SPEC_Healer"] = "治療者 (符文)"
L["SPEC_Melee"] = "近戰 (符文)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "我的分身"
L["OPTIONS_ALTS_INTRO"] =
	"你自己的角色，每個角色使用 Play It Forward 登入後就會加入。在左側選擇一個角色，設定它是否接收郵件，以及為哪些專精寄送裝備。"
L["OPTIONS_SEND_TO_ALTS"] = "寄給分身"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"優先寄給你自己的角色，排在你的公會和陌生人之前，但只寄其職業最適合的物品。角色需要在此伺服器或其連結伺服器上、以同一陣營使用 Play It Forward 登入過才會計入。寄給分身的郵件不計入你的慷慨徽章統計。"
L["OPTIONS_ALTS_EMPTY"] = "還沒有角色。你的每個角色使用 Play It Forward 登入後就會出現在這裡。"
L["OPTIONS_ALT_INCLUDE"] = "包含此角色"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"向此角色寄送裝備。取消勾選後，它永遠不會收到任何物品。已滿等的角色預設不勾選。"
L["OPTIONS_ALT_SPECS"] = "為以下專精寄送裝備"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"為此角色提供此專精的裝備。預設勾選該角色上次使用的專精；尚無專精時則勾選所有專精。"
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "裝備等級"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "最低"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"寄給此角色的裝備的最低等級。角色等級不會寄送低於其等級的裝備；角色等級 -2 還會寄送最多低兩級、它現在就能穿的裝備。"
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "最高"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"寄給此角色的裝備的最高等級。所有可用裝備會寄送它日後能用上的一切，所以 1 級獵人也能收到 50 級的弓。"
L["OPTIONS_ALT_LEVEL_THEIRS"] = "角色等級"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "角色等級 -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "角色等級 +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "所有可用裝備"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "寄送 %d 到 %d 級的裝備。"
L["OPTIONS_ALT_LEVELS_FROM"] = "寄送 %d 級及以上的裝備。"
L["OPTIONS_DELETE"] = "刪除"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "忘記 %s？它下次登入時會重新加入。"
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "忘記此角色。它下次登入時會重新加入。"

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "我的公會"
L["OPTIONS_GUILDS_INTRO"] =
	"你的角色所在的每個公會，會在其中任一角色登入時保存，這樣無論你在玩哪個角色，都能給正在練功的公會成員寄送物品。"
L["OPTIONS_GUILD_OFFLINE"] = "忽略離線公會成員"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"略過超過此時長未登入的公會成員，包括你目前所在的公會和已保存的公會。選擇從不則包含所有人，無論他們離開了多久。"
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "超過 1 週"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "超過 2 週"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "從不"
L["OPTIONS_GUILDS_EMPTY"] =
	"還沒有公會。當你在某個公會中的角色登入後，該公會就會出現在這裡。"
L["OPTIONS_GUILD_INCLUDE"] = "寄送給此公會的成員"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "向此公會的成員寄送裝備。"
L["OPTIONS_GUILD_MEMBERS"] = "活躍成員"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "此名單中沒有最近活躍到足以接收物品的成員。"
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "包含"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"向此公會成員寄送裝備。如果是公會銀行或專業分身，取消勾選即可，他們將永遠不會收到任何物品。"
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d 名活躍成員，%s由 %s 保存。"
L["OPTIONS_GUILD_SAVED_TODAY"] = "今天"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "昨天"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d 天前"
L["OPTIONS_GUILD_CURRENT"] = "你目前的公會，在信箱處即時讀取。"
L["OPTIONS_GUILD_SKIPPED_REALM"] = "位於其他伺服器，因此無法從這裡寄送郵件。"
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "屬於另一陣營，因此無法從這裡寄送郵件。"

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "郵件留言文字"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"隨每份禮物寄出的留言。在左側撰寫你自己的留言，右側會顯示實際寄出的內容。輸入時自動儲存；清空輸入框即可恢復預設文字。"
L["OPTIONS_MAIL_SUBJECT"] = "主旨"
L["OPTIONS_MAIL_BODY"] = "內文"
L["OPTIONS_MAIL_YOURS"] = "你的留言"
L["OPTIONS_MAIL_PREVIEW"] = "對方收到的內容"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "主旨 %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "內文 %d/%d"
L["OPTIONS_MAIL_RESET"] = "恢復預設"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "恢復為預設的主旨與內文。"

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "慷慨徽章"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"你帳號中所有角色的贈送統計。在城市和旅店中，它們會顯示在你的玩家滑鼠提示上，其他 Play It Forward 使用者將滑鼠移到你身上時就能看到，你也能看到他們的。在地城、團隊副本和野外則會隱藏。"

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "慷慨徽章"
L["OPTIONS_GENEROSITY_GIFTS"] = "禮物"
L["OPTIONS_GENEROSITY_ITEMS"] = "物品"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "物品等級"
L["OPTIONS_GENEROSITY_VALUE"] = "金幣價值"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "啟用慷慨徽章玩家滑鼠提示"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"在城市和旅店中，你附近的玩家可以在你的滑鼠提示中看到你的統計。關閉後將停止分享，但你仍能看到他們的統計，而你自己的統計無論如何都會繼續累計。"

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "幫助 Play It Forward 升級"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"這個插件由熱愛這款遊戲、希望讓每個人都盡可能玩得開心的玩家打造。我們永遠不會請求捐款。真正的滿足感來自知道我們的成果讓你的遊戲變得更好一點。如果確實如此，我們很樂意聽你分享！"
L["OPTIONS_LEVEL_UP_WAYS"] = "以下是幾種幫助我們接觸更多玩家的方式。"
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• 分享回饋：發現了錯誤或有什麼想法？請在 Discord 上告訴我們。你的回饋能幫助我們改進插件，也隨時歡迎提交拉取請求。"
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• 告訴朋友：認識可能會喜歡這個插件的人嗎？告訴他們吧。口碑能幫助更多玩家發現優秀的插件。"
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• 在 CurseForge 上收藏：開啟下方的 CurseForge 連結，登入後點擊 Download 按鈕下方的星號。收藏能幫助更多玩家發現這個插件。"
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• 在 GitHub 上給 Star：開啟下方的 GitHub 連結，登入後點擊右上角的 Star。Star 能幫助專案獲得更多免費的開發者工具。"
L["OPTIONS_LEVEL_UP_THANKS"] = "感謝選擇 Play It Forward！"

L["OPTIONS_FEEDBACK"] = "回饋與支援"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "回饋與支援連結"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "要複製連結，請點擊其輸入框，然後按 Ctrl+A 和 Ctrl+C。"
L["OPTIONS_VERSION"] = "版本 %s"
