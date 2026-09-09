import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [ItemRepository] for controller and widget tests.
class FakeItemRepository implements ItemRepository {
  /// What [byList] returns.
  Result<List<ShoppingItem>> byListResult = const Ok(<ShoppingItem>[]);

  /// What [save] returns. Defaults to echoing the saved item, as the server
  /// would after a successful write.
  Result<ShoppingItem>? saveResult;

  /// What [add] returns.
  Result<ShoppingItem>? addResult;

  /// What [remove] returns.
  Result<void> removeResult = const Ok<void>(null);

  /// Items passed to [save], in order.
  final List<ShoppingItem> savedItems = [];

  /// Ids passed to [remove], in order.
  final List<ItemId> removedIds = [];

  /// Completes before [save] answers, to observe the optimistic state.
  Future<void>? savePause;

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
  }) async => addResult ?? const Err(Failure.unexpected('add not configured'));

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) async {
    savedItems.add(item);
    if (savePause != null) await savePause;
    return saveResult ?? Ok(item);
  }

  @override
  Future<Result<void>> remove(ItemId id) async {
    removedIds.add(id);
    return removeResult;
  }

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      throw UnimplementedError();
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
}) => ShoppingItem(
  id: ItemId(id),
  listId: ListId(listId),
  name: name,
  addedBy: UserId('user-1'),
  createdAt: DateTime.utc(2026, 9, 9),
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 9),
  quantity: quantity,
  isChecked: isChecked,
  checkedBy: checkedBy == null ? null : UserId(checkedBy),
  checkedAt: checkedBy == null ? null : DateTime.utc(2026, 9, 9),
  note: note,
);
