# Design gap plan — Flows 09–10

The design bundle in `docs/multi-shop-shopping-list-app/` was re-exported on 2026-09-11 with two
new flows that did not exist when phases 0–12 (`docs/build-plan.md`) were scoped: **09 — The add
control** and **10 — Drawer, settings & preferences**. This doc is the gap analysis: what the
design now wants, what the app already has, and what is left to build to close the difference —
written *before* any of it is built, per `CLAUDE.md`'s "plan before you build" rule. Every open
question it originally raised was put to Nikolaos directly and is resolved below (§ Decisions) —
this is no longer a planning doc waiting on answers, it is ready to build from.

Source read for this doc: `Flow Screens.dc.html` (visual spec for both flows, in full), the
interactive prototype `Shopping List App.dc.html`'s state machine (confirms `profile`,
`list-settings`, `notifications`, `appearance` are real intended screens, not just illustrations,
and its `history`/`suggestions` logic, `keepChecked`/`haptics`/`tintTabs`/`largeText` flags), and a
diff of the bundle's `app_theme.dart`/`app_colors.dart`/`app_motion.dart` against the app's own —
no new design tokens, colours, or motion values were added; everything below is new *screens and
behaviour*, not new visual language.

## At a glance

| Area | Size | State |
| ---- | ---- | ----- |
| Add control polish (shop-tinted placeholder, leading dot, glyph state, entrance flash) | Small | ✅ Built — decisions #62 |
| Item-name suggestions (shared by the add control and Flow 06 search), per-list | Medium | Not built — new capability |
| Unify the add/edit item sheet into one component | Small–Medium | ✅ Built — decisions #63 |
| Drawer: remaining count + member avatars per row, plus inline New list / Join a list | Small–Medium | Not built |
| Settings: 4-group restructure | Medium | Not built (current screen is one card) |
| Edit profile: user-chosen avatar colour | Small–Medium | Not built — **domain change** |
| Appearance screen (theme mode, larger text, reduce-motion status) | Medium | Not built — no shop-tint toggle, see decisions |
| Notifications preferences (4 push toggles + per-list mute) | Large | Not built — one item needs local scheduled notifications, a new dependency |
| List settings screen (replaces Household; rename, members, per-list behaviour, shops, leave/delete) | Medium | Mostly relocating what exists, plus one new toggle |

## Decisions

Put to Nikolaos directly on 2026-09-11; these override anything the sections below still phrase
as an open question.

1. **Drawer create/join rows** — **add them.** Create/join now live in both the drawer and
   `ListsScreen`, accepting decisions #50's original "two places" cost because the design now
   draws them explicitly.
2. **Shop-tint toggle** — **skip it.** Per-shop dynamic theming stays always-on, not an optional
   preference. The Appearance screen does not get this row.
3. **"Reduce motion"** — **read-only status**, not a toggle. It shows what `AppMotion.reduced`
   already reads from the OS; it must not render as an interactive switch, since there is nothing
   for tapping it to do.
4. **"Keep checked items" vs. "Clear checked after shopping"** — **one preference, not two.** The
   global Settings toggle is dropped; the per-list "Clear checked after shopping" (§9, List
   settings) is the one that ships.
5. **List settings vs. Household** — **List settings replaces Household.** Household's members
   list, roles, invite, remove/transfer all move into List settings' "Members" group; Household
   as a separate screen goes away.
