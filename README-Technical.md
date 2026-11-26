# Play It Forward // Technical Reference

> Code map for working on Play It Forward: where things live, how they connect, and the traps. Where this and the code disagree, the code wins. For players, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md).

## File Map

```text
Play-It-Forward/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── config.yml                Per add-on: the New issue page links
│   │   ├── defect.yml                Shared Common-Core file
│   │   └── request.yml               Shared Common-Core file
│   └── workflows/
│       ├── ci.yml                    Calls Common-Core: Lua 5.1 syntax, luacheck, StyLua and the offline tests
│       ├── issue-labels.yml          Calls Common-Core: fills in a new issue's missing Area, Priority or Type label
│       └── package.yml               Calls Common-Core: packages and uploads a tagged release
├── .gitattributes                    Shared Common-Core file
├── .gitignore                        Shared Common-Core file
├── .luacheckrc                       Lint config; also names the ElvUI and TSM_API globals read for skinning and TSM's mail window
├── .pkgmeta                          Externals and ignore list; strips Data/Wrath, Data/Mainline and Tests
├── Play-It-Forward_Camelot.toc       WoW Forever
├── Play-It-Forward_Mists.toc         Mists of Pandaria Classic
├── Play-It-Forward_TBC.toc           TBC Anniversary
├── Play-It-Forward_Vanilla.toc       Classic Era and Season of Discovery: lists Data/Vanilla then Data/Discovery
├── Data/
│   ├── Flavor.lua                    Canonical: ns.FLAVOR, ns.EXPANSION, ns.IS_DISCOVERY, ns.DATA_FOLDER
│   ├── Data.lua                      Locale init, ns.Data, palette, links, ns.OPTIONS_REGISTRY, dropdown stop lists, matching constants
│   ├── Default-Settings.lua          The AceDB-3.0 defaults, ns.DATABASE_DEFAULTS
│   ├── Vanilla/                      Classic Era; every file opens with the Discovery guard
│   ├── Discovery/                    Season of Discovery; inverse guard
│   ├── TBC/                          TBC Anniversary
│   ├── Camelot/                      WoW Forever
│   ├── Mists/                        Mists of Pandaria Classic
│   ├── Wrath/                        No TOC lists it; stripped by .pkgmeta
│   └── Mainline/                     No TOC lists it; stripped by .pkgmeta
├── Diagnostics/                      Copied framework; Manifests.lua is this add-on's surface (API rows, reports, data sources, name lookups)
├── Features/
│   ├── Core.lua                      Identity, AceDB lifecycle, other-client prune, ns:ApplyProfile, welcome, the ns.On dispatcher
│   ├── Utilities.lua                 Tooltip reads, colors, names and realms, templates and ElvUI skinning, ns.AtMailbox, ns.AtRest
│   ├── Menu-Kit.lua                  Common-Core's Menu-Kit, copied unchanged: every dropdown list, the tab's menu, window title text
│   ├── Announcements.lua             Player-only output: ns:BuildBrandedLine, ns:PrintMessage
│   ├── Scan-Tooltip.lua              Tooltip lines to stats and the reputation requirement; pure parsers
│   ├── Scan-Bags.lua                 Bag slot to item record or a reject code; Keep in Bags and Never Give Away (ns.Bags)
│   ├── Match-Derivations.lua         Stat weights from SPECS; priority groups, weapon keys, rule matching
│   ├── Match-Engine.lua              The matcher (ns.Matcher): eligibility, claim, fit, coverage, rules, the verdict
│   ├── Match-Ranking.lua             Candidate ranking, level bands, band groups, targeted search order
│   ├── Match-List.lua                The match list (ns.MatchList): items, pairings, debounced rescan, the allocator
│   ├── Match-Roster.lua              The recipient pool: AddResults, the dedupe, the candidate cache, RecheckGuildmates
│   ├── Match-Search.lua              Band merging, which gifts still search, targeted narrowing
│   ├── Recipients-Who-Plan.lua       Builds, coalesces, prunes and exhausts the /who plan
│   ├── Recipients-Zones.lua          Zone order (ns.Data.ZonesFor), area names, candidate placement
│   ├── Recipients-Who.lua            Sends one /who per press: throttle, Who panel deafening, parsing
│   ├── Recipients-Guild.lua          Guild recipients (ns.Guild): live and saved rosters, guilds added by name, the /who guild lookup
│   ├── Recipients-Alts.lua           Alt recipients (ns.Alts): your own characters as recipients, the disenchanter
│   ├── Recipients-Fairness.lua       Session cooldown and the unreachable list
│   ├── Mail-Sender.lua               The mailer (ns.Distributor): one SendMail at a time, event-driven, Stop and the Sent list
│   ├── Mail-Copy.lua                 Subject, body and footer, stock or custom, cleaned and cut
│   ├── UI-Picker.lua                 ns.Picker: option lists to Menu-Kit dropdown entries, one shared list
│   ├── UI-Window.lua                 The Distribution Window frame and ns.UI: rows, sections, heading ticks, geometry
│   ├── UI-Top-Bar.lua                The window's giftability ticks, dropdowns and enchanter picker, UI:SyncControls
│   ├── UI-Status.lua                 Distribute/Stop button state, status line, UI:CanTick
│   ├── UI-Assignment.lua             A row's dropdown: header, candidates, manual picks, Never Give Away, row ticks
│   ├── UI-Mailbox.lua                Mailbox open and close, Find Recipients, Distribute, roster pulls, returned gifts
│   ├── UI-Mailbox-Tab.lua            The gift tab on the mail window's edge (Blizzard or TSM) and its hover menu
│   ├── Generosity.lua                Account-wide giving tally in global.stats
│   ├── Generosity-Broadcast.lua      Shares the tally with nearby players over YELL add-on messages
│   └── Generosity-Tooltip.lua        A peer's totals at the foot of their unit tooltip
├── Includes/
│   ├── Images/
│   │   ├── Gift.tga                  The window's portrait and the mailbox tab's icon
│   │   ├── Menu-Arrow.tga            Menu-Kit's sub-menu chevron, copied unchanged
│   │   ├── Menu-Plate.tga            Menu-Kit's angled plate, copied unchanged
│   │   └── Play-It-Forward.tga       Icon
│   └── Libraries/                    Vendored Ace3 down to AceDBOptions-3.0, nothing else
├── Locales/
│   └── enUS.lua                      Source of truth
├── Options/
│   ├── Options-Kit.lua               Common-Core's Options-Kit, copied unchanged: panel builders, registration, ns:OpenOptionsPanel
│   ├── Options-Utilities.lua         Shared ns.Options* constructors, ns.FEATURES, ns.RefreshMailWindow
│   ├── Options-General.lua           Root panel: welcome and the feature switches
│   ├── Options-Give-Away.lua         What to Give Away: gear, consumables and kinds, Keep in Bags, Never Give Away, disenchanting
│   ├── Options-Recipients.lua        Recipients: priority, stranger rules, Classes & Specs
│   ├── Options-Alts.lua              My Alts: tree of characters, each one's tick, gear levels and specs
│   ├── Options-Guilds.lua            My Guilds: offline limit, Add Guild box, tree of guilds, ticks, remove and member ignores
│   ├── Options-Mail.lua              Mail Message Text: the editor widget and live preview
│   ├── Options-Generosity.lua        Badge of Generosity: the Share switch and a badge preview
│   ├── Options-Profiles.lua          Stock AceDBOptions-3.0 table
│   ├── Options-Feedback-Support.lua  Level Up note, links, version line
│   └── Options.lua                   Panel registration, ns:OptionsPanelRoute, /pif
├── Tests/                            Offline suite, runs on Lua 5.1; never ships
│   └── Outcomes/                     Saved who-gets-what tables, one per flavor folder
├── LICENSE                           MIT
├── README.md                         Player documentation
├── README-Notes.md                   Exceptions to the Style Guide
├── README-Technical.md               This document
└── README-Testing.md                 Manual test plan
```

