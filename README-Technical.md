# Play It Forward // Technical Reference

This document combines architecture notes and contribution guidance for developers working on Play It Forward. For end-user documentation, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md).

## File Map

```text
Play-It-Forward/
├── .github/
│   ├── ISSUE_TEMPLATE/               Issue forms; defect.yml and request.yml synced from Common-Core
│   │   ├── config.yml                Per add-on: the New issue page links
│   │   ├── defect.yml
│   │   └── request.yml
│   └── workflows/
│       ├── ci.yml                    Calls Common-Core: Lua 5.1 syntax, luacheck, StyLua and the offline tests
│       ├── issue-labels.yml          Calls Common-Core: labels a new Defect by its Issue Type
│       └── package.yml               Calls Common-Core: packages and uploads a tagged release
├── .gitattributes                    Shared Common-Core file
├── .gitignore                        Shared Common-Core file
├── .luacheckrc                       Lint config
├── .pkgmeta                          Externals and ignore list
├── Play-It-Forward_Vanilla.toc       Classic Era, Season of Discovery included
├── Play-It-Forward_TBC.toc           TBC Anniversary
├── Play-It-Forward_Camelot.toc       WoW Forever
├── Play-It-Forward_Mists.toc         Mists of Pandaria Classic
├── Data/
│   ├── Flavor.lua                    Canonical: ns.FLAVOR, ns.EXPANSION, ns.IS_DISCOVERY, ns.DATA_FOLDER
│   ├── Data.lua                      Locale init, ns.Data, palette, links, widths, matching and band constants
│   ├── Default-Settings.lua          The AceDB-3.0 defaults, ns.DATABASE_DEFAULTS
│   ├── Vanilla/                      Classic Era game data and matching policy; every file has the Discovery guard
│   ├── Discovery/                    Season of Discovery, inverse guard; rides the Vanilla TOC
│   ├── TBC/                          TBC Anniversary
│   ├── Camelot/                      WoW Forever
│   ├── Wrath/                        No TOC lists it; .pkgmeta keeps it out of the zip
│   ├── Mists/                        Mists of Pandaria Classic
│   └── Mainline/                     No TOC lists it; .pkgmeta keeps it out of the zip
├── Diagnostics/                      Diagnostic Tools framework, copied from Magic Eraser
│   ├── Diagnostics-Core.lua          The ns.diagnostics gate and ns.DiagnosticsStrings
│   ├── Manifests.lua                 This add-on's surface: API rows, context probes, data sources, name lookups
│   ├── Event-Log.lua                 Event buffer and the per-id noise filter
│   ├── Code-Reports.lua              Event Registration, API Endpoints, Library Versions
│   ├── Settings-Reports.lua          Saved Variables, Display Context, Other Add-ons
│   ├── Validate-Data.lua             One TSV report per flavor-folder data file
│   ├── Localization-Reports.lua      Locale Context, Game Names
│   ├── Report-Runner.lua             The report and tab manifests and the one-at-a-time runner
│   └── Options-Diagnostics.lua       The panel builder; loads with the Options block
├── Features/
│   ├── Core.lua                      Identity, AceDB lifecycle, welcome, the ns.On dispatcher
│   ├── Utilities.lua                 API aliases, ns.ReadTooltip, colors, money, name and realm qualifying, ns.AtMailbox
│   ├── Announcements.lua             The ns:BuildBrandedLine and ns:PrintMessage builders; player-only output
│   ├── Scan-Tooltip.lua              Tooltip lines to stats, where random suffixes live
│   ├── Scan-Bags.lua                 Bag slot to item record, or nil plus a reject code
│   ├── Match-Derivations.lua         Stat weights from SPECS; priority groups, weapon keys, rule matching
│   ├── Match-Engine.lua              Eligibility, claim, fit, coverage, rules, the verdict
│   ├── Match-Ranking.lua             Candidate ranking, level bands, band groups, targeted search order
│   ├── Match-List.lua                Items and pairings; debounced rescan, RescanBags, the allocator
│   ├── Match-Roster.lua              The recipient pool: AddResults, the dedupe, the candidate cache
│   ├── Match-Search.lua              Band merging, which gifts still search, the targeted row
│   ├── Recipients-Who-Plan.lua       Builds, prunes and exhausts the /who plan
│   ├── Recipients-Zones.lua          ns.Data.ZonesFor, zone and instance names, candidate placement
│   ├── Recipients-Who.lua            Sends one /who per press; throttle, Who panel deafening, parsing
│   ├── Recipients-Guild.lua          Live and saved guild rosters as a recipient source
│   ├── Recipients-Alts.lua           Your own characters as a recipient source; the disenchanter
│   ├── Recipients-Fairness.lua       Session cooldown and the unreachable list
│   ├── Mail-Sender.lua               The ns.Distributor: one SendMail at a time, event-driven
│   ├── Mail-Copy.lua                 Subject, body and footer, stock or custom, cleaned and cut
│   ├── UI-Picker.lua                 The ns.Picker scrolling dropdown list
│   ├── UI-Window.lua                 The ns.UI mail window: top bar, rows and sections
│   ├── UI-Assignment.lua             Row dropdown options, manual picks, row ticks
│   ├── UI-Mailbox.lua                Mailbox open and close, Find Recipients, Distribute, the roster pulls
│   ├── UI-Reopen-Button.lua          The button beside MailFrame that brings the window back
│   ├── Generosity.lua                Account-wide giving tally in global.stats
│   ├── Generosity-Broadcast.lua      Shares the tally with nearby players over YELL add-on messages
│   └── Generosity-Tooltip.lua        A peer's totals at the foot of their unit tooltip
├── Includes/
│   ├── Images/
│   │   ├── Gift.tga                  The mail window's portrait
│   │   └── Play-It-Forward.tga       Icon
│   └── Libraries/                    Vendored Ace3 down to AceDBOptions-3.0, nothing else
├── Locales/                          Eleven locales
│   └── enUS.lua                      Source of truth
├── Options/
│   ├── Options-Utilities.lua         Shared ns.Options* constructors and ns.RefreshMailWindow
│   ├── Options-General.lua           The root panel: welcome and the three feature switches
│   ├── Options-Give-Away.lua         What to Give Away: gear, consumables and their kinds, disenchanting
│   ├── Options-Recipients.lua        Recipients: who comes first, stranger rules, one switch per spec
│   ├── Options-Alts.lua              My Alts: tree of characters, each one's tick, gear levels and specs
│   ├── Options-Guilds.lua            My Guilds: tree of saved guilds, each one's tick and member ignores
│   ├── Options-Mail.lua              Mail Message Text: the editor widget and live preview
│   ├── Options-Generosity.lua        Badge of Generosity: the Share switch and a preview of your badge
│   ├── Options-Profiles.lua          Stock AceDBOptions-3.0 table
│   ├── Options-Feedback-Support.lua  Level Up note, links, version line
│   └── Options.lua                   Registration, ns:OpenOptionsPanel, /pif
├── Tests/                            Offline suite, run on Lua 5.1: 40 case files plus Run, Harness, Stub-WoW-API and Write-Outcomes; never ships
│   └── Outcomes/                     Saved who-gets-what tables, one per flavor folder, checked by Outcomes.lua
├── LICENSE                           MIT
├── README.md                         Player documentation
├── README-Notes.md                   The add-on's exceptions to the Style Guide
├── README-Technical.md               This document
└── README-Testing.md                 Manual test plan
```

**Files that must not come back.** There is no mini-map button, so `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are deliberately absent. The diagnostics panel lives in `Diagnostics/Options-Diagnostics.lua`, never `Features/Diagnostics.lua` or `Options/Options-Diagnostics.lua`. Nothing but `Flavor.lua`, `Data.lua` and `Default-Settings.lua` sits directly in `Data/`: the shared `Data/Match-Armor.lua`, `Match-Rules.lua`, `Match-Stats.lua`, `Match-Weapons.lua`, `Recipients-Zones.lua`, `Scan-Food.lua`, `Scan-Potions.lua` and `Scan-Stats.lua` are replaced by their per-flavor copies. Game data and matching policy never return to a file every client loads.

**Each client loads one data folder.** Every flavor folder holds the same thirteen files, suffixed with the folder name, each declaring the same tables under `ns.Data`:

| File | Tables |
|---|---|
| `Match-Stat-Budget` | `STAT_BUDGET` |
| `Match-Weapons` | `WEAPON_SUBCLASS`, `RELIC_SUBCLASS`, `WEAPON_CLASS_ORDER`, `WEAPON_SPECS` |
| `Match-Armor` | `ARMOR_SUBCLASS`, `ARMOR_WEIGHT`, `NATIVE_ARMOR`, `UNIVERSAL_EQUIP_LOC` |
| `Match-Classes` | `FACTION_CLASSES`, `CONSUMABLE_CLASSES` |
| `Match-Specs` | `SPECS`, every spec per class with its role and stats |
| `Match-Rules` | `ITEM_RULES` |
| `Scan-Stats` | `STAT_MAP`, `GetItemStats` keys to internal stat tokens |
| `Scan-Food`, `Scan-Potions`, `Scan-Scrolls`, `Scan-Oils-Stones` | `FOOD_AND_WATER`, `POTIONS`, `SCROLLS`, `OILS_AND_STONES` |
| `Recipients-Zones` | `ZONES`, `ZONE_COLUMNS`, `INSTANCE_AREAS` |
| `Recipients-Realms` | `LINKED_REALMS`, the connected-realm clusters alts can be mailed across |

Each TOC lists its own folder only. The Vanilla TOC lists `Data/Vanilla/` then `Data/Discovery/`; Vanilla files open with `if ns.IS_DISCOVERY then return end` and Discovery files with the inverse, so exactly one set builds. `LINKED_REALMS` is built per region from `GetCurrentRegion()` in the Vanilla and Mists folders, and is an empty table everywhere else, Discovery included.

`Tests/` is development-only: no TOC lists it and `.pkgmeta` ignores it. `lua5.1 Tests/Run.lua` requires every case file and exits non-zero on any failure. `Tests/Outcomes.lua` builds a who-gets-what table (every common stat roll on every gear kind, at three levels) for each flavor folder and compares it with the saved file in `Tests/Outcomes/`; `Tests/Write-Outcomes.lua` rewrites those files when a change to the outcomes is intended.

## Architecture

### Event Loop

`Features/Core.lua` owns the add-on's one event frame and one entry point, `ns.On(event, fn)`. A feature file never creates its own event frame, because one would bypass the Diagnostics event log. Several handlers may share an event; they run in registration order, which is TOC order. `ns.EVENT_NAMES` is filled as events register rather than declared up front, since registration is flavor-conditional, so the Event Registration report tests exactly what this client took.

| Event | Registered in | Purpose |
|---|---|---|
| `ADDON_LOADED` | `Core.lua` | Name-guarded. Creates `PlayItForwardDB`, runs the dated migration, calls `ns.Data.RebuildStatWeights` now the player's spec choices exist, wires `ns:ApplyProfile` to the profile callbacks, calls `ns:RegisterOptionsPanels`. |
| `PLAYER_LOGIN` | `Core.lua` | Welcome print, when `profile.showWelcome` is on. |
| `PLAYER_LOGIN` | `Recipients-Who.lua` | Hooks the Who panel's `OnShow` to count it opening during a query (evidence for the Roster report). |
| `PLAYER_LOGIN` | `Recipients-Guild.lua` | After a 5 second `C_Timer.After`, asks for the roster so this character's guild is saved. |
| `PLAYER_LOGIN` | `Recipients-Alts.lua` | Records this character in `global.characters`. |
| `PLAYER_LOGIN` | `UI-Mailbox.lua` | Hooks `MailFrame` `OnShow` (opens the mailbox flow) and `OnHide` (rechecks Distribute). |
| `MAIL_SHOW` / `MAIL_CLOSED` | `UI-Mailbox.lua` | Mailbox open and close, every flavor. |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `UI-Mailbox.lua` | The same signal, filtered to `Enum.PlayerInteractionType.MailInfo`. Behind `ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot"`, so TBC Anniversary, Mists and Forever register them and Classic Era never does. |
| `BAG_UPDATE`, `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Mark the bag scan stale; see Debounced Bag Scanning. |
| `WHO_LIST_UPDATE` | `Recipients-Who.lua` | Parses a `/who` answer under `pcall`, ends the query, prunes exhausted attempts, hands results on. |
| `ADDON_ACTION_BLOCKED` | `Recipients-Who.lua` | Our own blocked `SendWho` only: counts it and prints `L["WHO_BLOCKED"]` instead of leaving silence. |
| `CHARACTER_POINTS_CHANGED` | `Recipients-Alts.lua` | Re-records the character after a respec. |
| `PLAYER_SPECIALIZATION_CHANGED` | `Recipients-Alts.lua` | The same, behind `ns.EXPANSION >= 5`, where specs are picked rather than talented. |
| `PLAYER_LEVEL_UP` | `Recipients-Alts.lua` | Re-records with the level the event carries, since `UnitLevel` can lag it. |
| `MAIL_SUCCESS` / `MAIL_FAILED` | `Mail-Sender.lua` | Advance the send queue. |
| `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | A refusal the server reports without either result event. |
| `GUILD_ROSTER_UPDATE` | `Recipients-Guild.lua` | Saves this character's guild on the first roster with members after login, and delivers a roster the add-on asked for; otherwise ignored. |
| `CHAT_MSG_ADDON` | `Generosity-Broadcast.lua` | A peer's tally or a ping. Own prefix only. |
| `PLAYER_ENTERING_WORLD` | `Generosity-Broadcast.lua` | Broadcasts presence; the broadcast throttle absorbs the refire on every loading screen. |
| `PLAYER_UPDATE_RESTING` | `Generosity-Broadcast.lua` | Entering a rest area fires no loading screen, so this is what announces arrival in town. |

The dispatcher logs before it calls handlers, behind one boolean read: `if ns.diagnostics.logging then ns:LogEvent(event, ...) end`. Diagnostics off costs nothing, and an entry survives a handler that errors. `ns.diagnostics` is created in `Diagnostics/Diagnostics-Core.lua`, which loads after `Core.lua`; that is safe only because no registered event fires before every file has loaded.

Two places touch event registration outside `ns.On`, and both are deliberate: the Event Registration report's throwaway probe frame (`Diagnostics/Code-Reports.lua`), and the Who panel deafening in `Recipients-Who.lua`, which unregisters and re-registers every other frame listening for `WHO_LIST_UPDATE`.

