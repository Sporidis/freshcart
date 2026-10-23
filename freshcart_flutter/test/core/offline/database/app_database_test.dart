import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';

import '../../../helpers/date_time_precision.dart';

void main() {
  group('AppDatabase — PendingOperations durability', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      // A real file, not NativeDatabase.memory() — an in-memory database has
      // nothing to survive being closed, so it can't prove durability at all.
      tempDir = Directory.systemTemp.createTempSync('app_database_test');
      dbFile = File('${tempDir.path}/test.sqlite');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('a written PendingOperation survives close + reopen', () async {
      final firstOpen = AppDatabase(NativeDatabase(dbFile));
      final queuedAt = DateTime.now().truncatedToSeconds;
      final pendingOp = PendingOperationsCompanion.insert(
        entityType: PendingEntityType.item,
        opType: PendingOpType.create,
        payload: 'test payload',
        queuedAt: queuedAt,
      );

      await firstOpen.into(firstOpen.pendingOperations).insert(pendingOp);
      await firstOpen.close();

      final secondOpen = AppDatabase(NativeDatabase(dbFile));
      final rows = await secondOpen.select(secondOpen.pendingOperations).get();
      await secondOpen.close();

      expect(rows.length, 1);
      final row = rows.first;
      expect(row.entityType, PendingEntityType.item);
      expect(row.opType, PendingOpType.create);
      expect(row.payload, 'test payload');
      expect(row.queuedAt.toUtc(), pendingOp.queuedAt.value.toUtc());
    });
  });
}
