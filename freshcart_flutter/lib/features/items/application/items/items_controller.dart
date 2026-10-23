import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_controller.g.dart';

/// The items on one list. Live, and optimistic.
///
/// * **Live**: the server sends updates whenever anyone changes the list,
///   so everyone's phone stays in sync without refreshing.
/// * **Optimistic**: changes show on screen straight away, before the
///   server answers. If the server says no, the change is undone.
///
/// The tricky part: while your change is still being saved, an update from
/// someone else can arrive. That update still has the OLD version of your
/// item, so your check would flicker off again. [_pending] fixes this: it
/// keeps your unsaved changes and puts them back on top of every update.
@riverpod
class ItemsController extends _$ItemsController {
  /// Changes shown on screen that the server hasn't confirmed yet, by id.
  final Map<ItemId, ShoppingItem> _pending = {};

  /// Rows hidden by [swipeDelete], not deleted on the server yet (the user
  /// can still undo). Stores the whole item, so undo puts back exactly the
  /// same row.
  final Map<ItemId, ShoppingItem> _pendingRemoval = {};

  /// How long the user can undo a delete. Matches the v3 toast's hold
  /// (`AppMotion.toastHold`), so Undo works exactly while it's on screen.
  static const swipeUndoWindow = Duration(milliseconds: 3400);

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
            // An error before the first data: nothing to show, so AsyncError.
            // Later errors come as Err in the stream and the list stays.
            if (!first.isCompleted) first.completeError(error, stackTrace);
          },
        );
    ref.onDispose(subscription.cancel);

    return first.future;
  }

  /// Takes new items from the server and:
  /// 1. puts our unsaved changes back on top ([_pending]);
  /// 2. removes rows that were swipe-deleted (waiting for undo);
  /// 3. sorts.
  ///
  /// Always sort here: a live update replaces a changed row in its old
  /// position, so the order can be wrong after an update.
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

  /// Sorts by [ShoppingItem.sortOrder]. The only place sorting happens, so
  /// the order is always the same.
  List<ShoppingItem> _sorted(List<ShoppingItem> items) =>
      [...items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _show(List<ShoppingItem> items) =>
      state = AsyncData(Ok<List<ShoppingItem>>(_sorted(items)));

  List<ShoppingItem> _replacing(List<ShoppingItem> items, ShoppingItem item) =>
      [
        for (final existing in items)
          if (existing.id == item.id) item else existing,
      ];

  /// Shows [optimistic] on screen right away, and keeps it there until
  /// [write] (the server call) answers. If it fails, undoes it.
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
        // Use the server's version, not our guess. The server sets checkedAt
        // and updatedAt, and the next save needs the right updatedAt.
        _show(_replacing(_current ?? before, value));
        return null;
      case Err<ShoppingItem>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Checks or unchecks [item], shown right away.
  ///
  /// Returns the error if the server said no, so the screen can explain why
  /// the check disappeared again. Undoing it silently would look like a bug.
  Future<Failure?> toggle(ShoppingItem item) async {
    // Use the already-loaded user id if we have it. Always waiting for it
    // would make the first check feel slow, which is what optimistic
    // updates are meant to avoid.
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
      // Same domain method the server uses, so our guess matches the result.
      item.toggleChecked(by: userId, at: DateTime.now().toUtc()),
      () =>
          ToggleItemChecked(ref.read(itemRepositoryProvider))(item, by: userId),
    );
  }

  /// Saves an edit to [item], shown right away.
  ///
  /// Takes the separate fields (not a finished [ShoppingItem]), so the
  /// domain's [ShoppingItem.withEdit] builds the new item and checks the
  /// rules. Callers can't skip that.
  Future<Failure?> edit(
    ShoppingItem item, {
    required String name,
    required int quantity,
    ShopId? shopId,
    String? noteText,
  }) {
    // Same domain method the use case uses, so our guess matches the
    // result. An invalid edit is rejected before calling the server, and
    // undone right away.
    final optimistic = item.withEdit(
      name: name.trim(),
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
      at: DateTime.now().toUtc(),
    );

    return _optimistically(
      optimistic,
      () => EditItem(ref.read(itemRepositoryProvider))(
        item,
        name: name,
        quantity: quantity,
        shopId: shopId,
        noteText: noteText,
      ),
    );
  }

  /// Moves [item] between [before] and [after] (drag to reorder), shown
  /// right away.
  ///
  /// [before] and [after] are the rows around where it was dropped (its
  /// new neighbours, not the old ones).
  Future<Failure?> reorder(
    ShoppingItem item, {
    required ShoppingItem? before,
    required ShoppingItem? after,
  }) {
    // Same calculation the use case uses, so our guess matches the result.
    final optimistic = item.copyWith(
      sortOrder: ShoppingItem.sortOrderBetween(before, after),
    );

    return _optimistically(
      optimistic,
      () => ReorderItem(ref.read(itemRepositoryProvider))(
        item,
        before: before,
        after: after,
      ),
    );
  }

  /// Adds an item. It only shows once the server has saved it.
  ///
  /// Not optimistic, because the server creates the id and dates. A fake
  /// row with a made-up id couldn't be checked or edited until replaced.
  ///
  /// If the same item already exists (same name, shop and note), the server
  /// adds to its quantity instead of making a new row. Either way, it
  /// returns one item, and we show that one.
  Future<Failure?> add({
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    final result = await AddItem(ref.read(itemRepositoryProvider))(
      listId: listId,
      name: name,
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
    );
    switch (result) {
      case Ok<ShoppingItem>(:final value):
        // Show it now (the live update would come a bit later). If the id is
        // already in the list, it was merged: replace that row (new
        // quantity) instead of adding a second one.
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

  /// Deletes [item]. It disappears right away, and comes back if the server
  /// says no.
  Future<Failure?> remove(ShoppingItem item) => _removeOptimistically(
    (i) => i.id == item.id,
    () => ref.read(itemRepositoryProvider).remove(item.id),
  );

  /// Deletes all checked items. They disappear right away, and all come
  /// back if the server says no.
  ///
  /// One change for all items (not [remove] in a loop): the server does it
  /// all at once (all or nothing), so the screen does too.
  Future<Failure?> clearChecked() => _removeOptimistically(
    (i) => i.isChecked,
    () => ref.read(itemRepositoryProvider).clearChecked(listId),
  );

  /// Hides [item] right away, and deletes it after [swipeUndoWindow] unless
  /// the user taps Undo. Returns the undo function (for the snackbar).
  ///
  /// Doesn't return an error like [remove] does: the delete happens 4
  /// seconds later, when the user is already doing something else. An
  /// error then would be confusing.
  void Function() swipeDelete(ShoppingItem item) =>
      _hideWithUndo([item], (repo) => repo.remove(item.id));

  /// [swipeDelete] for several items at once (Clear, or Delete in select
  /// mode): all hidden now, deleted together in one call after
  /// [swipeUndoWindow], unless the returned undo puts them all back first.
  ///
  /// Uses `removeMany` with these ids, not `clearChecked`: an item checked
  /// during the undo window wasn't part of what the user cleared.
  void Function() removeManyWithUndo(Iterable<ItemId> ids) {
    final wanted = ids.toSet();
    final removed = [
      for (final item in _current ?? const <ShoppingItem>[])
        if (wanted.contains(item.id)) item,
    ];
    if (removed.isEmpty) return () {};
    final list = listId;
    return _hideWithUndo(
      removed,
      (repo) => repo.removeMany(list, [for (final item in removed) item.id]),
    );
  }

  // ── Removal helpers ──────────────────────────────────────────────────

  /// Hides the items matching [gone], runs [write], and puts them back if
  /// it fails.
  ///
  /// Hidden through [_pendingRemoval], so a live update during the save
  /// can't bring them back (see [moveSelected]).
  Future<Failure?> _removeOptimistically(
    bool Function(ShoppingItem) gone,
    Future<Result<Object?>> Function() write,
  ) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');
    final removed = before.where(gone).toList();
    if (removed.isEmpty) return null;

    for (final item in removed) {
      _pendingRemoval[item.id] = item;
    }
    _show([
      for (final item in before)
        if (!gone(item)) item,
    ]);

    final result = await write();
    for (final item in removed) {
      _pendingRemoval.remove(item.id);
    }

    switch (result) {
      case Ok():
        return null;
      case Err(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Hides [removed] now, and calls [delete] after [swipeUndoWindow] unless
  /// the returned undo puts them back first.
  ///
  /// The repository is read now, not inside the timer. If the user leaves
  /// the screen, this controller is disposed and `ref` stops working, but
  /// the repository still does, so the delete still happens. That's what we
  /// want: the user did remove them.
  void Function() _hideWithUndo(
    List<ShoppingItem> removed,
    Future<Object?> Function(ItemRepository repo) delete,
  ) {
    final ids = {for (final item in removed) item.id};
    final before = _current;
    if (before != null) {
      for (final item in removed) {
        _pendingRemoval[item.id] = item;
      }
      _show([
        for (final item in before)
          if (!ids.contains(item.id)) item,
      ]);
    }

    final repo = ref.read(itemRepositoryProvider);
    final timer = Timer(swipeUndoWindow, () {
      for (final item in removed) {
        _pendingRemoval.remove(item.id);
      }
      unawaited(delete(repo));
    });

    var settled = false;
    return () {
      if (settled) return;
      settled = true;
      timer.cancel();
      final back = [
        for (final item in removed)
          if (_pendingRemoval.remove(item.id) != null) item,
      ];
      if (back.isEmpty || !ref.mounted) return;
      final current = _current;
      if (current == null) return;
      final shown = {for (final item in current) item.id};
      _show([
        ...current,
        for (final item in back)
          if (!shown.contains(item.id)) item,
      ]);
    };
  }

  /// Moves the items in [ids] to shop [shopId] (null = no shop). For
  /// "Move" in select mode. All at once, like [clearChecked].
  Future<Failure?> moveSelected(Set<ItemId> ids, ShopId? shopId) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');
    if (ids.isEmpty) return null;

    final selected = [
      for (final item in before)
        if (ids.contains(item.id)) item,
    ];
    // The MOVED version goes in [_pending]: it's what [_overlay] lays over
    // any live update that arrives before the server answers. Storing the
    // old item here put the old shop back on screen, and nothing redrew it
    // once the save finished.
    for (final item in selected) {
      _pending[item.id] = item.copyWith(shopId: shopId);
    }
    _show([
      for (final item in before) _pending[item.id] ?? item,
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

  /// Loads the items from the server again.
  Future<void> refresh() async => ref.invalidateSelf();
}
