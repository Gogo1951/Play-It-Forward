# Play It Forward // Notes

> Where Play It Forward departs from the Gogo1951 add-on Style Guide, kept so no review raises it again.

## Exceptions

### Diagnostics framework extensions

- **Departs from:** DIAGNOSTIC TOOLS → Live Reference, which copies Magic Eraser's `Diagnostics/` folder whole.
- **Instead:** keeps two additions to the copied framework: API Endpoints rows that say what they found, and report rows that take a typed input.
- **Why:** maintainer decision: these are upgrades the shared framework should carry, not drift to revert.

### Shared matching policy

- **Departs from:** DATA → Flavor Folders — no universal files.
- **Instead:** keeps the item-matching policy (the talent-tree stat weights, the item rules and the stat-name map) in shared `Data/` files every flavor loads, while the game facts that policy reads live in the flavor folders.
- **Why:** maintainer decision: matching policy is the add-on's own judgment of who an item suits, not game data, so it is the same on every client.

### English mail

- **Departs from:** LOCALIZATION, every string translated in every locale.
- **Instead:** `MAIL_SUBJECT` and `MAIL_BODY` stay English in every locale file.
- **Why:** The maintainer's choice.

### English-only equip and school-damage stats

- **Departs from:** GAME NAMES, never match against a name we typed in.
- **Instead:** reads "Equip:" stat lines and per-school spell damage lines off item tooltips by their English wording, so on other locales those stats go unread.
- **Why:** maintainer decision: the client offers no ID or global for those stats, and a per-flavor stats table built from IDs costs more than the scoring it would gain.
