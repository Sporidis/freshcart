import 'package:freshcart_client/freshcart_client.dart' as dto;

/// A fixed instant so tests never depend on the wall clock.
final DateTime testNow = DateTime.utc(2026, 9, 9, 12);

/// Stable ids, so a test can assert on exact values.
final dto.UuidValue listUuid = dto.UuidValue.withValidation(
  '00000000-0000-4000-8000-000000000001',
);

/// The id of the item under test.
final dto.UuidValue itemUuid = dto.UuidValue.withValidation(
  '00000000-0000-4000-8000-000000000002',
);

/// The id of the acting user.
final dto.UuidValue userUuid = dto.UuidValue.withValidation(
  '00000000-0000-4000-8000-000000000003',
);

/// The id of a shop.
final dto.UuidValue shopUuid = dto.UuidValue.withValidation(
  '00000000-0000-4000-8000-000000000004',
);

/// Builds a wire [dto.ShoppingList].
///
/// Has an invite with [joinCode] valid for a day from `testNow`, unless
/// [joinCode] is null.
dto.ShoppingList buildListDto({
  String name = 'Groceries',
  String? joinCode = 'ABC23',
  List<dto.ListMember>? members,
}) => dto.ShoppingList(
  id: listUuid,
  name: name,
  joinCode: joinCode,
  joinCodeExpiresAt: joinCode == null
      ? null
      : testNow.add(const Duration(days: 1)),
  ownerId: userUuid,
  createdAt: testNow,
  members: members,
);

/// Builds a wire [dto.ListMember].
dto.ListMember buildMemberDto({
  String displayName = 'Nikolaos',
  dto.MemberRole role = dto.MemberRole.owner,
}) => dto.ListMember(
  listId: listUuid,
  userId: userUuid,
  displayName: displayName,
  role: role,
  joinedAt: testNow,
);

/// Builds a wire [dto.ShoppingItem].
dto.ShoppingItem buildItemDto({
  String name = 'Milk',
  bool pending = false,
  int quantity = 1,
  bool isChecked = false,
  double sortOrder = 0,
  dto.UuidValue? shopId,
  dto.Note? note,
  dto.UuidValue? checkedBy,
  DateTime? checkedAt,
}) => dto.ShoppingItem(
  id: itemUuid,
  listId: listUuid,
  name: name,
  quantity: quantity,
  isChecked: isChecked,
  sortOrder: sortOrder,
  shopId: shopId,
  note: note,
  addedBy: userUuid,
  checkedBy: checkedBy,
  checkedAt: checkedAt,
  createdAt: testNow,
  updatedAt: testNow,
);
