local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "zhCN")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "分发窗口"
L["CHAT_LOADED"] =
	"版本 %s。设置（包括关闭此消息的选项）位于 选项 > 插件 > Play It Forward。喜欢这个插件吗？告诉朋友，在 CurseForge 上收藏它，或在 GitHub 上给它点个 Star。(="
L["CHAT_OPTIONS_IN_COMBAT"] = "出于安全考虑，战斗中无法打开设置界面。"

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "装备"
L["WINDOW_CONSUMABLES_LABEL"] = "消耗品"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "分解"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "选择角色"
L["WINDOW_DISENCHANT_NONE"] = "你的每个角色使用 Play It Forward 登录后就会出现在这里。"

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
L["WHO_WAIT"] = "%d 秒后再次搜索。等按钮显示为寻找收件人时再试。"
L["WHO_BLOCKED"] =
	"请再次点击寻找收件人。暴雪只允许直接通过点击按钮发起这种搜索，而这次被打断了。"

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "显示你背包里可以赠送的物品。"

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "没有可赠送的物品了。"
L["WINDOW_EMPTY_HINT"] = "更改上方的设置以列出更多。"

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "点击寻找收件人，为 %d 件物品寻找玩家。"
L["STATUS_MORE"] = "还计划进行 %d 次搜索。点击寻找收件人继续寻找。"
L["STATUS_DONE"] = "搜索完毕。仍有 %d 件物品在范围内无人可收。请稍后再试。"
L["STATUS_READY"] = "点击分发以寄出 %d 件物品。"
L["STATUS_AWAY"] = "打开邮箱以寄出 %d 件物品。"
L["STATUS_SENDING"] = "正在寄出第 %d 件，共 %d 件。请在每个弹窗中点击接受。"

L["SECTION_MATCHED"] = "已匹配"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "等待匹配"
L["SECTION_UNREADABLE"] = "无法读取属性"

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
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"已在另一行中。以你的选择为准，不是你亲自设置的那一行会另找他人。"
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"本次登录期间寄给对方的邮件曾被退回。你仍可以再试一次。"
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"本次登录期间已经收到过你的礼物。对方升级后会再次优先。"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "为此物品寻找收件人"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "你的小号"
L["PICKER_SECTION_GUILD"] = "你的公会"
L["PICKER_SECTION_STRANGERS"] = "陌生人"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "分解"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "收件人"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "%d 名候选人，等级 %d-%d。"
L["TOOLTIP_RECIPIENT_HINT"] = "点击重新分配。"
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "最适合%s。"
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "无法读取此物品的属性，因此不进行匹配。"
L["TOOLTIP_RECIPIENT_KEPT"] = "没有职业需要它，所以它会留在你的背包里。"
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "没有人能使用它，所以会寄给 %s 分解。"

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "点击分发时寄出。取消勾选即可保留。"
L["TOOLTIP_CHECK_WAITING"] = "搜索一找到人就会匹配。取消勾选即可保留。"
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "从列表中选择一个人来寄出此物品。"
L["TOOLTIP_CHECK_UNREADABLE"] = "在能读取其属性之前，此物品无法寄出。"

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
L["MAIL_STILL_SENDING"] = "仍在发送。请稍等片刻。"
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
	"如果你使用 TSM，请为此切换到暴雪的发送邮件面板。TSM 的邮箱不接受附件。"
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
	"把你用不上的装绑装备、食物、药水、卷轴、油和磨石，邮寄给你的小号、公会成员和正在练级的玩家。每件物品都会送给最适合它的职业，把背包里的杂物变成别人的下一次升级。传递善意，一次一件绿装。"
L["OPTIONS_WELCOME"] = "启用欢迎消息"
L["OPTIONS_WELCOME_DESCRIPTION"] = "登录时显示版本和设置提示。"

L["OPTIONS_FEATURES_HEADER"] = "功能"

