# Design upgrade guide

This guide compares the current Flutter UI with the updated reference bundle in
[`docs/multi-shop-shopping-list-app/project`](multi-shop-shopping-list-app/project).
The primary references are `Component Library.dc.html`, `Flow Screens v2.dc.html`,
`Theme Reference.dc.html`, and `Motion & Interaction Spec.dc.html`.

The comparison is based on source code and the design export, not a pixel-level
running-app screenshot comparison. Treat the priorities below as the order to
implement and verify them.

## Current state

The interaction foundation is already in good shape. These design behaviours are
present and should be preserved while the visual composition changes:

- Checked-item animation, delayed movement to the Done section, collapse, and clear.
- Swipe-to-delete threshold, haptic feedback, delete affordance, and undo snackbar.
- Multi-select reveal animation and single-shop drag reordering.
- Quick-add roll-out, shop-aware placeholder, suggestions, glyph rotation, and
  new-row entrance feedback.
- Completion celebration and reduced-motion handling.
- Shared colour, typography, radius, and motion tokens.

The remaining work is mostly about matching the reference's custom layout and
finishing the secondary flows. The current app is not missing a wholesale
interaction rewrite.

## Metadata audit: the small details

The design contains several quiet labels, chips, and states that depend on data
outside the visible item fields. This is the checklist for those details. The
important distinction is whether the data already exists and is merely unused,
or whether the storage/API contract must grow.

### Already stored, but not shown

#### Item edit provenance

The edit sheet in [`item_sheet.dart`](../freshcart_flutter/lib/features/items/presentation/widgets/item_sheet.dart)
already receives the complete [`ShoppingItem`](../packages/freshcart_domain/lib/src/items/entities/shopping_item.dart).
The item carries `addedBy` and `createdAt`, and list members provide the author's
display name. Add an edit-mode metadata line such as `Added by Sam · 2 days ago`:

- Resolve `item.addedBy` through the current list's `memberFor` lookup.
- Format `item.createdAt` using the app's locale/time rules.
- Keep the line read-only and omit it for the add sheet.
- Add widget coverage for known member, unknown member, and a missing/old date.

This is presentation work. It does not need a new database column.

#### Checked-by and checked-at

`checkedBy` and `checkedAt` already cross the domain, mapper, Serverpod DTO,
and item service. The current list resolves the checker's name for the row, but
the sheet/details presentation does not yet consume the timestamp consistently.
Decide whether the reference wants a compact `Checked by ...` line in the sheet;
if so, wire the existing fields rather than adding another event table.

#### Item-name history and member avatar colour

Name history is already persisted for suggestions, and member avatar colours are
already persisted/snapshotted. The missing work is consuming name history in the
search UI and ensuring every avatar surface reads the stored colour rather than
falling back unnecessarily.

### Missing durable data

#### Last editor (`updatedBy`)

`ShoppingItem` has `updatedAt`, but ordinary edits do not store who made them.
Realtime [`ItemChange`](../freshcart_client/lib/src/protocol/items/models/item_change.dart)
messages contain `actorId`, but that actor is currently discarded by
[`item_realtime_source.dart`](../freshcart_flutter/lib/features/items/data/item_realtime_source.dart).

Choose the smallest contract that matches the product requirement:

- For a temporary remote-edit chip lasting a few seconds, preserve `actorId` in
  application state as ephemeral metadata; no schema change is needed.
- For a durable `Last edited by Sam · yesterday` line in the edit sheet, add
  `updatedBy` to the domain entity, Serverpod model, mapper, save operation, and
  migration. The server must derive it from the authenticated user, never from a
  client-provided value.

Do not infer the editor from `updatedAt` or the currently logged-in user.

#### Offline outbox and pending state

The design's dashed row edge and `Offline - changes will sync` status imply
durable offline writes. The current pending map in `items_controller.dart` only
tracks in-flight work in memory. It is lost on network failure, app restart, or
process termination.

Add a local outbox with at least:

```text
localId, listId, itemId, operation, payload, baseUpdatedAt,
createdAt, retryCount, state
```

Then add connectivity-aware retry, conflict handling using the existing
`updatedAt`, and row/status-bar state. This is client persistence, not a reason
to add fake server timestamps.

#### Per-list and notification preferences

**"Clear checked after shopping" — ✅ built, decisions #79.** The trigger is the
whole list becoming fully checked (the same moment the completion celebration
already detects), and the clear is silent — no card, no prompt.

List mute persistence already exists on the server, but Flutter cannot currently
read it back to initialise the settings control. Add the repository read path.
The four global notification choices, including reminder schedule, still need a
user preference record and API. Scheduled reminders additionally need local
notification scheduling, timezone handling, permission, and cancellation on
disable/sign-out.

