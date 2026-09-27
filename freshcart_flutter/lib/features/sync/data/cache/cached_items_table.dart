import 'package:drift/drift.dart';

/// A locally-persisted snapshot of one `ShoppingItem`'s last-known server
/// state, read back when a list opens with no signal. See `CachedLists`'
/// own doc comment for why this is one JSON blob column rather than one
/// column per field.
class CachedItems extends Table {
  TextColumn get itemId => text()();
  TextColumn get listId => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}