L["OPTIONS_COMMANDS_HEADER"] = "/命令"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "打开此插件的设置界面。"

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "赠送内容"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"选择要赠送给其他玩家的物品。你也可以随时在分发窗口顶部更改装备和消耗品。"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"提供的最高品质。高于此品质的物品永远不会列出，因此好东西不会被误寄出去。"
L["OPTIONS_DISTRIBUTE_GEAR"] = "分发装备"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "提供装备后绑定的武器和护甲。"
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "分发消耗品"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"提供你已用不上的低级食物、饮料、药水、卷轴、武器油和磨石。"
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "油和磨石"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"提供你已用不上的武器油、磨刀石和平衡石。巫师之油给施法者，法力之油给使用法力的职业，磨刀石、平衡石和其他武器油给近战职业。"

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "分解未匹配物品"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"无人匹配的装备可以寄给你自己的某个角色进行分解，而不是留在你的背包里。开启此功能，然后选择由哪个角色接收。每个服务器和阵营会分别保存各自的选择。"
L["OPTIONS_DISENCHANT_SEND"] = "将未匹配物品寄给附魔师"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"无人能用的装备会寄给你的某个角色进行分解，而不是留在你的背包里。消耗品永远不会被寄出。"
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"你的附魔师。列出你在此服务器及其互通服务器上、同一阵营的角色，每个角色需先使用 Play It Forward 登录过。"

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "收件人"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"你的装备寄给谁，以及按什么顺序。在下方的我的小号和我的公会页面中，选择哪些角色和公会计入其中。"

L["OPTIONS_PRIORITY_HEADER"] = "谁优先"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"对于同样适合陌生人的物品，你自己的角色和公会成员可以排到队伍最前面。取消勾选任意一项，他们就会和其他人一样按等级和所在位置竞争。"
L["OPTIONS_PRIORITIZE_ALTS"] = "我的小号优先于陌生人和我的公会"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"对于同样适合其他人的物品，你自己的角色可以优先挑选。取消勾选后，他们会和其他人一样按等级和所在位置竞争。"
L["OPTIONS_PRIORITIZE_GUILDS"] = "我的公会优先于陌生人"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"对于同样适合的物品，你的公会成员可以先于陌生人挑选。取消勾选后，他们会和陌生人一样按等级和所在位置竞争。"

L["OPTIONS_STRANGERS_HEADER"] = "搜索陌生人时"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"如何比较通过 /who 找到的玩家。在同样合适的人选中，装备会优先给最有可能正在练级、并且会用上它的人。"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "优先等级适宜区域中的陌生人"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"优先把装备提供给在适合其等级的区域中做任务的玩家，排在城市中的玩家之前。这些做任务的玩家最有可能感激你的好意。"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "优先不在副本中的陌生人"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"只有在野外没有合适人选时，才把装备提供给地下城或团队副本中的玩家。地下城中的玩家可能是正在被别人带着升级的角色，不会长期需要这些装备。"
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "忽略 %d-%d 级的术士"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"永远不把装备提供给此等级范围内身为术士的陌生人。术士在 20 级学会召唤，许多玩家会把术士小号停在这个等级专门用来召唤朋友，所以寄给他们的装备往往用不上。你自己的角色和公会成员不受影响。"

L["OPTIONS_SPECS_HEADER"] = "职业和专精"
L["OPTIONS_SPECS_INTRO"] =
	"没有人能看到其他玩家的专精，所以装备会按以下假设寄出。你自己的角色使用我的小号中设置的专精。"
