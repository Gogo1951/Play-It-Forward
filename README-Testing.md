# Play It Forward — Manual Test Plan

This is the manual test plan for Play It Forward — the steps to confirm it works before a release is tagged. For what it does, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md); for how it works, see [README-Technical.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README-Technical.md).

## How to run this plan

Work top to bottom. Every step tells you what to do, what you should see, and what failure looks like — if a step doesn't match, you've found a bug. Steps are numbered continuously across the whole document, so a report only needs to say "failed on step 41."

Run the whole list on Classic Era, then again on TBC Anniversary. Do a `/reload` before starting each flavor.

Some steps behave differently on the two clients and say so where they sit. Those steps must be run on **both** flavors — especially the one the step names as the client that tends to break. Testing one flavor is not finishing.

## Before you start

Gather these once so nothing catches you short halfway through.

- **Both clients.** Classic Era (1.15.x) and TBC Anniversary (2.5.x). Copy the **same build** of the add-on into `Interface/AddOns` on each before you start — a stale copy in one client makes half these steps test the wrong code.
- **A character with bag clutter.** At least one unbound green (bind-on-equip) you can spare, ideally an unbound blue as well, and a stack of low-level food or water you are twenty or more levels past. Two or three giveable items at once is better than one.
- **Something that should be refused.** A soulbound item and a quest item sitting in the same bags, so the Bag Scan export has rejections to show.
- **Copper.** A few silver for postage.
- **A guild.** A character in a guild with members who have logged in recently, so guild recipients have somebody to find.
- **A second player** running Play It Forward, standing beside you in a city — the only way to check the shared Given Away tooltip. Steps that need one say so.
- **Location.** A mailbox in a city, which covers the resting steps too, plus a trip out into the world where you are *not* resting.
- **A non-English client** — for the optional localization spot-check at the end, nothing else.

## Smoke test

The add-on loads, opens, and does the thing it exists to do. Run this first on each flavor; if any of it fails, stop and report rather than working through the rest.

**1.** Log in with the add-on enabled. Chat prints one line beginning `Play It Forward //` with a version and a pointer to the settings. Failure looks like no line at all (with the welcome message still switched on), or a red Lua error on login.

**2.** Type `/reload`. The UI comes back and the same line prints again. Failure is an error popup, or the add-on missing from the AddOns list afterward.

**3.** Type `/pif`. The settings must appear **docked inside the Blizzard Options window**, with Play It Forward selected in the category list on the left. Failure looks like either nothing happening at all, or a standalone window floating free of the Options frame. **Run this on both flavors — TBC Anniversary is the client where this has historically floated.**

**4.** In that panel, confirm the two child entries **Profiles** and **Diagnostic Tools** exist under Play It Forward and that clicking each draws its own page. Failure is a missing child, or a child that opens blank.

**5.** Set **Give Away Up To** to Blue, type `/reload`, and return to the panel. It still reads Blue. Set it back to Green before continuing. Failure is the setting reverting on its own.

**6.** With at least one unbound green in your bags, walk to a mailbox and open it. A window titled **Play It Forward** opens by itself, to the right of the mail frame. Failure is no window appearing when you know you have something giveable in your bags.

**7.** Press **Find Recipients**. The button greys out and reads `Searching...` for about five seconds. While that happens the mailbox stays open and Blizzard's own Who window does **not** appear. Failure looks like the mailbox slamming shut, the Who panel popping up over everything, or the button never coming back.

**8.** When a name lands on a row, tick that row and press **Distribute**. Accept the confirmation popup. Chat reports `Sent <item> to <name> (1/1)` followed by `Done. 1 of 1 delivered.`, and the row leaves the list. Failure is nothing sending, the item still sitting in your bags afterward, or an error in place of the confirmation.

When steps 1–8 pass on both Classic Era and TBC Anniversary, the add-on loads and its core loop works. Work through the rest of the plan before running `4 - Pre-Launch Review Prompt.md`.