### Missing query or derived data

- **Drawer counts — ✅ built, decisions #78.** One batched list-summary query
  (`ListService.summaries`), not a per-list item-collection fetch, exactly as
  scoped here.
- **Recently bought search — ✅ built, decisions #77.** Needed a new,
  unfiltered `recentNames` read path alongside the existing (filtered, floored)
  `suggestNames` one, not a reuse of it as-is — no new persistence, per the
  original call here, but the query shape was underestimated.
- **List-finished notifications:** detect the transition from incomplete to
  complete once, rather than notifying on every edit to an already-complete list.

### Presentation-only collaboration details

The design's remote-edit avatar chip and coloured row edge can use existing
member names/colours plus the realtime actor. Preserve the actor through the
application layer, mark the item as recently changed by that actor, and expire
the visual state after the reference duration. Presence captions such as
`Active 4 min ago` are a separate feature: membership currently has `joinedAt`,
but no last-active or viewing-session data. Treat presence as ephemeral stream
state unless the product explicitly needs durable activity history.

### Corrected status of avatar colour

The user's avatar colour is already persisted with a deterministic fallback. It
should not be planned as a new persistence feature; the remaining work is to
verify that profile, drawer, member, and item surfaces all use the stored value.

## Priority 0: list composition

These differences are visible on the main screen and should be handled first.

### 1. Replace stock shop chips with the designed shop tabs

**Current:** [`shop_filter_bar.dart`](../freshcart_flutter/lib/features/shops/presentation/shop_filter_bar.dart)
uses Material `FilterChip`s in a horizontal list. It hides the bar when no shops
exist, has no permanent add-shop pill, and does not couple horizontal swiping to
the content.

**Reference:** `ShopTabPill` uses custom active/inactive pills, an always-present
`All` tab, a permanent dashed `+` sibling, and a `TabBar`/content interaction.
The active shop pill is filled with the shop colour; inactive pills keep a small
shop-colour dot. Counts disappear at zero.

**Work:**

- Build a small custom tab-pill widget instead of styling `FilterChip` further.
- Keep the `+` action outside the tab selection model.
- Introduce a shared tab/page selection model so tapping and swiping update the
  same shop filter.
- Keep `All` available even when the list has no shops.
- Preserve the existing remaining-item count calculation.

**Acceptance check:** tapping each pill, swiping between shops, and using `+`
produce the same selected shop, visible items, active colour, and add-control
placeholder.

### 2. Scope shop tint to the list experience — ✅ done, decisions #73

`app.dart` is now permanently neutral (`AppTheme.brandSeed`); `list_detail_screen.dart`
wraps only its own `body:` in a local `AnimatedTheme` seeded from
`activeShopColorProvider(listId)`, so the `AppBar` and `drawer:` (siblings of
`body`, not descendants) never see the tint. `activeSeedColorProvider` — the
global provider both used to share — is deleted outright, along with the
dispose-time reset dance it needed. Covered by `list_detail_screen_test.dart`:
the body tints on selecting a shop, the drawer stays neutral once opened, and
returning to "All" returns the body to neutral.

### 3. Rebuild `ItemTile` as the reference `ProductRow` — ✅ done

`ItemTile` is now `InkWell` + `Row`, not `ListTile`. The row itself opens
editing when tapped; the leading circle is its own, independent tap target
that toggles checked (or selection, while selecting) -- a real behaviour
swap, not just a visual one, since checking used to be the row's own tap.
The permanent edit icon and note glyph are both gone; quantity always shows
(`x1` included, not just `>1`); the note is one truncated subtitle line.
Selected rows get the reference's `#F1F0EB`/dark-equivalent background and
8px radius; lifted (reordering) was already handled correctly at the
`ReorderableListView` level in `items_section.dart` and needed no change.