L["OPTIONS_SPECS_RESET"] = "恢复默认"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "将所有专精恢复为插件的默认设置。"
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "法术伤害"
L["ROLE_MELEE"] = "近战伤害"
L["ROLE_RANGED"] = "远程伤害"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "武器"
L["SPEC_Fury"] = "狂怒"
L["SPEC_Protection"] = "防护"
L["SPEC_Holy"] = "神圣"
L["SPEC_Retribution"] = "惩戒"
L["SPEC_BeastMastery"] = "野兽控制"
L["SPEC_Marksmanship"] = "射击"
L["SPEC_Survival"] = "生存"
L["SPEC_Assassination"] = "刺杀"
L["SPEC_Combat"] = "战斗"
L["SPEC_Subtlety"] = "敏锐"
L["SPEC_Discipline"] = "戒律"
L["SPEC_Shadow"] = "暗影"
L["SPEC_Elemental"] = "元素"
L["SPEC_Enhancement"] = "增强"
L["SPEC_Restoration"] = "恢复"
L["SPEC_Arcane"] = "奥术"
L["SPEC_Fire"] = "火焰"
L["SPEC_Frost"] = "冰霜"
L["SPEC_Affliction"] = "痛苦"
L["SPEC_Demonology"] = "恶魔学识"
L["SPEC_Destruction"] = "毁灭"
L["SPEC_Balance"] = "平衡"
L["SPEC_Feral"] = "野性"
L["SPEC_Guardian"] = "守护"
L["SPEC_Blood"] = "鲜血"
L["SPEC_Unholy"] = "邪恶"
L["SPEC_Brewmaster"] = "酒仙"
L["SPEC_Mistweaver"] = "织雾"
L["SPEC_Windwalker"] = "踏风"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "防护"
L["SPEC_DRUID_Restoration"] = "恢复"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "坦克 (符文)"
L["SPEC_Healer"] = "治疗者 (符文)"
L["SPEC_Melee"] = "近战 (符文)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "我的小号"
L["OPTIONS_ALTS_INTRO"] =
	"你自己的角色，每个角色使用 Play It Forward 登录后就会加入。在左侧选择一个角色，设置它是否接收邮件，以及为哪些专精寄送装备。"
L["OPTIONS_SEND_TO_ALTS"] = "寄给小号"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"优先寄给你自己的角色，排在你的公会和陌生人之前，但只寄其职业最适合的物品。角色需要在此服务器或其互通服务器上、以同一阵营使用 Play It Forward 登录过才会计入。寄给小号的邮件不计入你的慷慨徽章统计。"
L["OPTIONS_ALTS_EMPTY"] = "还没有角色。你的每个角色使用 Play It Forward 登录后就会出现在这里。"
L["OPTIONS_ALT_INCLUDE"] = "包括此角色"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"向此角色寄送装备。取消勾选后，它永远不会收到任何物品。已满级的角色默认不勾选。"
L["OPTIONS_ALT_SPECS"] = "为以下专精寄送装备"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"为此角色提供此专精的装备。默认勾选该角色上次使用的专精；尚无专精时则勾选所有专精。"
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "装备等级"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "最低"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"寄给此角色的装备的最低等级。角色等级不会寄送低于其等级的装备；角色等级 -2 还会寄送最多低两级、它现在就能穿的装备。"
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "最高"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"寄给此角色的装备的最高等级。所有可用装备会寄送它日后能用上的一切，所以 1 级猎人也能收到 50 级的弓。"
L["OPTIONS_ALT_LEVEL_THEIRS"] = "角色等级"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "角色等级 -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "角色等级 +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "所有可用装备"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "寄送 %d 到 %d 级的装备。"
L["OPTIONS_ALT_LEVELS_FROM"] = "寄送 %d 级及以上的装备。"
L["OPTIONS_DELETE"] = "删除"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] = "忘记 %s？它下次登录时会重新加入。"
L["OPTIONS_ALT_DELETE_DESCRIPTION"] = "忘记此角色。它下次登录时会重新加入。"

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "我的公会"
L["OPTIONS_GUILDS_INTRO"] =
	"你的角色所在的每个公会，会在其中任一角色登录时保存，这样无论你在玩哪个角色，都能给正在练级的公会成员寄送物品。"
L["OPTIONS_GUILD_OFFLINE"] = "忽略离线公会成员"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"跳过超过此时长未登录的公会成员，包括你当前所在的公会和已保存的公会。选择从不则包括所有人，无论他们离开了多久。"
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "超过 1 周"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "超过 2 周"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "从不"
L["OPTIONS_GUILDS_EMPTY"] =
	"还没有公会。当你在某个公会中的角色登录后，该公会就会出现在这里。"
