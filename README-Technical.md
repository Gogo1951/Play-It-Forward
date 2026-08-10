# Play It Forward — Technical Reference

This document combines architecture notes and contribution guidance for developers working on Play It Forward. For end-user documentation, see [README.md](https://github.com/Gogo1951/Play-It-Forward/blob/main/README.md).

## File Map

```text
Play-It-Forward/
├── .github/
│   └── workflows/
│       └── package.yml           CurseForge release + library vendoring.
├── .gitattributes                LF normalization; identical in every add-on.
├── .pkgmeta                      Externals and ignore list.
├── LICENSE                       MIT.
├── Play-It-Forward.toc           Single TOC; dual interface (Classic Era, TBC Anniversary).
├── README.md                     Player-facing documentation.
├── README-Technical.md           This document.
├── README-Testing.md             Manual QA script.
├── Suffix.md                     Random-enchantment reference. Development only.
├── Data/
│   ├── Data.lua                  Locale init, ns.Data, flavor flags, palette, links, options registry.
│   ├── Default-Settings.lua      ns.DATABASE_DEFAULTS, the AceDB defaults table (profile + global.stats).
│   ├── Match-Stats.lua           Per-class stat point tables and the scoring constants.
│   ├── Match-Armor.lua           Native armor per class per level, the proficiency reach, universal equip slots.
│   ├── Match-Weapons.lua         Spec-count matrix per weapon type, plus proficiency level gates.
│   ├── Match-Rules.lua           Stat, form and weapon combinations that name their own class.
│   ├── Scan-Stats.lua            GetItemStats keys to internal stat tokens.
│   ├── Scan-Food.lua             Giftable food and drink (SQL-sourced).
│   ├── Scan-Potions.lua          Giftable potions (SQL-sourced).
│   └── Recipients-Zones.lua      Levelling zones per flavor and faction, for /who filtering.
├── Features/
│   ├── Core.lua                  Identity, AceDB lifecycle, central event dispatcher.
│   ├── Utilities.lua             Container API shims, frame templates, color accessors, number formatting, ns.QualifyPlayerName, ns.AtMailbox / ns.AtRest.
│   ├── Announcements.lua         ns:BuildBrandedLine and ns:PrintMessage, the only output path. Player-only.
│   ├── Scan-Tooltip.lua          Reads stats off a rendered tooltip, which is where suffix stats live.
│   ├── Scan-Bags.lua             Bag slot to giftable item record, or nil plus a reject code.
│   ├── Match-Derivations.lua     ns.Data answers over the Data/ tables: priority groups, weapon keys, rules.
│   ├── Match-Engine.lua          Eligibility, claim/fit scoring, coverage, verdict, candidate ranking.
│   ├── Match-List.lua            items / pools / assignedTo state, the rescan, and the allocator.
│   ├── Recipients-Who.lua        /who planning, chunking, throttling, result parsing.
│   ├── Recipients-Guild.lua      Second recipient source; activity window, own-alt and summon-alt filters.
│   ├── Recipients-Fairness.lua   Fairness history and this session's unreachable names.
│   ├── Mail-Sender.lua           Serialized, event-driven mailer.
│   ├── UI-Picker.lua             Scrolling dropdown widget, shared by the rarity, consumable-gap and recipient controls.
│   ├── UI-Window.lua             Frame, top-bar dropdowns, rows, rendering, and manual assignment.
│   ├── UI-Mailbox.lua            Search stepper, distribution glue, open/close behavior at a mailbox.
│   ├── Generosity.lua            Account-wide giving tally; RecordSend on each mailing, into global.stats.
│   ├── Generosity-Broadcast.lua  Shares the tally with nearby players over YELL addon messages; peers cache.
│   ├── Generosity-Tooltip.lua    Renders a player's Generosity totals at the bottom of their unit tooltip.
│   └── Diagnostics.lua           Report builders, manifests, event log, taint log.
├── Includes/
│   ├── Images/
│   │   └── Play-It-Forward.tga   Icon art.
│   └── Libraries/                Vendored: LibStub, CallbackHandler-1.0, AceLocale-3.0, AceDB-3.0,
                                  AceGUI-3.0, AceConfig-3.0 (Registry/Cmd/Dialog), AceDBOptions-3.0.
├── Locales/
│   └── enUS.lua                  Source of truth, and the only locale file this add-on ships.
├── Options/
│   ├── Options-Utilities.lua     Shared ns.Options* widget constructors, consumable-gap labels.
│   ├── Options-General.lua       ns.BuildGeneralOptions, the root panel; label-beside-control rows.
│   ├── Options-Profiles.lua      ns.BuildProfilesOptions, the stock AceDBOptions-3.0 table, unmodified.
│   ├── Options-Diagnostics.lua   ns.BuildDiagnosticsOptions, the Diagnostic Tools panel.
│   └── Options.lua               Panel registration, ns:OptionsPanelRoute, and the /pif slash command.
└── Tests/                        Headless suite, development only: 25 cases plus Run.lua, Harness.lua
                                  and Stub-WoW-API.lua.
```

There is no minimap button, so `Features/Minimap-Button.lua`, LibDataBroker-1.1 and LibDBIcon-1.0 are all deliberately absent. Don't reintroduce them.

`Suffix.md` and `Tests/` are development-only: neither is listed in the TOC, and nothing the player runs reads either. `.pkgmeta`'s ignore list is what keeps development-only files out of the player zip.

## Architecture

### Event Loop

`Features/Core.lua` owns one frame and one entry point, `ns.on(event, fn)`. Every registration goes through it; no feature file creates its own frame. `ns.EVENT_NAMES` accumulates as handlers register rather than being declared up front, because registration is flavor-conditional. The Diagnostics event probe reads that same list, so it can never test an event the dispatcher never took.

| Event | Registered in | Purpose |
|-------|---------------|---------|
| `ADDON_LOADED` | `Core.lua` | AceDB creation, fairness-list wipe, options registration. Name-guarded. |
| `PLAYER_LOGIN` | `Core.lua`, `UI-Mailbox.lua` | Welcome print; installs the `MailFrame` `OnShow` and `OnHide` hooks. |
| `MAIL_SHOW` / `MAIL_CLOSED` | `UI-Mailbox.lua` | Mailbox open/close on every flavor. |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` / `_HIDE` | `UI-Mailbox.lua` | The same signal, registered on every flavor except Era, where the interaction manager also reports it. |
| `BAG_UPDATE` | `Match-List.lua` | Marks the bag scan stale. |
| `GET_ITEM_INFO_RECEIVED` | `Match-List.lua` | Same, for an item the client has just resolved. |
| `WHO_LIST_UPDATE` | `Recipients-Who.lua` | A `/who` answer landed; parse and hand it to the callback. |
| `ADDON_ACTION_BLOCKED` | `Recipients-Who.lua` | Turns a blocked `SendWho` into an explanation instead of a BugSack popup. |
| `MAIL_SUCCESS` / `MAIL_FAILED` | `Mail-Sender.lua` | Advances the send queue. |
| `UI_ERROR_MESSAGE` | `Mail-Sender.lua` | Catches a refusal the server reports without either result event. |
| `GUILD_ROSTER_UPDATE` | `Recipients-Guild.lua` | Delivers a roster the add-on asked for. Ignored when no request is outstanding. |
| `CHAT_MSG_ADDON` | `Generosity-Broadcast.lua` | A peer's Generosity broadcast, or a ping to answer. Own prefix only. |
| `PLAYER_ENTERING_WORLD` | `Generosity-Broadcast.lua` | Broadcasts presence; the broadcast throttle absorbs the refire on every loading screen. |
| `PLAYER_UPDATE_RESTING` | `Generosity-Broadcast.lua` | The town gate opening. Walking into a city fires no loading screen, so this is what announces presence. |

The dispatcher's only addition is a single guarded call — `if ns.diagnostics.logging then ns:LogEvent(event, ...) end` — read before any allocation, so diagnostics off costs nothing.

### Debounced Bag Scanning

`BAG_UPDATE` fires on every loot, vendor sale and stack merge; `GET_ITEM_INFO_RECEIVED` fires once per item against a cold cache. Neither scans directly. `scanSoon` sets `bagsDirty` and then returns immediately unless the window is actually on screen — arming a two-second timer that will find the window closed is work done for nothing on nearly every one of those events. When the window *is* open the timer coalesces a burst into one scan, and re-checks that the window is still shown when it fires, since it can close inside the debounce.

Away from a mailbox the flag simply stays set, and the next `mailboxOpened` or `ForceShow` pays for one scan at the moment the answer is needed.

### Scan → Match → Search → Send

Four phases, each in its own file.

1. **Scan** — `Features/Scan-Bags.lua` walks bags 0–4. `Scanner:Classify` returns a finished record or `nil` plus a reject code (`NOT_CACHED`, `BIND_ON_PICKUP`, `LEVEL_GAP`, …). The codes are diagnostic identifiers, never shown to players, and exist so "why isn't this item listed" has an answer.
2. **Match** — `Features/Match-Engine.lua` produces one `verdict` per item: eligible classes, admitted classes, contenders, per-class claim/fit/coverage, and a state of `gift`, `leftover`, or `unreadable`. Everything downstream reads this one verdict rather than recomputing.
3. **Search** — `Features/Recipients-Who.lua` builds a plan of `/who` attempts and steps it one press at a time.
4. **Send** — `Features/Mail-Sender.lua` walks a job queue, one `SendMail` at a time, waiting on a result event before advancing.

`Features/Match-List.lua` holds the state the phases share (`items`, `pools`, `assignedTo`) and runs the allocator; `Features/UI-Window.lua` draws the result and `Features/UI-Mailbox.lua` drives the mailbox lifecycle around it.

### Item Data Caching

`GetItemInfo` returns `nil` for an item the client hasn't resolved. The scanner treats that as a `NOT_CACHED` rejection rather than a missing item, and `GET_ITEM_INFO_RECEIVED` marks the scan stale so the next open re-reads the bags. Without it a cold cache reads as an empty bag, and the window silently declines to open.

Stats are read twice and merged by taking the **max** per stat, never the sum: `GetItemStats` resolves the base item and ignores random suffixes, while the tooltip renders the item as the player sees it. Both report the same value on a fixed-stat item, so summing would double it. The merge is lossy, so `record.statRead` keeps each source's own answer for the diagnostics report.

A second cache covers candidate ranking. `MatchList:Candidates(item)` stores the ranked recipient list on the item, validated against a `poolsGeneration` counter. Ranking walks every admitted class against every pooled player and sorts the result, and the same answer is asked for repeatedly — once per allocation pass, once per dropdown open, and once per mouse-over of a recipient button, which is the one with no ceiling. The generation bumps in exactly one place, `AddResults`, and only when somebody new actually entered a pool, so a query returning nothing already known costs nothing; `rescanBags` needs no bump because it replaces every item table outright. Ranking reads only the pools and the item's own verdict and band — never `item.recipient` — so an assignment cannot stale a cached list. **The list is handed out by reference**: a caller that sorted or removed in place would poison it for everybody after.

Derived per-item data is cached under underscore-prefixed fields (`_weaponKey`, `_candidates`) to keep it out of the record's public shape.

### Scoring: Claim, Fit and Coverage

Three numbers per class per item, answering three different questions, and the separation is load-bearing.

- **Claim** (`Matcher:SpecScore`) — only the stats the point tables rank for that class. Decides who is *admitted*.
- **Fit** (`Matcher:Score`) — claim plus any universal weight and the `WEAPON_BASELINE` (0.15 × item level) that keeps a statless weapon placeable. Decides *ranking*.
- **Coverage** (`Matcher:Coverage`) — the share of the item's scoreable stats this class ranks at all, 0 to 1. Decides *breadth*.

Coverage exists because score sums, so breadth loses to a single large weight: on "of the Gorilla" a paladin scores 16 + 8 and a warrior 24 + 0, an exact tie the warrior wins with half the item dead on him. A class enters contention by clearing both `CLASS_SHARE` (0.35 of the best claim) and `COVERAGE_MAJORITY` (strictly more than half). Failing either leaves it admitted — still in the dropdown, still a fallback when nobody better is in range.

The denominator for coverage is *every stat some class ranks*, not the item's own stat line. That is why adding a stat weight is never only a scoring change: it enlarges the denominator on every item carrying that stat and can demote a class out of contention entirely.

**Coverage abstains when it demotes everyone.** It is a relative test, so a field where nobody clears the majority carries no information — an Agility and Spell Power roll, where the rogue ranks one half and the mage the other, leaves both at 0.5. Rather than empty the contender list, `Verdict` falls back to everyone who cleared `CLASS_SHARE` alone. An item with nothing scoreable on it returns a coverage of 1, not 0, for the same reason: those are placed by the weapon baseline, and a 0 would quietly bin every one of them.

### Verdict States

Three, not two. `gift` and `leftover` are the obvious pair; `unreadable` exists because an item whose random suffix failed to parse looks exactly like a worthless one, and telling a player to disenchant an item nobody actually evaluated is not reversible. An item is `unreadable` when it carries a suffix id and nothing parsed. Unreadable items are held out of auto-assignment entirely.

### Item Rules

The point tables in `Data/Match-Stats.lua` rank one stat at a time, and cannot say that a *pair* of stats together means something neither says alone. `Data/Match-Rules.lua` holds that second layer as `ns.Data.ItemRules`; `Features/Match-Derivations.lua` owns the matching. A rule matches on stats (`requires`, optionally `exclusive`), on a consumable's `form` plus what it `restores`, or on a weapon key — never a mix.

Three verbs, and they are not interchangeable:

| Verb | Effect | Timing |
|---|---|---|
| `veto` | Removes the class outright. The only absolute one. | Before anything is scored, so a vetoed class is gone from every answer downstream rather than filtered out of some. |
| `prefer` | Names the contenders, replacing what scoring chose. | After scoring. Narrowed to classes already admitted. |
| `demote` | Drops the class out of contention, keeping it admitted as a fallback. | After `prefer`, so a rule cannot promote a demoted class back. |

**Rules are soft by design.** A rule decides who is in *contention*, not who is *admitted* — everybody the weights allowed stays behind it as a fallback. An "of the Owl" staff still reaches a hunter when nobody else is in range. The one exception is `veto`, which is why there is exactly one in the table: Spirit against warlocks, which must outrank the Intellect a warlock genuinely wants, or "of the Owl" buys him back in through the half he can use.

The three verbs also differ in how many rules get a say. `prefer` is **first match wins**, so table order is data — only one combination can collide (Agility, Intellect and Spirit together) and the caster rule takes it. `veto` and `demote` accumulate across *every* matching rule, because a demotion names one class and one stat, and two can be true at once.

A rule may also carry `unclaimed = true`, which is a condition rather than a verb: it applies only when *no eligible class had a stat claim on the item at all* — the case `Verdict` calls `offerToEveryone`, where a statless weapon is placed by its level baseline and every admitted class scores identically. It pairs with `prefer` or `demote` and never with `veto`, which is applied before anything is scored and so could not answer the question. One rule uses it: an unclaimed bow, gun or crossbow is the hunter's, because all three of his trees build on the ranged slot and a warrior or a rogue carries one to pull with. A *stat-bearing* ranged weapon is still decided by the stats — an Agility bow is a rogue's as much as a hunter's — which is exactly why the condition is written on "unclaimed" and not on "ranged".

`applyDemotion` falls back **through the scoring, not past it**: it tries the contenders, then the scoring's own answer, then the admitted list, taking the first that is non-empty. Reaching straight for the admitted list would promote the classes coverage just demoted. That last resort exists for heavy armor carrying Intellect too far below its material's training level for `PROFICIENCY_REACH` to reach the hunter or shaman it was written for, which leaves nobody behind a warrior — the case that makes the Intellect rule a `demote` rather than a `veto`.

**`exclusive` measures against ranked stats only.** Armor and resistances sit on half the items in the game and are deliberately unweighted, so counting them would mean a bare Stamina ring qualified for the Stamina-alone rule where a bare Stamina chest did not.

### Recipient Ranking

`Matcher:RankCandidates` orders everyone in the pools who can use an item and sits in its level band. The keys, in order:

```text
fit bucket -> level proximity -> armor/weapon group -> class fit -> guild -> random
```

Bucket leads, so a class that genuinely wants the item beats one that barely does however close to equipping it they are. Level comes next, ahead of group, so a druid one level off beats a mage two off for cloth. The guild flag sits last before the coin flip: everything above it measures how well the item suits the person, so a guildmate never takes something from somebody it suits better — but it still decides often, since tier and fit are per-class and two candidates of one class at one level reach that line with nothing between them.

**Proximity is measured against opposite ends of the band for gear and consumables.** Gear anchors to the *top* — `[equipLevel - LEVEL_GAP_WIDEST, equipLevel - LEVEL_GAP_CLOSEST]`, so a level 19 sword goes to an 18 over a 17 and never reaches a 19, arriving just before it becomes useful. A consumable anchors to the *bottom*, its own use level, because its band runs upward from there; measuring it to the top would rank whoever has most outgrown a potion first, which is backwards.

**The band is per class, not per item.** `Matcher:LevelBand(item, class)` measures back from the level *that class* could first equip the item, which is the item's own requirement for nearly everything and later where the class has to train the armor material first — see *Armor Proficiency Reach* below. `RankCandidates` therefore filters each class's pool against its own band and never against a single pair of numbers stashed on the item; `item.bandLo`/`item.bandHi` are the union across everybody admitted, and exist for the tooltip and the reports only.

### Armor Proficiency Reach

`ns.Data.NativeArmor` says what each class wears at a given level, and its level gates were doing two jobs at once: "cannot wear this yet" and "is not who this is for". Only the first is true. A hunter trains mail at 40, so on a level 36 mail belt rolling nothing but Agility he was not eligible at all — and the belt went to a paladin, whose point weight on Agility is 2 against the hunter's 6. Blizzard itemizes the 35-to-39 mail and plate *for* the classes that train them at 40.

So a later training level moves the recipient band instead of closing the door. `ns.Data.ArmorEquipLevel` answers the item's own requirement, or the level the class trains the material, whichever is later; the priority group is computed at that level, so the hunter is group 1 for a level 36 mail belt exactly as he is for a level 40 one. The belt is then searched for at 38–39 for the hunter and 34–35 for the paladin beside him — `Matcher:BandGroups` splits the classes into one group per band, and `Who:Plan` takes them as separate attempts.

`ns.Data.PROFICIENCY_REACH` (5) is what keeps that honest: an item further below the training level than this reverts to being ineligible outright, because a level 20 mail belt is no gift to somebody who first equips it at 40. The training levels themselves are **probed off `NativeArmor`**, never listed a second time, so the 40s stay in one table.

This is armor only. `ns.Data.WeaponMinLevel` looks like the same gate and is not: druids never train polearms in Era or TBC, and that is written as a level 60 they cannot reach, so reaching for it would invent candidates for a proficiency that never arrives.

The random tail is a `shuffle` key rolled **once per player as they enter the pool**, never inside the comparator — `table.sort` throws on a comparator that changes mid-sort. Without it every spare green goes to whoever is early in the alphabet.

Two floors sit outside the ranking. `ns.Data.MIN_RECIPIENT_LEVEL` (5) is enforced in exactly one place, `MatchList:AddResults`, because that is the single door every recipient comes through — `/who` results, the guild roster, and anything added later inherits it without having to remember to. Levels 1 to 4 are where bank and profession alts sit. And `Fairness:PickFrom` runs two passes over the ranked list: first candidate both free and off cooldown, falling back to the first merely free, so an item is never stuck for want of a fresh face.

### Allocation

`MatchList:Assign()` rebuilds every pairing from scratch on each pass, against the whole roster. What survives is what the *player* decided — a row is `pinned` when they chose a recipient, kept the item, or unticked it. Rebuilding over a pin is the one thing the allocator must not do.

Items are handed out **scarcest first, then best first**. One item per person per pass makes this an allocation problem rather than a ranking one: an item two people can receive must pick before one fifty can, or the broad item takes one of the two and the narrow one gets nobody. An item nobody can receive sorts last, not first — zero is the impossible case, not the scarcest one.

When the pass leaves no gift still searching, `ns.Who:Clear()` drops the search plan; a plan left standing is a countdown over finished work. **Still searching means unmatched *or* held only by a fallback**: a pairing with a class outside the verdict's contenders keeps that item's band on the plan, narrowed to the contenders, so the hunt for the classes the item is actually for continues — and because every pass re-decides, a contender found later takes the item off its fallback. A pinned row is the player's decision and ends the search for that item.

**A fallback pairing arrives unticked.** `Assign` sets `send` only for a recipient whose class is in the verdict's contenders; a fallback shows on the row as a suggestion, and only the player's own tick (which pins the row) arms it for Distribute. Two paladins holding a pair of warrior swords is information; mailing them the swords is a decision.

## The Giving Tally

`Features/Generosity.lua` keeps an account-wide record of what this account has given away, in `ns.db.global.stats`: four integer counters — `gifts` (one per mailing), `items` (total quantity, so a stack of 20 counts as 20), `itemLevels` (summed for equippable gear only, consumables adding nothing), and `value` (vendor sell price times quantity, in copper). `ns.Generosity:RecordSend(link, quantity)` is the only writer, called from `Features/Mail-Sender.lua` beside `Fairness:Record` on each successful delivery — both the normal path and the in-flight-after-stop path. The stack size is captured in `Distributor:_next` *before* the attach and carried on the job as `_count`, because by `MAIL_SUCCESS` the bag slot is stale and would read as one. The General panel shows the four numbers read-only through `ns.Generosity:Get`; the share toggle and broadcast are the sharing feature below.

## Sharing the Tally (Proximity Broadcast)

`Features/Generosity-Broadcast.lua` shares the tally with nearby players and caches what theirs report; `Features/Generosity-Tooltip.lua` renders a peer's totals at the bottom of their unit tooltip. Blizzard removed custom addon channels in 1.13.3 and does not deliver addon whispers to non-social strangers, so `SAY`/`YELL` addon messages are the only sanctioned reach to nearby strangers. **This is why the feature is proximity-scoped: a peer sees your totals only when you are near them. A distant friend never appears — the honest limit, not a bug.** These are `C_ChatInfo.SendAddonMessage` calls, never `SendChatMessage`, so nothing here is player-visible chat and there is no target marker to add; Play It Forward stays player-only for actual chat.

The prefix is `ns.ADDON_MESSAGE_PREFIX` (`Data/Data.lua`, ≤16 characters), registered at load. The payload is versioned and pipe-delimited: a stats message is `1|S|<gifts>|<items>|<itemLevels>|<value>`, a ping is `1|?`. An unknown version or a foreign prefix is dropped. Peers are cached keyed `"Name-Realm"`, a realm-less sender qualified with the player's own realm — never filtered on the suffix, since Classic realms are all connected. A share-on account still broadcasts at zero gifts, so presence shows before the first gift.

A cached peer keeps its `GetTime()` stamp and is good for `PEER_MAX_AGE` (1800s). Past that `Generosity:Peer` reports them as never-heard-from, and the entry is dropped by a sweep on the next stats message received — the only point the table grows, so the cache is bounded without a timer. The span is deliberately long rather than tight: an expired entry can only be refilled by the tooltip's presence ping, which fires in a rest area alone, so a short window would make a peer standing beside you flicker out between hovers with no way back until you were both in town. `Generosity:AllPeers` still hands back the raw table for the diagnostics report, which prints each entry's age; a swept table simply shows fewer rows.

**Town only.** Every send and the tooltip block itself are gated on `ns.AtRest()` (`IsResting`, wrapped in `Features/Utilities.lua`), so the add-on puts nothing on the wire and adds nothing to a tooltip outside a city or an inn. Resting is a cheap, reliable proxy for "somewhere nobody is fighting", which keeps the feature clear of raids, dungeons and open-world combat without needing to reason about combat state. The gate is checked *before* the throttle on both outgoing paths — `Broadcast`'s own interval and the ping answer's — so nothing blocked out in the world consumes a window it never used, and arriving in town both broadcasts and answers the next ping immediately. Receiving is deliberately **not** gated — caching a peer costs nothing and leaves the data ready — which is also why the ping answer needs its own gate: unlike `Broadcast`, that path is reached out in the world. `ns.AtRest()` answers `false` when `IsResting` is missing: staying out of the way is the point of the gate.

Because walking from a field into a city fires no loading screen, `PLAYER_UPDATE_RESTING` is what announces presence on arrival; `PLAYER_ENTERING_WORLD` alone would leave a player silent until something else happened to send.

Three throttles keep a crowd from becoming a storm, all against `GetTime()`:

- **`BROADCAST_MIN_INTERVAL`** (60s) caps our own outgoing totals. It is also what guards the `PLAYER_ENTERING_WORLD` refire and the post-run broadcast in `Distributor:_finish` — both just call `Broadcast`, which no-ops if it fired too recently.
- **`PING_ANSWER_INTERVAL`** (30s) caps how often we answer a received ping, regardless of how many arrive.
- **`HOVER_PING_INTERVAL`** (10s, tooltip-side) caps how often hovering unknown players fires a presence ping.

**The tooltip block's shape is constrained, not styled to taste.** It opens with a blank line so it never reads as another line of whatever sits above it, then the branded header, then four indented rows. `ns:BuildBrandedLine` (`Features/Announcements.lua`) builds that header — the same blue name, gray `//` and white body a chat print carries — so the two surfaces cannot brand the add-on differently, and the locale string is the body word alone. **Values must be white**: the money row comes from `GetCoinTextureString`, which carries the client's own markup and ignores a color prefix, so coloring the other three anything else leaves that row visibly out of step. Labels are `HELP` silver rather than `TITLE` gold because gold field titles are the options panel's rule, where a caption sits beside a control the player acts on, and nothing in a readout is a control.

**Accepted latency:** in town, hovering a player you have never heard from shows nothing on the first pass and fires a ping; nearby clients answer, and the block is present on the next hover. A peer who has gone quiet for longer than `PEER_MAX_AGE` drops back to exactly that first-hover state, which is the intended reading — half an hour of silence is no longer evidence they are nearby. Your own tooltip shows your live tally, even at all zeros. Turning sharing off stops your broadcasts but not your view of others — you still see theirs. Outside a rest area none of this runs at all, which is the intended answer to "does this fire during a raid".

## /who Search Planning

`C_FriendList.SendWho` is hardware-event gated. A call outside the stack of a real click raises `ADDON_ACTION_BLOCKED` and does nothing — no error, no `WHO_LIST_UPDATE`. Queries therefore cannot be chained on a timer; each rides a button press.

**One class filter per query, never a list.** The client honors a single `c-"..."` and quietly drops the rest of an OR'd set — observed live on 1.15.9 (2026-07-23): a query carrying `c-"Paladin" c-"Rogue" c-"Warrior"` answered with paladins alone, the first filter alphabetically, and the pool filled with a class the item was not for. So a zoned query goes out class-unfiltered (the zones do the narrowing) unless exactly one class is wanted, and class filters are spent one class per query in the widened stage:

```text
16-19 z-"Westfall" z-"Loch Modan" z-"Duskwood"
16-19 c-"Warrior"
16-19 c-"Paladin"
16-19
```

Multiple `z-` filters are kept as a best effort: if the client honors only the first, the query still answers correctly from its first zone, and the per-class widening behind it is what the search actually relies on.

The plan widens in three stages per band — zones, then one query per wanted class, then bare levels — each giving up one constraint in the order that costs least. Bands are interleaved rather than run to exhaustion, so a bag holding a level 15 cloak and a level 45 sword makes progress on both. One item can contribute more than one band: `Matcher:BandGroups` splits its classes by the level each of them equips it at, so a level 36 mail belt plans a 38–39 attempt for the hunter and a 34–35 one for the paladin (see *Armor Proficiency Reach*). The filter string has a hard length budget (`FILTER_MAX`, 240): over it the server does not answer at all rather than truncating, so zone lists are chunked to fit.

**Zone order decides how many presses a search takes**, and `ns.Data.ZonesFor` sorts on three keys: overlap with the band, then *centrality* — how close the band sits to the middle of the zone's own range — then the narrower zone among equals. Centrality is the non-obvious one and it is the point: the edge of a zone's range is where people pass through, the middle is where they sit and quest, which is what puts a Horde 21-22 search in the Barrens first. Popularity is deliberately not a key, because there is no honest way to rank it from that table. An unresolved faction admits every zone rather than none — over-including costs one empty query, excluding on a nil answer silently drops half the list.

Three timing constants govern the stepper: `WHO_THROTTLE` (5s, which `UI:_lockFindButton` reads rather than duplicating), `RESULT_TIMEOUT` (6s, after which an unanswered query goes back on the *front* of the plan, since a blocked call never fires `WHO_LIST_UPDATE`), and the throttle running from the send rather than the answer — a reply often lands in under a second, and re-enabling then offers a press the server refuses for another four.

**`Who:Prune` only ever removes.** It narrows a plan already under way to the bands that still have somebody to find. Re-planning through `Who:Plan` instead would rebuild the queue from its best-first attempt and re-send what has already been asked, so a search that re-planned on each press would never get past its first zone. A survivor's class half is *intersected* with what the remaining bands want, never unioned, and an empty intersection drops the attempt rather than sending it unfiltered — which would be a wider query than the one being pruned.

A capped answer (`WHO_RESULT_CAP`, 50) is counted and otherwise ignored — the search stops once somebody in contention holds each item, so fifty names is already more than enough. The roster report reads that count, because a capped answer is the difference between a thin realm and a thin sample.

**The Who panel is deafened for the life of each query.** The stock UI opens the Who panel on `WHO_LIST_UPDATE` whenever results were routed to the UI list — and the panel is a UIPanel, so opening it over an open mailbox makes the panel manager close `MailFrame`, whose `OnHide` ends the mailbox interaction: pressing Find Recipients at a mailbox closed the mailbox. `beginQuery` unregisters `WHO_LIST_UPDATE` from the Blizzard frames that listen for it (the old WhoLib approach) and `endQuery` re-registers exactly those; hiding the panel after the fact remains only as a safety net, because by the time it fires the mailbox is already gone.

Two more pieces of cleanup ride on the answer rather than the request: `SetWhoToUi(true)` routes results to the list `GetWhoInfo` reads and is restored on the way out, in the same `endQuery`. That is why a query the player abandoned is marked `canceled` rather than dropped — the answer still lands, still restores the routing, and still gives the panel its ears back.

**A settings change re-plans.** `UI:Rescan` feeds the freshly merged bands to `ns.Who:Plan` before assigning, so raising the rarity cap or toggling Include Gear searches for what is on the list now rather than draining a plan built for the old one. Found players are kept either way; only the list of places left to look is rebuilt.

## The Guild Roster

A second recipient source, and on most realms the larger one. It costs no button press and no throttle, and answers for the whole guild at once — where `/who` is hardware-gated and returns at most `WHO_RESULT_CAP` (50) names per press. `Features/Recipients-Guild.lua` feeds `MatchList:AddResults` in the same shape `/who` results arrive in, so nothing downstream knows where a candidate came from except the one `guild` flag that earns guildmates their tiebreak in `Matcher:RankCandidates`.

`Guild:Request` is gated on a callback rather than reading on every event: `GUILD_ROSTER_UPDATE` fires constantly in a large guild — every login, logout, note edit and rank change — and walking hundreds of rows with a `GetGuildRosterLastOnline` call apiece on each one is work nobody asked for. With no request outstanding the event is ignored.

Four filters drop members, each counted separately so "the guild added nobody" and "the guild has nobody active" can be told apart in the roster report:

- **Unreadable class token** — the only outright discard, matching what the `/who` parser does with the same gap.
- **Your own characters** — checked first, since one of yours is one of yours at any level or recency.
- **Summoning alts** — a warlock parked in the band around where Ritual of Summoning unlocks. A range rather than the unlock level alone, since they drift a level or two before stopping. **This rule is the guild roster's alone**: the same character found by `/who` is left alone, because out in the world at that level they are somebody playing, and nothing can tell a parked alt from a real one except which list named them.
- **Inactivity** — anyone not seen within `Guild.ACTIVE_DAYS` (3). `GetGuildRosterLastOnline` returns nothing at all for a member who is online right now, and four separate duration components otherwise (years, months, days, hours), never a total. An offline member with no reading is treated as too old rather than recent enough: the roster arrives in pieces, and guessing "recent" on missing data mails gear to somebody who quit. Three days rather than a week because a guild of any size has far more eligible members than there are items to hand out, so the tighter window costs nothing.

There is deliberately **no level floor here**. The low levels are turned away for every source at once by `ns.Data.MIN_RECIPIENT_LEVEL` in `Features/Match-List.lua`; a second copy of that rule living in this file is how the guild floor and the consumable band drifted into each other the first time.

Own-character detection reads `ns.db.sv.profileKeys` — AceDB's record of every character that has loaded the add-on, keyed `"Character - Realm"`, rebuilt into a `"Character-Realm"` comparison key. **That table lives on `db.sv`, not on `db`.** AceDB's metatable resolves only scope names, so `ns.db.profileKeys` reads `nil` and the whole check silently passes everyone through. An alt that has never run the add-on is not in there and is not caught, which is the honest limit of the approach.

**Both sides of that comparison go through `ns.QualifyPlayerName`.** The roster spells a member on your own realm bare and suffixes only a character from another realm in the cluster, so keys built as `"Character-Realm"` matched no bare row and your own alts were handed your own gear. A bare name means "on my realm", which is the client's own convention, so the roster row is qualified before the lookup rather than the keys being stripped — stripping would collide two characters of one name on different realms in the cluster.

Names enter the pool exactly as the roster gave them, suffix and all. A name is an address: `SendMail` takes the full form, and rewriting it means mailing to an address the client never gave us.

**Identity is not the address.** `/who` answers with a bare name for somebody on your own realm where the roster qualifies the same character, so the two sources hand back different strings for one person. `MatchList:AddResults` therefore dedupes on `ns.QualifyPlayerName` (`Features/Utilities.lua`) rather than the raw name, while the pool entry keeps whichever spelling arrived first — the one an API actually produced. Pooling one person twice means mailing them twice, since `assignedTo`, the fairness cooldown and Distribute's own guard all key on that entry's name. A later sighting still contributes its `guild` flag to the entry already there.

## Mailing

`SendMail` cannot be looped. One send goes out, then the run waits for a result event before advancing. Mailing a non-friend arms Blizzard's confirmation popup; that popup is the anti-spam guard for mailing strangers and is never auto-clicked.

Three ordering constraints, all load-bearing:

- **Check the Send Mail panel before touching the item.** `UseContainerItem` only attaches while Blizzard's panel is visible. With it closed the identical call *uses* the item — a green raises "you must be level X", a consumable is simply drunk.
- **Fill the panel after the attach, never before.** Attaching writes the item's name into an empty subject box, so a subject set earlier is overwritten by the client's guess.
- **Never re-read the bag slot to verify delivery.** `MAIL_SUCCESS` fires before the bag update arrives, so the slot still holds the old link at that instant. Trust the event.

An attach can still fail with the panel up, and `SendMail` does not care — it posts an empty letter and reports success — so `GetSendMailItem(1)` is checked before every send.

**A send with no answer pauses rather than fails.** Every send arms a `RESULT_TIMEOUT` (30s) timer, because the confirmation popup can sit unanswered indefinitely. When it fires, the job moves to `_awaiting`, `busy` clears, and the player is told to click Accept and press Distribute again. `SendMail` has already gone out by that point, so a late Accept still delivers — which is why the job is held rather than dropped, and why `Distributor:_result` still records a delivery on a run that is no longer running. `Distributor:Stop` holds an in-flight job the same way. Nothing else clears `busy` inside that window, which is why `Features/UI-Mailbox.lua` stops the run outright when the mailbox closes.

`UI_ERROR_MESSAGE` is also watched: the server can refuse a send without firing either result event, and the refusal arrives as a UI error instead. The matching set is gathered from the client's own `ERR_MAIL*` globals rather than hardcoded English, so it works on any locale; strings carrying a format specifier are skipped, since they arrive with the placeholder already filled in and an exact comparison would never match. A name refused this way goes on `Fairness:MarkUnreachable` for the session.

The subject and body are fixed text from `Locales/enUS.lua` (`MAIL_SUBJECT`, `MAIL_BODY`), never saved settings — what a stranger receives cannot drift per profile or be rewritten into something the add-on would not have sent. `Distributor:WarnIfOversized` checks them against the client's limits (`SUBJECT_MAX` 31, `BODY_MAX` 500) at the start of every run.

## The Window

The window opens on the mailbox when the scan found anything worth acting on, and never auto-closes. `Features/Match-List.lua` holds items, roster and pairings at file scope, so matches survive walking away: come back and press Distribute.

Rows are sorted into four sections — matched, pending match, unreadable, kept — because the list runs longer than the window and the rows worth acting on would otherwise fall below the fold. Every row's dropdown lists *everybody* in range, because a name that silently vanishes reads as the add-on having lost them — and every one can be picked. The notes beside a name ("has one", "refused", "recent") are information, never gates: **the player's pick is never refused** (maintainer ruling, 2026-07-23). Picking a name that holds another row takes it from that row, which drops back to auto-assignment unpinned, so its search reopens. The list ends with a divider and **Find Recipients for This Item** — a targeted `/who` for that item alone. `Matcher:TargetedBands` puts the classes the verdict says the item is *for* at the front of the plan, so a lone contender becomes a query naming them: `38-39 z-"..." c-"Hunter"`, over that class's own band and the zones it passes through (maintainer ruling, 2026-08-09, replacing "admitted, since the point is more names"). Two or more contenders share their group with the fallbacks instead, because a query carrying two class filters is a query carrying none — splitting them would spend a press on a duplicate. The fallbacks keep their own group behind the leaders and are still asked for, a press later. It retasks the shared plan; the next fresh press of Find Recipients rebuilds the full plan for every item.

**Escape closes the window**, through `UISpecialFrames`. That only calls `Hide`, so everything that has to stop on a close — the picker, a running distribution, the query plan — hangs off the frame's `OnHide` rather than off the X button, and `UI:Close` calls the same `UI:_onClosed` for the window that was closed without ever being shown. Every line of it is idempotent, since pressing the X runs both routes.

**Never hook `MailFrame`'s `OnHide` to close the window.** It breaks twice over: mail-replacement add-ons hide `MailFrame` and show their own, killing the window the instant it opens, and `SendWho` raises the Who panel, which the UIPanel system swaps in over `MailFrame`, so pressing Find Recipients would close the window mid-query. Track the mailbox itself through `ns.AtMailbox()` instead.

## The Options Panel

### Opening the Panel

`ns:OpenOptionsPanel` in `Options/Options.lua` is the one entry point, and `/pif` does nothing but call it. Play It Forward is the Style Guide's reference for the combat guard on that opener, so the shape matters here.

**The combat gate is the first thing the function does**, in front of the whole routing chain rather than inside any one route. It prints `L["CHAT_OPTIONS_IN_COMBAT"]` and returns; it never queues, never registers `PLAYER_REGEN_ENABLED` to finish later, and prints every time the player asks, because a silent refusal reads as a broken command. Blizzard's Settings panel is protected in combat, so without the gate the player gets an `ADDON_ACTION_BLOCKED` error naming the add-on.

**The route is decided in exactly one place.** `ns:OptionsPanelRoute` returns `(route, insideOptions, description)` and the opener branches on that; the Diagnostics API row "Options panel opens inside the Blizzard interface" calls the same function rather than re-testing the same conditions, where a second copy of the branch would be free to drift and describe a route the add-on does not take. The order is modern, legacy, standalone.

**Never look the category up by name.** `AddToBlizOptions` returns `(frame, categoryID)` and both are captured at registration as `ns.GeneralPanel` and `ns.GeneralCategoryID`. AceConfigDialog overrides the category ID to the display name only on clients lacking `C_SettingsUtil.OpenSettingsPanel` — Era lacks it, TBC Anniversary has it — so a name lookup found nothing on exactly one flavor and the panel opened as a standalone floating window instead of docking. The legacy call is made twice: the first invocation selects the category, the second scrolls to it.

Registration itself is deferred. `ns:RegisterOptionsPanels` is called from the SavedVariables init point in `Features/Core.lua`, because the Profiles builder reads `ns.db` and registering at file scope would crash on load.

### Layout

AceConfig's flow layout is the source of every layout bug this panel has had, and two rules explain all of them.

**A row is a label cell plus a real control, and it needs a spacer behind it.** `ns.OptionsRowLabel` (a `description` at `ROW_LABEL_WIDTH`, 0.6) followed by a control at `ROW_VALUE_WIDTH` (2.0) fills exactly `ns.OPTIONS_ROW_WIDTH`, and a full-width spacer is what ends the row. Both builders in `Options/Options-General.lua` — `addFeedbackLinks` and `addGenerosityStats` — emit that spacer between pairs and not after the last one, which is where the gap before the next section would otherwise double.

**Two `description` widgets will not share a row.** Written without the spacer, four label/value pairs pack into the flow until it fills and the rows interleave into a jumble; GogoLoot never pairs two descriptions for this reason, always a description against an input or a select. The Generosity totals are text on both sides, so they depend entirely on the spacer to break each row.

**A toggle can be its own caption.** The two What to Give Away rows carry no label cell: the toggle sits at `ns.OPTIONS_LABEL_WIDTH` with its select beside it at `ns.OPTIONS_CONTROL_WIDTH`, and each select's *values* are self-describing ("Rare & Lower", "Outgrown by 20+ Levels") so nothing needs a caption. Those selects are **disabled, never hidden**, when their toggle is off — a hidden select leaves a gap the next toggle flows up into, pairing two toggles on one row.

The mail window's top bar carries the same two settings, built from one `buildDropdown` constructor in `Features/UI-Window.lua` so the pair cannot drift apart. It captions them ("Gear", "Consumables") because it has no toggles to borrow context from. Both surfaces read the same locale strings, and `UI:_syncControls` is the single refresh entry point — `Features/Core.lua`'s profile hook and the panel's own setters both call it, so a settings change can never refresh half the bar. `UI:_rarityPickerOptions` and `UI:_gapPickerOptions` are split from opening the pickers so `Tests/Options-Values.lua` can read the lists without a frame, and the gap picker compares `opt.gap == nil` rather than truthiness because **the All Consumables stop is a zero**.

## Diagnostic Tools

`Features/Diagnostics.lua` plus `Options/Options-Diagnostics.lua` provide a gated panel at **Options > AddOns > Play It Forward > Diagnostic Tools**: environment probing and state capture for bug reports, not unit tests. State lives in `ns.diagnostics` (`{ enabled, logging, log }`), a plain namespace table that is never a SavedVariable, so it defaults off and resets every session. Reports build only on a button press.

The framework — event log, event registration, API endpoints, display context, installed add-ons, saved variables, library versions, taint log — is the shared one. What is re-authored per add-on is the manifests and the context probes:

- **Bag Scan** — every occupied slot with its verdict or its reject code. The rejected rows are the point.
- **Recipient Roster** — everyone `/who` has found, with fairness state, what each qualifies for, and what the parser discarded.
- **Item Verdict** — one pasted link, with both stat sources side by side so a parse failure is visible as one rather than as a low score.
- **Class Groups** — the derived armor and weapon priority tables at a given required level.
- **Outgoing Mail** — the exact subject and body a stranger receives, with lengths.
- **Mail Window** — `ForceShow`: drops the saved position, re-centers, re-reads the bags, and reports what it found, which separates an off-screen window from an empty one.
- **Given Away Sharing** — `BuildGenerosityReport`: whether sharing is on, whether the player is resting, whether the message prefix registered, this account's four totals, and every nearby player heard from with the age of each entry. It answers "why don't I see anyone" — usually the resting line, since sharing is town-only, and otherwise because it reaches only players near you.

The panel writes nothing but the `taintLog` CVar, which keeps it to its read-only contract.

`ns.DIAGNOSTIC_EVENT_EXCLUDE` holds `BAG_UPDATE` and `GET_ITEM_INFO_RECEIVED`. Both are registered, both are firehoses that would bury the mailbox and `/who` events past the 500-entry cap, and — the part that earns an exclusion rather than a filter — **no instance of either is ever signal**: the Bag Scan export already prints the scan they triggered.

**A firehose that is *sometimes* signal gets the per-id filter instead.** `UI_ERROR_MESSAGE` and `CHAT_MSG_ADDON` are both registered and both mostly noise — every red combat error the client prints, and every other add-on's chatter in a city — but each also carries the one firing the add-on acts on: a mail refusal arriving as a UI error, and a peer's Generosity broadcast. Excluding them would hide exactly the entry a "the send failed" or "sharing doesn't work" report needs.

`ns.MESSAGE_ID_FILTERED_EVENTS` names those two and which argument position their id arrives in (1 for both: the message type, and the prefix). `ns:SuppressUncorrelatedMessage` runs inside `ns:LogEvent`, **at capture rather than at render** — filtering at display time still lets spam push real entries out of a bounded buffer. Three rules govern it:

- **Filter by what the add-on acts on, never by a denylist of noise.** Noise is unbounded, varies by class and activity, and renumbers across patches. Each rule's `correlated` predicate *calls the live handler's own test* rather than restating it — `ns.Distributor:IsMailError` for `UI_ERROR_MESSAGE`, a comparison against `ns.ADDON_MESSAGE_PREFIX` for `CHAT_MSG_ADDON` — so a drifted filter cannot make the log lie about what fired. `IsMailError` sits on the Distributor rather than file-local in `Features/Mail-Sender.lua` for that reason alone.
- **Count, don't delete.** Suppressed traffic aggregates per id as first-seen text plus a count and renders as one block at the end of the report, biggest offender first: `UI_ERROR_MESSAGE(56, Ability is not ready yet.) x469`. That block is also how a tester discovers an id the add-on *should* be correlating.
- **Unclassifiable is signal.** A firing with nothing at the id position is logged verbatim, and so is one with nowhere to count it — the filter never drops an entry it did not record. The counters live beside the buffer in `ns.diagnostics.suppressed` and are released with it in `ns:StopEventLog`.

`Tests/Event-Log-Noise.lua` pins all of it.

`ns.DIAGNOSTIC_API_CHECKS` carries a row per API reached through a compatibility guard plus the load-bearing calls — including `C_ChatInfo.SendAddonMessage`, `C_ChatInfo.RegisterAddonMessagePrefix` and `IsResting`, the three the broadcast needs; all target flavors ship them, so a FAIL there means sharing cannot register, send, or ever open its town gate. It also carries three rows that feed literal strings to `Tooltip:StatsFromLines`. Those three are regression guards rather than probes: a random-suffix roll arrives color-wrapped rather than bare, and when that form stops parsing every rolled green reads as statless and lands in the vendor pile while fixed-stat items carry on working — a failure that otherwise hides in plain sight.

A row marked `optional = true` reports ABSENT rather than FAIL when it answers false, so FAIL stays reserved for a client that is genuinely missing something the add-on needs. The `C_TooltipInfo` rows are the worked example: neither shipped flavor has them, and a row that always fails teaches the reader to skim.

## Saved Variables

One saved-variable table, `PlayItForwardDB`, managed by AceDB-3.0 and created in the name-guarded `ADDON_LOADED` handler with `LibStub("AceDB-3.0"):New("PlayItForwardDB", ns.DATABASE_DEFAULTS, true)`.

**The model is Simple** (Style Guide → SAVED VARIABLES → The Two Models): that third argument `true` is what puts every character on the shared `"Default"` profile, and it is the entire mechanical difference between the two models. **Reset Profile therefore wipes every setting back to install defaults** — but not the giving tally, which is the one thing held in `global` precisely so it survives (see below). That is the fact to know before adding a setting: a new user setting goes in `profile`, and only account-lifetime state earns `global`.

AceDB seeds both scopes from `ns.DATABASE_DEFAULTS` the same way, so neither needs init code — see *The defaults model* below for what "seeds" actually means, because it is not what the usual shorthand says.

| `profile` field | Holds |
|---|---|
| `showWelcome` | Print the login message. |
| `shareStats` | Broadcast this account's Generosity totals to nearby players. Off stops your own sends, never your view of theirs. |
| `maxRarity` | Rarity cap; nothing above it is ever listed. Defaults to Uncommon. |
| `includeGear` | Offer bind-on-equip weapons and armor. |
| `includeConsumables` | Offer outgrown food, drink and potions. |
| `consumableLevelGap` | Levels past a consumable before it counts as spare, as "at least this many". Defaults to 20, and must stay one of `ns.CONSUMABLE_GAP_ORDER` or the dropdown opens on a value it cannot show. **Zero is a sentinel, not a gap**: it is the "All Consumables" stop and lifts the level test outright, so items the player is under the level for are still offered. |
| `windowPos` | Dragged window position; its `point` field is what says the player moved it. |
| `recipients` | Fairness history, `name -> { level }`. |

**`recipients` is session-scoped.** It is wiped at every login, in the same `ADDON_LOADED` handler that creates the database, so the cooldown only ever spreads gifts out within one session. It lives in the profile rather than in a runtime table so the stock **Reset Profile** reaches it. There is deliberately no Recipient History control on the General panel: every login already makes everybody eligible again, so a button to do it by hand cleared nothing a reload would not.

**`global.stats` is account-wide and outlives Reset Profile.** It is the giving tally — a lifetime record that has to span every character on the account and survive a profile wipe, which is exactly why it sits in `global` rather than `profile`. Four integer counters, `value` in copper, all written only by `ns.Generosity:RecordSend`.

| `global.stats` field | Holds |
|---|---|
| `gifts` | Successful mailings; one per send. |
| `items` | Total quantity sent; a stack of 20 counts as 20. |
| `itemLevels` | Sum of item level, equippable gear only; consumables contribute 0. |
| `value` | Sum of vendor sell price times quantity, in copper. |

The rarity floor is **not** a setting. `ns.Data.MIN_RARITY` is a constant in `Data/Data.lua`; the cap above it is the one a player has a reason to move. It never applies to consumables, which return from the scanner before the rarity checks.

There is no migration chain and no `MIGRATION` tag anywhere in the add-on.

**The defaults model.** Defaults come from `ns.DATABASE_DEFAULTS` and are applied by AceDB-3.0 when a scope is first accessed — explicit user values, including `false`, are never overridden. Note that scalar and table defaults are physically copied into the saved table (`copyDefaults` via `rawset`); only `*`/`**` wildcard defaults resolve through metatables.

That distinction is worth being exact about, because the common shorthand for AceDB — "defaults are applied lazily via metatables, nothing is copied into the saved table" — is only true of the wildcards. `ns.DATABASE_DEFAULTS` uses none at all, so in this add-on every default takes the copying path. On the way out, `removeDefaults` strips back any key whose value still equals its default, so an untouched profile still saves as empty — which is what makes the shorthand look true from the outside.

Retiring a setting therefore needs one line. That cleanup only visits keys still present in the defaults, so a key removed from `ns.DATABASE_DEFAULTS` persists in every existing player's saved variables forever unless it is cleared explicitly at the init point in `Core.lua`. The live example is there now:

```lua
-- Deprecated: a setting no control ever reached, and a constant now as ns.Data.MIN_RARITY.
ns.db.profile.minRarity = nil
```

That is a key removal, not a data migration, and takes no dated tag.

There are no default item or spell lists, so no refill-on-empty logic. The giftable-item tables in `Data/` are static Lua and never enter saved variables.

## Adding a New Registered Event

1. Call `ns.on("YOUR_EVENT", handler)` from the feature file that needs it. Never create a frame — one would escape the diagnostics event-log tap.
2. That is the whole step. `ns.EVENT_NAMES` records it automatically, so the Diagnostics event probe picks it up with no second edit.
3. If the event is a firehose (many times per second, or once per item on a cold cache), it will bury the 500-entry event log, and which fix it gets turns on one question. If **no** instance of it is ever signal, add it to `ns.DIAGNOSTIC_EVENT_EXCLUDE` in `Features/Diagnostics.lua`. If it is *sometimes* signal — most of its traffic is noise but the add-on acts on particular firings — add it to `ns.MESSAGE_ID_FILTERED_EVENTS` instead, with the argument position its id arrives in and a `correlated` predicate that **calls the handler's own test** rather than restating it. Excluding a sometimes-signal event hides the one entry the report needed.

## Adding a New Giftable Consumable

1. Add a row to `ns.Data.FoodAndWater` in `Data/Scan-Food.lua` or `ns.Data.Potions` in `Data/Scan-Potions.lua`, in the existing `{ id, quality, useLevel, restores }` shape, with a trailing `-- Item Name` comment.
2. `restores` must be `"HEALTH"`, `"MANA"`, or `"BOTH"`. Eligibility derives from it via `ns.Data.ConsumableClasses` — there is no per-item class list.
3. **A `useLevel` of 0 is rejected, not offered** (`NO_USE_LEVEL`). The column is the database's `RequiredLevel`, which is 0 for a good deal of food that is in practice endgame. `Matcher:LevelBand` would band it at levels 1 to `CONSUMABLE_RECIPIENT_GAP` + 1, so 1–3 — entirely below `ns.Data.MIN_RECIPIENT_LEVEL` (5), which means no pooled player can ever fall inside it. If the item matters, source a real usefulness level rather than shipping the zero.
4. If the row came from a database query, update the SQL comment above the array so the table stays regenerable. Don't reconstruct a query you don't have; leave the `-- TODO: Add SQL Query` marker instead. Both consumable files are SQL-sourced, so prefer re-running the query over hand-editing — and if you hand-edit, note it, or the next re-run silently undoes you.
5. `Features/Scan-Bags.lua` stamps the source table's `form` (`FOOD` or `POTION`) onto the record. Rules in `Data/Match-Rules.lua` key on that form, which is what keeps a bottle of water from being treated as a mana potion.

## Adding a New Stat

1. Add the `GetItemStats` key to `ns.Data.StatMap` in `Data/Scan-Stats.lua`, mapping it to an internal token.
2. Add the token to the point tables in `Data/Match-Stats.lua`, on the documented 6-point scale. The gap between 2 (admitted, never leads) and 3 (enters the top bucket) is one point and it is categorical; a stat added at some other scale is silently misfiled.
3. **Weighting a stat is never only a scoring change.** See *Scoring: Claim, Fit and Coverage* — a new weight enlarges the coverage denominator on every item carrying that stat, and the majority test is strictly greater than half. Check `Tests/Stat-Scoring.lua`, which pins the scale against `CLASS_SHARE`.
4. If the stat renders only as tooltip text with no `ITEM_MOD_` global behind it (per-school spell damage, for example), add it to `ENUS_FALLBACK` or `EQUIP_PATTERNS` in `Features/Scan-Tooltip.lua`. Order matters there: the more specific pattern must come first.
5. Never add anything to `ns.Data.UniversalWeights`. A weight landing on every class makes every class score on every item, which compresses the deliberate gaps between them.

## Adding a New Item Rule

1. Add a table to `ns.Data.ItemRules` in `Data/Match-Rules.lua` with a `name` (developer-facing, never localized) and exactly one matcher: `weapon` for a list of weapon keys, `form` plus `restores` for a consumable, or `requires` for a stat list (optionally with `exclusive = true`). Give a rule two and only one applies — `matches` tests weapon first, then consumable, then stats, and returns on the first it finds rather than requiring all of them.
2. Pick the verb deliberately. `prefer` for "this is who it is for", `demote` for "not this class, but keep them as a fallback", `veto` only for "this class must never receive it". See *Item Rules* — the difference between `demote` and `veto` is whether the item still moves when nobody better is in range. Add `unclaimed = true` when the rule should only break a tie nothing else can break, i.e. when no class had a stat claim at all; it pairs with `prefer` or `demote` and never with `veto`.
3. **Position matters for `prefer` and only for `prefer`.** It is first-match-wins, so a new stat rule placed above an existing one silently takes items from it. `veto` and `demote` accumulate across every match, so their position is free.
4. A rule can only name classes scoring already admitted, so no rule needs an "unless it has caster stats" clause. A `prefer` naming nobody admitted strands nothing — it simply does not apply.
5. Add a case to `Tests/Item-Rules.lua` (or `Tests/Weapon-Rules.lua` / `Tests/Consumable-Rules.lua` by matcher type) and run `lua Tests/Run.lua`. Rule interactions are the part that does not survive being reasoned about — the veto-before-scoring and demote-after-prefer ordering both have tests pinning them.

## Adding a New Options Control

1. Add its key and default to `ns.DATABASE_DEFAULTS.profile` in `Data/Default-Settings.lua`.
2. Add the widget to `ns.BuildGeneralOptions` in `Options/Options-General.lua`, using the `ns.OptionsHeader` / `Desc` / `Spacer` / `RowLabel` constructors from `Options/Options-Utilities.lua`. A control needing a caption becomes a label-beside-control row — see *The Options Panel → Layout* for the widths and the spacer rule, both of which are load-bearing.
3. Add its strings to `Locales/enUS.lua`. Every user-facing string goes through `L["KEY"]`.
4. If the control changes what counts as giftable, call `refreshWindow()` from its setter. That routes to `UI:Rescan`, which re-reads the bags *and* re-plans the search.

## Localization

**Structure.** Locale files live in `Locales/<locale>.lua`, each registered through AceLocale-3.0's `NewLocale`. `enUS.lua` is the source of truth and the only file that passes the `true` default-fallback flag.

**enUS is the whole locale set.** `Locales/enUS.lua` is the only locale file, and that is a decision rather than a gap — the other ten are not to be created. Don't add one because a template or a stub generator asks for it. The notes below describe the model AceLocale would apply if that ever changed, and exist so a contributor who adds a second file knows what it commits them to; nothing in the shipped add-on depends on them.

**Identity.** `Locales/enUS.lua` registers under the literal `"Play-It-Forward"` and `Data/Data.lua` reads `GetLocale(ADDON_NAME)`, where `ADDON_NAME` is the packaged folder name from `.pkgmeta`'s `package-as`. Those two must resolve to the same string. If they ever diverge, every localized string is `nil` with no load error — which looks like a blank UI, not a crash.

**Keeping locales in sync.** Every non-English file carries a translation of the same key set, and AceLocale falls back to English via `__index` for anything missing at runtime. Translating each `enUS.lua` key and keeping the files aligned is the Localization pass's job; don't hand-edit other locales during ordinary work, and a renamed key leaves harmless orphans in them until that pass runs.

**Placeholders.** `%s`/`%d` count, type, and order must match `enUS` per key in every locale, or the string crashes at runtime. This is the highest-value invariant when editing strings.

**Spanish.** `esES.lua` and `esMX.lua` are two separate, self-contained files. Identical strings in both is correct and expected.

**Diagnostics strings are not localized.** They live in `ns.DiagnosticsStrings` in `Features/Diagnostics.lua` as plain English. That includes the `WHO_LABEL_*` query labels and `WINDOW_FORCED`, both of which are composed in feature files but read at call time from the namespace, because `Features/Diagnostics.lua` loads after them. The rule is decided by who reads the string, not where it is built.

**Locale overflow.** The mail subject and body have hard ceilings — `SUBJECT_MAX` (31) and `BODY_MAX` (500) — and both are measured with `#subject` / `#body`, so the unit is bytes. The shipped English sits well under each and `Tests/Mail-Contents.lua` pins it, but `Distributor:WarnIfOversized` stays because a test only measures the locale it was written for. Because the ceiling is in bytes, the canary for an overflow is whichever supported locale encodes widest — usually a Cyrillic locale such as ruRU, not automatically German. That is moot while enUS is the whole locale set, and is the first thing to measure if that ever changes. This add-on writes no macros and never calls `SendChatMessage`, so neither the 255-byte macro limit nor the 255-byte chat limit applies.

**Zone names are not localized, and must not be.** `Data/Recipients-Zones.lua` holds the strings the client's own `/who` parser matches. Running them through AceLocale would break the search. This is a known limitation on non-English clients — the search still terminates on the bare-level fallback, it just loses the zone filtering that makes it quick. See the note in that file for the uiMapID fix if it is ever taken on.

**Equip-effect parsing is English-only too.** `EQUIP_PATTERNS` in `Features/Scan-Tooltip.lua` matches the client's rendered "Equip: ..." wording, which vanilla builds from spell text rather than the `ITEM_MOD_*` globals. `Tooltip.equipPatternsUsable` gates it on `GetLocale()`, an API row reports the gate, and the Item Verdict report says so outright on a non-English client. A plain `+9 Intellect` line still parses anywhere, so an item misses a stat rather than scoring wrongly.

## Common Pitfalls

- **Calling `SendWho` outside a click handler**: silently blocked. No error, no event, just nothing. Every query rides a button press.
- **Using `UseContainerItem` with the Send Mail panel closed**: attaches nothing and *uses* the item instead. Check `SendMailFrame:IsShown()` before touching the item, never after.
- **Setting the mail subject before attaching**: the client overwrites an empty subject box with the item's name. Fill the panel after the attach.
- **Re-reading a bag slot on `MAIL_SUCCESS` to confirm delivery**: the slot still holds the old link at that instant. Every delivery reads as a skip, and no recipient goes on cooldown.
- **Dropping a job when the result timer fires**: `SendMail` has already gone out, so a late Accept still delivers. The job moves to `_awaiting` and `_result` credits it after the run has stopped.
- **Gating on `MailFrame:IsShown()`**: TSM replaces the mail UI and the Who panel swaps `MailFrame` out, so it reports "closed" while the player stands at a mailbox. Use `ns.AtMailbox()`.
- **Hooking `MailFrame`'s `OnHide` to close the window**: breaks twice over — mail-replacement add-ons hide it on open, and `SendWho` raises the Who panel over it mid-query.
- **Dropping an in-flight `/who` instead of cancelling it**: `endQuery` is the only thing that restores `SetWhoToUi` and closes the Who panel, so a forgotten query leaves Blizzard's Who window appearing by itself seconds after the player closed ours.
- **Re-planning a search mid-flight instead of pruning it**: `Who:Plan` rebuilds the queue from its best-first attempt, so a plan rebuilt on each press re-sends its first zone forever and never widens. `Who:Prune` only ever removes.
- **Trusting `GetItemStats` on a random-suffix green**: it resolves the base item and returns empty. The tooltip is the only source for suffix stats, which is why `Features/Scan-Tooltip.lua` is not optional.
- **Dropping `cleanLine` from the tooltip parser**: suffix and enchant stats arrive color-wrapped and newline-terminated, so they fail the `^%s*%+` anchor and every rolled green silently returns to the vendor pile.
- **Testing `classID == 2` to mean "weapon"**: shields and held off-hands are armor by class but rank on the weapon matrix. Use `ns.Data.UsesWeaponMatrix(item)`.
- **Reading a weapon key without checking `classID` first**: `WeaponKey` falls through to the weapon subclass table, and armor subclass 1 (cloth) collides with weapon subclass 1 (two-hand axe), so a cloth chest answers `2H_AXE`.
- **Reading `ns.db.profileKeys`**: always `nil`. AceDB keeps that table on `ns.db.sv`, and its metatable resolves only scope names, so the read fails silently rather than erroring — an own-alt check written against it passes everybody through.
- **Pairing two `description` widgets on one AceConfig row**: they do not lay out. The flow packs cells until a row fills, so four label/value pairs written without a full-width spacer behind each one interleave into a jumble. Every label-beside-value row needs its spacer; a label beside an input or a select is the only pair that can stand without one.
- **Hiding an options control instead of disabling it**: the widget after it flows up into the gap. Hiding the rarity select pairs "Include Gear" and "Include Consumables" onto one row.
- **Opening the options panel by category name**: `AddToBlizOptions` hands back a generated category ID on any client with `C_SettingsUtil.OpenSettingsPanel`, so a name lookup returns nil and the panel floats free instead of docking. TBC Anniversary has that API and Era does not, so the bug survives testing on one flavor. Route by the captured `ns.GeneralCategoryID`.
- **Coloring the Generosity values anything but white**: `GetCoinTextureString` ignores a color prefix, so the Gold Value row renders white regardless and any other color leaves it out of step with the three above it.
- **Comparing a roster or `/who` name as a raw string**: one player has two spellings. Both sources give a bare name for somebody on your own realm and a suffixed one for a character elsewhere in the cluster, so a raw comparison pools one person twice and lets your own alts past the own-character check. Compare `ns.QualifyPlayerName`; store and mail the name the client gave.
- **Treating a `consumableLevelGap` of 0 as an ordinary gap**: it is the "All Consumables" sentinel. Compared as a gap it still requires the player to be at or above the item's own level, so the one option meant to offer everything quietly withholds every consumable the player has not reached yet.
- **Treating a consumable's `useLevel` of 0 as level 1**: it is the database's `RequiredLevel`, not the level the item is worth having. Banding on it gives levels 1–3, which sits entirely below the level-5 recipient floor, so the item can never reach anybody at all. The scanner rejects those rows as `NO_USE_LEVEL` rather than offering them to nobody.
- **Rolling a random tiebreak inside a sort comparator**: `table.sort` throws when the comparator is inconsistent. The shuffle key is rolled once per player as they enter the pool.
- **Mutating the list `MatchList:Candidates` returns**: it is a cached table handed out by reference. Sorting or removing in place poisons it for every later caller until the pools generation changes.
- **Caching `MatchList:Items()` in a local**: `rescanBags` reassigns the table. Call the accessor each time.
- **Adding a stat weight and expecting only scores to move**: it changes the coverage denominator on every item carrying that stat, and can demote a class out of contention entirely.
- **Re-reading the bags at the end of a distribution run**: the client has not finished emptying the sent slots, so the scan finds delivered items and restores the pairing they were just sent under. `UI:_afterDelivery` re-assigns without scanning for exactly this reason.
- **Reordering `ns.Data.ItemRules`**: `prefer` is first-match-wins, so moving a stat rule above another silently takes items from it. `veto` and `demote` accumulate and do not care where they sit — which makes the table look more reorderable than it is.
- **Adding a recipient level floor to a new source**: there is one, in `MatchList:AddResults`, and it is the single door every source comes through. A second copy in `Recipients-Guild.lua` or `Recipients-Who.lua` is how the guild floor and the consumable band drifted apart the first time.
- **Deduping recipients on the raw name**: `/who` and the guild roster spell one same-realm player two different ways, so the raw string pools them twice and mails them twice. Compare `ns.QualifyPlayerName`; store the name the client gave.
- **Removing a key from `ns.DATABASE_DEFAULTS` and expecting it to disappear**: AceDB copies scalar defaults into the saved table and its cleanup only visits keys still in the defaults, so the orphan persists in every existing player's file. Clear it explicitly in `Core.lua`, as `minRarity` is.

## Contributing

**Issues** — [github.com/Gogo1951/Play-It-Forward/issues](https://github.com/Gogo1951/Play-It-Forward/issues).

**Bug reports** should include game version (Classic Era 1.15.x or TBC Anniversary 2.5.x) and locale, your class and level, repro steps, and the relevant output from the **Diagnostic Tools** panel (Options > AddOns > Play It Forward > Diagnostic Tools). The Bag Scan and Item Verdict reports answer most "why isn't this item showing up" questions on their own.

**Discord** — [discord.gg/eh8hKq992Q](https://discord.gg/eh8hKq992Q).

**Pull requests:**

- Keep the scope tight. One concern per PR.
- Match the house style: tab indentation, StyLua defaults (no `.stylua.toml`), no abbreviations in names, all user-facing strings through `L["KEY"]`, diagnostics strings through `ns.DiagnosticsStrings`.
- Run `stylua`, `luac -p`, and `lua Tests/Run.lua` before pushing. The suite runs headless against a stubbed client and must stay green.
- New saved-variable fields seed defaults through `ns.DATABASE_DEFAULTS` and are applied by AceDB; never hand-merge or overwrite user values.
- Any change to saved-variable shape needs a dated `MIGRATION (remove after YYYY-MM-DD)` tag, and migration code is deleted when the window closes. Retiring a key is the exception: it is a one-line `nil` at the init point in `Core.lua`, not a migration, and carries no tag.
- Anything that changes the mail subject or body needs its byte length re-checked against `SUBJECT_MAX` and `BODY_MAX` — see *Localization → Locale overflow*.
- Data-table edits keep the column-header comment and the SQL comment above the array; don't reformat existing rows.
- Update this document if the architecture or file map changes.

**Commit and PR descriptions require a User Story.** Don't just say "I changed X" or "I fixed Y." Frame the change in terms of who it helps and why:

**Format:** *As a [role], I [needed / wanted] [behavior] so that [outcome]. This change [does X].*

**Example:** *As a player who closed the mail window mid-search, I wanted Blizzard's Who panel to stop appearing by itself a second later, so that closing the window actually ended the search. This change marks an in-flight query canceled rather than dropping it, so its result still runs the cleanup that restores `SetWhoToUi`.*

The User Story makes review faster and gives future maintainers context the diff alone won't carry.
