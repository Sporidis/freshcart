import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [ItemRepository] for controller and widget tests.
class FakeItemRepository implements ItemRepository {
  /// What [byList] returns.
  Result<List<ShoppingItem>> byListResult = const Ok(<ShoppingItem>[]);

  /// What [save] returns. Defaults to echoing the saved item, as the server
  /// would after a successful write.
  Result<ShoppingItem>? saveResult;

  /// What consecutive [save] calls return, in order; falls back to
  /// [saveResult] once exhausted. For tests where the server's answer
  /// differs call to call.
  final List<Result<ShoppingItem>> saveResults = [];

  /// What [add] returns.
  Result<ShoppingItem>? addResult;

  /// What [remove] returns.
  Result<void> removeResult = const Ok<void>(null);

  /// What [clearChecked] returns.
  Result<int> clearCheckedResult = const Ok(0);

  /// What [removeMany] returns.
  Result<int>? removeManyResult;

  /// What [moveMany] returns.
  Result<int>? moveManyResult;

  /// What [suggestNames] returns.
  Result<List<String>> suggestNamesResult = const Ok(<String>[]);

  /// Every (listId, query) pair [suggestNames] was called with, in order.
  final List<({ListId listId, String query})> suggestNamesCalls = [];

  /// What [recentNames] returns.
  Result<List<NameHistoryEntry>> recentNamesResult = const Ok(
    <NameHistoryEntry>[],
  );

  /// Every listId [recentNames] was called with, in order.
  final List<ListId> recentNamesCalls = [];

  /// Every argument list [add] was called with, in order.
  final List<
    ({
      ListId listId,
      String name,
      int quantity,
      ShopId? shopId,
      String? noteText,
    })
  >
  addCalls = [];

  /// Items passed to [save], in order.
  final List<ShoppingItem> savedItems = [];

  /// Ids passed to [remove], in order.
  final List<ItemId> removedIds = [];

  /// Every id list passed to [removeMany], in order.
  final List<List<ItemId>> removeManyCalls = [];

  /// Every (ids, shopId) pair passed to [moveMany], in order.
  final List<({List<ItemId> ids, ShopId? shopId})> moveManyCalls = [];

  /// How many times [clearChecked] was called.
  int clearCheckedCallCount = 0;

  /// Completes before [save] answers, to observe the optimistic state.
  Future<void>? savePause;

  /// When set, [moveMany] waits for it, so a test can act mid-move.
  Future<void>? movePause;

  /// Completes before [add] answers, to observe state (or a busy guard)
  /// while the add is still in flight.
  Future<void>? addPause;

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) async =>
      byListResult;

  @override
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    addCalls.add((
      listId: listId,
      name: name,
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
    ));
    if (addPause != null) await addPause;
    return addResult ?? const Err(Failure.unexpected('add not configured'));
  }

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) async {
    savedItems.add(item);
    if (savePause != null) await savePause;
    if (savedItems.length <= saveResults.length) {
      return saveResults[savedItems.length - 1];
    }
    return saveResult ?? Ok(item);
  }

  @override
  Future<Result<void>> remove(ItemId id) async {
    removedIds.add(id);
    return removeResult;
  }

  @override
  Future<Result<int>> clearChecked(ListId listId) async {
    clearCheckedCallCount++;
    return clearCheckedResult;
  }

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) async {
    removeManyCalls.add(ids);
    return removeManyResult ?? Ok(ids.length);
  }

  @override
  Future<Result<int>> moveMany(
    ListId listId,
    List<ItemId> ids,
    ShopId? shopId,
  ) async {
    moveManyCalls.add((ids: ids, shopId: shopId));
    if (movePause != null) await movePause;
    return moveManyResult ?? Ok(ids.length);
  }

  /// Feeds [watchByList]. Tests push snapshots through this to simulate
  /// another client changing the list.
  final StreamController<Result<List<ShoppingItem>>> live =
      StreamController<Result<List<ShoppingItem>>>.broadcast();

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) {
    // Seeded exactly as the real source is: one immediate snapshot, then live
    // updates. Stream.multi rather than an async* generator so the live
    // listener attaches synchronously on subscribe — otherwise a test that
    // pushes an event right after the seed would race the generator.
    return Stream<Result<List<ShoppingItem>>>.multi((controller) {
      controller.add(byListResult);
      final subscription = live.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  /// Closes the live stream. Call from a test teardown.
  Future<void> dispose() => live.close();

  @override
  Future<Result<List<String>>> suggestNames(
    ListId listId,
    String query,
  ) async {
    suggestNamesCalls.add((listId: listId, query: query));
    return suggestNamesResult;
  }

  @override
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId) async {
    recentNamesCalls.add(listId);
    return recentNamesResult;
  }
}

/// Builds a domain [ShoppingItem] for tests.
ShoppingItem buildItem({
  String id = '00000000-0000-4000-8000-0000000000aa',
  String listId = '00000000-0000-4000-8000-000000000001',
  String name = 'Milk',
  int quantity = 1,
  bool isChecked = false,
  String? checkedBy,
  DateTime? updatedAt,
  Note? note,
  double sortOrder = 0,
  ShopId? shopId,
}) => ShoppingItem(
  id: ItemId(id),
  listId: ListId(listId),
  name: name,
  addedBy: UserId('user-1'),
  sortOrder: sortOrder,
  shopId: shopId,
  createdAt: DateTime.utc(2026, 9, 9),
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 9),
  quantity: quantity,
  isChecked: isChecked,
  checkedBy: checkedBy == null ? null : UserId(checkedBy),
  checkedAt: checkedBy == null ? null : DateTime.utc(2026, 9, 9),
  note: note,
);
