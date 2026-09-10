import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
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

  /// Re-applies in-flight optimistic values over an incoming snapshot.
  Result<List<ShoppingItem>> _overlay(Result<List<ShoppingItem>> event) {
    if (_pending.isEmpty) return event;
    return event.map(
      (items) => [
        for (final item in items) _pending[item.id] ?? item,
      ],
    );
  }

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

  /// Adds an item, showing it only once the server has accepted it.
  ///
  /// Deliberately *not* optimistic: the server mints the id, `createdAt` and
  /// `updatedAt`, and a placeholder row with a fabricated id could not be
  /// edited or checked until it was replaced.
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
        // The live stream will carry this too; appending here keeps the field
        // responsive, and the merge is by id so the echo is a no-op.
        final current = _current;
        if (current != null && !current.any((i) => i.id == value.id)) {
          _show([...current, value]);
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

  /// Re-reads the items from the server.
  Future<void> refresh() async => ref.invalidateSelf();
}
