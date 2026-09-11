# Build plan

Build in this order. Each phase is small, ends in a **compiling, checkable** state, and must
pass its acceptance commands before the next begins (golden rule 5). Do not stack unverified
work.

## How to read a phase

- **Goal** — the one thing this phase delivers.
- **Build** — the files/changes, in dependency order.
- **Accept** — commands that must pass. If they don't, the phase isn't done.
- **Learning toggle** — `MENTOR` = hand it to Nikolaos, help only when stuck; `BUILD` = agent
  writes it. Default per phase is set below; Nikolaos overrides at any time.

> The toggles below are a starting recommendation: infrastructure/plumbing defaults to
> `BUILD` (little learning value, easy to get wrong), and the parts where clean-arch judgment
> is actually exercised default to `MENTOR`. Change any of them.

## Progress

Status as of 2026-09-10. ✅ accepted · 🟡 partial, reason given · ⛔ blocked.

| Phase | State | Note |
| ----- | ----- | ---- |
| 0 Workspace scaffold | ✅ | |
| 1 Domain core | ✅ | 96 tests |
| 2 Server models + endpoints | ✅ | 73 tests |
| 3 App data layer | ✅ | |
| 4 App shell | ✅ | |
| 5 Lists | ✅ | |
| 6 Items | ✅ | |
| 7 Shops + dynamic theming | ✅ | |
| 8 Real-time sync | ✅ | `ListRepository.watch` gap closed; see decisions #34–36 |
| 9 Notifications | 🟡 | Ports, server aggregation/buffering, and the FCM adapter are all in and wired to a real Firebase project (`firebase_options.dart` exists, the client registers a real token). **Not yet verified**: delivery to a physical device — nothing here can confirm that from a dev machine. |
| 10 Auth upgrade path | 🟡 | Email linking done and tested. **Google blocked** on an OAuth client id — returns an honest failure, see decisions #40. |
| 11 Jaspr marketing site | 🟡 | Pages and components exist; SEO meta and Lighthouse pass not yet verified. No tests, and CI has no job for this package. |
| 12 Test coverage + CI | 🟡 | CI runs analyze, format and all four suites, and asserts the golden rules by grep (decisions #41). Coverage gaps remain in `freshcart_web` — no `test-web` job exists yet. |

**Suites:** 242 app · 96 domain · 88 server · 8 l10n.

## Design flows

The Claude Design handoff bundle in `docs/multi-shop-shopping-list-app/` defines eleven flows
(00–10, as of the 2026-09-11 re-export, which added 09 and 10). These are built *on top of* the
phases above, not instead of them. See `docs/design-gap-plan.md` for the detailed breakdown of
everything flows 09–10 add that phases 0–12 did not build yet.

| Flow | State | Note |
| ---- | ----- | ---- |
| 00 Onboarding | ✅ | Splash → Welcome (two exits) → 4-step wizard (name, list, shops, invite) → lists, plus a separate join-by-code flow off Welcome's second exit. Decisions #60. |
| 01 Empty states | ✅ | |
| 02 Done section | ✅ | 600 ms hold (decisions #47) plus the completion celebration card once the whole list is checked (decisions #61) |
| 03 Gestures | ✅ | Swipe-delete/undo, multi-select, and drag-to-reorder (fractional `sortOrder`) all built. Deliberately not built: the contextual bar's "Move" action — decisions #52–54. |
| 04 Editing lists & shops | ✅ | Live colour preview, decisions #45 and #48 |
| 05 Household & sharing | ✅ | Deliberately omitted: last-active captions (no timestamp), QR toggle, code expiry. See the commit. |
| 06 Search & suggestions | 🟡 | Search is built, local-only, its own header mode — decisions #55. The purchase-history capability "Recently bought" needs is now built (decisions #64, for the add control's own chips) — this row is now just a small UI piece away, not a backend gap. |
| 07 Offline & sync | ⛔ | Needs a connectivity port in the domain and cached reads. Overlaps the offline-first scope fork below. |
| 08 Errors | ✅ | Three tiers, decisions #42 |
| 09 The add control | 🟡 | The core interaction (roll-out FAB, +/× glyph rotation, fast Enter path vs. the detail sheet) is built — decisions #58, #59. **Not yet built:** the shop-tinted placeholder ("Add to Colruyt"), the leading shop-colour dot inside the field, the empty-vs-has-text glyph background state, item-name suggestion chips, and the new-row entrance flash. See `docs/design-gap-plan.md`. |
| 10 Drawer, settings & preferences | ⛔ | The drawer (decisions #57) and a minimal Settings screen (decisions #56) exist, but this flow's actual scope — remaining-count/member avatars on drawer rows, a 4-group Settings screen, Edit profile with a user-chosen avatar colour, Appearance/Notifications/List-settings as their own screens, and every preference they introduce — is almost entirely new. See `docs/design-gap-plan.md`. |


## ✅ Phase 0 — Workspace scaffold · `BUILD`

**Goal:** an empty but resolving monorepo with strict lints.

**Build**
1. `serverpod create freshcart` to generate `freshcart_server`, `freshcart_client`,
   `freshcart_flutter` (pin Serverpod 3.4.x — verify current stable on pub.dev first).
2. Add `packages/freshcart_domain` (pure Dart lib) and `packages/freshcart_l10n`.
3. Add `freshcart_web` via the Jaspr CLI (verify current stable).
4. Add the root `pubspec.yaml` `workspace:` listing every member; set `resolution: workspace`
   in each member. Copy the strict root `analysis_options.yaml` and have each package inherit it.
5. `.gitignore` for Dart/Flutter/Serverpod + Firebase config files. `git init`, first commit.

**Accept**
```bash
dart pub get           # resolves the whole workspace, one lockfile
dart analyze           # clean
```

## ✅ Phase 1 — Domain core · `MENTOR`

**Goal:** the pure heart — `Result`/`Failure`, value objects, the first entities and ports.
No Flutter, no Serverpod.

**Build** (in `packages/freshcart_domain`)
1. `core/result.dart`, `core/failure.dart` (freezed unions from `architecture.md`).
2. Value objects: `ListId`, `ItemId`, `ShopId`, `UserId`, `HexColor`.
3. Entities: `ShoppingList`, `ListMember`, `ShoppingItem`, `Shop`, `Note`.
4. Ports (abstract): `ListRepository`, `ItemRepository`, `ShopRepository`, `AuthPort`,
   `PushPort`.
5. First use cases: `JoinList`, `AddItem`, `ToggleItemChecked`.

**Accept**
```bash
dart test packages/freshcart_domain      # use-case unit tests pass
dart analyze packages/freshcart_domain   # clean; grep confirms no forbidden imports
```
> Purity check: `! grep -rE "package:(flutter|serverpod|firebase|freshcart_client)" packages/freshcart_domain/lib`

## ✅ Phase 2 — Server: models, migrations, first endpoints · `BUILD`

**Goal:** DB models + endpoints for lists and items, with real Postgres migrations.

**Build** (in `freshcart_server`)
1. Serverpod model YAML: `ShoppingList`, `ListMember`, `ShoppingItem`, `Shop`, `Note`, and
   the anonymous identity linkage. Use UUID keys.
2. `serverpod create-migration`; apply against local Postgres (Serverpod's docker compose).
3. Endpoints: `ListEndpoint` (create, byId, join), `ItemEndpoint` (add, toggle, edit,
   remove). Keep endpoints thin — validation + a call into a server-side op/service.
4. `serverpod generate` to produce the client.

**Accept**
```bash
cd freshcart_server && serverpod generate
dart run bin/main.dart --apply-migrations   # boots, DB in sync
dart test                                    # endpoint tests pass
```

## ✅ Phase 3 — App data layer: repositories + mappers · `MENTOR`

**Goal:** wire the generated client to the domain ports. This is where DTO↔entity mapping is
exercised — the reason `MENTOR` is the default here.

**Build** (in `freshcart_flutter/lib/features/*/data`)
1. Mappers for every entity (`toDomain` / `toDto`).
2. `ListRepositoryImpl`, `ItemRepositoryImpl` implementing the domain ports, returning
   `Result<T>`, translating `ServerpodClientException` → `Failure`.
3. A single `Client` provider in `core/di`.

**Accept**
```bash
cd freshcart_flutter && flutter analyze     # no dto. types escape data/
flutter test test/features/*/data           # mapper + repo tests pass
```
> Boundary check: `! grep -rE "freshcart_client" freshcart_flutter/lib/features/*/application freshcart_flutter/lib/features/*/presentation`

## ✅ Phase 4 — App shell: DI, router, theme, i18n · `BUILD`

**Goal:** the app runs, shows an empty lists screen, is themable and translatable.

**Build**
1. `core/di` root `ProviderScope`; `core/router` go_router with an auth guard placeholder.
2. `core/theme`: `ColorScheme.fromSeed`, light/dark, animated scheme swap hook.
3. `freshcart_l10n` with slang; `nl` default + `en`, `fr`. Regenerated with
   `dart run slang`, **not** `build_runner build` — `slang_build_runner`'s
   builder only reads `build.yaml`, which this repo has none of, so
   `build_runner` here silently falls back to every slang default (English
   base locale, `flutter_integration: true`, wrong output filename). See the
   note in the root `CLAUDE.md` cheatsheet.
4. Empty `ListsScreen` behind the router.

**Accept**
```bash
cd freshcart_flutter && dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
flutter run   # app boots to an (empty) translated, themed lists screen
```

## ✅ Phase 5 — Feature: Lists (create, join, view) · `MENTOR`

**Goal:** first vertical slice end-to-end — controller → use case → repo → server → back.

**Build**: `lists_controller.dart` (`@riverpod`), create/join flows, list detail screen,
membership guard in the router. Widget test for join-by-code.

**Accept**: `flutter analyze && flutter test`; manual: create a list on one client, join it
from another.

## ✅ Phase 6 — Feature: Items (add, edit, check, remove, notes) · `MENTOR`

**Goal:** the core interaction. Optimistic UI: apply locally, reconcile on server response,
roll back on `ConflictFailure`.

**Accept**: `flutter analyze && flutter test`; add/check/edit an item and see it persist.

## ✅ Phase 7 — Feature: Shops + dynamic theming · `BUILD`

**Goal:** shops with colours, filter list by shop, theme shifts to the active shop's seed.

**Accept**: switching the active shop animates the whole scheme; filter narrows the list.

## ✅ Phase 8 — Real-time sync (Serverpod streams) · `MENTOR`

**Goal:** two open clients on one list see each other's edits live, no refresh.

**Build**: `list_realtime_source.dart` wrapping the Serverpod stream; a stream provider that
merges server events into the list state; reconcile with optimistic local state.

**Accept**: edit on client A appears on client B within the stream's latency, no manual reload.
> Serverpod streaming API: verify against current docs, don't recall from memory.

## 🟡 Phase 9 — Notifications (in-app + FCM) · `BUILD`

**Goal:** background push via FCM behind `PushPort`; server aggregates + excludes the actor.

**Build**: FCM adapter implementing `PushPort`; server-side debounce/aggregate op; token
registration on sign-in; per-list mute setting.

**Accept**: closed-app client on Android receives an aggregated push; actor does not.
> Log the EU-iOS-web-push limitation in-code where token registration would otherwise assume
> availability.

## 🟡 Phase 10 — Auth upgrade path (Google/email linking) · `MENTOR`

**Goal:** link a provider to the existing anonymous `authUserId`; data preserved; nudge on
share/join.

**Accept**: upgrade an anonymous account to Google; all lists/items remain; `authUserId`
unchanged.

## 🟡 Phase 11 — Jaspr marketing site · `BUILD`

**Goal:** SEO-friendly public landing page (real HTML/CSS, SSR/SSG), reusing domain copy/types
where sensible from `freshcart_domain` / `freshcart_l10n`. No app functionality here.

**Accept**: `jaspr build` produces static HTML with meta tags; Lighthouse SEO is green.
> Jaspr rendering mode + API: verify against current docs.

## 🟡 Phase 12 — Test coverage + CI polish · `BUILD`

**Goal:** fill gaps to the DoD baseline; GitHub Actions running analyze + test on every push.

**Accept**: CI green; every use case has a unit test; key flows have widget tests.

---

## Scope-fork notes (decide before, not during)

- **Offline-first (drift + local DB + sync/CRDT):** deferred by default. v1 is
  server-authoritative with optimistic UI and cached reads. Full offline-first is a genuine,
  defensible over-engineering win for a shopping app, but it multiplies conflict-resolution
  complexity against real-time sync. Treat it as its own project after Phase 12 — do not let
  it leak into earlier phases.
- **3.5 `serverpod start` unified workflow:** nicer DX, but beta. Stay on 3.4.x stable for a
  reproducible portfolio unless Nikolaos opts in.
