# Web demo plan — two FreshCart phones inside the portfolio

> Read `CLAUDE.md`, `docs/architecture.md` and this file before writing code.
> Follow it phase by phase: plan the phase, build it, run its **Accept** commands,
> stop and report. Do not start the next phase until Nikolaos says so.

## Goal

A web-only build of FreshCart that runs **with no Serverpod, drift or Firebase**, and shows
**two phones at once** from **one Flutter engine** (multi-view). Both phones share one
in-memory fake backend, so a change on phone A shows up on phone B. On start, a scripted
"director" plays onboarding on phone A (create list), then the join flow on phone B (using A's
join code), then unlocks both phones for the visitor.

The output is a folder of static files that gets copied into Nikolaos' Jaspr portfolio
(a separate repo). The portfolio never imports FreshCart code.

**Scope:** this plan covers the FreshCart side only. The portfolio side (mount script, modal
slots) is done separately — but the contract below must be honoured exactly.

## Contract with the portfolio (do not change without saying so)

| Item | Value |
| --- | --- |
| Build output location | copied to `<portfolio>/web/demo/freshcart/` (served at `/demo/freshcart/`) |
| Loader hook | `web/flutter_bootstrap.js` calls `window.freshcartDemo.boot(_flutter)` when `window.freshcartDemo` exists; otherwise starts the normal PWA exactly as today |
| Multi-view | host page calls `initializeEngine({multiViewEnabled: true, entrypointBaseUrl, assetBase})`, then `app.addView({hostElement, initialData: {persona: 'a' \| 'b'}})` per phone |
| Persona | `initialData.persona` = `'a'` (Nikolaos, creates the list) or `'b'` (Anna, joins) |
| Views come and go | the modal can close (`removeView`) and reopen (`addView`) many times per page load |
| Host element CSS | explicit `width`/`height`, `position: relative`, `overflow: hidden`, and **no inherited `text-align`** on the host or its ancestors: it is inherited by Flutter's own elements and shifts the app half a phone-width to the right (found in D3) |

