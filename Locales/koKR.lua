local L = LibStub("AceLocale-3.0"):NewLocale("Play-It-Forward", "koKR")
if not L then
	return
end

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

L["ADDON_TITLE"] = "Play It Forward"
L["ADDON_SHORT_NAME"] = "Play It Forward"
-- The mail window's title, followed by " // " and ADDON_TITLE.
L["WINDOW_TITLE"] = "나눠 주기 창"
L["CHAT_LOADED"] =
	"버전 %s. 설정(이 메시지를 끄는 옵션 포함)은 설정 > 애드온 > Play It Forward에 있습니다. 이 애드온이 마음에 드시나요? 친구에게 알려 주시거나, CurseForge에서 즐겨찾기하거나, GitHub에서 Star를 눌러 주세요. (="
L["CHAT_OPTIONS_IN_COMBAT"] = "안전을 위해 전투 중에는 설정 창을 열 수 없습니다."

--------------------------------------------------------------------------------
-- Mail Window
--------------------------------------------------------------------------------

--[[
	Captions on the window's Gear and Consumables ticks, the twins of Distribute Gear and Distribute
	Consumables. Shorter than the panel's labels because the bar is narrow; the tooltips, the kind
	ticks and the dropdown values are the panel's own strings, so a setting is never explained two
	ways.
]]
L["WINDOW_GEAR_LABEL"] = "장비"
L["WINDOW_CONSUMABLES_LABEL"] = "소모품"
-- Under Gear: the twin of Disenchant Unmatched Items, with your enchanter's name beside it.
L["WINDOW_DISENCHANT_LABEL"] = "마력 추출"
-- In the enchanter dropdown while no character is picked, and in its list while none exists.
L["WINDOW_DISENCHANT_PICK"] = "캐릭터 선택"
L["WINDOW_DISENCHANT_NONE"] = "각 캐릭터는 Play It Forward를 사용해 접속하면 여기에 표시됩니다."

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
	On the Distribute button only while a run is going. It goes back to Distribute at every pause,
	because the chat lines that report a pause name Distribute.
]]
L["BUTTON_SENDING"] = "보내는 중..."

--[[
	The search behind Find Recipients, filed here with that button rather than under Distributing:
	nothing is being sent when it prints. SendWho only answers from a real button press, so a
	blocked call is explained instead of reading as a dead press.
]]
-- From Find Recipients for This Item, pressed while the last search is still out or throttled.
L["WHO_WAIT"] =
	"%d초 후 다시 검색합니다. 버튼에 받을 사람 찾기가 표시되면 다시 시도하세요."
L["WHO_BLOCKED"] =
	"받을 사람 찾기를 다시 누르세요. Blizzard는 버튼을 직접 눌렀을 때만 이 검색을 허용하는데, 이번에는 무언가가 방해했습니다."

-- On the button beside Blizzard's mail frame that brings the closed window back.
L["REOPEN_TOOLTIP"] = "가방에서 나눠 줄 수 있는 것을 보여 줍니다."

-- In the list while it is empty.
L["WINDOW_EMPTY"] = "더 이상 나눠 줄 것이 없습니다."
L["WINDOW_EMPTY_HINT"] = "더 보려면 위의 설정을 바꾸세요."

--[[
	The line above the two buttons: always the next step. One line 622 points wide, cut short
	rather than wrapped, so keep translations about this long.
]]
L["STATUS_START"] = "받을 사람 찾기를 눌러 아이템 %d개를 받을 플레이어를 찾으세요."
L["STATUS_MORE"] = "검색 %d회 더 예정. 받을 사람 찾기를 눌러 계속 찾으세요."
L["STATUS_DONE"] =
	"검색 완료. 아이템 %d개는 아직 받을 사람이 없습니다. 나중에 다시 시도하세요."
L["STATUS_READY"] = "나눠 주기를 눌러 아이템 %d개를 보내세요."
L["STATUS_AWAY"] = "아이템 %d개를 보내려면 우편함을 여세요."
L["STATUS_SENDING"] = "%d/%d 보내는 중. 각 확인 창에서 수락을 클릭하세요."

