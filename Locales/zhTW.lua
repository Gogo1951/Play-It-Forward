local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "zhTW")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"版本 %s。設定（包括關閉此訊息的選項）位於 選項 > 插件 > Play It Forward。喜歡這個插件嗎？告訴朋友吧！(="
L["CHAT_OPTIONS_IN_COMBAT"] = "基於安全考量，戰鬥中無法開啟設定介面。"

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "裝備"
L["WINDOW_CONSUMABLES_LABEL"] = "消耗品"

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
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"請再按一次尋找收件者。暴雪只允許直接透過點擊按鈕發起這種搜尋，而這次被打斷了。"

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "沒有可贈送的物品了。"
L["WINDOW_EMPTY_HINT"] = "變更上方的裝備或消耗品以列出更多。"

L["SECTION_MATCHED"] = "已配對"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "等待配對"
L["SECTION_UNREADABLE"] = "無法讀取屬性"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

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
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "為此物品尋找收件者"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "收件者"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d 名候選人，等級 %d-%d。"
L["TOOLTIP_RECIPIENT_HINT"] = "點擊以重新指派。"
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "無法讀取此物品的屬性，因此不進行配對。"
L["TOOLTIP_RECIPIENT_KEPT"] = "沒有職業需要它，所以它會留在你的背包裡。"

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "按下分發時寄出。取消勾選即可保留。"
L["TOOLTIP_CHECK_WAITING"] = "搜尋一找到人就會配對。取消勾選即可保留。"

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
L["MAIL_STILL_SENDING"] = "仍在寄送，請稍候。"
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
	"如果你使用 TSM，請為此切換到預設郵件介面。TSM 的信箱不接受附件。"
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
L["MAIL_SUBJECT_TOO_LONG"] = "主旨有 %d 個字元，而郵件只接受 %d 個，因此會被截斷。"
L["MAIL_BODY_TOO_LONG"] = "內文有 %d 個字元，而郵件只接受 %d 個，因此會被截斷。"

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
	"把你用不到的裝備和消耗品送給會珍惜它們的公會成員或陌生人。每件物品都會配對給最適合它的職業，把背包裡被遺忘的雜物變成別人的下一次升級。傳遞善意，一次一件綠裝。"
L["OPTIONS_WELCOME"] = "啟用歡迎訊息"
L["OPTIONS_WELCOME_DESCRIPTION"] = "登入時顯示版本和設定提醒。"

L["OPTIONS_COMMANDS_HEADER"] = "/指令"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "開啟此插件的設定介面。"

L["OPTIONS_GIVE_HEADER"] = "贈送內容"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"提供的最高品質。高於此品質的物品永遠不會列出，因此好東西不會被誤寄出去。"
L["OPTIONS_INCLUDE_GEAR"] = "包含裝備"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "提供裝備後綁定的武器和護甲。"
L["OPTIONS_INCLUDE_CONSUMABLES"] = "包含消耗品"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] = "提供你已用不到的低等級食物、飲料、藥水和卷軸。"
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
	One switch per kind, drawn under Include Consumables and again in the mail window from
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

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "慷慨"
L["OPTIONS_GENEROSITY_GIFTS"] = "禮物"
L["OPTIONS_GENEROSITY_ITEMS"] = "物品"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "物品等級"
L["OPTIONS_GENEROSITY_VALUE"] = "金幣價值"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "啟用慷慨提示"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"在城市和旅店中，你附近的玩家可以在你的滑鼠提示中看到你的統計。關閉後將停止分享，但你仍能看到他們的統計，而你下方的統計無論如何都會繼續累計。"

L["OPTIONS_FEEDBACK_HEADER"] = "回饋與支援"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "版本 %s"
