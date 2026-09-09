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

  /// Deletes a shop.
  ///
  /// Items tagged to it are untagged rather than deleted — the ON DELETE SET
  /// NULL on `shopId` does that in the database. Losing a shop must never lose
  /// the shopping.
  static Future<void> remove(
    Session session,
    UuidValue shopId,
    UuidValue userId,
  ) async {
    final stored = await Shop.db.findById(session, shopId);
    if (stored == null) throw ShopNotFoundException();
    await ListService.requireMembership(session, stored.listId, userId);
    await Shop.db.deleteRow(session, stored);
  }
}