L["SECTION_MATCHED"] = "배정됨"
-- "Pending Match", not "no recipient in range": usually the search just has not got there yet.
L["SECTION_NO_RECIPIENT"] = "배정 대기 중"
L["SECTION_UNREADABLE"] = "능력치를 읽을 수 없음"

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
-- What each note means, on hovering the name it sits beside.
L["PICKER_NOTE_HAS_ONE_DESCRIPTION"] =
	"이미 다른 줄에 배정되어 있습니다. 직접 고른 쪽이 우선이며, 직접 정하지 않은 줄은 다른 사람을 찾습니다."
L["PICKER_NOTE_REFUSED_DESCRIPTION"] =
	"이번 접속 중에 이 플레이어에게 보낸 우편이 반송되었습니다. 그래도 다시 시도할 수 있습니다."
L["PICKER_NOTE_RECENT_DESCRIPTION"] =
	"이번 접속 중에 이미 선물을 받았습니다. 레벨이 오르면 다시 우선 대상이 됩니다."
--[[
	Below the divider at the bottom of the list: a /who aimed at the classes the verdict says
	this item is for, their own bands first and the fallbacks a press behind them.
]]
L["PICKER_FIND_FOR_ITEM"] = "이 아이템의 받을 사람 찾기"
-- Section headings in the recipient picker, in matching order: your alts, your guild, then everyone else.
L["PICKER_SECTION_ALTS"] = "내 부캐"
L["PICKER_SECTION_GUILD"] = "내 길드"
L["PICKER_SECTION_STRANGERS"] = "낯선 사람"
-- Under the other sections on a Kept gear row, holding the enchanter Disenchant Unmatched Items sends to.
L["PICKER_SECTION_DISENCHANT"] = "마력 추출"

-- A heading takes no full stop; every body line under it does.
L["TOOLTIP_RECIPIENT"] = "받는 사람"
L["TOOLTIP_RECIPIENT_CANDIDATES"] = "후보 %d명, 레벨 %d-%d."
L["TOOLTIP_RECIPIENT_HINT"] = "클릭하여 다시 지정합니다."
-- TRANSLATORS: %s is one to three class names, comma-separated, each from the game itself.
L["TOOLTIP_RECIPIENT_BEST_FIT"] = "%s에게 가장 잘 맞습니다."
--[[
	In place of the count and hint on a row nobody can ever be offered, where the count is always
	zero. The unreadable line is also the picker's info line for that row: the add-on's failure,
	not an empty realm, so Find Recipients is not pressed forever.
]]
L["ITEM_STATS_UNREADABLE"] = "이 아이템의 능력치를 읽을 수 없어 배정하지 않습니다."
L["TOOLTIP_RECIPIENT_KEPT"] = "원하는 직업이 없어 가방에 남겨 둡니다."
-- On a Kept row Disenchant Unmatched Items sent to your enchanter. %s is that character's name.
L["TOOLTIP_RECIPIENT_DISENCHANT"] = "아무도 쓸 수 없어 마력 추출을 위해 %s에게 보냅니다."

-- The row's tick box. Every row starts ticked; unticking keeps the item, and stays unticked.
L["TOOLTIP_CHECK_SEND"] = "나눠 주기를 누르면 보냅니다. 보관하려면 체크를 해제하세요."
L["TOOLTIP_CHECK_WAITING"] =
	"검색으로 누군가를 찾는 즉시 배정됩니다. 보관하려면 체크를 해제하세요."
-- On the dimmed tick of a row Distribute can never mail as it stands.
L["TOOLTIP_CHECK_PICK"] = "보내려면 목록에서 받을 사람을 고르세요."
L["TOOLTIP_CHECK_UNREADABLE"] = "능력치를 읽을 수 있을 때까지 보낼 수 없습니다."

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
L["MAIL_STILL_SENDING"] = "아직 보내는 중입니다. 잠깐만 기다려 주세요."
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
	"TSM을 사용한다면 이 작업에는 Blizzard 기본 우편 보내기 창으로 전환하세요. TSM 우편함은 첨부를 받지 않습니다."
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
	"더 이상 쓰지 않는 착용 시 귀속 장비, 음식, 물약, 두루마리, 오일, 숫돌을 부캐, 길드원, 레벨업 중인 플레이어에게 우편으로 보내세요. 모든 아이템은 가장 잘 맞는 직업에게 가고, 가방 속 잡동사니가 누군가의 다음 업그레이드가 됩니다. 녹색 아이템 하나씩, 받은 만큼 베푸세요."
