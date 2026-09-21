import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:freshcart_flutter/features/sync/data/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_table.dart';

/// Persists writes that couldn't reach the server, so they survive the app
/// being killed and can be replayed later (Phase D).
///
/// Wraps [AppDatabase.pendingOperations] — nothing outside `data/` should
/// touch that table directly, same as `ConnectivityAdapter` wraps
/// `connectivity_plus`.
class PendingOperationsQueue {
  const PendingOperationsQueue(this._db);

  final AppDatabase _db;

  /// Records a write to replay once the server is reachable again.
  ///
  /// [payload] is whatever the real call needed (e.g. `add`'s name/quantity/
  /// shopId) — encoded to JSON here, so callers never think about the wire
  /// format. [tempId] is only set when queuing an `add`, whose server-minted
  /// id doesn't exist yet (see offline-sync-plan.md §2).
  Future<void> enqueue({
    required PendingEntityType entityType,
    required PendingOpType opType,
    required Map<String, dynamic> payload,
    String? tempId,
  }) {
    return _db
        .into(_db.pendingOperations)
        .insert(
          PendingOperationsCompanion.insert(
            entityType: entityType,
            opType: opType,
            payload: jsonEncode(payload),
            tempId: Value(tempId),
            queuedAt: DateTime.now(),
          ),
        );
  }

  Future<List<PendingOperation>> getAll() {
    return (_db.select(
      _db.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.queuedAt)])).get();
  }

  Future<int> remove(int id) {
    return (_db.delete(
      _db.pendingOperations,
    )..where((row) => row.id.equals(id))).go();
  }

  Stream<int> watchCount() {
    return _db.select(_db.pendingOperations).watch().map((rows) => rows.length);
  }
}
