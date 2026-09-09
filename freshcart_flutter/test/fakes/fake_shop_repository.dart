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

  @override
  Future<Result<List<Shop>>> byList(ListId listId) async => byListResult;

  @override
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  }) async => createResult ?? const Err(Failure.unexpected('create not set'));

  @override
  Future<Result<Shop>> save(Shop shop) async => Ok(shop);

  @override
  Future<Result<void>> remove(ShopId id) async {
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
