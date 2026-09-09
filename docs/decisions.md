# Decisions

Interview-ready justification for every non-obvious choice. Each entry: the decision, why,
what was rejected, and the honest trade-off. Add to this whenever a new judgment call is made.

## 1. Pure shared domain package (not domain-in-app)

**Decision:** entities, ports, and use cases live in `packages/freshcart_domain`, pure Dart.
**Why:** the compiler physically forbids Flutter/Serverpod imports there, so "the domain
stays clean" is enforced, not just intended; the same logic is reusable by app, server, and
Jaspr site. **Rejected:** per-feature domain folders inside the app (easier, but nothing stops
a Flutter import creeping in). **Trade-off:** one more package and a little wiring.

## 2. Map Serverpod DTOs to domain entities at the boundary

**Decision:** generated client models are DTOs, mapped to domain entities in `data/`; no
`dto.` type appears above the repository. **Why:** it's the core value of clean architecture —
the domain owns its invariants and doesn't deform to match wire shapes or nullable generated
fields; swapping Serverpod later touches only `data/`. **Rejected:** using generated models as
domain models (fast, but couples every layer to Serverpod and to nullable wire types).
**Trade-off:** mapper boilerplate — accepted deliberately; it's the thing the portfolio is
demonstrating.

## 3. Riverpod (+ generator) for state and DI

**Decision:** Riverpod with `riverpod_generator`. **Why:** compile-safe DI without a service
locator, testable via provider overrides, and it composes cleanly with the use-case layer;
the generator removes most boilerplate. **Rejected:** Bloc (more ceremony for this app's
interaction model); `get_it` + manual providers (runtime-resolved DI, weaker guarantees).
**Trade-off:** a code-gen step in the loop.

## 4. slang for i18n

**Decision:** `slang`, locales `nl` (default), `en`, `fr`. **Why:** type-safe keys (a typo is
a compile error), first-class pluralization/interpolation, good DX — fits the strict-typing
ethos and the app's i18n headline feature; Belgian context makes nl/fr/en the natural set.
**Rejected:** Flutter's `gen-l10n`/ARB (official, zero extra dep, but stringly-typed lookups
and clunkier plurals). **Trade-off:** a third-party dependency and its build step; `gen-l10n`
is the conservative fallback if that ever bites.

## 5. Pub workspaces, not Melos

