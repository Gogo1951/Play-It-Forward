# Play It Forward // Notes

> Where Play It Forward departs from the Gogo1951 add-on Style Guide, kept so no review raises it again.

## Exceptions

### Diagnostics framework extensions

- **Departs from:** DIAGNOSTIC TOOLS → Live Reference, which copies Magic Eraser's `Diagnostics/` folder whole.
- **Instead:** keeps two additions to the copied framework: API Endpoints rows that say what they found, and report rows that take a typed input.
- **Why:** maintainer decision: these are upgrades the shared framework should carry, not drift to revert.

### One mail reset

- **Departs from:** SAVED VARIABLES → Reset, a Reset per player-editable text input.
- **Instead:** the Mail Message Text panel's one Restore Default button resets the subject and the body together.
- **Why:** maintainer decision: the subject and body are one message, so they are restored as one.

### English mail

- **Departs from:** LOCALIZATION, every string translated in every locale.
- **Instead:** `MAIL_SUBJECT`, `MAIL_BODY` and the `MAIL_POWERED_BY` footer stay English in every locale file.
- **Why:** The maintainer's choice.

### English-only equip and school-damage stats

- **Departs from:** GAME NAMES, never match against a name we typed in.
- **Instead:** reads "Equip:" stat lines and per-school spell damage lines off item tooltips by their English wording, so on other locales those stats go unread.
- **Why:** maintainer decision: the client offers no ID or global for those stats, and a per-flavor stats table built from IDs costs more than the scoring it would gain.

### Typed spec names where the client has none

- **Departs from:** GAME NAMES, never translate a game name.
- **Instead:** spec names come from the client wherever it can name them, and from the add-on's SPEC_* strings only where it cannot.
- **Why:** Classic Era, TBC Anniversary and WoW Forever offer no API that names another class's talent trees, and Season of Discovery's rune roles have no name in the game.
