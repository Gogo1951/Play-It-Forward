local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "koKR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["CHAT_LOADED"] =
	"버전 %s. 설정(이 메시지를 끄는 옵션 포함)은 설정 > 애드온 > Play It Forward에서 찾을 수 있습니다. 애드온이 마음에 드시나요? 친구에게 알려 주세요! (="
L["CHAT_OPTIONS_IN_COMBAT"] = "안전을 위해 전투 중에는 설정 창을 열 수 없습니다."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's two top-bar ticks, the window's twins of Include Gear and Include
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips and the
	dropdown values are the panel's own strings, so a setting is never explained two ways.
]]
L["WINDOW_GEAR_LABEL"] = "장비"
L["WINDOW_CONSUMABLES_LABEL"] = "소모품"

--[[
	The gear cap's dropdown value: the game's own quality name, then this. The panel's select has
	no caption of its own, so each value states the cap it sets, that quality and everything
	beneath it.
]]
L["QUALITY_AND_LOWER"] = "%s 이하"

L["BUTTON_FIND_RECIPIENTS"] = "받을 사람 찾기"
-- On the button while the /who throttle is up; deliberately not a countdown.
L["BUTTON_SEARCHING"] = "검색 중..."
L["BUTTON_DISTRIBUTE"] = "나눠 주기"
-- On the Distribute button away from a mailbox: an ordinary state, not an error.
L["BUTTON_NEEDS_MAILBOX"] = "우편함을 열어야 함"

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
L["WHO_BLOCKED"] =
	"받을 사람 찾기를 다시 누르세요. Blizzard는 버튼을 직접 눌렀을 때만 이 검색을 허용하는데, 이번에는 무언가가 방해했습니다."

-- In the list while it is empty. The hint names the two top-bar captions: rename one, reread it.
L["WINDOW_EMPTY"] = "더 이상 나눠 줄 것이 없습니다."
L["WINDOW_EMPTY_HINT"] = "더 보려면 위의 장비 또는 소모품을 바꾸세요."

L["SECTION_MATCHED"] = "배정됨"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "배정 대기 중"
L["SECTION_UNREADABLE"] = "능력치를 읽을 수 없음"

--[[
	"Kept", never "vendor / disenchant": the add-on does not tell the player what to do with what
	stays. Covers the leftover rows: items no class wants, or that score too low to be worth sending.

	ONE KEY FOR TWO SURFACES, and the only section and row pair that shares one: the band and
	the row label read the same single word, so two keys could only drift apart. Every other
	section and row pair deliberately says something different on each -- "Pending Match" over
	a band of rows that each read "No Recipient".
]]
L["WINDOW_KEPT"] = "보관"

-- Row labels are Title Case, like the dropdown's own actions.
L["ROW_NO_RECIPIENT"] = "받을 사람 없음"
-- The section band's words, reordered as a row label, so one state is not named two ways.
L["ROW_UNREADABLE"] = "능력치 읽기 실패"

L["PICKER_KEEP_OPTION"] = "아이템 보관"
L["PICKER_NONE_IN_RANGE"] = "레벨 범위에 아무도 없습니다. 받을 사람 찾기를 누르세요."
--[[
	KEPT SHORT. A note shares one 18-pixel row with a cross-realm name, a level and a class, and
	anything longer is cut off. Notes are information, never gates: every name can be picked.
]]
L["PICKER_NOTE_HAS_ONE"] = "(보유 중)"
L["PICKER_NOTE_REFUSED"] = "(거절함)"
L["PICKER_NOTE_RECENT"] = "(최근)"
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "이 아이템의 받을 사람 찾기"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "받는 사람"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "후보 %d명, 레벨 %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "클릭하여 다시 지정합니다."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "이 아이템의 능력치를 읽을 수 없어 배정하지 않습니다."
L["TOOLTIP_RECIPIENT_KEPT"] = "원하는 직업이 없어 가방에 남겨 둡니다."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "나눠 주기를 누르면 보냅니다. 보관하려면 체크를 해제하세요."
L["TOOLTIP_CHECK_WAITING"] =
	"검색으로 누군가를 찾는 즉시 배정됩니다. 보관하려면 체크를 해제하세요."

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
L["MAIL_STILL_SENDING"] = "아직 보내는 중입니다. 잠시만 기다리세요."
L["MAIL_NOTHING_TO_DISTRIBUTE"] = "나눠 줄 것이 없습니다."
L["MAIL_DISTRIBUTING"] = "아이템 %d개를 보내려면 각 확인 창에서 수락을 클릭하세요."
L["MAIL_ITEM_MOVED"] =
	"다시 검사하려면 받을 사람 찾기를 누르세요. 가방에서 %s의 위치가 바뀌었습니다."
-- Named rather than dropped quietly: a silent skip looks like the row was never ticked.
L["MAIL_ALREADY_HAS_ONE"] = "%s: 다른 사람을 고르세요. %s 님이 이미 하나 받습니다."
L["MAIL_NOT_AT_MAILBOX"] = "나머지를 보내려면 우편함으로 돌아가 나눠 주기를 누르세요."
L["MAIL_MAILBOX_CLOSED"] =
	"나머지를 보내려면 우편함을 열고 나눠 주기를 누르세요. 도중에 우편함이 닫혔습니다."
L["MAIL_NO_POSTAGE"] =
	"우편 요금으로 구리를 조금 넣은 뒤 나눠 주기를 눌러 나머지를 보내세요."
L["MAIL_PANEL_CLOSED"] =
	"Blizzard 기본 우편 보내기 창을 열고 나눠 주기를 다시 누르세요. 아무것도 보내거나 건드리지 않았습니다."
L["MAIL_PANEL_CLOSED_HINT"] =
	"TSM을 사용한다면 이 작업에는 기본 우편 UI로 전환하세요. TSM 우편함은 첨부를 받지 않습니다."
