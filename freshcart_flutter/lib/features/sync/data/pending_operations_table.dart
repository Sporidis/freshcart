import 'package:drift/drift.dart';

/// What kind of write a [PendingOperations] row is waiting to replay.
///
/// One value per distinct repository method that gets queued, combined with
/// [PendingEntityType] to know which one to call on replay — except `create`
/// (shared by `item.add`/`list.create`: each entity type has exactly one
/// creation op, so `entityType` alone disambiguates) and `edit` (item `save`
/// only — `toggle`/`edit`/`reorder` all funnel through that one method, so
/// the repository layer genuinely can't tell them apart; this is the *only*
/// value allowed to stay coarse, for that reason). `joinByCode` has no value
/// here — it's not queued, see offline-sync-plan.md Phase C.
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

/// Which repository a [PendingOperations] row belongs to, so a replay knows
/// which one to call it against.
enum PendingEntityType { item, list }

/// A write that couldn't reach the server and is waiting to be replayed.
///
/// See offline-sync-plan.md §3 Phase B — this is the durable record behind
/// the in-memory queue idea, built to survive the app being killed.
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => textEnum<PendingEntityType>()();
  TextColumn get opType => textEnum<PendingOpType>()();
  TextColumn get payload => text()();
  TextColumn get tempId => text().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
}
