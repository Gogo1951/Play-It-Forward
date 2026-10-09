# Play It Forward // Technical Reference

This document combines architecture notes and contribution guidance for developers working on Play It Forward. For end-user documentation, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md).

## File Map

```text
Play-It-Forward/
├── .github/
│   └── workflows/
│       ├── ci.yml                Calls Common-Core: Lua 5.1 syntax, luacheck, StyLua and the offline tests
│       └── package.yml           Calls Common-Core: packages and uploads a tagged release
├── .gitattributes                Shared Common-Core file
├── .gitignore                    Shared Common-Core file
├── .luacheckrc                   Lint config
├── .pkgmeta                      Externals and ignore list
├── Play-It-Forward_Vanilla.toc   Classic Era, Season of Discovery included
├── Play-It-Forward_TBC.toc       TBC Anniversary
├── Play-It-Forward_Camelot.toc   WoW Forever
├── Data/
│   ├── Flavor.lua                Canonical: ns.FLAVOR, ns.EXPANSION, ns.IS_DISCOVERY, ns.DATA_FOLDER
│   ├── Data.lua                  Locale init, ns.Data, palette, links, layout grid, shared constants
│   ├── Default-Settings.lua      ns.DATABASE_DEFAULTS
│   ├── Match-Stats.lua           Shared policy: per-talent-tree stat points and the scoring thresholds
│   ├── Match-Armor.lua           Shared policy: armor weights, PROFICIENCY_REACH, universal equip slots
│   ├── Match-Rules.lua           Shared policy: ns.Data.ITEM_RULES
│   ├── Scan-Stats.lua            Shared policy: GetItemStats keys to internal stat tokens
│   ├── Vanilla/                  Classic Era game data; every file opens with the Discovery guard
│   ├── Discovery/                Season of Discovery game data, inverse guard; rides the Vanilla TOC
│   ├── TBC/                      TBC Anniversary game data
│   ├── Camelot/                  WoW Forever game data
│   ├── Wrath/                    No TOC lists it; .pkgmeta keeps it out of the zip
│   ├── Mists/                    No TOC lists it; .pkgmeta keeps it out of the zip
│   └── Mainline/                 No TOC lists it; .pkgmeta keeps it out of the zip
├── Diagnostics/                  Diagnostic Tools framework, copied from Magic Eraser
│   ├── Diagnostics-Core.lua      ns.diagnostics gate and ns.DiagnosticsStrings
│   ├── Manifests.lua             This add-on's surface: API rows, context probes, data sources, name lookups
│   ├── Event-Log.lua             Event buffer and the per-id noise filter
│   ├── Code-Reports.lua          Event Registration, API Endpoints, Library Versions
│   ├── Settings-Reports.lua      Saved Variables, Display Context, Other Add-ons
│   ├── Localization-Reports.lua  Locale Context, Game Names
│   ├── Validate-Data.lua         One report per flavor-folder data file
│   ├── Report-Runner.lua         ns.DIAGNOSTIC_REPORTS, ns.DIAGNOSTIC_SECTIONS, the one-at-a-time runner
│   └── Options-Diagnostics.lua   The panel builder; loads with the Options block
├── Features/
│   ├── Core.lua                  Identity, AceDB lifecycle, ns.on dispatcher
│   ├── Utilities.lua             API aliases, colors, money, ns.QualifyPlayerName, ns.AtMailbox, ns.AtRest
│   ├── Announcements.lua         ns:BuildBrandedLine and ns:PrintMessage; player-only output
│   ├── Scan-Tooltip.lua          Stats read off a rendered tooltip, where random suffixes live
│   ├── Scan-Bags.lua             Bag slot to item record, or nil plus a reject code
│   ├── Match-Derivations.lua     ns.Data answers over the tables: priority groups, weapon keys, rule matching
│   ├── Match-Engine.lua          Eligibility, claim, fit, coverage, rules, the verdict
│   ├── Match-Ranking.lua         Level bands, band groups, candidate ranking
│   ├── Match-List.lua            Items, pools and pairings; rescan, AddResults, the allocator
│   ├── Recipients-Who-Plan.lua   Builds, prunes and exhausts the /who plan; ns.Data.ZonesFor
│   ├── Recipients-Who.lua        Sends one /who per press; throttle, Who panel deafening, parsing
│   ├── Recipients-Guild.lua      Guild roster as a second recipient source
│   ├── Recipients-Fairness.lua   Session cooldown and the unreachable list
│   ├── Mail-Sender.lua           ns.Distributor: one SendMail at a time, event-driven
│   ├── UI-Picker.lua             ns.Picker, the scrolling dropdown list
│   ├── UI-Window.lua             ns.UI: the mail window, top bar, rows and sections
│   ├── UI-Assignment.lua         Row dropdown options, manual picks, row ticks
│   ├── UI-Mailbox.lua            Mailbox open and close, Find Recipients, Distribute
│   ├── Generosity.lua            Account-wide giving tally in global.stats
│   ├── Generosity-Broadcast.lua  Shares the tally with nearby players over YELL add-on messages
│   └── Generosity-Tooltip.lua    A peer's totals at the foot of their unit tooltip
├── Includes/
│   ├── Images/
│   │   └── Play-It-Forward.tga   Icon
│   └── Libraries/                Vendored Ace3 down to AceDBOptions-3.0, nothing else
├── Locales/                      Eleven locales
│   └── enUS.lua                  Source of truth
├── Options/
│   ├── Options-Utilities.lua     Shared ns.Options* widget constructors
│   ├── Options-General.lua       The root panel
│   ├── Options-Profiles.lua      Stock AceDBOptions-3.0 table
│   └── Options.lua               Registration, ns:OpenOptionsPanel, /pif
├── Tests/                        Offline suite on Lua 5.1: 28 cases plus Run, Harness and Stub-WoW-API; never ships
├── LICENSE                       MIT
├── README.md                     Player documentation
├── README-Notes.md               Maintainer's settled exceptions and decisions
├── README-Technical.md           This document
├── README-Testing.md             Manual test plan
└── Suffix.md                     Random-enchantment reference; development only, never ships
```

