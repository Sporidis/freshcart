import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/item_use_case_providers.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_controller.g.dart';

/// The items on one list: live, and optimistic.
///
/// Two mechanisms meet here and have to agree.
///
/// * **Live**: a server stream re-emits the whole list whenever anyone changes
///   it, so two open clients stay in step without a refresh.
/// * **Optimistic**: ticking something off in a shop must feel instant, so a
///   mutation applies locally first and rolls back if the server refuses.
///
/// The collision between them is the interesting part. While a write is in
/// flight, an unrelated change by someone *else* would arrive carrying the
/// server's older copy of the row being edited — and would visibly undo the
/// user's tick until their own write landed. [_pending] holds the optimistic
/// value for every in-flight id and is overlaid on each incoming snapshot, so
/// a third party's edit never stamps on a local one.
@riverpod
class ItemsController extends _$ItemsController {
  /// Optimistic values for writes that have not been answered yet.
  final Map<ItemId, ShoppingItem> _pending = {};

  /// Rows hidden by [swipeDelete] but not yet committed to the server.
  ///
  /// Keyed by the original item so [swipeDelete]'s undo can put back the exact
  /// row that was swiped, not a reconstruction of it.
  final Map<ItemId, ShoppingItem> _pendingRemoval = {};

  /// How long a swiped-away row can still be undone. Matches the Motion spec's
  /// swipe-to-delete undo snackbar (§10).
  static const swipeUndoWindow = Duration(seconds: 4);

