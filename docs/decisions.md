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

## 28. Anonymous sign-in is wired at startup, not deferred to phase 10

**Decision:** the server exposes `AnonymousIdpEndpoint` and registers
`AnonymousIdpConfig`; the app calls `AnonymousSessionBootstrap.ensureSignedIn` before the
first frame. **Why:** the build plan puts auth at phase 10, but every FreshCart endpoint sets
`requireLogin`, so without a session the very first list fetch returns unauthorized — phases 5
and 6 would have passed their tests against fakes while being non-functional against the real
server. `architecture.md` also says the stable `authUserId` exists "from day one". What phase
10 actually adds is *linking* Google/email to that existing id, which is a genuinely separate
problem. **Trade-off:** anonymous accounts can be created by anyone, so the default per-IP
rate limit on `AnonymousIdpConfig` is kept; app attestation via
`onBeforeAnonymousAccountCreated` is available if abuse ever appears.

## 29. Adding is not optimistic; checking, editing and removing are

**Decision:** `toggle`, `save` and `remove` apply locally and roll back on failure. `add`
waits for the server. **Why:** the asymmetry is deliberate. Ticking a box happens while
walking through a shop and must feel instant, and the entity already knows how to compute the
result — `ShoppingItem.toggleChecked` is the same rule the server's answer will agree with, so
the local guess and the eventual truth are computed one way. Adding is different: the server
mints the `id`, `createdAt` and `updatedAt`, and a placeholder row with a fabricated id could
not be edited or checked until it was replaced — a worse experience than the one round trip it
saves. **Trade-off:** a brief pause when adding, which is acceptable because adding is a
deliberate act the user is already looking at.

## 30. A rolled-back optimistic update is always explained

**Decision:** every mutating controller method returns `Failure?`, and the screen shows a
snackbar when it is non-null. **Why:** a silent rollback is indistinguishable from a bug — the
user sees a row tick and then untick itself for no stated reason, and concludes the app is
broken. Since `Failure.conflict()` is an *expected* outcome on a shared list rather than an
edge case, this happens often enough to matter. **Rejected:** folding the failure into
controller state (it is transient, not state) and swallowing it (dishonest).

## 31. Check attribution is server-owned

**Decision:** `ItemService.save` sets `checkedBy`/`checkedAt` from the session, ignoring
whatever the client sent. **Why:** the whole-entity save is a convenience, not a licence. A
member could otherwise attribute their tick to someone else, and on a shared list "checked off
by" is the one label that has to be trustworthy. The client still decides *whether* an item is
checked; the server decides *who* and *when*. Covered by a test that has one user tick an item
while claiming to be another.

## 32. The shop filter is one piece of state driving both filtering and theming

**Decision:** `shopFilterProvider(listId)` holds the selected `ShopId?`; the visible items and
the app's seed colour are both derived from it, and `activeShopColorProvider` derives the
colour rather than storing it. **Why:** the headline behaviour is that picking a shop narrows
the list *and* re-themes the app. Storing those separately would let them drift — a filter
showing Colruyt's items under the bakery's colour is exactly the sort of bug that survives
review because each half looks right on its own. **Trade-off:** the theme is global while the
filter belongs to whichever list is open, so the detail screen bridges the two with a
`ref.listen` and clears the colour on the way out. That bridge is deliberately in the screen —
the only place that knows both facts — rather than inside the theme provider, which stays
dumb and independently testable.

## 33. The domain decides what a filter matches, not the widget

**Decision:** filtering calls `ShoppingItem.matchesShopFilter`, which treats an *untagged* item
as matching every filter. **Why:** the alternative — hiding untagged items when a shop is
selected — silently loses shopping. Someone adds "batteries" without tagging it, filters to
Colruyt, and the item is simply gone. Because the rule lives on the entity it has a unit test
of its own and the widget cannot quietly disagree with it.

## 34. The wire carries deltas; the client keeps the merged list

**Decision:** `ItemEndpoint.watchList` streams one `ItemChange` per edit, and
`ItemRealtimeSource` maintains the merged list on the client. **Why:** a list can hold
hundreds of items while a change usually touches one, so re-sending the whole list on every
keystroke would waste the very connection this feature exists to make feel instant. Putting
the merge in `data/` keeps it above the transport and below anything that knows what a widget
is, and `applyChange` is a pure static function with unit tests — the part with rules in it is
pinned without needing a socket. **Trade-off:** the client can drift if it misses an event, so
the stream re-seeds with a full read on every (re)subscribe.

## 35. In-flight optimistic edits are overlaid on incoming live snapshots

**Decision:** `ItemsController` keeps a `_pending` map of optimistic values for writes that
have not been answered, and re-applies it to every snapshot arriving from the stream.
**Why:** this is where the two mechanisms collide. While one user's write is in flight, an
unrelated edit by *someone else* triggers a snapshot that still carries the server's older
copy of the row being edited — so the tick would visibly undo itself and then reappear a
moment later. Without the overlay, the more collaborative the list, the more the app flickers,
which is exactly backwards. **Rejected:** ignoring snapshots while any write is pending (drops
other people's changes) and reconciling purely on `updatedAt` (the server's older row is not
"newer" by any timestamp the client can compare). Covered by a test that ticks one item while
a third party renames another.

## 36. `ListRepository.watch` streams list-level changes too (gap now closed)

**Decision:** `watch` is implemented by `ListRealtimeSource`, a second channel of the same
shape as the item one, so a rename or a new member joining reaches an open detail screen
without a refresh. **Why:** phase 8 originally scoped live sync to *item* edits — the
collaboration that matters in a shop — and `watch` threw `UnimplementedError` so the omission
was loud rather than silent. The household work made the gap user-visible: sharing a list is
pointless if the person who shared it cannot see the other member arrive. **Trade-off:** two
streams per open list instead of one. Acceptable — they are per-screen and closed with it.

*Historical note:* decision entries are not rewritten when they are superseded, but this one
asserted the opposite of the current behaviour, which is worse than no entry at all.

## 37. Push delivery sits behind a `PushSender` on the server and a `PushTokenSource` in the app

**Decision:** the server's `NotificationService` decides *who* to notify and *what to say*,
then hands a `PushMessage` to a `PushSender`; the only implementation today is
`LoggingPushSender`. In the app, the one thing Firebase would be responsible for — producing a
token string — is isolated behind `PushTokenSource`, whose only implementation today is
`UnconfiguredPushTokenSource`. **Why:** it keeps the interesting, rule-bearing parts testable
with no Firebase project, no credentials and no network: actor exclusion, mute handling, burst
aggregation and token registration all have real tests. What is genuinely blocked on
credentials is one HTTP call and one `getToken()`. **Trade-off:** end-to-end delivery is
unverified until a Firebase project exists — stated plainly rather than implied by a green
test suite.

## 38. Notifications are buffered and summarised, not sent per change

**Decision:** every item change writes a `PendingItemNotification` and schedules a flush keyed
on the list; the flush summarises the batch into one push. **Why:** adding five things to a
list in a row is one action from the user's point of view, and five buzzes from the phone's.
The key is on the list, so a change arriving inside the window joins the existing batch rather
than scheduling a competing flush. The batch is deleted *before* sending, so a delivery failure
cannot leave a batch that replays the same notification forever. Removals alone produce no
notification — not worth waking a phone for. **Note:** `futureCallWithDelay` is marked
deprecated in Serverpod 3.4.13 in favour of "generated future call methods", but running
`serverpod generate` against a project-defined `FutureCall` produces no such dispatcher in this
version. The deprecated call is the only working API here, and the suppression says so.

## 39. Account linking is implemented on the IdpAdmin primitives, not waited for

**Decision:** `AccountLinkService.linkEmail` calls
`EmailIdpAdmin.createEmailAuthentication(authUserId:)` against the caller's *existing* id.
**Why:** Serverpod 3.4's anonymous provider ships without first-class account linking — its own
changelog says the feature "can not be completely used yet due to the missing support for
account linking". But `decisions.md` #6 stakes the entire auth design on the claim that
upgrading preserves all data because `authUserId` never changes, and an unverifiable claim is
worth little in the document whose purpose is to justify choices. The admin primitive accepts
an existing `authUserId`, so linking is buildable today, and there is now a test that creates a
list and an item anonymously, links an email, and asserts both survive under the same id.
Guarded against the two ways this goes wrong: linking twice, and linking an email that already
belongs to someone else (which would be account takeover). **Trade-off:** custom code where a
future Serverpod release will offer a supported path; revisit when it lands.

## 40. Google linking returns a clear failure rather than a stub

**Decision:** `AuthRepositoryImpl.linkGoogle` returns
`Failure.validation('google', 'not configured')`. **Why:** the server half already exists —
`GoogleIdpAdmin` accepts an existing `authUserId` exactly as the email path does — but the
client half needs an OAuth client id and the `google_sign_in` flow to obtain an id token, which
this build has no credentials for. A stub that looked wired up would be worse than an honest
failure: it would pass review and fail a user. **Trade-off:** the Google path is unexercised
until credentials exist; the email path proves the mechanism.

## 41. CI asserts the golden rules, it does not just run tests

**Decision:** the `analyze` job greps for forbidden imports in
`packages/freshcart_domain/lib` and for `freshcart_client` under any feature's `application/`
or `presentation/`, failing the build on a hit. **Why:** golden rules 1 and 2 are the whole
point of this architecture, and neither is enforceable by a lint — the analyzer has no idea
that a `Flutter` import in the domain is a design failure rather than a dependency. A grep is
crude, but it is exact, it runs in a second, and it turns "we intend to keep the domain pure"
into something that can actually fail. The alternative, trusting review, is how layered
architectures rot. **Trade-off:** the checks are textual, so a sufficiently creative violation
(a re-export chain) would slip past. That is acceptable: the rule exists to catch the ordinary
mistake, made in a hurry, which is the one that actually happens.

## 42. The error tier is decided by where a failure came from, not by what it is

