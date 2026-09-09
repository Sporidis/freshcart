import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/list_realtime_source.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';

/// The Serverpod-backed [ListRepository].
///
/// This class is the boundary: DTOs come in from `freshcart_client`, domain
/// entities go out, and nothing above it ever sees a `dto.` type. Expected
/// failures become `Err(Failure)` rather than exceptions.
class ListRepositoryImpl implements ListRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  const ListRepositoryImpl(this._client);

  final dto.Client _client;

  @override
  Future<Result<List<ShoppingList>>> myLists() => _guard(
    () async =>
        (await _client.list.myLists()).map((l) => l.toDomain()).toList(),
  );

  @override
  Future<Result<ShoppingList>> byId(ListId id) => _guard(
    () async => (await _client.list.byId(_uuid(id.value))).toDomain(),
  );

  @override
  Future<Result<ShoppingList>> create({required String name}) =>
      _guard(() async => (await _client.list.create(name)).toDomain());

  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) =>
      _guard(() async => (await _client.list.join(code.value)).toDomain());

  @override
  Future<Result<ShoppingList>> rename(ListId id, String name) => _guard(
    () async => (await _client.list.rename(_uuid(id.value), name)).toDomain(),
  );

  @override
  Future<Result<void>> leave(ListId id) =>
      _guard(() => _client.list.leave(_uuid(id.value)));

  @override
  Stream<Result<ShoppingList>> watch(ListId id) =>
      ListRealtimeSource(_client).watch(id);

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  /// Runs [body], turning any thrown transport error into an `Err`.
  ///
  /// Every method funnels through this so the try/catch and the
  /// exception-to-[Failure] translation exist exactly once.
  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}