  @override
  Future<Result<List<ShoppingItem>>> build(ListId listId) {
    final first = Completer<Result<List<ShoppingItem>>>();

    final subscription = ref
        .watch(itemRepositoryProvider)
        .watchByList(listId)
        .listen(
          (event) {
            final merged = _overlay(event);
            if (first.isCompleted) {
              state = AsyncData(merged);
            } else {
              first.complete(merged);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            // A transport error before the first snapshot has nothing to show,
            // so it surfaces as AsyncError. Later ones arrive as Err values on
            // the stream itself and keep the list on screen.
            if (!first.isCompleted) first.completeError(error, stackTrace);
          },
        );
    ref.onDispose(subscription.cancel);

    return first.future;
  }

  /// Re-applies in-flight optimistic values over an incoming snapshot, drops
  /// anything still hidden behind a pending [swipeDelete], and re-sorts.
  ///
  /// Sorting here, unconditionally, matters: a delta from the live stream
  /// (see [ItemRealtimeSource.applyChange]) upserts a changed row *in its old
  /// array slot* rather than moving it, so array order alone cannot be
  /// trusted to reflect [ShoppingItem.sortOrder] past the first snapshot.
  Result<List<ShoppingItem>> _overlay(Result<List<ShoppingItem>> event) {
    return event.map(
      (items) => _sorted([
        for (final item in items)
          if (!_pendingRemoval.containsKey(item.id)) _pending[item.id] ?? item,
      ]),
    );
  }

  /// The items currently on screen, or null if none have loaded yet.
  List<ShoppingItem>? get _current => state.dataOrNull;

  /// Sorts by [ShoppingItem.sortOrder] -- the one place this is enforced, so
  /// every write path ([_show]) and every incoming snapshot ([_overlay])
  /// agrees on display order without each one having to remember to.
  List<ShoppingItem> _sorted(List<ShoppingItem> items) =>
      [...items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _show(List<ShoppingItem> items) =>
      state = AsyncData(Ok<List<ShoppingItem>>(_sorted(items)));

  List<ShoppingItem> _replacing(List<ShoppingItem> items, ShoppingItem item) =>
      [
        for (final existing in items)
          if (existing.id == item.id) item else existing,
      ];

  /// Applies [optimistic] locally and keeps it pinned until [write] answers.
  Future<Failure?> _optimistically(
    ShoppingItem optimistic,
    Future<Result<ShoppingItem>> Function() write,
  ) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    _pending[optimistic.id] = optimistic;
    _show(_replacing(before, optimistic));

    final result = await write();
    _pending.remove(optimistic.id);

    switch (result) {
      case Ok<ShoppingItem>(:final value):
        // Reconcile rather than keep the guess: the server owns checkedAt and
        // updatedAt, and updatedAt is the token the *next* write depends on.
        _show(_replacing(_current ?? before, value));
        return null;
      case Err<ShoppingItem>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Checks or unchecks [item], applying the change immediately.
  ///
  /// Returns the failure if the server refused, so the screen can tell the user
  /// why the row it just saw tick untucked itself. A silent rollback would look
  /// like a bug.
  Future<Failure?> toggle(ShoppingItem item) async {
    // Read the cached identity synchronously when it is warm. Awaiting here
    // unconditionally would delay the *first* tick of a session behind an
    // identity lookup — precisely the lag optimistic updates exist to avoid.
    final cached = ref.read(currentUserIdProvider);
    final identity = cached.hasValue
        ? cached.requireValue
        : await ref.read(currentUserIdProvider.future);

    final UserId userId;
    switch (identity) {
      case Ok<UserId>(:final value):
        userId = value;
      case Err<UserId>(:final failure):
        return failure;
    }

    return _optimistically(
      // The same entity method the server's answer will agree with, so the
      // local guess and the eventual truth are computed one way.
      item.toggleChecked(by: userId, at: DateTime.now().toUtc()),
      () => ref.read(toggleItemCheckedUseCaseProvider)(item, by: userId),
    );
  }

  /// Applies a user's edit to [item], showing it immediately.
  ///
  /// Takes the raw field values rather than a finished [ShoppingItem] on
  /// purpose: building the edited entity is a domain transformation
  /// ([ShoppingItem.withEdit]) guarded by domain rules, and a caller that
  /// handed us a pre-built entity could — and did — skip both.
  Future<Failure?> edit(
    ShoppingItem item, {
    required String name,
    required int quantity,
    ShopId? shopId,
    String? noteText,
  }) {
    // The same entity method the use case will apply, so the local guess and
    // the eventual truth are computed one way. An invalid edit is rejected by
    // the use case before any network call and rolls straight back.
    final optimistic = item.withEdit(
      name: name.trim(),
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
      at: DateTime.now().toUtc(),
    );

    return _optimistically(
      optimistic,
      () => ref.read(editItemUseCaseProvider)(
        item,
        name: name,
        quantity: quantity,
        shopId: shopId,
        noteText: noteText,
      ),
    );
  }

  /// Moves [item] to sit between [before] and [after] (§10: drag to
  /// reorder), applying the new position immediately.
  ///
  /// [before] and [after] are the *new* neighbors -- wherever the row was
  /// dropped -- not whoever it sat next to before the drag started.
  Future<Failure?> reorder(
    ShoppingItem item, {
    required ShoppingItem? before,
    required ShoppingItem? after,
  }) {
    // The same pure arithmetic the use case will apply, so the local guess
    // and the eventual truth land on one value.
    final optimistic = item.copyWith(
      sortOrder: ShoppingItem.sortOrderBetween(before, after),
    );

    return _optimistically(
      optimistic,
      () => ref.read(reorderItemUseCaseProvider)(
        item,
        before: before,
        after: after,
      ),
    );
  }

  /// Adds an item, showing it only once the server has accepted it.
  ///
  /// Deliberately *not* optimistic: the server mints the id, `createdAt` and
  /// `updatedAt`, and a placeholder row with a fabricated id could not be
  /// edited or checked until it was replaced. This also means an add that
  /// merges into an existing open row of the same product (same name, shop
  /// and note text -- server-side, see `ItemService.add`) is indistinguishable
  /// from a fresh insert here: either way, the server hands back one
  /// [ShoppingItem] and this just needs to make sure it's the one shown.
  Future<Failure?> add({
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    final result = await ref.read(addItemUseCaseProvider)(
      listId: listId,
      name: name,
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
    );
    switch (result) {
      case Ok<ShoppingItem>(:final value):
        // The live stream will carry this too; showing it here keeps the
        // field responsive. If the id is already in the list this was a
        // merge -- replace it in place (the bumped quantity), not append,
        // or the row would sit stale until the next stream echo.
        final current = _current;
        if (current != null) {
          _show(
            current.any((i) => i.id == value.id)
                ? _replacing(current, value)
                : [...current, value],
          );
        }
        return null;
      case Err<ShoppingItem>(:final failure):
        return failure;
    }
  }

  /// Removes [item], taking it off screen immediately and putting it back if
  /// the server refuses.
  Future<Failure?> remove(ShoppingItem item) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    _pending[item.id] = item;
    _show([
      for (final existing in before)
        if (existing.id != item.id) existing,
    ]);

    final result = await ref.read(itemRepositoryProvider).remove(item.id);
    _pending.remove(item.id);

    switch (result) {
      case Ok<void>():
        return null;
      case Err<void>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Hides [item] immediately and, unless undone, deletes it once
  /// [swipeUndoWindow] has passed. Returns the undo action.
  ///
  /// Deliberately not `Future<Failure?>` like [remove]: the delete itself is
  /// deferred, so there is nothing to await yet and nothing to report — a
  /// failure surfacing four seconds after the swipe, once the user has moved
  /// on to the next row, would only read as a confusing, out-of-context bug.
  /// What the caller needs back synchronously is the undo action, to wire
  /// into the snackbar the swipe gesture shows.
  ///
  /// The repository is read into [repo] now, not inside the timer. If the
  /// user navigates away before the timer fires, this controller is disposed
  /// and `ref` stops working — but a plain captured Dart reference keeps
  /// going, so the delete still lands. That is deliberate: swiping a row away
  /// is a real decision, and having it silently survive just because the
  /// screen was left too soon would be its own kind of surprising.
  void Function() swipeDelete(ShoppingItem item) {
    final before = _current;
    if (before != null) {
      _pendingRemoval[item.id] = item;
      _show([
        for (final existing in before)
          if (existing.id != item.id) existing,
      ]);
    }

    final repo = ref.read(itemRepositoryProvider);
    final timer = Timer(swipeUndoWindow, () {
      _pendingRemoval.remove(item.id);
      unawaited(repo.remove(item.id));
    });

    var settled = false;
    return () {
      if (settled) return;
      settled = true;
      timer.cancel();
      if (_pendingRemoval.remove(item.id) == null) return;
      if (!ref.mounted) return;
      final current = _current;
      if (current != null && !current.any((i) => i.id == item.id)) {
        _show([...current, item]);
      }
    };
  }

  /// Removes every checked item, taking them off screen immediately and
  /// putting them all back if the server refuses.
  ///
  /// One optimistic guess for the whole batch rather than [remove] looped
  /// per item: the server does it as one transaction (all or nothing), so
  /// the local view should promise the same thing rather than showing rows
  /// disappearing one at a time toward a result that might still roll back.
  Future<Failure?> clearChecked() async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    final checked = [
      for (final item in before)
        if (item.isChecked) item,
    ];
    if (checked.isEmpty) return null;

    for (final item in checked) {
      _pending[item.id] = item;
    }
    _show([
      for (final item in before)
        if (!item.isChecked) item,
    ]);

    final result = await ref.read(itemRepositoryProvider).clearChecked(listId);
    for (final item in checked) {
      _pending.remove(item.id);
    }

    switch (result) {
      case Ok<int>():
        return null;
      case Err<int>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Deletes a multi-selected set of rows, taking them off screen immediately
  /// and putting them all back if the server refuses.
  ///
  /// Same shape as [clearChecked] and for the same reason: "Delete" on a
  /// selection is one promise covering every row in it, so it is one
  /// transaction server-side and one optimistic guess here, not [remove]
  /// looped per id.
  Future<Failure?> removeSelected(Set<ItemId> ids) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');
    if (ids.isEmpty) return null;

    final selected = [
      for (final item in before)
        if (ids.contains(item.id)) item,
    ];
    for (final item in selected) {
      _pending[item.id] = item;
    }
    _show([
      for (final item in before)
        if (!ids.contains(item.id)) item,
    ]);

    final result = await ref.read(itemRepositoryProvider).removeMany(listId, [
      for (final item in selected) item.id,
    ]);
    for (final item in selected) {
      _pending.remove(item.id);
    }

    switch (result) {
      case Ok<int>():
        return null;
      case Err<int>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Reassigns every item in [ids] to [shopId] (null untags them) -- a
  /// multi-select "Move".
  ///
  /// Same shape as [removeSelected]: one optimistic guess (retag every
  /// selected row locally), one transaction server-side, not [save] looped
  /// per id -- for the same reason, "Move" on a selection is one promise
  /// covering every row in it.
  Future<Failure?> moveSelected(Set<ItemId> ids, ShopId? shopId) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');
    if (ids.isEmpty) return null;

    final selected = [
      for (final item in before)
        if (ids.contains(item.id)) item,
    ];
    for (final item in selected) {
      _pending[item.id] = item;
    }
    _show([
      for (final item in before)
        if (ids.contains(item.id)) item.copyWith(shopId: shopId) else item,
    ]);

    final result = await ref.read(itemRepositoryProvider).moveMany(listId, [
      for (final item in selected) item.id,
    ], shopId);
    for (final item in selected) {
      _pending.remove(item.id);
    }

    switch (result) {
      case Ok<int>():
        return null;
      case Err<int>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Re-reads the items from the server.
  Future<void> refresh() async => ref.invalidateSelf();
}