**Files that must not come back.** There is no mini-map button, so `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are deliberately absent. The diagnostics panel lives in `Diagnostics/Options-Diagnostics.lua`, never `Features/Diagnostics.lua` or `Options/Options-Diagnostics.lua`. The universal `Data/Match-Weapons.lua`, `Data/Recipients-Zones.lua`, `Data/Scan-Food.lua` and `Data/Scan-Potions.lua` are replaced by their per-flavor copies; game data never returns to a file every client loads.

**Each client loads one data folder.** Every flavor folder holds the same eight files, suffixed with the folder name, and declares the same thirteen tables: `Match-Stat-Budget` (`STAT_BUDGET`), `Scan-Food` (`FOOD_AND_WATER`), `Scan-Potions` (`POTIONS`), `Scan-Scrolls` (`SCROLLS`), `Recipients-Zones` (`ZONES`, `ZONE_COLUMNS`), `Match-Weapons` (`WEAPON_SUBCLASS`, `RELIC_SUBCLASS`, `WEAPON_CLASS_ORDER`, `WEAPON_SPECS`), `Match-Armor` (`ARMOR_SUBCLASS`, `NATIVE_ARMOR`) and `Match-Classes` (`FACTION_CLASSES`), all under `ns.Data`. Each TOC lists its own folder only. The Vanilla TOC lists `Data/Vanilla/` then `Data/Discovery/`; Vanilla files open with `if ns.IS_DISCOVERY then return end` and Discovery files with the inverse, so exactly one set builds. The matching policy that reads those facts (talent-tree weights, item rules, the stat-name map) stays in shared `Data/` files every flavor loads, per the README-Notes exception.

`Suffix.md` and `Tests/` are development-only: no TOC lists them and `.pkgmeta` ignores both.

## Architecture

### Event Loop

`Features/Core.lua` owns the add-on's one event frame and one entry point, `ns.on(event, fn)`. A feature file never creates its own frame, because one would bypass the Diagnostics event log. `ns.EVENT_NAMES` is filled as events register rather than declared up front, since registration is flavor-conditional, so the Event Registration report tests exactly what this client took.

| Event | Registered in | Purpose |
|---|---|---|
| `ADDON_LOADED` | `Core.lua` | Name-guarded. Creates `PlayItForwardDB`, runs the dated migration, wires `ns:ApplyProfile` to the profile callbacks, calls `ns:RegisterOptionsPanels`. |
| `PLAYER_LOGIN` | `Core.lua` | Welcome print, when `profile.showWelcome` is on. |
| `PLAYER_LOGIN` | `UI-Mailbox.lua` | Hooks `MailFrame` `OnShow` (opens the mailbox flow) and `OnHide` (rechecks Distribute). |
| `MAIL_SHOW` / `MAIL_CLOSED` | `UI-Mailbox.lua` | Mailbox open and close, every flavor. |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `UI-Mailbox.lua` | The same signal, filtered to `Enum.PlayerInteractionType.MailInfo`. Not registered on the Vanilla TOC. |
| `BAG_UPDATE`, `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Mark the bag scan stale; see Debounced Bag Scanning. |
| `WHO_LIST_UPDATE` | `Recipients-Who.lua` | Parses a `/who` answer under `pcall`, ends the query, prunes exhausted attempts, hands results on. |
| `ADDON_ACTION_BLOCKED` | `Recipients-Who.lua` | Our own blocked `SendWho` only: prints an explanation instead of leaving silence. |
| `MAIL_SUCCESS` / `MAIL_FAILED` | `Mail-Sender.lua` | Advance the send queue. |
| `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | A refusal the server reports without either result event. |
| `GUILD_ROSTER_UPDATE` | `Recipients-Guild.lua` | Delivers a roster the add-on asked for; ignored with no request outstanding. |
| `CHAT_MSG_ADDON` | `Generosity-Broadcast.lua` | A peer's tally or a ping. Own prefix only. |
| `PLAYER_ENTERING_WORLD` | `Generosity-Broadcast.lua` | Broadcasts presence; the broadcast throttle absorbs the refire on every loading screen. |
| `PLAYER_UPDATE_RESTING` | `Generosity-Broadcast.lua` | Entering a rest area fires no loading screen, so this is what announces arrival in town. |

The dispatcher logs before it calls handlers, behind one boolean read: `if ns.diagnostics.logging then ns:LogEvent(event, ...) end`. Diagnostics off costs nothing, and an entry survives a handler that errors. `ns.diagnostics` is created in `Diagnostics/Diagnostics-Core.lua`, which loads after `Core.lua`; that is safe only because no registered event fires before every file has loaded.

Two places touch event registration outside `ns.on`, and both are deliberate: the Event Registration report's throwaway probe frame (`Diagnostics/Code-Reports.lua`), and the Who panel deafening in `Recipients-Who.lua`, which unregisters and re-registers Blizzard's own frames.

### Combat Lockdown

Only the options opener refuses in combat. `ns:OpenOptionsPanel` (`Options/Options.lua`) checks `InCombatLockdown()` as its first statement, prints `L["CHAT_OPTIONS_IN_COMBAT"]` and returns. It never queues and never registers `PLAYER_REGEN_ENABLED`: a silent deferral reads as a broken command, and the Settings panel is protected in combat, so without the gate the player gets an `ADDON_ACTION_BLOCKED` error naming the add-on. Nothing else in the add-on defers for combat. Mail and `/who` both run only at a mailbox, from a button press.

### Scan, Match, Search, Send

1. **Scan.** `Features/Scan-Bags.lua` walks bags 0 to 4 (`NUM_BAGS`, no reagent bag). `Scanner:Classify` returns a finished record or `nil` plus a reject code. The sixteen codes (`NOT_CACHED`, `KIND_DISABLED`, `NO_USE_LEVEL`, `LEVEL_GAP`, `BIND_ON_PICKUP`, `ABOVE_MAX_RARITY`, ...) are diagnostic identifiers, never shown to players; they exist so "why isn't this item listed" has an answer in the Bag Scan report. Each record's `uid` is `"bag:slot:link"`. Stats come from `GetItemStats` and from `Features/Scan-Tooltip.lua`, merged by taking the **max** per stat (see Item Data Caching).
2. **Match.** `Features/Match-Engine.lua` computes one `verdict` per item: `eligible`, `admitted` and `contenders` classes, per-class `claims`, `fits` and `coverage`, and a state of `gift`, `leftover` or `unreadable`. `Features/Match-Derivations.lua` answers the table questions it needs (priority groups, weapon keys, rule matches) and `Features/Match-Ranking.lua` turns a verdict into level bands and ranked candidates. Everything downstream reads the cached `item.verdict` rather than recomputing.
3. **Search.** `Features/Recipients-Who-Plan.lua` builds a plan of `/who` attempts from the items' bands; `Features/Recipients-Who.lua` sends one per button press. `Features/Recipients-Guild.lua` adds the guild roster without a press. Both feed `MatchList:AddResults`.
4. **Send.** `Features/Mail-Sender.lua` (`ns.Distributor`) walks a job queue, one `SendMail` at a time, waiting for a result event before advancing.

`Features/Match-List.lua` holds the shared state (`items`, `pools`, `assignedTo`) at file scope and runs the allocator. `Features/UI-Window.lua` draws it, `Features/UI-Assignment.lua` takes the player's manual choices, and `Features/UI-Mailbox.lua` drives the mailbox lifecycle. The TOC order `UI-Picker`, `UI-Window`, `UI-Assignment`, `UI-Mailbox` is load-bearing: each captures what the one before it created.

### Debounced Bag Scanning

`BAG_UPDATE` fires on every loot, sale and stack merge; `GET_ITEM_INFO_RECEIVED` fires once per item against a cold cache. Neither scans directly. `scanSoon` sets `bagsDirty` and returns at once unless `wouldRescan()` holds: the database exists, no distribution run is busy, and the window is shown. Only then does it arm a `SCAN_DEBOUNCE` (2s) timer, which re-checks the same test when it fires, because the window can close inside the debounce, and then scans and refreshes. Away from a mailbox the flag stays set and the next `mailboxOpened` pays for one scan when the answer is needed. `MatchList:WouldRescan()` exposes the same test so the event log classifies these two events with it.

### Item Data Caching

`C_Item.GetItemInfo` returns `nil` for an item the client has not resolved. The scanner rejects that slot as `NOT_CACHED` instead of treating it as empty, and `GET_ITEM_INFO_RECEIVED` marks the scan stale so the next pass re-reads it. Without that a cold cache reads as an empty bag and the window declines to open.

Stats are read twice and merged by the max per stat, never the sum. `GetItemStats` resolves the base item and returns nothing for a random suffix; the tooltip renders the item as the player sees it. Both report the same number on a fixed-stat item, so a sum would double it. `record.statRead` keeps each source's own answer for the Item Verdict report.

`MatchList:Candidates(item)` caches the ranked recipient list on the item as `_candidates`, stamped with `_candidatesGeneration` against `poolsGeneration`. Ranking is asked for once per allocation pass, once per dropdown open and once per mouse-over of a recipient button, and walks every admitted class against every pooled player. The generation bumps in exactly one place, `AddResults`, and only when a pool entry changed: a new player, a known one now flagged `guild`, or one seen at a higher level. `rescanBags` needs no bump because it replaces every item table. Ranking never reads `item.recipient`, so an assignment cannot stale the list. **The list is handed out by reference**; a caller that sorts or removes in place poisons it for every later caller. Derived per-item fields carry a leading underscore (`_weaponKey`, `_candidates`) to keep them out of the record's public shape.

## Scoring: Claim, Fit and Coverage

Three numbers per class per item answer three different questions, and the separation is load-bearing.

**Where the weights come from.** The recipient's spec is unknowable, so `Data/Match-Stats.lua` writes each talent tree as the player levelling it: a stat the tree builds around is worth 2, one that helps it 1, and a class weight is the sum over its three trees (0 to 6). Agility is main to all three rogue trees and sums to 6. Four sums are held at 2 on purpose, so the class is admitted but never leads: rogue Strength, hunter Intellect, priest Spirit, warlock Stamina. Feral is one druid tree with Strength, Agility and `FERAL_AP` all main. Nobody levels on Defense, so defensive stats weigh nothing. `SPELL_POWER` is derived per tree as the better of its damage and healing points.

**Every stat is read through its budget first.** `ns.Data.StatPoints` multiplies a stat's tooltip number by the flavor folder's `ns.Data.STAT_BUDGET` before any weight touches it. Classic writes "+1% crit" as 1 beside "+10 Strength", so read raw a percentage could never decide an item; Vanilla's budget makes 1% crit worth 14 points. TBC's ratings need no conversion.

- **Claim** (`Matcher:SpecScore`): only the stats the point tables rank for that class. Decides who is *admitted*.
- **Fit** (`Matcher:Score`): claim plus `ns.Data.UNIVERSAL_WEIGHTS` (empty) and `WEAPON_BASELINE` (0.15 times item level), which keeps a statless weapon placeable. Decides *ranking*.
- **Coverage** (`Matcher:Coverage`): the share of the item's scoreable stats this class ranks at all, 0 to 1. Decides *breadth*.

Coverage exists because a score sums, so breadth loses to one large weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0, a tie the warrior would win with half the item dead on him. A class enters contention by clearing both `CLASS_SHARE` (0.35 of the best claim) and `COVERAGE_MAJORITY` (strictly more than 0.5). Failing either leaves it admitted: in the dropdown, and a fallback when nobody better is in range.

The coverage denominator is every stat some class ranks, not the item's own stat line. Adding a stat weight is therefore never only a scoring change: it enlarges the denominator on every item carrying that stat and can demote a class out of contention.

**Coverage abstains when it demotes everyone.** It is a relative test, so a field where nobody clears the majority carries no information (an Agility and Spell Power roll leaves rogue and mage at 0.5 each). `Verdict` then falls back to everyone who cleared `CLASS_SHARE` alone. An item with nothing scoreable returns coverage 1, not 0: those are placed by the weapon baseline, and 0 would bin them all.

**Faction filters the class list.** `ALL_CLASSES()` in `Match-Engine.lua` keeps only the classes `ns.Data.FACTION_CLASSES` lets the player's faction roll, so a class nobody in reach can be never wins a tie. It is memoized only once the faction is known; an unknown faction gets every class. Its source list, `EVERY_CLASS`, stops at the death knight, so a later class added to a flavor's `FACTION_CLASSES` does nothing until it is added there too.

### Verdict States

`gift` and `leftover` split at `ns.Data.LEFTOVER_THRESHOLD` (1.0); an item with no admitted class is always a leftover, and so is statless armor that is not a weapon, shield, held off-hand or relic, since only the weapon matrix can place an item with no stats. `unreadable` exists because an item whose random suffix failed to parse looks exactly like a worthless one, and telling a player to vendor an item nobody evaluated cannot be undone. An item is `unreadable` when it carries a suffix id and nothing parsed. Unreadable items are held out of auto-assignment entirely.

## Item Rules

The point tables rank one stat at a time and cannot say that a *pair* of stats means something neither says alone. `Data/Match-Rules.lua` holds that layer as `ns.Data.ITEM_RULES`; `Features/Match-Derivations.lua` does the matching. A rule matches on exactly one of: a `weapon` key list, a consumable `form` plus `restores`, or a stat list `requires` (optionally `exclusive`, optionally narrowed to body `armor` of a material). `matches` tests weapon, then consumable, then stats, and stops at the first it finds.

| Verb | Effect | Timing |
|---|---|---|
| `veto` | Removes the class outright. The only absolute verb. | Before anything is scored, so a vetoed class is gone from every answer downstream. Skipped for consumables. |
| `prefer` | Names the contenders, replacing what scoring chose. | After scoring, narrowed to classes already admitted. **First match wins.** |
| `demote` | Drops the class out of contention, keeping it admitted as a fallback. | After `prefer`, so no rule can promote a demoted class back. Accumulates across every match. |

**Rules are soft by design.** A rule decides who is in contention, not who is admitted, so an "of the Owl" staff still reaches a hunter when nobody else is in range. The one `veto` is Spirit against warlocks: it must outrank the Intellect a warlock genuinely wants, or "of the Owl" buys him back in through that half.

`prefer` being first-match-wins makes table order data: cloth healing gear with Intellect and Spirit (the priest rule) and Agility, Intellect and Spirit together (the caster rule) can both match. The first matching `prefer` is used even when nobody it names is admitted, in which case it changes nothing and still blocks every `prefer` below it.

`unclaimed = true` is a condition, not a verb: the rule applies only when no eligible class had any stat claim (the case `Verdict` calls `offerToEveryone`, where a statless weapon is placed by its baseline). It pairs with `prefer` or `demote`, never with `veto`, which runs before anything is scored. One rule uses it: an unclaimed bow, gun or crossbow is the hunter's. A stat-bearing ranged weapon is still decided by its stats, which is why the condition is "unclaimed" and not "ranged". Consumables take `prefer` and `demote` with no claim context, so `unclaimed` never matches one.

`applyDemotion` falls back through the scoring, not past it: contenders, then the scoring's own answer, then the admitted list, first non-empty wins. Reaching straight for the admitted list would promote the classes coverage just demoted. The last resort exists for heavy armor carrying Intellect too far below its material's training level for `PROFICIENCY_REACH` to reach the hunter or shaman it was itemized for, which leaves only the warrior; that case is why the Intellect rule is a `demote` and not a `veto`.

**`exclusive` counts ranked stats only.** Armor and resistances sit on half the items in the game and are unweighted, so counting them would make a bare Stamina ring qualify for the Stamina-alone rule where a bare Stamina chest did not.

**What a rule cannot see.** `restores` matches `def.restores` only, so no rule can key on a scroll's `buffs`. `weapon` rules require `classID == 2`, so shields, held off-hands and relics never match them. `armor` rules exclude cloaks, rings, necks and trinkets (`UNIVERSAL_EQUIP_LOC`).

## Recipient Ranking

`Matcher:RankCandidates` (`Features/Match-Ranking.lua`) orders the pooled players of the verdict's **admitted** classes, each filtered against its own class's level band. The keys, in order:

```text
fit bucket -> level proximity -> armor/weapon group -> class fit -> guild -> shuffle -> name
```

Bucket leads, so a class that wants the item beats one that barely does however close to equipping it they are. Level comes before group, so a druid one level off beats a mage two off for cloth. The guild flag sits last before the coin flip: it never takes an item from somebody it suits better, but it decides often, since two players of one class at one level reach that line with nothing between them.

**The band runs below gear and above consumables.** Gear anchors to the top: `[equipLevel - LEVEL_GAP_WIDEST, equipLevel - LEVEL_GAP_CLOSEST]`, which is 2 and 1, so a level 19 sword goes to an 18 over a 17 and never reaches a 19. It arrives just before it becomes useful. A consumable anchors to the bottom, its own use level, with a band `CONSUMABLE_RECIPIENT_GAP` (2) levels up, so a potion goes to whoever drinks it now. `LEVEL_GAP_WIDEST` must stay above `LEVEL_GAP_CLOSEST`; equal values collapse the band to one level. `CONSUMABLE_RECIPIENT_GAP` is not `profile.consumableLevelGap`: that is the sender's threshold for when their own potion counts as spare.

**The band is per class, not per item.** `Matcher:LevelBand(item, class)` measures back from the level that class could first equip the item. `item.bandLo` and `item.bandHi` are the union across classes and exist for the tooltip and the reports only.

The `shuffle` tail is rolled once per player as they enter the pool, never inside the comparator: `table.sort` throws on a comparator that changes mid-sort. Without it every spare green goes to whoever is early in the alphabet.

**One recipient floor, in one place.** `ns.Data.MIN_RECIPIENT_LEVEL` (5) is enforced only in `MatchList:AddResults`, the door every source comes through, so a source added later inherits it. Levels 1 to 4 are where bank and profession alts sit. Turned-away players are counted before the dedupe.

**Fairness is a session cooldown.** `Features/Recipients-Fairness.lua` records each gift as `name -> { level }` in a file-local table, so every login starts it empty. A recipient is fresh again once seen at a higher level than when last gifted. `Fairness:PickFrom` makes two passes over the ranked list: the first candidate who is free, reachable and fresh, then the first who is merely free and reachable, so an item is never stuck for want of a fresh face. Unreachable means the server refused mail to that name this session (`Fairness:MarkUnreachable`).

### Armor Proficiency Reach

`ns.Data.NATIVE_ARMOR` rows are steps, `{ from level, armor worn }`, read through `ns.Data.NativeArmorAt`. A hunter trains mail at 40, and Blizzard itemizes the level 35 to 39 mail for the classes that train it at 40, so a level gate that meant "cannot wear this yet" must not also mean "is not who this is for". A later training level therefore moves the band instead of closing the door: `ns.Data.ArmorEquipLevel` answers the item's own requirement or the class's training level, whichever is later, and the priority group is computed there. A level 36 mail belt is searched for at 38 to 39 for the hunter and 34 to 35 for the paladin; `Matcher:BandGroups` splits the classes into one group per band and `Who:Plan` takes them as separate attempts.

`ns.Data.PROFICIENCY_REACH` (5, `Data/Match-Armor.lua`) bounds it: an item further below the training level than that is ineligible outright, because a level 20 mail belt is no gift to somebody who first wears mail at 40. Training levels are probed off `NATIVE_ARMOR` (up to `MAX_PROBE`, 80) and never listed a second time. The armor group is the class's native `ARMOR_WEIGHT` minus the item's, plus one (cloth 1 to plate 4).

Weapons have no reach. Each `ns.Data.WEAPON_SPECS` row gives, per class in `WEAPON_CLASS_ORDER` order, how many of the three trees build around that weapon: 0 means the class cannot receive it, and the priority group is 4 minus the count. Count a column against `WEAPON_CLASS_ORDER`, never a padded legend, which StyLua leaves to drift. `Match-Derivations.lua` reads `WEAPON_CLASS_ORDER` at load, so it must load after the flavor's `Match-Weapons` file. Relics (librams, idols, totems) are armor with no material, so `RELIC_SUBCLASS` gives each relic subclass a weapon key and its `WEAPON_SPECS` row names the one class that can equip it; left to the armor path, a relic was offered to whoever its stats suited, a Stamina idol to a warlock.

## Allocation

`MatchList:Assign()` rebuilds every unpinned pairing from scratch on each pass, against the whole roster. A row is `pinned` when the player chose a recipient, kept the item, or unticked it, and the allocator never rebuilds over a pin.

Items are handed out **scarcest first, then best first**. One item per person per pass makes this an allocation problem: an item two people can receive must pick before one fifty can, or the broad item takes one of the two and the narrow one gets nobody. An item nobody can receive sorts last; zero is the impossible case, not the scarcest.

When the pass leaves no gift still searching, `ns.Who:Clear()` drops the plan; otherwise `ns.Who:Prune` narrows it. **Still searching means unmatched or held only by a fallback.** A pairing with a class outside the verdict's contenders keeps that item's band on the plan, narrowed to the contenders, and because every pass re-decides, a contender found later takes the item off its fallback. A pinned row ends the search for that item.

**Every row starts ticked, and a tick means give this away** (README-Notes). The tick does not pin, so a fallback stays provisional. Unticking is the player's keep and pins the row; it keeps any name it held so a re-tick restores it, and no search, pass or rescan re-ticks it. `rescanBags` carries `send` and `pinned` across by slot; a ticked row that loses its recipient to another row comes back unpinned. Ticking a bare row unpins it and runs the allocator; ticking a row with a name keeps it pinned. A row whose name the server refused keeps its tick and returns to auto-assignment.

## /who Search Planning

`C_FriendList.SendWho` is hardware-event gated. A call outside a real click raises `ADDON_ACTION_BLOCKED` and does nothing: no error, no `WHO_LIST_UPDATE`. Queries cannot be chained on a timer, so every press has to be spent well. `Recipients-Who-Plan.lua` builds and maintains the plan; `Recipients-Who.lua` sends it.

**One class filter per query, never a list.** The client honors one `c-"..."` and silently drops the rest of an OR'd set (verified on Classic Era 1.15.9: `c-"Paladin" c-"Rogue" c-"Warrior"` answered with paladins alone). A zoned query carries a class filter only when exactly one class is wanted, and the per-class stage asks one class per query. A class list naming every class sends no `c-` filter and skips the per-class stage. Multiple `z-` filters are kept as a best effort: if the client honors only the first, the query still answers correctly from that zone.

The main button's plan, per span:

```text
52-57
52-57 c-"Warrior"
52-57 c-"Paladin"
52-57 z-"Felwood" z-"Winterspring"
```

Bare first, because a press is worth up to 50 people and the bare query is the most likely to fill it; somebody in a capital opens a parcel as well as somebody questing. Bands are folded into one span while the merged span stays within `SPAN_MAX` (6) levels from its first band's low end: an item's band is two levels wide, so gear for 52, 53 and 56 would otherwise cost three presses. Folding unions the classes, and a band wanting any class makes the whole span class-free. Wider than that and the 50-result cap thins each band's share. Spans are interleaved rather than run to exhaustion, so a level 15 cloak and a level 45 sword both make progress.

**An answer under the cap ends what it answered.** `Who:Exhausted` drops every planned attempt inside the same levels with the same or a narrower class filter, zoned attempts included. "Capped" is `raw >= WHO_RESULT_CAP (50) or total > raw`, reading the server's own total from `GetNumWhoResults`. A zoned answer never exhausts anything, since the client may have honored only its first zone; nor does an answer that failed to parse.

`FILTER_MAX` (240) is a hard budget on the filter string: over it the server does not answer at all, so zone lists are chunked to fit. A chunk is never empty; a zone whose name alone exceeds the budget still gets its own query.

**Zone order decides how many presses a search takes.** `ns.Data.ZonesFor` (in `Recipients-Who-Plan.lua`, not `Data/`) sorts on overlap with the band, then centrality (how close the band sits to the middle of the zone's range), then the narrower zone. The edge of a zone's range is where people pass through; the middle is where they sit and quest. An unresolved faction admits every zone: over-including costs one empty query, excluding on nil drops half the list.

**`Who:Prune` only ever removes.** It narrows a running plan to the bands that still have somebody to find. Re-planning through `Who:Plan` would rebuild from the best-first attempt and re-send it, so a search re-planned on each press would never get past its first zone. A survivor's classes are intersected with what the remaining bands want, and an empty intersection drops the attempt rather than sending it wider than before. An attempt with no class filter survives while any band overlaps it.

**A settings change re-plans.** `UI:Rescan` feeds the freshly merged bands to `Who:Plan` before assigning, so a raised rarity cap searches for what is on the list now. Found players are kept; only the places left to look are rebuilt. `Who:Plan` and `Who:Clear` both cancel whatever query is pending.

**Find Recipients for This Item** plans with `Matcher:TargetedBands` and `targeted = true`: zones first, then per class, then bare, with no folding, because a bare query is what the main button already sent. A lone contender becomes a query naming it over its own band and zones (`38-39 z-"..." c-"Hunter"`). Two or more contenders share their group with fallbacks of the exact same band, since a query with two class filters is a query with none. Other fallbacks keep their own group a press later. It retasks the shared plan; the main button keeps stepping it while `Who:Remaining()` is above zero, and rebuilds the full plan once it is empty.

**Timing.** `WHO_THROTTLE` (5s, exposed as `Who.THROTTLE` and read by `UI:_lockFindButton`) runs from the send, not the answer: a reply often lands in under a second, and re-enabling then offers a press the server refuses for four more. `RESULT_TIMEOUT` (6s) puts an unanswered query back on the front of the plan, since a blocked call never fires `WHO_LIST_UPDATE`. `Who:Step` returns `false, 0` while any job is pending.

**The Who panel is deafened for the life of each query.** The stock UI opens the Who panel on `WHO_LIST_UPDATE` when results route to the UI list, and the panel is a UIPanel: opening it over the mailbox makes the panel manager close `MailFrame`, which ends the mailbox interaction. `beginQuery` unregisters `WHO_LIST_UPDATE` from `FriendsFrame` and `WhoFrame` and sets `SetWhoToUi(true)` so `GetWhoInfo` can read the answer; `endQuery` re-registers exactly those frames, restores `SetWhoToUi(false)`, and hides the panel only if it was not already open when the query began. A query the player abandoned is marked `canceled`, never dropped, so its answer still lands and still runs `endQuery`; a canceled job gets no callback, no `Exhausted`, no requeue on timeout, and is not counted by `Who:Remaining`.

A capped answer is counted and otherwise ignored: the search stops once somebody in contention holds each item. The Recipient Roster report reads the count, because a capped answer separates a thin realm from a thin sample.

**Other-faction results are dropped.** Forever answers `/who` with both factions, and mail does not cross them. A result carries only its localized race, so `Recipients-Who.lua` builds a race-name to faction table from `C_CreatureInfo.GetRaceInfo` and `GetFactionInfo` (race IDs 1 to 100). A race it cannot place, or one two factions share, is kept: a wrong drop loses a recipient for good, a wrong keep costs one refused send. Female race names differ from the male ones `C_CreatureInfo` gives in esMX, ptBR and ruRU, so a female character of the other faction can get through there; the mailer skips that recipient without counting the refusal toward its abort. Drops are counted in `counts.otherFaction`.

## The Guild Roster

A second recipient source, and on most realms the larger one: no button press, no throttle, the whole guild at once. `Features/Recipients-Guild.lua` feeds `MatchList:AddResults` in the shape `/who` results arrive in, so nothing downstream knows the source except the `guild` flag that earns the ranking tiebreak.

`Guild:Request` is gated on a callback. `GUILD_ROSTER_UPDATE` fires on every login, logout, note edit and rank change in a large guild, and walking hundreds of rows with a `GetGuildRosterLastOnline` call apiece is work nobody asked for, so with no request outstanding the event is ignored. A second request overwrites the pending callback. The roster is pulled when a fresh plan starts, never for a targeted search.

Rows are dropped by four checks, each counted separately so "the guild added nobody" and "the guild has nobody active" can be told apart:

- **Unreadable row** (no name or no class token): discarded, as the `/who` parser does.
- **Your own characters**, at any level or recency.
- **Summoning alts**: a `WARLOCK` at levels 20 to 23, around where Ritual of Summoning unlocks. This rule is the roster's alone; the same character found by `/who` is out in the world and playing.
- **Inactivity**: not seen within `Guild.ACTIVE_DAYS` (3). `GetGuildRosterLastOnline` returns nothing for a member online now and four duration parts (years, months, days, hours) otherwise; the test is `years == 0 and months == 0 and days < 3`. An offline member with no reading counts as too old, because the roster arrives in pieces and guessing "recent" mails gear to somebody who quit.

There is no level floor in this file; `MIN_RECIPIENT_LEVEL` in `AddResults` covers every source.

**Own-character detection reads `ns.db.sv.profileKeys`**, AceDB's record of every character that has loaded the add-on, keyed `"Character - Realm"`, plus the current character from `UnitName`. That table lives on `db.sv`, not `db`: AceDB's metatable resolves only scope names, so `ns.db.profileKeys` reads `nil` and the check silently passes everybody. An alt that has never run the add-on is not caught; that is the honest limit.

**Identity is not the address.** The roster and `/who` can spell one same-realm character differently, one bare and one suffixed `-Realm`, so every identity comparison (own-character keys, the `AddResults` dedupe) goes through `ns.QualifyPlayerName` (`Features/Utilities.lua`) on both sides. The pool entry keeps the name exactly as an API produced it, because that is what `SendMail` takes. Pooling one person twice means mailing them twice, since `assignedTo`, the cooldown and Distribute's own guard all key on the entry's name. Never filter on the suffix: Classic realms are connected, so every name in reach is mailable.

## Mailing

`SendMail` cannot be looped. One send goes out, then the run waits for a result event. Mailing a non-friend arms Blizzard's confirmation popup, the anti-spam guard for mailing strangers, and it is never auto-clicked.

Three ordering constraints, all load-bearing:

- **Check the Send Mail panel before touching the item.** `UseContainerItem` attaches only while Blizzard's panel is visible; with it closed the same call *uses* the item, so a consumable is drunk. The sender forces `MailFrame` open on the Send tab (`MailFrameTab_OnClick(nil, 2)`, under `pcall`) and gates on `ns.AtMailbox()`.
- **Fill the panel after the attach.** Attaching writes the item's name into an empty subject box, so a subject set earlier is overwritten.
- **Never re-read the bag slot to verify delivery.** `MAIL_SUCCESS` fires before the bag update, so the slot still holds the old link. The stack size is captured as `job._count` before the send for the same reason.

An attach can fail with the panel up, and `SendMail` will then post an empty letter and report success, so `GetSendMailItem(1)` is checked before every send. Each queued item's link is compared with its bag slot first; a moved item is skipped as `MAIL_ITEM_MOVED`. `UseContainerItem` and `SendMail` run under `pcall` so a throw cannot leave `busy` stuck. On Era the body box is `MailEditBox:GetEditBox()`, since `SendMailBodyEditBox` is nil there. Postage is checked against `MAIL_COST` (30 copper).

**A send with no answer pauses rather than fails.** Each send arms a `RESULT_TIMEOUT` (30s, the mailer's own constant) because the confirmation popup can sit unanswered. When it fires the job moves to `_awaiting`, `busy` clears, and the player is told to Accept and press Distribute again. `SendMail` has already gone out, so a late Accept still delivers, and `Distributor:_result` records it on a run that has stopped. `Distributor:Stop` holds an in-flight job the same way. The held job lives until the next Distribute press (`Start` clears `_awaiting`). Closing the mailbox stops the run outright.

`UI_ERROR_MESSAGE` is watched because the server can refuse a send without either result event. The match set is built from the client's own `ERR_MAIL*` globals, skipping strings with a format specifier (they arrive already filled in), plus `ERR_PLAYER_WRONG_FACTION` by name, which lacks the prefix and is what mailing an other-faction player returns on Forever. `ns.Distributor:IsMailError` is that test, exposed so the event log filter calls it rather than restating it. A refused name goes on `Fairness:MarkUnreachable` for the session. After a failure the run waits `FAILURE_SETTLE` (1s) so a second signal for the same refusal is absorbed instead of landing on the next parcel. The run aborts after two consecutive counted failures; wrong-faction refusals skip that recipient and never count. `_finish` triggers a Generosity broadcast.

`UI:Distribute` sends one parcel per person per run (`MAIL_ALREADY_HAS_ONE` otherwise). The subject and body are fixed text, `L["MAIL_SUBJECT"]` and `L["MAIL_BODY"]`, never saved settings, so what a stranger receives cannot drift per profile. `Distributor:WarnIfOversized` checks them against `SUBJECT_MAX` (31) and `BODY_MAX` (500) at the start of every run, measured in bytes with `#`.

