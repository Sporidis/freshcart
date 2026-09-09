import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/shops/data/mappers/shop_mapper.dart';

/// The Serverpod-backed [ShopRepository].
class ShopRepositoryImpl implements ShopRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  const ShopRepositoryImpl(this._client);

  final dto.Client _client;

  @override
  Future<Result<List<Shop>>> byList(ListId listId) => _guard(
    () async => (await _client.shop.byList(
      _uuid(listId.value),
    )).map((s) => s.toDomain()).toList(),
  );

  @override
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  }) => _guard(
    () async => (await _client.shop.create(
      _uuid(listId.value),
      name,
      color.argb,
    )).toDomain(),
  );

  @override
  Future<Result<Shop>> save(Shop shop) =>
      _guard(() async => (await _client.shop.save(shop.toDto())).toDomain());

  @override
  Future<Result<void>> remove(ShopId id) =>
      _guard(() => _client.shop.remove(_uuid(id.value)));

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