- **No mini-map button**: `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are deliberately absent. The mailbox tab is the add-on's only button.
- **`UI-Reopen-Button.lua` is gone**, replaced by `UI-Mailbox-Tab.lua`; nothing reopens the window from a button beside `MailFrame` any more.
- **Diagnostics panel** lives in `Diagnostics/Options-Diagnostics.lua`, registered through Options-Kit like every other panel; never `Features/Diagnostics.lua` or `Options/Options-Diagnostics.lua`.
- **Nothing but `Flavor.lua`, `Data.lua` and `Default-Settings.lua` sits directly in `Data/`.** Game data and matching policy live in per-flavor copies and never return to a file every client loads.
- **TOC order is load-bearing.** Within Features: `Menu-Kit` before `UI-Picker` and `UI-Window` (both capture `ns.MenuKit` at file scope); `Mail-Copy` after `Mail-Sender`; `Generosity-Broadcast` and `Generosity-Tooltip` after `Generosity`; the UI files in order `UI-Picker`, `UI-Window`, `UI-Top-Bar`, `UI-Status`, `UI-Assignment`, `UI-Mailbox`, `UI-Mailbox-Tab`, each capturing what an earlier one created (`ns.UI`, `ns.Picker`, `UI.TICK_SIZE`, `UI.FIELD_HEIGHT`). Some reads go the other way at call time only: `UI-Window` reads `UI.MAILBOX_TAB_SIZE`/`UI.MailboxTabHost`, `UI.DISENCHANT_ICON` and `UI.TOP_BAR_BOTTOM`. Options: `Options-Kit` first, `Options/Options.lua` last.
- **Each client loads one data folder.** Every flavor folder holds the same fourteen files, suffixed with the folder name, each declaring the same `ns.Data` tables:

| File | Tables |
|---|---|
| `Match-Stat-Budget` | `STAT_BUDGET` |
| `Match-Weapons` | `WEAPON_SUBCLASS`, `RELIC_SUBCLASS`, `WEAPON_CLASS_ORDER`, `WEAPON_SPECS` |
| `Match-Armor` | `ARMOR_SUBCLASS`, `ARMOR_WEIGHT`, `NATIVE_ARMOR`, `UNIVERSAL_EQUIP_LOC` |
| `Match-Classes` | `FACTION_CLASSES`, `CONSUMABLE_CLASSES` |
| `Match-Specs` | `SPECS` |
| `Match-Rules` | `ITEM_RULES` |
| `Scan-Stats` | `STAT_MAP` |
| `Scan-Food`, `Scan-Potions`, `Scan-Scrolls`, `Scan-Oils-Stones` | `FOOD_AND_WATER`, `POTIONS`, `SCROLLS`, `OILS_AND_STONES` |
| `Recipients-Zones` | `ZONES`, `ZONE_COLUMNS`, `INSTANCE_AREAS` |
| `Recipients-Realms` | `LINKED_REALMS` |
| `Game-IDs` | `SPELL_IDS` (Disenchant, named through `ns.DisenchantName`) |

- Vanilla files open with `if ns.IS_DISCOVERY then return end`, Discovery files with the inverse, so one set builds under the shared Vanilla TOC.
- `Match-Derivations.lua` reads `WEAPON_CLASS_ORDER` and `SPECS` as it loads, so it comes after the whole Data block.
- `Tests/`: `lua5.1 Tests/Run.lua` runs a hand-kept list of `require` lines and exits non-zero on failure; a new case file runs only once it is added there. `Tests/Stub-WoW-API.lua` is the fake client; its locale table errors on an unknown key, so a missing string fails the case that shows it. `Tests/Harness.lua` loads a fresh copy of the add-on per case in TOC order (minus libraries and most options panels) and stands in for `Core.lua` and `Announcements.lua` (`Other-Client-Characters.lua` loads the real `Core.lua`). `Tests/Outcomes.lua` is both a case and the module `Tests/Write-Outcomes.lua` loads: it builds a who-gets-what table per flavor folder (Discovery as Vanilla with its season set) and reports every row that moved against `Tests/Outcomes/`; `Write-Outcomes.lua` rewrites those files once a change in outcomes is intended.

## Architecture

### Event Loop

- `Features/Core.lua` owns the one event frame (`ns.eventFrame`) and the one entry point, `ns.On(event, fn)`. A feature file never creates its own event frame: it would bypass the Diagnostics event log.
- Several handlers can share an event; they run in registration order, which is TOC order.
- `ns.EVENT_NAMES` fills as events register (registration is flavor-gated), so Event Registration tests exactly what this client took.
- The dispatcher logs before calling handlers, behind `if ns.diagnostics.logging`, so diagnostics off costs one boolean read and an entry survives a handler error. `ns.diagnostics` comes from `Diagnostics/Diagnostics-Core.lua`, which loads after `Core.lua`; safe only because no registered event fires before every file has loaded.

| Event | File | Does |
|---|---|---|
| `ADDON_LOADED` | `Core.lua` | Name-guarded init: AceDB, `PruneOtherClientCharacters`, `RebuildStatWeights`, profile callbacks, `ns:RegisterOptionsPanels` |
| `PLAYER_LOGIN` | `Core.lua` | Welcome print |
| `PLAYER_LOGIN` | `Recipients-Who.lua` | Hooks the Who panel's `OnShow` to count it opening mid-query |
| `PLAYER_LOGIN` | `Recipients-Guild.lua` | Delayed roster request so this character's guild is saved |
| `PLAYER_LOGIN` | `Recipients-Alts.lua` | Records this character in `global.characters` |
| `PLAYER_LOGIN` | `UI-Mailbox.lua` | Hooks `MailFrame` `OnShow` (mailbox flow) and `OnHide` (recheck Distribute) |
| `MAIL_SHOW` / `MAIL_CLOSED` | `UI-Mailbox.lua` | Mailbox open and close |
| `MAIL_INBOX_UPDATE` | `UI-Mailbox.lua` | One chat line per returned gift, once per session per sender and link |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `UI-Mailbox.lua` | Same signal, filtered to `MailInfo`; gated `ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot"` (never on Era) |
| `BAG_UPDATE`, `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Mark the scan stale (Caching) |
| `WHO_LIST_UPDATE` | `Recipients-Who.lua` | Parse under `pcall`, end the query, `Who:Exhausted` on a readable uncapped answer, hand on |
| `ADDON_ACTION_BLOCKED` | `Recipients-Who.lua` | Our own blocked `SendWho` only: counted, explained with `L["WHO_BLOCKED"]` |
| `CHARACTER_POINTS_CHANGED`, `PLAYER_LEVEL_UP` | `Recipients-Alts.lua` | Re-record; level up uses the event's level, since `UnitLevel` lags |
| `PLAYER_SPECIALIZATION_CHANGED` | `Recipients-Alts.lua` | Re-record; gated on clients that pick a specialization (Mists) |
| `MAIL_SUCCESS` / `MAIL_FAILED` / `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | Advance the send queue; catch refusals with neither result event |
| `GUILD_ROSTER_UPDATE` | `Recipients-Guild.lua` | Login save, or a requested roster; otherwise ignored |
| `CHAT_MSG_ADDON` | `Generosity-Broadcast.lua` | A peer's tally or a ping; own prefix only |
| `PLAYER_ENTERING_WORLD`, `PLAYER_UPDATE_RESTING` | `Generosity-Broadcast.lua` | Broadcast presence; the throttle absorbs refires, and resting catches entering town without a loading screen |

- Deliberate registrations and hooks outside `ns.On`: the Event Registration report's throwaway probe frame (`Diagnostics/Code-Reports.lua`), the Who panel deafening (`Recipients-Who.lua`), and the `OnShow`/`OnHide` hooks on TSM's mail window (`UI-Mailbox-Tab.lua`).

### Combat Lockdown

- Only `ns:OpenOptionsPanel` refuses in combat (Style Guide → Combat Guard); it and its gate live in Options-Kit (`Options/Options-Kit.lua`).
- Nothing defers for combat: mail runs only at a mailbox, `/who` only from a click in the window, and the Generosity broadcast is gated on `ns.AtRest()` rather than combat state.

### Main Pipeline: Scan, Match, Search, Send

