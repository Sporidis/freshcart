import 'package:drift/drift.dart';

/// Database table: the last known items of each list, for offline use.
///
/// One row per list, with all its items as a JSON array in [data]. Not one
/// row per item: then a list saved as empty would leave no rows, and look
/// the same as a list that was never saved. Offline, the first shows as an
/// empty list; the second can't be shown at all.
///
/// The items are only ever read and written for a whole list at once, so
/// nothing needs to find a single item in here.
class CachedListItems extends Table {
  TextColumn get listId => text()();
  TextColumn get data => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listId};
}
