# Play It Forward — Manual Test Plan

This is the manual test plan for Play It Forward — the steps to confirm it works before a release is tagged. For what it does, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md); for how it works, see [README-Technical.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README-Technical.md).

## How to run this plan

Work top to bottom. Every step tells you what to do, what you should see, and what failure looks like — if a step doesn't match, you've found a bug. Steps are numbered continuously across the whole document, so a report only needs to say "failed on step 44."

Run the whole list on Classic Era, then again on TBC Anniversary. Do a `/reload` before starting each flavor.

Some steps behave differently on the two clients and say so where they sit. Those steps must be run on **both** flavors — especially the one the step names as the client that tends to break. Testing one flavor is not finishing.

## Before you start

Gather these once so nothing catches you short halfway through.

- **Both clients.** Classic Era (1.15.x) and TBC Anniversary (2.5.x). Copy the **same build** of the add-on into `Interface/AddOns` on each before you start — a stale copy in one client makes half these steps test the wrong code.
- **A character with bag clutter.** At least one unbound green (bind-on-equip) you can spare, ideally an unbound blue as well, and a stack of low-level food or water you are twenty or more levels past. Two or three giveable items at once is better than one.
- **Something that should be refused.** A soulbound item and a quest item sitting in the same bags, so the Bag Scan export has rejections to show.
- **Copper.** A few silver for postage, and — for step 72 — a way to get *below* 30 copper, which realistically means trading your money to somebody else for a minute.
- **A guild.** A character in a guild with members who have logged in within the last three days, so guild recipients have somebody to find.
- **A character with no guild**, for step 60. If every character you have is guilded, skip that step and record it as not run rather than guessing.
- **A second player** running Play It Forward, standing beside you in a city — the only way to check the shared Generosity tooltip, and the only way to see a delivered parcel from the receiving end. Steps that need one say so.
- **Location.** A mailbox in a city, which covers the resting steps too, plus a trip out into the world where you are *not* resting, plus one trip into a dungeon or raid.
- **A non-English client** — for the optional localization spot-check at the end, nothing else.

## Smoke test

The add-on loads, opens, and does the thing it exists to do. Run this first on each flavor; if any of it fails, stop and report rather than working through the rest.

**1.** Log in with the add-on enabled. Chat prints one line beginning `Play It Forward //` with a version and a pointer to the settings. Failure looks like no line at all (with the welcome message still switched on), or a red Lua error on login.

**2.** Type `/reload`. The UI comes back and the same line prints again. Failure is an error popup, or the add-on missing from the AddOns list afterward.

**3.** Type `/pif`. The settings must appear **docked inside the Blizzard Options window**, with Play It Forward selected in the category list on the left. Failure looks like either nothing happening at all, or a standalone window floating free of the Options frame. **Run this on both flavors — TBC Anniversary is the client where this has historically floated.**

**4.** In that panel, confirm the two child entries **Profiles** and **Diagnostic Tools** exist under Play It Forward and that clicking each draws its own page. Failure is a missing child, or a child that opens blank.

**5.** Set the dropdown beside **Include Gear** to **Rare & Lower**, type `/reload`, and return to the panel. It still reads Rare & Lower. Set it back to **Uncommon** before continuing. Failure is the setting reverting on its own.

**6.** With at least one unbound green in your bags, walk to a mailbox and open it. A window titled **Play It Forward** opens by itself, to the right of the mail frame. Failure is no window appearing when you know you have something giveable in your bags.

**7.** Press **Find Recipients**. The button greys out and reads `Searching...` for about five seconds. While that happens the mailbox stays open and Blizzard's own Who window does **not** appear. Failure looks like the mailbox slamming shut, the Who panel popping up over everything, or the button never coming back.

**8.** When a name lands on a row, tick that row and press **Distribute**. Accept the confirmation popup. Chat reports `Sent <item> to <name> (1/1).` followed by `Done. 1 of 1 delivered.`, and the row leaves the list. Failure is nothing sending, the item still sitting in your bags afterward, or an error in place of the confirmation.