## The options panel and how you reach it

There is no minimap button. `/pif` and the Blizzard Options window are the only two ways in, which makes step 9 as important as step 3.

**9.** Without using the slash command, open the Blizzard Options window yourself (Escape → Options → AddOns) and select **Play It Forward** from the category list. You get the same page `/pif` gave you. Failure is the add-on missing from the list, or the page drawing empty.

**10.** With the Options window already open on some other add-on, type `/pif`. The selection jumps to Play It Forward. Failure is nothing moving, or a second window opening on top.

**11.** Click **Profiles**. You get the standard profile controls: the current profile name, and New / Copy From / Reset / Delete. Failure is a blank page or missing controls.

**12.** Click **Diagnostic Tools**. You see a warning paragraph and a single **Enable Diagnostic Tools** checkbox, and the checkbox is **unticked**. Failure is the box arriving ticked, or the report sections being visible before you enable anything.

**13.** Back on the main page, read the bottom line. It reads `Version` followed by a version number — an unpackaged development copy reads `Version Dev`. Failure is a blank version or a raw `@project-version@` token.

**14.** Under **Feedback & Support**, confirm four labeled boxes — Discord, GitHub, CurseForge, Wago — each holding a URL you can click into, select, and copy. Type over one and press Enter: the original URL comes straight back. Failure is an empty box, or an edit that sticks.

## What to give away

**15.** Untick **Include Gear**. The **Give Away Up To** dropdown beside it disappears. Tick it again and the dropdown returns showing your previous choice. Failure is the dropdown staying visible but dead, or losing its value.

**16.** Untick **Include Consumables**. The **Outgrown By** dropdown beside it disappears, and returns when you tick the box again. Failure is the same as above.

**17.** Open the **Outgrown By** dropdown. It offers exactly five stops: `0 levels`, `5 levels`, `10 levels`, `15 levels`, `20 levels`. Failure is a blank dropdown, a missing stop, or a bare number with no word after it.

**18.** Open **Give Away Up To**. It offers exactly three, each drawn in its own item color: Green, Blue, Purple. Failure is a fourth entry, a missing one, or uncolored text.

**19.** With an unbound blue in your bags and the mail window open at a mailbox, set **Give Away Up To** to Blue. The blue appears in the window's list without you pressing anything. Set it back to Green: the blue drops off the list again. Failure is the list not changing until you close and reopen the window.

**20.** With a stack of food or water you are twenty-plus levels past, set **Outgrown By** to `20` — the stack is listed. Set it to `0` and it is still listed; set it high enough that you no longer qualify and it leaves the list. Failure is the list ignoring the change.

**21.** Untick **Enable Welcome Message**, `/reload`, and watch chat: no Play It Forward line on login. Tick it again, `/reload`: the line is back. Failure is the message printing either way.

**22.** Change two settings, then log out fully and back in (not just `/reload`). Both survive. Failure is either setting reverting to its default.

**23.** Under **Recipient History**, press **Clear History and Roster**. A confirmation appears first, and pressing it through empties the known-player roster — with the mail window open, recipient names disappear from the rows. Failure is the button acting with no confirmation, or names surviving the clear.

**24.** With the mail window open, press **Find Recipients** again after clearing. Names come back. Failure is an empty roster that never refills.

## Profiles

**25.** On the **Profiles** page, create a new profile. Return to the main page: settings are back at their defaults — Green cap, both Include boxes ticked, Outgrown By at `20`. Failure is your old settings carrying over into the new profile.

**26.** Switch back to your original profile. Your settings return, and if the mail window is open at a mailbox its list and rarity control re-read themselves without a reload. Failure is a window still showing the other profile's list.

**27.** Note your four **Given Away** numbers on the main page, then press **Reset Profile**. Settings reset, but the four Given Away numbers are **unchanged** — that tally is account-wide and deliberately outlives a profile wipe. Failure is any of the four dropping to zero.

