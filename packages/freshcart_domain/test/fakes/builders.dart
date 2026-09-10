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

/// Builds a [ShoppingList] with sensible defaults, overriding only what a test
/// actually cares about.
ShoppingList buildList({
  String id = 'list-1',
  String name = 'Weekly Groceries',
  String joinCode = 'ABC23',
  List<ListMember> members = const <ListMember>[],
}) => ShoppingList(
  id: ListId(id),
  name: name,
  joinCode: JoinCode.parse(joinCode).valueOrNull!,
  ownerId: testUser,
  createdAt: testNow,
  members: members,
);

/// Builds a [Shop] with sensible defaults, overriding only what a test
/// actually cares about.
Shop buildShop({
  String id = 'shop-1',
  String name = 'Albert Heijn',
  int colorArgb = 0xFF2456A6,
}) => Shop(
  id: ShopId(id),
  listId: testList,
  name: name,
  color: HexColor.fromArgb(colorArgb),
);
