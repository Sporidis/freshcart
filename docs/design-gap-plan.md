# Design gap plan — Flows 09–10

The design bundle in `docs/multi-shop-shopping-list-app/` was re-exported on 2026-09-11 with two
new flows that did not exist when phases 0–12 (`docs/build-plan.md`) were scoped: **09 — The add
control** and **10 — Drawer, settings & preferences**. This doc is the gap analysis: what the
design now wants, what the app already has, and what is left to build to close the difference —
written *before* any of it is built, per `CLAUDE.md`'s "plan before you build" rule.

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
| Add control polish (shop-tinted placeholder, leading dot, glyph state, entrance flash) | Small | Not built |
| Item-name suggestions (shared by the add control and Flow 06 search) | Medium | Not built — new capability |
| Unify the add/edit item sheet into one component | Small–Medium | Not built (two components today) |
| Drawer: remaining count + member avatars per row | Small | Not built |
| Drawer: inline "New list" / "Join a list" | Small | Not built — **reopens decisions #50** |
| Settings: 4-group restructure | Medium | Not built (current screen is one card) |
| Edit profile: user-chosen avatar colour | Small–Medium | Not built — **domain change** |
| Appearance screen (theme mode, shop-tint toggle, larger text, reduce motion) | Medium–Large | Not built — **tint toggle affects a signature feature** |
| Notifications preferences (4 push toggles + per-list mute) | Large | Not built — one item needs local scheduled notifications, a new dependency |
| List settings screen (rename, members, per-list behaviour, shops, leave/delete) | Medium | Mostly relocating what exists, plus one new toggle |

## 1. The add control (Flow 09)

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
These are the same underlying capability wanted from two different screens, so it should be
designed once.

**What it needs:** a way to answer "what product names has this household typed before, most
recent or most frequent first" — the natural approach would be a distinct-names query over each
list's own item history (or the household's, across lists — see open decision below), reusing
`ShoppingItem` rows rather than a new table. **Checked against the current server model:**
`ItemService.remove`/`clearChecked`/`removeMany` all call `deleteRow`/`deleteWhere` directly — a
hard delete, no `isDeleted` flag — so a name's history disappears the moment the item is removed
or cleared, which is most items eventually. A real suggestions feature needs *some* record that
survives the item being deleted: either a genuinely new small table (`item_name_history` or
similar — just a name, a list/household id, and a last-used timestamp, written to on every
`AddItem` rather than derived from `ShoppingItem` after the fact), or turning `ShoppingItem`
removal into a soft delete everywhere (a bigger, more invasive change with its own
consequences for every existing query). The dedicated small table is very likely the smaller,
safer piece of work.

**Shape of the work:** a new domain port method (e.g. `ItemRepository.suggestNames(query, listId)`
or similar), a server endpoint backing it (likely a `SELECT DISTINCT name ... ORDER BY
last used`-style query, so no new migration if removals are already soft), and two small UI
consumers (the add control's chip row, the search screen's "Recently bought" section).

## 3. One item sheet, not two

The design's own note: *"The same sheet, titled Edit product and with a Remove action, is what a
row tap opens later — one component, two entry points."* Today the app has two separate
components: `AddItemSheet` (built this week, decisions #58) and `ItemEditorDialog` (built
earlier, for editing an existing row). They already do almost the same thing — name, quantity,
shop, note — so unifying them into one sheet with an `isEditing` mode (title text, a Remove
action, pre-filled fields) removes a duplicate surface rather than adding one. Worth doing before
the add control grows more fields (the suggestion chips, for one), so there is only one place to
add them.

## 4. Drawer

Two separate, differently-sized changes:

- **Remaining count + member avatars per row** ("6 left" / "All done", a small stack of who else
  is on that list) — a rendering change against data the drawer's list-switcher already has
  access to (`ListsController`'s collection already carries `members`; "remaining count" needs
  each list's own item counts, which the drawer does not currently fetch — it would need to read
  from wherever `ItemsController` or a lighter summary endpoint already knows this, ideally
  without each drawer open triggering N item-list fetches for N lists).
- **Inline "New list" / "Join a list" rows.** This directly reopens decisions #50, which
  deliberately kept the drawer to switching only and left create/join on `ListsScreen`, reasoning
  that the design showed no drawer state with them and duplicating the flow into a second widget
  would be two places to keep in sync for nothing. The new export explicitly draws them in the
  drawer. **Open decision:** add them to the drawer (matching the new design, accepting the
  "two places" cost) or keep drawer-is-switch-only and treat this frame as the design not yet
  reflecting the earlier call — this needs your steer either way, not a silent pick.

## 5. Settings restructure

