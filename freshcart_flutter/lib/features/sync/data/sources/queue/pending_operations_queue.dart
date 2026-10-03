import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_operations_queue.g.dart';

/// The offline queue: changes that couldn't be sent to the server.
///
/// Saved in the database, so they're not lost if the app is closed.
/// [QueueDrainer] sends them later. Only this class touches the
/// `pendingOperations` table directly.
class PendingOperationsQueue {
  const PendingOperationsQueue(this._db);

  final AppDatabase _db;

  /// Adds a change to the queue.
  ///
  /// [payload] holds what the server call needs (for an add: name,
  /// quantity, shop...). It's turned into JSON here.
  ///
  /// [tempId] is only for "create" operations. A new item made offline has
  /// no real id yet (the server gives it one), so it gets a temporary id.
  /// See offline-sync-plan.md §2.
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

  /// Every queued change, oldest first.
  Future<List<PendingOperation>> getAll() {
    return (_db.select(
      _db.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.queuedAt)])).get();
  }

  /// Removes one change from the queue (after it was sent).
  Future<int> remove(int id) {
    return (_db.delete(
      _db.pendingOperations,
    )..where((row) => row.id.equals(id))).go();
  }

  /// Every queued change, oldest first, again whenever the queue changes.
  /// Lets the screen show what's still waiting (see
  /// `applyQueuedItemChanges`).
  Stream<List<PendingOperation>> watchAll() {
    return (_db.select(
      _db.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.queuedAt)])).watch();
  }

  /// How many changes are in the queue, updated whenever it changes.
  Stream<int> watchCount() {
    return _db.select(_db.pendingOperations).watch().map((rows) => rows.length);
  }
}

/// Supplies the [PendingOperationsQueue], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
PendingOperationsQueue pendingOperationsQueue(Ref ref) =>
    PendingOperationsQueue(ref.watch(appDatabaseProvider));