**Decision:** `core/error/error_tier.dart` maps `(Failure, FailureSource)` to one of
`ErrorTier.inline | snackbar | screen`, where `FailureSource` is `input`, `write` or `load`.
**Why:** the obvious design — switch on the `Failure` type — cannot work, because the same
failure deserves different treatment depending on what the user was doing. A
`NetworkFailure` while typing a join code belongs under the field; the identical failure
while checking off an item belongs in a snackbar; while loading the list it must replace the
screen, because there is nothing left to render. The failure type alone does not carry that
information. Origin does, and `ValidationFailure` is the single case that overrides it: it is
always about a specific field, so it is always inline. **Trade-off:** every call site must
name its source, which is one more argument to get right. That is the point — it forces the
question "what was the user doing?" at the place that knows the answer.

## 43. Validation lives as statics on the entity, not in value objects

**Decision:** `ShoppingItem.validateName`, `.validateQuantity`, `ShoppingList.validateName`,
`Shop.validateName` and `AuthUser.validateDisplayName` return `Result<T>`; there is no
`ItemName` or `ListName` wrapper type. **Why:** a value object that validates in its
constructor has one fatal property here — it makes *reading* fallible. Server data flows
through the mappers in `data/`, and a name that the server accepted under an older rule would
crash the mapper rather than render. Constructors cannot return a `Result`, so the failure has
nowhere to go but an exception, across the exact boundary golden rule "no throwing" forbids.
Statics put the rule in one place on the entity that owns it, and keep it where it belongs: on
the write path only. **Trade-off:** nothing in the type system stops an unvalidated `String`
being passed to a use case. The use cases call the validator as their first act, so the rule is
enforced by convention at one chokepoint rather than by the compiler everywhere.

## 44. `invalidateSelf()` is guarded by `ref.mounted`

**Decision:** both `ListsController` and `ShopsController` refresh through a private
`_refreshIfAlive()` that checks `ref.mounted` first; 12 call sites use it. **Why:** a write can
outlive the screen that started it. The household screen removes a member and routes away
immediately; nothing on the destination watches `listsControllerProvider`, so it auto-disposes
while the request is still in flight, and the `invalidateSelf()` that follows the await throws
`UnmountedRefException`. This was found by the household tests but was never confined to that
screen — the same latent bug already sat under `leave` and `delete`, hidden only because those
screens happened to keep a watcher alive. **Trade-off:** a refresh can be silently skipped. That
is correct: if nothing is watching the provider, there is no stale UI to fix, and the next
watcher rebuilds it from scratch anyway.

## 45. Deleting a shop asks what happens to its items

**Decision:** `ShopRepository.remove` takes a `ShopItemDisposition` — `untag`, `moveToShop`
(with a destination validated to be on the same list) or `deleteItems` — and the whole
operation runs inside `session.db.transaction`. **Why:** the schema could answer this on its
own with `onDelete`, and either answer would be wrong for somebody: cascade quietly destroys a
shopping list, `SetNull` quietly untags it. Deleting a *shop* and deleting *the things you
still need to buy* are different intentions, and only the user knows which one they mean. The
UI therefore shows the item count and makes the choice explicit. **Trade-off:** three code
paths and a modal instead of one `DELETE`. Bought by the fact that the destructive option is
now deliberate rather than a side effect of a schema annotation.

## 46. Ownership transfer is one transaction; an owner cannot remove themselves

**Decision:** `ListService.transferOwnership` swaps both member roles *and* the list's
`ownerId` inside a single transaction, and `removeMember` refuses when the target is the caller
or the owner. **Why:** the failure modes of a partial transfer are worse than the failure: a
list with two owners, or with none and therefore no one who can ever delete or share it, is
unrecoverable through the app. A transaction makes both illegal states unreachable. The
self-removal guard exists for the same reason — leaving would orphan the list, so the honest
exit is to transfer first and then leave, which is two explicit acts rather than one
irreversible accident. **Trade-off:** an owner who abandons a list strands it. Server-side
reassignment is the eventual answer; refusing is the correct behaviour until it exists.

## 47. The "recently checked" hold is provider state, not widget state

**Decision:** `RecentlyChecked` keeps a checked item visible in place for 600 ms via timers in
a `@riverpod` notifier, rather than in the row's `State`. **Why:** the item list rebuilds
constantly — live updates, filter changes, optimistic writes — and a checked row is removed
from its position by that rebuild. State held in the widget dies with the element the moment
the row moves, so the animation the motion spec asks for would be cut off by the very rebuild
it exists to soften. The provider outlives the widget tree it drives. **Trade-off:** timers
need explicit cleanup, and `release()` exists so unchecking is immediate rather than waiting
out a hold that no longer means anything.

## 48. A shop's colour preview is app state, not sheet state

**Decision:** `ShopColorPreview` holds the `(ShopId, HexColor)` being previewed globally, and
`effectiveShopColor` resolves a shop's real colour against it. **Why:** the preview must retint
things that are not descendants of the colour picker — the app bar, the filter chips, the rows
behind the modal barrier. Local state can only repaint the subtree it sits in, so the one
widget the user is looking *past* would keep the old colour, which is precisely the thing the
preview is for. **Trade-off:** state that must be cleared on dismiss, or a cancelled edit
leaves the app tinted. `clear()` is called on every exit from the sheet, including the barrier
tap.

## 49. Previews live beside the widget, and a test renders every one

**Decision:** 24 `@Preview` functions sit at the bottom of the production files they preview
(17 files), and `test/core/preview/previews_test.dart` renders each. **Why:** co-location is
what the tooling expects — the previewer scans all of `lib/`, exactly as Compose and SwiftUI
do — and the standing objection to it, that previews rot unnoticed, is answered by making them
fail CI instead. A preview that no longer builds is then a red test, not a surprise weeks later.
The shared harness (`previewApp` / `previewPage` / `previewPiece`) pins `AppLocale.en` and uses
the real `AppTheme`, so a preview is showing the app's actual theme rather than a plausible
imitation. **Trade-off:** production files are longer, and the harness takes no `overrides`
because Riverpod 3 does not export the `Override` type — it can only be inferred inline — so
previews needing fake data will take in-memory fakes in `lib/` rather than provider overrides.

## 50. The list detail header follows the design's chrome, adapted where it named the prototype

**Decision:** every list-detail-style screen gets the design's three-part header — a
hamburger opening a lists-switcher drawer, an eyebrow-plus-title stack, and an avatar that
opens Household — replacing the ad hoc `AppBar` and the in-page member/join-code expansion
tile. The eyebrow reads `t.appName` ("FreshCart"), not the literal word the mockups show:
that word is the prototype's own product name (it is also the splash screen's wordmark), so
the faithful adaptation is *this app's* name in the same slot, not a copied string. **Why:**
the design draws this header on ten of its thirty-three screens, consistently, which is a
stronger signal than any single one of them; the avatar-opens-Household mapping was the only
reading that made sense of an avatar with no on-screen menu ever shown next to it. Household
already held the join code and member list (decisions.md #34, #46), so the old expansion tile
became a second, un-live-updating copy of the same data — removed rather than kept alongside.
**Trade-off:** the drawer is scoped to switching only (list, tap, gone) — creating and joining
stay on `ListsScreen`, reached through a plain "All lists" row at the bottom, because the
design shows no drawer state at all and duplicating the create/join flow into a second widget
would be two places to keep in sync for a feature nobody asked for.

## 51. "Clear checked" is one transaction, not a loop of `remove`

**Decision:** `ItemService.clearChecked` deletes every checked item on a list inside a single
`session.db.transaction`, via `ShoppingItem.db.deleteWhere`, and announces one `removed`
change per row afterward so open clients drop them the same way an individual delete does.
The client's `ItemsController.clearChecked` mirrors this with one optimistic guess for the
whole batch, not [remove] called once per item. **Why:** the design's own name for the
action is a promise — "all of them" — and a client-side loop of individual deletes cannot
keep it: the third request in ten could fail, leaving half the trolley cleared and half not,
with no single failure to report and no clean way to roll back the ones that already
succeeded. One transaction makes partial failure impossible on the server, and one optimistic
guess makes the same true of what the screen shows while the request is in flight.
**Trade-off:** a failure now rolls back the whole batch rather than clearing what it could —
correct here, since "mostly cleared" is a worse, harder-to-explain state than "not cleared,
try again."

## 52. Swipe-to-delete is deferred client-side, and its recoil is `Dismissible`'s own, not a hand-rolled spring

**Decision:** `ItemsController.swipeDelete` hides the row the instant the swipe commits, and
only calls the server after a 4-second undo window (`swipeUndoWindow`) passes uncancelled —
mirroring the Motion spec's swipe-to-delete rule (§10). The repository reference is captured
into a local (`ref.read(itemRepositoryProvider)`) before the `Timer` is scheduled, not read
again inside it: if the user navigates away and this controller is disposed before the timer
fires, `ref` stops working but the plain Dart reference does not, so the delete still lands.
`swipeDelete` returns the undo action synchronously rather than a `Future<Failure?>` like
[remove] — the delete is deferred, so there is nothing to await yet, and a failure surfacing
four seconds later, once the user is looking at a different row, would read as an unrelated
bug rather than a response to anything they just did. **Trade-off:** a delete that fails once
the window elapses is not surfaced at all; the alternative (a snackbar arriving seconds after
the gesture that caused it, out of context) seemed worse than staying silent.

**Also decided:** the swipe's cancel-and-spring-back motion is `Dismissible`'s own built-in
recoil, not a hand-built replica of `AppMotion.spring`. `Dismissible` does not expose a way to
swap in a custom physics curve for that recoil short of rebuilding the gesture/drag handling
from scratch, and doing that just to match one easing curve on a cancelled swipe is
disproportionate to what it would teach or how visible the difference actually is — flagged
here rather than silently shipped as if it were the literal spec. The parts of §10 that
`Dismissible` **does** expose directly — `dismissThresholds` at 0.4, a 220 ms `resizeDuration`,
`mediumImpact()` and an icon pop on threshold crossing via `onUpdate` — are implemented as
specified.

## 53. Multi-select scopes to open rows only, and ships without "Move"

**Decision:** Long-press multi-select (`SelectionController`, per list) only arms on the open
(unchecked) rows — `ItemTile` always renders out of selection mode for a row under the Done
divider. There is no separate "selection mode active" flag: the mode *is* having a non-empty
selection, so deselecting the last row exits it the same way emptying it any other way would.
The contextual bar's "Delete" calls a new `ItemEndpoint.removeMany`, which deletes exactly the
selected ids from the list in one transaction — the same reasoning as #51's `clearChecked`:
"delete these" is one promise covering the whole selection, so a loop of `remove` calls that
can fail partway through would break it. **Why the scoping:** checked items already have their
own bulk action (Clear checked, §12) and their own locked/settled treatment (drag-reorder
excludes them the same way, per §10) — letting them into a *second* bulk-delete mechanism would
mean two overlapping ways to do roughly the same thing, with no rule for which wins.

**Trade-off, stated rather than quietly worked around:** the contextual bar's "Move" action
(§10: "3 selected · Move · Delete · ✕") is not built. Reassigning an item's shop has no UI
anywhere in the app yet — not even the single-item editor exposes it — so "Move" is not a small
addition here, it is the app's *first* shop-picker, and building one just to unblock this one
toolbar button is its own piece of work with its own design questions (a sheet? inline chips?
does it reuse for the single-item case too?), not a corner to cut silently inside this feature.

## 54. Drag-to-reorder: fractional sortOrder, a dedicated handle, and three named animation gaps

**Decision:** Manual ordering is one `sortOrder` double per item (`ShoppingItem.sortOrderGap`
= 1024 apart on append), not consecutive integers. Dropping a row between two neighbours writes
`ShoppingItem.sortOrderBetween(before, after)` — their midpoint — so a reorder is always exactly
one row's write, never a rewrite of everyone between the old and new position. The same pure
function runs on the client (optimistic) and is what the server ends up storing, via the
existing `save` endpoint — reordering needed no endpoint of its own, since "write this whole
item back" already covers a changed `sortOrder` the same way it covers a changed name. `byList`
now orders by `(sortOrder, createdAt)`, the tiebreak matters for every item that predates this
column, since backfilling them all to the same default is `defaultPersist`, not `defaultModel`
— the distinction that let the migration `ALTER TABLE ADD COLUMN` in place instead of the
drop-and-recreate Serverpod's migration tool refuses to do silently (`serverpod create-migration`
caught this and named the reason, rather than requiring it be discovered the hard way).

