import 'package:drift/drift.dart';

/// Database table: the last known version of each item, for offline use.
///
/// The whole item is stored as JSON in [data], same as `CachedLists`.
class CachedItems extends Table {
  TextColumn get itemId => text()();
  TextColumn get listId => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}
