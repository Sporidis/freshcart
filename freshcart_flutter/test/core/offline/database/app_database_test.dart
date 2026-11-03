import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_items_store.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';

import '../../../fakes/dto_builders.dart';
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

  group('AppDatabase — upgrading from version 2', () {
    late Directory tempDir;
    late AppDatabase db;
    final oldListId = ListId(listUuid.uuid);

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('app_database_upgrade');
      // A phone still on version 2: the tables exactly as v2 created them,
      // with one queued change and one cached item in them. `setup` runs
      // before drift looks at the version, so drift sees a v2 database.
      final executor = NativeDatabase(
        File('${tempDir.path}/v2.sqlite'),
        setup: (raw) {
          if (raw.userVersion != 0) return;
          raw
            ..execute(
              'CREATE TABLE "pending_operations" ("id" INTEGER NOT NULL '
              'PRIMARY KEY AUTOINCREMENT, "entity_type" TEXT NOT NULL, '
              '"op_type" TEXT NOT NULL, "payload" TEXT NOT NULL, '
              '"temp_id" TEXT NULL, "queued_at" INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE "cached_lists" ("list_id" TEXT NOT NULL, '
              '"data" TEXT NOT NULL, "cached_at" INTEGER NOT NULL, '
              'PRIMARY KEY ("list_id"))',
            )
            ..execute(
              'CREATE TABLE "cached_items" ("item_id" TEXT NOT NULL, '
              '"list_id" TEXT NOT NULL, "data" TEXT NOT NULL, '
              '"cached_at" INTEGER NOT NULL, PRIMARY KEY ("item_id"))',
            )
            ..execute(
              'INSERT INTO pending_operations (entity_type, op_type, payload, '
              "queued_at) VALUES ('item', 'create', 'queued offline', 0)",
            )
            ..execute(
              "INSERT INTO cached_items VALUES ('item-1', '$oldListId', '{}', 0)",
            )
            ..userVersion = 2;
        },
      );
      db = AppDatabase(executor);
    });

    tearDown(() async {
      await db.close();
      tempDir.deleteSync(recursive: true);
    });

    test('changes made offline survive the upgrade', () async {
      // Not yet sent to the server: losing them loses the user's work.
      final rows = await db.select(db.pendingOperations).get();

      expect(rows.single.payload, 'queued offline');
    });

    test('the old per-item cache is dropped, not misread', () async {
      final store = CachedItemsStore(db);
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'cached_items'",
          )
          .get();

      expect(tables, isEmpty);
      // Refilled the next time the list is opened online.
      expect(await store.readForList(oldListId), isNull);
      await store.replaceForList(oldListId, const []);
      expect(await store.readForList(oldListId), isEmpty);
    });
  });
}
