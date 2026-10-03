import 'package:drift/drift.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_table.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_lists_table.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';

part 'app_database.g.dart';

/// The app's database on the phone (SQLite, using drift).
///
/// Three tables:
/// - [PendingOperations]: changes made offline, waiting to be sent.
/// - [CachedLists] and [CachedItems]: saved copies of lists and items, so
///   they can be shown without internet.
@DriftDatabase(tables: [PendingOperations, CachedLists, CachedItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  // Increase this every time the tables change, and add an upgrade step
  // below.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 2 added the offline cache tables.
      if (from < 2) {
        await m.createTable(cachedLists);
        await m.createTable(cachedItems);
      }
    },
  );
}