6. **"Manage lists" row in Settings** — **links to the existing `ListsScreen`**, not a new screen.
7. **Item-name suggestion scope** — **per-list**, not household-wide. Matches how shops are
   already scoped to one list (decisions #19).

## 1. The add control (Flow 09) — ✅ built, decisions #62

The core mechanic — a resting circle that rolls into a full-width field, the `+`/`×` glyph
rotation, Enter-commits-and-stays-open vs. tap-opens-the-sheet — is already built
(`QuickAddBar`, decisions #58–#59) and matches the design closely. What is new in this re-export
is the polish around it:

- **Shop-tinted placeholder.** Resting and rolled-open, the field/FAB should read "Add to
  Colruyt" (or whatever shop tab is active), not the generic "What do you need?" it shows now.
  On the "All" tab it stays generic. `QuickAddBar` already knows the active shop indirectly
  through the app's theme (`theme.colorScheme.primary` already *is* the active shop's colour,
  decisions #32), but it does not currently know the shop's *name*, needed for the placeholder
  text — that has to come from `ShopFilterBar`'s already-existing `activeShopColorProvider`
  neighbourhood, resolving a name alongside the colour.
- **Leading shop-colour dot inside the field**, matching the small dot already used in item rows
  and the shop filter chips — currently the field has no leading indicator at all.
- **Glyph background state.** Open and empty, the circular button should grey out (nothing to
  commit yet); the moment there is text, it re-fills with the shop colour. Today the button is
  always shop-coloured regardless of whether the field is empty.
- **New-row entrance.** A newly added row should scale in from 0.94 with a tinted flash fading
  over 900 ms, plus `lightImpact()` haptic feedback — not currently built; rows appear via
  whatever the list's normal insertion animation is.

None of this needs new domain concepts — it is presentation-layer work against data the app
already has (the active shop, its name and colour), except for the next item.

## 2. Item-name suggestions — one gap, needed by two flows

Flow 09's add control shows history chips ("Olive oil", "Olives", "Olive tapenade") once two
characters are typed, sourced from a flat list of past product names. Flow 06 ("Search &
suggestions", already flagged 🟡 in `build-plan.md`) wants the same thing for "Recently bought."
These are the same underlying capability wanted from two different screens, so it is designed
once — and scoped to one list at a time (decisions above), not the whole household.

**What it needs:** a way to answer "what product names has this list's history typed before, most
recent or most frequent first." **Checked against the current server model:**
`ItemService.remove`/`clearChecked`/`removeMany` all call `deleteRow`/`deleteWhere` directly — a
hard delete, no `isDeleted` flag — so a name's history disappears the moment the item is removed
or cleared, which is most items eventually. A real suggestions feature needs *some* record that
survives the item being deleted: a genuinely new small table (`item_name_history` or similar —
just a name, a list id, and a last-used timestamp, written to on every `AddItem` rather than
derived from `ShoppingItem` after the fact) is the smaller, safer piece of work, versus turning
`ShoppingItem` removal into a soft delete everywhere (a bigger, more invasive change with its own
consequences for every existing query).

**Shape of the work:** a new domain port method (e.g. `ItemRepository.suggestNames(query, listId)`
or similar), a server endpoint backing it (a `SELECT DISTINCT name ... ORDER BY last used`-style
query against the new table), and two small UI consumers (the add control's chip row, the search
screen's "Recently bought" section).

## 3. One item sheet, not two — ✅ built, decisions #63

The design's own note: *"The same sheet, titled Edit product and with a Remove action, is what a
row tap opens later — one component, two entry points."* Today the app has two separate
components: `AddItemSheet` (built this week, decisions #58) and `ItemEditorDialog` (built
earlier, for editing an existing row). They already do almost the same thing — name, quantity,
shop, note — so unifying them into one sheet with an `isEditing` mode (title text, a Remove
action, pre-filled fields) removes a duplicate surface rather than adding one. Worth doing before
the add control grows more fields (the suggestion chips, for one), so there is only one place to
add them.

## 4. Drawer

- **Remaining count + member avatars per row** ("6 left" / "All done", a small stack of who else
  is on that list) — a rendering change against data the drawer's list-switcher already has
  access to (`ListsController`'s collection already carries `members`; "remaining count" needs
  each list's own item counts, which the drawer does not currently fetch — it would need to read
  from wherever `ItemsController` or a lighter summary endpoint already knows this, ideally
  without each drawer open triggering N item-list fetches for N lists).
- **Inline "New list" / "Join a list" rows** — decided above: add them, alongside the existing
  entry points on `ListsScreen`.

## 5. Settings restructure

The current `SettingsScreen` is one card (anonymous vs. linked account, decisions #56). The
design wants four groups under one screen:

- **Profile row** at the top (avatar, name, "Joined \<date\>", Edit → a new Edit profile screen).
- **Lists & shops**: Manage lists (→ `ListsScreen`, decided above), Manage shops (with a count),
  Household — folded into List settings per the decisions above, so this row's destination
  changes from "open Household" to "open the relevant list's List settings," or this row drops
  entirely if there is no single list in context from Settings (worth a final look once List
  settings exists — Settings is not scoped to one list, so "Household" here may simply have no
  replacement and should be removed rather than repointed).
- **Preferences**: Appearance, Notifications, Haptics toggle. (No global "Keep checked items" —
  dropped per the decisions above; that preference now lives per-list in List settings only.)
- **About**: Help & feedback, Sign out, version footer.

The upgrade nudge (decisions #56) still belongs somewhere in here too, most naturally folded into
the profile row's area rather than kept as its own separate section.

## 6. Edit profile: a user-chosen avatar colour

Today a user's avatar colour is deterministic — `AppColors.avatarColorFor(userId)`, a hash into
the preset swatch list, so the same person is reliably the same colour everywhere without being
stored anywhere. The design's Edit profile screen lets a user *pick* their colour from the same
preset swatches shops use. **This is a real domain change, not styling:** `AuthUser` would need
a persisted colour field, a `SetAvatarColor`-shaped use case (mirroring `SetDisplayName`), a
server column/migration, and `avatarColorFor` would become "look up the stored colour, falling
back to the hash for anyone who has not set one" rather than always hashing. Every place that
currently calls `AppColors.avatarColorFor` (member rows, drawer, item "checked by" chips) would
read the stored value once it exists.

## 7. Appearance screen

Two things now, not three — the shop-tint toggle is not being built (decisions above):

- **Explicit theme-mode choice (Light/Dark/System).** `MaterialApp.router` already supplies both
  `theme` and `darkTheme`, so the app already *follows the system* by default — there is no
  current way for a user to pin Light or Dark regardless of the system, which is what this screen
  adds. Small: a persisted enum preference (`shared_preferences`, same tool as decisions #56) read
  into `MaterialApp.router`'s `themeMode`.
- **"Larger list text"** — a text-scale preference, most simply a `MediaQuery` `TextScaler`
  override applied at the app root, scoped conservatively (the design's own note is "easier to
  read at arm's length," not a full accessibility text-scale system).

Plus **"Reduce motion"** as a read-only status row (decisions above) — rendered without the
interactive switch styling the design mockup gives it, since there is no independent state behind
it to toggle; it just reports what `AppMotion.reduced` already knows.

## 8. Notifications preferences

Four named push toggles plus per-list mute:

- **"Someone adds an item"** (batched) and **"Someone joins a list"** — both map onto push
  triggers the server already has some shape of (decisions #37–#39); this is mostly exposing
  existing capability as a per-user setting rather than building new delivery.
- **"A list is finished"** — a new push trigger (server-side: detect "last item just got
  checked" and fire), not currently sent.
- **"Shopping reminder", "Saturdays at 10:00"** — this is a *scheduled local notification*, a
  fundamentally different mechanism from the other three (which are all server-push): it needs
  to fire from the device on a schedule the user sets, whether or not the app or even the network
  is reachable at the time. Needs a local-notification-scheduling package (e.g.
  `flutter_local_notifications`) — **a new dependency**, and its own platform permission flow on
  iOS/Android, distinct from the FCM permission already requested for push.
- **Per-list mute** — a small persisted per-user-per-list boolean. Natural home: alongside list
  membership (`ListMember`), or a lightweight preferences table keyed by user+list — needs
  a small domain/server addition either way, not just client-side state.

## 9. List settings screen

Reached from a list's own header, and — per the decisions above — **replaces Household**
entirely rather than coexisting with it:

- Rename → already possible (`EditableListTitle`).
- Members, "You · Owner" badge, remove/transfer, "Invite someone" → move here from
  `HouseholdScreen`, which is retired once this ships (its logic is not rebuilt, just relocated —
  the existing controller/use cases behind member management stay as they are).
- "Shops on this list" (count, opens shop management) → already exists as `ManageShopsScreen`,
  just needs a launch point here.
- Leave / Delete for everyone → already exist as actions on `ListsScreen`'s list menu; List
  settings becomes a second, list-scoped place to reach them (both stay, since `ListsScreen`'s
  own per-row menu is still how you act on a list you are not currently inside).
- **New:** "Clear checked after shopping" — a per-list toggle that, once on, asks to clear
  checked items once the list is complete rather than only ever clearing on an explicit tap. This
  is the one preference from the "keep checked / clear checked" overlap (decisions above) that
  actually ships.

## Suggested build order

Cheapest/most-isolated first. The architectural question (shop-tint toggle) that would have held
up the Appearance screen is resolved — skipped — so nothing here is still blocked on a decision.

1. ~~**Add-control polish** (§1)~~ — ✅ built, decisions #62.
2. ~~**Unify the item sheet** (§3)~~ — ✅ built, decisions #63.
3. **Item-name suggestions** (§2) — unblocks both the add control's chips and Flow 06's
   "Recently bought," so one piece of work closes two named gaps.
4. **Drawer enrichment** (§4) — remaining count/avatars, plus the now-decided inline
   New list / Join a list rows.
5. **Edit profile + stored avatar colour** (§6) — small domain change, self-contained.
6. **List settings screen** (§9) — retiring Household as part of the same change, since nothing
   downstream should keep pointing at a screen that is going away.
7. **Settings restructure** (§5) — once List settings exists, so its "Household" row has
   somewhere real to point (or is dropped, per §5's own note).
8. **Appearance screen** (§7) — theme-mode, larger-text and the reduce-motion status row; no
   longer has a held-back piece.
9. **Notifications preferences** (§8) — largest single piece, and the only one needing a new
   dependency (local scheduled notifications) — do this last, and possibly split "list finished"
   push + per-list mute from the local-notification scheduler as two separate phases.
