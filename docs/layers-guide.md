# What logic goes where — a guide to FreshCart's layers

> A learning guide, not a spec. `architecture.md` is the rulebook; this is the
> "why, and how do I actually do it" companion. Read it top to bottom once, then
> use **Level 7** (the recipe) and the **Inventory** at the end as a reference
> while you work.
>
> Every example here is real code from this repo.

---

## Level 0 — The one idea

**Every piece of code should have one job, and live in the layer whose job that is.**

That's it. Everything below is just: what are the layers, what is each one's job,
and how do they talk to each other.

A picture that helps — **a restaurant**:

| Restaurant        | FreshCart                 | Its job                                             |
| ----------------- | ------------------------- | --------------------------------------------------- |
| The dining room   | **Widget** (presentation) | What the guest sees and touches                     |
| The waiter        | **Screen VM**             | Knows _this table's_ order; talks to the kitchen    |
| A kitchen station | **Feature controller**    | Owns one kind of thing (grill = items, bar = lists) |
| The house rules   | **Use case / entity**     | "No steak well-done", "max 20 people per table"     |
| The supplier      | **Repository → server**   | Brings in what the kitchen doesn't have             |

The guest never walks into the kitchen. The grill doesn't take table orders. The
supplier doesn't decide the menu. When each one sticks to its job, you can change
one without breaking the others.

---

## Level 1 — The layers, one by one

```text
presentation/   Widgets                 "draw it, take input, show errors"
     │
application/    Screen VMs  (*_screen_controller)  "what THIS screen shows and can do"
     │          Controllers (*_controller)         "one feature's state, kept fresh"
     │          Providers   (<feature>_providers)  "derived values"
     │
domain/         Entities, use cases,    "the business rules"
(freshcart_domain) ports                   (pure Dart, knows nothing else)
     │
data/           Repository impls,       "talk to the outside world"
                mappers, sources
     │
     ▼
Serverpod server                        "who is allowed to, and saving it"
```

Arrows only point **down**. A widget may know about its VM. A VM must never
know about a widget. The domain knows about nobody.

**The widget rule:** a widget talks to **exactly one notifier** -- its screen
VM if the screen has one, otherwise its one feature controller. Ambient core
providers (`translationsProvider`, haptics, theme prefs) don't count.

