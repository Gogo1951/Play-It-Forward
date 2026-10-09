local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "zhCN")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"版本 %s。设置（包括关闭此消息的选项）位于 选项 > 插件 > Play It Forward。喜欢这个插件吗？告诉朋友吧！(="
L["CHAT_OPTIONS_IN_COMBAT"] = "出于安全考虑，战斗中无法打开设置界面。"

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "装备"
L["WINDOW_CONSUMABLES_LABEL"] = "消耗品"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s及以下"

L["BUTTON_FIND_RECIPIENTS"] = "寻找收件人"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "搜索中..."
L["BUTTON_DISTRIBUTE"] = "分发"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "需要打开邮箱"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"请再次点击寻找收件人。暴雪只允许直接通过点击按钮发起这种搜索，而这次被打断了。"

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "没有可赠送的物品了。"
L["WINDOW_EMPTY_HINT"] = "更改上方的装备或消耗品以列出更多。"

L["SECTION_MATCHED"] = "已匹配"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "等待匹配"
L["SECTION_UNREADABLE"] = "无法读取属性"

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
L["ROW_NO_RECIPIENT"] = "无收件人"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "属性读取失败"

L["PICKER_KEEP_OPTION"] = "保留物品"
L["PICKER_NONE_IN_RANGE"] = "等级范围内没有人。请点击寻找收件人。"
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(已有)"
L["PICKER_NOTE_REFUSED"] = "(已拒绝)"
L["PICKER_NOTE_RECENT"] = "(最近)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "为此物品寻找收件人"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "收件人"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d 名候选人，等级 %d-%d。"
L["TOOLTIP_RECIPIENT_HINT"] = "点击重新分配。"
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "无法读取此物品的属性，因此不进行匹配。"
L["TOOLTIP_RECIPIENT_KEPT"] = "没有职业需要它，所以它会留在你的背包里。"

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "点击分发时寄出。取消勾选即可保留。"
L["TOOLTIP_CHECK_WAITING"] = "搜索一找到人就会匹配。取消勾选即可保留。"

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
L["MAIL_STILL_SENDING"] = "仍在发送，请稍候。"
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "没有可分发的物品。"
L["MAIL_DISTRIBUTING"] = "在每个确认窗口中点击接受，以寄出 %d 件物品。"
L["MAIL_ITEM_MOVED"] = "请点击寻找收件人重新扫描。%s 在你的背包中被移动了。"
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "请为 %s 另选他人。%s 已经会收到一件。"
L["MAIL_NOT_AT_MAILBOX"] = "回到邮箱并点击分发以寄出剩余物品。"
L["MAIL_MAILBOX_CLOSED"] = "打开邮箱并点击分发以寄出剩余物品。邮箱在中途关闭了。"
L["MAIL_NO_POSTAGE"] = "放入一点铜币作为邮费，然后点击分发以寄出剩余物品。"
L["MAIL_PANEL_CLOSED"] =
	"打开暴雪的发送邮件面板，然后再次点击分发。没有寄出或改动任何东西。"
L["MAIL_PANEL_CLOSED_HINT"] =
	"如果你使用 TSM，请为此切换到默认邮件界面。TSM 的邮箱不接受附件。"
L["MAIL_ATTACH_FAILED"] = "无法附加 %s，因此未寄出。"
L["MAIL_AWAITING_CONFIRM"] = "在 %s 的确认窗口中点击接受，然后点击分发以寄出剩余物品。"
L["MAIL_SENT"] = "已将 %s 寄给 %s (%d/%d)。"
L["MAIL_SEND_FAILED"] = "寄给 %s 的邮件失败 (%s)。"
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "未给出原因"
L["MAIL_REASON_ERROR"] = "客户端错误"
L["MAIL_ABORTED"] = "邮件多次出错，已停止分发。"
L["MAIL_DONE"] = "完成。已寄出 %d/%d。"
L["MAIL_DONE_WITH_SKIPS"] = "完成。已寄出 %d/%d，跳过 %d (在背包中被移动)。"
L["MAIL_SUBJECT_TOO_LONG"] = "主题有 %d 个字符，而邮件只接受 %d 个，因此会被截断。"
L["MAIL_BODY_TOO_LONG"] = "正文有 %d 个字符，而邮件只接受 %d 个，因此会被截断。"

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
	"把你用不上的装备和消耗品送给会珍惜它们的公会成员或陌生人。每件物品都会匹配给最适合它的职业，把背包里被遗忘的杂物变成别人的下一次升级。传递善意，一次一件绿装。"
L["OPTIONS_WELCOME"] = "启用欢迎消息"
L["OPTIONS_WELCOME_DESCRIPTION"] = "登录时显示版本和设置提示。"

L["OPTIONS_COMMANDS_HEADER"] = "/命令"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "打开此插件的设置界面。"

L["OPTIONS_GIVE_HEADER"] = "赠送内容"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"提供的最高品质。高于此品质的物品永远不会列出，因此好东西不会被误寄出去。"
L["OPTIONS_INCLUDE_GEAR"] = "包括装备"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "提供装备后绑定的武器和护甲。"
L["OPTIONS_INCLUDE_CONSUMABLES"] = "包括消耗品"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] = "提供你已用不上的低级食物、饮料、药水和卷轴。"
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "超出 %d+ 级"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "所有消耗品"
L["OPTIONS_CONSUMABLE_GAP"] = "等级规则"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"你需要比消耗品高出多少级，它才算作多余。设为 20 或以上时，35 级的水会在你达到 55 级时提供。所有消耗品会提供背包里的每一件，无论你的等级如何。"

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "食物"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"提供你已用不上的食物。同时恢复法力的食物会在食物或饮料开启时提供。"
L["OPTIONS_KIND_DRINK"] = "饮料"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "提供你已用不上的水、果汁和其他饮料。"
L["OPTIONS_KIND_POTIONS"] = "药水"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] = "提供你已用不上的治疗、法力和恢复药水。"
L["OPTIONS_KIND_SCROLLS"] = "卷轴"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"提供你已用不上的属性卷轴。每张都会给使用该属性的职业。"

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "慷慨"
L["OPTIONS_GENEROSITY_GIFTS"] = "礼物"
L["OPTIONS_GENEROSITY_ITEMS"] = "物品"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "物品等级"
L["OPTIONS_GENEROSITY_VALUE"] = "金币价值"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "启用慷慨提示"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"在城市和旅店中，你附近的玩家可以在你的鼠标提示中看到你的统计。关闭后将停止分享，但你仍能看到他们的统计，而你下方的统计无论如何都会继续累计。"

L["OPTIONS_FEEDBACK_HEADER"] = "反馈与支持"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "版本 %s"
