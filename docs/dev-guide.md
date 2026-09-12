# Dev guide

Practical, day-to-day reference — not the rules (`CLAUDE.md`, `docs/architecture.md`) and
not the historical record (`docs/decisions.md`), but "what do I actually run, and what's the
trap I'll hit doing it." If something here and `CLAUDE.md`'s command cheatsheet disagree,
`CLAUDE.md` wins — this file exists to go deeper on things that cheatsheet doesn't have room
for, not to replace it.

## Seeing a widget without running the whole app

This codebase has dozens of `@Preview`-annotated functions (search `@Preview(` — every
screen and most standalone widgets have one). They're real Flutter tooling
(`package:flutter/widget_previews.dart`), not a custom harness, and nothing in this repo's
docs said how to actually open them until now:

```bash
cd freshcart_flutter
flutter widget-preview start
```

Opens a browser-based gallery of every `@Preview` in the project, grouped by the `group:`
argument each one passes (`'Items'`, `'Onboarding'`, `'States'`, …) — hot-reloads as you
edit, so it's the fastest way to iterate on a screen's visuals without navigating the real
app to reach it. `flutter widget-preview clean` resets its cached state if it ever gets
stuck.

The previews themselves live beside what they preview (e.g.
`completion_celebration_card.dart`'s own `completionCelebrationCardPreview` at the bottom
of the file) and share plumbing from `lib/core/preview/preview_harness.dart`
(`previewApp`/`previewPage`/`previewPiece`) — read that file's own doc comment before adding
a new one; it explains which wrapper a given widget needs and why previews are handed the
*real* app theme rather than a preview-only palette.

**One easy way to break every preview at once, and how you'd know:** a `Ticker`,
`AnimationController`, or anything else with its own scheduler callback that isn't torn
down when its widget is disposed — `test/core/preview/previews_test.dart` pumps *every*
preview in one test run, so a leaked animation from one preview doesn't just fail that
preview, it fails every preview that runs after it in the same process (see
`docs/decisions.md` #67's `ConfettiBurst` leak for exactly this happening). If previews
start failing with "An animation is still running even after the widget tree was
disposed" and the failing test's own widget looks unrelated, look at whichever preview ran
immediately before it, not the one that's red.

## Testing conventions

### Fakes and builders live in `freshcart_flutter/test/fakes/`

One fake repository per domain port (`fake_list_repository.dart`,
`fake_item_repository.dart`, `fake_shop_repository.dart`, `fake_auth_repository.dart`) —
in-memory, configured per-test by setting a public field before pumping (e.g.
`repository.myListsResult = Ok([...])`, `repository.byIdResult = const Err(...)`), not by
mocking. Alongside them, plain builder functions for domain entities with sensible
defaults so a test only names the fields it actually cares about:

```dart
buildList(name: 'Groceries', members: [buildMember()])
buildMember(userId: 'user-2', displayName: 'Mom')
buildItem(name: 'Milk')
```

`dto_builders.dart` is the same idea one layer down — `buildListDto`/`buildMemberDto`/
`buildItemDto` build **client DTOs**, for tests exercising a `data/` mapper rather than a
repository consumer. Reach for the domain builders unless you're specifically testing the
DTO → entity mapping itself.

### The `pump()` helper pattern

Nearly every widget test file defines its own local `pump(WidgetTester, {...})` that
builds a `ProviderContainer` with fakes overridden in, wraps the real `FreshCartApp` (or
just the one screen under test, for something simpler — see
`test/features/lists/presentation/household_test.dart` for that lighter version), and
returns the container so the test can read providers directly afterward. Copy the nearest
existing one in the same feature rather than inventing a new shape — the differences
between them (whole-app vs. single-screen, `currentUserId` override or not) are there for
specific reasons particular to what that file tests.

For anything that boots the **whole app** (most tests under `features/lists/` and
`features/onboarding/`), you need:

```dart
authBootstrapProvider.overrideWith(
  (ref) async => (authenticated: true, isNewIdentity: false),
),
```

Omit it and the app treats every test run like a brand-new device, routing to Welcome
instead of wherever the test actually wants to be.

### Two safety patterns worth knowing before you hit their bugs

Both cost a real debugging pass the first time (`docs/decisions.md` #65 and #68 tell the
full story); the short version, so you don't rediscover them the hard way:

- **A dialog opened from a widget that might already be gone by the time it resolves**
  (a drawer row that pops the drawer, then waits on a name being typed) needs a
  `ProviderContainer` grabbed via `ProviderScope.containerOf(context, listen: false)`
  *before* anything closes — not the widget's own `WidgetRef`, which Riverpod refuses to
  read once the widget is unmounted. See `showCreateListDialog`/`showJoinListDialog` in
  `lists_screen.dart` for the pattern. If the calling widget stays mounted while the
  dialog is up (a confirm dialog opened from a still-visible screen, say), a plain
  `WidgetRef` is fine — `confirmDeleteList`/`confirmLeaveList` in
  `list_danger_zone_actions.dart` use one deliberately, for exactly that reason.
- **`ref.invalidateSelf()` keeps the *previous* value visible through `AsyncValue.value`
  while a refresh is in flight** — a `ref.listen` callback that acts on `.value`
  unconditionally can act on stale, about-to-be-superseded data. Guard with
  `if (next.isLoading) return;` before checking `.value` if the callback does anything
  consequential (navigation, a write) — see `ListsScreen`'s own listener for the pattern
  and `docs/decisions.md` #68 for the bug this caused before the guard existed.

## Where things are, if you're not sure

- **A new use case or entity rule** → `packages/freshcart_domain/lib/src/<feature>/` —
  pure Dart, no Flutter or Serverpod imports, ever (`docs/architecture.md`).
- **A repository implementation, or a client DTO ↔ domain mapper** →
  `freshcart_flutter/lib/features/<feature>/data/`.
- **A Riverpod provider or controller** → `.../application/`.
- **A screen or widget** → `.../presentation/`, `widgets/` for anything not a full screen.
- **A server-side model, endpoint, or business rule** → `freshcart_server/lib/src/<feature>/`.
- **"Why does this exist / why not the obvious alternative"** →
  `docs/decisions.md` — search it before assuming something is an oversight; a
  surprising amount of "why isn't X built the simple way" already has a recorded answer.