**When does a screen get a VM?** Only when it _earns_ one: it combines two or
more sources (items + shops + filter…), or runs multi-step actions ("delete,
then leave selection mode only if that worked"). A screen that just shows one
controller's state and calls its methods uses that controller directly -- a VM
there would only forward calls, which is a hop with no job.

| Layer                   | Its one job                                                        | It must never…                           |
| ----------------------- | ------------------------------------------------------------------ | ---------------------------------------- |
| **Widget**              | Draw state, collect input, show failures (dialogs, snackbars)      | talk to 2+ notifiers, decide a rule      |
| **Screen VM**           | Combine providers into one state; offer the screen's actions       | touch `BuildContext`                     |
| **Feature controller**  | Own one feature's state; refresh it after writes                   | know which screen is calling             |
| **Provider** (function) | A value derived from other providers (`isListOwner`), or DI wiring | hold state you can change                |

Use cases have **no** providers of their own. A controller builds one right
where it uses it -- `AddItem(ref.read(itemRepositoryProvider))(...)` -- because
a use case is stateless and only needs its port. The repository provider stays
the one seam tests override.
| **Use case**            | Enforce a domain rule before a write                               | know about Riverpod or Flutter           |
| **Repository impl**     | Translate our types ↔ Serverpod's; exceptions → `Failure`          | decide business rules                    |
| **Server**              | Authorization ("are you the owner?") and persisting                | trust the client                         |

---

## Level 2 — Follow one tap, end to end

### The write path: renaming a list

The user types "Weekly shop" and presses Enter on the List settings screen.

```text
ListSettingsScreen          _vm.rename("Weekly shop")
  │                               ▲ Failure? (null = it worked)
ListSettingsScreenController   _lists.rename(listId, name)   ← adds the listId it already knows
  │                               ▲ Result<ShoppingList>       converts Result → Failure?
ListsController              renameListUseCase(id, name)
  │                               ▲ Result                      on success: refreshes the collection
RenameList (use case)        ShoppingList.validateName(name)
  │                               ▲ Err("too long")            ← stops here if invalid: no network call
ListRepository (port)        rename(id, name)
  │
ListRepositoryImpl           client.list.rename(...)  → DTO → toDomain()
  │
Server                       "is this user the owner?" → save
```

Notice how each layer adds exactly **one thing**:

- the VM adds **which list** (so the screen doesn't have to pass an id),
- the controller adds **"refresh after success"**,
- the use case adds **"is the name valid?"**,
- the repository adds **"how to talk to Serverpod"**,
- the server adds **"is this person allowed to?"**.

And the answer travels back up and gets **simpler** on the way: a DTO becomes a
`ShoppingList`, becomes a `Result`, becomes a `Failure?`, becomes an error text
under the field.

### The read path: showing the list

Reading goes the other way, and is **pushed**, not pulled:

```text
Server  ──stream──▶  ListRepository.watch(listId)
                          │
                     listByIdProvider(listId)          (a stream provider)
                          │  ref.watch
                     ListSettingsScreenController.build()   → ListSettingsScreenState
                          │  ref.watch
                     ListSettingsScreen.build()        → draws it
```

When someone else renames the list on their phone, the server pushes it, the
provider changes, the VM's `build()` runs again, the screen redraws. Nobody
"asked". That's what `ref.watch` gives you.

> **Key idea:** once data has arrived, it **lives in a provider**. Reading it
> again is a `ref.read`, not a new server call. (This is why
> `itemCountForDialog()` is one line reading `itemsControllerProvider` — the
> items are already in memory.)

---

## Level 3 — "Where does this line go?"

When you open a screen that does too much, go through it line by line and put
every line in one of three buckets:

| Bucket | Question                                | Examples                                                                      | Goes to                    |
| ------ | --------------------------------------- | ----------------------------------------------------------------------------- | -------------------------- |
| **A**  | Does it _read_ or _compute_ something?  | `ref.watch(...)`, `.where(...)`, "is owner?", "all done?"                     | **VM state** (or a getter) |
| **B**  | Does it _do_ something?                 | `controller.rename(...)`, "delete, then clear the selection"                  | **VM method**              |
| **C**  | Does it need `BuildContext` or Flutter? | dialogs, sheets, snackbars, `context.go`, `TextEditingController`, animations | **stays in the widget**    |

A few that surprise people:

- **Translating an error** (`failure.toMessage(t)`) is **C**. Keep a `Failure` in
  state, translate in `build()`. Otherwise switching language leaves old text.
- **A text field's "saving…" flag and its error** are **C** here. See Level 6,
  trap 1 for why.
- **A confirm dialog** is **C**, but the action _behind_ it is **B**. So the
  dialog stays in the widget and calls a VM method when the user says yes.

### After sorting, the widget looks like this

```dart
@override
Widget build(BuildContext context) {
  final t = ref.watch(translationsProvider);
  final s = ref.watch(listSettingsScreenControllerProvider(widget.listId)); // A: one watch

  void report(Failure? failure) {                                          // C: how to show it
    if (failure == null || !mounted) return;
    showFailureSnackBar(context, failure: failure, t: t);
  }

  // ... draw `s`, and wire taps like:
  onChanged: (v) async => report(await _vm.setClearCheckedAfterShopping(v)), // B via the VM
}
```

The rule of thumb: **the VM decides _what_; the widget decides _how it looks_.**

---

## Level 4 — The Riverpod you actually need

### 4.1 A provider has two faces: the balance and the teller

```dart
ref.watch(itemsControllerProvider(listId))           // the STATE    — the balance
ref.read(itemsControllerProvider(listId).notifier)   // the NOTIFIER — the teller (has methods)
```

You _look at_ the balance. You _ask the teller_ to do something. The teller
changes the balance, and everyone watching sees the new number.

### 4.2 `watch` in `build()`, `read` in methods

- `ref.watch` = "subscribe: run me again when this changes". Only makes sense
  in `build()`, whose whole job is to re-run.
- `ref.read` = "give it to me right now, once". For methods — they run once,
  when the user taps.

### 4.3 The getter trick

```dart
ListsController get _lists => ref.read(listsControllerProvider.notifier);
```

A **getter**, not a field, so it fetches the teller fresh every time. Many
providers are **autoDispose**: if nothing watches them for a moment, Riverpod
throws them away and makes a new one later. A saved field would point at the
old, dead one. The screen does the same for its VM:

```dart
ListSettingsScreenController get _vm =>
    ref.read(listSettingsScreenControllerProvider(widget.listId).notifier);
```

### 4.4 The family key

```dart
@riverpod
class ListSettingsScreenController extends _$ListSettingsScreenController {
  @override
  ListSettingsScreenState build(ListId listId) { ... }   // ← the key
```

`listId` is the **family key**: one VM instance per list. The generated base class
gives every method a `listId` getter, so methods never take an id:

```dart
Future<Failure?> deleteList() async =>
    (await _lists.delete(listId)).failureOrNull;   // listId comes for free
```

**How to choose the key:** use what the screen is _given_. `ListSettingsScreen`
gets a `ListId` from the route → key by `ListId`. `ItemsSection` is handed an
already-loaded `ShoppingList` → `ItemsScreenController` is keyed by `ShoppingList`.

### 4.5 Turning async data into plain fields

Providers that load give you an `AsyncOutcome<T>` (an `AsyncValue<Result<T>>`).
Don't pass that to the widget — flatten it in the VM with the helpers in
`core/async/async_outcome.dart`:

```dart
final listOutcome = ref.watch(listByIdProvider(listId));
final list = listOutcome.dataOrNull;               // T? — the data, or null
// ...
isLoading: listOutcome.isLoading && list == null,  // "loading with nothing to show yet"
loadFailure: listOutcome.loadFailure,              // the Failure, if loading failed
```

`dataOrNull` throws away _why_ there's no data. If the screen needs to tell
"loading" from "failed", keep the outcome variable and read all three.

---

## Level 5 — Use case, or call the repository directly?

This project writes a use case **only when there's a domain rule to enforce.**
Every one of the 12 use cases does one of these two things:

1. **Validates input** — `RenameList`, `CreateList`, `AddItem`, `EditItem`,
   `CreateShop`, `EditShop`, `SetDisplayName`, `SetAvatarPhoto` call
   `X.validate...()` first. `JoinList` parses the code.
2. **Computes the new value with an entity rule** — `ToggleItemChecked` saves
   `item.toggleChecked(by:, at:)`, `ReorderItem` saves
   `ShoppingItem.sortOrderBetween(...)`, `ToggleShopActive` saves
   `shop.toggleActive()`. The UI calls the _same_ entity method for its
   optimistic update, so what you see matches what gets stored.

Otherwise, the **feature controller calls the repository directly**:

| Operation                                              | Why no use case                                  |
| ------------------------------------------------------ | ------------------------------------------------ |
| `delete`, `leave`, `removeMember`, `transferOwnership` | Only rule is "who may" → that's the server's job |
| `setClearCheckedAfterShopping`, notification toggles   | A plain bool, nothing to validate                |
| `clearChecked`, `removeMany`, `moveMany`               | Ids in, done; no field with a rule is touched    |
| `myLists`, `watch`, `byList`, `itemCount`              | Reads                                            |

### The checklist

0. **Does the app already have this data?** → `ref.read` the provider. Done.
1. **Is it a read?** → repository, from a controller or provider. No use case.
2. **Can the input break a domain rule?** → use case that validates first.
3. **Is the new value _computed_ by a domain rule?** → use case that uses the entity method.
4. **Is the only rule "who is allowed to"?** → the server. Not a use case.
5. **None of these?** → the controller calls the repository.

### Where does a rule live?

| The rule needs to know…              | Lives in                       | Example                          |
| ------------------------------------ | ------------------------------ | -------------------------------- |
| only its own input                   | the **entity**, via a use case | "name is not blank, ≤ 60 chars"  |
| the current state of **shared** data | the **server**                 | "new owner is still a member"    |
| who you are                          | the **server**                 | "only the owner can delete"      |
| nothing — it's just nice feedback    | the **widget** (as a hint)     | "this colour is close to Lidl's" |

Why "shared data" goes to the server: your copy of `list.members` can be seconds
old. The person may have just left on their own phone. Only the server knows
_now_.

---

## Level 6 — The traps (all hit in this project)

### Trap 1 — A VM that watches things can't keep its own state

Every `ref.watch` in a VM's `build()` re-runs `build()` when that thing changes,
and `build()` **replaces the whole state**. So if you store a "saving…" flag or an
error in the VM's state, it gets **wiped** the next time _anything_ it watches
changes — like another household member checking off an item.

**Fix:** keep that kind of state either in the widget (like the name field's
`_savingName` / `_nameFailure`), or in its own small controller that watches
nothing (like `ItemsUiController`, which holds selection, search, rearrange
and the Done/celebration flags for one list). The VM _combines_; it doesn't
_own_.

### Trap 2 — Defaults hide mistakes

```dart
this.shops = const [],      // ❌ forget to pass it → compiles, screen shows "no shops" forever
required this.shops,        // ✅ forget to pass it → compile error
required this.list,         // ✅ even when nullable: forces you to write `list: null` on purpose
```

Only use defaults where the default is the normal case (`isLoading = false`).

### Trap 3 — Nullable only when null _means_ something

`list` is nullable because null shows a spinner. `shops` isn't, because
"not loaded" and "empty" look the same on screen. Collapse it once, in the VM:
`?? const <Shop>[]`. Every `?` on a state field is a question every widget has to
answer.

### Trap 4 — `s.list!` and type promotion

Dart only promotes a **local variable** after a null check, not `s.list`:

```dart
final list = s.list;             // local
if (list == null) return spinner;
list.name;                       // ✅ promoted, no `!`
```

A `!` on state is a crash waiting for the one frame you were wrong.

### Trap 5 — The VM's type must be the VM

```dart
final ItemsController vm;          // ❌ compiles (same method names!) but skips the VM
final ItemsScreenController vm;    // ✅
```

Typing a parameter as the VM is how the compiler enforces "presentation only
talks to the VM".

### Trap 6 — Shared helpers that take `ref`

`confirmDeleteList` is used by two screens (list settings, and the detail
screen's menu), so it can't move into either VM. It used to take `ref` and read
two controllers itself. **Fix:** make the helper _dumber_: data and callbacks
in, UI out. This is what it looks like now:

```dart
confirmDeleteList(context,
  list: list, t: t,
  itemCount: _vm.itemCountForDialog(),   // data it used to read via ref
  delete: _vm.deleteList,                // action it used to call via ref
);
```

The helper keeps the **flow** (ask → do → navigate or report). The VM supplies
**what** to do. Don't replace the helper with just the action — that deletes the
"are you sure?" step.

### Trap 7 — "Analyzer clean" is not "correct"

The analyzer checks types, not behaviour. Removing a confirmation dialog, or
forgetting to call `_seedNameOnce`, is perfectly type-correct. That's what the
tests are for — and why a pure refactor should pass the old tests **without
editing them**. If you must change a test, you changed behaviour.

### Trap 8 — A refactor loses the line that did two things

`if (loaded != null) _seedNameOnce(loaded.name);` both _used_ `loaded` and
_triggered_ seeding. Rewriting `loaded` into `s.list` dropped the trigger, and
the name field opened empty. When the analyzer says a method is unused, don't
delete the method — ask **why its caller disappeared**.

---

## Level 7 — The recipe: refactoring a screen

0. **Does it earn a VM?** (Level 1.) If the screen only shows one controller
   and calls its methods, stop here: use that controller directly.
1. **Sort** every line into A / B / C (Level 3). Write it down as a table.
2. **Pick the key** — what the screen is given (`ListId`? a loaded entity?).
3. **Write the State** (`application/x_screen_state.dart`): plain Dart,
   domain types, `Failure` not `String`, `required` fields, getters for derived
   values.
4. **Write `build()` only** (`x_screen_controller.dart`). Watch the providers,
   flatten outcomes, return the state. Analyze.
5. **Switch the screen's `build`** to `s = ref.watch(...)` and delete the old
   watches. Analyze.
6. **Add actions one at a time.** Each returns `Failure?` (via `failureOrNull`)
   and uses a getter for the feature controller. Switch each call site. Analyze.
7. **Make sub-widgets `StatelessWidget`s** taking data + callbacks.
8. **Run the existing tests, unedited.** Then search the file for `ref.` — only
   the VM getter and the watch should be left.

### Before writing any new method

- [ ] Search the **Inventory** below. Does a controller already do this?
- [ ] Is the data already in a provider? (→ `ref.read`, not a new port method)
- [ ] Does it need a use case? (Level 5 checklist)
- [ ] Does my VM method take an id? It shouldn't — the key already is one.

---

## Inventory — what already exists

> **This goes stale.** Last checked 2026-09-29. To re-check, run:
> `grep -rn "^class\|^@riverpod\|^@Riverpod" freshcart_flutter/lib/features/*/application`

### Feature controllers — "one feature's state" (`*_controller.dart`)

Their methods **take ids** and return `Result<T>` or `Failure?`. Many screens use them.

| Controller                          | State                          | Methods                                                                                                                                 |
| ----------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| `ListsController`                   | all the user's lists           | `create`, `join`, `rename`, `setClearCheckedAfterShopping`, `leave`, `delete`, `removeMember`, `transferOwnership`, `refresh`           |
| `LastOpenedListController`          | last opened `ListId` (on disk) | `select`                                                                                                                                |
| `ItemsController(listId)`           | one list's items               | `toggle`, `edit`, `reorder`, `add`, `remove`, `swipeDelete` (returns undo), `clearChecked`, `removeSelected`, `moveSelected`, `refresh` |
| `ItemsUiController(listId)`         | selection, search, rearrange, Done collapsed, celebration dismissed | `toggleSelection`, `clearSelection`, `openSearch`, `updateQuery`, `closeSearch`, `startRearrange`, `stopRearrange`, `toggleDoneCollapsed`, `dismissCelebration`, `resetCelebration` |
| `ShopsController(listId)`           | one list's shops               | `create`, `edit`, `toggleActive`, `itemCount`, `remove`                                                                                 |
| `ShopFilterController(listId)`      | selected shop tab (`ShopId?`)  | `select`                                                                                                                                |
| `ShopColorPreviewController`        | colour being tried in a sheet  | `preview`, `clear`                                                                                                                      |
| `ProfileController`                 | signed-in `AuthUser`           | `setDisplayName`, `setAvatarColor`, `setAvatarPhoto`, `clearAvatarPhoto`, `linkEmail`, `signOut`                                        |
| `UpgradeNudgeController`            | nudge dismissed?               | `dismiss`                                                                                                                               |
| `ListMuteController(listId)`        | this list muted?               | `setMuted`                                                                                                                              |
| `NotificationPreferencesController` | push preferences               | `setItemAdded`, `setMemberJoined`, `setListFinished`                                                                                    |
| `LocaleController` (core)           | app language                   | `select` (+ `translationsProvider` gives `t`)                                                                                           |
| `AppearanceController` (core)       | light / dark / system          | `select`                                                                                                                                |
| `LargeTextController` (core)        | larger list text?              | `select`                                                                                                                                |
| `HapticsController` (core)          | haptics on?                    | `select`                                                                                                                                |

### Derived providers — "answers computed from other providers" (`<feature>_providers.dart`)

| Provider                                    | File                          | Gives you                                                |
| ------------------------------------------- | ----------------------------- | -------------------------------------------------------- |
| `listByIdProvider(listId)`                  | `list_providers.dart`         | one list, live (stream)                                  |
| `isListOwnerProvider(list)`                 | `list_providers.dart`         | `bool` — am I the owner? (false until identity is known) |
| `myMembershipProvider(list)`                | `list_providers.dart`         | my `ListMember?` on that list                            |
| `listSummariesProvider`                     | `list_providers.dart`         | items left / all done, per list (drawer rows)            |
| `listsLandingTargetProvider`                | `list_providers.dart`         | which list `/lists` should open, or null to stay         |
| `signedInUserIdProvider`                    | `auth_providers.dart`         | my `UserId?`                                             |
| `isNewIdentityProvider`                     | `auth_providers.dart`         | brand-new identity? (→ onboarding)                       |
| `recentNamesProvider(listId)`               | `item_history_providers.dart` | name history ("Recently bought")                         |
| `itemSuggestionsProvider(listId:, query:)`  | `item_history_providers.dart` | name suggestions for quick-add                           |
| `effectiveShopColorProvider(shop)`          | `shop_providers.dart`         | shop colour, including a preview being tried             |
| `activeShopColorProvider(listId)`           | `shop_providers.dart`         | colour of the selected shop tab (the theme tint)         |
| `syncProvider`, `pendingWriteCountProvider` | `sync_providers.dart`         | online/offline status, writes waiting to sync            |

### Screen VMs — "what this screen needs" (`*_screen_controller.dart`)

Their methods **don't take ids** and return `Failure?`. One screen (or panel) each,
and only where they earn it.

| VM                                     | Used by                                                | State                                                                       | Methods                                                                                                                                                                                                                                                                                                  |
| -------------------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ItemsScreenController(list)`          | `ItemsSection`, `ListDetailAppBar`                     | list, `mode`, items, shops, filter, selection, search, celebration, loading | `toggle`, `setQuantity`, `edit`, `remove`, `swipeDelete`, `clearChecked`, `toggleDoneCollapsed`, `dismissCelebration`, `quickAdd`, `add`, `addFromSearch`, `startRearrange`, `stopRearrange`, `reorderOpen`, `toggleSelection`, `clearSelection`, `deleteSelected`, `moveSelected`, `openSearch`, `closeSearch`, `updateQuery` |
| `ListDetailScreenController(listId)`   | `ListDetailScreen`, `ListMenu`                         | list, isOwner, activeShopColor, mode, loading, loadFailure                  | `deleteList`, `leaveList`, `refreshLists`, `itemCountForDialog`                                                                                                                                                                                                                                          |
| `ListSettingsScreenController(listId)` | `ListSettingsScreen`                                   | list, allLists, shops, isOwner, loading, loadFailure                        | `rename`, `toggleShopActive`, `setClearCheckedAfterShopping`, `refreshLists`, `deleteList`, `leaveList`, `itemCountForDialog`                                                                                                                                                                            |
| `HouseholdScreenController(listId)`    | `HouseholdScreen`                                      | list, me, isOwner, loadFailure (+ `isMe`, `canManage`)                      | `removeMember`, `transferOwnership`, `refreshLists`                                                                                                                                                                                                                                                      |
| `ListsDrawerController`                | `ListsDrawer`                                          | one row per list: list, summary, others on it                               | `openList`                                                                                                                                                                                                                                                                                               |
| `ShopTabsController(listId)`           | `ShopFilterBar`                                        | tabs, selected, open items (+ `remainingIn`, `neighbour`)                   | `select`                                                                                                                                                                                                                                                                                                 |
| `OnboardingController`                 | onboarding flow                                        | step, name, list name, shop drafts                                          | `updateDisplayName`, `updateListName`, `toggleShop`, `addShop`, `next`, `back`, `submit`                                                                                                                                                                                                                 |
| `JoinFlowController`                   | join-by-code flow                                      | step, name, code, joined list                                               | `updateDisplayName`, `updateCode`, `continueFromName`, `back`, `submit`                                                                                                                                                                                                                                  |

**No VM on purpose** (one controller, nothing to combine): `ManageShopsScreen`
→ `ShopsController`, `NotificationsScreen` → its two preference controllers
(one per row widget), `SettingsScreen` / `EditProfileScreen` → `ProfileController`.

### Use cases (domain)

| Feature | Use cases                                                 |
| ------- | --------------------------------------------------------- |
| lists   | `CreateList`, `JoinList`, `RenameList`                    |
| items   | `AddItem`, `EditItem`, `ToggleItemChecked`, `ReorderItem` |
| shops   | `CreateShop`, `EditShop`, `ToggleShopActive`              |
| auth    | `SetDisplayName`, `SetAvatarPhoto`                        |

### Ports — everything the app can ask the outside world

| Port             | Methods                                                                                                                                                           |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ListRepository` | `myLists`, `byId`, `summaries`, `create`, `joinByCode`, `rename`, `setClearCheckedAfterShopping`, `leave`, `delete`, `removeMember`, `transferOwnership`, `watch` |
| `ItemRepository` | `byList`, `add`, `save`, `remove`, `clearChecked`, `removeMany`, `moveMany`, `watchByList`, `suggestNames`, `recentNames`                                         |
| `ShopRepository` | `byList`, `create`, `save`, `itemCount`, `remove`                                                                                                                 |
| `AuthPort`       | `authStateChanges`, `signInAnonymously`, `setDisplayName`, `setAvatarColor`, `setAvatarPhoto`, `clearAvatarPhoto`, `linkGoogle`, `linkEmail`, `signOut`           |
| `PushPort`       | `isSupported`, `registerDevice`, `unregisterDevice`, `setListMuted`, `isListMuted`, `notificationPreferences`, `set…NotificationsEnabled` (×3)                    |

**If what you need isn't in this table, it needs a server endpoint.** That's a
big step (server + `serverpod generate` + client). Check twice that the data
isn't already in a provider first.

---

## Self-check

Try these before opening the answers.

1. A VM method `Future<Failure?> deleteList(ListId listId)` — what's wrong with
   the signature?
2. You need "how many items are left in this list" on a new screen. New port
   method, new use case, or something else?
3. Where does "the new owner must be a member of the list" get enforced, and why
   not in a client use case?
4. Your VM stores `bool isSaving` in its state. What bug will you see in a shared
   list?
5. `moveMany(items, shopId)` goes straight to the repository even though
   `ShoppingItem` has rules. Why is that fine?

<details>
<summary>Answers</summary>

1. A VM is already keyed by its list — `listId` is a getter on every method.
   Taking an id makes it look like a feature controller, and lets a caller pass
   the _wrong_ id.
2. Neither: the items are already in `itemsControllerProvider(listId)`. Read or
   watch it (depending on whether the screen shows it continuously). For many
   lists at once, `listSummariesProvider` already exists.
3. On the server (`ListService.transferOwnership` → `requireMembership`). It
   depends on **shared data that can change** — the client's member list may be
   seconds old.
4. Another member checks off an item → the items provider changes → the VM's
   `build()` re-runs → `isSaving` resets to `false` mid-save. Keep it in the
   widget or its own controller (Level 6, trap 1).
5. A move only changes `shopId`, and no rule covers `shopId`. The rules on
   `ShoppingItem` are about name and quantity, which a move doesn't touch.

</details>
