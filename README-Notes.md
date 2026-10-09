# Play It Forward // Notes

> The maintainer's settled rulings for Play It Forward, kept so no review raises them again: exceptions to the Gogo1951 add-on Style Guide, and decisions it leaves open.

## Exceptions

### Diagnostics framework extensions
- **Departs from:** DIAGNOSTIC TOOLS → Live Reference, which copies Magic Eraser's `Diagnostics/` folder whole.
- **Instead:** keeps three additions to the copied framework: API Endpoints rows that say what they found, report rows that take a typed input, and zone rows in Validate Data.
- **Why:** maintainer decision: these are upgrades the shared framework should carry, not drift to revert.

### Shared matching policy
- **Departs from:** DATA → Flavor Folders — no universal files.
- **Instead:** keeps the item-matching policy (the talent-tree stat weights, the item rules and the stat-name map) in shared `Data/` files every flavor loads, while the game facts that policy reads live in the flavor folders.
- **Why:** maintainer decision: matching policy is the add-on's own judgment of who an item suits, not game data, so it is the same on every client.

## Decisions

- In the mail window, Consumables leads on the left with its Food, Drink, Potions and Scrolls ticks beneath it, and Gear sits on the right.
- Player-facing English uses the serial comma ("food, drink, potions, and scrolls"), matching the README.
- Every row in the mail window starts ticked: the tick means give this item away, so no row needs ticking again to be searched for, and an untick is remembered and never undone by a search or rescan.
- The mail a recipient receives, `MAIL_SUBJECT` and `MAIL_BODY`, stays English in every locale file; everything else the player reads is translated.