## The Mail Window

The window (`PlayItForwardMailFrame`, `Features/UI-Window.lua`) opens at the mailbox when the scan found something to act on, and never auto-closes. Items, roster and pairings live at file scope in `Match-List.lua`, so matches survive walking away. It anchors beside `MailFrame` until dragged; a drag saves `profile.windowPos`, and its `point` field is what says the player moved it.

**The top bar mirrors the options panel**, writing the same profile keys. Consumables leads on the left, its tick and Level Rule dropdown on one line with the Food, Drink, Potions and Scrolls ticks beneath; Gear sits on the right with its rarity dropdown against the window edge (README-Notes). A dropdown hides while its tick is off; the kind ticks disable and dim instead, so the row keeps its shape. Each tick's tooltip is the panel's own description. Both dropdowns come from one `buildDropdown` and open `ns.Picker`. `UI:_syncControls` is the one place the bar is redrawn from the profile, called by the ticks, the panel's setters and `ns:ApplyProfile`, and a tick also calls `NotifyChange` so an open panel redraws.

Rows sort into four sections (matched, pending match, unreadable, kept), then by score, then bag order, because the list outgrows the window and the rows worth acting on would fall below the fold. Find Recipients and Distribute share one width, the widest of their labels capped at half the frame, so the bar does not jump as labels change. Distribute is disabled away from a mailbox and enabled only when a ticked row has a recipient.

