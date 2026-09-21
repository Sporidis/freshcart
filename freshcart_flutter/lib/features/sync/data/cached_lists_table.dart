import 'package:drift/drift.dart';

/// A locally-persisted snapshot of one `ShoppingList`, read back when the
/// app opens with no signal (`docs/offline-sync-plan.md` §4's "cached
/// reads", deferred out of the original write-queue phases and built as its
/// own phase). [data] is the whole entity, JSON-encoded via
/// `ShoppingListCachePayload` -- one blob column rather than one column per
/// field, matching `PendingOperations`' own payload column, since nothing
/// here is ever queried by a field other than [listId].
class CachedLists extends Table {
  TextColumn get listId => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listId};
}
