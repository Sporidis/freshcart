import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/items/data/item_realtime_source.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

/// The Serverpod-backed [ItemRepository].
class ItemRepositoryImpl implements ItemRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  const ItemRepositoryImpl(this._client);

  final dto.Client _client;

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) => _guard(
    () async => (await _client.item.byList(
      _uuid(listId.value),
    )).map((i) => i.toDomain()).toList(),
  );

  @override
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) => _guard(
    () async => (await _client.item.add(
      _uuid(listId.value),
      name,
      quantity: quantity,
      shopId: shopId == null ? null : _uuid(shopId.value),
      noteText: noteText,
    )).toDomain(),
  );

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) =>
      _guard(() async => (await _client.item.save(item.toDto())).toDomain());

  @override
  Future<Result<void>> remove(ItemId id) =>
      _guard(() => _client.item.remove(_uuid(id.value)));

  @override
  Future<Result<int>> clearChecked(ListId listId) =>
      _guard(() => _client.item.clearChecked(_uuid(listId.value)));

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) => _guard(
    () => _client.item.removeMany(
      _uuid(listId.value),
      [for (final id in ids) _uuid(id.value)],
    ),
  );

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      ItemRealtimeSource(_client).watchByList(listId);

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}