### Combat Lockdown

Only the options opener refuses in combat. `ns:OpenOptionsPanel` (`Options/Options.lua`) checks `InCombatLockdown()` as its first statement, in front of every route, prints `L["CHAT_OPTIONS_IN_COMBAT"]` and returns. It never queues and never registers `PLAYER_REGEN_ENABLED`: a silent deferral reads as a broken command, and the Settings panel is protected in combat, so without the gate the player gets an `ADDON_ACTION_BLOCKED` error naming the add-on. Nothing else in the add-on defers for combat. Mail runs only at a mailbox, and `/who` only from a button press in the mail window.

### Scan, Match, Search, Send

1. **Scan.** `Features/Scan-Bags.lua` walks bags 0 to 4 (`NUM_BAGS`, no reagent bag). `Scanner:Classify` returns a finished record or `nil` plus a reject code. The sixteen codes (`NOT_CACHED`, `KIND_DISABLED`, `NO_USE_LEVEL`, `LEVEL_GAP`, `CONSUMABLE_NOT_LISTED`, `BIND_ON_PICKUP`, `ABOVE_MAX_RARITY`, ...) are diagnostic identifiers, never shown to players; they exist so "why isn't this item listed" has an answer in the Bag Scan report. Order among them matters: `CONSUMABLE_NOT_LISTED` is decided before the gear toggle, or a bandage scanned with gear off comes back `GEAR_DISABLED`, and gear needs a positive `classID` check because recipes carry an equip slot on this client. Each record's `uid` is `"bag:slot:link"`. Stats come from `GetItemStats` and from the rendered tooltip, merged by `NormalizedStats` taking the **max** per stat (see Item Data Caching). `ns.ReadTooltip` (`Features/Utilities.lua`) does the tooltip read, `C_TooltipInfo.GetHyperlink` first and a hidden `PlayItForwardScanTooltip` otherwise; `Features/Scan-Tooltip.lua` only parses the lines.
2. **Match.** `Features/Match-Engine.lua` computes one `verdict` per item: `eligible`, `admitted` and `contenders` classes, per-class `claims`, `fits` and `coverage`, and a state of `gift`, `leftover` or `unreadable`. `Features/Match-Derivations.lua` answers the table questions it needs (stat weights, priority groups, weapon keys, rule matches) and `Features/Match-Ranking.lua` turns a verdict into level bands and ranked candidates. Everything downstream reads the cached `item.verdict` rather than recomputing.
3. **Search.** Three sources fill one pool. `PullAlts` (`UI-Mailbox.lua`) reads your own characters through `ns.Alts`; `PullGuild` adds the saved guilds, then asks for the live roster through `ns.Guild`; neither needs a press. `Features/Recipients-Who-Plan.lua` builds a plan of `/who` attempts from the items' bands and `Features/Recipients-Who.lua` sends one per button press. Every source feeds `MatchList:AddResults` (`Features/Match-Roster.lua`).
4. **Send.** `Features/Mail-Sender.lua` (`ns.Distributor`) walks a job queue, one `SendMail` at a time, waiting for a result event before advancing.

`Features/Match-List.lua` holds the items and the pairings (`items`, `assignedTo`) at file scope and runs the allocator; `Features/Match-Roster.lua` holds the pool (`pools`, `poolsGeneration`); `Features/Match-Search.lua` merges bands and decides which gifts are still searching. `Features/UI-Window.lua` draws it all, `Features/UI-Assignment.lua` takes the player's manual choices, and `Features/UI-Mailbox.lua` drives the mailbox lifecycle. The TOC order `UI-Picker`, `UI-Window`, `UI-Assignment`, `UI-Mailbox`, `UI-Reopen-Button` is load-bearing: each captures what the one before it created.

### Debounced Bag Scanning

`BAG_UPDATE` fires on every loot, sale and stack merge; `GET_ITEM_INFO_RECEIVED` fires once per item against a cold cache, and counts only for an item the last full scan rejected as `NOT_CACHED` (`Scanner:IsPending`) that resolved with `success ~= false`. The pending set is wiped on every scan. Neither event scans directly. `ScanSoon` sets `bagsDirty` and returns at once unless `WouldRescan()` holds: the database exists, no distribution run is busy, and either the window is shown or a mailbox is waiting on it (`UI:WaitingToOpen`). A run is excluded because the Distributor's slots stay full until each send is confirmed, and the `BAG_UPDATE` the deliveries raise brings the scan back round anyway. Only then does it arm a `SCAN_DEBOUNCE` (2s) timer, since one loot fires several `BAG_UPDATE`s.

When the timer fires it asks `WouldRescan()` again, because the window can close and a mail run can start inside the debounce. With the window shown it runs `EnsureScan` and `UI:Assign()`, re-matching against the pool already found and leaving the search plan alone. Otherwise it calls `UI:OpenIfWaiting`: a mailbox that opened on nothing to give arms `waitingToOpen`, because that answer is often the cold cache's, and the first rescan that finds a gift opens the window there instead of making the player walk away and back. `waitingToOpen` clears when the window opens or the mailbox closes, and is also checked against `ns.AtMailbox()`, since `MAIL_CLOSED` skips Escape on Era; so the window never opens away from a mailbox, where a panel appearing because the player looted a green is the add-on talking over the game. Away from a mailbox `bagsDirty` stays set and the next `MailboxOpened` pays for one scan when the answer is needed.

**A mailbox visit is handled once.** `MAIL_SHOW`, `MailFrame`'s `OnShow`, the interaction manager and the Distributor's own `MailFrame:Show` can all report one mailbox, so `visitHandled` makes every report after the first free. It is skipped entirely while `Distributor.busy`, and cleared once the mailbox is gone. The event log classifies `BAG_UPDATE` with `MatchList:WouldRescan()` and `GET_ITEM_INFO_RECEIVED` with `MatchList:WouldRescanItem(itemID, success)`, the same tests the handlers use.

### Item Data Caching

`C_Item.GetItemInfo` returns `nil` for an item the client has not resolved. The scanner rejects that slot as `NOT_CACHED` instead of treating it as empty, and `GET_ITEM_INFO_RECEIVED` for that item marks the scan stale so the next pass re-reads it. Without that a cold cache reads as an empty bag and the window declines to open.

Stats are read twice and merged by the max per stat, never the sum. `GetItemStats` resolves the base item and returns nothing for a random suffix; the tooltip renders the item as the player sees it. Both report the same number on a fixed-stat item, so a sum would double it. `record.statRead` keeps each source's own answer for the Item Verdict report. A `C_TooltipInfo` read counts only when it carries real text: with `SurfaceArgs` missing every `leftText` is nil, so counting lines would succeed empty.

`Tooltip:StatsFromLines` is pure (no tooltip, no item cache, no client state), so the API report can feed it literal lines. Each line goes through `CleanLine`, then four readers in order:

1. **`+N Name`**, the number-first shape most locales use, against the lowercased client string of every `ns.Data.STAT_MAP` global plus the English `ENUS_FALLBACK` names.
2. **`SplitStats`**, for a line holding two stats: TBC writes "+42 Healing Spells and +14 Damage Spells", whose whole tail names no stat. It splits at each `+N`, and a half that still names nothing is retried with its last word dropped, by position rather than spelling, so a translated "and" goes too. A line with any half unresolved still counts as unread.
3. **`ReadFormatted`**, which turns each long `ITEM_MOD_*` format behind a `_SHORT` `STAT_MAP` key that carries a sign and an amount (`"%c%d Intellect"`) into a pattern, because koKR writes the name before the number (`"지능 %c%d"`) and the first reader never sees those lines.
4. **`EQUIP_PATTERNS`**, English clients only (see Localization).

A line carrying a signed number that no reader resolves goes back as unread for Item Verdict, whichever side of the name the number sits on. Only that shape counts, because reporting every prose line would bury the one that matters.

