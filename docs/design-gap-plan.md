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
| Item-name suggestions (shared by the add control and Flow 06 search), per-list | Medium | ✅ Built for the add control — decisions #64. Search's own "Recently bought" UI still to come. |
| Unify the add/edit item sheet into one component | Small–Medium | ✅ Built — decisions #63 |
| Drawer: remaining count + member avatars per row, plus inline New list / Join a list | Small–Medium | ✅ Avatars + inline rows built — decisions #65. Remaining count still deferred (needs a per-list summary endpoint). |
| Settings: 4-group restructure | Medium | ✅ Built — Profile, Lists & shops, Preferences, About |
| Edit profile: user-chosen avatar colour | Small–Medium | ✅ Built — domain field, `ProfileService`, swatch picker on `EditProfileScreen` |
| Appearance screen (theme mode, larger text, reduce-motion status) | Medium | ✅ Built (inline in Preferences, not a separate screen — nothing in the design requires one). Theme mode is also now persisted; it wasn't before. |
| Notifications preferences (4 push toggles + per-list mute) | Large | Not built — one item needs local scheduled notifications, a new dependency |
| List settings screen (replaces Household; rename, members, per-list behaviour, shops, leave/delete) | Medium | ✅ Built, decision #69. "Clear checked after shopping" deliberately still missing, see §9. |

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

## 2. Item-name suggestions — one gap, needed by two flows — ✅ built for the add control, decisions #64

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

- ~~**Member avatars per row**~~ — ✅ built, decisions #65. A small overlapping stack of who else
  is on that list (capped at three, "+N" for the rest), from data the drawer's list-switcher
  already had (`ListsController`'s collection already carries `members`).
- ~~**Inline "New list" / "Join a list" rows**~~ — ✅ built, decisions #65. Reuse the same dialogs
  `ListsScreen` already opens, not a second copy.
- **Remaining count** ("6 left" / "All done") — still **not built**. Needs each list's own item
  counts, which the drawer does not currently fetch — a lighter per-list summary endpoint,
  ideally without each drawer open triggering N item-list fetches for N lists. Deferred as its own
  future backend piece rather than folded into the avatar/inline-rows pass.

## 5. Settings restructure — ✅ built

The design's four groups all exist on `SettingsScreen` now. Kept for the record of what each one
resolved to:

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

## 6. Edit profile: a user-chosen avatar colour — ✅ built

`AuthUser.avatarColor`/`avatarPhotoUrl`, the server's `ProfileService` and `profile_endpoint.dart`,
and `EditProfileScreen`'s swatch picker + photo upload all exist. `avatarColorFor` reads the
stored value once set, falling back to the deterministic hash otherwise, exactly as originally
scoped below.

## 7. Appearance screen — ✅ built (inline in Preferences, decisions #76)

Both pieces exist, plus the read-only status row:

- **Explicit theme-mode choice (Light/Dark/System)** — a `SettingDropdownOption` inside
  `PreferencesSection`, not a separate screen; nothing in the design requires one, and the app
  already had a `SettingDropdownOption` component that fits this exactly. Persisted with
  `shared_preferences` via `AppearanceController` — this was originally built in-memory only
  (picking Dark and relaunching silently reverted to System) and was fixed alongside this work,
  not a new gap.
- **"Larger list text"** — a persisted `shared_preferences` bool (`LargeTextController`) applied
  as a `MediaQuery` `TextScaler.linear(1.15)` override at the app root, only when on; off leaves
  the ambient (OS-level) scaler untouched rather than stacking on top of it.
- **"Reduce motion"** — a genuinely read-only row (`SettingStatusOption`, no `Switch` anywhere in
  it), reporting `AppMotion.reduced(context)` as "On"/"Off" text, per decisions above.

**Found, not planned, while building this:** the "Haptics" toggle already on `PreferencesSection`
was decorative — `value: true, onChanged: (_) {}` — while 7 real `HapticFeedback` call sites across
4 files fired unconditionally, gated by nothing. Unlike the two dead controls decisions #64/#69
removed outright, the capability here already existed and worked, so the fix was to wire the
toggle for real (a new `HapticsController`, default on to match every site's existing behaviour,
read at each call site) rather than delete it. See decisions #76.

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

## 9. List settings screen — ✅ built, decisions #69

Reached from a list's own header; **replaces Household** as the entry point (decision #69 kept
`HouseholdScreen` itself alive underneath — see its own "not a second copy" reasoning — rather
than rebuilding member management inline):

- Rename → already possible (`EditableListTitle`).
- Members row → opens the existing `HouseholdScreen`, not rebuilt inline.
- "Shops on this list" row → opens the existing `ManageShopsScreen`.
- Leave / Delete for everyone → both here and on `ListsScreen`'s own per-row menu, deliberately
  (that menu is still how you act on a list you are not currently inside).
- **Still deliberately missing:** "Clear checked after shopping" — the mockup's toggle, left out
  because "after shopping" isn't yet a real, defined moment in the domain (all items checked?
  every shop tab clear? something explicit a person taps?), and `ShoppingList` has no field for it.
  Needs an actual domain decision plus a migration, not a switch wired to a guess — see decision
  #69's own note. This is the one piece of §9 not yet built.

## Suggested build order

Cheapest/most-isolated first. The architectural question (shop-tint toggle) that would have held
up the Appearance screen is resolved — skipped — so nothing here is still blocked on a decision.

1. ~~**Add-control polish** (§1)~~ — ✅ built, decisions #62.
2. ~~**Unify the item sheet** (§3)~~ — ✅ built, decisions #63.
3. ~~**Item-name suggestions** (§2)~~ — ✅ built, decisions #64. The add control's chips read
   from it now; Flow 06's "Recently bought" is unblocked but not itself built yet.
4. ~~**Drawer enrichment** (§4)~~ — ✅ member avatars + inline New list / Join a list built,
   decisions #65. Remaining count still deferred, needs its own summary endpoint.
5. ~~**Edit profile + stored avatar colour** (§6)~~ — ✅ built.
6. ~~**List settings screen** (§9)~~ — ✅ built, decision #69. "Clear checked after shopping"
   still deliberately missing, needs its own domain decision.
7. ~~**Settings restructure** (§5)~~ — ✅ built.
8. ~~**Appearance screen** (§7)~~ — ✅ built, decisions #76 (inline in Preferences, plus a
   pre-existing persistence bug and a decorative Haptics toggle found and fixed alongside it).
9. **Notifications preferences** (§8) — the largest remaining piece, and the only one needing a
   new dependency (local scheduled notifications) — do this last, and possibly split "list
   finished" push + per-list mute from the local-notification scheduler as two separate phases.

Three smaller items are still open, each deliberately deferred rather than forgotten: the
drawer's remaining count (§4, needs a summary endpoint), "Clear checked after shopping" (§9,
needs a real domain decision), and Flow 06's "Recently bought" search UI (§2, unblocked by the
suggestions backend but not itself built).
