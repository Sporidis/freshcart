import 'package:drift/drift.dart';

/// Database table: the last known version of each list, for offline use.
///
/// The whole list is stored as JSON in [data], not one column per field.
/// That's simpler, and we only ever look rows up by [listId] anyway.
class CachedLists extends Table {
  TextColumn get listId => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listId};
}