**A row's dropdown** (`UI:_pickerOptions` in `UI-Assignment.lua`) opens with **Keep Item**, which pins the row unticked, then every ranked candidate, then a divider and **Find Recipients for This Item**. Every candidate can be picked. The notes beside a name (refused, has one, recent; one per name, in that precedence) are information, never gates: the player's pick is never refused. Picking a name that holds another row takes it from that row, which returns to auto-assignment unpinned. `_pickerOptions` and `_pickerSelect` are frame-free so `Tests/Manual-Assignment.lua` can drive them.

**Escape closes the window** through `UISpecialFrames`, which only calls `Hide`. Everything that must stop on a close (the picker, a running distribution, the query plan) hangs off the frame's `OnHide` through `UI:_onClosed`, which `UI:Close` also calls for a window never shown. Every line of it is idempotent, since the X button runs both routes. Closing keeps the pairings.

**Never hook `MailFrame`'s `OnHide` to close the window, and never gate on `MailFrame:IsShown()`.** Mail-replacement add-ons hide `MailFrame` and show their own, and the Who panel can swap it out mid-query. `ns.AtMailbox()` asks `C_PlayerInteractionManager.IsInteractingWithNpcOfType(MailInfo)` and falls back to the add-on's own `ns.mailboxOpen` flag.

