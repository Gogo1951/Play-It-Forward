# Play It Forward — Technical Reference

This document combines architecture notes and contribution guidance for developers working on Play It Forward. For end-user documentation, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md).

## File Map

```text
Play-It-Forward/
├── .github/
│   └── workflows/
│       └── package.yml              CurseForge release + library vendoring.
├── .pkgmeta                         Externals and ignore list.
├── LICENSE                          MIT.
├── Play-It-Forward.toc              Single TOC; dual interface (Classic Era, TBC Anniversary).
├── README.md                        Player-facing documentation.
├── README-Technical.md              This document.
├── Data/
│   ├── Data.lua                     Locale init, ns.Data, flavor flags, palette, links, options registry.
│   ├── Default-Settings.lua         ns.DATABASE_DEFAULTS — the AceDB defaults table (profile only).
│   ├── Stat-Map.lua                 GetItemStats keys -> internal stat tokens.
│   ├── Stat-Weights.lua             Per-class stat point tables and the scoring constants.
│   ├── Item-Rules.lua               Stat, form and weapon combinations that name their own class.
│   ├── Armor-Priority.lua           Native armor per class per level; universal equip slots.
│   ├── Weapon-Priority.lua          Spec-count matrix per weapon type, plus proficiency level gates.
│   ├── Food-And-Water.lua           Giftable food and drink (SQL-sourced).
│   ├── Potions.lua                  Giftable potions (SQL-sourced).
│   └── Zones.lua                    Levelling zones per flavor and faction, for /who filtering.
├── Features/
│   ├── Core.lua                     Identity, AceDB lifecycle, central event dispatcher.
│   ├── Utilities.lua                Container API shims, frame templates, color accessors, ns.AtMailbox.
│   ├── Announcements.lua            ns:PrintMessage — the only output path, player-only.
│   ├── Tooltip-Scanner.lua          Reads stats off a rendered tooltip, which is where suffix stats live.
│   ├── Bag-Scanner.lua              Bag slot -> giftable item record, or nil plus a reject code.
│   ├── Matching-Engine.lua          Eligibility, claim/fit scoring, coverage, verdict, candidate ranking.
│   ├── Recipient-Search.lua         /who planning, chunking, throttling, result parsing.
│   ├── Guild-Roster.lua             Second recipient source; activity window, own-alt and summon-alt filters.
│   ├── Recipient-Cooldown.lua       Fairness history and this session's unreachable names.
│   ├── Mail-Sender.lua              Serialized, event-driven mailer.
│   ├── Recipient-Picker.lua         Scrolling dropdown widget, shared by the rarity and recipient controls.
│   ├── Match-List.lua               items / pools / assignedTo state, the rescan, and the allocator.
│   ├── Mail-Window.lua              Frame, rows, buttons, search stepper, delivery callbacks.
│   └── Diagnostics.lua              Report builders, manifests, event log, taint log.
├── Includes/
│   ├── Images/
│   │   └── Play-It-Forward.tga      Icon art.
│   └── Libraries/                   Vendored: LibStub, CallbackHandler-1.0, AceLocale-3.0, AceDB-3.0,
│                                    AceGUI-3.0, AceConfig-3.0 (Registry/Cmd/Dialog), AceDBOptions-3.0.
├── Locales/
│   └── enUS.lua                     Source of truth; the only locale file currently shipped.
├── Options/
│   ├── Options-Utilities.lua        Shared ns.Options* widget constructors, consumable-gap labels.
│   ├── Options-General.lua          ns.BuildGeneralOptions — root panel.
│   ├── Options-Profiles.lua         ns.BuildProfilesOptions — stock AceDBOptions-3.0 table, unmodified.
│   ├── Options-Diagnostics.lua      ns.BuildDiagnosticsOptions — Diagnostic Tools panel.
│   └── Options.lua                  Panel registration and the /pif slash command.
├── Tests/                           Headless suite; excluded from the packaged zip.
└── Suffix.md                        Random-enchantment reference; excluded from the zip.
```