L["OPTIONS_WELCOME"] = "환영 메시지 사용"
L["OPTIONS_WELCOME_DESCRIPTION"] = "접속할 때 버전과 설정 안내를 표시합니다."

L["OPTIONS_FEATURES_HEADER"] = "기능"

L["OPTIONS_COMMANDS_HEADER"] = "/명령어"
L["OPTIONS_COMMAND"] = "/pif"
L["OPTIONS_COMMAND_DESCRIPTION"] = "이 애드온의 설정 창을 엽니다."

--------------------------------------------------------------------------------
-- Options: What to Give Away Panel
--------------------------------------------------------------------------------

L["TAB_GIVE_AWAY"] = "나눠 줄 것"
L["OPTIONS_GIVE_AWAY_INTRO"] =
	"다른 플레이어에게 무엇을 나눠 줄지 고르세요. 장비와 소모품은 나눠 주기 창 위쪽에서도 언제든 바꿀 수 있습니다."
L["OPTIONS_MAX_RARITY_DESCRIPTION"] =
	"제공할 최고 희귀도입니다. 이보다 높은 것은 목록에 나오지 않으므로 좋은 전리품을 실수로 보낼 일이 없습니다."
L["OPTIONS_DISTRIBUTE_GEAR"] = "장비 나눠 주기"
L["OPTIONS_DISTRIBUTE_GEAR_DESCRIPTION"] = "착용 시 귀속되는 무기와 방어구를 제공합니다."
L["OPTIONS_DISTRIBUTE_CONSUMABLES"] = "소모품 나눠 주기"
L["OPTIONS_DISTRIBUTE_CONSUMABLES_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 저레벨 음식, 음료, 물약, 두루마리, 오일, 숫돌을 제공합니다."
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
	One switch per kind, drawn under Distribute Consumables and again in the mail window from
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
L["OPTIONS_KIND_OILS_STONES"] = "오일 및 숫돌"
L["OPTIONS_KIND_OILS_STONES_DESCRIPTION"] =
	"레벨이 지나 쓰지 않는 무기 오일, 숫돌, 무게추를 제공합니다. 마법사 오일은 주문 시전자에게, 마나 오일은 마나를 쓰는 직업에게, 숫돌과 무게추, 그 밖의 오일은 근접 직업에게 갑니다."

--[[
	Kept gear mailed to one of your own characters instead of staying in your bags. Gear only:
	consumables do not disenchant. The dropdown lists every character on this realm or a
	connected one, on this faction, that has logged in with the add-on.
]]
L["OPTIONS_DISENCHANT_HEADER"] = "배정되지 않은 아이템 마력 추출"
L["OPTIONS_DISENCHANT_DESCRIPTION"] =
	"아무에게도 배정되지 않은 장비를 가방에 남겨 두는 대신 내 캐릭터 중 하나에게 우편으로 보내 마력 추출할 수 있습니다. 이 기능을 켠 다음 받을 캐릭터를 고르세요. 서버와 진영마다 선택이 따로 저장됩니다."
L["OPTIONS_DISENCHANT_SEND"] = "배정되지 않은 아이템을 마법부여사에게 보내기"
L["OPTIONS_DISENCHANT_SEND_DESCRIPTION"] =
	"아무도 쓸 수 없는 장비를 가방에 남겨 두는 대신 내 캐릭터 중 하나에게 보내 마력 추출합니다. 소모품은 절대 보내지 않습니다."
L["OPTIONS_DISENCHANTER_DESCRIPTION"] =
	"내 마법부여사입니다. 이 서버와 연합 서버에 있는 이 진영의 내 캐릭터 중 Play It Forward를 사용해 접속한 적이 있는 캐릭터가 표시됩니다."

--------------------------------------------------------------------------------
-- Options: Recipients Panel
--------------------------------------------------------------------------------

L["TAB_RECIPIENTS"] = "받는 사람"
L["OPTIONS_RECIPIENTS_INTRO"] =
	"장비를 누구에게 어떤 순서로 보낼지 정합니다. 어떤 캐릭터와 길드를 포함할지는 아래 내 부캐와 내 길드 페이지에서 고르세요."

L["OPTIONS_PRIORITY_HEADER"] = "먼저 받을 사람"
L["OPTIONS_PRIORITY_DESCRIPTION"] =
	"낯선 사람만큼 잘 맞는 아이템이라면 내 캐릭터와 길드원이 줄 맨 앞에 설 수 있습니다. 둘 중 하나를 체크 해제하면 레벨과 위치를 기준으로 다른 모든 사람과 경쟁합니다."
L["OPTIONS_PRIORITIZE_ALTS"] = "낯선 사람과 내 길드보다 내 부캐 우선"
L["OPTIONS_PRIORITIZE_ALTS_DESCRIPTION"] =
	"다른 누구에게나 맞는 만큼 잘 맞는 아이템이라면 내 캐릭터가 먼저 받습니다. 체크를 해제하면 레벨과 위치를 기준으로 다른 모든 사람과 경쟁합니다."
L["OPTIONS_PRIORITIZE_GUILDS"] = "낯선 사람보다 내 길드 우선"
L["OPTIONS_PRIORITIZE_GUILDS_DESCRIPTION"] =
	"똑같이 잘 맞는 아이템이라면 길드원이 낯선 사람보다 먼저 받습니다. 체크를 해제하면 레벨과 위치를 기준으로 낯선 사람과 경쟁합니다."

L["OPTIONS_STRANGERS_HEADER"] = "낯선 사람을 검색할 때"
L["OPTIONS_STRANGERS_DESCRIPTION"] =
	"/who로 찾은 플레이어끼리 비교하는 방식입니다. 똑같이 잘 맞는 후보 중에서는 레벨업 중이라 실제로 쓸 가능성이 가장 높은 사람에게 장비가 먼저 갑니다."
L["OPTIONS_PRIORITIZE_LEVELING_ZONES"] = "적정 레벨 지역의 낯선 사람 우선"
L["OPTIONS_PRIORITIZE_LEVELING_ZONES_DESCRIPTION"] =
	"도시에 있는 플레이어보다 자기 레벨에 맞는 지역에서 퀘스트 중인 플레이어에게 먼저 장비를 제공합니다. 이렇게 퀘스트 중인 플레이어가 여러분의 호의를 가장 반길 가능성이 높습니다."
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES"] = "인스턴스 밖의 낯선 사람 우선"
L["OPTIONS_PRIORITIZE_OUTSIDE_INSTANCES_DESCRIPTION"] =
	"바깥 세상에 알맞은 사람이 없을 때만 던전이나 공격대에 있는 플레이어에게 장비를 제공합니다. 던전에 있는 플레이어는 버스를 타는 캐릭터일 수 있어 장비가 오래 필요하지 않을 수 있습니다."
-- TRANSLATORS: %d-%d is a level range, such as 20-25.
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS"] = "%d-%d레벨 흑마법사 제외"
L["OPTIONS_IGNORE_SUMMONER_WARLOCKS_DESCRIPTION"] =
	"이 레벨 범위의 흑마법사인 낯선 사람에게는 장비를 제공하지 않습니다. 흑마법사는 20레벨에 소환을 배우기 때문에 많은 플레이어가 친구를 소환하려고 흑마법사 부캐를 이 레벨에 세워 두며, 그래서 이들에게 보낸 장비는 쓰이지 않는 경우가 많습니다. 내 캐릭터와 길드원은 영향을 받지 않습니다."

L["OPTIONS_SPECS_HEADER"] = "직업 및 전문화"
L["OPTIONS_SPECS_INTRO"] =
	"다른 플레이어의 전문화는 볼 수 없으므로 장비는 아래 가정에 따라 보내집니다. 내 캐릭터는 내 부캐에서 설정한 전문화를 사용합니다."
L["OPTIONS_SPECS_RESET"] = "기본값 복원"
L["OPTIONS_SPECS_RESET_DESCRIPTION"] = "모든 전문화를 애드온의 기본 설정으로 되돌립니다."
-- The damage roles only: Tank and Healer come from the game's TANK and HEALER labels.
L["ROLE_CASTER"] = "주문 공격"
L["ROLE_MELEE"] = "근접 공격"
L["ROLE_RANGED"] = "원거리 공격"

-- Talent trees and specializations, by the key each flavor folder's Match-Specs file uses.
L["SPEC_Arms"] = "무기"
L["SPEC_Fury"] = "분노"
L["SPEC_Protection"] = "방어"
L["SPEC_Holy"] = "신성"
L["SPEC_Retribution"] = "징벌"
L["SPEC_BeastMastery"] = "야수"
L["SPEC_Marksmanship"] = "사격"
L["SPEC_Survival"] = "생존"
L["SPEC_Assassination"] = "암살"
L["SPEC_Combat"] = "전투"
L["SPEC_Subtlety"] = "잠행"
L["SPEC_Discipline"] = "수양"
L["SPEC_Shadow"] = "암흑"
L["SPEC_Elemental"] = "정기"
L["SPEC_Enhancement"] = "고양"
L["SPEC_Restoration"] = "복원"
L["SPEC_Arcane"] = "비전"
L["SPEC_Fire"] = "화염"
L["SPEC_Frost"] = "냉기"
L["SPEC_Affliction"] = "고통"
L["SPEC_Demonology"] = "악마"
L["SPEC_Destruction"] = "파괴"
L["SPEC_Balance"] = "조화"
L["SPEC_Feral"] = "야성"
L["SPEC_Guardian"] = "수호"
L["SPEC_Blood"] = "혈기"
L["SPEC_Unholy"] = "부정"
L["SPEC_Brewmaster"] = "양조"
L["SPEC_Mistweaver"] = "운무"
L["SPEC_Windwalker"] = "풍운"
-- Paladin Protection and Druid Restoration, which some locales name differently from the Warrior and Shaman trees.
L["SPEC_PALADIN_Protection"] = "보호"
L["SPEC_DRUID_Restoration"] = "회복"
-- Season of Discovery roles that runes added on top of the three trees.
L["SPEC_Tank"] = "방어 전담 (룬)"
L["SPEC_Healer"] = "치유 전담 (룬)"
L["SPEC_Melee"] = "근접 공격 (룬)"

--------------------------------------------------------------------------------
-- Options: My Alts Panel
--------------------------------------------------------------------------------

L["TAB_ALTS"] = "내 부캐"
L["OPTIONS_ALTS_INTRO"] =
	"내 캐릭터 목록입니다. 각 캐릭터는 Play It Forward를 사용해 접속하면 추가됩니다. 왼쪽에서 캐릭터를 골라 우편을 받을지, 어떤 전문화용 장비를 받을지 정하세요."
L["OPTIONS_SEND_TO_ALTS"] = "부캐에게 보내기"
L["OPTIONS_SEND_TO_ALTS_DESCRIPTION"] =
	"길드와 낯선 사람보다 먼저 내 캐릭터에게 보내되, 그 직업에 가장 잘 맞는 아이템만 보냅니다. 이 서버나 연합 서버에서, 이 진영으로 Play It Forward를 사용해 접속한 적이 있는 캐릭터가 대상입니다. 부캐에게 보낸 우편은 베풂의 휘장 합계에 포함되지 않습니다."
L["OPTIONS_ALTS_EMPTY"] =
	"아직 캐릭터가 없습니다. 각 캐릭터는 Play It Forward를 사용해 접속하면 여기에 표시됩니다."
L["OPTIONS_ALT_INCLUDE"] = "이 캐릭터 포함"
L["OPTIONS_ALT_INCLUDE_DESCRIPTION"] =
	"이 캐릭터에게 장비를 보냅니다. 체크를 해제하면 아무것도 제공하지 않습니다. 최고 레벨에 도달한 캐릭터는 체크 해제된 상태로 시작합니다."
L["OPTIONS_ALT_SPECS"] = "장비를 보낼 전문화"
L["OPTIONS_ALT_SPEC_TICK_DESCRIPTION"] =
	"이 전문화용 장비를 이 캐릭터에게 제공합니다. 처음에는 캐릭터가 마지막으로 플레이한 전문화가 선택되며, 아직 없으면 모든 전문화가 선택됩니다."
--[[
	Gear Levels on each alt's pane: the lowest and highest gear it is mailed, counted from its own
	level. The stops read "Their Level -2" and "Their Level +3" so they mean the same as it levels.
]]
L["OPTIONS_ALT_LEVELS"] = "장비 레벨"
L["OPTIONS_ALT_LEVEL_LOWEST"] = "최저"
L["OPTIONS_ALT_LEVEL_LOWEST_DESCRIPTION"] =
	"이 캐릭터에게 보낼 장비의 최저 레벨입니다. 캐릭터 레벨은 그 레벨보다 낮은 장비를 보내지 않고, 캐릭터 레벨 -2는 지금 착용할 수 있는 2레벨 아래까지의 장비도 보냅니다."
L["OPTIONS_ALT_LEVEL_HIGHEST"] = "최고"
L["OPTIONS_ALT_LEVEL_HIGHEST_DESCRIPTION"] =
	"이 캐릭터에게 보낼 장비의 최고 레벨입니다. 쓸 수 있는 모든 장비는 앞으로 착용하게 될 장비까지 모두 보내므로, 1레벨 사냥꾼도 50레벨 활을 받을 수 있습니다."
L["OPTIONS_ALT_LEVEL_THEIRS"] = "캐릭터 레벨"
-- TRANSLATORS: %d is 1 to 3.
L["OPTIONS_ALT_LEVEL_BELOW"] = "캐릭터 레벨 -%d"
L["OPTIONS_ALT_LEVEL_ABOVE"] = "캐릭터 레벨 +%d"
L["OPTIONS_ALT_LEVEL_ANY"] = "쓸 수 있는 모든 장비"
-- Under the two dropdowns, in real levels at the character's last recorded level.
L["OPTIONS_ALT_LEVELS_RANGE"] = "%d레벨부터 %d레벨까지의 장비를 보냅니다."
L["OPTIONS_ALT_LEVELS_FROM"] = "%d레벨 이상의 장비를 보냅니다."
L["OPTIONS_DELETE"] = "삭제"
-- TRANSLATORS: %s is a character's name.
L["OPTIONS_ALT_DELETE_CONFIRM"] =
	"%s 캐릭터를 목록에서 삭제할까요? 다음에 접속하면 다시 추가됩니다."
L["OPTIONS_ALT_DELETE_DESCRIPTION"] =
	"이 캐릭터를 목록에서 삭제합니다. 다음에 접속하면 다시 추가됩니다."

--------------------------------------------------------------------------------
-- Options: My Guilds Panel
--------------------------------------------------------------------------------

L["TAB_GUILDS"] = "내 길드"
L["OPTIONS_GUILDS_INTRO"] =
	"내 캐릭터가 속한 모든 길드입니다. 캐릭터가 접속할 때마다 저장되므로, 어느 캐릭터로 플레이하든 레벨업 중인 길드원에게 우편을 보낼 수 있습니다."
L["OPTIONS_GUILD_OFFLINE"] = "오프라인 길드원 제외"
L["OPTIONS_GUILD_OFFLINE_DESCRIPTION"] =
	"이 기간보다 오래 접속하지 않은 길드원을 건너뜁니다. 지금 속한 길드와 저장된 길드 모두에 적용됩니다. 안 함을 선택하면 얼마나 오래 접속하지 않았든 모두 포함합니다."
L["OPTIONS_GUILD_OFFLINE_WEEK"] = "1주 넘게 미접속"
L["OPTIONS_GUILD_OFFLINE_TWO_WEEKS"] = "2주 넘게 미접속"
L["OPTIONS_GUILD_OFFLINE_NEVER"] = "안 함"
L["OPTIONS_GUILDS_EMPTY"] =
	"아직 길드가 없습니다. 길드에 속한 내 캐릭터가 접속하면 여기에 표시됩니다."
L["OPTIONS_GUILD_INCLUDE"] = "이 길드의 길드원에게 보내기"
L["OPTIONS_GUILD_INCLUDE_DESCRIPTION"] = "이 길드의 길드원에게 장비를 보냅니다."
L["OPTIONS_GUILD_MEMBERS"] = "활동 중인 길드원"
L["OPTIONS_GUILD_MEMBERS_EMPTY"] =
	"이 명단에는 아이템을 받을 만큼 최근에 활동한 사람이 없습니다."
L["OPTIONS_GUILD_MEMBER_INCLUDE"] = "포함"
L["OPTIONS_GUILD_MEMBER_INCLUDE_DESCRIPTION"] =
	"이 길드원에게 장비를 보냅니다. 길드 은행 캐릭터나 전문 기술용 부캐라면 체크를 해제하세요. 그러면 아무것도 제공하지 않습니다."
-- TRANSLATORS: %d is a count of guild members, the first %s when the roster was saved ("today", "3 days ago"), the second a character's name.
L["OPTIONS_GUILD_STATUS"] = "활동 길드원 %d명, %s %s 님이 저장함."
L["OPTIONS_GUILD_SAVED_TODAY"] = "오늘"
L["OPTIONS_GUILD_SAVED_YESTERDAY"] = "어제"
L["OPTIONS_GUILD_SAVED_DAYS"] = "%d일 전"
L["OPTIONS_GUILD_CURRENT"] = "현재 길드입니다. 우편함에서 새로 읽어 옵니다."
L["OPTIONS_GUILD_SKIPPED_REALM"] = "다른 서버에 있어 여기서는 우편을 보낼 수 없습니다."
L["OPTIONS_GUILD_SKIPPED_FACTION"] = "다른 진영에 있어 여기서는 우편을 보낼 수 없습니다."

--------------------------------------------------------------------------------
-- Options: Mail Message Text Panel
--------------------------------------------------------------------------------

L["TAB_MAIL_MESSAGE"] = "우편 메시지 문구"
L["OPTIONS_MAIL_DESCRIPTION"] =
	"선물마다 함께 보내는 메모입니다. 왼쪽에 직접 작성하면 오른쪽에서 실제로 보내질 내용을 볼 수 있습니다. 입력하는 대로 저장되며, 칸을 비우면 기본 문구로 돌아갑니다."
L["OPTIONS_MAIL_SUBJECT"] = "제목"
L["OPTIONS_MAIL_BODY"] = "본문"
L["OPTIONS_MAIL_YOURS"] = "내 메시지"
L["OPTIONS_MAIL_PREVIEW"] = "받는 사람에게 보이는 내용"
L["OPTIONS_MAIL_COUNT_SUBJECT"] = "제목 %d/%d"
L["OPTIONS_MAIL_COUNT_BODY"] = "본문 %d/%d"
L["OPTIONS_MAIL_RESET"] = "기본값 복원"
L["OPTIONS_MAIL_RESET_DESCRIPTION"] = "기본 제목과 본문으로 돌아갑니다."

--------------------------------------------------------------------------------
-- Options: Badge of Generosity Panel
--------------------------------------------------------------------------------

L["TAB_GENEROSITY"] = "베풂의 휘장"
L["OPTIONS_GENEROSITY_DESCRIPTION"] =
	"계정의 모든 캐릭터를 합친 나눔 합계입니다. 도시와 여관에서 내 플레이어 툴팁에 표시되어, 다른 Play It Forward 사용자가 나에게 마우스를 올리면 볼 수 있고 나도 그들의 합계를 볼 수 있습니다. 던전, 공격대, 바깥 세상에서는 숨겨집니다."

--[[
	Account-wide giving tally, read-only here. Item Levels counts equippable gear only.

	The unit tooltip reuses the header and the four labels, so the two surfaces never disagree.
	There ns:BuildBrandedLine puts the Short Name and the // in front of the header, so it never
	carries either.
]]
L["OPTIONS_GENEROSITY_HEADER"] = "베풂의 휘장"
L["OPTIONS_GENEROSITY_GIFTS"] = "선물"
L["OPTIONS_GENEROSITY_ITEMS"] = "아이템"
L["OPTIONS_GENEROSITY_ITEM_LEVELS"] = "아이템 레벨"
L["OPTIONS_GENEROSITY_VALUE"] = "골드 가치"

-- Sharing the tally with nearby players.
L["OPTIONS_SHARE_STATS"] = "베풂의 휘장 플레이어 툴팁 사용"
L["OPTIONS_SHARE_STATS_DESCRIPTION"] =
	"도시와 여관에서 근처 플레이어가 내 툴팁에서 합계를 볼 수 있습니다. 끄면 공유가 멈추지만 다른 사람의 합계는 계속 보이며, 내 합계는 어느 쪽이든 계속 집계됩니다."

--------------------------------------------------------------------------------
-- Options: Feedback & Support Panel
--------------------------------------------------------------------------------

L["OPTIONS_LEVEL_UP_TITLE"] = "Play It Forward의 레벨 업을 도와주세요"
L["OPTIONS_LEVEL_UP_INTRO"] =
	"이 애드온은 이 게임을 사랑하고 모두가 최대한 즐겁게 플레이하길 바라는 플레이어들이 만들었습니다. 저희는 절대 후원을 요청하지 않습니다. 저희 작업이 여러분의 게임을 조금 더 즐겁게 만든다는 것이 진정한 보람입니다. 그렇다면 꼭 알려 주세요!"
L["OPTIONS_LEVEL_UP_WAYS"] =
	"더 많은 플레이어에게 다가갈 수 있도록 도와주실 방법이 몇 가지 있습니다."
L["OPTIONS_LEVEL_UP_FEEDBACK"] =
	"• 피드백 공유: 버그를 찾았거나 아이디어가 있으신가요? Discord에서 알려 주세요. 여러분의 피드백은 애드온 개선에 도움이 되며, 풀 리퀘스트는 언제나 환영합니다."
L["OPTIONS_LEVEL_UP_FRIEND"] =
	"• 친구에게 알리기: 이 애드온을 좋아할 만한 사람을 알고 계신가요? 소개해 주세요. 입소문은 더 많은 플레이어가 좋은 애드온을 발견하는 데 도움이 됩니다."
L["OPTIONS_LEVEL_UP_CURSEFORGE"] =
	"• CurseForge 즐겨찾기: 아래 CurseForge 링크를 열고 로그인한 뒤 Download 버튼 아래의 별을 클릭하세요. 즐겨찾기는 더 많은 플레이어가 애드온을 발견하는 데 도움이 됩니다."
L["OPTIONS_LEVEL_UP_GITHUB"] =
	"• GitHub Star: 아래 GitHub 링크를 열고 로그인한 뒤 오른쪽 위의 Star를 클릭하세요. Star는 프로젝트가 더 많은 무료 개발자 도구를 받을 자격을 얻는 데 도움이 됩니다."
L["OPTIONS_LEVEL_UP_THANKS"] = "Play It Forward를 선택해 주셔서 감사합니다!"

L["OPTIONS_FEEDBACK"] = "피드백 및 지원"
L["OPTIONS_FEEDBACK_LINKS_HEADER"] = "피드백 및 지원 링크"
L["OPTIONS_CURSEFORGE"] = "CurseForge"
L["OPTIONS_GITHUB"] = "GitHub"
L["OPTIONS_DISCORD"] = "Discord"
L["OPTIONS_WAGO"] = "Wago"
L["OPTIONS_COPY_LINK"] = "링크를 복사하려면 상자를 클릭한 다음 Ctrl+A, Ctrl+C를 누르세요."
L["OPTIONS_VERSION"] = "버전 %s"
