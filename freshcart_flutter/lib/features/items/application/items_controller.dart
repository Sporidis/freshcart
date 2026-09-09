import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/item_use_case_providers.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_controller.g.dart';

/// The items on one list, with optimistic updates.
///
/// Ticking something off in a shop must feel instant — the user is standing in
/// an aisle, not waiting on a spinner. So every mutation applies locally first,
/// then reconciles with what the server actually stored, and rolls back if the
/// server refused.
///
/// The rollback path is the one that matters and the one that is easy to get
/// wrong: two people editing the same list is this app's normal case, so
/// `Failure.conflict()` is an expected outcome, not an edge case.
@riverpod
class ItemsController extends _$ItemsController {
  @override
  Future<Result<List<ShoppingItem>>> build(ListId listId) =>
      ref.watch(itemRepositoryProvider).byList(listId);

  /// The items currently on screen, or null if none have loaded yet.
  List<ShoppingItem>? get _current => switch (state) {
    AsyncValue<Result<List<ShoppingItem>>>(
      value: Ok<List<ShoppingItem>>(:final value),
    ) =>
      value,
    _ => null,
  };

  void _show(List<ShoppingItem> items) =>
      state = AsyncData(Ok<List<ShoppingItem>>(items));

  /// Replaces [item] in the visible list, matching on id.
  List<ShoppingItem> _replacing(List<ShoppingItem> items, ShoppingItem item) =>
      [
        for (final existing in items)
          if (existing.id == item.id) item else existing,
      ];

  /// Checks or unchecks [item], applying the change immediately.
  ///
  /// Returns the failure if the server refused, so the screen can tell the user
  /// *why* the row it just saw tick suddenly untucked itself. A silent rollback
  /// would look like a bug.
  Future<Failure?> toggle(ShoppingItem item) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    // Read the cached identity synchronously when it is warm. Awaiting here
    // unconditionally would delay the *first* tick of a session behind an
    // identity lookup — precisely the lag optimistic updates exist to avoid.
    final cached = ref.read(currentUserIdProvider);
    final identity = cached.hasValue
        ? cached.requireValue
        : await ref.read(currentUserIdProvider.future);

    // Exhaustive switch, so a failure to identify the caller returns rather
    // than throwing — the convention this whole codebase runs on.
    final UserId userId;
    switch (identity) {
      case Ok<UserId>(:final value):
        userId = value;
      case Err<UserId>(:final failure):
        return failure;
    }

    // Optimistic: the same entity method the server's answer will agree with,
    // so the local guess and the eventual truth are computed one way.
    _show(
      _replacing(
        before,
        item.toggleChecked(by: userId, at: DateTime.now().toUtc()),
      ),
    );

    final result = await ref.read(toggleItemCheckedUseCaseProvider)(
      item,
      by: userId,
    );
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

  /// Adds an item, showing it only once the server has accepted it.
  ///
  /// Deliberately *not* optimistic: the server mints the id, `createdAt` and
  /// `updatedAt`, and a placeholder row with a fake id could not be edited or
  /// checked until it was replaced. Adding is also a deliberate act the user is
  /// already looking at, unlike ticking a box while walking.
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
        _show([...?_current, value]);
        return null;
      case Err<ShoppingItem>(:final failure):
        return failure;
    }
  }

  /// Saves an edited [item], applying the change immediately.
  Future<Failure?> save(ShoppingItem item) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    _show(_replacing(before, item));

    final result = await ref.read(itemRepositoryProvider).save(item);
    switch (result) {
      case Ok<ShoppingItem>(:final value):
        _show(_replacing(_current ?? before, value));
        return null;
      case Err<ShoppingItem>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Removes [item], taking it off screen immediately and putting it back if
  /// the server refuses.
  Future<Failure?> remove(ShoppingItem item) async {
    final before = _current;
    if (before == null) return const Failure.unexpected('No items loaded');

    _show([
      for (final existing in before)
        if (existing.id != item.id) existing,
    ]);

    final result = await ref.read(itemRepositoryProvider).remove(item.id);
    switch (result) {
      case Ok<void>():
        return null;
      case Err<void>(:final failure):
        _show(before);
        return failure;
    }
  }

  /// Re-reads the items from the server.
  Future<void> refresh() async => ref.invalidateSelf();
}
