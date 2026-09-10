import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [ShopRepository] for controller and widget tests.
class FakeShopRepository implements ShopRepository {
  /// What [byList] returns.
  Result<List<Shop>> byListResult = const Ok(<Shop>[]);

  /// What [create] returns.
  Result<Shop>? createResult;

  /// What [remove] returns.
  Result<void> removeResult = const Ok<void>(null);

  /// Ids passed to [remove], in order.
  final List<ShopId> removedIds = [];

  /// What [itemCount] will report.
  int itemCountResult = 0;

  /// How each [remove] was asked to dispose of the shop's items.
  final List<({ShopId id, ShopItemDisposition disposition, ShopId? moveTo})>
  removeCalls = [];

  /// Every shop passed to [save], in order. Lets a test assert that a preview
  /// wrote nothing.
  final List<Shop> savedShops = [];

  @override
  Future<Result<List<Shop>>> byList(ListId listId) async => byListResult;

  @override
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  }) async => createResult ?? const Err(Failure.unexpected('create not set'));

  @override
  Future<Result<Shop>> save(Shop shop) async {
    savedShops.add(shop);
    return Ok(shop);
  }

  @override
  Future<Result<int>> itemCount(ShopId id) async => Ok(itemCountResult);

  @override
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    ShopId? moveTo,
  }) async {
    removeCalls.add((id: id, disposition: disposition, moveTo: moveTo));
    removedIds.add(id);
    return removeResult;
  }
}

/// Builds a domain [Shop] for tests.
Shop buildShop({
  String id = '00000000-0000-4000-8000-0000000000c1',
  String listId = '00000000-0000-4000-8000-000000000001',
  String name = 'Colruyt',
  String color = '#4CAF50',
}) => Shop(
  id: ShopId(id),
  listId: ListId(listId),
  name: name,
  color: HexColor.parse(color).valueOrNull!,
);