When steps 1–8 pass on both Classic Era and TBC Anniversary, the add-on loads and its core loop works. Work through the rest of the plan before running `4 - Pre-Launch Review Prompt.md`.

## The options panel and how you reach it

There is no minimap button. `/pif` and the Blizzard Options window are the only two ways in, which makes step 9 as important as step 3.

**9.** Without using the slash command, open the Blizzard Options window yourself (Escape → Options → AddOns) and select **Play It Forward** from the category list. You get the same page `/pif` gave you. Failure is the add-on missing from the list, or the page drawing empty.

**10.** With the Options window already open on some other add-on, type `/pif`. The selection jumps to Play It Forward. Failure is nothing moving, or a second window opening on top.

**11.** Click **Profiles**. You get the standard profile controls: the current profile name, and New / Copy From / Reset / Delete. Failure is a blank page or missing controls.

**12.** Click **Diagnostic Tools**. You see a warning paragraph and a single **Enable Diagnostic Tools** checkbox, and the checkbox is **unticked**. Failure is the box arriving ticked, or the report sections being visible before you enable anything.

**13.** Back on the main page, read the bottom line. It reads `Version` followed by a version number — an unpackaged development copy reads `Version Dev`. Failure is a blank version or a raw `@project-version@` token.

**14.** Under **Feedback & Support**, confirm four labeled boxes — Discord, GitHub, CurseForge, Wago — each holding a URL you can click into, select, and copy. Type over one and press Enter: the original URL comes straight back. Failure is an empty box, or an edit that sticks.

## Opening the options panel in combat

**15.** Get into combat — pull a mob or hit a target dummy — and type `/pif` while you are still fighting. Chat prints *"As a safety precaution, the Options Interface cannot be opened during combat."* and the panel does **not** open. Failure is the panel opening anyway, silence with nothing printed, or a red `ADDON_ACTION_BLOCKED` error in the middle of the screen. **Run this on both flavors** — the two clients route the panel differently, so a gate that holds on one is not proof for the other.

**16.** Finish the fight and wait. The options panel does **not** open by itself once combat drops. Now type `/pif` again: it opens normally. Failure is a panel that pops up on its own the moment combat ends, or a slash command that stays dead afterward.

## What to give away

**17.** On the main page, find the **What to Give Away** header. Under it sit two toggles, each with a dropdown beside it on the same row: **Include Gear** with a rarity dropdown, and **Include Consumables** with an "outgrown by" dropdown. Failure is a toggle whose dropdown has wrapped onto its own line, or two toggles sharing one row.

**18.** Untick **Include Gear**. The rarity dropdown beside it stays visible but greys out and stops responding to clicks. Tick the box again: it goes live showing the same value it had. Failure is the dropdown disappearing, or staying clickable while the toggle is off.

**19.** Untick **Include Consumables**. The dropdown beside it greys out the same way and comes back live when you tick the box again. Failure is the same as above.

**20.** Open the rarity dropdown. It offers exactly three entries, each drawn in its own item color: **Uncommon** (green), **Rare & Lower** (blue), **Epic & Lower** (purple). Failure is a fourth entry, a missing one, uncolored text, or a bare color word like "Green".

**21.** Open the consumables dropdown. It offers exactly five entries in this order: **All Consumables**, **Outgrown by 5+ Levels**, **Outgrown by 10+ Levels**, **Outgrown by 15+ Levels**, **Outgrown by 20+ Levels**. Failure is a blank dropdown, a missing stop, a different order, or a bare number with no words around it.

**22.** With an unbound blue in your bags and the mail window open at a mailbox, set the rarity to **Rare & Lower**. The blue appears in the window's list without you pressing anything else. Set it back to **Uncommon**: the blue drops off the list again. Failure is the list not changing until you close and reopen the window.

**23.** With a stack of food or water you are twenty-plus levels past, set the consumables dropdown to **Outgrown by 20+ Levels** — the stack is listed. Set it to **All Consumables** and it is still listed. Set it to a stop you do not meet (a gap larger than your gap over the item) and it leaves the list. Failure is the list ignoring the change.