There is no minimap button, so `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are all deliberately absent. `Suffix.md` and `Tests/` are development-only and are listed in `.pkgmeta`'s ignore block.

## Architecture

### Event Loop

`Features/Core.lua` owns one frame and one entry point, `ns.on(event, fn)`. Every registration goes through it; no feature file creates its own frame. `ns.EVENT_NAMES` accumulates as handlers register rather than being declared up front, because registration is flavor-conditional. The Diagnostics event probe reads that same list, so it can never test an event the dispatcher never took.

| Event | Registered in | Purpose |
|-------|---------------|---------|
| `ADDON_LOADED` | `Core.lua` | AceDB creation, fairness-list wipe, options registration. Name-guarded. |
| `PLAYER_LOGIN` | `Core.lua`, `Mail-Window.lua` | Welcome print; installs the `MailFrame` `OnShow` hook. |
| `MAIL_SHOW` / `MAIL_CLOSED` | `Mail-Window.lua` | Mailbox open/close on every flavor. |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `Mail-Window.lua` | The same signal off Era, where the interaction manager also reports it. |
| `BAG_UPDATE` | `Match-List.lua` | Marks the bag scan stale. |
| `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Same, for an item the client has just resolved. |
| `WHO_LIST_UPDATE` | `Recipient-Search.lua` | A `/who` answer landed; parse and hand it to the callback. |
| `ADDON_ACTION_BLOCKED` | `Recipient-Search.lua` | Turns a blocked `SendWho` into an explanation instead of a BugSack popup. |
| `MAIL_SUCCESS` / `MAIL_FAILED` | `Mail-Sender.lua` | Advances the send queue. |
| `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | Catches a refusal the server reports without either result event. |
| `GUILD_ROSTER_UPDATE` | `Guild-Roster.lua` | Delivers a roster the add-on asked for. Ignored when no request is outstanding. |

The dispatcher's only addition is a single guarded call — `if ns.diagnostics.logging then ns:LogEvent(event, ...) end` — read before any allocation, so diagnostics off costs nothing.

### Debounced Bag Scanning

`BAG_UPDATE` fires on every loot, vendor sale and stack merge; `GET_ITEM_INFO_RECEIVED` fires once per item against a cold cache. Neither scans directly. `scanSoon` sets `bagsDirty` and then returns immediately unless the window is actually on screen — arming a two-second timer that will find the window closed is work done for nothing on nearly every one of those events. When the window *is* open the timer coalesces a burst into one scan, and re-checks that the window is still shown when it fires, since it can close inside the debounce.

Away from a mailbox the flag simply stays set, and the next `mailboxOpened` or `ForceShow` pays for one scan at the moment the answer is needed.

### Scan → Match → Search → Send

Four phases, each in its own file.

1. **Scan** — `Features/Bag-Scanner.lua` walks bags 0–4. `Scanner:Classify` returns a finished record or `nil` plus a reject code (`NOT_CACHED`, `BIND_ON_PICKUP`, `LEVEL_GAP`, …). The codes are diagnostic identifiers, never shown to players, and exist so "why isn't this item listed" has an answer.
2. **Match** — `Features/Matching-Engine.lua` produces one `verdict` per item: eligible classes, admitted classes, contenders, per-class claim/fit/coverage, and a state of `gift`, `leftover`, or `unreadable`. Everything downstream reads this one verdict rather than recomputing.
3. **Search** — `Features/Recipient-Search.lua` builds a plan of `/who` attempts and steps it one press at a time.
4. **Send** — `Features/Mail-Sender.lua` walks a job queue, one `SendMail` at a time, waiting on a result event before advancing.

`Features/Match-List.lua` holds the state the phases share (`items`, `pools`, `assignedTo`) and runs the allocator; `Features/Mail-Window.lua` draws the result.

### Item Data Caching

`GetItemInfo` returns `nil` for an item the client hasn't resolved. The scanner treats that as a `NOT_CACHED` rejection rather than a missing item, and `GET_ITEM_INFO_RECEIVED` marks the scan stale so the next open re-reads the bags. Without it a cold cache reads as an empty bag, and the window silently declines to open.

Stats are read twice and merged by taking the **max** per stat, never the sum: `GetItemStats` resolves the base item and ignores random suffixes, while the tooltip renders the item as the player sees it. Both report the same value on a fixed-stat item, so summing would double it. The merge is lossy, so `record.statRead` keeps each source's own answer for the diagnostics report.

A second cache covers candidate ranking. `MatchList:Candidates(item)` stores the ranked recipient list on the item, validated against a `poolsGeneration` counter. Ranking walks every admitted class against every pooled player and sorts the result, and the same answer is asked for repeatedly — once per allocation pass, once per dropdown open, and once per mouse-over of a recipient button, which is the one with no ceiling. The generation bumps in `AddResults` (only when somebody new actually entered a pool, so a query returning nothing already known costs nothing) and in `ClearPools`; `rescanBags` needs no bump because it replaces every item table outright. Ranking reads only the pools and the item's own verdict and band — never `item.recipient` — so an assignment cannot stale a cached list. **The list is handed out by reference**: a caller that sorted or removed in place would poison it for everybody after.

Derived per-item data is cached under underscore-prefixed fields (`_weaponKey`, `_candidates`) to keep it out of the record's public shape.

### Scoring: Claim, Fit and Coverage

Three numbers per class per item, answering three different questions, and the separation is load-bearing.

- **Claim** (`Matcher:SpecScore`) — only the stats the point tables rank for that class. Decides who is *admitted*.
- **Fit** (`Matcher:Score`) — claim plus any universal weight and the `WEAPON_BASELINE` (0.15 × item level) that keeps a statless weapon placeable. Decides *ranking*.
- **Coverage** (`Matcher:Coverage`) — the share of the item's scoreable stats this class ranks at all, 0 to 1. Decides *breadth*.

Coverage exists because score sums, so breadth loses to a single large weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0, an exact tie the warrior wins with half the item dead on him. A class enters contention by clearing both `CLASS_SHARE` (0.35 of the best claim) and `COVERAGE_MAJORITY` (strictly more than half). Failing either leaves it admitted — still in the dropdown, still a fallback when nobody better is in range.

The denominator for coverage is *every stat some class ranks*, not the item's own stat line. That is why adding a stat weight is never only a scoring change: it enlarges the denominator on every item carrying that stat and can demote a class out of contention entirely.

### Verdict States

Three, not two. `gift` and `leftover` are the obvious pair; `unreadable` exists because an item whose random suffix failed to parse looks exactly like a worthless one, and telling a player to disenchant an item nobody actually evaluated is not reversible. An item is `unreadable` when it carries a suffix id and nothing parsed. Unreadable items are held out of auto-assignment entirely.

### Allocation

`MatchList:Assign()` rebuilds every pairing from scratch on each pass, against the whole roster. What survives is what the *player* decided — a row is `pinned` when they chose a recipient, sent it to the vendor, or unticked it. Rebuilding over a pin is the one thing the allocator must not do.

Items are handed out **scarcest first, then best first**. One item per person per pass makes this an allocation problem rather than a ranking one: an item two people can receive must pick before one fifty can, or the broad item takes one of the two and the narrow one gets nobody. An item nobody can receive sorts last, not first — zero is the impossible case, not the scarcest one.

When the pass leaves no gift unmatched, `ns.Who:Clear()` drops the search plan; a plan left standing is a countdown over finished work.

## /who Search Planning

`C_FriendList.SendWho` is hardware-event gated. A call outside the stack of a real click raises `ADDON_ACTION_BLOCKED` and does nothing — no error, no `WHO_LIST_UPDATE`. Queries therefore cannot be chained on a timer; each rides a button press.

`/who` ORs repeated filters of the same kind, so one press covers a whole band:

```text
16-19 z-"Westfall" z-"Loch Modan" z-"Duskwood" c-"Warrior" c-"Paladin"
```

The plan widens in three stages per band — zones plus classes, then classes alone, then bare levels — each giving up one constraint in the order that costs least. Bands are interleaved rather than run to exhaustion, so a bag holding a level 15 cloak and a level 45 sword makes progress on both. The filter string has a hard length budget (`FILTER_MAX`, 240): over it the server does not answer at all rather than truncating, so zone lists are chunked to fit.

A capped answer (`WHO_RESULT_CAP`, 50) is counted and otherwise ignored — the search stops at the first viable candidate per item, so fifty names is already more than enough. The roster report reads that count, because a capped answer is the difference between a thin realm and a thin sample.

Two pieces of cleanup ride on the answer rather than the request. `SetWhoToUi(true)` is what routes results to the list `GetWhoInfo` reads, and it is restored on the way out; Blizzard's Who panel opens when results arrive, and is hidden afterwards only when this add-on opened it. Both happen in `endQuery`, which is why a query the player abandoned is marked `canceled` rather than dropped — the answer still lands and still cleans up after itself.

**A settings change re-plans.** `UI:Rescan` feeds the freshly merged bands to `ns.Who:Plan` before assigning, so raising the rarity cap or toggling Include Gear searches for what is on the list now rather than draining a plan built for the old one. Found players are kept either way; only the list of places left to look is rebuilt.

## The Guild Roster

A second recipient source, and on most realms the larger one. It costs no button press and no throttle, and answers for the whole guild at once — where `/who` is hardware-gated and returns at most ~49 names per press. `Features/Guild-Roster.lua` feeds `MatchList:AddResults` in the same shape `/who` results arrive in, so nothing downstream knows where a candidate came from except the one `guild` flag that earns guildmates their tiebreak in `Matcher:RankCandidates`.

`Guild:Request` is gated on a callback rather than reading on every event: `GUILD_ROSTER_UPDATE` fires constantly in a large guild — every login, logout, note edit and rank change — and walking hundreds of rows with a `GetGuildRosterLastOnline` call apiece on each one is work nobody asked for. With no request outstanding the event is ignored.

Four filters drop members, each counted separately so "the guild added nobody" and "the guild has nobody active" can be told apart in the roster report:

- **Unreadable class token** — the only outright discard, matching what the `/who` parser does with the same gap.
- **Your own characters** — checked first, since one of yours is one of yours at any level or recency.
- **Summoning alts** — a warlock parked in the band around where Ritual of Summoning unlocks. A range rather than the unlock level alone, since they drift a level or two before stopping. **This rule is the guild roster's alone**: the same character found by `/who` is left alone, because out in the world at that level they are somebody playing, and nothing can tell a parked alt from a real one except which list named them.
- **Inactivity** — `GetGuildRosterLastOnline` returns nothing at all for a member who is online right now, and four separate duration components otherwise (years, months, days, hours), never a total. An offline member with no reading is treated as too old rather than recent enough: the roster arrives in pieces, and guessing "recent" on missing data mails gear to somebody who quit.

Own-character detection reads `ns.db.sv.profileKeys` — AceDB's record of every character that has loaded the add-on, keyed `"Character - Realm"`, rebuilt into the roster's `"Character-Realm"` shape purely as a comparison key. **That table lives on `db.sv`, not on `db`.** AceDB's metatable resolves only scope names, so `ns.db.profileKeys` reads `nil` and the whole check silently passes everyone through. An alt that has never run the add-on is not in there and is not caught, which is the honest limit of the approach.

Names enter the pool exactly as the roster gave them, suffix and all. A name is an address: `SendMail` takes the full form, and rewriting it means mailing to an address the client never gave us.

## Mailing

`SendMail` cannot be looped. One send goes out, then the run waits for a result event before advancing. Mailing a non-friend arms Blizzard's confirmation popup; that popup is the anti-spam guard for mailing strangers and is never auto-clicked.

Three ordering constraints, all load-bearing:

- **Check the Send Mail panel before touching the item.** `UseContainerItem` only attaches while Blizzard's panel is visible. With it closed the identical call *uses* the item — a green raises "you must be level X", a consumable is simply drunk.
- **Fill the panel after the attach, never before.** Attaching writes the item's name into an empty subject box, so a subject set earlier is overwritten by the client's guess.
- **Never re-read the bag slot to verify delivery.** `MAIL_SUCCESS` fires before the bag update arrives, so the slot still holds the old link at that instant. Trust the event.

An attach can still fail with the panel up, and `SendMail` does not care — it posts an empty letter and reports success — so `GetSendMailItem(1)` is checked before every send.

`UI_ERROR_MESSAGE` is also watched: the server can refuse a send without firing either result event, and the refusal arrives as a UI error instead. The matching set is gathered from the client's own `ERR_MAIL*` globals rather than hardcoded English, so it works on any locale; strings carrying a format specifier are skipped, since they arrive with the placeholder already filled in and an exact comparison would never match. A name refused this way goes on `Fairness:MarkUnreachable` for the session.

The subject and body are fixed text from `Locales/enUS.lua` (`MAIL_SUBJECT`, `MAIL_BODY`), never saved settings — what a stranger receives cannot drift per profile or be rewritten into something the add-on would not have sent. `Dist:WarnIfOversized` checks them against the client's limits (`SUBJECT_MAX` 31, `BODY_MAX` 500) at the start of every run.

## The Window

The window opens on the mailbox when the scan found anything worth acting on, and never auto-closes. `Features/Match-List.lua` holds items, roster and pairings at file scope, so matches survive walking away: come back and press Distribute.

Rows are sorted into four sections — matched, pending match, unreadable, vendor pile — because the list runs longer than the window and the rows worth acting on would otherwise fall below the fold. Every row's dropdown lists *everybody* in range, graying the unavailable with the reason beside them, because a name that silently vanishes reads as the add-on having lost them.

**Never hook `MailFrame`'s `OnHide` to close the window.** It breaks twice over: mail-replacement add-ons hide `MailFrame` and show their own, killing the window the instant it opens, and `SendWho` raises the Who panel, which the UIPanel system swaps in over `MailFrame`, so pressing Find Recipients would close the window mid-query. Track the mailbox itself through `ns.AtMailbox()` instead.

## Diagnostic Tools

`Features/Diagnostics.lua` plus `Options/Options-Diagnostics.lua` provide a gated panel at **Options > AddOns > Play It Forward > Diagnostic Tools**: environment probing and state capture for bug reports, not unit tests. State lives in `ns.diagnostics` (`{ enabled, logging, log }`), a plain namespace table that is never a SavedVariable, so it defaults off and resets every session. Reports build only on a button press.

The framework — event log, event registration, API endpoints, installed add-ons, saved variables, library versions, taint log — is the shared one. What is re-authored per add-on is the manifests and the context probes:

- **Bag Scan** — every occupied slot with its verdict or its reject code. The rejected rows are the point.
- **Recipient Roster** — everyone `/who` has found, with fairness state, what each qualifies for, and what the parser discarded.
- **Item Verdict** — one pasted link, with both stat sources side by side so a parse failure is visible as one rather than as a low score.
- **Class Groups** — the derived armor and weapon priority tables at a given required level.
- **Outgoing Mail** — the exact subject and body a stranger receives, with lengths.
- **Mail Window** — `ForceShow`: drops the saved position, re-centers, re-reads the bags, and reports what it found, which separates an off-screen window from an empty one.
- **Recipient History** — the one control here that writes saved variables, so it is confirm-gated.

`ns.DIAGNOSTIC_EVENT_EXCLUDE` holds `BAG_UPDATE` and `GET_ITEM_INFO_RECEIVED`. Both are registered and both are firehoses, and either would bury the mailbox and `/who` events past the 500-entry cap.

`ns.DIAGNOSTIC_API_CHECKS` carries a row per API reached through a compatibility guard plus the load-bearing calls, and three rows that feed literal strings to `Tooltip:StatsFromLines`. Those three are regression guards rather than probes: a random-suffix roll arrives color-wrapped rather than bare, and when that form stops parsing every rolled green reads as statless and lands in the vendor pile while fixed-stat items carry on working — a failure that otherwise hides in plain sight.

## Saved Variables

One account-wide table, `PlayItForwardDB`, managed by AceDB-3.0 and created in the name-guarded `ADDON_LOADED` handler with `LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)`. Every setting lives under `profile`; there is no `global` subtable, since that scope is reserved for a minimap button this add-on does not have.

| Field | Holds |
|---|---|
| `showWelcome` | Print the login message. |
| `maxRarity` | Rarity cap; nothing above it is ever listed. Defaults to Uncommon. |
| `includeGear` | Offer bind-on-equip weapons and armor. |
| `includeConsumables` | Offer outgrown food, drink and potions. |
| `consumableLevelGap` | Levels past a consumable before it counts as spare. |
| `windowPos` | Dragged window position; its `point` field is what says the player moved it. |
| `recipients` | Fairness history, `name -> { level }`. |

**`recipients` is session-scoped.** It is wiped at every login, in the same `ADDON_LOADED` handler that creates the database, so the cooldown only ever spreads gifts out within one session. It lives in the profile rather than in a runtime table so the stock **Reset Profile** and the Diagnostic Tools **Clear History and Roster** button both reach it.

The rarity floor is **not** a setting. `ns.Data.MIN_RARITY` is a constant in `Data/Data.lua`; the cap above it is the one a player has a reason to move. It never applies to consumables, which return from the scanner before the rarity checks.

There is no migration chain and no `MIGRATION` tag anywhere in the add-on.

Retiring a setting does still need one line. AceDB physically copies scalar defaults into the saved table, and its cleanup only visits keys still present in the defaults — so a key removed from `ns.DATABASE_DEFAULTS` persists in every existing player's saved variables forever unless it is cleared explicitly at the init point in `Core.lua` (`ns.db.profile.oldField = nil`). That is a key removal, not a data migration, and takes no dated tag.

Defaults come from `ns.DATABASE_DEFAULTS` and are applied lazily by AceDB-3.0 via metatables — nothing is copied into the saved table, and explicit user values (including `false`) are never overridden.

There are no default item or spell lists, so no refill-on-empty logic. The giftable-item tables in `Data/` are static Lua and never enter saved variables.

## Adding a New Registered Event

1. Call `ns.on("YOUR_EVENT", handler)` from the feature file that needs it. Never create a frame — one would escape the diagnostics event-log tap.
2. That is the whole step. `ns.EVENT_NAMES` records it automatically, so the Diagnostics event probe picks it up with no second edit.
3. If the event is a firehose (many times per second, or once per item on a cold cache), add it to `ns.DIAGNOSTIC_EVENT_EXCLUDE` in `Features/Diagnostics.lua`, or it buries the 500-entry event log.

## Adding a New Giftable Consumable

1. Add a row to `ns.Data.FoodAndWater` in `Data/Food-And-Water.lua` or `ns.Data.Potions` in `Data/Potions.lua`, in the existing `{ id, quality, useLevel, restores }` shape, with a trailing `-- Item Name` comment.
2. `restores` must be `"HEALTH"`, `"MANA"`, or `"BOTH"`. Eligibility derives from it via `ns.Data.ConsumableClasses` — there is no per-item class list.
3. **A `useLevel` of 0 is rejected, not offered** (`NO_USE_LEVEL`). The column is the database's `RequiredLevel`, which is 0 for a good deal of food that is in practice endgame — banding on it leaves exactly one reachable recipient level. If the item matters, source a real usefulness level rather than shipping the zero.
4. If the row came from a database query, update the SQL comment above the array so the table stays regenerable. Don't reconstruct a query you don't have; leave the `-- TODO: Add SQL Query` marker instead. Both consumable files are SQL-sourced, so prefer re-running the query over hand-editing — and if you hand-edit, note it, or the next re-run silently undoes you.
5. `Features/Bag-Scanner.lua` stamps the source table's `form` (`FOOD` or `POTION`) onto the record. Rules in `Data/Item-Rules.lua` key on that form, which is what keeps a bottle of water from being treated as a mana potion.

## Adding a New Stat

1. Add the `GetItemStats` key to `ns.Data.StatMap` in `Data/Stat-Map.lua`, mapping it to an internal token.
2. Add the token to the point tables in `Data/Stat-Weights.lua`, on the documented 6-point scale. The gap between 2 (admitted, never leads) and 3 (enters the top bucket) is one point and it is categorical; a stat added at some other scale is silently misfiled.
3. **Weighting a stat is never only a scoring change.** See *Scoring: Claim, Fit and Coverage* — a new weight enlarges the coverage denominator on every item carrying that stat, and the majority test is strictly greater than half. Check `Tests/Stat-Scoring.lua`, which pins the scale against `CLASS_SHARE`.
4. If the stat renders only as tooltip text with no `ITEM_MOD_` global behind it (per-school spell damage, for example), add it to `ENUS_FALLBACK` or `EQUIP_PATTERNS` in `Features/Tooltip-Scanner.lua`. Order matters there: the more specific pattern must come first.
5. Never add anything to `ns.Data.UniversalWeights`. A weight landing on every class makes every class score on every item, which compresses the deliberate gaps between them.

## Adding a New Options Control

1. Add its key and default to `ns.DATABASE_DEFAULTS.profile` in `Data/Default-Settings.lua`.
2. Add the widget to `ns.BuildGeneralOptions` in `Options/Options-General.lua`, using the `ns.OptionsHeader` / `Desc` / `Spacer` / `SubHeader` constructors from `Options/Options-Utilities.lua`.
3. Add its strings to `Locales/enUS.lua`. Every user-facing string goes through `L["KEY"]`.
4. If the control changes what counts as giftable, call `refreshWindow()` from its setter. That routes to `UI:Rescan`, which re-reads the bags *and* re-plans the search.

## Localization

**Structure.** Locale files live in `Locales/<locale>.lua`, each registered through AceLocale-3.0's `NewLocale`. `enUS.lua` is the source of truth and the only file that passes the `true` default-fallback flag.

**Current state.** The add-on ships `Locales/enUS.lua` only. Adding and maintaining the rest of the locale set is the job of the Localization pass; the notes below describe the model that applies once they exist.

**Identity.** `Locales/enUS.lua` registers under the literal `"Play-It-Forward"` and `Data/Data.lua` reads `GetLocale(ADDON_NAME)`, where `ADDON_NAME` is the packaged folder name from `.pkgmeta`'s `package-as`. Those two must resolve to the same string. If they ever diverge, every localized string is `nil` with no load error — which looks like a blank UI, not a crash.

**Keeping locales in sync.** Every non-English file carries a translation of the same key set, and AceLocale falls back to English via `__index` for anything missing at runtime. Don't hand-edit other locales during ordinary work; a renamed key leaves harmless orphans in them until the Localization pass runs.

**Placeholders.** `%s`/`%d` count, type, and order must match `enUS` per key in every locale, or the string crashes at runtime. This is the highest-value invariant when editing strings.

**Spanish.** `esES.lua` and `esMX.lua` are two separate, self-contained files. Identical strings in both is correct and expected.

**Diagnostics strings are not localized.** They live in `ns.DiagnosticsStrings` in `Features/Diagnostics.lua` as plain English. That includes the `WHO_LABEL_*` query labels and `WINDOW_FORCED`, both of which are composed in feature files but read at call time from the namespace, because `Features/Diagnostics.lua` loads after them. The rule is decided by who reads the string, not where it is built.

**Locale overflow.** German is the usual canary. The mail body has a hard 500-character ceiling — the shipped English sits well under it, but a translation of the same four paragraphs can run longer, which is why `Dist:WarnIfOversized` stays even though `Tests/Mail-Contents.lua` already pins the English. This add-on writes no macros, so the 255-character macro limit does not apply.

**Zone names are not localized, and must not be.** `Data/Zones.lua` holds the strings the client's own `/who` parser matches. Running them through AceLocale would break the search. This is a known limitation on non-English clients — the search still terminates on the bare-level fallback, it just loses the zone filtering that makes it quick. See the note in that file for the uiMapID fix if it is ever taken on.

## Common Pitfalls

- **Calling `SendWho` outside a click handler**: silently blocked. No error, no event, just nothing. Every query rides a button press.
- **Using `UseContainerItem` with the Send Mail panel closed**: attaches nothing and *uses* the item instead. Check `SendMailFrame:IsShown()` before touching the item, never after.
- **Setting the mail subject before attaching**: the client overwrites an empty subject box with the item's name. Fill the panel after the attach.
- **Re-reading a bag slot on `MAIL_SUCCESS` to confirm delivery**: the slot still holds the old link at that instant. Every delivery reads as a skip, and no recipient goes on cooldown.
- **Gating on `MailFrame:IsShown()`**: TSM replaces the mail UI and the Who panel swaps `MailFrame` out, so it reports "closed" while the player stands at a mailbox. Use `ns.AtMailbox()`.
- **Hooking `MailFrame`'s `OnHide` to close the window**: breaks twice over — mail-replacement add-ons hide it on open, and `SendWho` raises the Who panel over it mid-query.
- **Dropping an in-flight `/who` instead of cancelling it**: `endQuery` is the only thing that restores `SetWhoToUi` and closes the Who panel, so a forgotten query leaves Blizzard's Who window appearing by itself seconds after the player closed ours.
- **Trusting `GetItemStats` on a random-suffix green**: it resolves the base item and returns empty. The tooltip is the only source for suffix stats, which is why `Features/Tooltip-Scanner.lua` is not optional.
- **Dropping `cleanLine` from the tooltip parser**: suffix and enchant stats arrive color-wrapped and newline-terminated, so they fail the `^%s*%+` anchor and every rolled green silently returns to the vendor pile.
- **Testing `classID == 2` to mean "weapon"**: shields and held off-hands are armor by class but rank on the weapon matrix. Use `ns.Data.UsesWeaponMatrix(item)`.
- **Reading a weapon key without checking `classID` first**: `WeaponKey` falls through to the weapon subclass table, and armor subclass 1 (cloth) collides with weapon subclass 1 (two-hand axe), so a cloth chest answers `2H_AXE`.
- **Reading `ns.db.profileKeys`**: always `nil`. AceDB keeps that table on `ns.db.sv`, and its metatable resolves only scope names, so the read fails silently rather than erroring — an own-alt check written against it passes everybody through.
- **Treating a consumable's `useLevel` of 0 as level 1**: it is the database's `RequiredLevel`, not the level the item is worth having. Banding on it gives 1 to `CONSUMABLE_RECIPIENT_GAP` against a recipient floor of 3, so the item can only ever reach a level-3 player. The scanner rejects those rows as `NO_USE_LEVEL` rather than offering them to nobody.
- **Rolling a random tiebreak inside a sort comparator**: `table.sort` throws when the comparator is inconsistent. The shuffle key is rolled once per player as they enter the pool.
- **Mutating the list `MatchList:Candidates` returns**: it is a cached table handed out by reference. Sorting or removing in place poisons it for every later caller until the pools generation changes.
- **Caching `MatchList:Items()` in a local**: `rescanBags` reassigns the table. Call the accessor each time.
- **Adding a stat weight and expecting only scores to move**: it changes the coverage denominator on every item carrying that stat, and can demote a class out of contention entirely.
- **Re-reading the bags at the end of a distribution run**: the client has not finished emptying the sent slots, so the scan finds delivered items and restores the pairing they were just sent under. `UI:_afterDelivery` re-assigns without scanning for exactly this reason.

## Contributing

**Issues** — [github.com/Gogo1951/Play-It-Forward/issues](https://github.com/Gogo1951/Play-It-Forward/issues).

**Bug reports** should include game version (Classic Era 1.15.x or TBC Anniversary 2.5.x) and locale, your class and level, repro steps, and the relevant output from the **Diagnostic Tools** panel (Options > Play It Forward > Diagnostic Tools). The Bag Scan and Item Verdict reports answer most "why isn't this item showing up" questions on their own.

**Discord** — [discord.gg/eh8hKq992Q](https://discord.gg/eh8hKq992Q).

**Pull requests:**

- Keep the scope tight. One concern per PR.
- Match the house style: tab indentation, StyLua defaults (no `.stylua.toml`), no abbreviations in names, all user-facing strings through `L["KEY"]`, diagnostics strings through `ns.DiagnosticsStrings`.
- Run `stylua`, `luac -p`, and `lua Tests/Run.lua` before pushing. The suite runs headless against a stubbed client and must stay green.
- New saved-variable fields seed defaults through `ns.DATABASE_DEFAULTS` and rely on AceDB's metatable application; never hand-merge or overwrite user values.
- Any change to saved-variable shape needs a dated `MIGRATION (remove after YYYY-MM-DD)` tag, and migration code is deleted when the window closes.
- Data-table edits keep the column-header comment and the SQL comment above the array; don't reformat existing rows.
- Update this document if the architecture or file map changes.

**Commit and PR descriptions require a User Story.** Don't just say "I changed X" or "I fixed Y." Frame the change in terms of who it helps and why:

**Format:** *As a [role], I [needed / wanted] [behavior] so that [outcome]. This change [does X].*

**Example:** *As a player who closed the mail window mid-search, I wanted Blizzard's Who panel to stop appearing by itself a second later, so that closing the window actually ended the search. This change marks an in-flight query canceled rather than dropping it, so its result still runs the cleanup that restores `SetWhoToUi`.*

The User Story makes review faster and gives future maintainers context the diff alone won't carry.
