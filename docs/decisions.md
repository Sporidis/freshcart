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
