import 'package:freshcart_domain/freshcart_domain.dart';

/// A fixed instant so tests never depend on the wall clock.
final DateTime testNow = DateTime.utc(2026, 9, 9, 12);

/// A [UserId] for the acting user in tests.
final UserId testUser = UserId('user-1');

/// A [ListId] for the list under test.
final ListId testList = ListId('list-1');

/// Builds a [ShoppingItem] with sensible defaults, overriding only what a test
/// actually cares about.
ShoppingItem buildItem({
  String id = 'item-1',
  String name = 'Milk',
  int quantity = 1,
  bool isChecked = false,
  ShopId? shopId,
  Note? note,
  UserId? checkedBy,
  DateTime? checkedAt,
}) => ShoppingItem(
  id: ItemId(id),
  listId: testList,
  name: name,
  addedBy: testUser,
  createdAt: testNow,
  updatedAt: testNow,
  quantity: quantity,
  isChecked: isChecked,
  shopId: shopId,
  note: note,
  checkedBy: checkedBy,
  checkedAt: checkedAt,
);