**24.** Untick **Enable Welcome Message**, `/reload`, and watch chat: no Play It Forward line on login. Tick it again, `/reload`: the line is back. Failure is the message printing either way.

**25.** Change two settings, then log out fully and back in (not just `/reload`). Both survive. Failure is either setting reverting to its default.

## Profiles

**26.** On the **Profiles** page, create a new profile. Return to the main page: settings are back at their defaults — **Uncommon**, both Include boxes ticked, **Outgrown by 20+ Levels**, welcome message on, Generosity tooltips on. Failure is your old settings carrying over into the new profile.

**27.** Switch back to your original profile. Your settings return, and if the mail window is open at a mailbox its list and its two top-bar dropdowns re-read themselves without a reload. Failure is a window still showing the other profile's list or values.

**28.** Note your four **Generosity** numbers on the main page, then press **Reset Profile**. Settings reset, but the four Generosity numbers are **unchanged** — that tally is account-wide and deliberately outlives a profile wipe. Failure is any of the four dropping to zero.

## The mail window

**29.** With something giveable in your bags, open a mailbox. The window opens by itself, anchored to the right of the mail frame. Failure is no window when the Bag Scan export (step 89) says you have giftable items.

**30.** Empty your bags of anything giveable and open a mailbox. No window opens, and nothing is printed to chat — a visit with nothing spare is meant to be silent. Failure is an empty window opening, or a "nothing to give" message.

**31.** Close the window with the **X** in its corner. It closes and stays closed. Reopen the mailbox and it returns. Failure is the X doing nothing, or the window reopening on its own.

**32.** With the window open, walk away from the mailbox. The window **stays open**, and the bottom-right button changes to `Requires Open Mailbox` and greys out. Failure is the window closing on you, or the button staying live away from a mailbox.

**33.** Walk back and open the mailbox again. The button reads `Distribute` once more, live if a row is ticked. Failure is the button staying stuck on `Requires Open Mailbox`.

**34.** Drag the window by its title bar to a new spot, close it, and reopen at a mailbox. It comes back where you left it, and survives a `/reload`. Failure is the window snapping back to its default position.

**35.** Read the top bar of the window. Two dropdowns sit there with gold captions: **Gear**, showing the same rarity the options panel shows, and **Consumables**, showing the same "outgrown by" wording. Failure is a caption missing, a value worded differently from the panel's ("Green" against "Uncommon"), or a value running under the dropdown arrow.

**36.** Click the **Gear** dropdown in the window and pick a different rarity. The list below re-reads itself immediately, and opening the options panel shows the new value there too. Failure is the window and the panel disagreeing, or the list not moving until you reopen the window.

**37.** Do the same with the **Consumables** dropdown. Same expected result, same failure.

**38.** Look at the section bands in the list. They appear in this order, and only when they have rows under them: **Matched**, **Pending Match**, **Stats Couldn't Be Read**, **Kept**. Failure is a band with nothing under it, or the order changing.

**39.** Find a stacked consumable row. The item link is followed by a grey `x20` (or whatever the stack size is). A single piece of gear shows no count at all. Failure is `x1` on a gear row, or a stack with no count.

**40.** Hover an item name in a row. The normal game item tooltip appears. Failure is no tooltip, or the wrong item's.

**41.** Hover the recipient control on the right of a row. A tooltip reads `Recipient`, then a line shaped `12 candidate(s) at level 17-18`, then `Click to reassign.` Failure is no tooltip, a zero count on a row that plainly has a name, or a level range that has nothing to do with the item's required level.

## Finding recipients

**42.** Press **Find Recipients**. The button immediately greys and reads `Searching...`, then comes back live about five seconds later. Failure is an instant re-enable, or a button that never recovers.

**43.** Watch the mailbox while that query runs. It stays open, and Blizzard's Who window never appears — not during the query and not a few seconds after. Failure is the mailbox closing, or the Who panel surfacing at any point. This is the single most important check in this section.

**44.** After the first answer lands, read the button. While there is still somewhere left to look it reads `Scan Again`; once there is nothing left to search for it reads `Find Recipients`. Failure is the label never changing.

