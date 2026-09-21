import 'dart:async';
import 'dart:math';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/list_realtime_source.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/list_summary_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/cached_lists_store.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_table.dart';

/// The Serverpod-backed [ListRepository].
///
/// This class is the boundary: DTOs come in from `freshcart_client`, domain
/// entities go out, and nothing above it ever sees a `dto.` type. Expected
/// failures become `Err(Failure)` rather than exceptions.
class ListRepositoryImpl implements ListRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  const ListRepositoryImpl(
    this._client,
    this.queue,
    this._connectivityAdapter,
    this.currentUserId,
    this._cache,
  );

  final dto.Client _client;
  final PendingOperationsQueue queue;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedListsStore _cache;

  final UserId Function() currentUserId;

  @override
  Future<Result<List<ShoppingList>>> myLists() async {
    final result = await _guard(
      () async =>
          (await _client.list.myLists()).map((l) => l.toDomain()).toList(),
    );
    switch (result) {
      case Ok(:final value):
        unawaited(_cache.replaceAll(value));
        return result;
      case Err(:final failure):
        // A cold start with no signal: nothing in _guard's retry loop ever
        // reached the server, so fall back to whatever was last synced
        // (`docs/offline-sync-plan.md` §4's "cached reads") rather than
        // showing ListsScreen an error for a connectivity problem it can't
        // do anything about. Any other failure (unauthorized, ...) is real
        // and surfaces as-is.
        if (failure is NetworkFailure) {
          final cached = await _cache.readAll();
          if (cached != null) return Ok(cached);
        }
        return result;
    }
  }

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
  Future<Result<ShoppingList>> create({required String name}) => _guard(
    () async => (await _client.list.create(name)).toDomain(),
    onUnreachable: () async {
      final tempId = _mintTempId();
      final random = Random();
      final joinCodeString = List.generate(
        JoinCode.length,
        (_) => JoinCode.alphabet[random.nextInt(JoinCode.alphabet.length)],
      ).join();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.create,
        tempId: tempId,
        payload: <String, dynamic>{
          'name': name,
        },
      );
      return ShoppingList(
        id: ListId(tempId),
        name: name,
        createdAt: DateTime.now().toUtc(),
        joinCode: JoinCode.parse(
          joinCodeString,
        ).valueOrNull!,
        ownerId: currentUserId(),
        pending: true,
      );
    },
  );

  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) =>
      _guard(() async => (await _client.list.join(code.value)).toDomain());

  @override
  Future<Result<ShoppingList>> rename(ListId id, String name) => _guard(
    () async => (await _client.list.rename(_uuid(id.value), name)).toDomain(),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.rename,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
          'name': name,
        },
      );
      return ShoppingList(
        id: ListId(tempId),
        name: name,
        createdAt: DateTime.now().toUtc(),
        joinCode: JoinCode.parse(
          'TEMP',
        ).valueOrNull!,
        ownerId: currentUserId(),
        pending: true,
      );
    },
  );

  @override
  Future<Result<ShoppingList>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  ) => _guard(
    () async => (await _client.list.setClearCheckedAfterShopping(
      _uuid(id.value),
      value,
    )).toDomain(),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.setClearCheckedAfterShopping,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
          'value': value,
        },
      );
      return ShoppingList(
        id: ListId(tempId),
        name: 'TEMP',
        createdAt: DateTime.now().toUtc(),
        joinCode: JoinCode.parse(
          'TEMP',
        ).valueOrNull!,
        ownerId: currentUserId(),
        pending: true,
      );
    },
  );

  @override
  Future<Result<void>> leave(ListId id) => _guard(
    () => _client.list.leave(_uuid(id.value)),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.leave,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
        },
      );
    },
  );

  @override
  Future<Result<void>> delete(ListId id) => _guard(
    () => _client.list.delete(_uuid(id.value)),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.delete,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
        },
      );
    },
  );

  @override
  Future<Result<void>> removeMember(ListId id, UserId userId) => _guard(
    () => _client.list.removeMember(_uuid(id.value), _uuid(userId.value)),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.removeMember,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
          'userId': userId.value,
        },
      );
    },
  );

  @override
  Future<Result<ShoppingList>> transferOwnership(
    ListId id,
    UserId userId,
  ) => _guard(
    () async => (await _client.list.transferOwnership(
      _uuid(id.value),
      _uuid(userId.value),
    )).toDomain(),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.list,
        opType: PendingOpType.transferOwnership,
        tempId: tempId,
        payload: <String, dynamic>{
          'id': id.value,
          'userId': userId.value,
        },
      );

      return ShoppingList(
        id: ListId(tempId),
        name: 'TEMP',
        createdAt: DateTime.now().toUtc(),
        joinCode: JoinCode.parse(
          'TEMP',
        ).valueOrNull!,
        ownerId: currentUserId(),
        pending: true,
      );
    },
  );

  @override
  Stream<Result<ShoppingList>> watch(ListId id) =>
      ListRealtimeSource(_client, _connectivityAdapter, _cache).watch(id);

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  /// Runs [body], turning any thrown transport error into an `Err`.
  ///
  /// If the error is due to the server being unreachable and [onUnreachable]
  /// is provided, it will be called to handle the situation.
  static Future<Result<T>> _guard<T>(
    Future<T> Function() body, {
    Future<T> Function()? onUnreachable,
  }) async {
    try {
      return Ok(await retryOnUnreachable(body, maxAttempts: 2));
    } on Object catch (error) {
      if (isUnreachable(error) && onUnreachable != null) {
        return Ok(await onUnreachable());
      }
      return Err(mapExceptionToFailure(error));
    }
  }

  String _mintTempId() => 'temp-${DateTime.now().microsecondsSinceEpoch}';
}