`ns.Picker` (`UI-Picker.lua`) is one shared popup: a full-screen click-catcher at `DIALOG` strata, the list above it, clamped between `PICKER_MIN_WIDTH` (190) and `PICKER_MAX_WIDTH` (360) wide and scrolling past `PICKER_MAX` (240) tall. Wider than that and `SetClampedToScreen` pushes the list back over its own button. Width is measured with a hidden ruler font string, because a font string anchored on both sides reports the width it was given. On Era `TooltipBorderedFrameTemplate` draws no fill, so a background texture is added rather than `SetBackdrop`, letting skins win.

## The Giving Tally

`Features/Generosity.lua` keeps what this account has given away in `ns.db.global.stats`: `gifts` (one per mailing), `items` (quantity, so a stack of 20 counts 20), `itemLevels` (summed once per mailing, equippable gear only) and `value` (vendor sell price times quantity, in copper). `ns.Generosity:RecordSend(link, quantity)` is the only writer, called from `Mail-Sender.lua` beside `Fairness:Record` on both the normal delivery path and the late-delivery path, with the `_count` captured before the attach. The General panel reads it through `ns.Generosity:Get`.

## Sharing the Tally

`Features/Generosity-Broadcast.lua` shares the tally with nearby players and caches theirs; `Features/Generosity-Tooltip.lua` renders a peer's totals at the bottom of their unit tooltip. Classic has no custom channels and does not deliver add-on whispers to non-social strangers, so `YELL` add-on messages are the only reach to nearby strangers. **The feature is proximity-scoped by construction: a distant friend never appears.** These are `C_ChatInfo.SendAddonMessage` calls, never `SendChatMessage`, so nothing here is player-visible chat and no target marker applies.

The prefix is `ns.ADDON_MESSAGE_PREFIX` (`"PIForward"`, `Data/Data.lua`; the client caps a prefix at 16 characters), registered at load under `pcall`. The payload is versioned and pipe-delimited:

```text
1|S|<gifts>|<items>|<itemLevels>|<value>    stats
1|?                                         ping
```

An unknown version or foreign prefix is dropped. Peers are cached by `ns.QualifyPlayerName` with their `GetTime()` stamp and good for `PEER_MAX_AGE` (1800s); expired entries are swept on the next stats message received, the only point the table grows, so it stays bounded without a timer. The span is long on purpose: an expired entry is refilled only by the tooltip's presence ping, so a short window would make a peer beside you flicker out between hovers. A share-on account broadcasts even at zero gifts, so presence shows before the first gift.

**Town only.** Every send and the tooltip block are gated on `ns.AtRest()` (`IsResting`, answering `false` when the API is missing), which keeps the feature out of raids, dungeons and open-world combat without reasoning about combat state. The gate is checked before the throttle on both outgoing paths, so nothing blocked in the world spends a window it never used. Receiving is not gated, which is why the ping answer needs its own gate: unlike `Broadcast`, it is reached out in the world.

Three throttles, all against `GetTime()`:

- **`BROADCAST_MIN_INTERVAL`** (60s) caps our outgoing totals. It also absorbs the `PLAYER_ENTERING_WORLD` refire and the post-run broadcast, which simply call `Broadcast`.
- **`PING_ANSWER_INTERVAL`** (30s) caps answers to received pings. An answer is a `Broadcast`, so it also needs `shareStats` on and the 60s window clear, and its own stamp is spent even when nothing went out.
- **`HOVER_PING_INTERVAL`** (10s, tooltip side) caps presence pings fired by hovering unknown players. A ping is gated on the rest area only, not on `shareStats`.