**45.** Press it several times in a row, waiting out each five-second lock. Names accumulate on rows — pressing again never empties the roster you already built. Failure is previously found names disappearing.

**46.** On a guilded character, open the window at a mailbox and wait a moment **without** pressing anything. Guild members can be matched to rows on their own — the guild costs no button press. Failure is guildmates only ever appearing after a search.

**47.** Enable Diagnostic Tools (step 86) and press **Export Known Players** on a guilded character. Nobody below level 5 is in the list, none of your own characters that have run this add-on are in it, and no guild warlock between level 20 and 23 is in it. Failure is any of those three appearing as a candidate.

**48.** Use the button hard for a while — press it, close and reopen the window, press it again, press it mid-cast. You may not be able to force this deliberately, but if a search is ever blocked, chat prints *"Press Find Recipients again. Blizzard only allows that search straight from a button press, and something interrupted this one."* and pressing again works. Failure is a Lua error popup in place of that line, or a button that goes permanently dead.

**49.** Close the window with the **X** while a search is still running. Nothing appears afterward — in particular Blizzard's Who window must not open by itself a few seconds later. Failure is any window surfacing after you closed ours.

## The recipient dropdown

**50.** Click the recipient control on any row. A list opens with **Keep Item** at the top, then everyone in range with their level, then a divider line, then **Find Recipients for This Item** at the bottom. Failure is a missing Keep Item, or a missing bottom entry.

**51.** Read the names. Each is class-colored with its level in grey beside it, and some carry a short grey note — `(has one)`, `(refused)`, or `(recent)`. Every one of them is still selectable. Failure is a greyed-out, unclickable name, or a note that has pushed the level off the end of the row.

**52.** Pick a name that another row is already holding — one marked `(has one)`. Your row takes the name, and the row that had it drops back to having no recipient and is re-matched automatically. Failure is the pick being refused, or both rows showing the same person.

**53.** Choose **Keep Item** on a matched row. The row loses its recipient and unticks. Press **Find Recipients** again: that row stays empty — your choice is not overridden. Failure is a new recipient appearing on it anyway.

**54.** Tick the checkbox on a row that has no recipient. The row is thrown back into matching, and picks somebody up if anybody suitable is in range. Failure is the checkbox doing nothing on such a row.

**55.** Open the dropdown on a row in the **Stats Couldn't Be Read** section. Instead of names it shows one dimmed, unclickable line: *"Couldn't read this item's stats, so it isn't matched"*. Failure is a normal-looking candidate list on an unreadable row.

**56.** Press **Find Recipients for This Item** at the bottom of a dropdown. The search button locks for its usual five seconds, and names for that one item can arrive. Failure is nothing happening at all, or a Lua error.

**57.** Open a dropdown, then click somewhere else on the screen. The list closes without picking anything. Press Escape with a list open: it closes the same way. Failure is a list that stays up, or one that selects whatever was under the cursor.

**58.** On a character with **no guild**, log in fresh, walk to a mailbox and open a row's dropdown before pressing anything. It shows one dimmed line: *"No one in range, run Find Recipients"*. Press Find Recipients, then reopen it: names are there. If you have no guildless character, skip this step and record it as not run. Failure is a blank list with no explanation.

## Distributing

**59.** With no row ticked at an open mailbox, look at **Distribute** — it is greyed out. Failure is a live button with nothing to send.

**60.** Tick a matched row. Distribute goes live. Untick it: greyed again. Failure is the button not tracking the ticks.

**61.** Press **Distribute** with one row ticked. Chat prints `Distributing 1 item(s). Click Accept on each confirm popup.` Blizzard's own "might be someone you don't know" confirmation appears for a stranger — the add-on never clicks it for you. Failure is mail going out with no confirmation.

**62.** Accept it. Chat prints `Sent <item> to <name> (1/1).`, the row leaves the list, and the run finishes with `Done. 1 of 1 delivered.` Failure is a success message with the item still in your bags.

