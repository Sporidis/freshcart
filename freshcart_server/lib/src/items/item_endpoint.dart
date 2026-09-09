import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/items/business/item_service.dart';
import 'package:serverpod/serverpod.dart';

/// The items on a list: read, add, save, remove.
class ItemEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Every item on a list the caller belongs to.
  Future<List<ShoppingItem>> byList(Session session, UuidValue listId) =>
      ItemService.byList(session, listId, session.requireUserId);

  /// The quantity used when a caller does not specify one.
  static const int defaultQuantity = 1;

  /// Adds an item to a list the caller belongs to.
  ///
  /// [quantity] is nullable rather than defaulted because Serverpod's generator
  /// drops Dart default values and emits any non-nullable named parameter as
  /// `required`. Nullability is what makes a parameter optional in the
  /// generated client, so the default lives here instead.
  Future<ShoppingItem> add(
    Session session,
    UuidValue listId,
    String name, {
    int? quantity,
    UuidValue? shopId,
    String? noteText,
  }) => ItemService.add(
    session,
    listId,
    session.requireUserId,
    name: name,
    quantity: quantity ?? defaultQuantity,
    shopId: shopId,
    noteText: noteText,
  );

  /// Writes an item back, rejecting the write on an optimistic-concurrency
  /// clash.
  Future<ShoppingItem> save(Session session, ShoppingItem item) =>
      ItemService.save(session, item, session.requireUserId);

  /// Deletes an item.
  Future<void> remove(Session session, UuidValue itemId) =>
      ItemService.remove(session, itemId, session.requireUserId);
}
