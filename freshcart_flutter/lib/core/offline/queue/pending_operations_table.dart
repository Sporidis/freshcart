import 'package:drift/drift.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';

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