**63.** Start another single-item run and leave the confirmation popup sitting untouched for about thirty seconds. Chat prints `Click Accept on the popup for <name>, then press Distribute to send the rest.` Accept it late: it still delivers. Failure is a run that hangs silently, or an item lost between the two.

**64.** While a send is genuinely in flight, press **Distribute** a second time. Chat prints `Still sending, give it a sec.` and nothing is double-sent. Failure is a second run starting on top of the first.

**65.** Tick three rows and Distribute. Each confirmation is handled one at a time, the counter climbs `(1/3)`, `(2/3)`, `(3/3)`, and the run reports `Done. 3 of 3 delivered.` Failure is sends overlapping, a stuck counter, or a run that stalls halfway.

**66.** Before pressing Distribute on a multi-row run, read down the list: no name appears on two rows at once, and taking a name for a second row (step 52) always frees the first rather than duplicating it. Run it and confirm each recipient receives exactly one parcel. Failure is any player getting two letters out of a single run.

**67.** Match a row, then move that item to a different bag slot before pressing Distribute. Chat prints `Press Find Recipients to re-scan, <item> moved in your bags.`, that item is skipped, and the run ends with `Done. N of M delivered, 1 skipped (moved in your bags).` Failure is the wrong item going out, or the skip going unmentioned.

**68.** Start a run, then close the mailbox part-way through (walk away or press Escape). Chat prints `Open a mailbox and tick the rows again, the mailbox closed part-way through.` and nothing further is sent. Failure is the run carrying on, or the add-on hanging with Distribute stuck on "still sending."

**69.** Get your character below 30 copper — trade your money to somebody for a minute — and press Distribute. Chat prints `Add a little copper for postage, then press Distribute to send the rest.` Take your money back, press again: it sends. Failure is a silent no-op, or a "sent" message with nothing delivered.

**70.** If you run TSM or another add-on that replaces the mail window, open your mailbox through it and press Distribute. Chat prints `Open Blizzard's Send Mail panel and press Distribute again. Nothing was sent or touched.` followed by a hint about switching to the default mail UI. Failure is an item being *used* instead of attached — a green raising a "you must be level X" warning, a drink being drunk. That is the worst failure in this plan; report it immediately. Skip this step if you don't run one of those add-ons.

**71.** Right after a successful run, open the dropdown on any remaining row. The people you just mailed carry `(recent)` beside their names. Now `/reload` and look again: the `(recent)` notes are gone — that cooldown is per session. Failure is the note missing straight after a send, or surviving the reload.

## What a stranger receives

**72.** Have the player you mailed open it, or check from a second account. The subject reads `Play It Forward!`, the body is the full fixed letter — four paragraphs, ending `Happy adventuring!` — and the item is attached. Failure is a truncated body, a subject that is the item's name instead, or an empty letter with the item missing. If you have no way to read a delivered parcel, record this step as not run and rely on step 73.

**73.** In **Diagnostic Tools**, press **Preview What Strangers Receive**. The report reads `subject (16/31)` followed by the subject, then `body (N/500)` followed by the whole letter. Both counts are under their limits, and the text matches what actually arrived in step 72. Failure is a count over its limit, or a preview that differs from the delivered mail.

**74.** Look through both the options panel and the mail window for any way to edit the subject or body. There is none — the letter is fixed text. Failure is an editable field anywhere.

## The Generosity tally

**75.** Note the four numbers under **Generosity** — Gifts, Items, Item Levels, Gold Value. Send one green, then look again: Gifts is up by one, Items by one, Item Levels by that item's item level, Gold Value by its vendor price. Failure is any counter not moving, or moving by the wrong amount.

**76.** Send a **stack** of consumables — say twenty waters. Gifts goes up by one and Items by twenty; Item Levels does **not** move, because consumables contribute nothing to it. Failure is Items rising by one, or Item Levels rising at all.

**77.** `/reload`, then log out and back in. All four numbers survive. Failure is any counter resetting.

**78.** Log in on a **different character on the same account** and open the panel. The same four numbers are there — the tally is account-wide, not per character. Failure is a fresh zeroed tally on the alt.

## Generosity tooltips (town only)

