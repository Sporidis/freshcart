import 'package:drift/drift.dart';

/// What kind of change a queued row is.
///
/// Together with [PendingEntityType] (item or list), this tells
/// [QueueDrainer] which repository method to call.
///
/// - `create` is used for both new items and new lists.
/// - `edit` covers every item change (check, rename, reorder...), because
///   they all go through the same `save()` method.
/// - Joining a list isn't here: it can't be done offline.
enum PendingOpType {
  create,
  edit,
  remove,
  clearChecked,
  removeMany,
  moveMany,
  rename,
  setClearCheckedAfterShopping,
  transferOwnership,
  leave,
  delete,
  removeMember,
}

/// Whether a queued change is about an item or a list.
enum PendingEntityType { item, list }

/// Database table: changes made offline, waiting to be sent to the server.
///
/// One row per change. [payload] is the change's data as JSON.
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => textEnum<PendingEntityType>()();
  TextColumn get opType => textEnum<PendingOpType>()();
  TextColumn get payload => text()();
  TextColumn get tempId => text().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
}
