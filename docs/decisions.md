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

**Decision:** `slang`, locales `nl` (default), `en`, `fr`, `ru`, `tl`. **Why:** type-safe keys
(a typo is a compile error), first-class pluralization/interpolation, good DX — fits the
strict-typing ethos and the app's i18n headline feature. `nl`/`fr`/`en` come from the Belgian
context; `ru` and `tl` were added to cover the households the app is actually for, and they
are what turned pluralization from a nice-to-have into a requirement (see #25).
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

## 16. `Result` is hand-written; `Failure` and the entities use freezed

**Decision:** `Result<T>` is a plain Dart `sealed class` with `fold`/`map`/`flatMap` and
hand-written `==`. `Failure` and every entity stay on `freezed`, as `architecture.md`
specifies. **Why:** golden rule 7 — reach for a pattern only when it earns its keep. What
`freezed` generates is `copyWith`, `==`, `hashCode` and `toString`. For an *entity* that is
real value: optimistic-UI rollback needs `copyWith`, and Riverpod needs `==` to decide
whether to rebuild. For `Result` it is close to nothing — `copyWith` on an `Ok` is
meaningless, and the `==` is four lines. Meanwhile the things `Result` genuinely wants —
`fold`, `map`, `flatMap` — cannot be generated and would have been written as extensions
anyway. Since Dart 3 already gives exhaustive `switch` over any `sealed` type, the generator
was contributing nothing to the most-used type in the codebase. **Rejected:** `@freezed
sealed class Result<T>` as written in `architecture.md` (consistent, but adds a generated
file and a codegen dependency to the one type every layer imports). **Trade-off:** two
idioms in one package instead of one. The rule that keeps it principled: *codegen where
data-class boilerplate pays, plain Dart where the language already suffices.*

## 17. Ids are extension types, not wrapper classes

**Decision:** `ListId`, `ItemId`, `ShopId`, `UserId`, plus `JoinCode` and `HexColor`, are
Dart `extension type`s over `String`/`int`. **Why:** they give the type safety the value
objects exist for — the compiler refuses to pass an `ItemId` where a `ListId` belongs — at
genuinely zero runtime cost, because an extension type *is* its representation once
compiled. A wrapper class would allocate an object per id, and a list screen holds hundreds.
Validation still happens: the unnamed constructor is a factory that throws `ArgumentError`
on a malformed id (a programmer error — the server never issues one), while `JoinCode.parse`
and `HexColor.parse` return a `Result` because those *are* fed from user input.
**Rejected:** `freezed` wrapper classes (allocation per id, a generated file per value
object, for no added safety); raw `String` ids (the bug class these exist to prevent).
**Trade-off:** extension types are erased at runtime, so `is ListId` and runtime reflection
over them do not discriminate. The domain never does either; if that changes, this is the
one decision to revisit.

## 18. `Failure.validation(field, message)` added to the union

**Decision:** a sixth `Failure` case beyond the five in `architecture.md`. **Why:** value
objects and use cases reject input *before* any network call — a malformed join code, a
blank item name, a quantity below one — and none of the existing cases describe that.
Folding it into `unexpected` would have lost the field name the UI needs to mark the right
form field. **Trade-off:** one more case for every exhaustive `switch` to handle, which is
the point of an exhaustive switch.

## 19. Shops are scoped to a list, not to a user

**Decision:** `Shop` carries a `listId`; every member of a list sees the same shop set.
**Why:** shops exist so items can be tagged and filtered *collaboratively*. If shops belonged
to a user, an item Mom tagged "Colruyt" would reference a shop nobody else on the list owns —
the tag would be meaningless to everyone but her, and the theme-follows-shop behaviour would
differ per viewer on the same screen. **Rejected:** user-owned shops (avoids re-creating
"Colruyt" on each list, but breaks the shared meaning of a tag); global shops (no
multi-tenancy). **Trade-off:** the same shop name is re-entered per list. Acceptable — a
household typically runs one or two lists — and a "copy shops from another list" action is a
cheap future addition. This changed the domain's `ShopRepository` to be list-scoped.

## 20. Explicit foreign-key fields instead of object relations

**Decision:** `ShoppingItem`, `ListMember` and `Shop` declare `listId: UuidValue, relation(...)`
rather than `list: ShoppingList?, relation(...)`. **Why:** two reasons, one of them a bug.
The bug: an object relation declared as `shop: Shop?` generated a **NOT NULL** `shopId`
column while still emitting the `ON DELETE SET NULL` constraint I asked for — a combination
that is fine until the first shop is deleted, at which point Postgres refuses the write. The
explicit `shopId: UuidValue?` form generates a nullable column and a coherent constraint. The
design reason: the domain entities hold `ListId`/`ShopId` scalars, not nested objects, so the
explicit form maps one-to-one onto them and stops a single-item read from dragging a whole
list across the wire. **Trade-off:** loses the generated object accessor, which this app never
wanted.

## 21. The server depends on `freshcart_domain`

**Decision:** `freshcart_server` takes a path dependency on the pure domain package, which the
import matrix in `docs/architecture.md` already permits. **Why:** it is the shared-domain
payoff made concrete. The join-code alphabet (no `I`, `O`, `0`, `1`) is defined once in
`JoinCode`; the server generates codes from it and the app parses codes against it, so the two
cannot drift into a state where the server issues a code the client rejects. The server also
reuses `JoinCode.parse` to reject a malformed code before it reaches the database.
**Trade-off:** the domain is now on the server's dependency graph, so it must stay genuinely
pure — which the Phase 1 purity check already enforces.

## 22. Optimistic concurrency via `updatedAt`, with server-owned fields

**Decision:** `ItemEndpoint.save` takes the whole item; the server compares the incoming
`updatedAt` against the stored row and throws `EditConflictException` if they differ, then
overwrites `listId`, `addedBy` and `createdAt` from the stored row. **Why:** two people
editing one shopping list at once is this app's *normal* case, not an edge case, so a
last-write-wins update would routinely discard someone's change. Re-imposing the server-owned
fields means a client cannot move an item to another list or rewrite its provenance by
tampering with a field — a whole-entity save is convenient, not a licence. **Rejected:**
field-level mutation endpoints (no single place to check the version, and `null` cannot
distinguish "unchanged" from "clear this field"); a separate integer version column
(equivalent, and `updatedAt` was needed for display anyway). **Trade-off:** a conflicting edit
is rejected rather than merged; the client re-reads and re-applies.

## 23. Serverpod's generator drops Dart default values

**Not a decision — a constraint worth recording.** An endpoint parameter written as
`int quantity = 1` is generated into the client as `required int quantity`: the default is
silently dropped, and only *nullability* makes a generated parameter optional. Optional
endpoint parameters are therefore declared `int? quantity` with the default applied in the
endpoint body. Worth knowing before designing any endpoint signature.


## 24. `freshcart_l10n` generates plain Dart, not Flutter-integrated slang

**Decision:** slang runs with `flutter_integration: false`, and `lazy: false`. **Why:** the
integration flag makes the generated classes extend Flutter types, which would stop the Jaspr
marketing site — plain Dart, no Flutter — from sharing this package, and sharing it is the
entire reason `freshcart_l10n` is a package rather than a folder in the app. The cost is that
there is no `TranslationProvider` or `context.t`: choosing a locale becomes the consumer's
job, which in the app is a Riverpod provider — arguably where locale state belonged anyway.
`lazy: false` because deferring five locales of roughly a kilobyte each saves nothing
measurable while making every locale switch async. **Trade-off:** no automatic device-locale
detection from slang; the app asks the platform itself and calls `LocaleSettings`.

## 25. Plural resolvers are registered for `nl` and `tl`

**Decision:** `freshcart_l10n` ships `freshCartCardinalResolvers` plus a `translationsFor()`
helper, and callers use that rather than `AppLocale.x.buildSync()` directly. **Why:** slang
ships built-in CLDR cardinal resolvers for `ar cs de en es fr he it ja pl ru sv uk vi` only.
FreshCart's **base** locale `nl` is not among them, nor is `tl`. Left alone, both silently use
a tolerant fallback (`one` only when n == 1) and slang logs an error on every plural lookup.
For Dutch that fallback happens to be correct — but leaving the default language's grammar to
a coincidence is not a decision, it is an accident waiting to be noticed by a user. For
Tagalog it is simply **wrong**: CLDR selects `one` unless the integer ends in 4, 6 or 9, so
the fallback mis-renders 5, 10, 4, 6, 9 and 14. Registering the two resolvers costs about
thirty lines and is covered by tests that assert the exact forms. **Note:** a resolver set via
`LocaleSettings.setPluralResolver` only reaches the singleton behind the global `t`;
translations built by hand need the resolver passed to `buildSync`, which is exactly what
`translationsFor()` exists to stop people forgetting.

## 26. Controllers expose `AsyncValue<Result<T>>`, not `AsyncValue<T>`

**Decision:** every controller's state is `AsyncOutcome<T>` — a typedef for
`AsyncValue<Result<T>>`. **Why:** the two wrappers mean different things and collapsing them
loses information. `AsyncValue` carries *loading*, a fact about the request. `Result` carries
*expected failure* — offline, not found, conflict — which `CLAUDE.md` requires to travel as a
value rather than a thrown exception. Keeping both means `AsyncError` now has a precise
meaning: something genuinely unexpected happened, i.e. a bug. `AsyncData(Err(...))` means the
operation completed and failed in a way the UI is expected to handle. **Rejected:** throwing
the `Failure` into `AsyncValue`'s error channel — the idiomatic Riverpod shortcut. It would
have blurred bugs and expected failures into one channel, and it does not even typecheck
cleanly: `Failure` is deliberately not an `Exception`, so the `only_throw_errors` lint
rejects it and it would have needed a fake exception wrapper built solely to satisfy the
framework. **Trade-off:** one extra level of pattern matching in each widget, which is
visible in `lists_screen.dart` and is the honest cost of the distinction. Named
`AsyncOutcome` because Riverpod 3 already exports an `AsyncResult`.

## 27. List membership is enforced server-side only

**Decision:** the router has no membership guard; `ListService.requireMembership` on the
server is the single check, and the detail screen renders the resulting
`Failure.unauthorized()` as "no access". **Why:** a client-side guard would be a second
source of truth for an authorisation rule, and the client's copy is the one that can be
stale, tampered with, or simply wrong after someone is removed from a list mid-session. The
server has to check regardless, so the client check buys nothing but a chance to disagree.
**Rejected:** a `redirect` that pre-fetches the list and bounces non-members — more code, an
extra round trip before every navigation, and it still cannot be trusted. **Trade-off:** a
non-member briefly sees a loading state before the message instead of never routing at all.
Acceptable: it is an error path that should be rare, and the honest one.