This whole feature is gated on resting: it works in cities and inns and nowhere else. Two of these steps need a second player running the add-on.

**79.** Standing in a city, hover your **own** character. A `Play It Forward // Generosity` block appears at the bottom of your tooltip with the four totals indented under it — present even when they are all zero. Failure is no block while resting.

**80.** Ride out into the open world until the resting icon disappears, then hover yourself again. The block is **gone**. Failure is the block rendering outside a rest area.

**81.** Go into a dungeon or a raid with a group and hover a party member, then yourself. No block on anyone, and no add-on chatter of any kind. Failure is the block appearing in an instance.

**82.** Back in a city with a second Play It Forward player beside you: hover them. The first hover may show nothing — that is expected. Wait a few seconds and hover again: their Generosity block is there. Failure is the block never arriving after several hovers over half a minute.

**83.** Have that player untick **Enable Generosity Tooltips**. Their totals stop reaching you; an entry you already cached can linger for up to half an hour, so check with a player you have not seen before for a clean read. Meanwhile **you** still see everyone else's, and they still see yours if you left the toggle on. Failure is the toggle also blinding the player who turned it off.

**84.** Hover an NPC — a guard, a vendor, your own pet. No Generosity block on any of them. Failure is the block rendering on anything that isn't a player.

## Diagnostic Tools

Everything here is read-only except the taint-log switch. The panel resets to disabled every session, by design.

**85.** Open **Diagnostic Tools**. Only the warning paragraph and the **Enable Diagnostic Tools** checkbox are visible, and the box is unticked. Failure is any report section showing before you enable.

**86.** Tick it. The report sections appear. Failure is a partial panel or an error.

**87.** `/reload` and return to the panel. The box is unticked again and the sections are hidden — this setting is deliberately not saved. Failure is it remembering that it was on.

**88.** Enable it again for the rest of this section.

**89.** Press **Export Every Bag Slot**. The box fills with one row per occupied bag slot, each with its own item link on the line beneath. Your giveable green is accepted; the soulbound item carries `SOULBOUND` and the quest item `QUEST_ITEM` as their reason. Failure is an empty export, or an occupied slot missing from it.

**90.** Untick **Include Gear** on the main page and run the export again. Your green now carries `GEAR_DISABLED` rather than being accepted. Tick it back on. Failure is the reason code not tracking the setting.

**91.** Press **Export Known Players** before running any search: it is empty or nearly so. Run **Find Recipients**, press it again: the players found are listed by class with what they qualify for. Failure is an export that stays empty after a successful search.

**92.** Shift-click an item into your chat box, copy the link, paste it into the **Item link** field, and press **Explain This Item**. A verdict appears naming the classes the item suits, with both stat readings shown. Failure is a blank report, or an error on a valid link.

**93.** Type a level into **Item required level** and press **Show Armor Groups**, then **Show Weapon Groups**. Each fills the box with the class groupings for that level. **Flavor-sensitive:** on Classic Era, an Alliance character sees no Shaman and a Horde character no Paladin; on TBC Anniversary both classes are present for both factions. Failure is the two clients producing an identical class list.

**94.** Close the mail window, walk away from any mailbox, and press **Force the Window Open**. The window appears centered on screen, and chat reports a line shaped `window: shown=true size=600x470, 14 scanned (3 giftable), re-anchored to CENTER. Drag it where you want it.` Failure is no window appearing, or a report claiming `shown=true` when nothing is visible.

**95.** Press **Check Sharing and Nearby Players**. The report states `shareStats`, whether you are resting, that the prefix `"PIForward"` registered, your own four totals, and every nearby player heard from with how long ago. Standing in a city the resting line reads `true`; out in the world it reads `false`. Failure is `prefix "PIForward" registered = false`, or a resting line that disagrees with your rest icon.

**96.** Press **Start Event Log**, open and close a mailbox, then press **Show Captured Events**. `MAIL_SHOW` and `MAIL_CLOSED` appear in the order they fired. Press **Stop Event Log** and confirm the log stops growing. Bag events are deliberately left out of this log, so their absence is not a failure. Failure is an empty log after mailbox activity, or a log that keeps growing after you stop it.