L["MAIL_ATTACH_FAILED"] = "%s 첨부에 실패하여 보내지 않았습니다."
L["MAIL_AWAITING_CONFIRM"] =
	"%s 확인 창에서 수락을 클릭한 뒤 나눠 주기를 눌러 나머지를 보내세요."
L["MAIL_SENT"] = "%s 아이템을 %s 님에게 보냈습니다 (%d/%d)."
L["MAIL_SEND_FAILED"] = "%s 님에게 우편 보내기 실패 (%s)."
--[[
	The parenthetical above. On the UI_ERROR_MESSAGE path it is the client's own error text, already
	in the player's language; these two cover the paths where the reason is ours to name, so that
	slot never carries a bare English word the player cannot act on.
]]
L["MAIL_REASON_FAILED"] = "이유 없음"
L["MAIL_REASON_ERROR"] = "클라이언트 오류"
L["MAIL_ABORTED"] = "우편 오류가 반복되어 나눠 주기를 중단했습니다."
L["MAIL_DONE"] = "완료. %d/%d개 보냄."
L["MAIL_DONE_WITH_SKIPS"] = "완료. %d/%d개 보냄, %d개 건너뜀 (가방에서 옮겨짐)."
L["MAIL_SUBJECT_TOO_LONG"] = "제목이 %d자인데 우편은 %d자까지만 받으므로 잘립니다."
L["MAIL_BODY_TOO_LONG"] = "본문이 %d자인데 우편은 %d자까지만 받으므로 잘립니다."

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
	"더 이상 쓰지 않는 장비와 소모품을 고마워할 길드원이나 낯선 이에게 보내세요. 모든 아이템은 가장 잘 맞는 직업에 배정되어, 가방 속 잊힌 잡동사니가 누군가의 다음 업그레이드가 됩니다. 녹색 아이템 하나씩, 받은 만큼 베푸세요."
L["OPTIONS_WELCOME"] = "환영 메시지 사용"
L["OPTIONS_WELCOME_DESCRIPTION"] = "접속할 때 버전과 설정 안내를 표시합니다."

L["OPTIONS_COMMANDS_HEADER"] = "/명령어"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "이 애드온의 설정 창을 엽니다."

L["OPTIONS_GIVE_HEADER"] = "나눠 줄 것"
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"제공할 최고 희귀도입니다. 이보다 높은 것은 목록에 나오지 않으므로 좋은 전리품을 실수로 보낼 일이 없습니다."
L["OPTIONS_INCLUDE_GEAR"] = "장비 포함"
L["OPTIONS_INCLUDE_GEAR_DESCRIPTION"] = "착용 시 귀속되는 무기와 방어구를 제공합니다."
L["OPTIONS_INCLUDE_CONSUMABLES"] = "소모품 포함"
L["OPTIONS_INCLUDE_CONSUMABLES_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 저레벨 음식, 음료, 물약, 두루마리를 제공합니다."
--[[
	Self-describing: a bare "20" says nothing.
	"%d+" rather than ">%d" because the scan admits an item at exactly that many levels past it,
	which "more than 20" would say it does not. The zero stop lifts the rule instead of tightening
	it to nothing, so it gets its own words rather than "Outgrown by 0+ Levels".
]]
L["OPTIONS_CONSUMABLE_GAP_VALUE"] = "%d+레벨 지남"
L["OPTIONS_CONSUMABLE_GAP_ALL"] = "모든 소모품"
L["OPTIONS_CONSUMABLE_GAP"] = "레벨 규칙"
L["OPTIONS_CONSUMABLE_GAP_DESCRIPTION"] =
	"소모품을 여분으로 치기까지 그 레벨을 얼마나 넘어야 하는지 정합니다. 20 이상이면 35레벨 물은 55레벨에 도달할 때 제공됩니다. 모든 소모품은 레벨과 상관없이 가방의 모든 소모품을 제공합니다."

--[[
	One switch per kind, drawn under Include Consumables and again in the mail window from
	ns.CONSUMABLE_KIND_STRINGS, so both surfaces use these words. Concepts, not game names.
]]
L["OPTIONS_KIND_FOOD"] = "음식"
L["OPTIONS_KIND_FOOD_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 음식을 제공합니다. 마나도 회복하는 음식은 음식 또는 음료가 켜져 있으면 제공됩니다."
L["OPTIONS_KIND_DRINK"] = "음료"
L["OPTIONS_KIND_DRINK_DESCRIPTION"] = "레벨이 지나 쓰지 않는 물, 주스 등의 음료를 제공합니다."
L["OPTIONS_KIND_POTIONS"] = "물약"
L["OPTIONS_KIND_POTIONS_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 치유, 마나, 회복 물약을 제공합니다."
L["OPTIONS_KIND_SCROLLS"] = "두루마리"
L["OPTIONS_KIND_SCROLLS_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 능력치 두루마리를 제공합니다. 각각 그 능력치를 쓰는 직업에게 갑니다."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the add-on name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "베풂"
L["OPTIONS_GENEROSITY_GIFTS"] = "선물"
L["OPTIONS_GENEROSITY_ITEMS"] = "아이템"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "아이템 레벨"
L["OPTIONS_GENEROSITY_VALUE"] = "골드 가치"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "베풂 툴팁 사용"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"도시와 여관에서 근처 플레이어가 내 툴팁에서 합계를 볼 수 있습니다. 끄면 공유가 멈추지만 다른 사람의 합계는 계속 보이며, 아래의 내 합계는 어느 쪽이든 계속 집계됩니다."

L["OPTIONS_FEEDBACK_HEADER"] = "피드백 및 지원"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_VERSION"] = "버전 %s"