## The mail window

**28.** With something giveable in your bags, open a mailbox. The window opens by itself, anchored to the right of the mail frame. Failure is no window when the Bag Scan export (step 79) says you have giftable items.

**29.** Empty your bags of anything giveable and open a mailbox. No window opens, and nothing is printed to chat — a visit with nothing spare is meant to be silent. Failure is an empty window opening, or a "nothing to give" message.

**30.** Close the window with the **X** in its corner. It closes and stays closed. Reopen the mailbox and it returns. Failure is the X doing nothing, or the window reopening on its own.

**31.** With the window open, walk away from the mailbox. The window **stays open**, and the bottom-right button changes to `Requires Open Mailbox` and greys out. Failure is the window closing on you, or the button staying live away from a mailbox.

**32.** Walk back and open the mailbox again. The button reads `Distribute` once more, live if a row is ticked. Failure is the button staying stuck on `Requires Open Mailbox`.

**33.** Drag the window by its title bar to a new spot, close it, and reopen at a mailbox. It comes back where you left it, and survives a `/reload`. Failure is the window snapping back to its default position.

**34.** Look at the section bands in the list. They appear in this order, and only when they have rows under them: **Matched**, **Pending Match**, **Stats Couldn't Be Read**, **Kept**. Failure is a band with nothing under it, or the order changing.

**35.** Hover an item name in a row. The normal game item tooltip appears. Failure is no tooltip, or the wrong item's.

**36.** Hover the recipient control on the right of a row. A tooltip reads `Recipient`, then a line counting candidates and the level range being searched, then `Click to reassign.` Failure is no tooltip, a zero count on a row that plainly has a name, or a nonsense level range.

## Finding recipients

**37.** Press **Find Recipients**. The button immediately greys and reads `Searching...`, then comes back live about five seconds later. Failure is an instant re-enable, or a button that never recovers.

**38.** Watch the mailbox while that query runs. It stays open, and Blizzard's Who window never appears — not during the query and not a few seconds after. Failure is the mailbox closing, or the Who panel surfacing at any point. This is the single most important check in this section.

**39.** After the first answer lands, read the button. While there is still somewhere left to look it reads `Scan Again`; once there is nothing left to search for it reads `Find Recipients`. Failure is the label never changing.

**40.** Press it several times in a row, waiting out each five-second lock. Names accumulate on rows — pressing again never empties the roster you already built. Failure is previously found names disappearing.

**41.** On a guilded character, open the window at a mailbox and wait a moment **without** pressing anything. Guild members can be matched to rows on their own — the guild costs no button press. Failure is guildmates only ever appearing after a `/who`.

**42.** Use the button hard for a while — press it, close and reopen the window, press it again, press it mid-cast. You may not be able to force this deliberately, but if a search is ever blocked, chat prints a plain line telling you to press Find Recipients again, and pressing it again works. Failure is a Lua error popup in place of that line, or a button that goes permanently dead.

**43.** Close the window with the **X** while a search is still running. Nothing appears afterward — in particular Blizzard's Who window must not open by itself a few seconds later. Failure is any window surfacing after you closed ours.

## The recipient dropdown

**44.** Click the recipient control on any row. A list opens with **Keep Item** at the top, then everyone in range with their level, then a divider, then **Find Recipients for This Item** at the bottom. Failure is a missing Keep Item, or a missing bottom entry.

**45.** Read the names. Some carry a short note in grey — `(has one)`, `(refused)`, or `(recent)`. Every one of them is still selectable. Failure is a greyed-out, unclickable name, or a note that has pushed the level off the end of the row.

**46.** Pick a name that another row is already holding — one marked `(has one)`. Your row takes the name, and the row that had it drops back to having no recipient and is re-matched automatically. Failure is the pick being refused, or both rows showing the same person.

