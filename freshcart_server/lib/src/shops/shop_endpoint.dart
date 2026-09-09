import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/shops/business/shop_service.dart';
import 'package:serverpod/serverpod.dart';

/// The shops belonging to a list.
class ShopEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Every shop on a list the caller belongs to.
  Future<List<Shop>> byList(Session session, UuidValue listId) =>
      ShopService.byList(session, listId, session.requireUserId);

  /// Creates a shop on a list the caller belongs to.
  Future<Shop> create(
    Session session,
    UuidValue listId,
    String name,
    int colorArgb,
  ) => ShopService.create(
    session,
    listId,
    session.requireUserId,
    name: name,
    colorArgb: colorArgb,
  );

  /// Writes a shop back.
  Future<Shop> save(Session session, Shop shop) =>
      ShopService.save(session, shop, session.requireUserId);

  /// Deletes a shop, untagging its items rather than deleting them.
  Future<void> remove(Session session, UuidValue shopId) =>
      ShopService.remove(session, shopId, session.requireUserId);
}
