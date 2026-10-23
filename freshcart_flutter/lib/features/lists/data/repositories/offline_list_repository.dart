import 'dart:async';
import 'dart:math';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/remote_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_list_repository.g.dart';

/// A [ListRepository] that keeps working offline.
///
/// Wraps another [ListRepository] (the remote one) and passes every call
/// through. Only when that comes back as [NetworkFailure] does it step in:
/// writes are queued for later, and the lists are read from the cache.
class OfflineListRepository implements ListRepository {
  OfflineListRepository(
    this._remote,
    this._queue,
    this._cache,
    this._currentUserId,
  );

  final ListRepository _remote;
  final PendingOperationsQueue _queue;
  final CachedListsStore _cache;

  /// The signed-in user's id, read when needed (it can change).
  final UserId Function() _currentUserId;

  // ── Reads ────────────────────────────────────────────────────────────

  /// The user's lists. Saved to the cache when they load, and read from
  /// it when the server can't be reached. Other errors (like
  /// unauthorized) are passed on.
  @override
  Future<Result<List<ShoppingList>>> myLists() async {
    final result = await _remote.myLists();
    if (result case Ok(:final value)) {
      // Without waiting: if saving fails we still have the lists.
      unawaited(_cache.replaceAll(value).catchError((_) {}));
      return result;
    }
    if (!_isOffline(result)) return result;
    final cached = await _cache.readAll();
    return cached == null ? result : Ok(cached);
  }

  @override
  Future<Result<ShoppingList>> byId(ListId id) => _remote.byId(id);

  @override
  Future<Result<List<ListSummary>>> summaries(List<ListId> ids) =>
      _remote.summaries(ids);

  @override
  Stream<Result<ShoppingList>> watch(ListId id) => _remote.watch(id);

  /// Joining needs the server to check the code, so it's never queued.
  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) =>
      _remote.joinByCode(code);

  // ── Writes: pass through, queue when offline ─────────────────────────

  @override
  Future<Result<ShoppingList>> create({required String name}) async {
    final result = await _remote.create(name: name);
    if (!_isOffline(result)) return result;

    // The queue and the screen share one temporary id, so later offline
    // changes to this list (adding items to it) point at the right one.
    final tempId = _newTempId();
    await _enqueue(PendingOpType.create, tempId: tempId, {'name': name});
    return Ok(_pendingNewList(ListId(tempId), name));
  }

  @override
  Future<Result<void>> rename(ListId id, String name) => _queueWhenOffline(
    _remote.rename(id, name),
    PendingOpType.rename,
    {'id': id.value, 'name': name},
  );

  @override
  Future<Result<void>> setClearCheckedAfterShopping(ListId id, bool value) =>
      _queueWhenOffline(
        _remote.setClearCheckedAfterShopping(id, value),
        PendingOpType.setClearCheckedAfterShopping,
        {'id': id.value, 'value': value},
      );

  @override
  Future<Result<void>> leave(ListId id) => _queueWhenOffline(
    _remote.leave(id),
    PendingOpType.leave,
    {'id': id.value},
  );

  @override
  Future<Result<void>> delete(ListId id) => _queueWhenOffline(
    _remote.delete(id),
    PendingOpType.delete,
    {'id': id.value},
  );

  @override
  Future<Result<void>> removeMember(ListId id, UserId userId) =>
      _queueWhenOffline(
        _remote.removeMember(id, userId),
        PendingOpType.removeMember,
        {'id': id.value, 'userId': userId.value},
      );

  @override
  Future<Result<void>> transferOwnership(ListId id, UserId userId) =>
      _queueWhenOffline(
        _remote.transferOwnership(id, userId),
        PendingOpType.transferOwnership,
        {'id': id.value, 'userId': userId.value},
      );

  // ── Offline helpers ──────────────────────────────────────────────────

  /// Waits for [write]; if the server couldn't be reached, queues it as
  /// [opType] with [payload] and answers Ok.
  Future<Result<void>> _queueWhenOffline(
    Future<Result<void>> write,
    PendingOpType opType,
    Map<String, Object?> payload,
  ) async {
    final result = await write;
    if (!_isOffline(result)) return result;
    await _enqueue(opType, payload);
    return const Ok(null);
  }

  /// Whether [result] failed only because the server couldn't be reached.
  static bool _isOffline(Result<Object?> result) => switch (result) {
    Err(failure: NetworkFailure()) => true,
    _ => false,
  };

  /// Saves a list change to send once the server is reachable again.
  Future<void> _enqueue(
    PendingOpType opType,
    Map<String, Object?> payload, {
    String? tempId,
  }) => _queue.enqueue(
    entityType: PendingEntityType.list,
    opType: opType,
    tempId: tempId,
    payload: payload,
  );

  /// The list to show for a create that's waiting in the queue. Its join
  /// code is a stand-in: the server picks the real one.
  ShoppingList _pendingNewList(ListId id, String name) {
    final random = Random();
    final code = List.generate(
      JoinCode.length,
      (_) => JoinCode.alphabet[random.nextInt(JoinCode.alphabet.length)],
    ).join();
    return ShoppingList(
      id: id,
      name: name,
      createdAt: DateTime.now().toUtc(),
      joinCode: JoinCode.parse(code).valueOrNull!,
      ownerId: _currentUserId(),
      pending: true,
    );
  }

  /// A temporary id for something created offline, until the server gives
  /// it a real one.
  static String _newTempId() => 'temp-${DateTime.now().microsecondsSinceEpoch}';
}

/// Supplies the app's [ListRepository]: the server, kept working offline.
///
/// Its type is the interface ([ListRepository]), so the rest of the app
/// only knows the interface, and tests can swap in a fake.
@Riverpod(keepAlive: true)
ListRepository listRepository(Ref ref) => OfflineListRepository(
  ref.watch(remoteListRepositoryProvider),
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(cachedListsStoreProvider),
  () =>
      ref.read(currentUserIdProvider).asData?.value.valueOrNull ??
      (throw StateError(
        'currentUserId not resolved — cannot queue an offline change without a known user',
      )),
);
