import 'package:drift/drift.dart';
import 'package:freshcart_flutter/features/sync/data/cached_items_table.dart';
import 'package:freshcart_flutter/features/sync/data/cached_lists_table.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_table.dart';

part 'app_database.g.dart';

/// The app's local SQLite database — the offline write queue
/// ([PendingOperations]) and the read cache ([CachedLists]/[CachedItems])
/// that lets a list still open with no signal (`docs/offline-sync-plan.md`
/// §4's "cached reads", deferred out of the original write-queue phases and
/// built as its own phase).
@DriftDatabase(tables: [PendingOperations, CachedLists, CachedItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedLists);
        await m.createTable(cachedItems);
      }
    },
  );
}