1. **Scan** (`Scan-Bags.lua`): bags 0 to `NUM_BAGS`, no reagent bag. `Scanner:Classify` returns a record or `nil` plus a `Scanner.REJECT` code. Codes are diagnostic identifiers for the Bag Scan report, never shown to players. Record `uid` is `"bag:slot:link"`.
   - Order (`FilterSlot`): `NEVER_GIVE` first, ahead even of the cache check. `CONSUMABLE_NOT_LISTED` before the gear toggle (or a bandage with gear off reads `GEAR_DISABLED`); gear needs a positive `classID` check because recipes carry an equip slot. Consumables then run `CONSUMABLES_DISABLED`, `KIND_DISABLED`, `NO_USE_LEVEL`, `LEVEL_GAP`, `SOULBOUND`, `REPUTATION_LOCKED`.
   - `REPUTATION_LOCKED` is last, as the one test that reads a tooltip (`Tooltip:RequiredReputation`, matched through the client's `ITEM_REQ_REPUTATION` format). Cached per item ID, but only once a tooltip actually rendered.
   - `ns.Data.MIN_RARITY` and `profile.maxRarity` gate gear only; consumables skip every rarity check.
   - **Kinds are not form** (`CONSUMABLE_TABLES`): form is the source table and item rules match on it; kinds are the player's switches. `FOOD_KINDS` maps a food row's `restores` onto the Food and Drink switches.
   - **Keep in Bags** runs after the filter, per item ID, on whole stacks, largest first: `KeepAmount` takes the largest keep among the item's kinds switched on (`profile.keepInBags`, stops in `ns.Bags.KEEP_ORDER`). Mail takes a stack whole, so a keep holds back stacks, never splits one. `Scanner:Scan` drops held stacks silently; `ScanAll` (the Bag Scan report) relabels them `KEEP_IN_BAGS`.
   - **Never Give Away**: `profile.neverGive[itemID]`, written through `ns.Bags:NeverGive` / `GiveAgain`, listed by `NeverGiveList`.
2. **Match** (`Match-Engine.lua`): one `verdict` per item — `eligible`, `admitted`, `contenders`, per-class `claims`, `fits`, `coverage`, `best`, and a state (`gift`, `leftover`, `unreadable`). `Match-Derivations.lua` answers the table questions, `Match-Ranking.lua` turns a verdict into bands and ranked candidates. Downstream reads the cached `item.verdict`. *Admitted* is about classes, never the live roster, or everything would read as leftover before the first `/who`.
3. **Search**: three sources fill one pool through `MatchList:AddResults` (`Match-Roster.lua`). `PullAlts` and `PullGuild` (`UI-Mailbox.lua`) need no press; `/who` sends one query per press.
4. **Send** (`Mail-Sender.lua`): `ns.Distributor` walks a job queue, one `SendMail` at a time, waiting on a result event.

- State lives at file scope: `Match-List.lua` holds `items` and `assignedTo` and runs the allocator; `Match-Roster.lua` holds `pools` and `poolsGeneration`. Items, roster and hand picks survive walking away.
- `UI:Rescan` (`UI-Mailbox.lua`) re-plans the search from fresh bands before assigning, so a settings change searches for what is listed now; found players are kept.
- **The `matching` flag** (`UI-Mailbox.lua`): after the window opens, `UI:Assign` only redraws until Find Recipients is pressed; that first press re-plans from `RescanBags` rather than stepping a plan `UI:Rescan` left standing. `UI:HasSearched` feeds the status line.

### Caching

- **Cold item cache**: `C_Item.GetItemInfo` nil rejects the slot as `NOT_CACHED`, never treats it as empty. `GET_ITEM_INFO_RECEIVED` counts only for an item the last scan rejected that way (`Scanner:IsPending`) and resolved with `success ~= false`. Without it a cold cache reads as an empty bag and the window lists nothing. `pendingItems` is wiped only by `Scanner:Scan`; `ScanAll` adds to it without wiping.
- **Debounced rescan** (`Match-List.lua`): neither event scans. `ScanSoon` sets `bagsDirty` and arms `SCAN_DEBOUNCE` only when `WouldRescan()` holds: database exists, no distribution run busy, and the window is shown. The timer re-asks `WouldRescan()`.
  - Window shown: `EnsureScan` plus `UI:Assign()`, against the pool already found, plan left alone (re-planning would throw away a Rescan for Better Match mid-run).
  - Window shut: `bagsDirty` stays set; the next open pays for one scan (`EnsureScan` in the tab's click).
  - Excluded during a run: Distributor slots stay full until each send is confirmed, and the deliveries' own `BAG_UPDATE` brings the scan back.
- **A mailbox opening only puts up the tab**: every report (`MAIL_SHOW`, `OnShow`, interaction manager, the Distributor's own `MailFrame:Show`) runs `MailboxOpened`, which scans nothing and opens nothing. A window left open from before is redrawn, except while `Distributor.busy`.
- **Stats read twice, merged by max per stat, never summed** (`NormalizedStats`): `GetItemStats` resolves the base item and misses random suffixes; the tooltip renders the item as seen. Both report fixed stats, so a sum doubles them. `record.statRead` keeps each source's answer for Item Verdict.
- **Tooltip read** (`ns.ReadTooltip`, `Utilities.lua`): `C_TooltipInfo.GetHyperlink` first, hidden `PlayItForwardScanTooltip` otherwise. A `C_TooltipInfo` read counts only with real text (without `SurfaceArgs` every `leftText` is nil).
- **Tooltip parsing** (`Scan-Tooltip.lua`, `Tooltip:StatsFromLines`, pure so the API report and tests can feed literal lines). `STAT_BY_NAME` and `FORMAT_READERS` are built on first call. Each line: `CleanLine`, skip non-stat lines (Use:, Chance on hit:, set bonuses, built from `ITEM_SPELL_TRIGGER_ONUSE`, `ITEM_SPELL_TRIGGER_ONPROC`, `ITEM_SET_BONUS`, plus the `(N)` inactive set shape), then readers in order:
  1. `+N Name` against every lowercased `STAT_MAP` global, plus `ENUS_FALLBACK` names merged in on every locale where no localized global took the name (`StatNames`).
  2. `SplitStats` for two-stat lines (TBC "+42 Healing Spells and +14 Damage Spells"), splitting at each `+N` and retrying a half with its last word dropped, so a translated "and" goes too. A line only half resolved still counts as unread.
  3. `ReadFormatted`, patterns from each long `ITEM_MOD_*` format behind a `_SHORT` `STAT_MAP` key, for locales that write the name first (koKR).
  4. `EQUIP_PATTERNS`, English clients only (`Tooltip.equipPatternsUsable`).
  - A signed-number line no reader resolves goes back as unread for Item Verdict; only that shape, or prose would bury it.
- **Candidate cache** (`MatchList:Candidates`, `Match-Roster.lua`): ranked list cached on the item as `_candidates`, stamped `_candidatesGeneration` against `poolsGeneration`.
  - Generation bumps in `AddResults` when a pool entry changed (new player, newly `guild` or `alt`, higher level, different area) and in `RecheckGuildmates` when it drops someone. `RescanBags` needs none: it replaces every item table.
  - Ranking never reads `item.recipient`. Settings it reads (`sendToAlts`, alt choices, specs, the prioritize switches, `ignoreSummonerWarlocks`) bump nothing; their setters call `ns.RefreshMailWindow`, which rescans.
  - Handed out by reference. Derived per-item fields carry a leading underscore (`_weaponKey`, `_candidates`, `_candidatesGeneration`, `_specVerdicts`).

### Scoring: Claim, Fit and Coverage

- **Weights**: the recipient's spec is unknowable, so specs are assumed. `ns.Data.SPECS[class]` lists each spec's `key`, `role`, `main` stats (2) and `useful` stats (1); `off = true` ships a spec disabled. `profile.specs[class][key]` stores only differences from the default, so a default changed in a release reaches everyone who never touched it.
- *Useful* means the tree gears for the stat, not that it merely benefits; defense, dodge, parry, block and resistances are weighted for nobody, by the maintainer's choice. `SPELL_POWER` is never listed: `SpecPoints` takes the better of `SPELL_DAMAGE` and `HEALING`. Main overrides useful within a spec.
- `ns.Data.RebuildStatWeights` sums enabled specs into `ns.Data.STAT_WEIGHTS` on a three-spec scale: `main` averaged over enabled specs times three (a Holy-only paladin is as committed to Intellect as a mage); `useful` summed, scaled by `min(1, 3 / #specs)` over every spec the class has. A class with every spec off gets no weights and no gear. Also records `ns.Data.MAIN_STATS`. Rebuilt at load, after AceDB, on spec change and profile change; cached verdicts are not, so a spec setter rescans. The scale is pinned by tests against `CLASS_SHARE`: against a main stat, a useful one is only ever a fallback.
- **Budget first**: `ns.Data.StatPoints` multiplies a tooltip number by `STAT_BUDGET` (1 when unlisted) before weighting, so Classic's "+1% crit" can compete with "+10 Strength".
- **Claim** (`Matcher:SpecScore`): weighted stats only; decides *admitted*. **Fit** (`Matcher:Score`): claim plus `WEAPON_BASELINE` × item level on weapon-matrix items, keeping statless weapons placeable; decides *ranking*. **Coverage** (`Matcher:Coverage`): share of the item's own scoreable stats, counted at `STAT_BUDGET` points, that the class weights at all; decides *breadth*.
- Coverage exists because sums let one large weight beat breadth ("of the Gorilla": warrior strength alone outscores a paladin weighting both stats). Contention needs both `CLASS_SHARE` of the best claim and strictly more than `COVERAGE_MAJORITY` (set where it is because Classic's two-stat suffixes split near-evenly). Failing either leaves the class admitted: in the dropdown, a fallback.
- Adding a weight or toggling a spec reshuffles contention on every item carrying that stat.
- **Coverage abstains** when it demotes everyone: `Verdict` falls back to everyone who cleared `CLASS_SHARE`. Nothing scoreable returns coverage 1 (placed by the baseline).
- **Primary stat names the class**: an item with Strength, Agility or Intellect leads only with contenders building on one (`MAIN_STATS`), else admitted classes gearing for one, else nobody. Exists because Mists secondaries outweigh the Agility beside them (a mage would lead an Agility cloak on crit), and because a rogue's Strength is a secondary, which keeps "of the Soldier" with the warrior.
- **Body armor leads with natural wearers**: only the lowest priority group of contenders stays. Not for cloaks, rings, weapons, shields, held off-hands.
- **Stamina is everybody's**: left out of coverage and not a judged stat; a Stamina-only weapon takes the everyone-fallback unless some eligible class weights Stamina.
- **Faction filters classes**: `AllClasses()` keeps classes `FACTION_CLASSES` lets the player's faction roll; union until `UnitFactionGroup` answers, then memoized on any answer (a faction with no row, such as Neutral, keeps every class for the session). Source list `EVERY_CLASS` stops at the monk.
- **Consumables skip scoring**: `SpecScore` and `Score` return 1, but `Verdict`'s consumable path leaves `claims` and `fits` empty and sets `score = 1`, so ranking and `TargetedClasses` read fit 0 for every class. Eligibility from `restores`/`buffs`/`enhances` through `CONSUMABLE_CLASSES`; the band does the rest. Veto and `ClassEnabled` are skipped; `prefer` and `demote` still apply.
- `best` comes from contenders, ties to the lower priority group.
- **`Matcher:VerdictForSpecs`** (alts) swaps `ns.Data.SpecOverride` and rebuilds the global `STAT_WEIGHTS` twice per uncached call, under `pcall`; anything reading the weights during that call sees the alt's specs. Cached per item as `_specVerdicts`.

### Verdict States

- `gift` / `leftover` split at `ns.Data.LEFTOVER_THRESHOLD`. No eligible or no admitted class is always leftover; so is statless non-weapon-matrix armor.
- `unreadable`: at least one class eligible, carries a suffix id, nothing parsed. Exists because a failed suffix parse looks exactly like a worthless item, and telling a player to vendor it cannot be undone. Held out of auto-assignment, disenchanting and Rescan for Better Match.

### Item Rules

- `ns.Data.ITEM_RULES` (each folder's `Match-Rules`), matched in `Match-Derivations.lua`: pair-of-stats meaning the weights cannot express. One matcher per rule: `weapon` key list, consumable `form` plus `restores` (both required), or `requires` (optional `exclusive`, `without`, `armor` material). `Matches` tests `unclaimed`, then weapon, consumable, stats.
- Verbs:
  - `veto` / `vetoUnlessRole`: removes the class before scoring; the only absolute verb. Skipped for consumables. `vetoUnlessRole` reads `ns.Data.ClassHasRole` live.
  - `prefer`: names the contenders after scoring, narrowed to admitted. **First match wins**, even when it names nobody admitted (then it blocks every `prefer` below).
  - `demote`: drops from contention, keeps admitted; after `prefer`, accumulates.
- `unclaimed = true` is a condition, `offerToEveryone` in `Matcher:Verdict`: no class had a stat claim, the item is weapon-matrix, and it has no ranked non-Stamina stat. Pairs with `prefer`/`demote`, never `veto`.
- `ApplyDemotion` falls back contenders → scoring's answer → admitted, never straight to admitted (that would promote what coverage demoted).
- `exclusive` counts weighted stats only (armor and resistances would make a bare Stamina ring qualify where a chest did not).
- Blind spots: no rule can key on `buffs` or `enhances`; `weapon` rules need `classID == 2`; `armor` rules exclude `UNIVERSAL_EQUIP_LOC`.

### Recipient Ranking

- `Matcher:RankCandidates` (`Match-Ranking.lua`) ranks pooled players of the **admitted** classes, each against its own class's band, plus any class an alt in the pool plays. Keys: `fit bucket -> source -> placement -> level proximity -> armor/weapon group -> class fit -> shuffle -> name`.
- **Source** (`Matcher:SourceRank`): alt, then guildmate, then stranger, each step only while `profile.prioritizeAlts` / `prioritizeGuilds` is on. `Matcher:Source` is the raw value the picker files sections under.
- **Placement** (`Who:Placement`, `Recipients-Zones.lua`): `PLACED_LEVELING` (a `ZONES` zone fitting their level within `ZONE_LEVEL_SLACK`), `PLACED_UNKNOWN` (also a listed zone their level doesn't fit), `PLACED_ELSEWHERE`, `PLACED_INSTANCE`. `Who:PlacementRank` applies `prioritizeLevelingZones` and `prioritizeOutsideInstances`; a switch off drops its key. All prioritize switches read as `~= false`.
- **Instances are area records**: `Who.InstanceNames` names `INSTANCE_AREAS` AreaTable IDs through `C_Map.GetAreaInfo`, the record `/who` names a zone by. Classic Era and Forever ship no dungeon maps.
- `profile.ignoreSummonerWarlocks` skips stranger warlocks in `SUMMONER_MIN_LEVEL`..`SUMMONER_MAX_LEVEL`; the guild roster has its own always-on rule (`SUMMON_ALT_*` in `Recipients-Guild.lua`). The stranger band is wider because a stranger is an opt-in guess.
- **Band per class** (`Matcher:LevelBand`): gear anchors below its equip level (`LEVEL_GAP_WIDEST`..`LEVEL_GAP_CLOSEST` under it, arriving just before it is useful); consumables anchor at their use level, `CONSUMABLE_RECIPIENT_GAP` up. `item.bandLo`/`bandHi` are the union, for display and reports only.
- `CONSUMABLE_RECIPIENT_GAP` (how far above the use level a recipient may be) and `profile.consumableLevelGap` (how far below your level a consumable is outgrown) answer opposite questions: the first stays small, the second large.
- **Armor proficiency reach**: `NATIVE_ARMOR` rows are steps read through `NativeArmorAt`. `ns.Data.ArmorEquipLevel` answers the later of the item's requirement and the class's training level, so a later training level moves the band instead of closing the door (level 35–39 mail is itemized for hunters who train mail at 40). `PROFICIENCY_REACH` bounds it, so an older item does not arrive stale; armor only, since weapons have no training level. Training levels are probed off `NATIVE_ARMOR` up to `MAX_PROBE`. `Matcher:BandGroups` splits classes by band.
- **Weapons have no reach**: `WEAPON_SPECS` rows count trees per class in `WEAPON_CLASS_ORDER`; 0 means cannot receive. Relics get weapon keys through `RELIC_SUBCLASS`.
- **Shuffle** is rolled once per player at pool entry, never in the comparator.
- **One recipient floor**: `ns.Data.MIN_RECIPIENT_LEVEL`, enforced only in `MatchList:AddResults`, the door every source uses. Alts are exempt.
- **Fairness** (`Recipients-Fairness.lua`): session-only `name -> { level }`; fresh again once seen higher. `Fairness:PickFrom` takes the first free, reachable, fresh candidate, then the first free and reachable. Unreachable = server refused mail this session (`MarkUnreachable`). `Credit` records alts too; only the `person.alt` test in `PickFrom` keeps them off the cooldown.

### Allocation

- `MatchList:Assign()` rebuilds every unpinned pairing each pass. Filling only the gaps would strand soft rules: an "of the Owl" staff given to a hunter would never move to a priest found later. A row is `pinned` when the player picked a recipient, kept it, or unticked it.
- **Scarcest first, then best first**: an item two people can take picks before one fifty can take. One item per person per pass; an item nobody can take sorts last. Alts are exempt from one-per-person (`IsTaken`).
- **Disenchant step last**: with `profile.disenchantUnmatched`, each unpinned unmatched `MatchList:Disenchantable` row (leftover gear only) goes to `ns.Alts:DisenchantRecipient()`, staying unpinned so a later gift can take it back.
- After a pass: no gift still searching → `ns.Who:Clear()`; else `ns.Who:Prune`; during a targeted search `NarrowTargeted` (`Match-Search.lua`) instead.
- **Still searching** (`StillSearching`, `Match-Search.lua`): an unpinned `gift` row unmatched, held by a fallback, or held by a holder `Who:KeepsSearching` says a better-placed find would beat. Only a holder ranked as a stranger (`SourceRank` 3, which includes a guildmate or alt whose Prioritize switch is off) can be beaten. A holder is in contention when the class is a contender **or the holder is an alt** (`HolderInContention`): alts are admitted by their own specs. Leftovers and unreadables never count.
- **Bands**: `MergeBands` (`Match-Search.lua`) is shared by scan bands, searching bands and Who-Plan spans, so `Who:Prune` compares bands built the same way; `emptyMeansAnyone` lets a band with no class absorb its neighbours. Scan bands include leftovers so the dropdown has candidates for a manual override; `SearchingBands` leaves them out.
- **Ticks**: every row starts ticked; a tick means give away and does not pin. Unticking pins and keeps the name for a re-tick. `RescanBags` carries `send` and `pinned` by slot, restoring hand picks first, then automatic pairings whose name is still free.
- Closing the window runs `MatchList:ReleaseAutomatic`: pins and pool survive, nothing re-matches until Find Recipients.

### /who Search Planning

- `C_FriendList.SendWho` is hardware-event gated: outside a real click it raises `ADDON_ACTION_BLOCKED` and nothing else (no error, no `WHO_LIST_UPDATE`). Every press must count. `Recipients-Who-Plan.lua` builds the plan; `Recipients-Who.lua` sends it.
- **One class filter per query**: the client honors one `c-"..."` and silently drops the rest. Multiple `z-` filters kept as best effort.
- **Female class names** get a twin query right after the male one; `Who:Exhausted` never lets one gender exhaust the other; pruning treats the pair as one class. Whether `/who` needs the female name at all is unverified in game (comment at `FemaleName`).
- **Plan per span**: zones first (people out leveling), then bare levels, then one query per class. Ahead of all, one `lo-hi g-"Name"` query per guild added by name (`Guild:SearchNames`), spanning every band.
- `Coalesce` (`Recipients-Who-Plan.lua`, via `MergeBands`) folds bands into spans up to `SPAN_MAX`, since several narrow bands would each cost a press where one wider query answers. Spans are interleaved so distant items both progress.
- **An answer under the cap ends what it answered** (`Who:Exhausted`): capped is `raw >= WHO_RESULT_CAP or total > raw`. Zoned, guild and unparsed answers never exhaust anything.
- `FILTER_MAX` is a hard budget on the filter string (over it the server does not answer); `ZoneChunks` splits zone lists to fit.
- **Zone order** (`ns.Data.ZonesFor`, `Recipients-Zones.lua`): overlap, centrality, narrower, table order. Unresolved faction admits every zone. A zone with no client name is cached `false` by `Who.AreaName` and skipped, never sent as `z-""`.
- **`Who:Prune` only removes**, and runs from `MatchList:Assign`; re-planning via `Who:Plan` restarts at the first attempt. `Who:Plan` and `Who:Clear` cancel the pending query; `Who:Plan` sets `Who.targeted` to its argument, `Who:Clear` to false. `Who:Remaining` leaves out a canceled pending query, or the next press would step to an attempt that can't send.
- `Who:Step` returns the attempt's label; its callback gets `nil` results on a timeout and `{}` on an unreadable answer.
- **Rescan for Better Match** (`UI:FindRecipientsForItem`): offered only where `UI:RescanCanHelp` (not unreadable, admits someone), shared by the picker entry and the press. Plans `Matcher:TargetedBands` with `targeted = true`: contenders first, zones then class queries, no bare query, no guild-by-name queries, no `Coalesce`, and all zone queries before all class queries. One class per class attempt (a class filter finds players in dungeons and unlisted zones that zone filters miss); a group of several classes (a consumable) sends its zone queries with no class filter. Tracks the row by slot key (`MatchList:Target`). `NarrowTargeted` drops attempts whose class could not outrank the holder (`Who:PruneTargeted`, `Matcher:CouldOutrank`; an alt holder ranks with the contenders). Refuses with `L["WHO_WAIT"]` while a query is in flight or the throttle runs, before retasking.
- **Timing**: `WHO_THROTTLE` (exposed as `Who.THROTTLE`, read by `UI:LockFindButton`) runs from the send. The Recipients-Who `RESULT_TIMEOUT` requeues an unanswered query at the front.
- **Who panel deafened per query**: the stock UI opens the Who panel on `WHO_LIST_UPDATE`, and as a UIPanel it closes `MailFrame`, ending the mailbox interaction. `BeginQuery` unregisters `WHO_LIST_UPDATE` from every frame `GetFramesRegisteredForEvent` names except `ns.eventFrame` (skipping forbidden ones) and sets `SetWhoToUi(true)`; `EndQuery` re-registers exactly those, restores `SetWhoToUi(false)`, hides the panel only if it was closed before. Naming `FriendsFrame`/`WhoFrame` is only the fallback. Parsed under `pcall`, `EndQuery` either way. An abandoned query is marked `canceled`, never dropped.
- **Parsing**: other-faction results dropped via a race-name → faction table from `C_CreatureInfo.GetRaceInfo` (race IDs probed up to a fixed bound; unplaceable or shared races kept). Connected-realm results are kept and counted. Each answer reads `ns.Guild:WhoLookup()` once: members of any usable My Guilds guild are flagged `guild` with `guildName`; ignored members dropped (`counts.ignoredGuild`). The lookup matches by guild name alone (`NameKey`), so a same-named guild on a connected realm matches too.

### Guild Roster

- `Recipients-Guild.lua` hands a filtered list to a callback in the `/who` result shape; `PullGuild` feeds `AddResults`. No press, no throttle.
- `Guild:Request` is callback-gated, holding one callback (a second request before the answer replaces the first): `GUILD_ROSTER_UPDATE` storms in large guilds, so with no request outstanding it is ignored, except the login save (first update with members runs `Guild:Save()`). Pulled when the window opens at a mailbox and when a fresh plan starts; never for a targeted search.
- `Classify` drops, in order and counted apart: your own characters, members ignored on My Guilds, summoning alts (`SUMMON_ALT_*`), and members offline past `profile.guildOfflineLimit` (`Guild.OFFLINE_DAYS`; any key it lacks means no limit). An offline member with no reading counts as too old (the roster arrives in pieces).
- **Own-character detection** (`OwnCharacters`) reads `ns.db.sv.profileKeys` (never `ns.db.profileKeys`) and `global.characters`. Realm keys rebuilt as `Character-Realm` via `ns.NormalizeRealm`; Forever's `"First Last"` keys qualified like a roster row.
- **Saved guilds**: every character saves its roster to `global.guilds`, keyed `Guild:Key` (`realm:faction:name`). `Guild:ReadSaved` offers ticked guilds on this faction and any realm `ns.Alts:Connected` allows (`Guild:Usable`), minus the current guild (read live); a bare name from a connected-realm guild is addressed `Name-Realm`. Members age out by `days` plus days since the scan. `Guild:Read` saves first, then returns nobody when the current guild is unticked or removed, so the panel's roster stays fresh. `Guild:Save` reuses the entry, keeping `removed`, `include` and `ignored`.
- **Guilds added by name** (`Guild:Add`, the Add Guild box; several names split on comma, semicolon or newline): `added = true`, no members; searched by `g-"Name"` queries. Names compare via `NameKey` (trimmed, spaces collapsed, lower case); `Guild:Save` takes over an added entry spelled with other capitals.
- **Removing** (`Guild:Remove`, confirmed in the panel): an added-never-saved guild is deleted; any other is flagged `removed`, since a character in it would save it again at login. Re-adding by name clears the flag.
- **Ignores** live in `entry.ignored[qualified name]`, which `Guild:Save` leaves alone; an ignore holds even when its whole guild is unticked or removed.
- **My Guilds changes reach the pool** through `MatchList:RecheckGuildmates`, called from the panel's `Changed()`: drops (never demotes, since a roster member was never a searched stranger) pooled guildmates the lookup no longer calls guildmates, or calls ignored.

### Alts as Recipients

- Each character records itself in `global.characters` (`Recipients-Alts.lua`) at login, level up, respec: name, realm, class, level, faction, spec. A login never rewrites the player's choices on the entry (`include`, `specs`, `levelsBelow`, `levelsAbove`, `disenchanter`).
- Spec read (`DetectSpec`): `C_SpecializationInfo.GetSpecialization` on clients that pick a specialization (Mists has no global and its talent tabs throw); elsewhere the most-pointed tree. `GetTalentTabInfo` returns name-first on Era and id-first later, moving points from the third return to the fifth. The index reads `ns.Data.SPECS[class][index]`, so each `Match-Specs` row order must match the client's tab and spec order. A nil answer keeps the old `spec`.
- Unset `include` = ticked below the level cap, unticked at it (`Alts:IncludedByDefault`, `GetMaxPlayerLevel` used alone where it exists). `Alts:Included(nil)` is false, so an alt deleted this session stops receiving.
- Reach: `Alts:Connected` (same realm or same `LINKED_REALMS` cluster); `Alts:Address` mails bare on this realm, `Name-Realm` on a connected one.
- Judged by its own specs: `Alts:SpecsFor` (the player's ticks, else the recorded spec, else every spec; never the class defaults) → `Matcher:VerdictForSpecs`. An alt follows its recorded spec until the player changes any tick on My Alts; that first change writes the whole set to `alt.specs` and freezes it, and unticking all stores an empty set, not a return to the default. Gear and consumables only inside `Alts:LevelRange` (stops in `ns.ALT_LEVELS_BELOW_ORDER`, `ns.ALT_LEVELS_ABOVE_ORDER`; consumables by use level, `AltWants`).
- `ALT_LEVELS_*_ORDER` defaults are positional (first stop below, last stop above) and `Options-Alts` stores nil for the default pick, so reordering a list moves every alt that never picked.
- **Mailing yourself is not giving**: alts skip one-per-person, the cooldown and the tally. Mail to an alt carries **no subject or body**: a letter with text stays in the mailbox after its item is taken. The client writes the item name into the emptied subject box on attach.
- A refused alt is dropped via `ns.Alts:Forget`; it re-records at its next login.
- **Disenchanter**: one per realm cluster and faction, `disenchanter = true` on its `characters` entry (`Alts:SetDisenchanter`), not the profile, because the shared Default profile also serves characters that cannot mail it.

### Character Identity

- `ns.PlayerName()` is the mailing address: `"First Last"` where `ns.UsesSurnames()` (WoW Forever, via `UnitNameUnmodified`), `UnitName` elsewhere.
- `ns.QualifyPlayerName` is identity, not address: appends `-Realm` to a bare name. Roster rows, the current character, the `AddResults` dedupe, peer keys and own-echo detection all compare through it. The pool keeps the name exactly as the API gave it, because that is what `SendMail` takes.
- AceDB keys characters `"Name - Realm"` on realm clients and `"First Last"` on Forever. `PruneOtherClientCharacters` (`Core.lua`, right after `AceDB:New`) drops saved characters shaped the other way: copied WTF folders (Style Guide → Other-Client Characters). It also prunes namespaces and non-string keys, and deletes a pruned character's same-named profile unless the current or a kept character uses it. Not a migration; permanent.

### Mailing

- `SendMail` cannot be looped; one send, then wait for a result. The non-friend confirmation popup is never auto-clicked.
- **Ordering constraints** (`Distributor:Next`):
  - Check the Send Mail panel before touching the item: `UseContainerItem` with it closed *uses* the item. Each job checks `ns.AtMailbox()` and postage (`MAIL_COST`); missing either pauses the run (`MAIL_NOT_AT_MAILBOX`, `MAIL_NO_POSTAGE`). It forces the Send tab (`MailFrameTab_OnClick(nil, 2)` under `pcall`) and finishes with `MAIL_PANEL_CLOSED` if `SendMailFrame` still is not shown.
  - Empty the subject box before attaching, fill the panel after: the client writes the item name only into an empty subject. `SubjectOf(job)` falls back to that text, then the link's bracketed name.
  - `FillMailPanel` fills each box under its own `pcall`; the fill is cosmetic and never breaks a send. Era has no `SendMailBodyEditBox`: the body box is found by what exists (`MailEditBox:GetEditBox()`), never by flavor.
  - Never re-read the bag slot on `MAIL_SUCCESS`: it fires before the bag update. Stack size captured as `job._count` before the send; delivered rows removed by `uid`.
- `GetSendMailItem(1)` checked before every send (a failed attach posts an empty letter as success). Moved items skipped as `MAIL_ITEM_MOVED`. Attach and `SendMail` under `pcall`; a throw releases the attachment via `ClearSendMail`. After each call the job re-checks `busy` and current job.
- **Run state**: `running` covers the whole run; `busy` covers one send and is false during the failure settle. **Stop** (`RequestStop`) halts at once, or after the letter in hand or the settle resolves; `Halt` prints the stopped count, flushes, calls `onDone` and broadcasts. `stopped` feeds the status line; `onStateChange` drives `UI:SyncDistributeButton`.
- **Held chat lines**: each "Sent … to …" line waits in `_held` until the run's total prints (`FlushHeld` from `Finish`, `Halt`, `Pause`, `Stop`).
- **Sent list**: `Distributor:Sent()` feeds the window's Sent section, cleared on window show and hide.
- **No answer pauses** (Mail-Sender `RESULT_TIMEOUT`): job moves to `_awaiting`, player told to Accept and press Distribute. A late result (`Distributor:Result` while not busy) credits the send, adds it to the Sent list, removes it from the head of the queue and calls `onProgress`; without that the row stays ticked and a resume skips it as moved. `Start` refuses for one more timeout while a job is held (`MAIL_STILL_SENDING`), then clears it. `RecheckDistribute` (`UI-Mailbox.lua`) also clears `_awaiting` once the player leaves the mailbox.
- **Closing the mailbox stops the run**: `RecheckDistribute` waits one frame, stops if `ns.AtMailbox()` is false.
- **Refusals**: `UI_ERROR_MESSAGE` matched against the client's `ERR_MAIL*` globals (format-specifier strings skipped) plus `OTHER_MAIL_ERRORS` (`ERR_PLAYER_WRONG_FACTION`, without which a cross-faction send waits out the full timeout); `Distributor:IsMailError` is that test, shared with the event log filter and an API row. Only a job with `_sent` marks the name unreachable and runs `DropRepeats` (an attach error is about the item; a bare `MAIL_FAILED` names nobody). `RECIPIENT_ONLY_ERRORS` never count. A refusal inside the settle window marks the name and drops repeats but counts nothing. `FAILURE_SETTLE` absorbs the second signal; `Distributor._run` bumps on `Start`/`Stop` so stale timers do nothing. Abort after two consecutive counted failures, clearing the panel first (the failed item and name still sit in it). Repeats dropped are not skips: `Finish`'s skip count means items that moved in the bags.
- `UI:Distribute` sends one parcel per stranger per run (`MAIL_ALREADY_HAS_ONE`); alts and hand picks exempt. `Distributor:Finish` and `Halt` trigger a Generosity broadcast.
- **Returned gifts** (`UI-Mailbox.lua`, `MAIL_INBOX_UPDATE`): `IsGiftSubject` recognizes a returned gift by the current `BuildSubject()` or stock `L["MAIL_SUBJECT"]`, so a gift sent under an older custom subject is not recognized.

### Mail Copy

- `Mail-Copy.lua`: player's `mailSubject`/`mailBody` when set, cleaned by `Distributor:CleanText`, else `L["MAIL_SUBJECT"]`/`L["MAIL_BODY"]`. `Distributor.MAIL_FIELDS` maps each key to its stock string and byte ceiling; editor and mailer both read it.
- A custom body always ends with `L["MAIL_POWERED_BY"]`. Custom copy is stored uncut and cut at build (`SUBJECT_MAX`, `CUSTOM_BODY_MAX`) by `Shorten`, byte-measured, never inside a multi-byte character, footer after the cut. `SaveCustomText` stores `""` when the text equals stock.

### The Distribution Window

- `PlayItForwardMailFrame` (`UI-Window.lua`): sizes and gaps on the Spacing Scale except the row icon and row height and the title strip (`TITLE_BAR_HEIGHT`, `TITLE_BAR_RIGHT`). The scrollbar is the add-on's own thin thumb in a narrow gutter, no template. Title text through Menu-Kit's `Kit.WindowTitle`, centered (README-Notes). Portrait `Gift.tga` via `PortraitFrameTemplate`, falling back through `ns.PickTemplate` (which returns the last name even when that template is missing). Skinned for ElvUI through `ns.SkinWidget`/`ns.SkinScrollFrame` when present.
- **Geometry**: resizable; `UI:SaveGeometry` writes `profile.windowPos`/`windowSize`, whose `point`/`width` fields mean the player moved or sized it. Position is saved with every resize, since sizing from the corner can move the anchor. `UI:ResetWindowPosition` (tab menu) empties both, restores `FRAME_WIDTH`×`FRAME_HEIGHT` and calls `PlaceAtFirst`.
- **Placement is written three times**: `UI:BuildFrame` and `PlaceAtFirst` (`UI-Window.lua`) and `UI:Open` (`UI-Mailbox.lua`) each put an undragged window `UI.MAILBOX_TAB_SIZE` plus a gap right of `UI:MailboxTabHost()`, clear of the tab. Change one, change all three.
- Never opens by itself: only the mailbox tab and its menu open it. Never auto-closes.
- **Top bar** (`UI-Top-Bar.lua`, `UI:BuildTopBar`): mirrors the options panels, writing the same profile keys. Each tick's tooltip is the panel's own description. A dropdown hides while its tick is off; kind ticks dim instead. Second line: the Disenchant tick (`profile.disenchantUnmatched`) and the enchanter dropdown (`UI:OpenDisenchanterPicker` → `ns.Alts:SetDisenchanter`, `UI:SyncDisenchanterButton`). `UI:SyncControls` is the one redraw entry point (ticks, panel setters, `ns:ApplyProfile`); a change runs `UI:Rescan()` and `ns.RefreshSettings()`. The list hangs from `UI.TOP_BAR_BOTTOM`.
- **Sections**: Matched, Disenchant (labeled `ns.DisenchantName()`, computed once at file load), Pending Match, Stats Couldn't Be Read, Kept, Sent (no tick); then score, then bag order. Disenchant is its own section because the enchanter is often also an alt, whose name would otherwise appear twice under Matched; `UI:RecipientLabel`'s icon does the same on the row. Each heading shows a row count and a tick (`UI:SectionTick`, `UI:ToggleSection`) that skips rows already in the asked state, so it never pins a pairing the allocator made.
- **Row ticks**: a dimmed tick is display only (`item.send` unchanged); `SetMotionScriptsWhileDisabled` keeps its tooltip saying why.
- **Status and Distribute** (`UI-Status.lua`): `UI:StatusLine` (frame-free for `Tests/Status-Line.lua`) picks the first that holds: sending, stopped with ready rows, waiting on a search, ready (or away from a mailbox), Kept disenchantable gear with Disenchant off, done (Sent list). Distribute reads Requires Open Mailbox away from a mailbox (`ns.AtMailbox`, never `ns.mailboxOpen`), Stop during a run (disabled once a stop is requested), enabled only with a ticked row holding a recipient. Find and Distribute share one width, the widest label measured with a hidden ruler in `UI:BuildFrame`, capped at half the button row.
- **Row dropdown** (`UI:PickerOptions`, `UI-Assignment.lua`, frame-free for `Tests/Manual-Assignment.lua`): `UI:PickerHeader` (count, band and `UI:BestFitLine`, or why nobody; an empty list gets a note), candidates under Your Alts (alphabetical) / Your Guild / Strangers (ranked), Disenchant (gear rows only; disabled, not hidden, with no enchanter) and Keep Item, Rescan for Better Match when `UI:RescanCanHelp`, then Never Give Away (`ns.Bags:NeverGive`). The recipient button has no tooltip; the header is where its reasoning lives. Notes beside names are information, never gates. Picking a name holding another unpinned row takes it; an alt's name never is. `UI:BestFitLine` reads contenders, and shows no line for a consumable that fits more than three classes equally.
- **Picker** (`UI-Picker.lua`): a thin adapter onto Menu-Kit. `Picker:Entries` turns option lists into kit entries (a spacer before each separator) and `Picker:Build` makes one shared list (`Kit.CreateDropdownMenu("PlayItForwardRecipientPicker")`) used by the row dropdown and the top bar's Disenchanter, Rarity and Gap lists. Each entry's `onClick` runs `onSelect` **before** `Picker:Close`, with `keepOpen = true` so the kit doesn't hide the list first (issue #16). `PickedTest` checks the current choice: a list that sets `selected` is taken at its word; top-bar lists match the button's text, or its text plus a space (the Disenchant list adds the level).
- **Escape** goes through `UISpecialFrames` (Hide only). Everything that stops on close hangs off `OnHide` via `UI:OnClosed`, idempotent; `UI:Close` also calls it directly for a window never shown. `OnHide` returns early while still shown (Alt+Z), and is set after `BuildFrame`'s own `Hide()`, or it would fire before `UI.frame` exists. The open picker pulls the window out of `UISpecialFrames` so Escape closes only the list; `RestoreMainWindow` puts it back one frame after the list closes (Escape's own walk would otherwise reach it), unless the list reopened.
- `UI:ScrollList` keeps its own offset rather than reading it back from the scroll frame, so a shrunk list is pulled back into range.

### The Mailbox Tab

- `UI-Mailbox-Tab.lua`, `PlayItForwardMailboxTab`: a `CheckButton` sized `UI.MAILBOX_TAB_SIZE` with `Gift.tga`, its top-left on the host window's top-right edge. Shows at a mailbox on the window `UI:MailboxTabHost` names (`UI:WantsMailboxTab`), whatever the Distribution Window is doing: `MailFrame` while it is shown, else TSM's mail window while `TSM_API.IsUIVisible("MAILING")` holds.
- **Finding TSM's window**: it has no name, and TSM's API hands out only its crafting window, so `FindTSMFrame` picks the shown, largest direct child of `UIParent` whose `GetSourceLocation()` names a TradeSkillMaster file, then hooks its `OnShow`/`OnHide` to re-sync. `IsForbidden()` is asked first; any other call on a forbidden child errors. A client without `GetSourceLocation` gets no tab on TSM's window.
- `MailboxOpened` syncs now, next frame and shortly after (`UI:SyncMailboxTabSoon`), since a mail add-on can show its window late. `UI:SyncMailboxTab` also runs from `Open`, `OnClosed`, `RecheckDistribute`.
- Parented to `UIParent`, only anchored beside the host, and not skinned, so ElvUI's `StripTextures` can't take the icon.
- Click: `MatchList:EnsureScan()` then `UI:Open()`, or `UI:Close()` when the window is up. Lit (checked) while the window is shown.
- Hover opens a Menu-Kit menu (`Kit.CreateMenu`, `publish = false`, `PlayItForwardMailboxTabMenu`), rows from `UI:MailboxTabMenuEntries`: header (Short Name on its right), spacer, Open Distribution Window, Reset Window Position, then `Kit.OptionsRow`.

### Giving Tally and Sharing

- `Generosity.lua`: `global.stats` (`gifts`, `items`, `itemLevels`, `value`). `ns.Generosity:RecordSend` is the only writer, via `Credit(job)` on normal and late delivery; skips alts. `Generosity:BlockLines` renders both the tooltip and the panel preview, with its own header (not `ns:BuildBrandedLine`, whose only caller is `ns:PrintMessage`).
- `Generosity-Broadcast.lua`: `C_ChatInfo.SendAddonMessage` on `YELL` (Classic has no custom channels and drops add-on whispers to strangers), so the feature is proximity-scoped. Prefix `ns.ADDON_MESSAGE_PREFIX`, registered at load under `pcall`. Payload is versioned and pipe-delimited:

```text
1|S|<gifts>|<items>|<itemLevels>|<value>    stats
1|?                                         ping
```

- Receiving: secret prefix, message or sender dropped first (`issecretvalue`); unknown version or prefix dropped; our own YELL echo ignored (sender key equals `ns.QualifyPlayerName(ns.PlayerName())`); a stats message needs exactly `STATS_FIELDS` parts of plain digits up to `PEER_TOTAL_MAX` (`ReadTotal`), else dropped. Peers cached by qualified name with a `GetTime()` stamp, good for `PEER_MAX_AGE`, swept on the next stats message (no timer).
- One `Send`, under `pcall`, result kept in `Generosity.lastSendResult` (a refused channel is a return value, not an error).
- **Share off** (`profile.shareStats`) stops only your own broadcasts: `Ping` ignores it, but pings are answered through `Broadcast`, so Share off sends no answer. You still see others' totals.
- **Town only**: every send and the tooltip block gated on `ns.AtRest()` (false without the API), checked before the throttles. Throttles: `BROADCAST_MIN_INTERVAL` (outgoing totals, ping answers), `HOVER_PING_INTERVAL` (`Generosity-Tooltip.lua`).
- **Tooltip block**: values white (`GetCoinTextureString` ignores a color prefix); labels `HELP`. Hook: `TooltipDataProcessor` unit post-call only where `GameTooltip.GetPrimaryTooltipData` exists, else `OnTooltipSetUnit` when `GameTooltip:HasScript` confirms, else none; `Generosity.tooltipHook` records which. `C_Secrets.ShouldUnitIdentityBeSecret` asked before any name read. First hover of an unknown player pings; the block appears next hover.

### Options Panel

- Built on Options-Kit (`Options/Options-Kit.lua`, read-only kit copy). `ns:OpenOptionsPanel` (in the kit, optional panel key) is the one entry point; `/pif` only calls it. Every panel registers as a builder function through `Kit.RegisterPanel(key, builder, name, parentKey)`, which stores the category ID it gets back; the kit opens a panel by that ID, never by name (Era lacks `C_SettingsUtil.OpenSettingsPanel`, TBC Anniversary has it, so a name lookup floats the panel on one).
- `ns:OptionsPanelRoute` (`Options.lua`) copies the kit's route decision for the root panel only, for its Diagnostics API row, using a local `rootCategoryID`. Two copies to keep in step.
- Registration deferred to `ns:RegisterOptionsPanels` at `ADDON_LOADED`, because the Profiles builder runs once at registration to read its localized name and needs `ns.db`. Order is tree order: the first call is the root (General); a parent registers before its children. Children: What to Give Away, Recipients (My Alts, My Guilds under it), Mail Message Text, Badge of Generosity, Profiles, Feedback & Support, Diagnostic Tools.
- **Refresh**: `Kit.Set` and `Kit.FeatureSwitch` end with `ns.RefreshSettings()` (redraws every `ns.OPTIONS_REGISTRY` panel). A hand-written setter must call it itself (the Disenchanter dropdown, spec ticks, My Alts/My Guilds `Changed()` do). A setter changing giftability or anything ranking reads also calls `ns.RefreshMailWindow()` (`Options-Utilities.lua`): `UI:SyncControls()` if the window exists, `UI:Rescan()` always (which marks the scan stale with no window, `MatchList:MarkStale`).
- `ns:ApplyProfile` is defined inside `OnAddonLoaded` (absent before it), and repeats `ns.RefreshMailWindow`'s two window calls after rebuilding weights, then `ns.RefreshSettings()`: change one, change both.
- **Feature switches** need an `ns.FEATURES` entry (`Options-Utilities.lua`); `Kit.FeatureSwitch` errors at build time without one. Gear and consumables pass `apply = GiftSwitch(...)` to rescan. Badge of Generosity uses `ns.OptionsProfileToggle` on `shareStats` instead.
- **Trees**: My Alts and My Guilds are tree groups; `Kit.PrepareTree(key, home)` seeds width and selection. The home function (current character's qualified name; `ns.Guild:CurrentKey()`) must return the same saved key the builder keys its nodes by. A tree group draws its non-group args once, full width, above the tree: that is where Send to Alts and My Guilds' offline limit and Add Guild sit.
- Widths come from Options-Kit (`Kit.*` constants, published as `ns.OPTIONS_*`); panel-local splits sit in their files. Recipients' spec row widths come from `SpecWidth()`: the row split by the most specs any class has here, at least three.
- **Resets** are `Kit.ResetRow`s with a confirm: the spec reset (grayed by `SpecsAtDefault`) wipes `profile.specs`; the mail reset clears both mail keys and is never grayed. Both kept by README-Notes.
- **Mail editor** (`ADDON_NAME .. "_MailEditor"`, `Options-Mail.lua`): saves every keystroke via `Distributor:SaveCustomText`, bypassing AceConfig's set (a set redraws the panel and steals the cursor). Counts are bytes against `MAIL_FIELDS`. Widget traps:
  - A FontString wraps only when its text is set, so `Wrap` re-sets the text (cleared first, since the same string doesn't rewrap) at each new width.
  - Inside `OnSizeChanged` an anchored FontString still reports the old width, so the width is set by hand.
  - `OnAcquire` uses `rowHeight`, not `self.height`: AceGUI's Release clears `height`, and `SetHeight(nil)` blanks the page on a second visit.
  - `Fit` keeps the preview at least as tall as the editor and re-lays the parents so the footer isn't cut; `OnRelease` clears `parent` so `Fit` never lays out a page no longer shown. Adopted child widgets are never released to AceGUI's pool.
- **Never Give Away list and Keep in Bags** (`Options-Give-Away.lua`): `profile.keepInBags[kind]` over `ns.Bags.KEEP_ORDER`; the list reads `ns.Bags:NeverGiveList`, item info warmed via `Kit.WarmItems`, and `GiveAgain` takes no confirm (one click on the row's dropdown puts it back).
- `UI:RarityPickerOptions` / `UI:GapPickerOptions` are frame-free for `Tests/Options-Values.lua`. The All Consumables stop is a gap of zero; compare `== nil`. Off-stop values snap for display via `ns.NearestConsumableGap`.
- The Badge preview (`PlayItForwardBadgePreview`) is a custom widget through `dialogControl`; its row `name` is `tostring(gifts)` so a gift forces a redraw. It stays shown while sharing is off (README-Notes).
- `ns.OptionsDesc` and `ns.OptionsSpacer` (`Options-Utilities.lua`) have no callers.

### Localization and Game Names

- `enUS.lua` is the only `NewLocale(..., true)` and registers under the literal `"Play-It-Forward"`, which must equal `ADDON_NAME` read in `Data/Data.lua`; `GetLocale` there is called without the silent flag, so a mismatch errors at load. Other locales belong to the Localization Review.
- Game names come from the client: zones and instances by AreaTable ID (`C_Map.GetAreaInfo`, `Who.AreaName`); classes by token (`LOCALIZED_CLASS_NAMES_MALE`/`_FEMALE`); races by ID; specs via `ns.SpecName`; qualities via `ITEM_QUALITY*_DESC` (`ns.QualityName` adds "and lower" above `MIN_RARITY`); Disenchant via `SPELL_IDS.DISENCHANT` and `C_Spell.GetSpellName`; mail refusals and non-stat tooltip prefixes via their globals.
- Exceptions (README-Notes): `SPEC_*` strings where the client cannot name a tree; English-only `EQUIP_PATTERNS` and `ENUS_FALLBACK`; English mail copy in every locale.
- `CLASS_QUALIFIED_SPECS` (`Utilities.lua`) disambiguates tree names two classes share (`SPEC_PALADIN_Protection`, `SPEC_DRUID_Restoration`); a new shared name needs an entry plus its locale keys.
- Zones are area records, not map records: `/who` matches the area name, and area and map names differ in some locales.
- Diagnostics strings are not localized (`ns.DiagnosticsStrings`), including the `WHO_LABEL_*` query labels `Recipients-Who-Plan.lua` reads at call time, since Diagnostics loads after it.

### Diagnostic Tools

- Framework copied from Magic Eraser, plus two additions kept by README-Notes: API rows print their second return, and a report row can take a typed `input`. Its panel registers through Options-Kit. `Validate-Data.lua` reads tables off `ns.Data`. `ns:FormatCommaNumber` (`Utilities.lua`) exists only for this framework.
- `Manifests.lua` holds this add-on's surface: `ns.DIAGNOSTIC_API_CHECKS` (including mailbox probes), the context reports (`ns:BuildMailboxReport`, `BuildBagScanReport`, `BuildRosterReport`, `BuildItemVerdictReport`, `BuildClassGroupsReport`, `BuildMailPreviewReport`, `BuildGenerosityReport`), `ns.DIAGNOSTIC_DATA_SOURCES` (one per flavor-folder file, `Game-IDs` validating `SPELL_IDS` as spells), `ns.DIAGNOSTIC_NAME_LOOKUPS` (built from the add-on's own data, so new stats, classes, specs and areas get rows unedited), `ns.DiagnosticsStrings.EVENT_LOG_EXAMPLES`.
- Reports call the live handlers' own tests (`MatchList:WouldRescan`, `UI:WantsMailboxTab`, `Distributor:IsMailError`, `ns:OptionsPanelRoute`) so a report cannot describe behavior the add-on does not have.
- Three API rows feed literal lines (plain, color-wrapped, equip-effect) to `Tooltip:StatsFromLines` as regression guards; another counts how many `ERR_MAIL*` strings `IsMailError` recognizes.
- **Event log filter** (`Diagnostics/Event-Log.lua`): `ns.DIAGNOSTIC_EVENT_EXCLUDE` is deliberately empty. Noisy events go through `ns.MESSAGE_ID_FILTERED_EVENTS` with a `correlated` predicate calling the handler's own test: `UI_ERROR_MESSAGE` (`IsMailError`), `CHAT_MSG_ADDON` (our prefix), `BAG_UPDATE` (`WouldRescan`), `GET_ITEM_INFO_RECEIVED` (`WouldRescanItem`). Filtered at capture, counted per event and id. Secret values (WoW Forever) are never compared or stringified: they log as `<secret>` and count under `SECRET_ID`; a predicate runs under `pcall` because the log runs ahead of the real handlers. `Tests/Event-Log-Noise.lua` pins it.

## Files That Change Together

- **New registered event**: `ns.On` in its feature file, behind a flavor gate if the client may lack it (registering an unknown event throws); if noisy, a `ns.MESSAGE_ID_FILTERED_EVENTS` entry in `Diagnostics/Event-Log.lua` whose predicate calls the handler's own exposed test.
- **New giftable consumable row**: the row in `Scan-Food`/`Scan-Potions`/`Scan-Scrolls`/`Scan-Oils-Stones` in every flavor folder whose client has it, with a nonzero use level (0 rejects as `NO_USE_LEVEL`); its `restores`/`buffs`/`enhances` value must exist in that folder's `CONSUMABLE_CLASSES`; a case in the matching `Tests/*-Rules.lua`.
- **New consumable table or kind**: the file in all seven flavor folders and each TOC; `ns.CONSUMABLE_KIND_ORDER` and `ns.CONSUMABLE_KIND_STRINGS` (`Data/Data.lua`); its `consumableKinds` and `keepInBags` defaults; `CONSUMABLE_TABLES` (and `FOOD_KINDS` if food-like) in `Scan-Bags.lua`; its locale keys; a `DIAGNOSTIC_DATA_SOURCES` entry in `Manifests.lua`.
- **New stat**: `STAT_MAP` (every key spelling any client returns), `Match-Specs` weights and `Match-Stat-Budget` cost in every folder; `ENUS_FALLBACK` or `EQUIP_PATTERNS` if it has no `ITEM_MOD_` global; `Tests/Stat-Scoring.lua`, `Tests/Tooltip-Parsing.lua`; rewrite `Tests/Outcomes/` via `Tests/Write-Outcomes.lua` once intended.
- **New or reordered spec row**: `Match-Specs` order must match the client's tab and specialization order (`DetectSpec`); a tree name another class shares needs a `CLASS_QUALIFIED_SPECS` entry and its `SPEC_*` locale keys.
- **New item rule**: `ITEM_RULES` in every folder's `Match-Rules`, placed deliberately if `prefer`; a case in `Tests/Item-Rules.lua` (or the weapon/consumable/scroll/oil rule tests).
- **New setting**: its `ns.DATABASE_DEFAULTS.profile` key; its row in the feature panel builder (never General); `enUS.lua` strings and every locale; `ns.RefreshMailWindow()` in its setter if it touches giftability or ranking, and `ns.RefreshSettings()` if the setter is hand-written; its top-bar twin and `UI:SyncControls` if the bar shows that section.
- **New feature switch**: an `ns.FEATURES` entry (`Options-Utilities.lua`) plus the setting's steps above.
- **New options panel**: an `ns.OPTIONS_REGISTRY` entry in `Data/Data.lua`, a `Kit.RegisterPanel` call in `ns:RegisterOptionsPanels` (after its parent), its TOC line before `Options/Options.lua`.
- **New game record named by ID**: a constant in every folder's `Game-IDs` file; a `DIAGNOSTIC_NAME_LOOKUPS` row.
- **New flavor-folder file**: all seven folders, the four TOCs (Vanilla lists both Vanilla and Discovery), the Discovery guard, and a `DIAGNOSTIC_DATA_SOURCES` entry.
- **New Features file**: the four TOCs at a position after everything it captures at file scope.
- **Ranking sort keys**: `Matcher:RankCandidates`, `Matcher:CouldOutrank` (copies the keys) and `AnchorFor` (copies the anchor) in `Match-Ranking.lua`.
- **Placement switches**: `SEARCH_ON_RANK` (`Recipients-Zones.lua`) is read against `Who:PlacementRank`'s numbers.
- **Window placement**: `UI:BuildFrame`, `PlaceAtFirst`, `UI:Open`.
- **Profile apply**: `ns:ApplyProfile` (`Core.lua`) and `ns.RefreshMailWindow` (`Options-Utilities.lua`).
- **Saved-variables name**: the TOCs' `SavedVariables`, the `AceDB:New` literal in `Core.lua`, and `ns.SAVED_VARIABLES_NAME`.
- **Custom mail subject**: changing `BuildSubject` changes which returned gifts `IsGiftSubject` recognizes.

## Saved Variables

- `PlayItForwardDB`: the one table, created in the name-guarded `ADDON_LOADED` handler (`Core.lua`), with `PruneOtherClientCharacters` on the next line.
- `profile`: every setting, the Never Give Away list (`neverGive`), Keep in Bags amounts, the custom mail copy, and the window's `windowPos`/`windowSize`. `global.characters`: every character that has logged in, plus the player's choices on each. `global.guilds`: saved rosters and guilds added by name. `global.stats`: the giving tally. Shapes in `ns.DATABASE_DEFAULTS`.
- **Model: Simple** (third argument `true`, one shared `"Default"` profile). Nothing is stored per character as a profile. **Reset Profile restores every setting, spec choices and the Never Give Away list included, and leaves `global` untouched**: characters, guilds, the choices made on them, and the tally. A new setting goes in `profile`.
- The disenchanter lives on its `characters` entry rather than in `profile`: the shared profile also serves characters that cannot mail it.
- The mail keys are `mailSubject`/`mailBody`, not an earlier editor's `subject`/`message`, so values left under those stay unread.
- `consumableLevelGap` of 0 is the All Consumables sentinel. A new kind in `ns.CONSUMABLE_KIND_ORDER` reaches existing profiles through AceDB's nested `consumableKinds` and `keepInBags` defaults.
- No default item or spell lists, so no seeding. `characters` and `guilds` fill from the game; an alt's default `include` is computed, not stored. Fairness history is session-only.
- Not settings, on purpose: `ns.Data.MIN_RARITY`, every matching constant, the `MAIL_POWERED_BY` footer.

### Migration Chain

- First names to full names (`Recipients-Alts.lua`, `Adopt` and `UpgradeFirstNames`): a WoW Forever character recorded under its first name alone is moved onto its `"First Last"` key, choices carried over. `MIGRATION (remove after 2026-12-05)`, with its tests in `Tests/Alts.lua`.

## Pitfalls & Why

- **Calling `SendWho` outside a click**: blocked with no error and no event. Every query rides a button press; `ADDON_ACTION_BLOCKED` is caught only to explain one.
- **Letting a dropdown close before its pick runs**: on WoW Forever, hiding the list first left Rescan for Better Match's `SendWho` blocked. `Picker:Entries` sets `keepOpen = true` and runs `onSelect` before `Picker:Close`.
- **`UseContainerItem` with the Send Mail panel closed**: uses the item. Check the panel first.
- **Setting the subject before the attach, or leaving the last one in the box**: the client writes the item name only into an empty subject, and a stale subject would carry onto an alt's letter. Empty it before the attach; fill the panel after.
- **Giving mail to your own alts a body**: the letter stays in the mailbox after the item is taken. Alt jobs carry no subject or body.
- **Finding the mail body box by flavor**: Era has no `SendMailBodyEditBox`. Pick the box that exists.
- **Re-reading a bag slot on `MAIL_SUCCESS`**: still holds the old link. Trust the event; capture `_count` before the send.
- **Dropping a job when the mail result timer fires**: `SendMail` already went out; the job moves to `_awaiting`.
- **Starting a run over an awaited send**: its late result would credit the new run's first job. `Start` refuses for one more `RESULT_TIMEOUT`.
- **Ignoring a late result on a stopped run**: the row stays ticked and the next run skips it as moved. `Distributor:Result` credits it and removes it from the queue.
- **Old settle timers**: `FAILURE_SETTLE` outlives its run; checked against `Distributor._run`.
- **Treating every failure as a refusal**: only a job with `_sent` set marks the name unreachable and drops that recipient's other jobs; attach errors and bare `MAIL_FAILED` say nothing about who.
- **Dropping `ERR_PLAYER_WRONG_FACTION` from `OTHER_MAIL_ERRORS`**: a cross-faction send then waits out the full result timeout.
- **Aborting with the item still on the panel**: one Send would re-mail it. Abort calls `ClearSendMail` first.
- **Closing the window from `MailFrame`'s `OnHide`, or gating on `MailFrame:IsShown()`**: mail-replacement add-ons and the Who panel hide it at a mailbox. Use `ns.AtMailbox()`.
- **Parenting a frame to `MailFrame`**: protected for good, and writing to the panel taints it. Parent to `UIParent`, anchor beside it.
- **Skinning the mailbox tab**: ElvUI's `StripTextures` would take the icon. It is left unskinned.
- **Calling anything but `IsForbidden()` first on an unknown `UIParent` child**: a forbidden frame errors. `FindTSMFrame` asks it first.
- **Setting the window's `OnHide` before `BuildFrame` hides it**: it fires before `UI.frame` exists.
- **Dropping an in-flight `/who` instead of cancelling it**: `EndQuery` restores Blizzard's frames and `SetWhoToUi`; skip it and the player's own `/who` is silent for the session.
- **Re-planning a search mid-flight**: `Who:Plan` restarts from the first attempt. `Who:Prune` only removes.
- **Two class filters in one `/who`**: the client keeps the first.
- **Naming instances from uiMaps**: Era and Forever ship no dungeon maps. Use `INSTANCE_AREAS` through `C_Map.GetAreaInfo`.
- **Trusting `GetItemStats` on a random-suffix green**: returns nothing for the suffix. The tooltip is the only source.
- **Dropping `CleanLine`**: text handed straight to `StatsFromLines` (Diagnostics probe, tests) arrives color-wrapped and fails the `+N` anchor. `CleanLine` strips only `|cffXXXXXX` and `|r`, not the named `|cn…:` escapes `ns.PlainText` handles.
- **Reading Use:, proc or set-bonus lines as stats**: "Use: Increases attack power" is not attack power. `IsNonStatLine` skips them by the client's own prefixes.
- **Caching a reputation check off an unrendered tooltip**: a loading item would pass as needing no standing. `IsReputationLocked` caches only after a render.
- **Counting tooltip lines as a successful read**: a `C_TooltipInfo` answer can carry no text.
- **`classID == 2` to mean weapon-matrix**: shields, held off-hands and relics rank there too. Use `ns.Data.UsesWeaponMatrix(item)`; read a weapon key only after checking `classID` (cloth subclass 1 collides with two-hand axe).
- **`INVTYPE_HOLDABLE` in `UNIVERSAL_EQUIP_LOC`**: makes an Intellect orb eligible for warriors. Held off-hands route as `HELD`.
- **Reading `ns.db.profileKeys`**: always nil; it lives on `ns.db.sv`.
- **Comparing player names raw**: one character can arrive bare and suffixed. Compare `ns.QualifyPlayerName`; mail the name the client gave.
- **Using `UnitName("player")` as this character's address**: on WoW Forever it answers the first name alone. Use `ns.PlayerName()`.
- **Treating an alt holder as a fallback**: alts are admitted by their own specs. `HolderInContention` and `CouldOutrank` count `person.alt` as a contender, or the search keeps hunting to replace your alt.
- **Reading `STAT_WEIGHTS` during `Matcher:VerdictForSpecs`**: it holds the alt's specs until the call restores them.
- **Changing My Guilds without `RecheckGuildmates`**: guild state is read only at pool entry, so an unticked guildmate stays pooled until a reload.
- **Deleting a guild a character of yours is in**: it is saved again at that character's next login. `Guild:Remove` flags it `removed`.
- **Mists specs through the global `GetSpecialization` or talent tabs**: missing or throwing. Ask `C_SpecializationInfo` on clients that pick a specialization.
- **Reordering `Match-Specs` rows**: `DetectSpec` reads them by the client's tab or specialization index.
- **A second recipient level floor**: there is one, in `AddResults` (alts exempt); a copy drifts.
- **A ranking-relevant setting without `ns.RefreshMailWindow`**: the candidate cache is stamped against the pool only.
- **A hand-written options setter without `ns.RefreshSettings()`**: other panels and the window's mirror go stale.
- **Mutating `MatchList:Candidates`'s list, or caching `MatchList:Items()`**: the first is shared by reference; `RescanBags` reassigns the second.
- **Re-reading bags at the end of a run**: sent slots are not empty yet, so the scan restores delivered pairings. `UI:AfterDelivery` re-assigns without scanning.
- **Random tiebreak in a sort comparator**: `table.sort` throws. Shuffle is rolled at pool entry.
- **Changing the ranking sort alone**: `CouldOutrank` and `AnchorFor` copy it.
- **Reordering `ITEM_RULES`**: `prefer` is first-match-wins; `veto` and `demote` make the table look more reorderable than it is.
- **Adding a stat weight and expecting only scores to move**: it changes coverage on every item with that stat.
- **Mapping one spelling of a stat key**: TBC Anniversary returns long spell damage and healing keys. Map every spelling.
- **A class added to `FACTION_CLASSES` alone**: `EVERY_CLASS` in `Match-Engine.lua` stops at the monk.
- **Misspelling a consumable's `restores`/`buffs`/`enhances`**: missing from `CONSUMABLE_CLASSES` means every class, failing open.
- **A consumable rule on `form` alone, or on `OIL_STONE`**: needs `form` plus `restores`; never matches.
- **A consumable whose band ends below `MIN_RECIPIENT_LEVEL`**: matches nobody and keeps the search plan alive for it. Use level 0 is rejected at scan (`NO_USE_LEVEL`); a very low nonzero one is not.
- **Treating `consumableLevelGap` 0 as a gap**: it is the All Consumables sentinel.
- **Reordering `ALT_LEVELS_*_ORDER`**: defaults are positional, so every alt that never picked moves.
- **Expecting Keep in Bags to split a stack**: mail takes a stack whole; a keep holds back whole stacks.
- **Changing the custom mail subject**: gifts already sent under the old one are no longer recognized when returned.
- **Believing a peer's totals as sent**: anyone in yelling range can send them. `ReadTotal` accepts plain digits up to `PEER_TOTAL_MAX` only.
- **Answering our own YELL ping**: it echoes back and spends `BROADCAST_MIN_INTERVAL` on nobody.
- **Hooking a tooltip because `TooltipDataProcessor` exists**: Classic clients never run its post-calls, and `HookScript` on a missing script type throws (Forever dropped `OnTooltipSetUnit`).
- **Coloring Generosity values**: the money row ignores the prefix; everything stays white.
- **Stringifying an event argument on WoW Forever**: a secret value errors when compared, concatenated or used as a key. The log goes through `IsPlain`; add-on messages drop secrets first.
- **Opening an options panel by category name**: works on Era, floats the panel on TBC Anniversary. Use the ID `Kit.RegisterPanel` stored.
- **A feature switch without an `ns.FEATURES` entry**: `Kit.FeatureSwitch` errors when the panel builds.
- **A tree home key that differs from the node keys**: the tree opens on nothing. Both use the saved key.
- **Reading `self.height` in the mail editor's `OnAcquire`**: AceGUI's Release cleared it; the page goes blank on the second visit.
- **Pairing two `description` widgets without a spacer**: rows interleave.
- **Removing a key from `ns.DATABASE_DEFAULTS` and expecting it gone**: AceDB's cleanup only visits keys still in the defaults. Nil it in a tagged migration.
- **Writing the packager's version token anywhere, comments included**: the packager replaces it, and `GetVersion` (`Core.lua`) detects a dev copy by it.
- **Moving a file earlier in the TOC**: `Match-Derivations.lua` reads data at load, and the UI files capture what Menu-Kit and earlier UI files created.