**The tooltip block's shape is constrained.** A blank line, then the header from `ns:BuildBrandedLine` (`Features/Announcements.lua`, the same builder chat prints use, so the two surfaces cannot brand the add-on differently), then four indented rows. **Values are white**: the money row comes from `GetCoinTextureString`, which carries its own markup and ignores a color prefix, so any other color leaves it out of step. Labels are `HELP` silver, because gold field titles mark a control the player acts on. The hook is `TooltipDataProcessor`'s post-call where it exists, `OnTooltipSetUnit` otherwise, on `GameTooltip` only, and `C_Secrets.ShouldUnitIdentityBeSecret` is asked before reading the unit.

**Accepted latency.** Hovering a player you have never heard from shows nothing on the first pass and fires a ping; the block appears on the next hover. A peer silent past `PEER_MAX_AGE` drops back to that state. Your own tooltip shows your live tally, even at zero. Turning sharing off stops your broadcasts but not your view of others.

## The Options Panel

### Opening the Panel

`ns:OpenOptionsPanel` (`Options/Options.lua`) is the one entry point, and `/pif` does nothing but call it. The combat gate comes first (see Combat Lockdown). **The route is decided in one place**: `ns:OptionsPanelRoute` returns `(route, insideOptions, description)`, the opener branches on it, and the Diagnostics API row "Options panel opens inside the Blizzard interface" calls the same function, so the report cannot describe a route the add-on does not take. It routes to `Settings.OpenToCategory(ns.GeneralCategoryID)` and falls back to AceConfigDialog's standalone window only when `Settings.OpenToCategory` or the captured ID is missing.

**Never look the category up by name.** `AddToBlizOptions` returns `(frame, categoryID)`, captured as `ns.GeneralPanel` and `ns.GeneralCategoryID`. AceConfigDialog uses the display name as the category ID only on clients lacking `C_SettingsUtil.OpenSettingsPanel`; Era lacks it and TBC Anniversary has it, so a name lookup works on one flavor and floats the panel free on the other.

Registration is deferred: `ns:RegisterOptionsPanels` runs from the `ADDON_LOADED` init point, because the Profiles builder reads `ns.db`. Child order is General, Profiles, Diagnostic Tools. The Diagnostics panel registers as its builder function, so its tabs are rebuilt on every repaint.

### Layout

AceConfig's flow layout packs cells until a row fills, and two rules follow from that.

**A label-beside-value row needs a spacer behind it.** The Feedback & Support links and the Generosity totals are built by `addFeedbackLinks` and `addGenerosityStats` (`Options/Options-General.lua`) as a `ns.OptionsRowLabel` at `ROW_LABEL_WIDTH` (0.6) plus a value at `ROW_VALUE_WIDTH` (`ns.OPTIONS_ROW_WIDTH` minus that, 2.8), with a full-width spacer between pairs and none after the last, where the gap before the next section would double. The Generosity totals are text on both sides, and two `description` widgets never break a row on their own, so they depend entirely on that spacer.

**A toggle can be its own caption.** Include Gear is a toggle at `ns.OPTIONS_LABEL_WIDTH` (2.1) with its rarity select beside it at `ns.OPTIONS_CONTROL_WIDTH` (1.3); the select's values ("Rare & Lower") describe themselves. Include Consumables is a full-width toggle with indented sub-rows beneath it (`SubRow`, `SubLabel`, `ns.OPTIONS_SUB_INDENT_WIDTH`): the Level Rule select with its caption, then the four kind toggles. A select or sub-row hides while its toggle is off, and the spacer between the two sections keeps the toggles from pairing on one line. All widths live in `Data/Data.lua` except the two row widths, which are local to `Options-General.lua`.

Panel order: description, Enable Welcome Message, What to Give Away, Generosity (Share toggle and the four totals), /Commands, Feedback & Support, version line.

A setter that changes what counts as giftable calls `refreshWindow()`, which runs `UI:_syncControls()` and `UI:Rescan()` when the window exists. `UI:_rarityPickerOptions` and `UI:_gapPickerOptions` are split from opening the pickers so `Tests/Options-Values.lua` can read them without a frame. The gap picker compares `opt.gap == nil` rather than truthiness, because **the All Consumables stop is a zero**. A stored gap that is not one of `ns.CONSUMABLE_GAP_ORDER` is snapped to the nearest stop for display by `ns.NearestConsumableGap`.

## Diagnostic Tools

`Diagnostics/` is the shared framework, gated behind a runtime-only toggle in `ns.diagnostics` that starts off every session and is never saved. Reports build only on a button press, and the panel writes nothing but the `taintLog` CVar. Five tabs: **Run Tests** (Event Log, Taint Log, in-game and external tool pointers), then **Settings**, **Code**, **Data** and **Localization**, each with Run All, one row per report and one output box. Reports and tabs come from `ns.DIAGNOSTIC_REPORTS` and `ns.DIAGNOSTIC_SECTIONS` in `Report-Runner.lua`.

The README-Notes exception keeps three additions to Magic Eraser's framework: an API row's optional second return is printed beside its result, a report row can carry an input box (`input` on its `ns.DIAGNOSTIC_REPORTS` entry), and Validate Data has a zone kind. `Validate-Data.lua` reads tables off `ns.Data` rather than `ns`.

**Settings** holds the context probes, then the shared Saved Variables, Display Context and Other Add-ons:

- **Mailbox**: what `ns.AtMailbox()` answers and which source answered it, the `MailFrame` hooks, and whether the window is built and shown.
- **Bag Scan**: every occupied slot with its verdict or reject code. The rejected rows are the point.
- **Recipient Roster**: everyone pooled, with fairness state, what each qualifies for, and what the parsers discarded.
- **Item Verdict**: one link or item id typed into the row's box, with both stat sources side by side, so a parse failure shows as one rather than as a low score.
- **Class Groups**: the derived armor and weapon priority tables at a typed level, or the player's own.
- **Outgoing Mail**: the exact subject and body a stranger receives, with byte lengths.
- **Given Away Sharing**: share state, resting state, prefix registration, which tooltip hook installed, the throttle stamps, this account's totals, and every peer with its age and an expired marker. It answers "why don't I see anyone", usually with the resting line.

**Code** holds Event Registration (driven off `ns.EVENT_NAMES`), API Endpoints and Library Versions. `ns.DIAGNOSTIC_API_CHECKS` carries a row per API reached through a compatibility guard plus the load-bearing calls, including `C_ChatInfo.SendAddonMessage`, `C_ChatInfo.RegisterAddonMessagePrefix` and `IsResting`, which the broadcast needs. Where the add-on picks between two APIs both halves are rows, so a FAIL on one half says which branch that client took (the `C_TooltipInfo` rows fail on Classic Era, where `Scan-Tooltip.lua` reads its hidden tooltip instead). Three rows feed literal strings to `Tooltip:StatsFromLines` as regression guards: a random-suffix roll arrives color-wrapped, and when that form stops parsing every rolled green reads as statless and lands in the vendor pile while fixed-stat items keep working.

**Data** has one Validate Data row per flavor-folder file (`ns.DIAGNOSTIC_DATA_SOURCES`, eight sources). Food, potions and scrolls validate as items. Zones validate as `"area"`: each row prints the name `C_Map.GetAreaInfo` gives its ID, and a blank name is `NO NAME` rather than `NOT ON CLIENT`, since a client can know an area and leave it untranslated; a wrong zone ID otherwise fails silently, because the search skips a zone it cannot name. Stat budget, weapons, armor and faction classes carry no ID a client API looks up, so they report a row count or `TABLE MISSING`.

**Localization** holds Locale Context (locale, text and audio locale CVars, defined key count) and Game Names, a table of every lookup in `ns.DIAGNOSTIC_NAME_LOOKUPS` with a nil count. The add-on sends no chat and writes no macros, so there is no Message Length report; mail lengths are in Outgoing Mail.

### The Event Log Filter

`ns.DIAGNOSTIC_EVENT_EXCLUDE` (`Event-Log.lua`) is deliberately empty: every event this add-on registers is signal some of the time. The noisy ones go through `ns.MESSAGE_ID_FILTERED_EVENTS` instead, which names each event, the argument position of the id that classifies a firing, and a `correlated` predicate:

| Event | Correlated when |
|---|---|
| `UI_ERROR_MESSAGE` | `ns.Distributor:IsMailError(message)` |
| `CHAT_MSG_ADDON` | the prefix is `ns.ADDON_MESSAGE_PREFIX` |
| `BAG_UPDATE`, `GET_ITEM_INFO_RECEIVED` | `ns.MatchList:WouldRescan()`, the firing armed a rescan of the open window |

`ns:SuppressUncorrelatedMessage` runs inside `ns:LogEvent`, **at capture rather than at render**, because filtering at display time still lets spam push real entries out of the 500-entry buffer. Three rules govern it:

- **Filter by what the add-on acts on, never by a denylist of noise.** Noise is unbounded and renumbers across patches. Each predicate calls the live handler's own test, so a drifted filter cannot make the log lie about what fired. That is the only reason `IsMailError` and `WouldRescan` are exposed.
- **Count, don't delete.** Suppressed traffic aggregates per id as first-seen text plus a count, rendered as one block at the end of the report, biggest first: `UI_ERROR_MESSAGE(56, Ability is not ready yet.) x469`. That block is how a tester finds an id the add-on should be correlating.
- **Unclassifiable is signal.** A firing with nothing at the id position is logged verbatim. The counters live in `ns.diagnostics.suppressed`; Stop keeps them, Start replaces them, and switching the panel off releases them.

`Tests/Event-Log-Noise.lua` pins all of it.

## Saved Variables

One table, `PlayItForwardDB`, created in the name-guarded `ADDON_LOADED` handler with `LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)`.

**The model is Simple.** Nothing the add-on stores differs from character to character, so every character shares the `"Default"` profile (that third argument `true`). **Reset Profile restores every setting to its install default, and leaves the giving tally in `global` untouched.** A new setting goes in `profile`; only reset-proof state, which here is the lifetime tally, belongs in `global`.

`profile` holds the presentation and giftability settings (`showWelcome`, `shareStats`, `maxRarity`, `includeGear`, `includeConsumables`, `consumableKinds`, `consumableLevelGap`) and the dragged `windowPos`. `global.stats` holds the four tally counters, written only by `ns.Generosity:RecordSend`. Read `Data/Default-Settings.lua` for the current shape and defaults. `consumableLevelGap` of 0 is a sentinel, the All Consumables stop, which lifts the level test outright.

AceDB applies `ns.DATABASE_DEFAULTS` when a scope is first accessed, never overriding an explicit user value including `false`; scalar and table defaults are copied into the saved table, and `removeDefaults` strips any key still equal to its default on logout, so an untouched profile saves empty. A key removed from `ns.DATABASE_DEFAULTS` is never visited by that cleanup, so retiring one takes an explicit nil inside a tagged migration.

There are no default item or spell lists, so no seeding logic. The giftable-item tables are static data and never enter saved variables. The fairness history is session-only, in a file-local table.

Not settings, on purpose: the rarity floor `ns.Data.MIN_RARITY` (Uncommon, gear only; consumables return before the rarity checks), every matching constant, and the mail text.

### Migration Chain

- `ns.db.profile.recipients = nil` in `Features/Core.lua`: the fairness history left saved variables for a session table. `MIGRATION (remove after 2026-11-05)`.

## Adding a New Registered Event

1. Call `ns.on("YOUR_EVENT", handler)` from the feature file that needs it. Never create a frame; it would escape the event log.
2. `ns.EVENT_NAMES` records it automatically, so Event Registration picks it up with no second edit. Add it only on the TOCs whose client ships it, or behind the same flavor check as the `PLAYER_INTERACTION_MANAGER` pair; registering an event the client lacks throws.
3. If it fires often enough to bury the 500-entry log, decide whether any firing is ever signal. If none is, add it to `ns.DIAGNOSTIC_EVENT_EXCLUDE` in `Diagnostics/Event-Log.lua`. If some are, add it to `ns.MESSAGE_ID_FILTERED_EVENTS` with its id position and a `correlated` predicate that calls the handler's own test. Excluding a sometimes-signal event hides the one entry a bug report needs.

## Adding a New Giftable Consumable

1. Add the row to `FOOD_AND_WATER`, `POTIONS` or `SCROLLS` in `Data/{Flavor}/Scan-Food-{Flavor}.lua`, `Scan-Potions-{Flavor}.lua` or `Scan-Scrolls-{Flavor}.lua`, in every folder whose client has the item, as `{ id, quality, useLevel, restores }` (`buffs` in place of `restores` for a scroll) with a trailing `-- Item Name`. Edit rows in place; look up the same ID in the other six folders and say which copies changed (Style Guide → DATA → Flavor Folders). The file's `How We Got the Data` block belongs to the Data Review.
2. `restores` is `"HEALTH"`, `"MANA"`, `"BOTH"` or `"PET"`; a scroll's `buffs` is `"STRENGTH"`, `"AGILITY"`, `"STAMINA"`, `"INTELLECT"`, `"SPIRIT"` or `"ARMOR"`. Eligibility derives from that value through `ns.Data.CONSUMABLE_CLASSES` in `Data/Data.lua`; there is no per-item class list, and the classes are then filtered by faction.
3. **A `useLevel` of 2 or less reaches nobody.** The band runs from the use level up `CONSUMABLE_RECIPIENT_GAP` (2), so it tops out at 4, below `MIN_RECIPIENT_LEVEL` (5). A 0 is rejected as `NO_USE_LEVEL`; a 1 or 2 is offered and never matched, and keeps the search plan alive for an item nobody can take. Leave such rows out, or give the item a real usefulness level.
4. `Features/Scan-Bags.lua` stamps the source table's `form` (`FOOD`, `POTION`, `SCROLL`) and the row's `kinds` onto `record.def`, and files the fourth column under `restores` or `buffs`. Kinds are the player's switches, not the form: a `FOOD_AND_WATER` row restoring `MANA` is `DRINK`, `BOTH` is `FOOD` and `DRINK`, the rest (`PET` included) `FOOD`. A row in two tables is silently won by the later one.
5. Rules key on `def.form` and `def.restores`, which is what keeps water from being treated as a mana potion. No rule can key on a scroll's `buffs`.

## Adding a New Stat

1. Map the `GetItemStats` key to an internal token in `ns.Data.STAT_MAP` (`Data/Scan-Stats.lua`).
2. Weigh the token in the talent trees in `Data/Match-Stats.lua` as main (2) or useful (1), and give it a cost in every flavor folder's `Match-Stat-Budget` file if a point of it is not worth a point of primary stat. The step from a sum of 2 (admitted, never leads) to 3 (enters the top bucket) is categorical; a stat weighted on another scale is silently misfiled.
3. **Weighting a stat is never only a scoring change.** It enlarges the coverage denominator on every item carrying that stat, and the majority test is strictly greater than half. Run `Tests/Stat-Scoring.lua` and `Tests/Talent-Trees.lua`.
4. If the stat renders only as tooltip text with no `ITEM_MOD_` global (per-school spell damage), add it to `ENUS_FALLBACK` or `EQUIP_PATTERNS` in `Features/Scan-Tooltip.lua`, more specific patterns first.
5. Never add to `ns.Data.UNIVERSAL_WEIGHTS`. A weight on every class scores every class on every item and compresses the gaps between them.

## Adding a New Item Rule

1. Add a table to `ns.Data.ITEM_RULES` in `Data/Match-Rules.lua` with a developer-facing `name` (never localized) and exactly one matcher: `weapon`, `form` plus `restores`, or `requires` (optionally `exclusive = true`, optionally `armor`).
2. Pick the verb deliberately: `prefer` for "this is who it is for", `demote` for "not this class, but keep them as a fallback", `veto` only for "this class must never receive it". Add `unclaimed = true` only to break a tie no stat can break; it pairs with `prefer` or `demote`.
3. **Position matters for `prefer` and only for `prefer`.** A new stat rule above an existing one silently takes items from it, even when it names nobody admitted. `veto` and `demote` accumulate, so their position is free.
4. Add a case to `Tests/Item-Rules.lua`, `Tests/Weapon-Rules.lua`, `Tests/Consumable-Rules.lua` or `Tests/Scroll-Rules.lua` and run `lua5.1 Tests/Run.lua`. Rule interactions do not survive being reasoned about; the veto-before-scoring and demote-after-prefer orders both have tests.

## Adding a New Options Control

1. Add its key and default to `ns.DATABASE_DEFAULTS.profile` in `Data/Default-Settings.lua`. Under the Simple model every setting lives on the profile; `global` holds only the giving tally.
2. Add the widget to `ns.BuildGeneralOptions` in `Options/Options-General.lua` with the `ns.OptionsHeader`, `ns.OptionsDesc`, `ns.OptionsSpacer` and `ns.OptionsRowLabel` constructors from `Options/Options-Utilities.lua`. Its explanation goes in `desc`, never a second line under it. Follow the spacer rule under The Options Panel → Layout.
3. Add its strings to `Locales/enUS.lua` only.
4. If it changes what counts as giftable, call `refreshWindow()` from its setter, and mirror it in the window's top bar only if the bar already shows its section.

## Localization

**`enUS.lua` is the source of truth** and the only file whose `NewLocale` passes `true`. It registers under the literal `"Play-It-Forward"`, and `Data/Data.lua` reads `GetLocale(ADDON_NAME)`; the two must stay the same string, or every `L` lookup is nil with no load error. The other ten files translate its key set and are owned by the Localization Review (`07 - Localization Review.md`); ordinary work edits `enUS.lua` alone.

**Placeholders.** `%s` and `%d` count, type and order must match `enUS` per key in every locale, or the string errors at runtime.

**Game names never go in `Locales/`.** The add-on stores IDs and tokens and asks the client:

