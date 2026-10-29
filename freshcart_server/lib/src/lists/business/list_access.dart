import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Who may read or change a list. Every service asks here, so each
/// permission rule exists once.
abstract final class ListAccess {
  /// Throws [NotAMemberException] if [userId] isn't on [listId].
  static Future<ListMember> requireMember(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    Transaction? transaction,
  }) async {
    final membership = await _membership(
      session,
      listId,
      userId,
      transaction: transaction,
    );
    if (membership == null) throw NotAMemberException();
    return membership;
  }

  /// [messages], passed on only while [userId] is still on [listId].
  ///
  /// For live streams. Checking membership once, when the stream starts, is
  /// not enough: someone removed from the list would keep receiving its
  /// changes until their app disconnects. The stream ends instead: quietly,
  /// not with an error, because being removed isn't a failure of the stream.
  ///
  /// Built from stream operators, not `async*` with `await for`: an `async*`
  /// only notices a cancel at its next `yield`, so a closed app would keep
  /// its listener (and session) alive until the list's next change.
  static Stream<T> whileMember<T>(
    Session session,
    UuidValue listId,
    UuidValue userId,
    Stream<T> messages,
  ) => messages
      .asyncMap(
        (message) async => (
          message: message,
          stillMember: await _membership(session, listId, userId) != null,
        ),
      )
      .takeWhile((checked) => checked.stillMember)
      .map((checked) => checked.message);

  /// [userId]'s membership of [listId], or null if they aren't on it.
  static Future<ListMember?> _membership(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    Transaction? transaction,
  }) => ListMember.db.findFirstRow(
    session,
    where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    transaction: transaction,
  );

  /// The list, if [userId] owns it.
  ///
  /// Throws [ListNotFoundException] if there's no such list, and
  /// [NotListOwnerException] if someone else owns it.
  static Future<ShoppingList> requireOwner(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != userId) throw NotListOwnerException();
    return list;
  }

  /// The item, if [userId] is on its list.
  ///
  /// Throws [ItemNotFoundException] or [NotAMemberException].
  static Future<ShoppingItem> requireItemAccess(
    Session session,
    UuidValue itemId,
    UuidValue userId, {
    Transaction? transaction,
  }) async {
    final item = await ShoppingItem.db.findById(
      session,
      itemId,
      transaction: transaction,
    );
    if (item == null) throw ItemNotFoundException();
    await requireMember(session, item.listId, userId, transaction: transaction);
    return item;
  }

  /// The shop, if [userId] is on its list.
  ///
  /// Throws [ShopNotFoundException] or [NotAMemberException].
  static Future<Shop> requireShopAccess(
    Session session,
    UuidValue shopId,
    UuidValue userId,
  ) async {
    final shop = await Shop.db.findById(session, shopId);
    if (shop == null) throw ShopNotFoundException();
    await requireMember(session, shop.listId, userId);
    return shop;
  }

  /// Throws [ShopNotFoundException] unless [shopId] is null or a shop on
  /// [listId]: an item can't be tagged with another list's shop.
  static Future<void> requireShopOnList(
    Session session,
    UuidValue listId,
    UuidValue? shopId, {
    Transaction? transaction,
  }) async {
    if (shopId == null) return;
    final shop = await Shop.db.findById(
      session,
      shopId,
      transaction: transaction,
    );
    if (shop == null || shop.listId != listId) throw ShopNotFoundException();
  }
}
