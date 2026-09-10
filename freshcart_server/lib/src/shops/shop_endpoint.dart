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
  /// How many products are tagged to a shop.
  Future<int> itemCount(Session session, UuidValue shopId) =>
      ShopService.itemCount(session, shopId, session.requireUserId);

  /// Deletes a shop, disposing of its products as the caller chooses.
  ///
  /// [disposition] is required at the call site rather than defaulted, because
  /// the whole point of the flow is that someone decides what happens to the
  /// products instead of finding out afterwards.
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