**47.** Choose **Keep Item** on a matched row. The row loses its recipient and unticks. Press **Find Recipients** again: that row stays empty — your choice is not overridden. Failure is a new recipient appearing on it anyway.

**48.** Tick the checkbox on a row that has no recipient. The row is thrown back into matching, and picks somebody up if anybody suitable is in range. Failure is the checkbox doing nothing on such a row.

**49.** Open the dropdown on a row in the **Stats Couldn't Be Read** section. Instead of names it says the item's stats couldn't be read, so it isn't matched. Failure is a normal-looking candidate list on an unreadable row.

**50.** Clear the roster (step 23), then open a dropdown. It says there is no one in range and to run Find Recipients. Failure is a blank list with no explanation.

**51.** Press **Find Recipients for This Item** at the bottom of a dropdown. The search button locks for its usual five seconds, and names for that one item can arrive. Failure is nothing happening at all, or a Lua error.

## Distributing

**52.** With no row ticked at an open mailbox, look at **Distribute** — it is greyed out. Failure is a live button with nothing to send.

**53.** Tick a matched row. Distribute goes live. Untick it: greyed again. Failure is the button not tracking the ticks.

**54.** Press **Distribute** with one row ticked. Chat prints how many items are going out and tells you to click Accept on each confirm popup. Blizzard's confirmation appears for a stranger — the add-on never clicks it for you. Failure is mail going out with no confirmation.

**55.** Accept it. Chat prints `Sent <item> to <name> (1/1)`, the row leaves the list, and the run finishes with `Done. 1 of 1 delivered.` Failure is a success message with the item still in your bags. Now repeat and leave the popup sitting untouched for a while first: chat tells you to click Accept and then press Distribute to send the rest, and accepting late still delivers. Failure is a run that hangs silently, or an item lost between the two.

**56.** Tick three rows and Distribute. Each confirmation is handled one at a time, the counter climbs `(1/3)`, `(2/3)`, `(3/3)`, and the run reports `Done. 3 of 3 delivered.` Failure is sends overlapping, a stuck counter, or a run that stalls halfway.

**57.** Before pressing Distribute on a multi-row run, read down the list: no name appears on two rows at once, and taking a name for a second row (step 46) always frees the first rather than duplicating it. Run it and confirm each recipient receives exactly one parcel. Failure is any player getting two letters out of a single run.

**58.** Empty your character of copper and press Distribute. Chat tells you to add a little copper for postage and press Distribute again. Add copper, press again: it sends. Failure is a silent no-op, or a "sent" message with nothing delivered.

**59.** Start a run, then close the mailbox part-way through (walk away or press Escape). Chat tells you to open a mailbox and tick the rows again, and nothing further is sent. Failure is the run carrying on, or the add-on hanging with the Distribute button stuck on "still sending."

**60.** Match a row, then move that item to a different bag slot before pressing Distribute. Chat tells you to press Find Recipients to re-scan and names the item that moved; nothing wrong is sent. Failure is the wrong item going out.

**61.** If you run TSM or another add-on that replaces the mail window, open your mailbox through it and press Distribute. Chat tells you to open Blizzard's own Send Mail panel and try again, and says plainly that nothing was sent or touched — followed by a hint about switching to the default mail UI. Failure is an item being *used* instead of attached (a green raising a level warning, a drink being drunk). Skip this step if you don't run one of those add-ons.

## What a stranger receives

**62.** Have your recipient (or an alt on the same faction) open the mail. The subject reads `Play It Forward!`, the body is the full fixed letter, and the item is attached. Failure is a truncated body, a subject that is the item's name instead, or an empty letter with the item missing.

**63.** In **Diagnostic Tools**, press **Preview What Strangers Receive** and compare it with what actually arrived. They match, and the reported lengths sit under the limits (31 for the subject, 500 for the body). Failure is a preview that differs from the delivered mail, or a length over its limit.

