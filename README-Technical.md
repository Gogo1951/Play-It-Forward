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
├── .luacheckrc                       Lint config
├── .pkgmeta                          Externals and ignore list; strips Data/Wrath, Data/Mainline and Tests
├── Play-It-Forward_Camelot.toc       WoW Forever
├── Play-It-Forward_Mists.toc         Mists of Pandaria Classic
├── Play-It-Forward_TBC.toc           TBC Anniversary
├── Play-It-Forward_Vanilla.toc       Classic Era and Season of Discovery: lists Data/Vanilla then Data/Discovery
├── Data/
│   ├── Flavor.lua                    Canonical: ns.FLAVOR, ns.EXPANSION, ns.IS_DISCOVERY, ns.DATA_FOLDER
│   ├── Data.lua                      Locale init, ns.Data, palette, links, options widths, ns.OPTIONS_REGISTRY, matching constants
│   ├── Default-Settings.lua          The AceDB-3.0 defaults, ns.DATABASE_DEFAULTS
│   ├── Vanilla/                      Classic Era; every file opens with the Discovery guard
│   ├── Discovery/                    Season of Discovery; inverse guard
│   ├── TBC/                          TBC Anniversary
│   ├── Camelot/                      WoW Forever
│   ├── Mists/                        Mists of Pandaria Classic
│   ├── Wrath/                        No TOC lists it; stripped by .pkgmeta
│   └── Mainline/                     No TOC lists it; stripped by .pkgmeta
├── Diagnostics/                      Copied framework; Manifests.lua is this add-on's surface (API rows, probes, data sources, name lookups)
├── Features/
│   ├── Core.lua                      Identity, AceDB lifecycle, other-client prune, ns:ApplyProfile, welcome, the ns.On dispatcher
│   ├── Utilities.lua                 Tooltip reads (ns.ReadTooltip), colors, names and realms (ns.PlayerName, ns.QualifyPlayerName), ns.AtMailbox, ns.DisenchantName
│   ├── Announcements.lua             Player-only output: ns:BuildBrandedLine, ns:PrintMessage
│   ├── Scan-Tooltip.lua              Tooltip lines to stats and the reputation requirement; pure parsers
│   ├── Scan-Bags.lua                 Bag slot to item record, or nil plus a reject code
│   ├── Match-Derivations.lua         Stat weights from SPECS; priority groups, weapon keys, rule matching
│   ├── Match-Engine.lua              The matcher (ns.Matcher): eligibility, claim, fit, coverage, rules, the verdict
│   ├── Match-Ranking.lua             Candidate ranking, level bands, band groups, targeted search order
│   ├── Match-List.lua                The match list (ns.MatchList): items, pairings, debounced rescan, the allocator
│   ├── Match-Roster.lua              The recipient pool: AddResults, the dedupe, the candidate cache, RecheckGuildmates
│   ├── Match-Search.lua              Band merging, which gifts still search, targeted narrowing
│   ├── Recipients-Who-Plan.lua       Builds, prunes and exhausts the /who plan
│   ├── Recipients-Zones.lua          Zone order (ns.Data.ZonesFor), area names, candidate placement
│   ├── Recipients-Who.lua            Sends one /who per press: throttle, Who panel deafening, parsing
│   ├── Recipients-Guild.lua          Guild recipients (ns.Guild): live and saved rosters, guilds added by name, the /who guild lookup
│   ├── Recipients-Alts.lua           Alt recipients (ns.Alts): your own characters as recipients, the disenchanter
│   ├── Recipients-Fairness.lua       Session cooldown and the unreachable list
│   ├── Mail-Sender.lua               The mailer (ns.Distributor): one SendMail at a time, event-driven
│   ├── Mail-Copy.lua                 Subject, body and footer, stock or custom, cleaned and cut
│   ├── UI-Picker.lua                 The shared scrolling dropdown, ns.Picker scrolling dropdown list
│   ├── UI-Window.lua                 The mail window frame and ns.UI: rows, sections, geometry, UI.BuildDropdown
│   ├── UI-Top-Bar.lua                The window's giftability ticks and dropdowns, UI:SyncControls
│   ├── UI-Status.lua                 Distribute button state, status line, UI:CanTick
│   ├── UI-Assignment.lua             A row's dropdown: header, candidates, manual picks, row ticks
│   ├── UI-Mailbox.lua                Mailbox open and close, Find Recipients, Distribute, the roster pulls
│   ├── UI-Reopen-Button.lua          The button beside MailFrame that brings the window back, and its hover menu
│   ├── Generosity.lua                Account-wide giving tally in global.stats
│   ├── Generosity-Broadcast.lua      Shares the tally with nearby players over YELL add-on messages
│   └── Generosity-Tooltip.lua        A peer's totals at the foot of their unit tooltip
├── Includes/
│   ├── Images/
│   │   ├── Gift.tga                  The mail window's portrait
│   │   ├── Menu-Plate.tga            The reopen menu's angled plate
│   │   └── Play-It-Forward.tga       Icon
│   └── Libraries/                    Vendored Ace3 down to AceDBOptions-3.0, nothing else
├── Locales/
│   └── enUS.lua                      Source of truth
├── Options/
│   ├── Options-Utilities.lua         Shared ns.Options* constructors and ns.RefreshMailWindow
│   ├── Options-General.lua           Root panel: welcome and the three feature switches
│   ├── Options-Give-Away.lua         What to Give Away: gear, consumables and their kinds, disenchanting
│   ├── Options-Recipients.lua        Recipients: priority, stranger rules, Classes & Specs
│   ├── Options-Alts.lua              My Alts: tree of characters, each one's tick, gear levels and specs
│   ├── Options-Guilds.lua            My Guilds: Add Guild box, tree of guilds, each one's tick, remove and member ignores
│   ├── Options-Mail.lua              Mail Message Text: the editor widget and live preview
│   ├── Options-Generosity.lua        Badge of Generosity: the Share switch and a badge preview
│   ├── Options-Profiles.lua          Stock AceDBOptions-3.0 table
│   ├── Options-Feedback-Support.lua  Level Up note, links, version line
│   └── Options.lua                   Registration, ns:OpenOptionsPanel, /pif
├── Tests/                            Offline suite, runs on Lua 5.1; never ships
│   └── Outcomes/                     Saved who-gets-what tables, one per flavor folder
├── LICENSE                           MIT
├── README.md                         Player documentation
├── README-Notes.md                   Exceptions to the Style Guide
├── README-Technical.md               This document
└── README-Testing.md                 Manual test plan
```

- **No mini-map button**: `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are deliberately absent.
- **Diagnostics panel** lives in `Diagnostics/Options-Diagnostics.lua`; never `Features/Diagnostics.lua` or `Options/Options-Diagnostics.lua`.
- **Nothing but `Flavor.lua`, `Data.lua` and `Default-Settings.lua` sits directly in `Data/`.** The old shared `Data/Match-*.lua`, `Recipients-Zones.lua`, `Scan-*.lua` files are replaced by per-flavor copies; game data and matching policy never return to a file every client loads.
- **The UI split is load-bearing TOC order**: `UI-Picker`, `UI-Window`, `UI-Top-Bar`, `UI-Status`, `UI-Assignment`, `UI-Mailbox`, `UI-Reopen-Button`. Each captures at file scope what an earlier one created (`ns.UI`, `ns.Picker`, `UI.BuildDropdown`, `UI.TICK_SIZE`).
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
- `Tests/`: `lua5.1 Tests/Run.lua` requires every case file and exits non-zero on failure. `Tests/Outcomes.lua` builds a who-gets-what table per flavor folder and diffs it against `Tests/Outcomes/`; `Tests/Write-Outcomes.lua` rewrites those files once a change in outcomes is intended. `Tests/Stub-WoW-API.lua` and `Tests/Harness.lua` are the fake client.

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
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `UI-Mailbox.lua` | Same signal, filtered to `MailInfo`; gated `ns.EXPANSION >= 2 or ns.FLAVOR == "Camelot"` (never on Era) |
| `BAG_UPDATE`, `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Mark the scan stale (Caching) |
| `WHO_LIST_UPDATE` | `Recipients-Who.lua` | Parse under `pcall`, end the query, prune, hand on |
| `ADDON_ACTION_BLOCKED` | `Recipients-Who.lua` | Our own blocked `SendWho` only: counted, explained with `L["WHO_BLOCKED"]` |
| `CHARACTER_POINTS_CHANGED`, `PLAYER_LEVEL_UP` | `Recipients-Alts.lua` | Re-record; level up uses the event's level, since `UnitLevel` lags |
| `PLAYER_SPECIALIZATION_CHANGED` | `Recipients-Alts.lua` | Re-record; gated `ns.EXPANSION >= 5` |
| `MAIL_SUCCESS` / `MAIL_FAILED` / `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | Advance the send queue; catch refusals with neither result event |
| `GUILD_ROSTER_UPDATE` | `Recipients-Guild.lua` | Login save, or a requested roster; otherwise ignored |
| `CHAT_MSG_ADDON` | `Generosity-Broadcast.lua` | A peer's tally or a ping; own prefix only |
| `PLAYER_ENTERING_WORLD`, `PLAYER_UPDATE_RESTING` | `Generosity-Broadcast.lua` | Broadcast presence; the throttle absorbs refires, and resting catches entering town without a loading screen |

