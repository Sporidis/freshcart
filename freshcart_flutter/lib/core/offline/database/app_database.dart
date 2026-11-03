import 'package:drift/drift.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_list_items_table.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_table.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_table.dart';

part 'app_database.g.dart';

/// The app's database on the phone (SQLite, using drift).
///
/// Three tables:
/// - [PendingOperations]: changes made offline, waiting to be sent.
/// - [CachedLists] and [CachedListItems]: saved copies of lists and their
///   items, so they can be shown without internet.
@DriftDatabase(tables: [PendingOperations, CachedLists, CachedListItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  // Increase this every time the tables change, and add an upgrade step
  // below.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 2 added the offline cache tables.
      if (from < 2) {
        await m.createTable(cachedLists);
      }
      // Version 3 saves a list's items in one row, not one row per item
      // (see CachedListItems). It's only a cache, so the old rows are
      // dropped, not converted: each list refills the next time it's
      // opened online. The queued changes are not touched.
      if (from < 3) {
        await m.deleteTable('cached_items');
        await m.createTable(cachedListItems);
      }
    },
  );
}