The checkbox itself is a new small widget, `_CheckCircle` -- replacing the
stock Material `Checkbox` (a rounded square, not the reference's 22px
circle) -- with the Component Library's own named "CheckCircle" states: a
340ms `easeOutBack` fill overshoot on checking, a plain reverse on
unchecking (same asymmetry `_strike`'s strike-through already used), tick
fading in behind the fill. Filled from `colorScheme.primary`, not the row's
own shop dot -- decisions #73's tint scoping is what makes that the correct,
context-aware colour to read.

Not built: the remote-edit/offline-pending row states from the same
component-library section. Those need real actor/outbox data the app
doesn't have yet -- Priority 1 item #7 below, deliberately not guessed at
here.

## Priority 1: visible flow gaps

### 4. Complete multi-select actions — ✅ done, decisions #75

`_buildActions` now offers Move alongside Delete, resolving decisions #53's own
stated blocker: "Move" needed the app's first shop-picker, and one already
exists (`ItemSheet`'s `ChoiceChip` row) since decisions #63/#64 landed after that
one was written. `ItemService.moveMany` reassigns a selection's `shopId` in one
transaction, same shape as `removeMany` (decisions #53's own reasoning: one
promise covering the whole selection, not a loop that can fail partway
through). Cancelling the sheet or a rejected write both leave the selection
exactly as it was -- verified by test, not just implied by the code.

### 5. Match the search state — ✅ done

The search field is now a bordered, rounded `TextField` (an `OutlineInputBorder`
at `AppRadii.input`) with a visible leading search icon, matching Flow Screens
v2's "Search, active" mockup exactly. The leading back-arrow is gone; "Cancel"
moved into the trailing actions slot instead, which is where the reference
actually draws it. The query controller/provider are untouched -- this was
presentation only.

### 6. Remove list-flow-only content that is absent from the reference — ✅ done

`UpgradeNudge` no longer renders above the shop tabs in the list body. The
account-linking prompt already has two real homes that predate this change --
`AccountCard` in Settings (decisions #56, always visible while anonymous, no
dismiss) and `UpgradeNudge` itself inside Edit profile -- so removing it from
the list body loses no reachable surface, just the one the reference never
drew there.

### 7. Add collaborative and pending-sync row states when the data supports them

The component library specifies a coloured edge/avatar chip for a recent remote
edit and a dashed edge for an offline-pending write. The current row has no data
for either state. First expose the smallest domain/application metadata needed
at the data boundary; then add the presentation state to `ItemTile`. Do not fake
these states from local timestamps.

## Priority 2: secondary surfaces

These are already described in [`design-gap-plan.md`](design-gap-plan.md); keep
that file as the detailed feature plan rather than duplicating all architecture
work here. Most of this list turned out to already be built by the time work on
it actually started — corrected below rather than left stale.

- **List settings** — ✅ fully built, decisions #69, #79. Member management
  opens the existing Household screen rather than being rebuilt inline; shop
  management and Leave/Delete are all reachable from here; the per-list
  "Clear checked after shopping" preference ships too.
- **Settings** — ✅ built. All four groups (Profile, Lists & shops, Preferences,
  About) exist on `SettingsScreen`.
- **Profile** — ✅ built. Stored avatar colour and photo both exist end to end
  (domain, server, `EditProfileScreen`'s picker), with the deterministic hash as
  the fallback for anyone who hasn't set one.
- **Appearance** — ✅ built, decisions #76. Theme mode, larger list text, and the
  read-only reduce-motion status row all live inline in Settings' Preferences
  group (no separate screen — nothing in the design requires one). Two bugs
  found and fixed alongside this, neither previously named anywhere: theme mode
  wasn't actually persisted, and the "Haptics" toggle was decorative (wired to
  nothing, while 7 real `HapticFeedback` call sites fired unconditionally) — now
  wired for real.
- **Drawer — ✅ built, decisions #65, #78.** Remaining count, member avatars,
  and inline New list / Join a list rows all ship.
- **Notifications:** still not built — add push preferences, per-list mute, and
  scheduled local reminders as a separately scoped dependency/permission task.
  The only piece of Priority 2 left, and the only one needing a new
  dependency.

## Suggested implementation order

1. ~~Add focused widget tests for the intended `ShopTabPill` states, then
   implement the custom shop tabs.~~ — ✅ done. `ProductRow`'s own states are
   still item 3 below.
2. ~~Move shop tint into the list subtree and verify navigation/chrome
   boundaries.~~ — ✅ done, decisions #73.
3. ~~Rebuild `ItemTile` geometry while retaining its existing gesture/animation
   controllers.~~ — ✅ done.
4. ~~Add Move, update search presentation, and relocate the upgrade nudge.~~ —
   ✅ done, decisions #75. Priority 1 is now only item #7 (remote/offline row
   states), deliberately last since it needs new data-layer work first.
5. Implement drawer counts and the secondary settings/list-settings flows from
   [`design-gap-plan.md`](design-gap-plan.md).
6. Only then add remote/offline row metadata and its visual states, because that
   work crosses the data and backend layers.

## Definition of done

- The primary list matches the reference in All, shop-selected, empty, search,
  multi-select, checked, and Done states.
- Shop colour affects list content and controls only, with neutral surrounding
  chrome.
- Tapping and swiping shop tabs stay synchronized.
- Item rows have no permanent edit affordance and show the reference quantity and
  note treatment.
- Move, search cancel, drawer counts, and settings destinations work on both
  success and failure paths.
- `flutter analyze` and the focused widget tests pass before the next design area
  is started.