Reference docs (verify APIs here, don't recall from memory):
- Multi-view: https://docs.flutter.dev/platform-integration/web/embedding-flutter-web
- Loader / `flutter_bootstrap.js`: https://docs.flutter.dev/platform-integration/web/initialization
- Riverpod overrides: https://riverpod.dev/docs/how_to/testing

## Rules for this work

1. **Everything demo-specific lives in `freshcart_flutter/lib/demo/`** plus `lib/main_demo.dart`.
   Production code must never import `lib/demo/`. The single allowed exception is the
   scripted-text hook in D4 (lives in `lib/core/demo_hooks/`, never written to in production).
2. **Fakes implement the domain ports** (`ListRepository`, `ItemRepository`, `ShopRepository`,
   `AuthPort`, `PushPort`). They return pure domain entities and `Result`. No Serverpod types.
3. **Do not modify `lib/main.dart`, the real repositories, or the router** for this.
   The normal app, iOS/Android builds and the PWA must behave exactly as before.
4. Add a `docs/decisions.md` entry when the plan is accepted (why a demo, why multi-view,
   why fakes at the port boundary, why the text hook).

## What is already known about the codebase (verified 2026-10-03)

- Repository DI providers: `listRepositoryProvider`, `itemRepositoryProvider`,
  `shopRepositoryProvider`, `authRepositoryProvider` (returns `AuthPort`),
  `pushRepositoryProvider` — each at the bottom of its `*_impl.dart`.
- **Other providers that reach the outside world and must also be overridden:**
  - `currentUserIdProvider` (`auth/data/sources/current_user_provider.dart`) → calls `client.profile.me()`
  - `authBootstrapProvider` (`auth/data/sources/anonymous_session_bootstrap.dart`) → Serverpod sign-in; splash waits on it
  - `syncProvider`, `pendingWriteCountProvider`, `queueDrainCoordinatorProvider` (`sync/application/sync/sync_providers.dart`) → connectivity_plus + drift queue; `FreshCartApp` watches the coordinator
  - With these + the repositories overridden, `appDatabaseProvider` (drift) is never created.
- Leave `serverpodClientProvider` **un-overridden** on purpose: it throws when read, so any
  missed path fails loudly.
- Riverpod 3 does **not** export the `Override` type (see `core/preview/preview_harness.dart`):
  build the whole `ProviderContainer` inside one function instead of returning `List<Override>`.
- **Navigation lives in screens**, not controllers: `OnboardingScreen` / `JoinFlowScreen` call
  `context.go(...)` after submit. The director must navigate itself via each phone's
  `appRouterProvider`.
- **Text fields own private `TextEditingController`s** (`NameWithAvatarField`,
  `CreateListStep`, `JoinCodeInput`). Calling `updateDisplayName` changes controller state
  but not the visible text → needs the D4 hook.
- `OnboardingController` and `JoinFlowController` are **auto-dispose**: only read them while
  their screen is mounted.
- `OnboardingController.submit()` creates name + list + shops and moves to the invite step;
  `state.createdList!.joinCode` is the code phone B needs.
- `JoinCode.alphabet`, `JoinCode.length`, `JoinCode.parse` exist in the domain — the fake must
  use them so generated codes are always valid.
- Member roles: check `lists/entities/member_role.dart` for the exact enum values.

---

## Phase D1 — In-memory backend + fakes · `BUILD`

**Goal:** a pure-Dart fake "server" that both phones can share, proven by tests.

**Build**
- `lib/demo/demo_backend.dart` — `DemoBackend`: maps of lists / items / shops / users keyed by
  their id value objects; a broadcast `Stream<void> changes` + `notify()`; `now()` from a
  `Clock`; sequential ids; `newJoinCode()` via the domain alphabet + `JoinCode.parse`;
  `latency()` = a short random delay (~120–300 ms) so pending/spinner states still show.
- `lib/demo/fakes/fake_list_repository.dart` — `FakeListRepository(DemoBackend, UserId me)`.
  Must-haves: `create`, `joinByCode` (adds `me` as member, `notFound` on unknown code),
  `myLists`, `byId`, `watch` (yield current, then re-yield on every `changes` event),
  `summaries`. The rest: same pattern, simple but correct.
- `lib/demo/fakes/fake_item_repository.dart` — `add` (addedBy `me`, next `sortOrder`), `save`,
  `remove`, `clearChecked`, `removeMany`, `moveMany`, `watchByList` (sorted by `sortOrder`),
  `byList`; `suggestNames`/`recentNames` return a small fixed list.
- `lib/demo/fakes/fake_shop_repository.dart` — full implementation (it's small).
- `lib/demo/fakes/fake_auth.dart` — one per phone; user stored in `db.users[me]`;
  `setDisplayName`/`setAvatarColor` also update the matching `ListMember` in every list;
  `linkGoogle`/`linkEmail`/avatar photo → `Err(Failure.unexpected('Not available in the demo'))`;
  `authStateChanges` driven by `db.changes`.
- `lib/demo/fakes/fake_push.dart` — `isSupported()` → false, everything else a harmless no-op
  returning `Ok`.
- No `noSuchMethod` shortcuts in the final code — implement every interface member.

**Accept**
```bash
cd freshcart_flutter
flutter test test/demo
flutter analyze
```
Tests must include: an item added via user A's fake reaches user B's `watchByList`; joining
with an unknown code returns `notFound`; a renamed display name shows in the list's members.

---

## Phase D2 — Demo entrypoint, one phone · `BUILD`

**Goal:** the real app UI runs in Chrome on the fakes, single view, no server running.

**Build**
- `lib/demo/demo_persona.dart` — `DemoPersona(id, name)`; `a` = Nikolaos, `b` = Anna. No fixed
  colour: the avatar gets the automatic colour for the user id, the same one onboarding shows.
- `lib/demo/demo_overrides.dart` — `ProviderContainer createPhoneContainer(DemoBackend db,
  DemoPersona p)`: seeds `db.users[me]` (empty display name, no colour) if absent, and
  overrides: the five repositories (fakes), `currentUserIdProvider` → `Ok(me)`,
  `authBootstrapProvider` → `(authenticated: true, isNewIdentity: true)`,
  `syncProvider` → online, `pendingWriteCountProvider` → `0`, `queueDrainCoordinatorProvider` → no-op.
- `lib/main_demo.dart` (temporary single-view version): `ensureInitialized`,
  `configurePluralResolvers()`, `setUrlStrategy(null)` (from
  `package:flutter_web_plugins/url_strategy.dart`, so go_router never touches the host page's
  address bar), then `runApp(UncontrolledProviderScope(container: ..., child: FreshCartApp()))`.
- Add `flutter_web_plugins: sdk: flutter` to `freshcart_flutter/pubspec.yaml`.

**Accept**
```bash
flutter analyze
flutter run -d chrome -t lib/main_demo.dart
```
Manual: onboard, add / edit / tick / delete items, open settings — **zero** console errors,
no network calls to a Serverpod host. Normal `flutter run -d chrome` (real `main.dart`) still
starts the real app unchanged.

---

## Phase D3 — Two phones, one engine · `BUILD`

**Goal:** multi-view: two independent phones sharing one `DemoBackend`.

**Build**
- `lib/demo/multi_view_app.dart` — the `MultiViewApp` widget from the Flutter multi-view docs.
- `lib/demo/demo_phone.dart` — `DemoPhone` StatefulWidget. In `didChangeDependencies`
  (needs `View.of(context)`), read `initialData` via `dart:ui_web` `views.getInitialData(viewId)`
  through a JS-interop extension type (`persona` getter), pick `DemoPersona.a`/`b`, create
  its container once with `createPhoneContainer(sharedDb, persona)`. Dispose the container in
  `dispose`. Build `UncontrolledProviderScope(container, FreshCartApp())`.
- `lib/main_demo.dart` — final shape: `runWidget(MultiViewApp(viewBuilder: (_) => DemoPhone(...)))`.
- `web/flutter_bootstrap.js` — custom loader:
  ```js
  {{flutter_js}}
  {{flutter_build_config}}
  if (window.freshcartDemo) {
    window.freshcartDemo.boot(_flutter);
  } else {
    _flutter.loader.load(/* copy whatever options the current generated bootstrap passes */);
  }
  ```
  First inspect `build/web/flutter_bootstrap.js` from a normal build and keep its `load(...)`
  options in the `else` branch so the PWA is unaffected.
- `web/demo.html` — dev-only host page: two fixed-size host divs (`position: relative;
  overflow: hidden;` + explicit width/height), sets `window.freshcartDemo.boot` to
  `load({ onEntrypointLoaded })` → `initializeEngine({multiViewEnabled: true})` → `runApp()` →
  two `addView` calls with personas `'a'` and `'b'`.

**Accept**
```bash
flutter analyze
flutter build web -t lib/main_demo.dart && (cd build/web && python3 -m http.server 8090)
# open http://localhost:8090/demo.html
flutter build web            # the normal PWA build still works
```
Manual: onboard on A, join on B with A's code, add an item on A → appears on B; tick on B →
shows on A. Address bar never changes.

---

## Phase D4 — The director (auto-play) · `BUILD`

**Goal:** opening the demo plays the script on its own; Skip finishes instantly; then unlocked.

**Build**
- `lib/core/demo_hooks/scripted_text.dart` — `@Riverpod(keepAlive: true) class ScriptedText`
  holding `Map<ScriptedField, String>`; `enum ScriptedField { onboardingName,
  onboardingListName, joinName, joinCode }`; `type(field, text)`. Never written to outside the demo.
- Give `NameWithAvatarField`, `CreateListStep`'s field and `JoinCodeInput` an optional
  `ScriptedField? scriptedField`. When set, `ref.listen` the field's entry and push it into the
  private `TextEditingController` (cursor at end) **and** call the existing `onChanged`.
  Convert to `Consumer*` widgets only where needed. Pass the fields at each call site.
  Widget behaviour with `scriptedField == null` must be byte-for-byte unchanged.
- `lib/demo/demo_stage.dart` — per-session registry: each phone registers its container;
  `Future<ProviderContainer> phone(persona)`; `ValueNotifier<bool> locked`; `fastForward` flag.
- `lib/demo/director/demo_director.dart` — script, driving controllers + router (no fake
  taps / pointer events):
  1. pause on welcome → A: go onboarding → type name "Nikolaos" → `continueIfValid()` →
     type list name "Home" → `continueIfValid()` → (shop step, keep presets) → `submit()` →
     pause on invite step → read `createdList` → go to the list.
  2. B: go join → type "Anna" → `continueFromName()` → type A's join code → `submit()` →
     go to the same list.
  3. A adds "Milk" via its item repository → visible on B.
  4. `locked = false`.
  Typing = one character at a time, 60–130 ms apart. All pauses go through one `_pause()` that
  returns immediately when `fastForward` is set and throws a private cancel exception (caught
  in `run()`) when the director is cancelled.
- `DemoPhone.build`: `Directionality` + `ValueListenableBuilder(locked)` →
  `Stack[AbsorbPointer(absorbing: locked, app), if (locked) Skip chip]`. Skip chip built from
  plain widgets (it sits above `MaterialApp`).
- Landing screen after the script: list detail (`Routes.listDetail`) unless that screen
  requires being pushed from the overview — then `Routes.lists`. Report which.

**Accept**
```bash
flutter analyze
flutter test        # full suite still green — the text hook must not break existing widget tests
```
Manual on `demo.html`: script plays end to end; Skip at any moment finishes it; afterwards
both phones respond to input.

---

## Phase D5 — Sessions, build script · `BUILD`

**Goal:** survives open/close/reopen; one command produces the portfolio folder.

**Build**
- `lib/demo/demo_session.dart` — `DemoSession` (fresh `DemoBackend` + `DemoStage` + running
  `DemoDirector`) and `DemoSessions` (`attach()` on phone create, `detach()` on dispose; last
  detach cancels the director and drops the session). `main_demo.dart` passes one
  `DemoSessions` to every `DemoPhone`.
- `tool/build_demo.sh` — `flutter build web --release -t lib/main_demo.dart`, copy
  `build/web/.` to `$PORTFOLIO/web/demo/freshcart/` (default
  `$HOME/Documents/Portfolio/Website/nikolaos_sporidis_portfolio`, overridable via env var),
  then remove `index.html`, `demo.html`, `manifest.json`, `flutter_service_worker.js` from the copy.
- `docs/dev-guide.md` — short "Web demo" section: how to run `demo.html`, how to build for the
  portfolio.

**Accept**
```bash
flutter analyze && flutter test
./tool/build_demo.sh
```
Manual on `demo.html` (add buttons there that call `removeView`/`addView` to simulate the
modal): close and reopen 5×, each time a clean run, no console errors.

---

## Definition of done (whole plan)

- [ ] `flutter analyze` clean, `flutter test` green, domain/server suites untouched
- [ ] Real app unchanged on iOS / Android / PWA (`main.dart` not modified)
- [ ] No import of `lib/demo/` outside `lib/demo/` and `lib/main_demo.dart`
- [ ] `decisions.md` entry written; `build-plan.md` progress table mentions the demo
- [ ] `tool/build_demo.sh` produces a folder that works when served at `/demo/freshcart/`