**Decision:** native pub workspaces (Dart 3.6+). **Why:** one `pub get`, one lockfile, no extra
tool — KISS for a monorepo this size, and signals familiarity with the current idiomatic Dart
approach. **Rejected:** Melos (powerful scripting/versioning, but machinery this project
doesn't need). **Trade-off:** if the repo later needs orchestrated multi-package release
scripting, Melos may return.

## 6. Serverpod-native auth, anonymous-first, provider-linked

**Decision:** one stable `authUserId` from an anonymous start; Google/email added later as
*linked* providers behind an `AuthPort`. **Why:** users get value with zero sign-up friction,
and upgrading later preserves all data with no migration because identity never changes;
the port makes adding a provider a swap. **Rejected:** forcing sign-up up front (friction on a
casual shopping app); Firebase Auth for identity (would split identity across two systems).
**Trade-off:** anonymous session loss = list-access loss — mitigated in product (early display
name, upgrade nudge on share/join), not hidden.

## 7. Firebase scoped to FCM only, behind a port

**Decision:** Firebase is used solely for push, behind `PushPort`. **Why:** FCM is the
pragmatic cross-platform push channel, but letting Firebase spread would couple the app to it;
a port keeps it swappable and keeps the rest of the stack all-Dart/Serverpod. **Rejected:**
Firebase for auth/data too (vendor lock-in, redundant with Serverpod). **Trade-off:** an extra
boundary to maintain for a single capability — worth it for the isolation.

## 8. Two-layer notifications; EU iOS web push documented as a limitation

**Decision:** live in-app updates via Serverpod streams (app open) + FCM background push (app
closed); accept that EU iOS PWA web push is unavailable. **Why:** the two layers cover the two
real states cleanly, and the iOS/EU gap is a platform constraint, not a fixable bug — pretending
otherwise would be worse than documenting it. **Rejected:** chasing a PWA workaround for EU
iPhones (there isn't a sound one under free distribution). **Trade-off:** EU iPhone users on the
free PWA get live updates but not background push; real background push there needs a native
build + paid Apple account, deferred.

## 9. Result/Failure union instead of exceptions across boundaries

**Decision:** use cases and repositories return `Result<T>` (`Ok`/`Err(Failure)`). **Why:**
expected failures (network, not-found, conflict) become part of the type signature, so callers
must handle them and the compiler helps; exceptions are reserved for genuine programmer errors.
**Rejected:** throwing typed exceptions everywhere (easy to forget to catch; control flow
hidden). **Trade-off:** slightly more verbose call sites — bought back by exhaustive `switch`
on the sealed union.

## 10. Server-authoritative + optimistic UI for v1 (offline-first deferred)

**Decision:** v1 writes go to the server with optimistic local application and rollback on
conflict; no local DB / offline-first yet. **Why:** it keeps real-time collaboration simple and
correct; full offline-first against a live-sync backend is a large, separate problem (merge
semantics, conflict resolution). **Rejected:** offline-first with drift + CRDT from the start
(defensible for a shopping app, but a complexity multiplier that would swamp the core).
**Trade-off:** no true offline editing in v1 — flagged as a follow-on project, not a silent gap.

## 11. Jaspr for the marketing site, Flutter for everything behind login

**Decision:** Jaspr renders the public landing page; Flutter (incl. the installable PWA) is the
app. **Why:** Flutter Web is for web *apps*, not content sites — it's poor for SEO and semantic
HTML; Jaspr emits real HTML/CSS with SSR/SSG, which is exactly what a marketing/SEO surface
needs. The app lives behind login where SEO is irrelevant. **Rejected:** one Flutter Web build
for both (bad SEO landing page); a non-Dart site (loses code/type reuse and adds a toolchain).
**Trade-off:** two web toolchains — justified by the split in requirements.

## 12. No `json_serializable` in the domain package

**Decision:** `freshcart_domain` depends on `freezed_annotation` and `meta` only; JSON
serialization is not available there. **Why:** serialization is a *wire* concern. The domain
describes what a `ShoppingItem` **is** and what invariants hold; how it is encoded for
transport belongs to the DTO layer, which Serverpod already generates. Letting the domain
carry `toJson`/`fromJson` invites entities to be shaped by wire convenience — exactly the
deformation decision #2 exists to prevent. **Rejected:** `freezed + json_serializable` in the
domain, as the top-level stack table suggests (convenient, but it re-couples the centre to a
transport concern and the generated DTOs make it redundant). **Trade-off:** if the domain
ever needs local persistence, the codec goes in that adapter, not on the entity.

## 13. `freshcart_web` sits *outside* the pub workspace

**Decision:** the Jaspr site keeps its own `pubspec.lock` and resolves independently; the
workspace covers the five Dart/Flutter members only. **Why:** forced by a hard constraint —
`jaspr_builder` 0.23.4 pins `analyzer ^12.1.0`, while `freezed` 4.x and `riverpod_generator`
4.x require `analyzer >=13`. A pub workspace has a **single** resolution, so the two cannot
coexist. Keeping them together would mean pinning the app's codegen down to `freezed`
3.2.6-**dev**.1 and `riverpod_generator` 4.0.4 — shipping a prerelease code generator across
the entire app to satisfy a marketing site. **Rejected:** that downgrade; and dropping Jaspr
(loses the SEO surface, decision #11). **Trade-off:** two `pub get` invocations and two
lockfiles instead of one, which dents decision #5's "one lockfile" benefit. Verified that the
site can still `path:`-depend on `freshcart_domain` and `freshcart_l10n` for Phase 11: build-time
dependencies are not transitive, so it pulls `freezed_annotation` (pure, analyzer-free) and
never the `freezed` builder. Revisit and re-merge once `jaspr_builder` adopts analyzer 13.

## 14. Serverpod's generated code is committed; other codegen output is not

**Decision:** `freshcart_client/lib/src/protocol/**` and `freshcart_server/lib/src/generated/**`
are tracked in git. `*.freezed.dart`, `*.g.dart` and slang's `lib/gen/` are gitignored.
**Why:** the split follows what each toolchain's CI assumes. Serverpod's own generated
workflows run `dart analyze` **without** invoking the Serverpod CLI, so the protocol must be
present at checkout; regenerating it in CI would also require a Postgres-less `serverpod
generate` step for no benefit. `build_runner` output, by contrast, is cheap to regenerate and
noisy in diffs. **Rejected:** committing everything (large, churn-heavy diffs on every entity
change); committing nothing (breaks Serverpod's CI contract). **Trade-off:** contributors must
run `build_runner` after a fresh clone — documented in the README and enforced by CI in Phase 12.

## 15. Local dev credentials committed, real secrets never

**Decision:** `config/passwords.yaml` is gitignored; `config/passwords.example.yaml` is tracked
and carries the *development* and *test* values verbatim while `staging`/`production` hold
placeholders. **Why:** the dev/test values are throwaway credentials for a localhost Docker
container and must match `docker-compose.yaml`'s `POSTGRES_PASSWORD` for a clone to boot at
all — hiding them buys no security and costs every fresh clone a debugging session. The
staging/production secrets Serverpod generates are real and must never land in git.
**Rejected:** committing `passwords.yaml` wholesale (leaks production JWT/service secrets,
and Serverpod's own file header forbids it); placeholdering everything (a fresh clone cannot
start the database without out-of-band values). **Trade-off:** the local DB password is public
in the repo — acceptable because it is bound to a local container and grants nothing remotely.