**64.** Look through both the options panel and the mail window for any way to edit the subject or body. There is none — the letter is fixed text. Failure is an editable field anywhere.

## The Given Away tally

**65.** Note the four numbers under **Given Away** — Gifts, Items, Item Levels, Gold Value. Send one green, then look again: Gifts is up by one, Items by one, Item Levels by that item's level, Gold Value by its vendor price. Failure is any counter not moving, or moving by the wrong amount.

**66.** Send a **stack** of consumables — say twenty waters. Gifts goes up by one and Items by twenty; Item Levels does **not** move, because consumables contribute nothing to it. Failure is Items rising by one, or Item Levels rising at all.

**67.** `/reload`, then log out and back in. All four numbers survive. Failure is any counter resetting.

**68.** Log in on a **different character on the same account** and open the panel. The same four numbers are there — the tally is account-wide, not per character. Failure is a fresh zeroed tally on the alt.

## Sharing your totals (town only)

This whole feature is gated on resting: it works in cities and inns and nowhere else. Two of these steps need a second player running the add-on.

**69.** Standing in a city, hover your **own** character. A `Play It Forward // Given Away` block appears at the bottom of your tooltip with the four totals — present even when they are all zero. Failure is no block while resting.

**70.** Ride out into the open world until the resting icon disappears, then hover yourself again. The block is **gone**. Failure is the block rendering outside a rest area.

**71.** Go into a dungeon or a raid with a group and hover a party member. No block on anyone, and no add-on chatter of any kind. Failure is the block appearing in an instance.

**72.** Back in a city with a second Play It Forward player beside you: hover them. The first hover may show nothing — that is expected. Wait a few seconds and hover again: their Given Away block is there. Failure is the block never arriving after several hovers over half a minute.

**73.** Have that player untick **Share My Giving Stats**. Their totals stop updating on your tooltip; an entry you already cached can linger for up to half an hour, so check with a player you have not seen before for a clean read. Meanwhile **you** still see everyone else's, and they still see yours if you left sharing on. Failure is the toggle also blinding the player who turned it off.

**74.** Hover an NPC — a guard, a vendor, your own pet. No Given Away block on any of them. Failure is the block rendering on anything that isn't a player.

## Diagnostic Tools

Everything here is read-only except the taint-log switch. The panel resets to disabled every session, by design.

**75.** Open **Diagnostic Tools**. Only the warning and the **Enable Diagnostic Tools** checkbox are visible, and the box is unticked. Failure is any report section showing before you enable.

**76.** Tick it. The report sections appear. Failure is a partial panel or an error.

**77.** `/reload` and return to the panel. The box is unticked again and the sections are hidden — this setting is deliberately not saved. Failure is it remembering that it was on.

**78.** Enable it again for the rest of this section.

**79.** Press **Export Every Bag Slot**. The box fills with one row per occupied bag slot. Your giveable green is listed as giftable; the soulbound item and the quest item each carry a reason code saying why they were passed over. Failure is an empty export, or an occupied slot missing from it.

**80.** Press **Export Known Players** before running any search: it is empty or nearly so. Run **Find Recipients**, press it again: the players found are listed with what they qualify for. Failure is an export that stays empty after a successful search.

**81.** Shift-click an item into your chat box, copy the link, paste it into the **Item link** field, and press **Explain This Item**. A verdict appears naming the classes the item suits, with both stat readings shown. Failure is a blank report, or an error on a valid link.

**82.** Type a level into **Item required level** and press **Show Armor Groups**, then **Show Weapon Groups**. Each fills the box with the class groupings for that level. **Flavor-sensitive:** on Classic Era, an Alliance character sees no Shaman and a Horde character no Paladin; on TBC Anniversary both classes are present for both factions. Failure is the missing-class list being identical on the two clients.

**83.** Press **Preview What Strangers Receive**. The exact subject and body appear with their character counts. Failure is placeholder text, or counts over the limits.