**97.** Press **Test Event Registration**. Every line reads `[PASS]` and the report ends `All events register on this client.` Failure is any `[FAIL]` line — note which event and on which client.

**98.** Press **Test WoW API Endpoints** and read every line. **Flavor-sensitive and the most important line in this section:** the row **Options panel opens inside the Blizzard interface** must read `[PASS]` on *both* clients, with the route named after it. Failure is that row reading `[FAIL]` on either flavor — which is the same defect step 3 catches by eye, and TBC Anniversary is where it shows up.

**99.** Press **Read Display Settings**, **List Installed Add-ons**, **Dump Saved Variables**, and **List Library Versions** in turn. Each fills its own box with plausible content, and the saved-variables dump shows your current settings. Failure is an empty box or an error on any of the four.

**100.** Press **Turn On Taint Log**, read the state line above it, then **Turn Off Taint Log** and watch the line change back. Leave it **off**. Failure is the state line not tracking the buttons.

**101.** Read the **External Tools** section at the bottom. Two lines are there: one pointing at BugSack and `/console scriptErrors 1`, one pointing at `/etrace`. Failure is a missing line or a raw format placeholder left in the text.

**102.** Untick **Enable Diagnostic Tools**. Every section hides again, leaving only the warning and the checkbox. Failure is a section left on screen.

## Flavor differences to watch

Do not let a pass on Classic Era stand in for the whole add-on. These are the places the two clients genuinely differ:

- **The options panel dock (steps 3, 9 and 98).** The two clients open settings by different routes, and TBC Anniversary is the one where the panel has historically floated free of the Options window instead of docking inside it. With no minimap button, a floating or missing panel leaves a player with no way to reach the settings at all — so this is the single most important flavor check in the plan. Step 98's API report tells you the same thing in words.
- **The combat gate (steps 15 and 16).** Since the panel opens by a different route on each client, the check that stops it opening in combat has to be seen working on each client too.
- **Mailbox detection (steps 29–33).** TBC Anniversary reports the mailbox through an extra channel Classic Era does not have. Watch the `Requires Open Mailbox` button on both: walking away and back must flip it in each client.
- **Classes that exist (step 93).** On Classic Era, Alliance has no Shamans and Horde no Paladins, and the add-on will not match items to them. On TBC Anniversary both classes exist on both sides and must appear.
- **Where the search looks.** The two clients search different zone lists. Nothing in the UI names them, but a search that finds nobody on one flavor while working on the other is worth reporting with the Recipient Roster export (step 91) attached.

## Localization spot-check

Optional, and only worth running on a non-English client. The add-on ships English strings only, so English text on a German or Russian client is expected — these steps confirm it falls back cleanly rather than breaking. A Cyrillic client such as ruRU is the harshest test, because its characters encode widest.

**103.** Log in on a non-English client and open the options panel. Every label reads as English words, not as raw keys like `OPTIONS_GIVE_HEADER`, and nothing shows `nil`. Failure is any key name or `nil` leaking into the UI.

**104.** Send one item and read the chat lines. `Sent <item> to <name> (1/1).` and `Done. 1 of 1 delivered.` come out with real item links, names and numbers filled in — no doubled or missing values. If a send fails, the reason in the parentheses is the client's own error text, in the client's language. Failure is a placeholder left unfilled, or numbers in the wrong order.

**105.** Run **Preview What Strangers Receive** on that client. The subject stays within 31 and the body within 500 — the two counts the report prints. Failure is either count over its limit; note the locale if it happens, since the add-on warns in chat rather than silently cutting the letter short.

## Sign-off

When every step above passes on **both** Classic Era and TBC Anniversary, manual testing is complete and the add-on is ready for `4 - Pre-Launch Review Prompt.md`. A pass on one flavor is not a pass.

| Flavor | Tester | Date | Result |
|---|---|---|---|
| Classic Era (1.15.x) | | | pass / fail |
| TBC Anniversary (2.5.x) | | | pass / fail |

Record any failure as the step number, the flavor, and what you saw instead.
