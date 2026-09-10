import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// Business operations on the shops belonging to a list.
abstract final class ShopService {
  /// Every shop on [listId], for a caller who belongs to it.
  static Future<List<Shop>> byList(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
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
    await ListService.requireMembership(session, listId, userId);
    return Shop.db.insertRow(
      session,
      Shop(listId: listId, name: name, colorArgb: colorArgb),
    );
  }

  /// Writes [incoming] back, keeping it on the list it started on.
  static Future<Shop> save(
    Session session,
    Shop incoming,
    UuidValue userId,
  ) async {
    final stored = await Shop.db.findById(session, incoming.id!);
    if (stored == null) throw ShopNotFoundException();
    await ListService.requireMembership(session, stored.listId, userId);

    // listId is server-owned, as with items: a shop cannot be moved to another
    // list by editing a field.
    return Shop.db.updateRow(
      session,
      incoming.copyWith(listId: stored.listId),
    );
  }

  /// How many products are tagged to [shopId].
  ///
  /// The delete sheet leads with this number, because "delete Colruyt" reads
  /// very differently when it is holding six things than when it is empty.
  static Future<int> itemCount(
    Session session,
    UuidValue shopId,
    UuidValue userId,
  ) async {
    final stored = await Shop.db.findById(session, shopId);
    if (stored == null) throw ShopNotFoundException();
    await ListService.requireMembership(session, stored.listId, userId);
    return ShoppingItem.db.count(
      session,
      where: (t) => t.shopId.equals(shopId),
    );
  }

  /// Deletes a shop, disposing of its products as [disposition] says.
  ///
  /// The caller must choose: products are never destroyed silently, and never
  /// silently kept either when someone meant to clear them out. Untagging is
  /// the safe default the schema already provides (ON DELETE SET NULL on
  /// `shopId`), but it is still stated rather than assumed.
  ///
  /// Runs in a transaction: moving six products and then failing to delete the
  /// shop would leave the list in a state the user never asked for.
  static Future<void> remove(
    Session session,
    UuidValue shopId,
    UuidValue userId, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    UuidValue? moveToShopId,
  }) async {
    final stored = await Shop.db.findById(session, shopId);
    if (stored == null) throw ShopNotFoundException();
    await ListService.requireMembership(session, stored.listId, userId);

    if (disposition == ShopItemDisposition.moveToShop) {
      if (moveToShopId == null) {
        throw ShopNotFoundException();
      }
      final target = await Shop.db.findById(session, moveToShopId);
      // A shop from another list is not a valid destination: it would move
      // products off the list they belong to.
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
