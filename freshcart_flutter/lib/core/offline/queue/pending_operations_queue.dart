import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/database/app_database_provider.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_change.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_operations_queue.g.dart';

/// The offline queue: changes that couldn't be sent to the server.
///
/// Saved in the database, so they're not lost if the app is closed.
/// [PendingOperationsReplayer] sends them later. Only this class touches the
/// `pendingOperations` table directly.
class PendingOperationsQueue {
  const PendingOperationsQueue(this._db);

  final AppDatabase _db;

  /// Adds [change] to the queue.
  ///
  /// The row's type columns, payload JSON and temporary id all come from
  /// [change], so a row can't be stored with a type that doesn't match its
  /// payload. See offline-sync-plan.md §2 for why creates carry a tempId.
  Future<void> enqueue(PendingChange change) {
    return _db
        .into(_db.pendingOperations)
        .insert(
          PendingOperationsCompanion.insert(
            entityType: change.entityType,
            opType: change.opType,
            payload: jsonEncode(change.toJson()),
            tempId: Value(change.tempId),
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

  /// How many changes are waiting to be sent.
  Future<int> count() => _db.pendingOperations.count().getSingle();

  /// Deletes every waiting change. Used on sign-out.
  Future<void> clear() => _db.delete(_db.pendingOperations).go();
}

/// Reads a queue row back as the [PendingChange] it was stored from.
extension PendingOperationChange on PendingOperation {
  /// The change in this row: the reverse of [PendingOperationsQueue.enqueue].
  ///
  /// Throws [FormatException] for a row that can't be read back.
  PendingChange toChange() {
    try {
      return PendingChange.fromQueue(
        entityType,
        opType,
        jsonDecode(payload) as Map<String, Object?>,
        tempId: tempId,
      );
    } catch (e) {
      throw FormatException('Failed to read queued change: $e');
    }
  }
}

/// Supplies the [PendingOperationsQueue], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
PendingOperationsQueue pendingOperationsQueue(Ref ref) =>
    PendingOperationsQueue(ref.watch(appDatabaseProvider));
