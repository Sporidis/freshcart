import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/shops/business/shop_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for a list's shops.
class ShopEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// All shops on a list (the caller must be a member).
  Future<List<Shop>> byList(Session session, UuidValue listId) =>
      ShopService.byList(session, listId, session.requireUserId);

  /// Creates a shop on a list (the caller must be a member).
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

  /// Saves changes to a shop.
  Future<Shop> save(Session session, Shop shop) =>
      ShopService.save(session, shop, session.requireUserId);

  /// How many items a shop has.
  Future<int> itemCount(Session session, UuidValue shopId) =>
      ShopService.itemCount(session, shopId, session.requireUserId);

  /// Deletes a shop. [disposition] says what happens to its items.
  ///
  /// [disposition] has no default on purpose: the user must decide what
  /// happens to the items.
  Future<void> remove(
    Session session,
    UuidValue shopId,
    ShopItemDisposition disposition,
    UuidValue? moveToShopId,
  ) => ShopService.remove(
    session,
    shopId,
    session.requireUserId,
    disposition: disposition,
    moveToShopId: moveToShopId,
  );
}