`MatchList:Candidates(item)` (`Match-Roster.lua`) caches the ranked recipient list on the item as `_candidates`, stamped with `_candidatesGeneration` against `poolsGeneration`. Ranking is asked for once per allocation pass, once per dropdown open and once per mouse-over of a recipient button, and walks every admitted class against every pooled player. The generation bumps in exactly one place, `AddResults`, and only when a pool entry changed: a new player, a known one now flagged `guild` or `alt`, one seen at a higher level, or one seen in a different area. `RescanBags` needs no bump because it replaces every item table. Ranking never reads `item.recipient`, so an assignment cannot stale the list. Settings the ranking reads (`profile.sendToAlts`, each alt's include, specs and gear levels) bump nothing; the cache stays right only because their setters call `ns.RefreshMailWindow`, which rescans. **The list is handed out by reference**; a caller that sorts or removes in place poisons it for every later caller. Derived per-item fields carry a leading underscore (`_weaponKey`, `_candidates`) to keep them out of the record's public shape.

## Scoring: Claim, Fit and Coverage

Three numbers per class per item answer three different questions, and the separation is load-bearing.

**Where the weights come from.** The recipient's spec is unknowable, so the add-on assumes one. Each flavor folder's `Match-Specs` file lists every spec as `ns.Data.SPECS[class]`: a `key`, a `role` (`HEALER`, `CASTER`, `MELEE`, `RANGED`, `TANK`), the stats it builds around (`main`, 2 points) and the stats it gears for (`useful`, 1 point). Paladins ship with Holy and Retribution on, shamans with Restoration and Elemental; druids ship with Restoration and Feral (Balance off, and Guardian off in Mists), warriors without Arms, and in Mists monks with Mistweaver; the specs left out carry `off = true`. Season of Discovery adds rune roles (rogue, shaman and warlock tanks, the arcane mage healer, the melee hunter) as specs that start off. The **Classes & Specs** section of the **Recipients** options panel (`Options/Options-Recipients.lua`) turns any spec on or off; `profile.specs[class][key]` stores only what differs from the default, so a default changed in a release reaches everyone who never touched it.

`ns.Data.RebuildStatWeights` (`Match-Derivations.lua`) sums the specs that are on into `ns.Data.STAT_WEIGHTS`, on a three-spec scale of 0 to 6. Main stats are averaged over the specs that are on and multiplied by three, so a Holy-only paladin weighs 6 on Intellect, as committed as a mage. Useful stats sum over the specs that are on, scaled by `min(1, 3 / #specs)` where `#specs` counts every spec the class has, on or off, so one spec's secondary never triples and every four-spec class (a Mists or Mainline druid, the Discovery classes with a rune role) is scaled to three quarters. A class with every spec off has no weights and is offered no gear (consumables are unaffected). It also records `ns.Data.MAIN_STATS`, which stats each class builds on. MP5 is main for every healer on the Classic-era folders; Mists and Mainline healers build on Intellect and healing alone. Nobody levels on Defense, so defensive stats weigh nothing for anybody. The weights are rebuilt at load, again once saved variables exist, on every spec change and on every profile change; a verdict cached on an item is not, so a caller that changes a spec rescans the bags too.

**Every stat is read through its budget first.** `ns.Data.StatPoints` multiplies a stat's tooltip number by the flavor folder's `ns.Data.STAT_BUDGET` (1 for an unlisted stat) before any weight touches it. Classic writes "+1% crit" as 1 beside "+10 Strength", so read raw a percentage could never decide an item; Vanilla's budget makes 1% crit worth 14 points. TBC's ratings need no conversion.

- **Claim** (`Matcher:SpecScore`): only the stats the weights rank for that class. Decides who is *admitted*.
- **Fit** (`Matcher:Score`): claim plus, for anything on the weapon matrix (weapons, shields, held off-hands, relics), `WEAPON_BASELINE` (0.15 times item level), which keeps a statless weapon placeable. A class with no weights gets nothing. Decides *ranking*.
- **Coverage** (`Matcher:Coverage`): the share of the item's scoreable stats this class ranks at all, 0 to 1. Decides *breadth*.

Coverage exists because a score sums, so breadth loses to one large weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0, a tie the warrior would win with half the item dead on him. A class enters contention by clearing both `CLASS_SHARE` (0.35 of the best claim) and `COVERAGE_MAJORITY` (strictly more than 0.5). Failing either leaves it admitted: in the dropdown, and a fallback when nobody better is in range.

The coverage denominator is every stat some class ranks with the specs now on, not the item's own stat line. Adding a stat weight is therefore never only a scoring change: it enlarges the denominator on every item carrying that stat and can demote a class out of contention. Turning a spec off can shrink it the same way.

**Coverage abstains when it demotes everyone.** It is a relative test, so a field where nobody clears the majority carries no information: on a two-stat roll where every class that clears `CLASS_SHARE` ranks only one half, each sits at 0.5. `Verdict` then falls back to everyone who cleared `CLASS_SHARE` alone. An item with nothing scoreable returns coverage 1, not 0: those are placed by the weapon baseline, and 0 would bin them all.

**Consumables skip the stat scoring.** Claim and fit are both 1 for every eligible class, every eligible class is admitted and in contention, and the level band does the rest. Eligibility comes from the row's `restores`, `buffs` or `enhances` value through the flavor folder's `ns.Data.CONSUMABLE_CLASSES` (see Adding a New Giftable Consumable).

**Faction filters the class list.** `AllClasses()` in `Match-Engine.lua` keeps only the classes `ns.Data.FACTION_CLASSES` lets the player's faction roll, so a class nobody in reach can be never wins a tie. Until `UnitFactionGroup` answers it returns the union of every `FACTION_CLASSES` row and retries next call; once it answers, the result is memoized for the session. Its source list, `EVERY_CLASS`, stops at the monk, so a later class added to a flavor's `FACTION_CLASSES` does nothing until it is added there too.

**The primary stat names the class.** An item carrying Strength, Agility or Intellect leads only with the contenders that build on one of those (`MAIN_STATS`); failing that, with the admitted classes that gear for one, which can bring back a class coverage dropped; failing that, nobody leads and it is not a gift. Secondaries never name a class on their own, which is what stops a mage leading a Mists Agility cloak on its crit and mastery.

**Body armor leads with its natural wearers.** Among the contenders, only the lowest priority group stays: a Holy paladin wants Intellect as much as a mage, but an Intellect robe leads with the cloth wearers and the paladin is a fallback. Cloaks, rings, weapons, shields and held off-hands are untouched.

**Stamina is everybody's.** Coverage leaves it out of the denominator, so a mage uses all of "of the Eagle", and it does not count as a judged stat. A weapon carrying only Stamina takes the everyone-fallback when no eligible class weights Stamina, while one carrying a stat nobody eligible wants (a Spirit shield) goes to nobody. Where a class does weight Stamina (Classic warlocks), that class holds a real claim on a Stamina-only staff, dagger or wand and is the only one admitted.

The verdict's headline `best` class comes from the contenders, never the admitted list, with ties going to the lower priority group; a class with no group sorts as 9.

### Verdict States

`gift` and `leftover` split at `ns.Data.LEFTOVER_THRESHOLD` (1.0). An item with no eligible or no admitted class is always a leftover, and so is statless armor that is not a weapon, shield, held off-hand or relic, since only the weapon matrix can place an item with no stats. `unreadable` exists because an item whose random suffix failed to parse looks exactly like a worthless one, and telling a player to vendor an item nobody evaluated cannot be undone. A piece of gear is `unreadable` when at least one class is eligible, it carries a suffix id and nothing parsed; the no-eligible-class leftover is decided first. Unreadable items are held out of auto-assignment entirely, and out of the disenchant step.

## Item Rules

The weights rank one stat at a time and cannot say that a *pair* of stats means something neither says alone. Each flavor folder's `Match-Rules` file holds that layer as `ns.Data.ITEM_RULES`; `Features/Match-Derivations.lua` does the matching. A rule matches on exactly one of: a `weapon` key list, a consumable `form` plus `restores` (both required), or a stat list `requires` (optionally `exclusive`, optionally `without` stats that must be absent, optionally narrowed to body `armor` of a material). `Matches` tests the `unclaimed` condition first, then weapon, then consumable, then stats, and stops at the first matcher it finds.

| Verb | Effect | Timing |
|---|---|---|
| `veto` | Removes the class outright. The only absolute verb. `vetoUnlessRole` does the same to every class with no spec of that role turned on, read live through `ns.Data.ClassHasRole`. | Before anything is scored, so a vetoed class is gone from every answer downstream. Skipped for consumables. |
| `prefer` | Names the contenders, replacing what scoring chose. | After scoring, narrowed to classes already admitted. **First match wins.** |
| `demote` | Drops the class out of contention, keeping it admitted as a fallback. | After `prefer`, so no rule can promote a demoted class back. Accumulates across every match. |

**Rules are soft by design.** A rule decides who is in contention, not who is admitted, so an "of the Owl" staff still reaches a hunter when nobody else is in range. Every flavor vetoes Healing against every class with no healer spec on (`vetoUnlessRole = "HEALER"`) and Spirit against warlocks. The Classic-era folders (Vanilla, Discovery, TBC, Camelot, Wrath) add Spirit against shamans and paladins and Intellect `without` Agility against hunters; Mists and Mainline have neither. Each veto must outrank the half of the item the class does want, or "of the Owl" buys a warlock back in through the Intellect.

`prefer` being first-match-wins makes table order data. An Agility, Intellect and Spirit item matches the Intellect and Spirit rule (priest, mage, druid) before the Agility and Intellect rule (hunter), so moving the second above the first changes who leads. The first matching `prefer` is used even when nobody it names is admitted, in which case it changes nothing and still blocks every `prefer` below it.

`unclaimed = true` is a condition, not a verb: the rule applies only when no eligible class had any stat claim (the case `Verdict` calls `offerToEveryone`, where a statless weapon is placed by its baseline). It pairs with `prefer` or `demote`, never with `veto`, which runs before anything is scored. One rule uses it: an unclaimed bow, gun or crossbow is the hunter's. A stat-bearing ranged weapon is still decided by its stats, which is why the condition is "unclaimed" and not "ranged". Consumables take `prefer` and `demote` with no claim context, so `unclaimed` never matches one.

`ApplyDemotion` falls back through the scoring, not past it: contenders, then the scoring's own answer, then the admitted list, first non-empty wins. Reaching straight for the admitted list would promote the classes coverage just demoted. The last resort exists for heavy armor carrying Intellect too far below its material's training level for `PROFICIENCY_REACH` to reach the hunter or shaman it was itemized for, which leaves only the warrior; that case is why the Intellect rule is a `demote` and not a `veto`.

**`exclusive` counts ranked stats only.** Armor and resistances sit on half the items in the game and are unweighted, so counting them would make a bare Stamina ring qualify for the Stamina-alone rule where a bare Stamina chest did not.

**What a rule cannot see.** A consumable rule needs both `form` and `restores`, and `restores` matches `def.restores` only, so no rule can key on a scroll's `buffs` or an oil or stone's `enhances`; a rule naming `form = "OIL_STONE"` or a `form` with no `restores` silently never matches. `weapon` rules require `classID == 2`, so shields, held off-hands and relics never match them. `armor` rules exclude cloaks, rings, necks and trinkets (`UNIVERSAL_EQUIP_LOC`).

## Recipient Ranking

`Matcher:RankCandidates` (`Features/Match-Ranking.lua`) orders the pooled players of the verdict's **admitted** classes, each filtered against its own class's level band, plus every class one of your alts in the pool plays (see Alts as Recipients). The keys, in order:

```text
fit bucket -> source -> placement -> level proximity -> armor/weapon group -> class fit -> shuffle -> name
```

**Source and placement follow the Recipients panel** (`Options/Options-Recipients.lua`). `Matcher:SourceRank` is 1 for an alt while `profile.prioritizeAlts` is on, 2 for a guildmate while `profile.prioritizeGuilds` is on, and 3 otherwise; an alt who is also a guildmate falls back to 2 when only the alts switch is off. `Matcher:Source` is the raw 1/2/3 the picker files sections under, whatever the switches say. `Who:PlacementRank` turns placement into the sort key: with `profile.prioritizeLevelingZones` on, `PLACED_LEVELING` 0, `PLACED_UNKNOWN` 1, `PLACED_ELSEWHERE` and `PLACED_INSTANCE` 2; with `profile.prioritizeOutsideInstances` on, an instance adds 3. A switch that is off drops its key rather than reversing it. All four switches default on and are read as `~= false`. `profile.ignoreSummonerWarlocks` (off by default) skips stranger warlocks in `ns.Data.SUMMONER_MIN_LEVEL` to `SUMMONER_MAX_LEVEL` (20 to 25), the band summoning alts park in, because `/who` cannot tell a parked alt from a real one; alts and guildmates are never skipped by it, and the guild roster keeps its own always-on 20 to 23 rule.

Bucket leads, so a class that wants the item beats one that barely does however close to equipping it they are. **Placement** (`Who:Placement`, `Features/Recipients-Zones.lua`) is where the candidate stands, the best evidence `/who` gives that they are levelling: `PLACED_LEVELING` for a zone in `ns.Data.ZONES` whose range fits their level within `ZONE_LEVEL_SLACK` (2, either side), `PLACED_UNKNOWN` for no area (an offline guildmate) or a listed zone their level does not fit, `PLACED_INSTANCE` for a dungeon or raid, and `PLACED_ELSEWHERE` for any other area the table does not list: a capital, a battleground. **Instances are area records, not maps.** `Who.InstanceNames` names each `ns.Data.INSTANCE_AREAS` AreaTable ID through `C_Map.GetAreaInfo` on first use, the same record `/who` names a player's zone by; the uiMap list is never used, because Classic Era and WoW Forever ship no dungeon maps at all. The Recipient Roster report prints how many it named. No placement is excluded. Level comes before group, so a druid one level off beats a mage two off for cloth.

**The band runs below gear and above consumables.** Gear anchors to the top: `[equipLevel - LEVEL_GAP_WIDEST, equipLevel - LEVEL_GAP_CLOSEST]`, which is 2 and 1, so a level 19 sword goes to an 18 over a 17 and never reaches a 19. It arrives just before it becomes useful. A consumable anchors to the bottom, its own use level, with a band `CONSUMABLE_RECIPIENT_GAP` (2) levels up, so a potion goes to whoever drinks it now. `LEVEL_GAP_WIDEST` must stay above `LEVEL_GAP_CLOSEST`; equal values collapse the band to one level. `CONSUMABLE_RECIPIENT_GAP` is not `profile.consumableLevelGap`: that is the sender's threshold for when their own potion counts as spare.

**The band is per class, not per item.** `Matcher:LevelBand(item, class)` measures back from the level that class could first equip the item. `item.bandLo` and `item.bandHi` are the union across classes and exist for the tooltip and the reports only.

The `shuffle` tail is rolled once per player as they enter the pool, never inside the comparator: `table.sort` throws on a comparator that changes mid-sort. Without it every spare green goes to whoever is early in the alphabet.

**One recipient floor, in one place.** `ns.Data.MIN_RECIPIENT_LEVEL` (5) is enforced only in `MatchList:AddResults` (`Match-Roster.lua`), the door every source comes through, so a source added later inherits it. Levels 1 to 4 are where bank and profession alts sit. Turned-away players are counted before the dedupe.

**Fairness is a session cooldown.** `Features/Recipients-Fairness.lua` records each gift as `name -> { level }` in a file-local table, so every login starts it empty. A recipient is fresh again once seen at a higher level than when last gifted. `Fairness:PickFrom` makes two passes over the ranked list: the first candidate who is free, reachable and fresh, then the first who is merely free and reachable, so an item is never stuck for want of a fresh face. Unreachable means the server refused mail to that name this session (`Fairness:MarkUnreachable`). Your own alts are never on the cooldown.

### Armor Proficiency Reach

`ns.Data.NATIVE_ARMOR` rows are steps, `{ from level, armor worn }`, read through `ns.Data.NativeArmorAt`. A hunter trains mail at 40, and Blizzard itemizes the level 35 to 39 mail for the classes that train it at 40, so a level gate that meant "cannot wear this yet" must not also mean "is not who this is for". A later training level therefore moves the band instead of closing the door: `ns.Data.ArmorEquipLevel` answers the item's own requirement or the class's training level, whichever is later, and the priority group is computed there. A level 36 mail belt is wanted at 38 to 39 by the hunter and 34 to 35 by the paladin. `Matcher:BandGroups` splits the classes into one group per band; the main plan merges bands (see /who Search Planning), so the belt costs one 34 to 39 span, while a targeted search asks one class per attempt.

`ns.Data.PROFICIENCY_REACH` (5, `Data/Data.lua`) bounds it: an item further below the training level than that is ineligible outright, because a level 20 mail belt is no gift to somebody who first wears mail at 40. Training levels are probed off `NATIVE_ARMOR` (up to `MAX_PROBE`, 90, local to `Match-Derivations.lua`) and never listed a second time. The armor group is the class's native `ARMOR_WEIGHT` minus the item's, plus one (cloth 1 to plate 4).

Weapons have no reach. Each `ns.Data.WEAPON_SPECS` row gives, per class in `WEAPON_CLASS_ORDER` order, how many of the three trees build around that weapon: 0 means the class cannot receive it, and the priority group is 4 minus the count. Count a column against `WEAPON_CLASS_ORDER`, never a padded legend, which StyLua leaves to drift. `Match-Derivations.lua` reads `WEAPON_CLASS_ORDER` and `SPECS` at load, so it must load after the flavor folder. Relics (librams, idols, totems) are armor with no material, so `RELIC_SUBCLASS` gives each relic subclass a weapon key and its `WEAPON_SPECS` row names the one class that can equip it; left to the armor path, a relic was offered to whoever its stats suited, a Stamina idol to a warlock.

## Allocation

`MatchList:Assign()` rebuilds every unpinned pairing from scratch on each pass, against the whole roster. A row is `pinned` when the player chose a recipient, kept the item, or unticked it, and the allocator never rebuilds over a pin.

Items are handed out **scarcest first, then best first**. One item per person per pass makes this an allocation problem: an item two people can receive must pick before one fifty can, or the broad item takes one of the two and the narrow one gets nobody. An item nobody can receive sorts last; zero is the impossible case, not the scarcest. Your own alts are exempt from one-per-person (`IsTaken` ignores them), since several gifts in your own mailbox is nobody's spam.

**The disenchant step runs last.** With `profile.disenchantUnmatched` on, once everyone else is paired, each unpinned, unmatched `MatchList:Disenchantable` row (gear in the `leftover` state, never consumables, Pending Match rows or unreadables) goes to `ns.Alts:DisenchantRecipient()`. Those rows stay unpinned, so a change that turns a Kept row into a gift takes it back.

When the pass leaves no gift still searching, `ns.Who:Clear()` drops the plan; otherwise `ns.Who:Prune` narrows it. During a targeted search (`ns.Who.targeted`) `NarrowTargeted` (`Match-Search.lua`) narrows that search instead (see /who Search Planning). **Still searching means an unpinned `gift` row that is unmatched, held only by a fallback, or held by somebody `Who:KeepsSearching` says a better-placed find would beat** (a placement rank of 2 or more: a capital or a dungeon, as the Recipients switches weigh them; an offline guildmate ends the search): the zones still on the plan may turn up somebody out levelling, and the plan running dry ends it. Leftovers and unreadables never count, or the plan would never empty. A pairing with a class outside the verdict's contenders keeps that item's band on the plan, narrowed to the contenders, and because every pass re-decides, a contender found later takes the item off its fallback.

**Every row starts ticked, and a tick means give this away**, so no row needs ticking before it is searched for. The tick does not pin, so a fallback stays provisional. Unticking is the player's keep and pins the row; it keeps any name it held so a re-tick restores it, and no search, pass or rescan re-ticks it. `RescanBags` carries `send` and `pinned` across by slot, restoring the player's pinned picks first so two rows set by hand to one name both survive, and an automatic pairing only if its name is still free. Ticking a bare row unpins it and runs the allocator; ticking a row with a name keeps it pinned. A row whose name the server refused keeps its tick and returns to auto-assignment.

**Closing the window releases the automatic pairings** (`MatchList:ReleaseAutomatic`). Pinned rows keep their names and the pool survives, but nothing is matched again until Find Recipients is pressed.

## /who Search Planning

`C_FriendList.SendWho` is hardware-event gated. A call outside a real click raises `ADDON_ACTION_BLOCKED` and does nothing else: no error, no `WHO_LIST_UPDATE`. Queries cannot be chained on a timer, so every press has to be spent well. `Recipients-Who-Plan.lua` builds and maintains the plan; `Recipients-Who.lua` sends it, and counts and explains a block if one happens anyway.

**One class filter per query, never a list.** The client honors one `c-"..."` and silently drops the rest of an OR'd set (verified on Classic Era 1.15.9: `c-"Paladin" c-"Rogue" c-"Warrior"` answered with paladins alone). A zoned query carries a class filter only when exactly one class is wanted, and the per-class stage asks one class per query. A class list naming every class sends no `c-` filter and skips the per-class stage. Multiple `z-` filters are kept as a best effort: if the client honors only the first, the query still answers correctly from that zone.

**Female class names get their own query.** Where the locale gives a class a distinct female name, every single-class step gets a twin with the female filter, sent right after the male one, since `/who` may match only the name a character's gender uses (unverified in game, which the code says). Zone chunks budget for the longer of the two filters, `Who:Exhausted` never lets one gender's answer exhaust the other, and pruning treats the pair as one class.

The main button's plan, per span:

```text
52-57 z-"Felwood" z-"Winterspring"
52-57
52-57 c-"Warrior"
52-57 c-"Paladin"
```

**Zones first**, because somebody out in a zone made for their level is levelling, and that is who a gift is for; a bare query fills its 50 mostly with people standing in a capital. The bare query is the fallback behind the zones, then one class at a time. A zoned answer never ends anything (see below), so every zone gets its press before the fallback. Bands reach the planner already merged: `MergeBands` (`Features/Match-Search.lua`) joins any bands that touch or overlap, at any width. `Coalesce` then runs the same `MergeBands` with a span test, folding bands into one span while the merged span stays within `SPAN_MAX` (6) levels from its first band's low end, and never splitting one: an item's band is two levels wide, so gear for 52, 53 and 56 would otherwise cost three presses. Folding unions the classes, and a band naming no class makes the whole span class-free. Wider than that and the 50-result cap thins each band's share. Spans are interleaved rather than run to exhaustion, so a level 15 cloak and a level 45 sword both make progress.

**An answer under the cap ends what it answered.** `Who:Exhausted` drops every planned attempt inside the same levels with the same or a narrower class filter, zoned attempts included. "Capped" is `raw >= WHO_RESULT_CAP (50) or total > raw`, reading the server's own total from `GetNumWhoResults`. A zoned answer never exhausts anything, since the client may have honored only its first zone; nor does an answer that failed to parse.

`FILTER_MAX` (240) is a hard budget on the filter string: over it the server does not answer at all, so `ZoneChunks` splits zone lists to fit against the level text plus the class part, sending the whole span's levels with each chunk. A chunk is never empty; a zone whose name alone exceeds the budget still gets its own query.

**Zone order decides how many presses a search takes.** `ns.Data.ZonesFor` (in `Features/Recipients-Zones.lua`, not `Data/`) sorts on overlap with the band, then centrality (how close the band sits to the middle of the zone's range), then the narrower zone, then table order. The edge of a zone's range is where people pass through; the middle is where they sit and quest. An unresolved faction admits every zone: over-including costs one empty query, excluding on nil drops half the list. A zone the client has no name for is cached as `false` by `Who.AreaName` and skipped, never sent as `z-""`.

**`Who:Prune` only ever removes.** It narrows a running plan to the bands that still have somebody to find. Re-planning through `Who:Plan` would rebuild from the best-first attempt and re-send it, so a search re-planned on each press would never get past its first zone. A survivor's classes are intersected with what the remaining bands want, and an empty intersection drops the attempt rather than sending it wider than before. An attempt with no class filter survives while any band overlaps it.

**A settings change re-plans.** `UI:Rescan` feeds the freshly merged bands to `Who:Plan` before assigning, so a raised rarity cap searches for what is on the list now. Found players are kept; only the places left to look are rebuilt. `Who:Plan` and `Who:Clear` both cancel whatever query is pending and reset `Who.targeted`.

**Find Recipients for This Item** plans with `Matcher:TargetedBands` and `targeted = true`: one class per attempt, contenders first, then the other admitted classes, each half sorted by armor group then fit (`Matcher:TargetedClasses`), with no folding and no bare query, because a bare query is what the main button already sent. The plan runs in two stages: every class in its zones first (`38-39 z-"Desolace" c-"Hunter"`), then every class anywhere (`38-39 c-"Hunter"`) as the fallback. A consumable keeps its classes in one group, so its zones go out with no class filter, then each class anywhere. The press refuses with `L["WHO_WAIT"]` while a query is in flight or the throttle runs, checked before retasking, so a press that cannot send does not cancel the current plan. The search tracks its row by slot key (`MatchList:Target`), because `RescanBags` replaces the item tables. After every answer `MatchList:Assign` calls `NarrowTargeted`, which drops each attempt whose class could not outrank the row's holder (`Who:PruneTargeted` with `Matcher:CouldOutrank`: bucket, then source, so a stranger never outranks an alt or guildmate in the same bucket, then placement, so a holder with a placement rank above 0 can always be outranked, then distance from each class's own anchor, then group, then fit, ties never outranking; an attempt with no class filter is tested against every admitted class). The search ends once nothing is left, or at once when the row is gone or pinned. The `targeted` flag exists because the rule that ends a full search (every gift has a contender) must not end a targeted one. It retasks the shared plan; the main button keeps stepping it while `Who:Remaining()` is above zero, and rebuilds the full plan once it is empty.

**Timing.** `WHO_THROTTLE` (5s, exposed as `Who.THROTTLE` and read by `UI:LockFindButton`) runs from the send, not the answer: a reply often lands in under a second, and re-enabling then offers a press the server refuses for four more. While locked the button reads "Searching..."; otherwise it always carries the one Find Recipients label, because chat lines tell the player to press that button by name. `RESULT_TIMEOUT` (6s) puts an unanswered query back on the front of the plan, since a blocked call never fires `WHO_LIST_UPDATE`. `Who:Step` returns `false, 0` while any job is pending.

**The Who panel is deafened for the life of each query.** The stock UI opens the Who panel on `WHO_LIST_UPDATE` when results route to the UI list, and the panel is a UIPanel: opening it over the mailbox makes the panel manager close `MailFrame`, which ends the mailbox interaction. `BeginQuery` unregisters `WHO_LIST_UPDATE` from every frame `GetFramesRegisteredForEvent` names except the add-on's own dispatcher (`ns.eventFrame`), skipping forbidden ones, and sets `SetWhoToUi(true)` so `GetWhoInfo` can read the answer; `EndQuery` re-registers exactly those frames, restores `SetWhoToUi(false)`, and hides the panel only if it was not already open when the query began. Naming `FriendsFrame` and `WhoFrame` is only the fallback for a client without `GetFramesRegisteredForEvent`: on Forever's Retail-based UI the panel still opened over the mailbox with both of them deaf. The `PLAYER_LOGIN` hook counts the panel opening while a query is out (`counts.panelOpened`), and the roster report prints that count and the names of the frames that hear an answer, so a Forever session shows whether the deafening held. The answer is parsed under `pcall` and `EndQuery` runs either way, or a parse error would leave the player's own `/who` silent until a reload. A query the player abandoned is marked `canceled`, never dropped, so its answer still lands and still runs `EndQuery`; a canceled job gets no callback, no `Exhausted`, no requeue on timeout, and is not counted by `Who:Remaining`.

A capped answer is counted and otherwise ignored: the search stops once somebody in contention holds each item. The Recipient Roster report reads the count, because a capped answer separates a thin realm from a thin sample.

**Other-faction results are dropped.** Forever answers `/who` with both factions, and mail does not cross them. A result carries only its localized race, so `Recipients-Who.lua` builds a race-name to faction table from `C_CreatureInfo.GetRaceInfo` and `GetFactionInfo` (race IDs 1 to 100). A race it cannot place, or one two factions share (marked `false` once and never reassigned), is kept: a wrong drop loses a recipient for good, a wrong keep costs one refused send. Female race names differ from the male ones `C_CreatureInfo` gives in some locales, so a female character of the other faction can get through there; the mailer skips that recipient without counting the refusal toward its abort. Drops are counted in `counts.otherFaction`.

## The Guild Roster

A second recipient source, and on most realms the larger one: no button press, no throttle, the whole guild at once. `Features/Recipients-Guild.lua` hands its filtered list to a callback in the shape `/who` results arrive in, and `PullGuild` (`UI-Mailbox.lua`) feeds it to `MatchList:AddResults` and re-assigns only when something changed and the window is shown. Downstream the `guild` flag is the source key: guildmates rank 2, ahead of strangers, while `profile.prioritizeGuilds` is on.

`Guild:Request` is gated on a callback. `GUILD_ROSTER_UPDATE` fires on every login, logout, note edit and rank change in a large guild, and walking hundreds of rows with a `GetGuildRosterLastOnline` call apiece is work nobody asked for, so with no request outstanding the event is ignored. The one exception is the login save: `PLAYER_LOGIN` asks for the roster after 5 seconds, and the first update that carries members runs `Guild:Save()` with no callback. A second request overwrites the pending callback. The roster is pulled each time the window opens at a mailbox and when a fresh plan starts, never on a press that steps a running plan and never for a targeted search.

Rows with no name or no class token are discarded when the roster is saved, as the `/who` parser does. The rest pass `Classify`, which drops them by four checks in this order, each counted separately so "the guild added nobody" and "the guild has nobody active" can be told apart:

- **Your own characters**, at any level or recency.
- **Members you ignored** on the My Guilds panel.
- **Summoning alts**: a `WARLOCK` at levels 20 to 23, around where Ritual of Summoning unlocks. Always on, and separate from the opt-in stranger rule.
- **Inactivity**: offline longer than the My Guilds panel's **Ignore Offline Guild Members** (`profile.guildOfflineLimit`: `WEEK`, `TWO_WEEKS` or `NEVER`; `Guild.OFFLINE_DAYS`). `GetGuildRosterLastOnline` returns nothing for a member online now and four duration parts (years, months, days, hours) otherwise, summed as `years * 365 + months * 30 + days`; a member is kept at or under the limit, and `NEVER` keeps everyone. An offline member with no reading counts as too old, because the roster arrives in pieces and guessing "recent" mails gear to somebody who quit.

There is no level floor in this file; `MIN_RECIPIENT_LEVEL` in `AddResults` covers every source.

**Own-character detection reads `ns.db.sv.profileKeys` and `ns.db.global.characters`.** `profileKeys` is AceDB's record of every character that has loaded the add-on, keyed `"Character - Realm"`; it lives on `db.sv`, not `db`, because AceDB's metatable resolves only scope names, so `ns.db.profileKeys` reads `nil` and the check silently passes everybody. Each key is rebuilt as `Character-Realm` through `ns.NormalizeRealm`, which strips spaces and hyphens, to compare against qualified roster names; every recorded alt and the current character join it. An alt that has never run the add-on is not caught; that is the honest limit.

**Identity is not the address.** The roster and `/who` can spell one same-realm character differently, one bare and one suffixed `-Realm`, so roster rows, the current character and the `AddResults` dedupe all go through `ns.QualifyPlayerName` (`Features/Utilities.lua`). The pool entry keeps the name exactly as an API produced it, because that is what `SendMail` takes. Pooling one person twice means mailing them twice, since `assignedTo`, the cooldown and Distribute's own guard all key on the entry's name. Never filter on the suffix: Classic realms are connected, so every name in reach is mailable.

**Saved guilds.** Every character saves its guild roster to `ns.db.global.guilds`, keyed `realm:faction:name` (`Guild:Key`, with the realm normalized), a few seconds after login and again at every live read. Each member keeps `days`, days offline at the scan. `Guild:ReadSaved` offers every ticked saved guild on this character's exact realm and faction, however old, leaving out the guild the character is in now, which is read live. Connected realms are not consulted here, so a guild saved on a connected realm is skipped even though an alt there is mailable. A member counts while their `days` plus the days since the scan is within the offline limit, so an old roster thins out member by member rather than being dropped whole, with the same `Classify` rules as a live read. **Ignored members** are kept as `entry.ignored[qualified name] = true`, which `Guild:Save` leaves alone, so an ignore survives the rescan that replaces `entry.members`; `Guild:Read` checks the current guild's entry too, so the live roster honors them. The panel lists `Guild:ListedMembers`: everybody `Classify` keeps plus anybody ignored, so an ignore can be taken back. Guilds have no Delete; unticking is the lasting choice, since a deleted guild comes back at the next login.

## Alts as Recipients

Each character records itself in `ns.db.global.characters` (`Features/Recipients-Alts.lua`) at login, on level up, after a respec (`CHARACTER_POINTS_CHANGED`, or `PLAYER_SPECIALIZATION_CHANGED` from Mists on): name, realm, class, level, faction and the spec it plays. The spec is `C_SpecializationInfo.GetSpecialization` (falling back to the global) when `ns.EXPANSION >= 5`, because Mists Classic has no global `GetSpecialization` and its `GetNumTalentTabs` is a stub that throws; elsewhere it is the talent tree with the most points, and `GetTalentTabInfo` answers with the name first on Classic Era and a numeric id first on the later clients, which moves the points from its third return to its fifth. A failed read keeps the spec recorded before. A login rewrites what the character is and never the player's choices on the same entry: `include`, `specs`, `levelsBelow`, `levelsAbove` and `disenchanter`, set on the **My Alts** and **What to Give Away** panels and from the mail window. Unset `include` means ticked below the level cap and unticked at it (`Alts:IncludedByDefault`, from `GetMaxPlayerLevel`), so a character that dings the cap drops out unless the player ticked it; the panel stores `include` only when it differs from that default.

**Which alts are in reach.** `Alts:Connected` accepts the same realm or one in the same `ns.Data.LINKED_REALMS` cluster, matched with spaces, hyphens and case ignored. `Alts:Address` mails the bare name on this realm and `Name-Realm` on a connected one. `Alts:Read` skips the current character and anybody on an unconnected realm or the other faction, and the whole source needs `profile.sendToAlts` on.

**An alt is judged by its own specs, not the class defaults.** `Alts:SpecsFor` is the ticked set, else the one spec the character last recorded, else every spec its class has. `Matcher:VerdictForSpecs` reruns the verdict with that one class swapped to those specs (`ns.Data.SpecOverride`, read by `SpecEnabled`), cached on the item by class and spec set, so a Retribution paladin alt is offered Strength plate while paladins default to Holy. An alt must be a contender under its own specs, and one that is ranks in bucket 1. Gear goes to an alt only between its **Lowest** and **Highest** Gear Level (`Alts:LevelRange`), compared with the level its class equips the item at: `levelsBelow` is 0 to 3 levels under its own level, `levelsAbove` 1 to 3 over it or `"ANY"` (stops in `ns.ALT_LEVELS_BELOW_ORDER` and `ns.ALT_LEVELS_ABOVE_ORDER`), and the panel stores neither at its default (0 and `"ANY"`), so an untouched alt takes anything from its own level up. Consumables keep the usual band.

**Mailing yourself is not giving.** Alts skip the one-per-person rule in the allocator and in `UI:Distribute`, are never on the fairness cooldown, and add nothing to the giving tally. An alt the server refuses is dropped through `ns.Alts:Forget` as well as marked unreachable, and the My Alts panel has a Delete; either way the character is recorded again at its next login.

**The disenchanter** is one character per realm cluster and faction, stored as `disenchanter = true` on its `global.characters` entry (`Alts:SetDisenchanter`) rather than in the profile, because the shared Default profile also serves characters that cannot mail it. `Alts:DisenchantChoices` feeds the pickers and `Alts:DisenchantRecipient` the allocator's last step.

**The My Alts and My Guilds panels are trees** (`childGroups = "tree"`), Magic Eraser's list layout, nested under Recipients by the category ID its `AddToBlizOptions` returned. `PrepareListTree` in `Options/Options.lua` seeds `treewidth` (`ns.OPTIONS_TREE_WIDTH`, 180) and the selected node (the character being played, or the guild it is in), and reseeds the selection each time the panel hides. Nodes are keyed by saved key, never position, so the selection holds when a row appears.

## Mailing

`SendMail` cannot be looped. One send goes out, then the run waits for a result event. Mailing a non-friend arms Blizzard's confirmation popup, the anti-spam guard for mailing strangers, and it is never auto-clicked.

Three ordering constraints, all load-bearing:

- **Check the Send Mail panel before touching the item.** `UseContainerItem` attaches only while Blizzard's panel is visible; with it closed the same call *uses* the item, so a consumable is drunk. Each job checks `ns.AtMailbox()` and postage first (failing either leaves the queue intact), then forces `MailFrame` open on the Send tab (`MailFrameTab_OnClick(nil, 2)`, under `pcall`), and finishes the run with `MAIL_PANEL_CLOSED` if `SendMailFrame` still is not shown.
- **Fill the panel after the attach.** Attaching writes the item's name into an empty subject box, so a subject set earlier is overwritten.
- **Never re-read the bag slot to verify delivery.** `MAIL_SUCCESS` fires before the bag update, so the slot still holds the old link. The stack size is captured as `job._count` before the send for the same reason, and `UI:Distribute` removes delivered rows by `uid`, since two copies of one green share a name and a link.

An attach can fail with the panel up, and `SendMail` will then post an empty letter and report success, so `GetSendMailItem(1)` is checked before every send. Each queued item's link is compared with its bag slot first; a moved item is skipped as `MAIL_ITEM_MOVED` and reported in its own summary. `UseContainerItem` and `SendMail` run under `pcall` so a throw cannot leave `busy` stuck, and a `SendMail` that throws releases the attachment through `ClearSendMail`. After each of those calls the job re-checks `busy` and that it is still the current job, because a UI error raised inside the call may already have finished it. On Era the body box is `MailEditBox:GetEditBox()`, since `SendMailBodyEditBox` is nil there. Postage is checked against `MAIL_COST` (30 copper).

**A send with no answer pauses rather than fails.** Each send arms a `RESULT_TIMEOUT` (30s, the mailer's own constant) because the confirmation popup can sit unanswered. When it fires the job moves to `_awaiting`, `busy` clears, and the player is told to Accept and press Distribute again. `SendMail` has already gone out, so a late Accept still delivers, and `Distributor:Result` records it on a run that has stopped, takes the job off the queue and reports progress so the row leaves the list. `Distributor:Stop` holds an in-flight job the same way. A held job blocks the next run for one more `RESULT_TIMEOUT` (`Start` prints `MAIL_STILL_SENDING`), or its late result would be credited to the new run's first job; after that `Start` clears it, since a send the player never confirmed produces no result at all and must not lock Distribute. Leaving the mailbox clears it too.

**Closing the mailbox stops the run.** `RecheckDistribute` (from `MAIL_CLOSED`, the interaction-manager hide and `MailFrame`'s `OnHide`) waits one frame, because the close and the interaction manager's report are not guaranteed to land in order, then stops a busy or queued run if `ns.AtMailbox()` is false and prints `MAIL_MAILBOX_CLOSED`. Without it nothing would clear `busy` before the 30 second timeout.

`UI_ERROR_MESSAGE` is watched because the server can refuse a send without either result event. The match set is built from the client's own `ERR_MAIL*` globals, skipping strings with a format specifier (they arrive already filled in), plus `ERR_PLAYER_WRONG_FACTION` by name, which lacks the prefix and is what mailing an other-faction player returns on Forever. `ns.Distributor:IsMailError` is that test, exposed so the event log filter and the Diagnostics API row call it rather than restating it. A refusal marks the name unreachable for the session (`Fairness:MarkUnreachable`) only once the job has been sent (`job._sent`); a refusal during the attach is about the item, not the recipient. `Distributor:DropRepeats` then drops every other queued job for that recipient, so one bad name cannot spend the abort budget on its own. After a failure the run waits `FAILURE_SETTLE` (1s) so a second signal for the same refusal is absorbed instead of landing on the next parcel; inside that window an error only marks the name unreachable and releases its row. `Start` and `Stop` bump `Distributor._run`, so a settle timer from an earlier run never fires into a later one. The run aborts after two consecutive counted failures; wrong-faction refusals skip that recipient and never count. `Distributor:Finish` triggers a Generosity broadcast.

`UI:Distribute` sends one parcel per person per run (`MAIL_ALREADY_HAS_ONE` otherwise), enforced rather than merely intended, because two greens in one stranger's mailbox reads as spam and cannot be taken back. Your own alts and rows the player set by hand are exempt: their choice always stands.

## Mail Copy

`Features/Mail-Copy.lua` owns the subject and body. The subject and body are the player's own `mailSubject` and `mailBody` when set, cleaned by `Distributor:CleanText` (pipes stripped, line endings normalized, trimmed), and the stock `L["MAIL_SUBJECT"]` and `L["MAIL_BODY"]` otherwise. `Distributor.MAIL_FIELDS` maps each profile key to its stock string and its byte ceiling, and both the editor and the mailer read it, so they cannot disagree. **A custom body always ends with `L["MAIL_POWERED_BY"]`** after a blank line, because it replaces the paragraph that says where the gift came from; a custom subject adds nothing, since the body beneath it names the add-on either way.

**Custom copy is stored uncut and cut when built.** A subject past `SUBJECT_MAX` (31), or a body past `CUSTOM_BODY_MAX` (`BODY_MAX`, 500, less the footer and its blank line), is cut three bytes early by `Shorten`, trailing whitespace trimmed, and ends in `...`, never inside a multi-byte character; the footer is added after the cut so it always arrives whole. Every length is bytes, measured with `#`. There is no warning in chat: the editor's red counts are the warning. `Distributor:SaveCustomText` stores `""` when the text equals the stock copy, so a later change to the stock copy reaches the player.

## The Mail Window

The window (`PlayItForwardMailFrame`, `Features/UI-Window.lua`) is 652 wide and 470 tall, resizable from its corner grip between that width and 320 tall up to 1200 by 1000. It opens at the mailbox when the scan found something to act on (`HasSomethingToDo`: a ticked row with a recipient or in the `gift` state, or a Kept gear row while disenchanting is on and a disenchanter is set, so a mailbox holding only kept rows opens nothing), and never auto-closes. Opening is skipped while a run is busy. Items, roster and hand picks live at file scope and survive walking away; guild and alt names are read in on open, for the dropdown, without pairing them. It anchors beside `MailFrame` until moved, or at screen center offset right when there is none; `UI:SaveGeometry` saves `profile.windowPos` after a drag and `profile.windowSize` after a resize, and their `point` and `width` fields are what say the player moved or sized it. The portrait is `Includes/Images/Gift.tga` through `PortraitFrameTemplate`, falling back to `BasicFrameTemplate` and then `BackdropTemplate` on a client without it.

**The top bar mirrors the options panels**, writing the same profile keys. Consumables leads on the left, its tick and Level Rule dropdown on one line with the Food, Drink, Potions, Scrolls and Oils & Stones ticks beneath; Gear sits on the right with its rarity dropdown against the window edge, and beneath it the Disenchant tick and the disenchanter dropdown, right-aligned with it. A dropdown hides while its tick is off; the kind ticks disable and dim instead, so the row keeps its shape. Each tick's tooltip is the panel's own description. All three dropdowns, and every row's recipient button, come from one `BuildDropdown` and open `ns.Picker`. `UI:SyncControls` is the one place the bar is redrawn from the profile, called by the ticks, the panels' setters and `ns:ApplyProfile`; a tick then runs `UI:Rescan()` and sends `NotifyChange` to the General and What to Give Away panels, so the list and an open panel follow.

Rows sort into four sections, each headed with its count (Matched, Pending Match, Stats Couldn't Be Read, Kept), then by score, then bag order, because the list outgrows the window and the rows worth acting on would fall below the fold. An empty list shows a hint instead, and a status line above the buttons (`UI:StatusLine`) tells the player the next step: press Find Recipients, keep searching, open a mailbox, press Distribute, or accept each popup while sending. A row's tick is dimmed when nobody can be found for it (`UI:CanTick`). Item and recipient text never wrap, so a long name cannot draw over the next row, and a stack shows `xN`. Find Recipients and Distribute share one width, the widest of their five possible labels plus padding, at least 150 and capped at half the bar, so the bar does not jump as labels change. Distribute reads "Requires Open Mailbox" and is disabled away from a mailbox (`ns.AtMailbox`, never `ns.mailboxOpen`), reads "Sending..." and is disabled while a run is going, and is enabled only when a ticked row has a recipient. Find and Distribute both close the picker first.

**A row's dropdown** (`UI:PickerOptions` in `UI-Assignment.lua`) opens with **Keep Item**, which pins the row unticked, then every ranked candidate under the headers Your Alts, Your Guild and Strangers (an empty group is left out), a Disenchant section offering the disenchanter where it applies, or a disabled note when there is nobody, then a divider and **Find Recipients for This Item**. Every candidate can be picked. The notes beside a name (refused, has one, recent; one per name, in that precedence) are information, never gates: the player's pick is never refused. Picking a name that holds another unpinned row takes it from that row, which loses its recipient and its pin and is reassigned on the next pass; an alt's name is never taken, since an alt can hold several rows. `UI:PickerOptions` and `UI:PickerSelect` are frame-free so `Tests/Manual-Assignment.lua` can drive them.

**Escape closes the window** through `UISpecialFrames`, which only calls `Hide`. Everything that must stop on a close (the picker, a running distribution, the query plan, the automatic pairings) hangs off the frame's `OnHide` through `UI:OnClosed`, which `UI:Close` also calls for a window never shown. Every line of it is idempotent, since the X button runs both routes. `OnHide` returns early while the window still reports shown, which is Alt+Z hiding the whole UI. While the picker is open it takes the window out of `UISpecialFrames`, so Escape closes only the list and not the window with its mail run, and puts it back when it hides.

**Never close the window from `MailFrame`'s `OnHide`, and never gate on `MailFrame:IsShown()`.** Mail-replacement add-ons hide `MailFrame` and show their own, and the Who panel can swap it out mid-query. The `OnHide` hook exists only to recheck Distribute, because `MAIL_CLOSED` is skipped by Escape and by other add-ons, and Era registers no interaction-manager events. `ns.AtMailbox()` asks `C_PlayerInteractionManager.IsInteractingWithNpcOfType(MailInfo)` and falls back to the add-on's own `ns.mailboxOpen` flag when that is missing or throws.

**The reopen button** (`Features/UI-Reopen-Button.lua`, `PlayItForwardReopenButton`) is the way back for a player who closed the window at this mailbox, or whose mailbox listed nothing. It shows while `MailFrame` is shown, `ns.AtMailbox()` is true and the window is hidden, and is built on first need. It is parented to `UIParent` and only anchored beside `MailFrame`: a frame parented to a Blizzard panel stays protected for good, and writing to the panel taints it. A click runs `MatchList:EnsureScan()` then `UI:Open()`, since `Open` does not scan. `UI:SyncReopenButton` runs from `Open`, `OnClosed`, `MailboxOpened` and `RecheckDistribute`, and `UI:WantsReopenButton` is exposed for the Mailbox report.

`ns.Picker` (`UI-Picker.lua`) is one shared popup in `UISpecialFrames`: a full-screen click-catcher at `DIALOG` strata, the list above it, at least as wide as its button or `PICKER_MIN_WIDTH` (190) and at most `PICKER_MAX_WIDTH` (360), scrolling past `PICKER_MAX` (240) tall. Wider than that and `SetClampedToScreen` pushes the list back over its own button. Width is measured with a hidden ruler font string, because a font string anchored on both sides reports the width it was given. `TooltipBorderedFrameTemplate` draws no fill on Era, so a background texture is added on every flavor rather than `SetBackdrop`, letting skins win.

## The Giving Tally

`Features/Generosity.lua` keeps what this account has given away in `ns.db.global.stats`: `gifts` (one per mailing), `items` (quantity, so a stack of 20 counts 20), `itemLevels` (summed once per mailing, equippable gear only) and `value` (vendor sell price times quantity, in copper). `ns.Generosity:RecordSend(link, quantity)` is the only writer, reached from `Mail-Sender.lua` through `Credit(job)` beside `Fairness:Record` on both the normal delivery path and the late-delivery path, with the `_count` captured before the attach. `Credit` skips mail to your own alts. `Generosity:BlockLines(Generosity:Get())` renders it for both the unit tooltip and the Badge of Generosity panel's preview, so the two cannot differ.

## Sharing the Tally

`Features/Generosity-Broadcast.lua` shares the tally with nearby players and caches theirs; `Features/Generosity-Tooltip.lua` renders a peer's totals at the bottom of their unit tooltip. Classic has no custom channels and does not deliver add-on whispers to non-social strangers, so `YELL` add-on messages are the only reach to nearby strangers. **The feature is proximity-scoped by construction: a distant friend never appears.** These are `C_ChatInfo.SendAddonMessage` calls, never `SendChatMessage`, so nothing here is player-visible chat and no target marker applies.

The prefix is `ns.ADDON_MESSAGE_PREFIX` (`"PIForward"`, `Data/Data.lua`; the client caps a prefix at 16 characters), registered at load under `pcall`, so every login and reload registers it again. The payload is versioned and pipe-delimited, four integers at most, far under the 255-byte cut an add-on message takes silently:

```text
1|S|<gifts>|<items>|<itemLevels>|<value>    stats
1|?                                         ping
```

An unknown version or foreign prefix is dropped. Peers are cached by `ns.QualifyPlayerName` with their `GetTime()` stamp and good for `PEER_MAX_AGE` (1800s); expired entries are swept on the next stats message received, the only point the table grows, so it stays bounded without a timer. The span is long on purpose: an expired entry is refilled only by the tooltip's presence ping, so a short window would make a peer beside you flicker out between hovers. A share-on account broadcasts even at zero gifts, so presence shows before the first gift.

Both outgoing paths go through one `Send`, which runs `SendAddonMessage` under `pcall` and keeps what came back in `Generosity.lastSendResult`. A refused channel is a return value, not an error, and the send is otherwise fire-and-forget, so that field is the only place a refusal shows; Given Away Sharing prints it.

**Town only.** Every send and the tooltip block are gated on `ns.AtRest()` (`IsResting`, answering `false` when the API is missing), which keeps the feature out of raids, dungeons and open-world combat without reasoning about combat state. The gate is checked before the throttle on both outgoing paths, so nothing blocked in the world spends a window it never used. Receiving is not gated; a received ping is answered by calling `Broadcast`, which applies its own rest gate, throttle and `shareStats` check.

Two throttles, both against `GetTime()`:

- **`BROADCAST_MIN_INTERVAL`** (60s) caps our outgoing totals, ping answers included. It also absorbs the `PLAYER_ENTERING_WORLD` refire, `PLAYER_UPDATE_RESTING` and the post-run broadcast, which simply call `Broadcast`.
- **`HOVER_PING_INTERVAL`** (10s, tooltip side) caps presence pings fired by hovering unknown players. A ping is gated on the rest area only, not on `shareStats`.

**The tooltip block's shape is constrained.** A blank line, then the header from `ns:BuildBrandedLine` (`Features/Announcements.lua`, the same builder chat prints use, so the two surfaces cannot brand the add-on differently), then four indented rows. **Values are white**: the money row comes from `GetCoinTextureString`, which carries its own markup and ignores a color prefix, so any other color leaves it out of step. Labels are `HELP` silver, because gold field titles mark a control the player acts on. The hook is `TooltipDataProcessor`'s unit post-call only where `GameTooltip.GetPrimaryTooltipData` also exists: the Classic clients expose `TooltipDataProcessor`, but their native tooltips still fire only the legacy scripts, so a post-call registered there never runs. Otherwise it is `OnTooltipSetUnit` when `GameTooltip:HasScript` confirms the script type, and none at all on a client with neither, on `GameTooltip` only. `Generosity.tooltipHook` records which one installed. `C_Secrets.ShouldUnitIdentityBeSecret` is asked once the unit token is in hand and before any name or player read.

**Accepted latency.** Hovering a player you have never heard from shows nothing on the first pass and fires a ping; the block appears on the next hover. A peer silent past `PEER_MAX_AGE` drops back to that state. Your own tooltip shows your live tally, even at zero. Turning sharing off stops your broadcasts but not your view of others.

## The Options Panel

### Opening the Panel

`ns:OpenOptionsPanel` (`Options/Options.lua`) is the one entry point, and `/pif` does nothing but call it. The combat gate comes first (see Combat Lockdown). **The route is decided in one place**: `ns:OptionsPanelRoute` returns `(route, insideOptions, description)`, the opener branches on it, and the Diagnostics API row "Options panel opens inside the Blizzard interface" calls the same function, so the report cannot describe a route the add-on does not take. It routes to `Settings.OpenToCategory(ns.GeneralCategoryID)` and falls back to AceConfigDialog's standalone window only when `Settings.OpenToCategory` or the captured ID is missing.

**Never look the category up by name.** `AddToBlizOptions` returns `(frame, categoryID)`, captured as `ns.GeneralPanel` and `ns.GeneralCategoryID`. AceConfigDialog uses the display name as the category ID only on clients lacking `C_SettingsUtil.OpenSettingsPanel`; Era lacks it and TBC Anniversary has it, so a name lookup works on one flavor and floats the panel free on the other. An API row reports `C_SettingsUtil.OpenSettingsPanel`, where a FAIL names the route rather than a fault.

Registration is deferred: `ns:RegisterOptionsPanels` runs from the `ADDON_LOADED` init point, because the Profiles builder reads `ns.db`. The root is General; its children, in order, are What to Give Away, Recipients (with My Alts and My Guilds nested under it), Mail Message Text, Badge of Generosity, Profiles, Feedback & Support and Diagnostic Tools. My Alts, My Guilds and Diagnostic Tools register as builder functions, so their trees and tabs are rebuilt on every repaint.

### The Panels

- **General** (`Options-General.lua`): description, Enable Welcome Message, a Features header with the three feature switches two to a line (Distribute Gear, Distribute Consumables, Share), then /Commands. Every other setting lives on its feature's panel.
- **What to Give Away** (`Options-Give-Away.lua`): Distribute Gear, a toggle at `ns.OPTIONS_LABEL_WIDTH` (2.1) with its rarity select beside it at `ns.OPTIONS_CONTROL_WIDTH` (1.3), whose values ("Rare & Lower") describe themselves; then Distribute Consumables, full width, with indented sub-rows beneath it (`SubRow`, `SubLabel`, `ns.OPTIONS_SUB_INDENT_WIDTH`): the Level Rule select with its caption, then the five kind toggles from `ns.CONSUMABLE_KIND_ORDER`. Last, Disenchant Unmatched Items, its toggle beside the disenchanter select, which is disabled when `Alts:DisenchantChoices` offers nobody. A select or sub-row hides while its toggle is off, and the spacer between the sections keeps the toggles from pairing on one line.
- **Recipients** (`Options-Recipients.lua`): Priority (Prioritize Alts, Prioritize Guilds), Strangers (leveling zones, outside instances, Ignore Warlocks with its levels filled from `SUMMONER_MIN_LEVEL` and `SUMMONER_MAX_LEVEL`), then Classes & Specs, one inline row per class this client can roll, and a Reset that wipes `profile.specs`. Each spec setter calls `ns.Data.RebuildStatWeights` and `ns.RefreshMailWindow`.
- **My Alts** (`Options-Alts.lua`): Send to Alts above the tree; each character's pane holds Include, Gear Levels (Lowest and Highest selects with a summary line), its spec ticks and a Delete behind a confirm.
- **My Guilds** (`Options-Guilds.lua`): the offline-limit select above the tree; each guild's pane holds Include, a status line (active count, when and by whom it was saved) and one Include tick per member. A member's realm is shown only when it differs from the guild's.
- **Mail Message Text** (`Options-Mail.lua`): see below.
- **Badge of Generosity** (`Options-Generosity.lua`): an intro, the Share toggle, and `PlayItForwardBadgePreview`, a custom AceGUI widget fed through a `description` row's `dialogControl`, drawing your own unit tooltip's badge (your name, level, race and class, then `BlockLines`). The row's `name` is `tostring(gifts)`, so a gift makes AceConfig redraw it.
- **Feedback & Support** (`Options-Feedback-Support.lua`): the mandated Level Up paragraphs, a Feedback & Support Links header, the Discord, CurseForge, Wago and GitHub links, the copy caption and the version line.

### Layout

AceConfig's flow layout packs cells until a row fills, and two rules follow from that.

**A label-beside-value row needs a spacer behind it.** The Feedback & Support links are each a `ns.OptionsRowLabel` at `LINK_LABEL_WIDTH` (0.6) plus an `input` at `ns.OPTIONS_ROW_WIDTH` (3.4) minus that, with a full-width spacer after every pair; the last one doubles as the blank line above the copy caption. Two `description` widgets never break a row on their own, so any label-beside-text pair depends entirely on that spacer.

**A toggle can be its own caption**, as Distribute Gear and its rarity select show. All shared widths live in `Data/Data.lua`; the splits a single panel draws are local to its file (`LINK_LABEL_WIDTH` in Feedback & Support, `FEATURE_TOGGLE_WIDTH` in General, `SPEC_WIDTH` and `CLASS_WIDTH` in Recipients, `SPEC_WIDTH` and the `LEVEL_*` widths in My Alts, `MEMBER_LABEL_WIDTH` in My Guilds).

A setter that changes what counts as giftable, or what the ranking reads, calls `ns.RefreshMailWindow()` (`Options-Utilities.lua`), which runs `UI:SyncControls()` when the window exists and `UI:Rescan()` always. With no window built, `UI:Rescan` marks the scan stale (`MatchList:MarkStale`), or the next mailbox would reuse a scan judged under the old setting and open on nothing; at a mailbox still waiting it also opens the window if the new setting turned up a gift. `ns:ApplyProfile` does the same for a profile switch, copy or reset, after rebuilding the stat weights, and sends `NotifyChange` to every registered panel.

### The Mail Editor

The Mail Message Text panel is one custom AceGUI widget, `PlayItForward-MailEditor`, fed as a `description` row through `dialogControl`: the subject and body boxes on the left, the mail as `BuildSubject` and `BuildBody` will send it on the right. **It saves on every keystroke and bypasses AceConfig's set**, because AceConfigDialog redraws the whole panel after a set and would take the cursor out of the box mid-word; `OnTextChanged` calls `Distributor:SaveCustomText` and repaints only the preview and the byte counts. The counts are bytes of the cleaned text against each field's `MAIL_FIELDS` ceiling (`CUSTOM_BODY_MAX` for the body), and turn red past it. Each box opens on `Distributor:EditableText`, so editing starts from the stock copy. There is no typing limit. Restore Default clears both keys at once (README-Notes) with no confirm, since a confirm popup blanked the panel behind it, and is never disabled, since the panel is not redrawn while the player types and a `disabled` gate would go stale.

`UI:RarityPickerOptions` (qualities 2 to 4) and `UI:GapPickerOptions` are split from opening the pickers so `Tests/Options-Values.lua` can read them without a frame. The gap picker compares `opt.gap == nil` rather than truthiness, because **the All Consumables stop is a zero**. A stored gap that is not one of `ns.CONSUMABLE_GAP_ORDER` is snapped to the nearest stop for display by `ns.NearestConsumableGap`, and the stored number is left alone.

## Diagnostic Tools

`Diagnostics/` is the shared framework, gated behind a runtime-only toggle in `ns.diagnostics` that starts off every session and is never saved. Reports build only on a button press, and the panel writes nothing but the `taintLog` CVar. Five tabs: **Run Tests** (Event Log, Taint Log, in-game and external tool pointers), then **Settings**, **Code**, **Data** and **Localization**, each with Run All, one row per report and one output box. Reports and tabs come from `ns.DIAGNOSTIC_REPORTS` and `ns.DIAGNOSTIC_SECTIONS` in `Report-Runner.lua`.

The README-Notes exception keeps two additions to Magic Eraser's framework: an API row's optional second return is printed beside its result, and a report row can carry an input box (`input` on its `ns.DIAGNOSTIC_REPORTS` entry). `Validate-Data.lua` reads tables off `ns.Data` rather than `ns`, since that is where this add-on keeps them.

**Settings** holds the context probes, then the shared Saved Variables, Display Context and Other Add-ons:

- **Mailbox**: what `ns.AtMailbox()` answers and which source answered it, the `MailFrame` hooks, `SendMailFrame`, whether the window is built and shown and would open now, whether the reopen button would show, item counts by state, whether bag changes rescan the open window now (`WouldRescan`), where a mail run stands (busy, queue, consecutive errors, awaiting a late result, settling a refusal, money against postage), the giftability settings, and the combat state.
- **Bag Scan**: every occupied slot with its verdict or reject code. The rejected rows are the point: a listed consumable shows its data row, and a `LEVEL_GAP` rejection shows the player's level against the row's use level and the Level Rule, since the client's own required level does not show what decided it. An accepted consumable shows its form, use level, what it is for, its switches, its eligible and contending classes and its band.
- **Recipient Roster**: the ordering switches; everyone pooled, with fairness state and what each qualifies for; the last alts read, the disenchanter, the saved guilds and the linked realms; the search plan, in-flight query, throttle, timeouts, blocks and quieted Who frames; the guild pull's counts; the level floor; the instances named; and what the parsers discarded.
- **Item Verdict**: one link or item id typed into the row's box, with both stat sources side by side, so a parse failure shows as one rather than as a low score.
- **Class Groups**: the class list this client and faction resolve to and the specs each counts (a class with none is offered no gear), then the derived armor priority table at a typed level, or the player's own, and the weapon table, which has no level.
- **Outgoing Mail**: the exact subject and body a stranger receives, with byte lengths.
- **Given Away Sharing**: share state, resting state, prefix registration, this account's totals, which tooltip hook installed and whether `C_Secrets` is present, the throttle stamps and countdowns, what the last send answered, and every peer with its age and an expired marker. It answers "why don't I see anyone", usually with the resting line.

**Code** holds Event Registration (driven off `ns.EVENT_NAMES`), API Endpoints and Library Versions. `ns.DIAGNOSTIC_API_CHECKS` carries a row per API reached through a compatibility guard plus the load-bearing calls, including `C_ChatInfo.SendAddonMessage`, `C_ChatInfo.RegisterAddonMessagePrefix` and `IsResting`, which the broadcast needs, and the spec-name lookups. Where the add-on picks between two APIs both halves are rows, so a FAIL on one half says which branch that client took (the `C_TooltipInfo` rows fail on Classic Era, where `ns.ReadTooltip` reads its hidden tooltip instead; the tooltip-hook rows show which pipeline this client's `GameTooltip` runs). Three rows feed literal strings to `Tooltip:StatsFromLines` as regression guards: a random-suffix roll arrives color-wrapped, and when that form stops parsing every rolled green reads as statless and lands in the vendor pile while fixed-stat items keep working. Another row counts how many of the client's `ERR_MAIL*` strings `IsMailError` recognizes, because with none recognized every refused mail sits out the full result timeout and is blamed on a confirm nobody was shown.

**Data** has one Validate Data row per flavor-folder file (`ns.DIAGNOSTIC_DATA_SOURCES`, thirteen sources), labeled by table-file name with the file this client loaded beneath it. A report is the client header, then one tab-separated block per record kind, ready to paste into a spreadsheet and sort by `STATUS`. Food, potions, scrolls and oils and stones validate as `"item"`: every item API return, the file's own columns, the item's spell and its whole tooltip. `ZONES` and `INSTANCE_AREAS` validate as `"area"`: each row prints the name `C_Map.GetAreaInfo` gives its ID, and a blank name is `NO NAME` rather than `NOT ON CLIENT`, since a client can know an area and leave it untranslated; a wrong zone ID otherwise fails silently, because the search skips a zone it cannot name. Every other table (stat budget, stat map, zone columns, linked realms, rules, specs, weapons, armor, faction and consumable classes) carries no ID a client API looks up, so it validates as `"other"`, a row count or `TABLE MISSING`.

**Localization** holds Locale Context (locale, text and audio locale CVars, defined key count) and Game Names: one `OK` or `NIL` line per `ns.DIAGNOSTIC_NAME_LOOKUPS` row, read through the same call its feature makes. The rows are `ERR_PLAYER_WRONG_FACTION`, the three item-quality labels, the `TANK` and `HEALER` role labels, then rows built from the add-on's own data (every `STAT_MAP` global, every class either faction can roll on this client in both genders, every spec name `ns.SpecName` gives, every zone and instance), so a stat, spec or zone added there gets its row unedited. The add-on names no items or spells by ID, so no row waits on a server load. The add-on sends no chat and writes no macros, so there is no Message Length report; mail lengths are in Outgoing Mail.

### The Event Log Filter

`ns.DIAGNOSTIC_EVENT_EXCLUDE` (`Event-Log.lua`) is deliberately empty: every event this add-on registers is signal some of the time. The noisy ones go through `ns.MESSAGE_ID_FILTERED_EVENTS` instead, which names each event, the argument position of the id that classifies a firing, and a `correlated` predicate:

| Event | Correlated when |
|---|---|
| `UI_ERROR_MESSAGE` | `ns.Distributor:IsMailError(message)` |
| `CHAT_MSG_ADDON` | the prefix is `ns.ADDON_MESSAGE_PREFIX` |
| `BAG_UPDATE` | `ns.MatchList:WouldRescan()`, the firing armed a rescan |
| `GET_ITEM_INFO_RECEIVED` | `ns.MatchList:WouldRescanItem(itemID, success)`, the item was pending and the firing armed a rescan |

`ns:SuppressUncorrelatedMessage` runs inside `ns:LogEvent`, **at capture rather than at render**, because filtering at display time still lets spam push real entries out of the 500-entry buffer. Three rules govern it:

- **Filter by what the add-on acts on, never by a denylist of noise.** Noise is unbounded and renumbers across patches. Each predicate calls the live handler's own test, so a drifted filter cannot make the log lie about what fired. That is why `IsMailError`, `WouldRescan` and `WouldRescanItem` are exposed, and the Diagnostics reports call the same tests.
- **Count, don't delete.** Suppressed traffic aggregates per id as first-seen text plus a count, rendered as one block at the end of the report, biggest first: `UI_ERROR_MESSAGE(56, Ability is not ready yet.) x469`. That block is how a tester finds an id the add-on should be correlating.
- **Unclassifiable is signal.** A firing with nothing at the id position is logged verbatim. The counters live in `ns.diagnostics.suppressed`; Stop keeps them, Start replaces them, and switching the panel off releases them.

`Tests/Event-Log-Noise.lua` pins all of it.

## Saved Variables

One table, `PlayItForwardDB`, created in the name-guarded `ADDON_LOADED` handler with `LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)`.

**The model is Simple.** No setting differs from character to character, so every character shares the `"Default"` profile (that third argument `true`). **Reset Profile restores every setting to its install default, the spec choices included, and leaves `global` untouched: your characters and guilds, with the choices made on them, and the giving tally.** A new setting goes in `profile`; only state a reset must not take from the player belongs in `global`.

`profile` holds the settings: the welcome and Share switches (`showWelcome`, `shareStats`); what is given (`maxRarity`, `includeGear`, `includeConsumables`, `consumableKinds`, `consumableLevelGap`, `disenchantUnmatched`); who receives it (`sendToAlts`, `guildOfflineLimit`, the four `prioritize*` switches, `ignoreSummonerWarlocks`, `specs`); the custom mail copy (`mailSubject`, `mailBody`, empty for the stock text); and the window's `windowPos` and `windowSize`. The mail keys are deliberately not `subject` and `message`, an earlier editor's names, so a value left under those stays unread. `consumableLevelGap` of 0 is a sentinel, the All Consumables stop, which lifts the level test outright. `consumableKinds` carries one switch per `ns.CONSUMABLE_KIND_ORDER` entry; a kind added there reaches existing profiles through AceDB's nested defaults with no migration. Read `Data/Default-Settings.lua` for the current shape and defaults.

`global` holds three tables. `characters` is every character that has logged in, keyed by qualified name, with what the game says it is (name, realm, class, level, faction, spec) and what the player chose for it (`include`, `specs`, `levelsBelow`, `levelsAbove`, `disenchanter`). `guilds` is every guild any character has been in, keyed by `Guild:Key`, with its members as last scanned and the player's `include` and `ignored`. `stats` holds the four tally counters, written only by `ns.Generosity:RecordSend`. Which character `disenchantUnmatched` mails Kept gear to lives on its `characters` entry, not under `profile`, because the shared Default profile also serves characters that cannot mail it.

AceDB applies `ns.DATABASE_DEFAULTS` when a scope is first accessed, never overriding an explicit user value including `false`; scalar and table defaults are copied into the saved table, and `removeDefaults` strips any key still equal to its default on logout, so an untouched profile saves empty. A key removed from `ns.DATABASE_DEFAULTS` is never visited by that cleanup, so retiring one takes an explicit nil inside a tagged migration.

There are no default item or spell lists, so no seeding logic. `characters` and `guilds` fill themselves from the game at login, level up, respec and roster reads, and an alt's default `include` is computed from the level cap rather than stored. The giftable-item tables are static data and never enter saved variables. The fairness history is session-only, in a file-local table.

Not settings, on purpose: the rarity floor `ns.Data.MIN_RARITY` (Uncommon, gear only; consumables return before the rarity checks), every matching constant, and the `MAIL_POWERED_BY` footer under a custom body.

### Migration Chain

- `ns.db.profile.recipients = nil` in `Features/Core.lua`: the fairness history left saved variables for a session table. `MIGRATION (remove after 2026-11-05)`.

## Adding a New Registered Event

1. Call `ns.On("YOUR_EVENT", handler)` from the feature file that needs it. Never create an event frame; it would escape the event log.
2. `ns.EVENT_NAMES` records it automatically, so Event Registration picks it up with no second edit. Register it only where the client ships it, behind a gate like the `PLAYER_INTERACTION_MANAGER` pair (`ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot"`) or `PLAYER_SPECIALIZATION_CHANGED` (`ns.EXPANSION >= 5`); registering an event the client lacks throws.
3. If it fires often enough to bury the 500-entry log, decide whether any firing is ever signal. If none is, add it to `ns.DIAGNOSTIC_EVENT_EXCLUDE` in `Diagnostics/Event-Log.lua`. If some are, add it to `ns.MESSAGE_ID_FILTERED_EVENTS` with its id position and a `correlated` predicate that calls the handler's own test. Excluding a sometimes-signal event hides the one entry a bug report needs; if an excluded one turns out to matter now and then, the handler that knows can record that firing with `ns:LogEventNow(event, ...)`, which skips the exclude list and carries the dispatcher's own logging check.

## Adding a New Giftable Consumable

1. Add the row to `FOOD_AND_WATER`, `POTIONS`, `SCROLLS` or `OILS_AND_STONES` in `Data/{Flavor}/Scan-Food-{Flavor}.lua`, `Scan-Potions-{Flavor}.lua`, `Scan-Scrolls-{Flavor}.lua` or `Scan-Oils-Stones-{Flavor}.lua`, in every folder whose client has the item, as `{ id, quality, useLevel, restores }` (`buffs` in place of `restores` for a scroll, `enhances` for an oil or stone) with a trailing `-- Item Name`. Edit rows in place; look up the same ID in the other six folders and say which copies changed (Style Guide → DATA → Flavor Folders). The file's `How We Got the Data` block belongs to the Data Review.
2. `restores` is `"HEALTH"`, `"MANA"`, `"BOTH"` or `"PET"` (potions use the first three); a scroll's `buffs` is `"STRENGTH"`, `"AGILITY"`, `"STAMINA"`, `"INTELLECT"`, `"SPIRIT"` or `"ARMOR"`; an oil or stone's `enhances` is `"MELEE"`, `"SPELL_DAMAGE"` or `"MANA"`, and on Mists `"INTELLECT"` or `"SPIRIT"`. Eligibility derives from that value through the folder's `ns.Data.CONSUMABLE_CLASSES` in `Match-Classes-{Flavor}.lua`; there is no per-item class list, and the classes are then filtered by faction. **A value missing from `CONSUMABLE_CLASSES` reaches every class**, exactly like `"ALL"`, so a typo fails open rather than loudly. `MANA` serves water, mana potions and, outside Mists, mana oils, so changing it changes all of them.
3. **A `useLevel` of 2 or less reaches nobody.** The band runs from the use level up `CONSUMABLE_RECIPIENT_GAP` (2), so it tops out at 4, below `MIN_RECIPIENT_LEVEL` (5). A 0 is rejected as `NO_USE_LEVEL`; a 1 or 2 is offered and never matched, and keeps the search plan alive for an item nobody can take. Leave such rows out, or give the item a real usefulness level.
4. `Features/Scan-Bags.lua` stamps the source table's `form` (`FOOD`, `POTION`, `SCROLL`, `OIL_STONE`) and the row's `kinds` onto `record.def`, and files the fourth column under `restores`, `buffs` or `enhances`. Kinds are the player's switches, not the form: a `FOOD_AND_WATER` row restoring `MANA` is `DRINK`, `BOTH` is `FOOD` and `DRINK`, the rest (`PET` included) `FOOD`. A row in two tables is silently won by the later one.
5. Rules key on `def.form` and `def.restores`, which is what keeps water from being treated as a mana potion. No rule can key on a scroll's `buffs` or an oil or stone's `enhances`.
6. A new consumable table, rather than a row, also needs a `DIAGNOSTIC_DATA_SOURCES` entry and its data columns in `Diagnostics/Manifests.lua`, a kind in `ns.CONSUMABLE_KIND_ORDER` and `ns.CONSUMABLE_KIND_STRINGS`, its `consumableKinds` default, and the same file in all seven flavor folders.

## Adding a New Stat

1. Map the `GetItemStats` key to an internal token in `ns.Data.STAT_MAP`, in every flavor folder's `Scan-Stats` file. Clients disagree on the key set: TBC Anniversary answers with the long `ITEM_MOD_SPELL_DAMAGE_DONE` and `ITEM_MOD_SPELL_HEALING_DONE` rather than their `_SHORT` keys, so map every key any client returns. Only `_SHORT` keys feed `ReadFormatted`, so a stat mapped by a long key alone gets no name-first reader.
2. Weigh the token in the specs in every flavor folder's `Match-Specs` file as main (2) or useful (1), and give it a cost in every flavor folder's `Match-Stat-Budget` file if a point of it is not worth a point of primary stat. The step from a sum of 2 (admitted, never leads) to 3 (enters the top bucket) is categorical; a stat weighted on another scale is silently misfiled.
3. **Weighting a stat is never only a scoring change.** It enlarges the coverage denominator on every item carrying that stat, and the majority test is strictly greater than half. Run `Tests/Stat-Scoring.lua`, `Tests/Talent-Trees.lua` and `Tests/Outcomes.lua`; rewrite the saved outcomes with `Tests/Write-Outcomes.lua` only once the new answers are the intended ones.
4. If the stat renders only as tooltip text with no `ITEM_MOD_` global (per-school spell damage), add its English name to the `ENUS_FALLBACK` map or a pattern to the ordered `EQUIP_PATTERNS` list in `Features/Scan-Tooltip.lua`, more specific patterns first. Add a case to `Tests/Tooltip-Parsing.lua`.
5. Never write `ns.Data.STAT_WEIGHTS` directly. `RebuildStatWeights` derives it from `SPECS` and the specs the player has on, and wipes it on every rebuild.

## Adding a New Item Rule

1. Add a table to `ns.Data.ITEM_RULES` in every flavor folder's `Match-Rules` file with a developer-facing `name` (never localized) and exactly one matcher: `weapon`, `form` plus `restores`, or `requires` (optionally `exclusive = true`, `without`, `armor`).
2. Pick the verb deliberately: `prefer` for "this is who it is for", `demote` for "not this class, but keep them as a fallback", `veto` only for "this class must never receive it", `vetoUnlessRole` for "never to a class with no spec of this role on". Add `unclaimed = true` only to break a tie no stat can break; it pairs with `prefer` or `demote`.
3. **Position matters for `prefer` and only for `prefer`.** A new stat rule above an existing one silently takes items from it, even when it names nobody admitted. `veto` and `demote` accumulate, so their position is free.
4. Add a case to `Tests/Item-Rules.lua`, `Tests/Weapon-Rules.lua`, `Tests/Consumable-Rules.lua`, `Tests/Scroll-Rules.lua` or `Tests/Oil-Stone-Rules.lua` and run `lua5.1 Tests/Run.lua`. Rule interactions do not survive being reasoned about; the veto-before-scoring and demote-after-prefer orders both have tests.

## Adding a New Options Control

1. Add its key and default to `ns.DATABASE_DEFAULTS.profile` in `Data/Default-Settings.lua`. Under the Simple model every setting lives on the profile.
2. Add the widget to its feature's panel builder (`ns.BuildGiveAwayOptions`, `ns.BuildRecipientsOptions`, `ns.BuildAltsOptions`, `ns.BuildGuildsOptions`, `ns.BuildMailOptions` or `ns.BuildGenerosityOptions`), never to General, which holds only the feature switches. Use the constructors from `Options/Options-Utilities.lua` (`ns.OptionsHeader`, `ns.OptionsDesc`, `ns.OptionsSpacer`, `ns.OptionsRowLabel`, `ns.OptionsProfileToggle`, ...). Its explanation goes in `desc`, never a second line under it. Follow the spacer rule under The Options Panel → Layout. A new panel also needs an `ns.OPTIONS_REGISTRY` entry in `Data/Data.lua` and a line in `ns:RegisterOptionsPanels`.
3. Add its strings to `Locales/enUS.lua` only.
4. If it changes what counts as giftable or anything the ranking reads, call `ns.RefreshMailWindow()` from its setter; the candidate cache has no other way to learn of it. Mirror it in the window's top bar only if the bar already shows its section.

## Localization

**`enUS.lua` is the source of truth** and the only file whose `NewLocale` passes `true`. It registers under the literal `"Play-It-Forward"`, and `Data/Data.lua` reads `GetLocale(ADDON_NAME)`; the two must stay the same string, or every `L` lookup is nil with no load error. The other ten files translate its key set and are owned by the Localization Review (`07 - Localization Review.md`); ordinary work edits `enUS.lua` alone.

**Placeholders.** `%s` and `%d` count, type and order must match `enUS` per key in every locale, or the string errors at runtime.

**Game names never go in `Locales/`.** The add-on stores IDs and tokens and asks the client:

| Record | Stored as | Named by |
|---|---|---|
| Zone, instance | AreaTable ID, `ns.Data.ZONES` column `ZONE_COLUMNS.AREA_ID` and `ns.Data.INSTANCE_AREAS` | `C_Map.GetAreaInfo`, cached per session by `Who.AreaName` (`Recipients-Zones.lua`) |
| Class | Token | `LOCALIZED_CLASS_NAMES_MALE` (`Who.ClassName`, `Recipients-Who-Plan.lua`) for `/who` filters, plus `_FEMALE` (`Who.FemaleName`) where it differs; both genders for parsing results |
| Spec | `ns.Data.SPECS` key | `ns.SpecName`: `GetSpecializationInfoForClassID` where it exists, else `GetTalentTabInfo` for your own class, else `L["SPEC_*"]` |
| Race | Race ID, 1 to 100 | `C_CreatureInfo.GetRaceInfo(id).raceName` |
| Item | Bag link | `C_Item.GetItemInfo`; the data tables' IDs are read by name only in Validate Data |
| Item quality | 2 to 4 | `ITEM_QUALITY2_DESC` to `ITEM_QUALITY4_DESC` |
| Role | `TANK`, `HEALER` | The globals themselves |
| Stat | `ITEM_MOD_*` global name, `ns.Data.STAT_MAP` | The global itself |
| Mail refusal | `ERR_MAIL*` and `ERR_PLAYER_WRONG_FACTION` | The globals themselves |

**Spec names are the one typed game name** (README-Notes). Classic Era, TBC Anniversary and WoW Forever offer no API that names another class's talent trees, and Season of Discovery's rune roles have no name in the game, so `enUS.lua` carries `SPEC_*` strings for the tree names, `SPEC_PALADIN_Protection` and `SPEC_DRUID_Restoration` where two classes share a tree name (`CLASS_QUALIFIED_SPECS`), and `SPEC_Tank`, `SPEC_Healer` and `SPEC_Melee` for the rune roles. They are read only when the client cannot answer.

**Zones are area records, not map records.** `/who` matches the zone text its results carry, which is the AreaTable name, and area and map names disagree in some locales on every client (frFR area names carry an English suffix, deDE names The Barrens `Brachland` against the map's `Das Brachland`). An area the client has no name for is skipped rather than sent as an empty `z-""`.

**Equip-effect parsing is English-only.** `EQUIP_PATTERNS` in `Features/Scan-Tooltip.lua` matches the rendered "Equip: ..." wording vanilla builds from spell text. `Tooltip.equipPatternsUsable` gates it on `GetLocale()` matching `Tooltip.equipPatternsLocale` (`"enUS"`), an API row reports the gate, and Item Verdict says so on other clients. So are the English names in `ENUS_FALLBACK`: the five base stats and the spell damage and healing wordings, per-school damage included, that have no `ITEM_MOD_` global (README-Notes). Plain stat lines parse in every locale, through the `+N Name` reader and the client's own `ITEM_MOD_*` formats, so an item misses a stat rather than scoring wrongly.

**The mail stays English.** `MAIL_SUBJECT`, `MAIL_BODY` and `MAIL_POWERED_BY` are English in every locale file (README-Notes), so every client sends the bytes `Tests/Mail-Contents.lua` measures. Their ceilings are `SUBJECT_MAX` (31) and `BODY_MAX` (500) bytes. The add-on never calls `SendChatMessage` and writes no macros, so the 255-byte chat and macro limits do not apply, and its one add-on message payload is four integers.

**Diagnostics strings are not localized.** They live in `ns.DiagnosticsStrings` (`Diagnostics/Diagnostics-Core.lua`, plus `EVENT_LOG_EXAMPLES` in `Manifests.lua`) and inline in the report builders. That includes the `WHO_LABEL_*` query labels, which `Recipients-Who-Plan.lua` composes but reads at call time, since the Diagnostics files load after it. Who reads a string decides the rule, not where it is built.

## Common Pitfalls

- **Calling `SendWho` outside a click handler**: blocked with no error and no event. Every query rides a button press, and `ADDON_ACTION_BLOCKED` is caught only to explain one.
- **Using `UseContainerItem` with the Send Mail panel closed**: uses the item instead of attaching it. Check the panel before touching the item.
- **Setting the mail subject before attaching**: the client overwrites an empty subject with the item's name. Fill the panel after the attach.
- **Re-reading a bag slot on `MAIL_SUCCESS`**: the slot still holds the old link, so every delivery reads as a skip. Trust the event; capture the stack size before the send.
- **Dropping a job when the mail result timer fires**: `SendMail` already went out, so a late Accept still delivers. The job moves to `_awaiting` and `Distributor:Result` credits it.
- **Starting a run over an awaited send**: its late result would be credited to the new run's first job. `Start` refuses for one more `RESULT_TIMEOUT`.
- **Letting an old settle timer act on a new run**: a `FAILURE_SETTLE` timer outlives the run that armed it. `Distributor._run` is bumped by `Start` and `Stop` and checked when the timer fires.
- **Marking a recipient unreachable for an attach failure**: the refusal was about the item. Only a job with `_sent` set marks the name.
- **Closing the window from `MailFrame`'s `OnHide`, or gating on `MailFrame:IsShown()`**: mail-replacement add-ons and the Who panel both hide it while the player stands at a mailbox. The `OnHide` hook only rechecks Distribute; use `ns.AtMailbox()`.
- **Parenting a frame to `MailFrame`**: it stays protected for good and writing to the panel taints it. The reopen button is parented to `UIParent` and only anchored there.
- **Dropping an in-flight `/who` instead of cancelling it**: `EndQuery` is what re-registers `WHO_LIST_UPDATE` on Blizzard's frames and restores `SetWhoToUi`. Skip it, or let a parse error skip it, and the player's own `/who` answers with silence for the rest of the session. Cancel the job and parse under `pcall`.
- **Re-planning a search mid-flight instead of pruning it**: `Who:Plan` restarts from the best-first attempt, so a search re-planned per press never gets past its first zone. `Who:Prune` only removes.
- **Putting two class filters in one `/who`**: the client honors the first and drops the rest, filling the pool with the wrong class. One class per query.
- **Naming instances from the uiMap list**: Classic Era and WoW Forever ship no dungeon maps, and a map is a different record from the zone `/who` names. Instances come from `INSTANCE_AREAS` through `C_Map.GetAreaInfo`.
- **Trusting `GetItemStats` on a random-suffix green**: it resolves the base item and returns nothing. The tooltip is the only source for suffix stats.
- **Dropping `CleanLine` from the tooltip parser**: suffix and enchant stats arrive color-wrapped and newline-terminated, fail the `^%s*%+` anchor, and every rolled green returns to the vendor pile. It strips `|r` by shape, since a surviving `|r` turns "Intellect" into "Intellect|r".
- **Counting tooltip lines as a successful read**: a `C_TooltipInfo` answer without surfaced text has every `leftText` nil. A read counts only when it carries text.
- **Reading a two-stat line as one stat**: TBC's "+42 Healing Spells and +14 Damage Spells" names no stat as a whole. `SplitStats` splits it at each `+N`.
- **Testing `classID == 2` to mean "weapon"**: shields, held off-hands and relics are armor but rank on the weapon matrix. Use `ns.Data.UsesWeaponMatrix(item)`.
- **Reading a weapon key without checking `classID` first**: armor subclass 1 (cloth) collides with weapon subclass 1 (two-hand axe), so a cloth chest answers `2H_AXE`.
- **Putting `INVTYPE_HOLDABLE` in `UNIVERSAL_EQUIP_LOC`**: a held off-hand turns on whether a class has the off-hand slot free, so as universal an Intellect orb becomes eligible for a warrior. They route through the weapon matrix as `HELD`.
- **Reading `ns.db.profileKeys`**: always nil; AceDB keeps it on `ns.db.sv`. An own-alt check against it silently passes everybody.
- **Comparing or deduping player names as raw strings**: the roster and `/who` can spell one same-realm character two ways, so a raw comparison pools them twice and lets your own alts past. Compare `ns.QualifyPlayerName`; store and mail the name the client gave.
- **Reading a Mists spec through the global `GetSpecialization` or the talent tabs**: Mists Classic has no global and its `GetNumTalentTabs` throws. `Recipients-Alts.lua` asks `C_SpecializationInfo` first when `ns.EXPANSION >= 5`.
- **Adding a recipient level floor to a source**: there is one, in `MatchList:AddResults`, the door every source comes through. A second copy drifts from it.
- **Adding a setting the ranking reads without calling `ns.RefreshMailWindow`**: the candidate cache is stamped against the pool only, so it keeps serving the old ranking.
- **Treating a `consumableLevelGap` of 0 as a gap**: it is the All Consumables sentinel, and compared as a gap it withholds every consumable the player has not reached.
- **Shipping a consumable with a `useLevel` of 2 or less**: its band ends below the level-5 floor, so it matches nobody and keeps the search running for it.
- **Misspelling a consumable's `restores`, `buffs` or `enhances` value**: `EligibleClasses` treats a value missing from `CONSUMABLE_CLASSES` as `"ALL"`, so the item is offered to every class. Use only the listed values.
- **Writing a consumable rule on `form` alone**: `Matches` needs `form` and `restores` together, so the rule never matches. Oils and stones carry `enhances` and cannot be ruled on.
- **Rolling a random tiebreak inside a sort comparator**: `table.sort` throws. The shuffle key is rolled once per player at pool entry.
- **Mutating the list `MatchList:Candidates` returns**: it is the cached table, handed out by reference.
- **Caching `MatchList:Items()` in a local**: `RescanBags` reassigns the table. Call the accessor each time.
- **Re-reading the bags at the end of a distribution run**: the client has not emptied the sent slots yet, so the scan restores the pairings just delivered. `UI:AfterDelivery` re-assigns without scanning.
- **Reordering `ns.Data.ITEM_RULES`**: `prefer` is first-match-wins, so moving a stat rule above another silently takes items from it. `veto` and `demote` do not care, which makes the table look more reorderable than it is.
- **Adding a stat weight and expecting only scores to move**: it changes the coverage denominator on every item carrying that stat.
- **Mapping only one spelling of a stat key**: TBC Anniversary's `GetItemStats` returns long spell damage and healing keys rather than the `_SHORT` ones, so a stat mapped one way can score on some clients only. Map every spelling.
- **Adding a class to a flavor's `FACTION_CLASSES` alone**: `EVERY_CLASS` in `Match-Engine.lua` filters through it and stops at the monk.
- **Pairing two `description` widgets on one options row without a spacer**: the flow packs them until the row fills and the rows interleave. Every label-beside-value pair needs its full-width spacer.
- **Hooking a tooltip because `TooltipDataProcessor` exists**: the Classic clients expose it but never run its post-calls, and `HookScript` on a script type the widget lacks throws at load (Forever has dropped `OnTooltipSetUnit`). `Generosity-Tooltip.lua` takes the post-call only alongside `GameTooltip.GetPrimaryTooltipData`, checks `GameTooltip:HasScript` otherwise, and failing both installs nothing.
- **Opening the options panel by category name**: works on Era, floats the panel on TBC Anniversary. Route by `ns.GeneralCategoryID`.
- **Coloring the Generosity values anything but white**: `GetCoinTextureString` ignores the prefix, so the money row stays white regardless.
- **Removing a key from `ns.DATABASE_DEFAULTS` and expecting it to disappear**: AceDB's cleanup only visits keys still in the defaults, so the orphan persists. Nil it explicitly inside a tagged migration in `Core.lua`.
- **Moving a file earlier in the TOC**: `Match-Derivations.lua` reads `WEAPON_CLASS_ORDER` and `SPECS` at load, and the UI files capture `ns.UI`, `ns.MatchList` and `ns.Picker` at file scope in order. Each depends on the file before it.

## Contributing

**Issues**: [github.com/Gogo1951/Play-It-Forward/issues](https://github.com/Gogo1951/Play-It-Forward/issues).

**Bug reports** include the game version (Classic Era 1.15.x or Season of Discovery, WoW Forever 1.60.x, TBC Anniversary 2.5.x or Mists of Pandaria Classic 5.5.x) and locale, class and level, repro steps, and the relevant output from **Options > AddOns > Play It Forward > Diagnostic Tools**. Bag Scan and Item Verdict answer most "why isn't this item showing up" questions; Mailbox answers "why didn't the window open"; Given Away Sharing answers "why don't I see anyone".

**Discord**: [discord.gg/eh8hKq992Q](https://discord.gg/eh8hKq992Q).

**Pull requests:**

- One concern per PR.
- Match the house style: StyLua defaults with `--syntax lua51` (no `.stylua.toml`), no abbreviations, every player-facing string through `L["KEY"]`, diagnostics strings through `ns.DiagnosticsStrings`.
- Run `stylua`, `luac -p`, a clean `luacheck .` and `lua5.1 Tests/Run.lua` before pushing; CI runs the same on every PR.
- New settings take their defaults from `ns.DATABASE_DEFAULTS`; never hand-merge or overwrite a user value. Any change to saved-variable shape ships a dated `MIGRATION (remove after YYYY-MM-DD)` bridge, deleted once the date passes.
- The add-on sends no chat and writes no macros, so the 255-byte limits never apply; a change to the mail subject or body re-checks its byte length against `SUBJECT_MAX` and `BODY_MAX` instead, and a change to the broadcast payload keeps it under the 255-byte add-on message cut.
- Update this document if the architecture or file map changes.

**PR descriptions say what a player will notice**, in plain language, the way release notes do. Commit messages carry the developer detail.