**84.** Close the mail window, walk away from any mailbox, and press **Force the Window Open**. The window appears centered on screen, and chat reports that it is shown, its size, how many items were scanned and how many are giftable. Failure is no window appearing, or a report claiming it is shown when nothing is visible.

**85.** Press **Check Sharing and Nearby Players**. The report states whether sharing is on, whether you are resting, whether the message prefix registered, your own four totals, and every nearby player heard from with how long ago. Standing in a city the resting line reads yes; out in the world it reads no. Failure is a missing prefix registration, or a resting line that disagrees with your rest icon.

**86.** Press **Start Event Log**, open and close a mailbox, then press **Show Captured Events**. Mailbox events appear in the order they fired. Press **Stop Event Log**. Failure is an empty log after activity, or a log that keeps growing after you stop it.

**87.** Press **Test Event Registration** and then **Test WoW API Endpoints**. Both fill their boxes, and the API check reports no failures on either flavor. Failure is any FAIL line — note which one and on which client.

**88.** Press **Read Display Settings**, **List Installed Add-ons**, **Dump Saved Variables**, and **List Library Versions** in turn. Each fills its own box with plausible content, and the saved-variables dump shows your current settings. Failure is an empty box or an error on any of the four.

**89.** Press **Turn On Taint Log**, read the state line above it, then **Turn Off Taint Log** and watch the line change back. Leave it **off**. Failure is the state line not tracking the buttons. Finally, untick **Enable Diagnostic Tools**: every section hides again.

## Flavor differences to watch

Do not let a pass on Classic Era stand in for the whole add-on. These are the places the two clients genuinely differ:

- **The options panel dock (steps 3 and 9).** The two clients open settings by different routes, and TBC Anniversary is the one where the panel has historically floated free of the Options window instead of docking inside it. With no minimap button, a floating or missing panel leaves a player with no way to reach the settings at all — so this is the single most important flavor check in the plan.
- **Mailbox detection (steps 28–32).** TBC Anniversary reports the mailbox through an extra channel Classic Era does not have. Watch the `Requires Open Mailbox` button on both: walking away and back must flip it in each client.
- **Classes that exist (step 82).** On Classic Era, Alliance has no Shamans and Horde no Paladins, and the add-on will not match items to them. On TBC Anniversary both classes exist on both sides and must appear.
- **Where the search looks.** The two clients search different zone lists. Nothing in the UI names them, but a search that finds nobody on one flavor while working on the other is worth reporting with the Recipient Roster export (step 80) attached.

## Localization spot-check

Optional, and only worth running on a non-English client. The add-on ships English strings only, so English text on a German or Russian client is expected — these steps confirm it falls back cleanly rather than breaking.

**90.** Log in on a non-English client and open the options panel. Every label reads as English words, not as raw keys like `OPTIONS_GIVE_HEADER`, and nothing shows `nil`. Failure is any key name or `nil` leaking into the UI.

**91.** Send one item and read the chat lines. `Sent <item> to <name> (1/1)` and `Done. 1 of 1 delivered.` come out with real item links, names and numbers filled in — no doubled or missing values. If a send fails, the reason in the parentheses is the client's own error text, in the client's language. Failure is a placeholder left unfilled, or numbers in the wrong order.

**92.** Open the mail a recipient received on that client. The subject and body are the full English letter, not cut short. Failure is a truncated body — report the locale if it happens.

## Sign-off

When every step above passes on **both** Classic Era and TBC Anniversary, manual testing is complete and the add-on is ready for `4 - Pre-Launch Review Prompt.md`. A pass on one flavor is not a pass.

| Flavor | Tester | Date | Result |
|---|---|---|---|
| Classic Era (1.15.x) | | | pass / fail |
| TBC Anniversary (2.5.x) | | | pass / fail |

Record any failure as the step number, the flavor, and what you saw instead.
