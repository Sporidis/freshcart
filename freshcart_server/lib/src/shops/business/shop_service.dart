import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:serverpod/serverpod.dart';

/// The logic for a list's shops.
abstract final class ShopService {
  /// All shops on [listId] (the caller must be a member).
  static Future<List<Shop>> byList(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListAccess.requireMember(session, listId, userId);
    return Shop.db.find(session, where: (t) => t.listId.equals(listId));
  }

  /// Creates a shop on [listId].
  static Future<Shop> create(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    required String name,
    required int colorArgb,
  }) async {
    await ListAccess.requireMember(session, listId, userId);
    return Shop.db.insertRow(
      session,
      Shop(listId: listId, name: name, colorArgb: colorArgb),
    );
  }

  /// Saves [incoming]. It always stays on its own list.
  static Future<Shop> save(
    Session session,
    Shop incoming,
    UuidValue userId,
  ) async {
    final stored = await Shop.db.findById(session, incoming.id!);
    if (stored == null) throw ShopNotFoundException();
    await ListAccess.requireMember(session, stored.listId, userId);

    // listId is set by the server only (like items), so a shop can't be
    // moved to another list.
    return Shop.db.updateRow(
      session,
      incoming.copyWith(listId: stored.listId),
    );
  }

  /// How many items shop [shopId] has. Shown in the delete sheet.
  static Future<int> itemCount(
    Session session,
    UuidValue shopId,
    UuidValue userId,
  ) async {
    final stored = await Shop.db.findById(session, shopId);
    if (stored == null) throw ShopNotFoundException();
    await ListAccess.requireMember(session, stored.listId, userId);
    return ShoppingItem.db.count(
      session,
      where: (t) => t.shopId.equals(shopId),
    );
  }

  /// Deletes a shop. [disposition] says what happens to its items.
  ///
  /// The caller must choose, so items are never deleted (or kept) without
  /// the user deciding. (The database would untag them anyway, with ON
  /// DELETE SET NULL, but we still make it explicit.)
  ///
  /// In a transaction: moving the items and then failing to delete the
  /// shop would leave things half done.
  static Future<void> remove(
    Session session,
    UuidValue shopId,
    UuidValue userId, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    UuidValue? moveToShopId,
  }) async {
    final stored = await Shop.db.findById(session, shopId);
    if (stored == null) throw ShopNotFoundException();
    await ListAccess.requireMember(session, stored.listId, userId);

    if (disposition == ShopItemDisposition.moveToShop) {
      if (moveToShopId == null) {
        throw ShopNotFoundException();
      }
      final target = await Shop.db.findById(session, moveToShopId);
      // Can't move items to a shop on another list (they'd leave their list).
      if (target == null || target.listId != stored.listId) {
        throw ShopNotFoundException();
      }
    }

    await session.db.transaction((transaction) async {
      switch (disposition) {
        case ShopItemDisposition.untag:
          break;
        case ShopItemDisposition.moveToShop:
          final items = await ShoppingItem.db.find(
            session,
            where: (t) => t.shopId.equals(shopId),
            transaction: transaction,
          );
          await ShoppingItem.db.update(
            session,
            [for (final item in items) item.copyWith(shopId: moveToShopId)],
            transaction: transaction,
          );
        case ShopItemDisposition.deleteItems:
          await ShoppingItem.db.deleteWhere(
            session,
            where: (t) => t.shopId.equals(shopId),
            transaction: transaction,
          );
      }
      await Shop.db.deleteRow(session, stored, transaction: transaction);
    });
  }
}