L["OPTIONS_GUILD_INCLUDE"] = "给此公会的成员寄送"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "向此公会的成员寄送装备。"
L["OPTIONS_GUILD_MEMBERS"] = "活跃成员"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] = "此名单中没有最近活跃到足以接收物品的成员。"
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "包括"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"向此公会成员寄送装备。如果是公会银行或专业小号，取消勾选即可，他们将永远不会收到任何物品。"
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "%d 名活跃成员，%s由 %s 保存。"
L["OPTIONS_GUILD_SAVED_TODAY"] = "今天"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "昨天"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d 天前"
L["OPTIONS_GUILD_CURRENT"] = "你当前的公会，在邮箱处实时读取。"
L["OPTIONS_GUILD_SKIPPED_REALM"] = "位于其他服务器，因此无法从这里寄送邮件。"
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "属于另一阵营，因此无法从这里寄送邮件。"

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "邮件留言文本"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"随每份礼物寄出的留言。在左侧撰写你自己的留言，右侧会显示实际寄出的内容。输入时自动保存；清空输入框即可恢复默认文字。"
L["OPTIONS_MAIL_SUBJECT"] = "主题"
L["OPTIONS_MAIL_BODY"] = "正文"
L["OPTIONS_MAIL_YOURS"] = "你的留言"
L["OPTIONS_MAIL_PREVIEW"] = "对方收到的内容"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "主题 %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "正文 %d/%d"
L["OPTIONS_MAIL_RESET"] = "恢复默认"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "恢复为默认的主题和正文。"

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "慷慨徽章"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"你账号中所有角色的赠送统计。在城市和旅店中，它们会显示在你的玩家鼠标提示上，其他 Play It Forward 用户将鼠标悬停在你身上时就能看到，你也能看到他们的。在地下城、团队副本和野外则会隐藏。"

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "慷慨徽章"
L["OPTIONS_GENEROSITY_GIFTS"] = "礼物"
L["OPTIONS_GENEROSITY_ITEMS"] = "物品"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "物品等级"
L["OPTIONS_GENEROSITY_VALUE"] = "金币价值"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "启用慷慨徽章玩家鼠标提示"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"在城市和旅店中，你附近的玩家可以在你的鼠标提示中看到你的统计。关闭后将停止分享，但你仍能看到他们的统计，而你自己的统计无论如何都会继续累计。"

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "帮助 Play It Forward 升级"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"这个插件由热爱这款游戏、希望让每个人都尽可能玩得开心的玩家打造。我们永远不会请求捐赠。真正的满足感来自知道我们的工作让你的游戏变得更好一点。如果确实如此，我们很乐意听你说说！"
L["OPTIONS_LEVEL_UP_WAYS"] = "以下是几种帮助我们接触更多玩家的方式。"
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• 分享反馈：发现了错误或有什么想法？请在 Discord 上告诉我们。你的反馈能帮助我们改进插件，也随时欢迎提交拉取请求。"
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• 告诉朋友：认识可能会喜欢这个插件的人吗？告诉他们吧。口碑能帮助更多玩家发现优秀的插件。"
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• 在 CurseForge 上收藏：打开下方的 CurseForge 链接，登录后点击 Download 按钮下方的星标。收藏能帮助更多玩家发现这个插件。"
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• 在 GitHub 上点 Star：打开下方的 GitHub 链接，登录后点击右上角的 Star。Star 能帮助项目获得更多免费的开发者工具。"
L["OPTIONS_LEVEL_UP_THANKS"] = "感谢选择 Play It Forward！"

L["OPTIONS_FEEDBACK"] = "反馈与支持"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "反馈与支持链接"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "要复制链接，请点击其输入框，然后按 Ctrl+A 和 Ctrl+C。"
L["OPTIONS_VERSION"] = "版本 %s"