| Record | Stored as | Named by |
|---|---|---|
| Zone | AreaTable ID, `ns.Data.ZONES` column `ZONE_COLUMNS.AREA_ID` | `C_Map.GetAreaInfo`, cached per session in `Recipients-Who-Plan.lua` (`Who.AreaName`) |
| Class | Token | `LOCALIZED_CLASS_NAMES_MALE` (`Who.ClassName`) for `/who` filters; male and female both for parsing results |
| Race | Race ID, 1 to 100 | `C_CreatureInfo.GetRaceInfo(id).raceName` |
| Item | Bag link | `C_Item.GetItemInfo`; the data tables' IDs are read by name only in Validate Data |
| Item quality | 2 to 4 | `ITEM_QUALITY2_DESC` to `ITEM_QUALITY4_DESC` |
| Stat | `ITEM_MOD_*` global name, `ns.Data.STAT_MAP` | The global itself |
| Mail refusal | `ERR_MAIL*` and `ERR_PLAYER_WRONG_FACTION` | The globals themselves |

**Zones are area records, not map records.** `/who` matches the zone text its results carry, which is the AreaTable name, and area and map names disagree in some locales on every client (frFR area names carry an English suffix, deDE names The Barrens `Brachland` against the map's `Das Brachland`). An area the client has no name for is skipped rather than sent as an empty `z-""`.

**Equip-effect parsing is English-only.** `EQUIP_PATTERNS` in `Features/Scan-Tooltip.lua` matches the rendered "Equip: ..." wording vanilla builds from spell text. `Tooltip.equipPatternsUsable` gates it on `GetLocale() == "enUS"`, an API row reports the gate, and Item Verdict says so on other clients. A plain `+9 Intellect` line parses everywhere, so an item misses a stat rather than scoring wrongly.

**The mail stays English.** `MAIL_SUBJECT` and `MAIL_BODY` are English in every locale file (README-Notes), so every client sends the bytes `Tests/Mail-Contents.lua` measures. They are the add-on's only output with a ceiling, `SUBJECT_MAX` (31) and `BODY_MAX` (500) bytes; the add-on never calls `SendChatMessage` and writes no macros, so the 255-byte limits do not apply.

**Diagnostics strings are not localized.** They live in `ns.DiagnosticsStrings` (`Diagnostics/Diagnostics-Core.lua`, plus `EVENT_LOG_EXAMPLES` in `Manifests.lua`) and inline in the report builders. That includes the `WHO_LABEL_*` query labels, which `Recipients-Who-Plan.lua` composes but reads at call time, since the Diagnostics files load after it. Who reads a string decides the rule, not where it is built.

## Common Pitfalls

- **Calling `SendWho` outside a click handler**: silently blocked, no error, no event. Every query rides a button press.
- **Using `UseContainerItem` with the Send Mail panel closed**: uses the item instead of attaching it. Check the panel before touching the item.
- **Setting the mail subject before attaching**: the client overwrites an empty subject with the item's name. Fill the panel after the attach.
- **Re-reading a bag slot on `MAIL_SUCCESS`**: the slot still holds the old link, so every delivery reads as a skip. Trust the event; capture the stack size before the send.
- **Dropping a job when the mail result timer fires**: `SendMail` already went out, so a late Accept still delivers. The job moves to `_awaiting` and `_result` credits it.
- **Gating on `MailFrame:IsShown()` or hooking its `OnHide`**: mail-replacement add-ons and the Who panel both hide it while the player stands at a mailbox. Use `ns.AtMailbox()`.
- **Dropping an in-flight `/who` instead of cancelling it**: `endQuery` is what re-registers `WHO_LIST_UPDATE` on Blizzard's frames and restores `SetWhoToUi`. Skip it and the player's own `/who` answers with silence for the rest of the session.
- **Re-planning a search mid-flight instead of pruning it**: `Who:Plan` restarts from the best-first attempt, so a search re-planned per press never gets past its first zone. `Who:Prune` only removes.
- **Putting two class filters in one `/who`**: the client honors the first and drops the rest, filling the pool with the wrong class. One class per query.
- **Trusting `GetItemStats` on a random-suffix green**: it resolves the base item and returns nothing. The tooltip is the only source for suffix stats.
- **Dropping `cleanLine` from the tooltip parser**: suffix and enchant stats arrive color-wrapped and newline-terminated, fail the `^%s*%+` anchor, and every rolled green returns to the vendor pile.
- **Testing `classID == 2` to mean "weapon"**: shields, held off-hands and relics are armor but rank on the weapon matrix. Use `ns.Data.UsesWeaponMatrix(item)`.
- **Reading a weapon key without checking `classID` first**: armor subclass 1 (cloth) collides with weapon subclass 1 (two-hand axe), so a cloth chest answers `2H_AXE`.
- **Putting `INVTYPE_HOLDABLE` in `UNIVERSAL_EQUIP_LOC`**: a held off-hand turns on whether a class has the off-hand slot free, so as universal an Intellect orb becomes eligible for a warrior. They route through the weapon matrix as `HELD`.
- **Reading `ns.db.profileKeys`**: always nil; AceDB keeps it on `ns.db.sv`. An own-alt check against it silently passes everybody.
- **Comparing or deduping player names as raw strings**: the roster and `/who` can spell one same-realm character two ways, so a raw comparison pools them twice and lets your own alts past. Compare `ns.QualifyPlayerName`; store and mail the name the client gave.
- **Adding a recipient level floor to a source**: there is one, in `MatchList:AddResults`, the door every source comes through. A second copy drifts from it.
- **Treating a `consumableLevelGap` of 0 as a gap**: it is the All Consumables sentinel, and compared as a gap it withholds every consumable the player has not reached.
- **Shipping a consumable with a `useLevel` of 2 or less**: its band ends below the level-5 floor, so it matches nobody and keeps the search running for it.
- **Rolling a random tiebreak inside a sort comparator**: `table.sort` throws. The shuffle key is rolled once per player at pool entry.
- **Mutating the list `MatchList:Candidates` returns**: it is the cached table, handed out by reference.
- **Caching `MatchList:Items()` in a local**: `rescanBags` reassigns the table. Call the accessor each time.
- **Re-reading the bags at the end of a distribution run**: the client has not emptied the sent slots yet, so the scan restores the pairings just delivered. `UI:_afterDelivery` re-assigns without scanning.
- **Reordering `ns.Data.ITEM_RULES`**: `prefer` is first-match-wins, so moving a stat rule above another silently takes items from it. `veto` and `demote` do not care, which makes the table look more reorderable than it is.
- **Adding a stat weight and expecting only scores to move**: it changes the coverage denominator on every item carrying that stat.
- **Adding a class to a flavor's `FACTION_CLASSES` alone**: `EVERY_CLASS` in `Match-Engine.lua` filters through it and stops at the death knight.
- **Pairing two `description` widgets on one options row without a spacer**: the flow packs them until the row fills and the rows interleave. Every label-beside-value pair needs its full-width spacer.
- **Opening the options panel by category name**: works on Era, floats the panel on TBC Anniversary. Route by `ns.GeneralCategoryID`.
- **Coloring the Generosity values anything but white**: `GetCoinTextureString` ignores the prefix, so the money row stays white regardless.
- **Removing a key from `ns.DATABASE_DEFAULTS` and expecting it to disappear**: AceDB's cleanup only visits keys still in the defaults, so the orphan persists. Nil it explicitly inside a tagged migration in `Core.lua`.
- **Moving a file earlier in the TOC**: `Match-Derivations.lua` reads `WEAPON_CLASS_ORDER` at load, the UI files capture each other in order, and `Diagnostics/Manifests.lua` reads `ns.Who.AreaName` at load. Each depends on the file before it.

## Contributing

**Issues**: [github.com/Gogo1951/Play-It-Forward/issues](https://github.com/Gogo1951/Play-It-Forward/issues).

**Bug reports** include the game version (Classic Era 1.15.x, WoW Forever 1.60.x or TBC Anniversary 2.5.x) and locale, class and level, repro steps, and the relevant output from **Options > AddOns > Play It Forward > Diagnostic Tools**. Bag Scan and Item Verdict answer most "why isn't this item showing up" questions; Given Away Sharing answers "why don't I see anyone".

**Discord**: [discord.gg/eh8hKq992Q](https://discord.gg/eh8hKq992Q).

**Pull requests:**

- One concern per PR.
- Match the house style: StyLua defaults with `--syntax lua51` (no `.stylua.toml`), no abbreviations, every player-facing string through `L["KEY"]`, diagnostics strings through `ns.DiagnosticsStrings`.
- Run `stylua`, `luac -p`, a clean `luacheck .` and `lua5.1 Tests/Run.lua` before pushing; CI runs the same on every PR.
- New settings take their defaults from `ns.DATABASE_DEFAULTS`; never hand-merge or overwrite a user value. Any change to saved-variable shape ships a dated `MIGRATION (remove after YYYY-MM-DD)` bridge, deleted once the date passes.
- A change to the mail subject or body re-checks its byte length against `SUBJECT_MAX` and `BODY_MAX`.
- Update this document if the architecture or file map changes.

**PR descriptions say what a player will notice**, in plain language, the way release notes do. Commit messages carry the developer detail.