**The gesture conflict, and how it's resolved:** `ReorderableListView`'s default mobile
behaviour starts a drag on a bare long-press anywhere on the row — which is already long-press's
job here (§10: enter multi-select). Rather than let two features fight over one gesture, or one
silently break the other, dragging goes through `buildDefaultDragHandles: false` plus a
dedicated `Icons.drag_handle` wrapped in `ReorderableDragStartListener`, next to the edit icon.
This is a real departure from the mockup, which shows no permanent handle (only a grip glyph
appearing on the row *already* mid-drag) — but the design's own vocabulary already uses an
explicit handle for the *other* reorder feature (reordering shops, §13), so this borrows an
established pattern rather than inventing one. Scoped to a single shop tab and to open rows only
— the same two exclusions §10 states for reordering and multi-select respectively — and disabled
entirely while a selection is active, so the two gestures never have to be told apart on the
same touch.

**Trade-off, three related gaps named rather than faked:** `ReorderableListView`'s pickup/drop
transition is internally a fixed 250 ms, not the spec's 200 ms; the "other rows part" animation
and the drop's settle are the widget's own built-in easing, not `AppMotion.spring`; and there is
no public per-crossing callback, so `selectionClick()` fires on pickup and `lightImpact()` on
drop (both directly supported) but not once per index crossed while dragging. All three come
from the same root cause — `ReorderableListView` owns those specific timings internally and
does not expose them — and matching them exactly would mean rebuilding the widget from
`Draggable`/`DragTarget` primitives to save what is, in practice, a very small visual gap.

## 55. Search is local-only and its own header mode; suggestions and offline are named, not built

**Decision:** Search (§16) is a third header mode alongside the normal title and the multi-select
contextual bar, all three cross-fading through the same `AnimatedSwitcher` rather than three
separate widget trees, so the header reads as one bar changing what it says. `SearchController`
tracks `active` and `query` as two separate fields rather than treating an empty query as
closed the way `SelectionController` treats an empty selection: opening the field intentionally
leaves it active with nothing typed yet, and that state has to survive rendering with an empty
`TextField`, not collapse the instant it does. Results are computed client-side, against every
item already loaded for the list, regardless of shop or checked state — matching the spec's
"local-only, no spinner, results filter per keystroke" — so no new data source or endpoint was
needed. Rendered through a new `SearchResults` widget rather than a fourth mode threaded into
`_ItemList`: search bypasses the shop filter and the open/done split entirely, and none of
`ItemTile`'s selection or drag wiring applies to a result row, so a separate small widget stayed
plainer than growing the other one's branching further.

**Deferred, and why, rather than silently left out:**