The current `SettingsScreen` is one card (anonymous vs. linked account, decisions #56). The
design wants four groups under one screen:

- **Profile row** at the top (avatar, name, "Joined \<date\>", Edit → a new Edit profile screen).
- **Lists & shops**: Manage lists, Manage shops (with a count), Household.
- **Preferences**: Appearance, Notifications, "Keep checked items" toggle, Haptics toggle.
- **About**: Help & feedback, Sign out, version footer.

Mostly a restructure of existing destinations (Household, Manage shops already exist as screens;
"Manage lists" does not yet exist as its own screen — today creating/renaming/leaving/deleting a
list all happen from `ListsScreen` directly, not a dedicated management view, so this row either
opens `ListsScreen` or wants its own screen — worth confirming which). The upgrade nudge
(decisions #56) still belongs somewhere in here too, most naturally folded into the profile row's
area rather than kept as its own separate section.

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

Three things bundled in one screen, worth separating because they are different sizes:

- **Explicit theme-mode choice (Light/Dark/System).** `MaterialApp.router` already supplies both
  `theme` and `darkTheme`, so the app already *follows the system* by default — there is no
  current way for a user to pin Light or Dark regardless of the system, which is what this screen
  adds. Small: a persisted enum preference (`shared_preferences`, same tool as decisions #56) read
  into `MaterialApp.router`'s `themeMode`.
- **"Tint tabs with shop colours"** (on by default in the prototype's own state).
  **Open decision, and the biggest one in this doc:** per-shop
  dynamic theming (decisions #32, #7 in the original design docs, one of this app's headline
  portfolio features) becoming *optional* is a real architectural question, not a styling toggle
  — `AppTheme.forShop` is called from the router/app-shell level today assuming it always applies.
  Making it conditional needs a preference read at that same level, and a defined "off" state
  (falls back to the neutral `AppTheme.light/dark(AppTheme.brandSeed)` this app already uses for
  chrome, per `AppColors`' own doc comment) rather than a genuinely new theme. Confirm this is
  wanted before it is built — it is easy to build, but worth being a deliberate choice given what
  it is turning off.
- **"Larger list text"** — a text-scale preference, most simply a `MediaQuery` `TextScaler`
  override applied at the app root, scoped conservatively (the design's own note is "easier to
  read at arm's length," not a full accessibility text-scale system).
- **"Reduce motion"**, drawn as a toggle but captioned "Follows your system setting" — reads as
  a status display of `AppMotion.reduced` (which already exists and already reads the OS
  setting), not a real independent preference. Worth confirming it is not meant to be a manual
  override that can *diverge* from the OS setting before treating it as read-only.

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

Reached from a list's own header, distinct from Settings. Mostly relocating things that already
exist:

- Rename → already possible (`EditableListTitle`).
- Members, "You · Owner" badge, remove/transfer, "Invite someone" → all already exist on
  `HouseholdScreen`. **Open decision:** does "List settings" *replace* Household, wrap it as one
  of its sections, or do the two coexist as separate destinations reached from different places?
  The design draws members inline on this screen rather than pointing at a separate Household
  screen, which reads as "replace," but worth confirming rather than assuming.
- "Shops on this list" (count, opens shop management) → already exists as `ManageShopsScreen`,
  just needs a launch point here.
- Leave / Delete for everyone → already exist as actions on `ListsScreen`'s list menu; this adds
  a second place to reach them, or (if List settings replaces the relevant part of that menu)
  relocates them.
- **New:** "Clear checked after shopping" — a per-list toggle that, once on, asks to clear
  checked items once the list is complete rather than only ever clearing on an explicit tap. This
  is genuinely new behaviour, and it overlaps the global "Keep checked items" toggle in Settings
  (§5 above) — **open decision:** are these two independent preferences (a global default plus a
  per-list override), or does the design mean one and describe it twice from two different
  screens? Needs resolving before building either, so they do not end up fighting over the same
  behaviour.

## Suggested build order

Roughly cheapest/most-isolated first, and holding the one open decision with real architectural
weight (shop-tint toggle) for a deliberate go/no-go before touching the theming layer:

1. **Add-control polish** (§1) — small, self-contained, no domain changes.
2. **Unify the item sheet** (§3) — worth doing before anything else adds fields to either sheet.
3. **Item-name suggestions** (§2) — unblocks both the add control's chips and Flow 06's
   "Recently bought," so one piece of work closes two named gaps.
4. **Drawer row enrichment** (§4, the remaining-count/avatars half only — the inline
   create/join half waits on its open decision).
5. **Edit profile + stored avatar colour** (§6) — small domain change, self-contained.
6. **Settings restructure** (§5) — mostly wiring existing destinations into a new layout.
7. **List settings screen** (§9) — once its "replaces Household?" question is answered.
8. **Appearance screen** (§7) — theme-mode and larger-text pieces are safe to build immediately;
   hold the shop-tint toggle for its own explicit yes.
9. **Notifications preferences** (§8) — largest single piece, and the only one needing a new
   dependency (local scheduled notifications) — do this last, and possibly split "list finished"
   push + per-list mute from the local-notification scheduler as two separate phases.

## Open decisions, collected

Everything below needs your call before (or while) it is built — flagged inline above, repeated
here so none of them get missed:

1. **Drawer create/join rows** — add them (reopening decisions #50), or keep the drawer
   switch-only?
2. **Shop-tint toggle in Appearance** — make dynamic per-shop theming optional, or is this one
   frame of the export not meant to be taken literally?
3. **"Reduce motion" in Appearance** — a real manual override, or just a status readout of the OS
   setting (in which case it should not be drawn as an interactive toggle)?
4. **"Keep checked items" (global) vs. "Clear checked after shopping" (per-list)** — two
   independent preferences, or the same idea described twice?
5. **List settings vs. Household** — does List settings replace Household, wrap it, or do both
   screens coexist?
6. **"Manage lists" row in Settings** — its own new screen, or a link to the existing
   `ListsScreen`?
7. **Item-name suggestion scope** — per-list history, or household-wide across every list a user
   belongs to?