- Two deliberate registrations outside `ns.On`: the Event Registration report's throwaway probe frame (`Diagnostics/Code-Reports.lua`), and the Who panel deafening (`Recipients-Who.lua`).

### Combat Lockdown

- Only `ns:OpenOptionsPanel` refuses in combat (Style Guide → Combat Guard), in `Options/Options.lua`.
- Nothing defers for combat: mail runs only at a mailbox, `/who` only from a click in the mail window, and the Generosity broadcast is gated on `ns.AtRest()` rather than combat state.

### Main Pipeline: Scan, Match, Search, Send

1. **Scan** (`Scan-Bags.lua`): bags 0 to `NUM_BAGS`, no reagent bag. `Scanner:Classify` returns a record or `nil` plus a `Scanner.REJECT` code. Codes are diagnostic identifiers for the Bag Scan report, never shown to players. Record `uid` is `"bag:slot:link"`.
   - Order matters: `CONSUMABLE_NOT_LISTED` before the gear toggle (or a bandage with gear off reads `GEAR_DISABLED`); gear needs a positive `classID` check because recipes carry an equip slot.
   - `REPUTATION_LOCKED` is checked last on consumables, as the one test that reads a tooltip (`Tooltip:RequiredReputation`, matched through the client's `ITEM_REQ_REPUTATION` format). Cached per item ID, but only once a tooltip actually rendered.
2. **Match** (`Match-Engine.lua`): one `verdict` per item — `eligible`, `admitted`, `contenders`, per-class `claims`, `fits`, `coverage`, `best`, and a state (`gift`, `leftover`, `unreadable`). `Match-Derivations.lua` answers the table questions, `Match-Ranking.lua` turns a verdict into bands and ranked candidates. Downstream reads the cached `item.verdict`.
3. **Search**: three sources fill one pool through `MatchList:AddResults` (`Match-Roster.lua`). `PullAlts` and `PullGuild` (`UI-Mailbox.lua`) need no press; `/who` sends one query per press.
4. **Send** (`Mail-Sender.lua`): `ns.Distributor` walks a job queue, one `SendMail` at a time, waiting on a result event.

- State lives at file scope: `Match-List.lua` holds `items` and `assignedTo` and runs the allocator; `Match-Roster.lua` holds `pools` and `poolsGeneration`. Items, roster and hand picks survive walking away.
- `UI:Rescan` (`UI-Mailbox.lua`) re-plans the search from fresh bands before assigning, so a settings change searches for what is listed now; found players are kept.

### Caching

- **Cold item cache**: `C_Item.GetItemInfo` nil rejects the slot as `NOT_CACHED`, never treats it as empty. `GET_ITEM_INFO_RECEIVED` counts only for an item the last scan rejected that way (`Scanner:IsPending`) and resolved with `success ~= false`. Without it a cold cache reads as an empty bag and the window declines to open.
- **Debounced rescan** (`Match-List.lua`): neither event scans. `ScanSoon` sets `bagsDirty` and arms `SCAN_DEBOUNCE` only when `WouldRescan()` holds: database exists, no distribution run busy, and the window is shown or a mailbox waits on it (`UI:WaitingToOpen`). The timer re-asks `WouldRescan()`.
  - Window shown: `EnsureScan` plus `UI:Assign()`, against the pool already found, plan left alone (re-planning would throw away a Rescan for Better Match mid-run).
  - Otherwise `UI:OpenIfWaiting`: a mailbox that opened on nothing arms `waitingToOpen` (that answer is often the cold cache's), and the first rescan that finds a gift opens the window there. Checked against `ns.AtMailbox()` too, since `MAIL_CLOSED` skips Escape on Era.
  - Away from a mailbox `bagsDirty` stays set; the next `MailboxOpened` pays for one scan.
  - Excluded during a run: Distributor slots stay full until each send is confirmed, and the deliveries' own `BAG_UPDATE` brings the scan back.
- **A mailbox visit is handled once**: `visitHandled` makes every report after the first free (`MAIL_SHOW`, `OnShow`, interaction manager, the Distributor's own `MailFrame:Show`). Skipped while `Distributor.busy`, cleared once the mailbox is gone.
- **Stats read twice, merged by max per stat, never summed** (`NormalizedStats`): `GetItemStats` resolves the base item and misses random suffixes; the tooltip renders the item as seen. Both report fixed stats, so a sum doubles them. `record.statRead` keeps each source's answer for Item Verdict.
- **Tooltip read** (`ns.ReadTooltip`, `Utilities.lua`): `C_TooltipInfo.GetHyperlink` first, hidden `PlayItForwardScanTooltip` otherwise. A `C_TooltipInfo` read counts only with real text (without `SurfaceArgs` every `leftText` is nil).
- **Tooltip parsing** (`Scan-Tooltip.lua`, `Tooltip:StatsFromLines`, pure so the API report and tests can feed literal lines). Each line: `CleanLine`, skip non-stat lines (Use:, Chance on hit:, set bonuses, built from `ITEM_SPELL_TRIGGER_ONUSE`, `ITEM_SPELL_TRIGGER_ONPROC`, `ITEM_SET_BONUS`, plus the `(N)` inactive set shape), then readers in order:
  1. `+N Name` against every lowercased `STAT_MAP` global plus `ENUS_FALLBACK`.
  2. `SplitStats` for two-stat lines (TBC "+42 Healing Spells and +14 Damage Spells"), splitting at each `+N` and retrying a half with its last word dropped, so a translated "and" goes too.
  3. `ReadFormatted`, patterns from each long `ITEM_MOD_*` format behind a `_SHORT` `STAT_MAP` key, for locales that write the name first (koKR).
  4. `EQUIP_PATTERNS`, English clients only.
  - A signed-number line no reader resolves goes back as unread for Item Verdict; only that shape, or prose would bury it.
- **Candidate cache** (`MatchList:Candidates`, `Match-Roster.lua`): ranked list cached on the item as `_candidates`, stamped `_candidatesGeneration` against `poolsGeneration`.
  - Generation bumps in `AddResults` when a pool entry changed (new player, newly `guild` or `alt`, higher level, different area) and in `RecheckGuildmates` when it drops someone. `RescanBags` needs none: it replaces every item table.
  - Ranking never reads `item.recipient`. Settings it reads (`sendToAlts`, alt choices, specs) bump nothing; their setters call `ns.RefreshMailWindow`, which rescans.
  - Handed out by reference. Derived per-item fields carry a leading underscore (`_weaponKey`, `_candidates`).

### Scoring: Claim, Fit and Coverage

- **Weights**: the recipient's spec is unknowable, so specs are assumed. `ns.Data.SPECS[class]` lists each spec's `key`, `role`, `main` stats (2) and `useful` stats (1); `off = true` ships a spec disabled. `profile.specs[class][key]` stores only differences from the default.
- `ns.Data.RebuildStatWeights` sums enabled specs into `ns.Data.STAT_WEIGHTS` on a three-spec scale: `main` averaged over enabled specs times three (a Holy-only paladin is as committed to Intellect as a mage); `useful` summed, scaled by `min(1, 3 / #specs)` over every spec the class has. A class with every spec off gets no weights and no gear. Also records `ns.Data.MAIN_STATS`. Rebuilt at load, after AceDB, on spec change and profile change; cached verdicts are not, so a spec setter rescans.
- **Budget first**: `ns.Data.StatPoints` multiplies a tooltip number by `STAT_BUDGET` (1 when unlisted) before weighting, so Classic's "+1% crit" can compete with "+10 Strength".
- **Claim** (`Matcher:SpecScore`): weighted stats only; decides *admitted*. **Fit** (`Matcher:Score`): claim plus `WEAPON_BASELINE` × item level on weapon-matrix items, keeping statless weapons placeable; decides *ranking*. **Coverage** (`Matcher:Coverage`): share of the item's scoreable stats the class weights at all; decides *breadth*.
- Coverage exists because sums let one large weight beat breadth ("of the Gorilla": warrior 24 + 0 vs paladin 16 + 8). Contention needs both `CLASS_SHARE` of the best claim and strictly more than `COVERAGE_MAJORITY`. Failing either leaves the class admitted: in the dropdown, a fallback.
- Coverage denominator is every stat some class weights with current specs, so adding a weight or toggling a spec reshuffles contention on every item carrying that stat.
- **Coverage abstains** when it demotes everyone: `Verdict` falls back to everyone who cleared `CLASS_SHARE`. Nothing scoreable returns coverage 1 (placed by the baseline).
- **Primary stat names the class**: an item with Strength, Agility or Intellect leads only with contenders building on one (`MAIN_STATS`), else admitted classes gearing for one, else nobody. Stops a mage leading a Mists Agility cloak on crit.
- **Body armor leads with natural wearers**: only the lowest priority group of contenders stays. Not for cloaks, rings, weapons, shields, held off-hands.
- **Stamina is everybody's**: left out of the coverage denominator and not a judged stat; a Stamina-only weapon takes the everyone-fallback unless some eligible class weights Stamina.
- **Faction filters classes**: `AllClasses()` keeps classes `FACTION_CLASSES` lets the player's faction roll; union until `UnitFactionGroup` answers, then memoized. Source list `EVERY_CLASS` stops at the monk.
- **Consumables skip scoring**: claim and fit 1 for every eligible class; eligibility from `restores`/`buffs`/`enhances` through `CONSUMABLE_CLASSES`; the band does the rest.
- `best` comes from contenders, ties to the lower priority group.

### Verdict States

- `gift` / `leftover` split at `ns.Data.LEFTOVER_THRESHOLD`. No eligible or no admitted class is always leftover; so is statless non-weapon-matrix armor.
- `unreadable`: at least one class eligible, carries a suffix id, nothing parsed. Exists because a failed suffix parse looks exactly like a worthless item, and telling a player to vendor it cannot be undone. Held out of auto-assignment, disenchanting and Rescan for Better Match.

### Item Rules

- `ns.Data.ITEM_RULES` (each folder's `Match-Rules`), matched in `Match-Derivations.lua`: pair-of-stats meaning the weights cannot express. One matcher per rule: `weapon` key list, consumable `form` plus `restores` (both required), or `requires` (optional `exclusive`, `without`, `armor` material). `Matches` tests `unclaimed`, then weapon, consumable, stats.
- Verbs:
  - `veto` / `vetoUnlessRole`: removes the class before scoring; the only absolute verb. Skipped for consumables. `vetoUnlessRole` reads `ns.Data.ClassHasRole` live.
  - `prefer`: names the contenders after scoring, narrowed to admitted. **First match wins**, even when it names nobody admitted (then it blocks every `prefer` below).
  - `demote`: drops from contention, keeps admitted; after `prefer`, accumulates.
- `unclaimed = true` is a condition: applies only when no eligible class had a stat claim. Pairs with `prefer`/`demote`, never `veto`.
- `ApplyDemotion` falls back contenders → scoring's answer → admitted, never straight to admitted (that would promote what coverage demoted).
- `exclusive` counts weighted stats only (armor and resistances would make a bare Stamina ring qualify where a chest did not).
- Blind spots: no rule can key on `buffs` or `enhances`; `weapon` rules need `classID == 2`; `armor` rules exclude `UNIVERSAL_EQUIP_LOC`.

### Recipient Ranking

- `Matcher:RankCandidates` (`Match-Ranking.lua`) ranks pooled players of the **admitted** classes, each against its own class's band, plus any class an alt in the pool plays. Keys: `fit bucket -> source -> placement -> level proximity -> armor/weapon group -> class fit -> shuffle -> name`.
- **Source** (`Matcher:SourceRank`): alt, then guildmate, then stranger, each step only while `profile.prioritizeAlts` / `prioritizeGuilds` is on. `Matcher:Source` is the raw value the picker files sections under.
- **Placement** (`Who:Placement`, `Recipients-Zones.lua`): `PLACED_LEVELING` (a `ZONES` zone fitting their level within `ZONE_LEVEL_SLACK`), `PLACED_UNKNOWN`, `PLACED_ELSEWHERE`, `PLACED_INSTANCE`. `Who:PlacementRank` applies `prioritizeLevelingZones` and `prioritizeOutsideInstances`; a switch off drops its key. All prioritize switches read as `~= false`.
- **Instances are area records**: `Who.InstanceNames` names `INSTANCE_AREAS` AreaTable IDs through `C_Map.GetAreaInfo`, the record `/who` names a zone by. Classic Era and Forever ship no dungeon maps.
- `profile.ignoreSummonerWarlocks` skips stranger warlocks in `SUMMONER_MIN_LEVEL`..`SUMMONER_MAX_LEVEL`; the guild roster has its own always-on rule (`SUMMON_ALT_*` in `Recipients-Guild.lua`).
- **Band per class** (`Matcher:LevelBand`): gear anchors below its equip level (`LEVEL_GAP_WIDEST`..`LEVEL_GAP_CLOSEST` under it, arriving just before it is useful); consumables anchor at their use level, `CONSUMABLE_RECIPIENT_GAP` up. `item.bandLo`/`bandHi` are the union, for display and reports only.
- **Armor proficiency reach**: `NATIVE_ARMOR` rows are steps read through `NativeArmorAt`. `ns.Data.ArmorEquipLevel` answers the later of the item's requirement and the class's training level, so a later training level moves the band instead of closing the door (level 35–39 mail is itemized for hunters who train mail at 40). `PROFICIENCY_REACH` bounds it; training levels are probed off `NATIVE_ARMOR` up to `MAX_PROBE`. `Matcher:BandGroups` splits classes by band.
- **Weapons have no reach**: `WEAPON_SPECS` rows count trees per class in `WEAPON_CLASS_ORDER`; 0 means cannot receive. Relics get weapon keys through `RELIC_SUBCLASS`.
- **Shuffle** is rolled once per player at pool entry, never in the comparator.
- **One recipient floor**: `ns.Data.MIN_RECIPIENT_LEVEL`, enforced only in `MatchList:AddResults`, the door every source uses.
- **Fairness** (`Recipients-Fairness.lua`): session-only `name -> { level }`; fresh again once seen higher. `Fairness:PickFrom` takes the first free, reachable, fresh candidate, then the first free and reachable. Unreachable = server refused mail this session (`MarkUnreachable`). Alts are never on the cooldown.

### Allocation

- `MatchList:Assign()` rebuilds every unpinned pairing each pass. A row is `pinned` when the player picked a recipient, kept it, or unticked it.
- **Scarcest first, then best first**: one item per person per pass; an item nobody can take sorts last. Alts are exempt from one-per-person (`IsTaken`).
- **Disenchant step last**: with `profile.disenchantUnmatched`, each unpinned unmatched `MatchList:Disenchantable` row (leftover gear only) goes to `ns.Alts:DisenchantRecipient()`, staying unpinned so a later gift can take it back.
- After a pass: no gift still searching → `ns.Who:Clear()`; else `ns.Who:Prune`; during a targeted search `NarrowTargeted` (`Match-Search.lua`) instead.
- **Still searching** (`StillSearching`, `Match-Search.lua`): an unpinned `gift` row unmatched, held by a fallback, or held by someone `Who:KeepsSearching` says a better-placed find would beat. A holder is in contention when the class is a contender **or the holder is an alt** (`HolderInContention`): alts are admitted by their own specs. Leftovers and unreadables never count.
- **Ticks**: every row starts ticked; a tick means give away and does not pin. Unticking pins and keeps the name for a re-tick. `RescanBags` carries `send` and `pinned` by slot, restoring hand picks first, then automatic pairings whose name is still free.
- Closing the window runs `MatchList:ReleaseAutomatic`: pins and pool survive, nothing re-matches until Find Recipients.

### /who Search Planning

- `C_FriendList.SendWho` is hardware-event gated: outside a real click it raises `ADDON_ACTION_BLOCKED` and nothing else (no error, no `WHO_LIST_UPDATE`). Every press must count. `Recipients-Who-Plan.lua` builds the plan; `Recipients-Who.lua` sends it.
- **One class filter per query**: the client honors one `c-"..."` and silently drops the rest. Multiple `z-` filters kept as best effort.
- **Female class names** get a twin query right after the male one; `Who:Exhausted` never lets one gender exhaust the other; pruning treats the pair as one class.
- **Plan per span**: zones first (people out leveling), then bare levels, then one query per class. Ahead of all, one `lo-hi g-"Name"` query per guild added by name (`Guild:SearchNames`), spanning every band.
- `MergeBands` (`Match-Search.lua`) joins touching bands; `Coalesce` folds bands into spans up to `SPAN_MAX`. Spans are interleaved so distant items both progress.
- **An answer under the cap ends what it answered** (`Who:Exhausted`): capped is `raw >= WHO_RESULT_CAP or total > raw`. Zoned, guild and unparsed answers never exhaust anything.
- `FILTER_MAX` is a hard budget on the filter string (over it the server does not answer); `ZoneChunks` splits zone lists to fit.
- **Zone order** (`ns.Data.ZonesFor`, `Recipients-Zones.lua`): overlap, centrality, narrower, table order. Unresolved faction admits every zone. A zone with no client name is cached `false` by `Who.AreaName` and skipped, never sent as `z-""`.
- **`Who:Prune` only removes**; re-planning via `Who:Plan` restarts at the first attempt. `Who:Plan` and `Who:Clear` cancel the pending query and reset `Who.targeted`.
- **Rescan for Better Match** (`UI:FindRecipientsForItem`): offered only where `UI:RescanCanHelp` (not unreadable, admits someone), shared by the picker entry and the press. Plans `Matcher:TargetedBands` with `targeted = true`: one class per attempt, contenders first, zones then anywhere, no bare query. Tracks the row by slot key (`MatchList:Target`). `NarrowTargeted` drops attempts whose class could not outrank the holder (`Who:PruneTargeted`, `Matcher:CouldOutrank`; an alt holder ranks with the contenders). Refuses with `L["WHO_WAIT"]` while a query is in flight or the throttle runs, before retasking.
- **Timing**: `WHO_THROTTLE` (exposed as `Who.THROTTLE`, read by `UI:LockFindButton`) runs from the send. The Recipients-Who `RESULT_TIMEOUT` requeues an unanswered query at the front.
- **Who panel deafened per query**: the stock UI opens the Who panel on `WHO_LIST_UPDATE`, and as a UIPanel it closes `MailFrame`, ending the mailbox interaction. `BeginQuery` unregisters `WHO_LIST_UPDATE` from every frame `GetFramesRegisteredForEvent` names except `ns.eventFrame` (skipping forbidden ones) and sets `SetWhoToUi(true)`; `EndQuery` re-registers exactly those, restores `SetWhoToUi(false)`, hides the panel only if it was closed before. Naming `FriendsFrame`/`WhoFrame` is only the fallback. Parsed under `pcall`, `EndQuery` either way. An abandoned query is marked `canceled`, never dropped.
- **Parsing**: other-faction results dropped via a race-name → faction table from `C_CreatureInfo.GetRaceInfo`; unplaceable or shared races kept. Each answer reads `ns.Guild:WhoLookup()` once: members of any usable My Guilds guild are flagged `guild` with `guildName`; ignored members dropped (`counts.ignoredGuild`).

### Guild Roster

- `Recipients-Guild.lua` hands a filtered list to a callback in the `/who` result shape; `PullGuild` feeds `AddResults`. No press, no throttle.
- `Guild:Request` is callback-gated: `GUILD_ROSTER_UPDATE` storms in large guilds, so with no request outstanding it is ignored, except the login save (first update with members runs `Guild:Save()`). Pulled when the window opens at a mailbox and when a fresh plan starts; never for a targeted search.
- `Classify` drops, in order and counted apart: your own characters, members ignored on My Guilds, summoning alts (`SUMMON_ALT_*`), and members offline past `profile.guildOfflineLimit` (`Guild.OFFLINE_DAYS`). An offline member with no reading counts as too old (the roster arrives in pieces).
- **Own-character detection** (`OwnCharacters`) reads `ns.db.sv.profileKeys` (never `ns.db.profileKeys`) and `global.characters`. Realm keys rebuilt as `Character-Realm` via `ns.NormalizeRealm`; Forever's `"First Last"` keys qualified like a roster row.
- **Saved guilds**: every character saves its roster to `global.guilds`, keyed `Guild:Key` (`realm:faction:name`). `Guild:ReadSaved` offers ticked guilds on this exact realm and faction, minus the current guild (read live). Members age out by `days` plus days since the scan. `Guild:Read` returns nobody when the current guild is unticked or removed (`Guild:Usable`).
- **Guilds added by name** (`Guild:Add`, TFTB's box): `added = true`, no members; searched by `g-"Name"` queries. Names compare via `NameKey` (trimmed, spaces collapsed, lower case); `Guild:Save` takes over an added entry spelled with other capitals.
- **Removing** (`Guild:Remove`): an added-never-saved guild is deleted; any other is flagged `removed`, since a character in it would save it again at login. Re-adding by name clears the flag.
- **Ignores** live in `entry.ignored[qualified name]`, which `Guild:Save` leaves alone; an ignore holds even when its whole guild is unticked or removed.
- **My Guilds changes reach the pool** through `MatchList:RecheckGuildmates`, called from the panel's `Changed()`: drops pooled guildmates the lookup no longer calls guildmates, or calls ignored.

### Alts as Recipients

- Each character records itself in `global.characters` (`Recipients-Alts.lua`) at login, level up, respec: what it is (name, realm, class, level, faction, spec). A login never rewrites the player's choices on the entry (`include`, `specs`, `levelsBelow`, `levelsAbove`, `disenchanter`).
- Spec read: `C_SpecializationInfo.GetSpecialization` when `ns.EXPANSION >= 5` (Mists has no global and its talent tabs throw); elsewhere the most-pointed tree. `GetTalentTabInfo` returns name-first on Era and id-first later, moving points from the third return to the fifth.
- Unset `include` = ticked below the level cap, unticked at it (`Alts:IncludedByDefault`, `GetMaxPlayerLevel` used alone where it exists). `Alts:Included(nil)` is false, so an alt deleted this session stops receiving.
- Reach: `Alts:Connected` (same realm or same `LINKED_REALMS` cluster); `Alts:Address` mails bare on this realm, `Name-Realm` on a connected one.
- Judged by its own specs: `Alts:SpecsFor` → `Matcher:VerdictForSpecs` (via `ns.Data.SpecOverride`), cached per class and spec set. Gear only inside `Alts:LevelRange` (stops in `ns.ALT_LEVELS_BELOW_ORDER`, `ns.ALT_LEVELS_ABOVE_ORDER`).
- **Mailing yourself is not giving**: alts skip one-per-person, the cooldown and the tally. Mail to an alt carries **no subject or body**: a letter with text stays in the mailbox after its item is taken. The client writes the item name into the emptied subject box on attach.
- A refused alt is dropped via `ns.Alts:Forget`; it re-records at its next login.
- **Disenchanter**: one per realm cluster and faction, `disenchanter = true` on its `characters` entry (`Alts:SetDisenchanter`), not the profile, because the shared Default profile also serves characters that cannot mail it.

### Character Identity

- `ns.PlayerName()` is the mailing address: `"First Last"` where `ns.UsesSurnames()` (WoW Forever, via `UnitNameUnmodified`), `UnitName` elsewhere.
- `ns.QualifyPlayerName` is identity, not address: appends `-Realm` to a bare name. Roster rows, the current character, the `AddResults` dedupe, peer keys and own-echo detection all compare through it. The pool keeps the name exactly as the API gave it, because that is what `SendMail` takes.
- AceDB keys characters `"Name - Realm"` on realm clients and `"First Last"` on Forever. `PruneOtherClientCharacters` (`Core.lua`, right after `AceDB:New`) drops saved characters shaped the other way: copied WTF folders (Style Guide → Other-Client Characters). Not a migration; permanent.

### Mailing

- `SendMail` cannot be looped; one send, then wait for a result. The non-friend confirmation popup is never auto-clicked.
- **Ordering constraints**:
  - Check the Send Mail panel before touching the item: `UseContainerItem` with it closed *uses* the item. Each job checks `ns.AtMailbox()` and postage (`MAIL_COST`), forces the Send tab (`MailFrameTab_OnClick(nil, 2)` under `pcall`), ends with `MAIL_PANEL_CLOSED` if `SendMailFrame` still is not shown.
  - Empty the subject box before attaching, fill the panel after: the client writes the item name only into an empty subject. `SubjectOf(job)` falls back to that text, then the link's bracketed name.
  - Never re-read the bag slot on `MAIL_SUCCESS`: it fires before the bag update. Stack size captured as `job._count` before the send; delivered rows removed by `uid`.
- `GetSendMailItem(1)` checked before every send (a failed attach posts an empty letter as success). Moved items skipped as `MAIL_ITEM_MOVED`. Attach and `SendMail` under `pcall`; a throw releases the attachment via `ClearSendMail`. After each call the job re-checks `busy` and current job.
- **No answer pauses** (Mail-Sender `RESULT_TIMEOUT`): job moves to `_awaiting`, player told to Accept and press Distribute. A late result is credited by `Distributor:Result` on a stopped run. `Start` refuses for one more timeout while a job is held (`MAIL_STILL_SENDING`), then clears it.
- **Closing the mailbox stops the run**: `RecheckDistribute` waits one frame, stops if `ns.AtMailbox()` is false.
- **Refusals**: `UI_ERROR_MESSAGE` matched against the client's `ERR_MAIL*` globals (format-specifier strings skipped) plus `ERR_PLAYER_WRONG_FACTION`; `Distributor:IsMailError` is that test, shared with the event log filter and an API row. Only a job with `_sent` marks the name unreachable and runs `DropRepeats` (an attach error is about the item; a bare `MAIL_FAILED` names nobody). `FAILURE_SETTLE` absorbs the second signal; `Distributor._run` bumps on `Start`/`Stop` so stale timers do nothing. Abort after two consecutive counted failures, clearing the panel first (the failed item and name still sit in it). Wrong-faction refusals never count.
- `UI:Distribute` sends one parcel per stranger per run (`MAIL_ALREADY_HAS_ONE`); alts and hand picks exempt. `Distributor:Finish` triggers a Generosity broadcast.

### Mail Copy

- `Mail-Copy.lua`: player's `mailSubject`/`mailBody` when set, cleaned by `Distributor:CleanText`, else `L["MAIL_SUBJECT"]`/`L["MAIL_BODY"]`. `Distributor.MAIL_FIELDS` maps each key to its stock string and byte ceiling; editor and mailer both read it.
- A custom body always ends with `L["MAIL_POWERED_BY"]`. Custom copy is stored uncut and cut at build (`SUBJECT_MAX`, `CUSTOM_BODY_MAX`) by `Shorten`, byte-measured, never inside a multi-byte character, footer after the cut. `SaveCustomText` stores `""` when the text equals stock.

### The Mail Window

- `PlayItForwardMailFrame` (`UI-Window.lua`): sizes and gaps on the Spacing Scale except Blizzard art (22-tall buttons, scrollbar gutter). Resizable; `UI:SaveGeometry` writes `profile.windowPos`/`windowSize`, whose `point`/`width` fields mean the player moved or sized it. Portrait `Gift.tga` via `PortraitFrameTemplate`, falling back through `ns.PickTemplate`.
- Opens at a mailbox when `UI:HasSomethingToDo` (a ticked row with a recipient or in `gift`, or Kept gear while disenchanting has a disenchanter); never auto-closes; skipped while a run is busy.
- **Top bar** (`UI-Top-Bar.lua`, `UI:BuildTopBar`): mirrors the options panels, writing the same profile keys. Each tick's tooltip is the panel's own description. A dropdown hides while its tick is off; kind ticks dim instead. `UI:SyncControls` is the one redraw entry point (ticks, panel setters, `ns:ApplyProfile`); a change runs `UI:Rescan()` and `NotifyChange` on General and What to Give Away. The list hangs from `UI.TOP_BAR_BOTTOM`.
- **Sections**: Matched, Disenchant (labeled `ns.DisenchantName()`), Pending Match, Stats Couldn't Be Read, Kept; then score, then bag order.
- **Status and Distribute** (`UI-Status.lua`): `UI:StatusLine` (frame-free for `Tests/Status-Line.lua`) picks the first that holds: sending, waiting on a search, ready, Kept gear with Disenchant off. Distribute reads Requires Open Mailbox away from a mailbox (`ns.AtMailbox`, never `ns.mailboxOpen`), Sending during a run, enabled only with a ticked row holding a recipient. Find and Distribute share one width, the widest label.
- **Row dropdown** (`UI:PickerOptions`, `UI-Assignment.lua`, frame-free for `Tests/Manual-Assignment.lua`): four blocks — `UI:PickerHeader` (count, band and `UI:BestFitLine`, or why nobody), candidates under Your Alts / Your Guild / Strangers, Disenchant and Keep Item, then Rescan for Better Match when `UI:RescanCanHelp`. The recipient button has no tooltip; the header is where its reasoning lives. Notes beside names are information, never gates. Picking a name holding another unpinned row takes it; an alt's name never is.
- **Picker** (`UI-Picker.lua`): one shared popup in `UISpecialFrames`, click-catcher at `DIALOG` strata, `info` entries for header lines. The pick runs **before** the list closes (issue #16). Width measured with a hidden ruler font string. Background texture added on every flavor (`TooltipBorderedFrameTemplate` draws no fill on Era).
- **Escape** goes through `UISpecialFrames` (Hide only). Everything that stops on close hangs off `OnHide` via `UI:OnClosed`, idempotent. `OnHide` returns early while still shown (Alt+Z). The open picker pulls the window out of `UISpecialFrames` so Escape closes only the list.
- **Reopen button** (`UI-Reopen-Button.lua`, `PlayItForwardReopenButton`): shows while `MailFrame` is shown, at a mailbox, window hidden. Parented to `UIParent`, only anchored beside `MailFrame`. Click: `MatchList:EnsureScan()` then `UI:Open()`. Hover opens a menu (Menus, Not Tooltips), `PlayItForwardReopenMenu`, on `Menu-Plate.tga`, rows from `UI:ReopenMenuEntries`; closes after the mouse leaves both, on Escape, or when the button hides. `UI:SyncReopenButton` runs from `Open`, `OnClosed`, `MailboxOpened`, `RecheckDistribute`.

### Giving Tally and Sharing

- `Generosity.lua`: `global.stats` (`gifts`, `items`, `itemLevels`, `value`). `ns.Generosity:RecordSend` is the only writer, via `Credit(job)` on normal and late delivery; skips alts. `Generosity:BlockLines` renders both the tooltip and the panel preview.
- `Generosity-Broadcast.lua`: `C_ChatInfo.SendAddonMessage` on `YELL` (Classic has no custom channels and drops add-on whispers to strangers), so the feature is proximity-scoped. Prefix `ns.ADDON_MESSAGE_PREFIX`, registered at load under `pcall`. Payload is versioned and pipe-delimited:

```text
1|S|<gifts>|<items>|<itemLevels>|<value>    stats
1|?                                         ping
```

- Receiving: unknown version or prefix dropped; our own YELL echo ignored (sender key equals `ns.QualifyPlayerName(ns.PlayerName())`); a stats message needs exactly `STATS_FIELDS` parts of plain digits up to `PEER_TOTAL_MAX` (`ReadTotal`), else dropped. Peers cached by qualified name with a `GetTime()` stamp, good for `PEER_MAX_AGE`, swept on the next stats message (no timer).
- One `Send`, under `pcall`, result kept in `Generosity.lastSendResult` (a refused channel is a return value, not an error).
- **Town only**: every send and the tooltip block gated on `ns.AtRest()`, checked before the throttles. Throttles: `BROADCAST_MIN_INTERVAL` (outgoing totals, ping answers), `HOVER_PING_INTERVAL` (`Generosity-Tooltip.lua`).
- **Tooltip block**: header from `ns:BuildBrandedLine`; values white (`GetCoinTextureString` ignores a color prefix); labels `HELP`. Hook: `TooltipDataProcessor` unit post-call only where `GameTooltip.GetPrimaryTooltipData` exists, else `OnTooltipSetUnit` when `GameTooltip:HasScript` confirms, else none; `Generosity.tooltipHook` records which. `C_Secrets.ShouldUnitIdentityBeSecret` asked before any name read. First hover of an unknown player pings; the block appears next hover.

### Options Panel

- `ns:OpenOptionsPanel` is the one entry point (`/pif` only calls it). `ns:OptionsPanelRoute` decides the route in one place, shared with its Diagnostics API row. Routes to `Settings.OpenToCategory(ns.GeneralCategoryID)`, falling back to AceConfigDialog's window.
- Category ID is captured from `AddToBlizOptions`' second return, never looked up by name (Era lacks `C_SettingsUtil.OpenSettingsPanel`, TBC Anniversary has it, so a name lookup floats the panel on one).
- Registration deferred to `ns:RegisterOptionsPanels` at `ADDON_LOADED` (Profiles reads `ns.db`). Root General; children: What to Give Away, Recipients (My Alts, My Guilds nested by category ID), Mail Message Text, Badge of Generosity, Profiles, Feedback & Support, Diagnostic Tools. My Alts, My Guilds and Diagnostic Tools register as builder functions, rebuilt every repaint.
- My Alts and My Guilds are `childGroups = "tree"`; `PrepareListTree` (`Options.lua`) seeds `ns.OPTIONS_TREE_WIDTH` and the selected node, reseeded on hide. Nodes keyed by saved key, never position.
- Recipients' spec row widths come from `SpecWidth()`: the row split by the most specs any class has here, at least three. Spec Restore Defaults is a confirmed `execute` wiping `profile.specs` (README-Notes).
- **Layout**: AceConfig's flow packs cells until a row fills. A label-beside-value pair needs a full-width spacer after it; two `description` widgets never break a row alone. Shared widths in `Data/Data.lua`; panel-local splits in their files.
- A setter changing giftability or anything ranking reads calls `ns.RefreshMailWindow()` (`Options-Utilities.lua`): `UI:SyncControls()` if the window exists, `UI:Rescan()` always (which marks the scan stale with no window, `MatchList:MarkStale`). `ns:ApplyProfile` does the same on profile switch, copy or reset, after rebuilding weights, and notifies every panel.
- **Mail editor** (`PlayItForward-MailEditor`, `Options-Mail.lua`): saves every keystroke via `Distributor:SaveCustomText`, bypassing AceConfig's set (a set redraws the panel and steals the cursor). Counts are bytes against `MAIL_FIELDS`. Restore Default clears both keys (README-Notes), no confirm (a confirm popup blanked the panel), never disabled (a `disabled` gate would go stale).
- `UI:RarityPickerOptions` / `UI:GapPickerOptions` are frame-free for `Tests/Options-Values.lua`. The All Consumables stop is a gap of zero; compare `== nil`. Off-stop values snap for display via `ns.NearestConsumableGap`.
- The Badge preview (`PlayItForwardBadgePreview`) is a custom widget through `dialogControl`; its row `name` is `tostring(gifts)` so a gift forces a redraw.

### Localization and Game Names

- `enUS.lua` is the only `NewLocale(..., true)` and registers under the literal `"Play-It-Forward"`, which must equal `ADDON_NAME` read in `Data/Data.lua` (else every `L` is nil with no load error). Other locales belong to the Localization Review.
- Game names come from the client: zones and instances by AreaTable ID (`C_Map.GetAreaInfo`, `Who.AreaName`); classes by token (`LOCALIZED_CLASS_NAMES_MALE`/`_FEMALE`); races by ID; specs via `ns.SpecName`; qualities 2–4 via `ITEM_QUALITY*_DESC`; Disenchant via `SPELL_IDS.DISENCHANT` and `C_Spell.GetSpellName`; mail refusals and non-stat tooltip prefixes via their globals.
- Exceptions (README-Notes): `SPEC_*` strings where the client cannot name a tree; English-only `EQUIP_PATTERNS` and `ENUS_FALLBACK` (gated by `Tooltip.equipPatternsUsable`); English mail copy in every locale.
- Zones are area records, not map records: `/who` matches the area name, and area and map names differ in some locales.
- Diagnostics strings are not localized (`ns.DiagnosticsStrings`), including the `WHO_LABEL_*` query labels `Recipients-Who-Plan.lua` reads at call time, since Diagnostics loads after it.

### Diagnostic Tools

- Framework copied from Magic Eraser, plus two additions kept by README-Notes: API rows print their second return, and a report row can take a typed `input`. `Validate-Data.lua` reads tables off `ns.Data`.
- `Manifests.lua` holds this add-on's surface: `ns.DIAGNOSTIC_API_CHECKS`, the context reports (Mailbox, Bag Scan, Recipient Roster, Item Verdict, Class Groups, Outgoing Mail, Given Away Sharing), `ns.DIAGNOSTIC_DATA_SOURCES` (one per flavor-folder file, `Game-IDs` validating `SPELL_IDS` as spells), `ns.DIAGNOSTIC_NAME_LOOKUPS` (built from the add-on's own data, so new stats, classes, specs and areas get rows unedited), `EVENT_LOG_EXAMPLES`.
- Reports call the live handlers' own tests (`MatchList:WouldRescan`, `UI:HasSomethingToDo`, `UI:WantsReopenButton`, `Distributor:IsMailError`, `ns:OptionsPanelRoute`) so a report cannot describe behavior the add-on does not have.
- Three API rows feed literal color-wrapped suffix lines to `Tooltip:StatsFromLines` as regression guards; another counts how many `ERR_MAIL*` strings `IsMailError` recognizes.
- **Event log filter** (`Diagnostics/Event-Log.lua`): `ns.DIAGNOSTIC_EVENT_EXCLUDE` is deliberately empty. Noisy events go through `ns.MESSAGE_ID_FILTERED_EVENTS` with a `correlated` predicate calling the handler's own test: `UI_ERROR_MESSAGE` (`IsMailError`), `CHAT_MSG_ADDON` (our prefix), `BAG_UPDATE` (`WouldRescan`), `GET_ITEM_INFO_RECEIVED` (`WouldRescanItem`). Filtered at capture, counted per event and id. Secret values (WoW Forever) are never compared or stringified: they log as `<secret>` and count under `SECRET_ID`; a predicate runs under `pcall` because the log runs ahead of the real handlers. `Tests/Event-Log-Noise.lua` pins it.

## Files That Change Together

- **New registered event**: `ns.On` in its feature file, behind a flavor gate if the client may lack it (registering an unknown event throws); if noisy, a `ns.MESSAGE_ID_FILTERED_EVENTS` entry in `Diagnostics/Event-Log.lua` whose predicate calls the handler's own exposed test.
- **New giftable consumable row**: the row in `Scan-Food`/`Scan-Potions`/`Scan-Scrolls`/`Scan-Oils-Stones` in every flavor folder whose client has it; its `restores`/`buffs`/`enhances` value must exist in that folder's `CONSUMABLE_CLASSES`; a case in the matching `Tests/*-Rules.lua`.
- **New consumable table**: the file in all seven flavor folders and each TOC; `ns.CONSUMABLE_KIND_ORDER` and `ns.CONSUMABLE_KIND_STRINGS` (`Data/Data.lua`); its `consumableKinds` default; its locale keys; a `DIAGNOSTIC_DATA_SOURCES` entry in `Manifests.lua`; the kind stamping in `Scan-Bags.lua`.
- **New stat**: `STAT_MAP` (every key spelling any client returns), `Match-Specs` weights and `Match-Stat-Budget` cost in every folder; `ENUS_FALLBACK` or `EQUIP_PATTERNS` if it has no `ITEM_MOD_` global; `Tests/Stat-Scoring.lua`, `Tests/Tooltip-Parsing.lua`; rewrite `Tests/Outcomes/` via `Tests/Write-Outcomes.lua` once intended.
- **New item rule**: `ITEM_RULES` in every folder's `Match-Rules`, placed deliberately if `prefer`; a case in `Tests/Item-Rules.lua` (or the weapon/consumable/scroll/oil rule tests).
- **New setting**: its `ns.DATABASE_DEFAULTS.profile` key; its row in the feature panel builder (never General); `enUS.lua` strings; `ns.RefreshMailWindow()` in its setter if it touches giftability or ranking; its top-bar twin and `UI:SyncControls` if the bar shows that section.
- **New options panel**: an `ns.OPTIONS_REGISTRY` entry in `Data/Data.lua`, a line in `ns:RegisterOptionsPanels`, its TOC line.
- **New game record named by ID**: a constant in every folder's `Game-IDs` file; a `DIAGNOSTIC_NAME_LOOKUPS` row.
- **New flavor-folder file**: all seven folders, the four TOCs (Vanilla lists both Vanilla and Discovery), the Discovery guard, and a `DIAGNOSTIC_DATA_SOURCES` entry.
- **New Features file**: the four TOCs at a position after everything it captures at file scope.

## Saved Variables

- `PlayItForwardDB`: the one table, created in the name-guarded `ADDON_LOADED` handler (`Core.lua`), with `PruneOtherClientCharacters` on the next line.
- `profile`: every setting, the custom mail copy, and the window's `windowPos`/`windowSize`. `global.characters`: every character that has logged in, plus the player's choices on each. `global.guilds`: saved rosters and guilds added by name, with `include`, `ignored`, `added`, `removed`. `global.stats`: the giving tally.
- **Model: Simple** (third argument `true`, one shared `"Default"` profile). Nothing is stored per character as a profile. **Reset Profile restores every setting, spec choices included, and leaves `global` untouched**: characters, guilds, the choices made on them, and the tally. A new setting goes in `profile`.
- The disenchanter lives on its `characters` entry rather than in `profile`: the shared profile also serves characters that cannot mail it.
- The mail keys are `mailSubject`/`mailBody`, not an earlier editor's `subject`/`message`, so values left under those stay unread.
- `consumableLevelGap` of 0 is the All Consumables sentinel. A new kind in `ns.CONSUMABLE_KIND_ORDER` reaches existing profiles through AceDB's nested `consumableKinds` defaults.
- No default item or spell lists, so no seeding. `characters` and `guilds` fill from the game; an alt's default `include` is computed, not stored. Fairness history is session-only.
- Not settings, on purpose: `ns.Data.MIN_RARITY`, every matching constant, the `MAIL_POWERED_BY` footer.

### Migration Chain

- First names to full names (`Recipients-Alts.lua`, `Adopt` and `UpgradeFirstNames`): a WoW Forever character recorded under its first name alone is moved onto its `"First Last"` key, choices carried over. `MIGRATION (remove after 2026-12-05)`, with its tests in `Tests/Alts.lua`.

## Pitfalls & Why

- **Calling `SendWho` outside a click**: blocked with no error and no event. Every query rides a button press; `ADDON_ACTION_BLOCKED` is caught only to explain one.
- **Closing a picker before running its pick**: on WoW Forever, hiding the list and its click catcher first left Rescan for Better Match's `SendWho` blocked. `Picker:Open`'s click runs `onSelect` then `Close`.
- **`UseContainerItem` with the Send Mail panel closed**: uses the item. Check the panel first.
- **Setting the subject before the attach, or leaving the last one in the box**: the client writes the item name only into an empty subject, and a stale subject would carry onto an alt's letter. Empty it before the attach; fill the panel after.
- **Giving mail to your own alts a body**: the letter stays in the mailbox after the item is taken. Alt jobs carry no subject or body.
- **Re-reading a bag slot on `MAIL_SUCCESS`**: still holds the old link. Trust the event; capture `_count` before the send.
- **Dropping a job when the mail result timer fires**: `SendMail` already went out; the job moves to `_awaiting`.
- **Starting a run over an awaited send**: its late result would credit the new run's first job. `Start` refuses for one more `RESULT_TIMEOUT`.
- **Old settle timers**: `FAILURE_SETTLE` outlives its run; checked against `Distributor._run`.
- **Treating every failure as a refusal**: only a job with `_sent` set marks the name unreachable and drops that recipient's other jobs; attach errors and bare `MAIL_FAILED` say nothing about who.
- **Aborting with the item still on the panel**: one Send would re-mail it. Abort calls `ClearSendMail` first.
- **Closing the window from `MailFrame`'s `OnHide`, or gating on `MailFrame:IsShown()`**: mail-replacement add-ons and the Who panel hide it at a mailbox. Use `ns.AtMailbox()`.
- **Parenting a frame to `MailFrame`**: protected for good, and writing to the panel taints it. Parent to `UIParent`, anchor beside it.
- **Dropping an in-flight `/who` instead of cancelling it**: `EndQuery` restores Blizzard's frames and `SetWhoToUi`; skip it and the player's own `/who` is silent for the session.
- **Re-planning a search mid-flight**: `Who:Plan` restarts from the first attempt. `Who:Prune` only removes.
- **Two class filters in one `/who`**: the client keeps the first.
- **Naming instances from uiMaps**: Era and Forever ship no dungeon maps. Use `INSTANCE_AREAS` through `C_Map.GetAreaInfo`.
- **Trusting `GetItemStats` on a random-suffix green**: returns nothing for the suffix. The tooltip is the only source.
- **Dropping `CleanLine`**: text handed straight to `StatsFromLines` (Diagnostics probe, tests) arrives color-wrapped and fails the `+N` anchor.
- **Reading Use:, proc or set-bonus lines as stats**: "Use: Increases attack power" is not attack power. `IsNonStatLine` skips them by the client's own prefixes.
- **Caching a reputation check off an unrendered tooltip**: a loading item would pass as needing no standing. `IsReputationLocked` caches only after a render.
- **Counting tooltip lines as a successful read**: a `C_TooltipInfo` answer can carry no text.
- **`classID == 2` to mean weapon-matrix**: shields, held off-hands and relics rank there too. Use `ns.Data.UsesWeaponMatrix(item)`; read a weapon key only after checking `classID` (cloth subclass 1 collides with two-hand axe).
- **`INVTYPE_HOLDABLE` in `UNIVERSAL_EQUIP_LOC`**: makes an Intellect orb eligible for warriors. Held off-hands route as `HELD`.
- **Reading `ns.db.profileKeys`**: always nil; it lives on `ns.db.sv`.
- **Comparing player names raw**: one character can arrive bare and suffixed. Compare `ns.QualifyPlayerName`; mail the name the client gave.
- **Using `UnitName("player")` as this character's address**: on WoW Forever it answers the first name alone. Use `ns.PlayerName()`.
- **Treating an alt holder as a fallback**: alts are admitted by their own specs. `HolderInContention` and `CouldOutrank` count `person.alt` as a contender, or the search keeps hunting to replace your alt.
- **Changing My Guilds without `RecheckGuildmates`**: guild state is read only at pool entry, so an unticked guildmate stays pooled until a reload.
- **Deleting a guild a character of yours is in**: it is saved again at that character's next login. `Guild:Remove` flags it `removed`.
- **Mists specs through the global `GetSpecialization` or talent tabs**: missing or throwing. Ask `C_SpecializationInfo` when `ns.EXPANSION >= 5`.
- **A second recipient level floor**: there is one, in `AddResults`; a copy drifts.
- **A ranking-relevant setting without `ns.RefreshMailWindow`**: the candidate cache is stamped against the pool only.
- **Mutating `MatchList:Candidates`'s list, or caching `MatchList:Items()`**: the first is shared by reference; `RescanBags` reassigns the second.
- **Re-reading bags at the end of a run**: sent slots are not empty yet, so the scan restores delivered pairings. `UI:AfterDelivery` re-assigns without scanning.
- **Random tiebreak in a sort comparator**: `table.sort` throws. Shuffle is rolled at pool entry.
- **Reordering `ITEM_RULES`**: `prefer` is first-match-wins; `veto` and `demote` make the table look more reorderable than it is.
- **Adding a stat weight and expecting only scores to move**: it widens the coverage denominator on every item with that stat.
- **Mapping one spelling of a stat key**: TBC Anniversary returns long spell damage and healing keys. Map every spelling.
- **A class added to `FACTION_CLASSES` alone**: `EVERY_CLASS` in `Match-Engine.lua` stops at the monk.
- **Misspelling a consumable's `restores`/`buffs`/`enhances`**: missing from `CONSUMABLE_CLASSES` means every class, failing open.
- **A consumable rule on `form` alone, or on `OIL_STONE`**: needs `form` plus `restores`; never matches.
- **A consumable whose band ends below `MIN_RECIPIENT_LEVEL`**: matches nobody and keeps the search plan alive for it.
- **Treating `consumableLevelGap` 0 as a gap**: it is the All Consumables sentinel.
- **Believing a peer's totals as sent**: anyone in yelling range can send them. `ReadTotal` accepts plain digits up to `PEER_TOTAL_MAX` only.
- **Answering our own YELL ping**: it echoes back and spends `BROADCAST_MIN_INTERVAL` on nobody.
- **Hooking a tooltip because `TooltipDataProcessor` exists**: Classic clients never run its post-calls, and `HookScript` on a missing script type throws (Forever dropped `OnTooltipSetUnit`).
- **Coloring Generosity values**: the money row ignores the prefix; everything stays white.
- **Stringifying an event argument on WoW Forever**: a secret value errors when compared, concatenated or used as a key. The log goes through `IsPlain`.
- **Opening the options panel by category name**: works on Era, floats the panel on TBC Anniversary. Use `ns.GeneralCategoryID`.
- **Pairing two `description` widgets without a spacer**: rows interleave.
- **Removing a key from `ns.DATABASE_DEFAULTS` and expecting it gone**: AceDB's cleanup only visits keys still in the defaults. Nil it in a tagged migration.
- **Moving a file earlier in the TOC**: `Match-Derivations.lua` reads data at load, and the UI files capture what earlier UI files created.