- **Suggestion chips and "Recently bought"** (§16's second half) need a concept this app does
  not have yet: per-household purchase history, ranked by recency × frequency. That is new
  domain modelling — an event log or a frequency table, a new server endpoint, a new screen
  (drawer → Recently bought) — not an extension of anything already built, so it did not belong
  bundled into this pass.
- **Offline & sync (§18)** is the biggest single gap left in the whole spec, and deliberately not
  started here. Its own text says why it is out of scope for a quiet addition: *"Firestore's
  local cache does the work; the UI's job is honesty without anxiety."* This app is Serverpod
  over Postgres, not Firestore — there is no local-cache-first sync engine underneath to be
  honest *about*. Building genuine offline support (edit while offline, sync on reconnect, a
  "not yet confirmed" mark on unsynced rows) means designing local persistence, a write queue
  and reconciliation from scratch, which is an architecture decision on its own footing, not
  a UI pass over existing plumbing the way search and the three gesture flows were.

## 56. The upgrade nudge is permanently dismissible, backed by shared_preferences, with Settings as its new home

**Decision:** "Secure your lists" now carries a close button, and dismissing it is permanent —
`UpgradeNudgeDismissed` persists the flag via `shared_preferences`, not in-memory state, so it
does not simply reappear on the next cold start. `shared_preferences` over the already-present
`flutter_secure_storage`: the flag is a plain UI preference, not a secret, and secure storage is
already a dependency only for what the auth packages need internally — reusing it here for
something that isn't a secret would be the wrong tool wearing the right one's name. **Why
permanent, when the banner's own doc comment argues for asking again "when the stakes become
real":** direct product feedback overrides that original reasoning here — repeating it on every
list opened reads as nagging, not helpfulness, and the same action needing to stay reachable
somewhere is a separate problem from whether the banner should keep interrupting to offer it.

**That somewhere is a new Settings screen** (`/settings`), reached from the drawer. Not
list-scoped — linking an email is an account-wide fact, not a property of whichever list happens
to be open — so it does not belong on Household (membership of *one* list) or buried in a list's
overflow menu. `LinkEmailDialog` is now public and opened through one shared
`showLinkEmailDialog`, so the nudge and Settings cannot drift into two different dialogs for the
same action.

## 57. Drawer rows get the Household avatar treatment; two stray theme tokens get wired to their evident purpose

**Decision:** The lists-switcher drawer's rows now carry a monogram avatar per list (first
letter, ink-filled when current) instead of a bare radio glyph, mirroring `_MemberRow` in
Household — the same visual language for "a specific X" (a person, a list) throughout the app,
rather than two different conventions for what is structurally the same kind of row. Along the
way, two theme tokens that existed but were never actually used got wired to what they were
evidently for: `AppColors.selectedRow{Light,Dark}` is now `ListTileThemeData.selectedTileColor`
(nothing rendered a selected row any differently before this), and every drawer/footer row gets
explicit `contentPadding` — the app's `ListTileThemeData.contentPadding: EdgeInsets.zero` is
deliberate for rows that already wrap their own padding (matches `lists_screen.dart`'s and
`item_tile.dart`'s own `ListTile`s), but nothing in the drawer was supplying that wrapper, so its
text sat flush against the drawer's edges. A footer "Settings" row joins "All lists", added for
decision #56.

## 58. Quick-add is a morphing FAB; the fast path bypasses the new details sheet on purpose

**Decision:** The always-visible add-item bar is gone, replaced by `QuickAddBar`: a circular
FAB that rolls out into a pill-shaped field when tapped. One [Icons.add] glyph carries every
state by rotating 1/8 turn rather than swapping icons — unrotated it reads as "+" (closed, or
"open the details sheet" once there is text), rotated it reads as "×" (open and empty —
"cancel"). Rotating the same glyph both ways is what makes "the x turns back into a plus" true
of the implementation, not just a description of the intended effect.

**The fast path is a deliberate departure from the literal brief, made for the brief's own other
requirement** ("add items fast... don't have to click too much"): typing a name and pressing
Return commits immediately with quantity 1 and no shop, exactly like the old bar's onSubmit, and
the field stays open and focused for the next item. Tapping the button once there is text is
the only way to reach the new bottom sheet (`AddItemSheet`) — quantity and a shop, pre-filled
with the typed name. Gating *every* add behind a sheet would have made the common case (rattling
off several items) slower than the bar it replaced; this keeps the sheet as what was asked for
(a deliberate path to more detail) without making it mandatory overhead on the fast one.

`AddItemSheet` doubles as this app's first shop-picker — chips per shop plus "No shop", the same
visual language `ShopFilterBar` already uses for its tabs. Kept deliberately to name + quantity +
shop: a picture field would need real upload infrastructure (an entity field, a migration, and
either Serverpod's own file storage or a new dependency, since this app deliberately carries no
Firebase beyond push) this session did not build, and was named and set aside as its own future
piece rather than bolted on half-built.

## 59. Quick-add fixes, item rows carry their shop, and the filter chip's tap path is now actually tested

**Decision:** Three fixes in one pass, found together while working the same area:

- `AddItemSheet` gained a note field (it already had one everywhere else an item can be
  edited — `ItemEditorDialog` — and quietly not having it here was an omission, not a choice).
- `QuickAddBar`'s "open details" callback was fire-and-forget, so a successful save through the
  sheet never told the bar to clear itself — the field just sat there, full, looking like nothing
  happened. It now mirrors the fast path's own contract (`Future<bool>`): true clears the text and
  collapses the bar back to a bare button, false (cancelled, or the write failed) leaves the typed
  name in place for another attempt, matching what a rejected quick-add already did.
- Every item row now shows its shop as a small coloured dot, matching the mockup's own reference
  screens (checked directly — the dot is not conditional on the "All" tab; the design's own
  per-shop-tab screenshots carry it too, so it is unconditional here as well) — this was already
  built for search results, just never wired into the ordinary list. Quantity moved from a bold,
  primary-coloured prefix ("6×") to a muted suffix ("x6") after the name, matching `.fs-qty`'s own
  styling and position in the reference markup rather than an invented placement.

**On "shop navigation doesn't work":** the actual filter logic and the chip's tap wiring were
both already correct — `shop_filter_test.dart` only ever drove the underlying provider directly,
never the chip itself, so a real UI-wiring regression could have slipped past it unnoticed. Added
a test that taps the rendered chips end to end (select, toggle off, switch shops, back to "All")
to close that gap and confirm it directly, rather than trusting inspection alone. The likely
actual source of "doesn't work": every row looked identical with no shop tag showing, so filtering
by shop had nothing visible to distinguish before and after — the same dot fix above.

## 60. Splash, Welcome and onboarding finished to match the design; join-by-code built as its own flow

**Decision:** Four things landed together because they are one continuous path — "getting in" — and
each one only makes sense against the others.

**Splash is a real route (`/splash`), not a widget `main()` shows before `runApp`.** The old boot
sequence awaited `AnonymousSessionBootstrap.ensureSignedIn` before calling `runApp` at all, so the
*OS* launch image covered the wait, and `isNewIdentityProvider` was a plain bool pushed in through a
`ProviderContainer` override once the answer was already known. That cannot produce the design's own
note on the Splash frame — "the mark is a Hero — it flies to the top-left of Welcome rather than
cutting" — because a route that does not exist yet cannot animate into one that replaces it. Now
`runApp` fires immediately, `authBootstrapProvider` is a real `FutureProvider` `main()` kicks off
without awaiting, and `SplashScreen` (the router's actual `initialLocation`) watches it and calls
`context.go` the instant it resolves. "Skip the splash entirely" for a fast check needed no special
casing: there is no artificial minimum hold anywhere in this, so a launch that resolves before the
first frame's `ref.listen` even fires just never shows a second frame of it.

**Welcome was rebuilt to the mockup, not kept as the from-scratch animated scene it had become** —
a real, deliberate choice, not a default: the previous version (falling groceries into a basket,
gradient blobs, a spinning wheel) was a legitimate creative take in the same spirit as decision #50's
"adapted where it names the prototype," but this session's brief was to match the design *exactly*,
which that scene structurally could not do (different content, no top-left mark for the Hero to land
on). Asked directly, rebuilding to the mockup was the answer, so the animation code
(`welcome_screen_animations.dart`, `blob_background.dart`, `cart_painter.dart`,
`grocery_item_shapes.dart`) was deleted rather than kept unused. The tilted list-preview card, its
checkmark rows and the floating "added a product" activity bubble are traced from the design's own
markup; the bubble's sample name is "koliiin" rather than the mockup's own placeholder, per direct
instruction — the one hardcoded display name anywhere in the app, and commented as such since it is
not a real session's data. `BasketMark` (`widgets/basket_mark.dart`) draws the design's own basket
SVG path with a `CustomPainter` rather than shipping an image asset, so one glyph can be recoloured
and resized for both Splash's badge and Welcome's small mark and still share a `Hero` tag.

**Onboarding gained a fourth step and its first real i18n.** Every string in the wizard (headlines,
placeholders, the step indicator's "Step X of Y", the continue button) was hardcoded English before
this pass, despite the rest of the app running through `slang` for five locales — an omission, not a
choice, now fixed with new `welcome` / `onboarding` / `splash` / `join` translation sections across
all five `.i18n.json` files. `OnboardingStep` gained `invite`, matching the design's own Step 4
("Shopping with someone?"), which meant moving `OnboardingController.finish()` (now `submit()`) to
fire on the *Shops → Invite* transition instead of at the wizard's end — Invite needs the real list's
join code to show, so the list has to exist before that step renders. The one thing this could not
inherit from the design's own click-through prototype: `submit()` is a real network round trip, so
`Back` from Invite to Shops and pressing Continue again had to be guarded (`state.createdList != null`
short-circuits straight back to Invite) — the design's own state machine just mutated local arrays and
had no such failure mode to guard against. **Also kept, deliberately, not by default:** Step 1's
design frame shows a shake-on-invalid-submit micro-interaction; this app's continue button instead
hides itself until the step is valid (`OnboardingState.canContinue`), the same pattern already used
for every other step — recreating one step's shake would mean two different "what happens when this
step isn't done yet" conventions in one wizard for no visible gain.

**Joining by code is its own controller and screen (`JoinFlowController` / `JoinFlowScreen`), not a
second mode bolted onto `OnboardingController`.** The two flows share exactly one step in the design
(the name) and diverge completely after it; a shared state machine would mean every onboarding-only
field (list name, shop drafts) growing a "not applicable on this path" case. Explicitly scoped in:
`JoinList` and `JoinCode` already existed domain-side (built for the signed-in "add another list"
dialog on `ListsScreen`), so wiring Welcome's "I have an invite code" through to a proper name → code
→ confirmation flow was smaller than it first looked. Explicitly scoped out, and named rather than
silently cut: the design's QR code and "Scan QR instead" — a QR generator and a camera-scanning
package are both real new dependencies this session did not add, so the invite step and the join
screen show the code as text (via the existing `InviteCard`) and nothing else. `JoinCodeInput`
currently renders a single working field (uppercased, capped at 5 characters) rather than the design's
five separate auto-advancing boxes — left as a named follow-up with a working fallback already wired
end to end, rather than blocking the rest of the flow on it.

**Found along the way:** `AddShopStep` was the first screen in this feature to get an actual widget
test, and it immediately caught a real bug the previous, testless state had been shipping — a plain
`Column` (title, shop rows, the "add a shop" button, then a `Spacer`, then the tabs preview) overflows
once there are enough shops or the keyboard shrinks the viewport. Fixed by splitting it the way the
design's own markup already does: the shop list scrolls in its own `Expanded`, and the tabs preview
stays pinned below as a fixed footer, never inside the scrollable area.

## 61. The join-code input is now the real segmented boxes; the add sheet inherits the active shop tab; the completion celebration is built

**Decision:** Three independent fixes/additions landed together — user-reported bugs plus the one
piece of decision #60 that was deliberately left as a working placeholder.

**`JoinCodeInput`'s five boxes are real now, not the interim single field.** The insight that made
this simple rather than five hand-rolled `FocusNode`s: the design's whole interaction — type and the
"cursor" hops forward, backspace on an empty box steps back and clears it, pasting a full code fills
every box — is already exactly what happens to a plain string in one ordinary text field on delete or
paste. There is no real per-box focus to hand off, only the *look* of five boxes. So one real
`TextField`, fully transparent and sized over the whole row, does the actual editing (keeping the
platform keyboard, paste and SMS-autofill suggestions working for free); five read-only boxes drawn
underneath just reflect its text and highlight whichever box is next. Tested directly — typing,
backspacing, pasting a full code, and the 5-character cap — rather than only through the join flow's
own end-to-end test, since the boxes' own correctness (right character in the right box) is a
different claim than "the flow works."

**`AddItemSheet` now pre-selects whichever shop tab is active when it opens.** `ItemsSection` already
watched `shopFilterProvider(list.id)` for filtering; threading that same value into the sheet as
`initialShopId` was the whole fix. Guarded against a stale filter (the shop was deleted by someone
else between opening the tab and opening the sheet) by falling back to "no shop" unless the id is
actually still one of the list's shops — the same defensive check `activeShopColorProvider` already
makes for the same reason. Still just a starting point, not a lock: the existing shop chips let it
be changed before saving.

**The completion celebration (`CompletionCelebrationCard`) is built.** `AppRadii.celebration` and
`AppMotion.celebrate`/`AppMotion.spring` had existed since early in the project, unused — this is
what they were for. Shown when every item on the *whole list* is checked (not just the active shop
tab, matching the design's own `allDone` check), it offers "Keep list" (dismiss) and "Clear checked"
(the same `ItemsController.clearChecked` the Done divider's own button already calls — not a second
implementation of "clear everything checked"). The dismissal is provider state
(`CelebrationDismissed`, family-keyed by list id), not widget state, for the same reason as the
"recently checked" hold (#47): a rebuild must not forget it. It resets itself the moment the list
stops being fully checked — an item added, unchecked, or cleared — so the *next* time the list is
completed, the card shows again rather than staying silenced by one long-ago tap; verified with a
test that dismisses, re-opens the list via a live update, completes it a second time, and checks the
card is back. The spring entrance (`AnimationController.animateWith(SpringSimulation(...))`,
`AppMotion.spring`) is deferred a frame via `addPostFrameCallback` so `AppMotion.reduced` has a built
`context` to read `MediaQuery` from; reduced motion collapses it to a static appearance, per the
motion spec's own explicit fallback note for this exact card. **Noted, not fixed:** once the list is
fully checked, "Clear checked" is now genuinely offered in two places (the Done divider and this
card) — both call the same use case, so there is nothing to get out of sync, and duplicating a
one-tap action across two natural places a person's eye might land felt better than hiding one of
them for the sake of there being exactly one button.

## 62. Add-control polish (Flow 09) — the first item off the design-gap plan

**Decision:** `QuickAddBar` now matches the re-export's own refinements rather than the earlier
build's simpler shop-tinted-pill treatment. Traced from the design's own four frames (resting →
rolling open → open+empty → text entered): resting is a solid circle "tinted to the active shop";
open, it "flattens into the sheet-adjacent surface" — the pill itself goes back to a plain
`colorScheme.surface` with a hairline border, and the shop's colour survives as two smaller things
instead: a leading dot before the text, and the trailing button's own fill, which doubles as the
answer to "is there anything to commit" — grey and muted while empty, shop-coloured the instant
there is text. The placeholder itself is now shop-aware ("Add to Colruyt" vs. a generic prompt on
"All"), reusing `theme.colorScheme.primary` for the colour (already the active shop's colour end
to end, since selecting a tab re-themes the whole app — decisions #32) rather than plumbing a
second colour value through for the same thing.

**Found and fixed along the way, not originally scoped:** the fast Enter-path (`onQuickAdd`) never
tagged the new item to the active shop tab at all — only the detail sheet did, after the previous
session's fix. The design's own "5 · Enter — committed" frame shows the new row landing under the
active shop's group, confirming the fast path is supposed to tag too; fixed to match, and to match
the user's own direct ask that whichever shop tab is active is what a fast add should land in by
default, changeable via the detail sheet, not skipped by it.

**The new-row entrance** (scale 0.94 → 1, a tinted flash fading over 900 ms, `lightImpact()`) is
driven by a `RecentlyAdded` provider mirroring `RecentlyChecked`'s own shape (a `Timer`-backed
family provider, so it survives a rebuild) — but with a narrower job: `ItemTile`'s own `initState`
reads it once, at the moment a new row's tile first mounts, and plays the whole 900 ms locally from
there. The flag only has to be right for that one build, not for the full 900 ms the way
`RecentlyChecked`'s hold does, which is what makes reusing the same "read once at mount" trick
sound rather than a coincidence. Scoped to this device's own adds only — a live snapshot bringing
in someone else's new item does not flash — matching the literal frame it comes from ("Enter,
still open," the person who is typing watching their own row land), not extended into realtime
sync's own separate territory.

**Found by a debug-mode assertion, not by inspection:** the tint was first built as a plain
`DecoratedBox` wrapping the row's `ListTile`; Flutter's own runtime check caught that a `ListTile`
paints its splashes on the nearest `Material` ancestor, and a coloured `DecoratedBox` sitting
between it and that ancestor would hide them. Fixed by using a `Material` for the tint instead,
which is also the correct semantic choice, not just a workaround.

## 63. `AddItemSheet` and `ItemEditorDialog` are now one `ItemSheet`

**Decision:** Second item off `docs/design-gap-plan.md`'s build order. The design's own note —
"the same sheet, titled Edit product and with a Remove action, is what a row tap opens later; one
component, two entry points" — named a real duplication: `AddItemSheet` and `ItemEditorDialog`
already did almost the same thing (name, quantity, note), and `ItemEditorDialog` was a centred
`AlertDialog` while the design draws editing as the same bottom sheet adding uses. Replaced both
with `ItemSheet`, one widget with two named constructors (`.add`, `.edit`) that decide the mode
from whether an `item` was given — no separate boolean to drift out of step with it. Its result is
a small sealed type, `ItemSheetOutcome` (`ItemSheetSave` / `ItemSheetRemove`), rather than a
nullable-field record: a `switch` on it has to handle both outcomes, with no silent third "neither"
shape to forget the way an ad hoc boolean-plus-optional-fields shape would allow.

**A real capability gained, not just a merge:** `ItemEditorDialog` never let a shop be changed —
`onEdit` always passed `shopId: item.shopId` straight through, unchanged. `ItemSheet.edit`
pre-fills the item's current shop into the same chip picker `.add` already has, so editing can now
retag an item to a different shop. This is the first piece of decisions #53's deferred "Move"
action to land — not the whole thing (there is still no bulk multi-select move), but the
single-item case no longer has *no* way to do it at all.

**New title and button copy, traced from the same frame the unification note comes from:** "New
product" / "Edit product" as the sheet's own heading (previously neither sheet had one), "Save"
rather than "Add item" for the edit path's primary button (matching `ItemEditorDialog`'s own
correct prior convention, not `AddItemSheet`'s).

## 64. Item-name suggestions: a real backend capability, shared by the add control now and search later

**Decision:** Third item off `docs/design-gap-plan.md`'s build order, and the first that needed
real server work rather than pure client polish. New `ItemNameHistory` model
(`freshcart_item_name_history`), one row per distinct name per list (a unique index on
`(listId, name)`), written to on every successful `ItemService.add` — an upsert (find by
`listId` + exact `name`, bump `lastUsedAt` or insert fresh), not a fresh row per add, and
deliberately case-sensitive at the unique-index level even though the read side matches with
`ILIKE`: "Milk" and "milk" persist as two rows, a simplification stated rather than an oversight.
**Why a new table rather than deriving suggestions from `ShoppingItem` itself:** checked directly
against the server code — `ItemService.remove`, `clearChecked` and `removeMany` all call
`deleteRow`/`deleteWhere` (a hard delete, no `isDeleted` flag) — so a name's history would
disappear from `ShoppingItem` the moment the item did, which is most items eventually, and exactly
when a suggestion for it (re-adding something just cleared off a finished list) would be most
useful.

**The history write must never fail the add it rides along with.** `_recordNameHistory` is wrapped
in its own `try`/`catch` inside `ItemService.add`, discarding any error — the same reasoning
`_announce`'s own fire-and-forget push already uses in this file: a person who just successfully
added "Milk" must never see that fail because a bookkeeping insert for suggestions had a problem.

**Query side:** `ItemService.suggestNames` enforces a two-character floor before touching the
database at all (matching one letter would surface most of a list's history at once, noise rather
than a suggestion) — checked both server-side (defence in depth) and client-side, in the new
`itemSuggestionsProvider`, so a too-short query never even reaches the network. Scoped per-list,
not household-wide, per the design-gap-plan's own resolved decision, and ordered by `lastUsedAt`
descending, most recently used first.

**Client-side debouncing, not per-keystroke requests:** `QuickAddBar` (now a
`ConsumerStatefulWidget`, its first use of Riverpod directly rather than through callbacks its
parent supplies) holds its own 300&nbsp;ms `Timer`, only advancing `_debouncedQuery` — and only
then watching `itemSuggestionsProvider` — once typing pauses. A network call fired on every
keystroke would mean several in-flight requests racing each other for every word typed, and
answering out of order.

**Scope, named rather than silently expanded:** this pass wires suggestions into the add control's
own chip row (§09's frame 4 — "Olive oil", "Olives", "Olive tapenade" riding just above the
field), matching what was actually asked for. Flow 06's "Recently bought" section on the search
screen wants the exact same underlying capability and is now fully unblocked (`itemSuggestionsProvider`
and the server endpoint are generic, not add-control-specific) but was not itself built in this
pass — a small, separate follow-up UI piece, not a backend gap any more.

## 65. Drawer enrichment (Flow 10, §4) — member avatars and inline create/join, remaining count deferred

**Decision:** Fourth item off `docs/design-gap-plan.md`'s build order, and deliberately only half
of §4. Built: a small overlapping-avatar stack per list row (capped at three, a "+N" circle for
the rest), showing who else — not the viewer's own row — is on each list; and the two inline
"New list" / "Join a list" rows decided earlier, drawn inside the scrollable list of lists itself
rather than tucked into the footer, matching the design's own frame. Not built: "6 left" / "All
done" remaining-item counts. That half needs each list's own item counts, which the drawer does
not currently fetch, and getting it right means a lighter per-list summary the drawer can call
without N item-list fetches for N lists open at once — the same "no aggregate-function escape
hatch short of raw SQL, do small parallel calls instead" shape `ItemService` already uses
elsewhere, not something to bolt on as a side effect of an avatar-stack change. Left as its own
future backend piece rather than widened into here.

**Reused rather than duplicated:** the avatar stack's colouring calls the same
`AppColors.avatarColorFor` member rows and item "checked by" chips already use, keyed off
`ListMember.userId.value`. The two inline rows call the exact same `showCreateListDialog` /
`showJoinListDialog` `ListsScreen` itself uses (decisions #63's "one component, more than one
entry point" reasoning, applied again) — no second copy of either dialog's flow to keep in sync.

**A real bug found and fixed along the way, not a hypothetical one:** wiring the inline rows into
`ListsDrawer` at first passed the drawer's own `WidgetRef` straight into the shared dialog
functions, the same way every other call site in the app already worked. It compiled, and by
inspection looked identical to the existing `ListsScreen` call sites. A widget test tapping
through the actual flow — enter a name, tap Save — caught what inspection didn't: `Riverpod`
throws `StateError: Using 'ref' when a widget is about to or has been unmounted is unsafe`,
because the row's own `onTap` pops the drawer (unmounting `ListsDrawer`) *before* the dialog's
`onSubmit` ever runs — sometimes seconds later, once someone actually finishes typing. A `ref`
captured from a widget's `build` does not outlive that widget; a dialog opened *after* that widget
closes needs something with its own lifecycle instead. Fixed by changing
`showCreateListDialog`/`showJoinListDialog` to take a `ProviderContainer` rather than a
`WidgetRef` — grabbed once via `ProviderScope.containerOf(context, listen: false)` *before* the
pop, at every call site (both of `ListsDrawer`'s new rows, and all four existing ones in
`ListsScreen`, for consistency, though only the drawer's were ever actually unsafe). Worth calling
out on its own: this is exactly the kind of bug `CLAUDE.md`'s "tests live beside the phase that
adds the feature" rule is for — it would not have been caught by `flutter analyze`, only by
actually driving the interaction.

## 67. The completion celebration gets its confetti back — #61's "no confetti" was an under-build, not a recorded trade-off

**Decision:** `CompletionCelebrationCard` (decisions #61) shipped as a card with no particle
effect, and its own doc comment said so — "no confetti or full-screen takeover" — as if that were
a considered simplification. It wasn't recorded as one here, though, and re-reading the Motion &
Interaction Spec's §09 ("Signature moment — completing the whole list") directly, it's explicit and
fairly precise: *"400ms: Confetti, but restrained: 14–20 particles in the list's shop colours
only, gravity fall, 1.4s, no repeat. Skip entirely if reduced-motion is on."* That's not an
invitation to interpret loosely — the spec calls this "the one place the app is allowed to be
theatrical," and then immediately hedges it with exact bounds. Skipping it was a quiet scope cut,
not a design call, so it's fixed now rather than left as a permanent gap with no justification
behind it.

**Revised after hands-on testing:** the spec's literal 14–20-particle count, spawning just above
the screen and gently raining in, read as sparse and flat in practice — not the "one place the app
is allowed to be theatrical" the spec itself calls it. Two changes, not just "add more": particles
now spawn already spread across the top ~22% of the screen (a burst that's partly in view the
instant it fires, not one that has to scroll on from off-screen first) with a stronger initial
sideways/upward kick, and each one now tumbles — a second, independent rotation (`flip`) drives a
`canvas.scale(cos(flip), 1)` squash, so a piece reads as flipping end-over-end like a real card
catching the light, not spinning flat like a coin on a table. The count went up too (roughly
24–36, from 14–20) but that came second — motion and spawn shape were the bigger lever, and are
worth understanding before reaching for "more particles" as a first move next time.

**`ConfettiBurst.fire`** is a static, one-shot call, not a widget you mount — it inserts its own
`OverlayEntry`, drives its own `Ticker`, and removes both when the 1.4s is up. Kept out of the
widget tree deliberately: nothing about a fire-and-forget visual event should need a
`StatefulWidget`'s lifecycle wired into `CompletionCelebrationCard` just to clean itself up.
Physics (`ConfettiParticle.tick`) is a plain, `Canvas`-free method — position and velocity in,
position and velocity out — kept separate from `_ConfettiPainter` so the "is this actually gravity"
question never depends on how it's drawn.

**"The list's shop colours only"** is read as `ItemsSection`'s own `shops` for this list, not
every colour the app knows about — a shopless list (nothing tagged) falls back to
`AppColors.presetShopColors` rather than the confetti call silently receiving an empty palette
and rendering nothing. Colours are handed to `CompletionCelebrationCard` as a parameter rather than
re-derived inside it, so the card never needs its own opinion about that fallback — `ItemsSection`
already owns it for the rest of the screen (the shop tab strip, the add sheet).

**Reduced motion** is checked once, at the call site inside `CompletionCelebrationCard`'s existing
`AppMotion.reduced(context)` branch — the same branch that already decides between the spring
entrance and a static appearance — rather than duplicating that check inside `ConfettiBurst`
itself. A static utility method deciding motion-preference on its own would be a second source of
truth for the same question this widget already answers once per build.

**A second real bug, this time a leak, also caught by a test rather than by reading the code:**
the first version of `ConfettiBurst.fire` started its own `Ticker` with no link back to whatever
widget triggered it. `flutter test` refused to let a later, unrelated preview test run after the
completion-celebration one — "An animation is still running even after the widget tree was
disposed" — because nothing had told the confetti's `Ticker` to stop when
`CompletionCelebrationCard` (and, in the preview test's case, its whole screen) got disposed
before the 1.4s naturally finished. Fixed by having `fire` return a `ConfettiBurstHandle`, which
`_CompletionCelebrationCardState.dispose()` cancels — one shared `finish()` closure serves both
the natural end-of-burst path and an early cancel, guarded so whichever fires first is the only
one that actually tears down the `Ticker`/`OverlayEntry`. Same lesson as the `ProviderContainer`
bug below: this is a runtime lifecycle problem `flutter analyze` has no way to see, only a test
that actually drives the widget through disposal.

## 68. The "all lists" screen is gone — there was never a browser in the design, only a switcher

**Decision:** `/lists` (`ListsScreen`) rendered a plain `ListTile` per list under a generic
`AppBar` — early scaffolding, and it showed. Checking the actual design (`Flow Screens.dc.html`,
Flow 10) rather than assumption: there is no "all lists" screen in it at all. Its own words —
*"The drawer answers 'which list?' and nothing else — switching is one tap from anywhere"* — and
its drawer mockup already shows the complete list-switching UI (remaining counts, avatars,
New list/Join a list/Manage shops/Settings), which decisions #65 had already built. `ListsScreen`
was never actually part of the intended design; it just predated the drawer taking over its job
and was never revisited.

**What's left at `/lists`, and why it isn't simply deleted:** the route is still real, because two
things about it are. First, it's still the parent route for `/lists/:listId` and everything nested
under it — removing the path would break every list detail URL. Second, one of its states *is* in
the design: §11's "No lists yet" empty state, reachable only by deleting your last list. So
`ListsScreen` now does exactly two things: while `listsControllerProvider` is still loading, and
for that one genuine empty case. The instant there's at least one list, a `ref.listen` — the same
one-shot listen-and-`context.go` idiom `SplashScreen` already uses for its own "decide where to
actually go" job — sends the user straight into their first list's detail screen, and the
populated `ListView` branch this screen used to have is gone; there is no path left to reach it.

**A race worth naming, since it cost a debugging pass:** that `ref.listen` originally read
`next.value` unconditionally. `ref.invalidateSelf()` (what every mutating method on
`ListsController` calls after a successful write) deliberately keeps the *previous* value visible
through `.value` while the refetch is in flight, so a list doesn't flash empty mid-reload. Deleting
your only list therefore transitions through a loading state that still reports the old,
now-stale, non-empty list — and an unguarded listener redirects on that stale value, straight back
into the list that's mid-deletion, before the real (empty) result ever lands. Fixed by skipping the
check entirely while `next.isLoading` is true; only a genuinely settled value is acted on. Two
widget tests exercise this directly (deleting your last list, and a list someone else deletes while
you're viewing it) rather than trusting that "it redirects" is enough — both go through the exact
refresh-then-navigate sequence a real deletion does.

**The "someone else deleted it while you were looking" case gets the same fix from a different
angle.** `list_detail_screen.dart`/`household_screen.dart`'s `ErrorScreen.onExit` used to be a bare
`context.go(Routes.lists)`. With the browser gone, that route now redirects using whatever
`listsControllerProvider` currently has cached — and nothing had ever told that cache the
now-inaccessible list should drop out of it, since the detection came from `listByIdProvider`'s own
live stream, a completely different provider with no automatic link back. Left alone, "Back to
your lists" would have silently bounced straight back into the same error. Fixed by having
`onExit` call `listsControllerProvider.notifier.refresh()` (fire-and-forget, wrapped in
`unawaited` — the navigation itself doesn't need to wait on it) immediately before navigating.

**Two more mismatches removed for the same reason, not just the screen itself:** Settings'
"Manage lists" row pushed straight to `Routes.lists` — a redundant door to a screen that shouldn't
be a destination, and not a row the design's own Settings section has (Flow 10: "Settings stays
one screen deep with four short groups; a household shopping app should never grow an admin
console"). And the drawer's own "All lists" footer button, which did the same — doubly redundant,
since the drawer already shows every list inline above it. Both removed; the drawer's own
now-stale class doc comment (still describing a pre-#65 world where create/join "already have a
home on `ListsScreen`") corrected to match what's actually true now.

## 69. `ListSettingsScreen` — #68 was wrong to remove Settings' "Manage lists" row outright

**Decision:** #68 concluded there was no "manage lists" concept in the design's Settings screen
and removed the row entirely. That was incomplete research, not a design call — the actual
mockup has "Manage lists" as a real row in Settings' "Lists & shops" group, sitting alongside
"Manage shops" and "Household," and a fully-specified "List settings" screen exists too (name,
Members, Behaviour, Leave/Delete at the bottom "alone... with a rule above them"). The row is
restored, now pointing at a real screen rather than the removed browser.

**What the design leaves genuinely unspecified:** it shows the Settings *row* and, separately, the
destination *screen*, but never mocks up what sits between them when there is more than one list
to choose from. Rather than invent a picker screen nothing in the design calls for, `ListSettingsScreen`
is opened directly for `firstList` — the same convention `_ListsAndShopsSection` already uses for
its sibling "Manage shops" and "Household" rows, both of which already treat "the first list" as
the implicit current one. Consistent with existing choices beats inventing new UI to fill a gap
the design never actually asked to be filled.

**Members and shops are rows that open the existing screens, not sections rebuilt inline** (a
choice made explicitly, not by default — see the human's own steer on this). The mockup draws
member rows and a shop count directly on the List settings screen, merged into one view. But
`HouseholdScreen` and `ManageShopsScreen` already exist, already work, and are already reached
from elsewhere — rebuilding their content a second time here would be exactly the "second copy of
a flow to keep in sync" this codebase has repeatedly avoided elsewhere (decisions #63, #65). The
shop row shows a plain count (`shopsControllerProvider(listId).length`) rather than the mockup's
"3 of 4" (shops actually used vs. total) — that ratio needs both items and shops loaded together
to compute, a small new piece of derived state that wasn't the actual ask here and is a reasonable
follow-up, not a silent gap.

**`confirmDeleteList`/`confirmLeaveList` are now shared top-level functions**, extracted out of
`_ListMenu` (`list_detail_screen.dart`) into `list_danger_zone_actions.dart`, rather than a second
copy of both dialogs living on the new screen. Both still take a `WidgetRef`, not a
`ProviderContainer` — unlike the drawer's create/join rows (decisions #65), nothing here pops the
calling screen before the dialog resolves, so the `WidgetRef`-unmounted hazard that bug was about
does not apply.

**Deliberately missing: "Clear checked after shopping."** The mockup shows it as a toggle, but
`ShoppingList` has no field for it, and "after shopping" is not yet a real, defined moment
anywhere in the domain — it would need an actual decision (all items checked? every shop tab
clear? something explicit a person taps?) plus a new field and a migration, not just a switch
wired to a guess. Left out rather than guessed at; a real follow-up, not a silent gap, since the
screen's own doc comment says so.

## 70. Dark mode's unreadable buttons — a variable-name collision, not a design flaw

**Decision:** `AppTheme._build` had a local `ink` variable meaning "whichever text colour suits
this brightness" (white in dark mode, near-black in light) — correct for text, but three `on*`
colour-scheme roles (`onPrimary`, `onSecondary`, `onTertiary`) reused that same local when the
*neutral* theme (no active shop — the app's default state on most screens, since it only shifts to
a shop's colour while a shop tab is actually selected) needed the fixed `AppColors.ink` instead.
In dark mode this made `primary == onPrimary` (both white) and the same for `secondary`/`tertiary`
— any `FilledButton`, `FloatingActionButton`, or checkbox reading those roles rendered background
and foreground in the identical colour. Not a seed-colour contrast problem (`AppTheme.forShop`'s
own `_onColorFor` luminance check, added earlier, already guards that correctly) — a plain
copy-paste-shaped bug sitting right next to code that had the correct pattern (`buttonBg`/
`buttonFg`, a few lines up, already computed this same "ink-on-paper, inverted per brightness"
pairing correctly). Fixed by giving the "on" side its own `onNeutralPrimary` value, computed from
`AppColors.ink` rather than the brightness-dependent local.

**Never caught by any existing check:** `flutter analyze` has no way to see two `Color`s being
equal — this is a runtime value bug, not a type or lint issue. Nothing in the test suite asserted
anything about the theme's own internal contrast before now. Added
`test/core/theme/app_theme_test.dart` — plain `test()`s (no widget pumping needed, since this is
pure `ColorScheme` value inspection) asserting `primary != onPrimary` etc. for the neutral theme in
both brightnesses, and for `AppTheme.forShop` across a spread of real colours including the
edge cases most likely to break a luminance check (pure black, pure white). Exists specifically so
this exact class of bug — two theme roles resolving to the same colour — cannot silently return.

## 71. The add control was a docked bottom bar, not a floating one — and the whole-app re-theme ran on the wrong token

**Decision:** Two separate visual mismatches, found by comparing the running app against Flow 09's
own mockup and the motion spec's token table directly, rather than by screen-hunting.

**The add control (`QuickAddBar`) was laid out as the last child of `ItemsSection`'s own `Column`**
— a docked row sharing space with the item list, which shrank via `Expanded` to make room for it.
Flow 09 calls it "the FAB" throughout and is explicit ("Bottom-right so it never sits under the
reading path") that it floats *over* the list, not beside it. Fixed by restructuring
`ItemsSection.build` into a `Stack`: the item list (loading/error/empty/search/populated, all of
it) as a `Positioned.fill` base layer, and the completion celebration + add control as a
`Positioned` overlay anchored to the bottom. `_ItemList`'s own `ListView` gained
`padding: EdgeInsets.only(bottom: 84)` so its last rows clear the floating cluster instead of
rendering underneath it — the inverse of before, where the list was *shrunk* to make room; now it
fills the space and the floating cluster sits on top with clearance reserved for it.

**Three motion details inside `QuickAddBar` didn't match §09's own frame-by-frame spec**, each
checked against the design doc directly rather than assumed: the roll-open width animation ran on
`_reveal`'s raw linear value (`AnimationController` has no curve of its own) where the spec calls
for "260ms, easeOutQuint on width" — fixed by curving through `AppMotion.sheet` before using the
value for width, fill colour, and border alpha, which all rode the same progress already. The
glyph rotation used `AppMotion.enter` (`easeOutCubic`) where the spec calls for "easeOutBack" —
fixed to `AppMotion.pop`, wrapped in `AppMotion.curveFor` so its overshoot still collapses under
reduced motion, per the app's own stated rule. The placeholder text's fade-in window was `(x-0.4)
/0.6` (a 60% window starting at 40% progress) where the spec says "fades in over the last 40%" (a
40% window starting at 60%) — fixed to `(x-0.6)/0.4`.

**The whole-app re-theme (`AnimatedTheme` in `app.dart`) ran on a hardcoded 400ms/`easeInOut`**,
not any token from `AppMotion` at all. The motion spec's own duration/curve table assigns
"colour tint" to `quick` (180ms, `easeOutCubic`) explicitly — the same token chip selection and
row strike-through already use elsewhere in the app. More than double the duration, and a
symmetric ease rather than the app's consistent asymmetric "fast in" convention, made the single
biggest colour-tint moment (switching shop tabs re-themes the entire screen) run at a visibly
different rhythm than every smaller colour-tint moment around it — the likely source of a
transition that was hard to fault specifically but "didn't feel quite right." Fixed to
`AppMotion.durationFor(context, AppMotion.quick)` / `AppMotion.enter`, which also closes a real
accessibility gap the hardcoded value had: a fixed duration never respected reduced-motion at all,
contradicting the motion spec's own "every non-essential animation checks this" rule.

## 72. Welcome screen's preview mockup was hardcoded to light mode — the actual "white on white" was two colours from two different sources

**Decision:** `_ListPreviewCard`, `_PreviewRow`, and `_ActivityBubble` (the tilted list mockup and
"koliiin added pasta" bubble on the Welcome screen) were built entirely against fixed
`AppColors.*Light` constants — never an `isDark ? ... : ...` branch, never `Theme.of(context)`, in
any of the three. The reported symptom ("white font colour on white background") wasn't one bug,
it was two independently-correct-looking pieces of code that stopped agreeing the moment dark mode
was active: the card's own background stayed hardcoded light (a real, visible bug on its own —
"bright white" in dark mode, per the human's first report), while the activity text beside it had
*no* explicit colour and correctly inherited the screen's ambient, theme-aware text colour — white
in dark mode, exactly like the headline text a few lines up in the same file already does
correctly. Two things each doing something locally sensible produced white-on-white together.
Fixed by making the card backgrounds, dividers, borders, and non-inherited text colours in all
three widgets theme-aware (`theme.colorScheme.surface`/`onSurface`/`onSurfaceVariant`/
`outlineVariant`), rather than patching the text colour alone — that would have hidden the
symptom without fixing the actual bug (a card that still never left light mode).

**Checked, not assumed, that this was isolated:** grepped the whole app for the same
`AppColors.*Light` constants used outside `app_theme.dart` itself. Two other hits, both legitimate
on inspection: `onboarding_continue_button.dart` already branches on `isDark` correctly, and
`splash_screen.dart`'s use of `AppColors.bgLight` is against a fixed `AppColors.ink` background —
a splash screen deliberately keeping the same ink-and-cream brand mark regardless of theme, not a
missed dark-mode case. This bug's actual scope was exactly the three Welcome-screen mockup
widgets, not a systemic pattern worth a wider sweep.

## 73. Shop tint is scoped to the list-detail subtree — `activeSeedColorProvider` is gone

**Decision:** First item off `docs/upgrade-design-guide.md`'s Priority 0. Since decision #32,
selecting a shop wrote into `activeSeedColorProvider`, a single global piece of state `app.dart`
read to re-theme the *entire* `MaterialApp` — chrome included. The design's own rule is that shop
colour reaches selected tabs, checks, focused inputs, the quick-add control and empty-state tint,
while the surrounding chrome (drawer, settings, dialogs, navigation transitions) stays neutral.
The global mechanism could not express that distinction; it re-themed everything or nothing.

**Fix:** `app.dart` is now permanently seeded from `AppTheme.brandSeed` — nothing in it varies with
the active shop any more. `ListDetailScreen` wraps only its own `body:` (not the `Scaffold`, so the
`AppBar` and `drawer:` stay siblings of it, on the ambient neutral theme) in a local
`AnimatedTheme`, seeded from `ref.watch(activeShopColorProvider(listId))` directly. This is the
`AppTheme.forShop` pattern the theme file's own class doc already documented as the intended
per-subtree usage, but nothing had actually called it that way until now.

**What this deleted, not just changed:** `ListDetailScreen` used to push the shop colour into the
global provider via `ref.listen`, and had to carefully reset it on `dispose()` with a
`scheduleMicrotask` + `selectIfAlive` guard (so a fast pop-then-navigate-away didn't write to a
provider that had already torn itself down) so the lists screen wasn't left wearing a shop's
colour after leaving it. None of that exists any more: a locally-scoped `Theme` cannot leak past
its own subtree's lifetime, so there is nothing to reset on the way out. `activeSeedColorProvider`
itself (`core/theme/active_seed_color_provider.dart` + its `.g.dart`) is deleted outright, not
deprecated — nothing else in the app ever read it.

**Motion carries over unchanged:** decision #71's tuned token (`AppMotion.quick`, 180ms
`easeOutCubic` — the motion spec's own "colour tint" entry) moved with the mechanism to
`ListDetailScreen`'s new local `AnimatedTheme`, rather than being retuned. `app.dart` keeps its own
`AnimatedTheme` too, but now purely for smoothing a light/dark `Appearance` change — it no longer
has a shop colour to glide between.

**Test coverage moved, not just updated:** `app_shell_test.dart`'s "theming" group used to prove
selecting a shop re-themed the app root; that premise is gone, so those two tests are deleted
rather than patched, leaving one narrower test that the root is *always* neutral. The real
coverage — a shop tinting the body, and that tint stopping at the drawer — is new, in
`list_detail_screen_test.dart`, which resolves `Theme.of(context)` from inside `ItemsSection` and
separately from inside `ListsDrawer` after opening it, so the "does not leak sideways" claim is
checked against an actual element in each subtree rather than inferred from the FAB or a chip's
own colour (both of which take their colour from `effectiveShopColorProvider` directly and would
have passed even before this fix, telling this specific regression nothing).

## 74. `ItemTile` rebuilt as `ProductRow` — the row now opens editing, the leading circle checks

**Decision:** Priority 0 item #3. `ItemTile` was `ListTile` + a permanent edit `IconButton`;
Component Library §01 draws `ProductRow` as `InkWell` + `Row`, with the row itself opening editing
and no permanent edit affordance at all. Matching that is a real interaction change, not a
re-skin: checking an item used to be a tap anywhere on the row, and is now the leading circle's
job specifically, freeing the row's own tap for editing. The leading circle got its own
independent `GestureDetector` (`ItemTile.checkKey`, a shared key across rows the way
`find.byType(Checkbox)` used to be type-based rather than id-based) nested inside the row's outer
`InkWell` — the same "child tap wins over parent" composition `Checkbox` inside `ListTile.leading`
already relied on, just built by hand once `ListTile` was gone.

**`_CheckCircle` replaces the stock `Checkbox`, not just restyles it.** The reference's own
22px-circle "CheckCircle" is a named component with its own states (§02): unchecked outline,
checked-and-filled, and a 340ms `easeOutBack` fill overshoot specifically on *checking* — "because
the user did it" — with a plain reverse on unchecking, no overshoot. That asymmetry already existed
in this file for the strike-through (`_strike.forward()` vs `.reverse()`, "the intent is
unambiguous"); `_checkFill` is the same shape, a second `AnimationController` rather than folding
into `_strike`, because the two animate different things (a scale-in disc vs. a wipe) on
overlapping but not identical triggers. The tick's own "fades in 80ms behind the fill" is
approximated from the same fill progress (`(fill-0.3)/0.7`) rather than a third controller for 80ms
of motion — a deliberate simplification, not an oversight.

**The fill colour is `colorScheme.primary`, deliberately not `ItemTile.shopDotColor`.** The
reference is explicit that CheckCircle's fill is "free when the tab's subtree is wrapped in
`AppTheme.forShop`" — i.e. it is the *active tab's* colour, while the dot beside an item's name is
that *item's own* shop, and the two can differ (search results span every shop, with the All tab's
neutral theme active throughout). Decision #73's tint scoping, from earlier the same session, is
what makes reading `Theme.of(context).colorScheme.primary` directly the correct thing to do here —
this rebuild would have inherited the old bug (every check circle either always shop-tinted or
never) had #73 not already landed first.

**Quantity always shows now** (`x1` included, not just `item.quantity > 1`), and the note glyph is
gone — the note itself is the subtitle line, which already existed; only the redundant icon needed
removing. **Selected rows** get the reference's `#F1F0EB`/dark-equivalent background, matched to
the existing `AppColors.selectedRowLight`/`Dark` tokens (already named for exactly this, unused
until now) with an 8px radius. **Lifted (reordering)** rows needed no change at all — elevation 8,
scale 1.03, 95% opacity were already exactly right, in `items_section.dart`'s `proxyDecorator`, not
`ItemTile` itself.

**Deliberately not built:** the reference's remote-edit (coloured edge + avatar chip) and
offline-pending (dashed edge) row states. Both need domain/application data the app does not carry
yet — a preserved realtime `actorId`, and a local outbox for offline writes — matching Priority 1
item #7's own note not to fake either from local timestamps. Left for that item, not guessed at
here.

**Test fallout, not a regression:** eight `items_section_test.dart` cases broke on this change,
all for the same two reasons — `find.byType(Checkbox)`/`find.byType(ListTile)` no longer resolve to
anything, and tapping `Icons.edit_outlined` no longer opens the edit sheet. Fixed by scoping to
`find.byType(ItemTile)` (reading `.item.isChecked` off the widget directly, which is a more honest
assertion than reading a stock `Checkbox`'s `.value` ever was) and tapping the row's own name text
where a test used to reach for the edit icon.

## 75. Priority 1 closed out: Move, the search header, and the upgrade nudge's real home

**Decision:** Three items off `docs/upgrade-design-guide.md`'s Priority 1, taken together since
none needed the others but all three closed the list of "visible flow gaps" in one pass.

**Move reverses decisions #53, on purpose, because its own stated reason no longer holds.** #53
left "Move" out of multi-select because building it meant building the app's *first* shop-picker
just to unblock one button — its own words: "not a corner to cut silently inside this feature."
That blocker is gone: `ItemSheet`'s `ChoiceChip` shop picker (decisions #63) already exists and
already reassigns a single item's `shopId` (decisions #64's suggestion chips sit right beside it).
Reusing that exact shape for the sheet — "No shop" first, then one chip per shop, each tinted —
rather than extracting a shared widget between a full edit form and a single-purpose picker sheet
is a deliberate non-abstraction: the two have different lifecycles (one saves on a separate button
press, the other commits the instant a chip is tapped) and forcing one widget to serve both would
cost more than the few duplicated lines save.

**`ItemService.moveMany` is `removeMany`'s own shape, reassignment instead of deletion.** One
transaction, not a loop of individual `save` calls — #53's original reasoning again: "Move" on a
selection is one promise ("these, all of them, to this shop"), and a loop that fails partway
through would leave the selection split across two shops with nothing clean to report. Every moved
item still announces `ItemChangeKind.upserted` over the realtime channel, same as any other edit —
a bulk operation is not a reason to skip the notification path a single edit gets.

**The controller's optimistic guess and the sheet's own cancel/error handling were both worth a
real test, not just the code reading right.** `ItemsController.moveSelected` mirrors
`removeSelected`'s shape exactly (retag locally, call the repository, roll back to the *previous*
per-item state — not a blanket "clear shopId" — on failure). Three widget tests exercise the sheet
itself: retagging and exiting the mode on success, keeping the selection on a rejected write (the
guide's own acceptance line: an error must not lose the pick), and dismissing the sheet without
choosing leaving the selection untouched — none of which the controller-level tests alone could
have caught, since they never open the actual sheet.

**The search field's border/radius/icon match Flow Screens v2's "Search, active" mockup
directly**, read off the export rather than approximated: `OutlineInputBorder` at `AppRadii.input`
(the same 12px token every other bordered input already uses), a leading search glyph, "Cancel"
moved from a leading back-arrow into the trailing actions slot — which is where the mockup actually
draws it, once looked at directly rather than assumed to be a back-arrow because that is the
platform's usual affordance. The query controller and `SearchController` provider underneath are
untouched; this was a presentation-only change, confirmed by the existing search tests needing
only their finders updated (`Icons.arrow_back` → `'Cancel'`), not their assertions about what
searching actually does.

**`UpgradeNudge` leaving the list body loses no reachable surface.** It looked like a nudge with
nowhere else to live, but two real homes already existed before this change: `AccountCard` in
Settings (decisions #56) shows the same prompt permanently while an account is anonymous, and
`EditProfileScreen` renders `UpgradeNudge` itself already. Removing it from `list_detail_screen.dart`
is confirmed safe by grep, not assumption: nothing outside those two files, plus its own dedicated
test file, referenced the widget.

## 76. Appearance's remaining pieces close out `docs/design-gap-plan.md` §7 — plus two bugs the plan never named

**Decision:** Starting into Priority 2, reading the actual code against `design-gap-plan.md`
first (per its own "written before any of it is built" framing, now stale in several places)
turned up that §5 (Settings restructure), §6 (Edit profile + avatar colour), and §9 (List
settings) were already fully built in earlier sessions, despite the doc still marking them "Not
built." Corrected in the doc directly rather than left to rot further. The one piece of §7
(Appearance) genuinely still open was the persisted theme-mode choice, larger list text, and the
reduce-motion status row — all three built now, inline in `PreferencesSection` rather than a
separate screen, since nothing in the design mockup requires a dedicated destination and the app
already had `SettingDropdownOption` for exactly this shape of row. A new `SettingStatusOption`
was added for reduce motion specifically *because* it must not look tappable (decisions above,
§ Decisions #3) — reusing `SettingToggleOption` for a state with nothing behind it to toggle would
have been the wrong component wearing the right label.

**Two bugs found while doing this, neither named in the plan:**

`AppearanceController` was never persisted — a plain in-memory `Notifier`, so picking Dark and
relaunching silently reverted to System. `UpgradeNudgeDismissed`, in the same feature, already
showed the correct `shared_preferences` pattern; `AppearanceController` just hadn't followed it.
Fixed by converting `build()` to the async, prefs-backed shape (`Appearance.values.byName`-style
lookup, stored by name rather than index so adding a value later can't silently shift what an
already-stored index meant) — which turns the provider's type from `Appearance` to
`AsyncValue<Appearance>`, so both read sites (`app.dart`'s `themeMode`, `PreferencesSection`'s
dropdown) now fall back to a sensible default while the persisted value is still loading rather
than assume it has already resolved.

The Settings "Haptics" toggle was decorative: `value: true, onChanged: (_) {}`, wired to nothing.
Meanwhile `HapticFeedback` fires unconditionally from 7 real call sites across 4 files (checking
an item, long-press-to-select, swipe-to-delete's threshold pop, drag-to-reorder start/end, the
invite-code copy confirmation, a shake on error) — the capability the toggle claims to control
already fully exists and works, unlike decisions #64/#69's two *actually* dead controls
(notifications, global "keep checked items"), which had no capability behind them at all and were
removed outright rather than wired. That distinction is why this one was fixed, not deleted: a
toggle promising to gate something real, doing nothing, is a worse state than not having the
toggle. Wiring it meant converting three plain `State` classes (`ShakeOnError`, `InviteCard`,
`_ItemTileState`) to `ConsumerState` so each call site can read the new `HapticsController`
(`shared_preferences`-backed, same pattern as `AppearanceController`, default **on** — an unset
preference has to mean "keep doing what every site already does," not silently go quiet for
everyone who has never opened Settings) — `items_section.dart`'s own two call sites needed no such
conversion, already living inside a `ConsumerWidget`.

**Larger list text** is a `MediaQuery` `TextScaler.linear(1.15)` override at the app root, applied
only when the preference is on; off leaves the ambient scaler untouched rather than stacking on
top of whatever OS-level accessibility scaling is already active — deliberately not a general
accessibility text-scale system, matching the design's own "easier to read at arm's length" framing
for this row.

**Test coverage:** four new cases in `settings_screen_test.dart` (`SharedPreferences` was already
mocked there for the account-linking tests) — the Appearance dialog's choice persists to the
correct key, larger text defaults off and persists once toggled, haptics defaults on and persists
once turned off, and reduce motion renders as plain text with no `Switch` descendant anywhere in
its row, not just no visible thumb.
