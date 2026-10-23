import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/list_summary_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/sources/list_realtime_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_list_repository.g.dart';

/// The [ListRepository] that only talks to the Serverpod server.
///
/// Serverpod types (`dto.`) come in, domain types go out. When the server
/// can't be reached the result is `Err(Failure.network)`: deciding what
/// to do about that (queue it, or show cached lists) is the offline
/// layer's job.
class RemoteListRepository implements ListRepository {
  const RemoteListRepository(
    this._client,
    this._connectivityAdapter,
    this._cache,
  );

  final dto.Client _client;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedListsStore _cache;

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
  Future<Result<List<ListSummary>>> summaries(List<ListId> ids) => _guard(
    () async => (await _client.list.summaries([
      for (final id in ids) _uuid(id.value),
    ])).map((s) => s.toDomain()).toList(),
  );

  @override
  Future<Result<ShoppingList>> create({required String name}) =>
      _guard(() async => (await _client.list.create(name)).toDomain());

  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) =>
      _guard(() async => (await _client.list.join(code.value)).toDomain());

  @override
  Future<Result<void>> rename(ListId id, String name) =>
      _guard(() => _client.list.rename(_uuid(id.value), name));

  @override
  Future<Result<void>> setClearCheckedAfterShopping(ListId id, bool value) =>
      _guard(
        () => _client.list.setClearCheckedAfterShopping(_uuid(id.value), value),
      );

  @override
  Future<Result<void>> leave(ListId id) =>
      _guard(() => _client.list.leave(_uuid(id.value)));

  @override
  Future<Result<void>> delete(ListId id) =>
      _guard(() => _client.list.delete(_uuid(id.value)));

  @override
  Future<Result<void>> removeMember(ListId id, UserId userId) => _guard(
    () => _client.list.removeMember(_uuid(id.value), _uuid(userId.value)),
  );

  @override
  Future<Result<void>> transferOwnership(ListId id, UserId userId) => _guard(
    () => _client.list.transferOwnership(_uuid(id.value), _uuid(userId.value)),
  );

  /// The list, live from the server (cached for when it's gone).
  @override
  Stream<Result<ShoppingList>> watch(ListId id) =>
      ListRealtimeSource(_client, _connectivityAdapter, _cache).watch(id);

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await retryOnUnreachable(body, maxAttempts: 2));
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}

/// Supplies the [RemoteListRepository]: what the offline queue is
/// replayed through, so a replay can never queue itself again.
@Riverpod(keepAlive: true)
RemoteListRepository remoteListRepository(Ref ref) => RemoteListRepository(
  ref.watch(serverpodClientProvider),
  ref.watch(connectivityAdapterProvider),
  ref.watch(cachedListsStoreProvider),
);
