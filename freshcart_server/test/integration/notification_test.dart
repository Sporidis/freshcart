import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/notification_digest.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/notifications/business/push_sender.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Records what would have been pushed, instead of pushing it.
class RecordingPushSender implements PushSender {
  final List<PushMessage> sent = [];

  @override
  Future<void> send(Session session, PushMessage message) async =>
      sent.add(message);
}

PendingItemNotification pending({
  required String actorName,
  String itemName = 'Milk',
}) => PendingItemNotification(
  listId: UuidValue.withValidation('00000000-0000-4000-8000-000000000001'),
  actorId: UuidValue.withValidation('00000000-0000-4000-8000-000000000002'),
  actorName: actorName,
  itemName: itemName,
);

void main() {
  group('NotificationDigest', () {
    test('names the item when one person adds one thing', () {
      final digest = NotificationDigest.summarise('Groceries', [
        pending(actorName: 'Mom', itemName: 'Milk'),
      ]);

      expect(digest?.title, 'Groceries');
      expect(digest?.body, 'Mom added Milk');
    });

    test('aggregates a burst from one person', () {
      // The reason changes are buffered at all: three items added in a row
      // should buzz a phone once, not three times.
      final digest = NotificationDigest.summarise('Groceries', [
        pending(actorName: 'Mom', itemName: 'Milk'),
        pending(actorName: 'Mom', itemName: 'Bread'),
        pending(actorName: 'Mom', itemName: 'Eggs'),
      ]);

      // Names them: what was added is the point.
      expect(digest?.body, 'Mom added Milk, Bread and Eggs');
    });

    test('past three items, names two and counts the rest', () {
      final digest = NotificationDigest.summarise('Groceries', [
        for (final name in ['Milk', 'Bread', 'Eggs', 'Butter', 'Rice'])
          pending(actorName: 'Mom', itemName: name),
      ]);

      expect(digest?.body, 'Mom added Milk, Bread and 3 more');
    });

    test('an item added twice in the batch is named once', () {
      final digest = NotificationDigest.summarise('Groceries', [
        pending(actorName: 'Mom', itemName: 'Milk'),
        pending(actorName: 'Mom', itemName: 'milk'),
        pending(actorName: 'Mom', itemName: 'Eggs'),
      ]);

      expect(digest?.body, 'Mom added Milk and Eggs');
    });

    test('names two people, and counts for more', () {
      final two = NotificationDigest.summarise('Groceries', [
        pending(actorName: 'Mom', itemName: 'Milk'),
        pending(actorName: 'Dad', itemName: 'Eggs'),
      ]);
      expect(two?.body, 'Mom and Dad added Milk and Eggs');

      final three = NotificationDigest.summarise('Groceries', [
        pending(actorName: 'Mom', itemName: 'Milk'),
        pending(actorName: 'Dad', itemName: 'Eggs'),
        pending(actorName: 'Sam', itemName: 'Rice'),
      ]);
      expect(three?.body, '3 people added 3 items');
    });

    test('stays silent for an empty batch', () {
      expect(NotificationDigest.summarise('Groceries', []), isNull);
    });
  });

  group('NotificationService.sendDelay', () {
    final first = DateTime.utc(2026, 10, 3, 12);

    test('one minute after the last add, normally', () {
      expect(
        NotificationService.sendDelay(now: first, firstPendingAt: first),
        const Duration(minutes: 1),
      );
    });

    test('never later than three minutes after the first add', () {
      // Adding all along: 2.5 minutes in, only 30s of the cap is left.
      final now = first.add(const Duration(minutes: 2, seconds: 30));
      expect(
        NotificationService.sendDelay(now: now, firstPendingAt: first),
        const Duration(seconds: 30),
      );
    });

    test('straight away once the cap has passed', () {
      final now = first.add(const Duration(minutes: 4));
      expect(
        NotificationService.sendDelay(now: now, firstPendingAt: first),
        Duration.zero,
      );
    });
  });

  final aliceId = const Uuid().v4();
  final bobId = const Uuid().v4();
  final carolId = const Uuid().v4();

  withServerpod('Given notifications', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    Future<ShoppingList> aSharedList() async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);
      await endpoints.list.join(as(carolId), list.joinCode);
      return list;
    }

    test('registering the same token twice does not duplicate it', () async {
      await endpoints.notification.registerDevice(
        as(aliceId),
        'token-1',
        DevicePlatform.android,
      );
      final second = await endpoints.notification.registerDevice(
        as(aliceId),
        'token-1',
        DevicePlatform.android,
      );

      final session = sessionBuilder.build();
      final all = await DeviceToken.db.find(
        session,
        where: (t) => t.token.equals('token-1'),
      );
      expect(all, hasLength(1));
      expect(second.ownerId, UuidValue.withValidation(aliceId));
    });

    test('re-registering a token re-points it at the new owner', () async {
      // A shared device that changes hands must stop notifying the old user.
      await endpoints.notification.registerDevice(
        as(aliceId),
        'token-shared',
        DevicePlatform.android,
      );
      final moved = await endpoints.notification.registerDevice(
        as(bobId),
        'token-shared',
        DevicePlatform.android,
      );

      expect(moved.ownerId, UuidValue.withValidation(bobId));
    });

    test('unregistering cannot remove someone else\'s token', () async {
      await endpoints.notification.registerDevice(
        as(aliceId),
        'token-alice',
        DevicePlatform.android,
      );
      await endpoints.notification.unregisterDevice(
        as(bobId),
        'token-alice',
      );

      final session = sessionBuilder.build();
      final all = await DeviceToken.db.find(
        session,
        where: (t) => t.token.equals('token-alice'),
      );
      expect(all, hasLength(1));
      expect(all.first.ownerId, UuidValue.withValidation(aliceId));
    });

    test('unregistering removes the caller\'s own token', () async {
      await endpoints.notification.registerDevice(
        as(aliceId),
        'token-alice-own',
        DevicePlatform.android,
      );
      await endpoints.notification.unregisterDevice(
        as(aliceId),
        'token-alice-own',
      );

      final session = sessionBuilder.build();
      final all = await DeviceToken.db.find(
        session,
        where: (t) => t.token.equals('token-alice-own'),
      );
      expect(all, isEmpty);
    });

    test('the actor is never among the recipients', () async {
      final list = await aSharedList();
      for (final entry in {aliceId: 'a', bobId: 'b', carolId: 'c'}.entries) {
        await endpoints.notification.registerDevice(
          as(entry.key),
          'token-${entry.value}',
          DevicePlatform.android,
        );
      }

      final session = sessionBuilder.build();
      final tokens = await NotificationService.recipientTokens(
        session,
        list.id!,
        {UuidValue.withValidation(aliceId)},
      );

      expect(
        tokens.map((t) => t.token),
        unorderedEquals(['token-b', 'token-c']),
      );
    });

    test('a muted list excludes that member', () async {
      final list = await aSharedList();
      for (final entry in {aliceId: 'a', bobId: 'b', carolId: 'c'}.entries) {
        await endpoints.notification.registerDevice(
          as(entry.key),
          'token-${entry.value}',
          DevicePlatform.android,
        );
      }
      await endpoints.notification.setListMuted(as(bobId), list.id!, true);

      final session = sessionBuilder.build();
      final tokens = await NotificationService.recipientTokens(
        session,
        list.id!,
        {UuidValue.withValidation(aliceId)},
      );

      expect(tokens.map((t) => t.token), ['token-c']);
    });

    test('unmuting restores delivery', () async {
      final list = await aSharedList();
      await endpoints.notification.registerDevice(
        as(bobId),
        'token-b',
        DevicePlatform.android,
      );
      await endpoints.notification.setListMuted(as(bobId), list.id!, true);
      expect(
        await endpoints.notification.isListMuted(as(bobId), list.id!),
        isTrue,
      );

      await endpoints.notification.setListMuted(as(bobId), list.id!, false);
      expect(
        await endpoints.notification.isListMuted(as(bobId), list.id!),
        isFalse,
      );

      final session = sessionBuilder.build();
      final tokens = await NotificationService.recipientTokens(
        session,
        list.id!,
        {UuidValue.withValidation(aliceId)},
      );
      expect(tokens.map((t) => t.token), ['token-b']);
    });

    test('a non-member cannot mute someone else\'s list', () async {
      final list = await endpoints.list.create(as(aliceId), 'Private');
      await expectLater(
        endpoints.notification.setListMuted(as(bobId), list.id!, true),
        throwsA(isA<NotAMemberException>()),
      );
    });

    group('NotificationPreferences (decisions #80, phase 2)', () {
      test(
        'defaults to everything on (decision #108), with no row written',
        () async {
          final prefs = await endpoints.notification.preferences(
            as(aliceId),
          );

          expect(prefs.itemAdded, isTrue);
          expect(prefs.memberJoined, isTrue);
          expect(prefs.listFinished, isTrue);

          final session = sessionBuilder.build();
          final rows = await NotificationPreferences.db.find(
            session,
            where: (t) => t.userId.equals(UuidValue.withValidation(aliceId)),
          );
          expect(rows, isEmpty);
        },
      );

      test('each setter persists and reads back independently', () async {
        await endpoints.notification.setItemAddedEnabled(as(aliceId), false);
        await endpoints.notification.setMemberJoinedEnabled(
          as(aliceId),
          true,
        );

        final prefs = await endpoints.notification.preferences(as(aliceId));
        expect(prefs.itemAdded, isFalse);
        expect(prefs.memberJoined, isTrue);
        // Untouched setting keeps its default.
        expect(prefs.listFinished, isTrue);
      });
    });

    test('adding items buffers one push, not one per item', () async {
      final recorder = RecordingPushSender();
      NotificationService.sender = recorder;
      addTearDown(() => NotificationService.sender = const LoggingPushSender());

      final list = await aSharedList();
      await endpoints.notification.registerDevice(
        as(bobId),
        'token-b',
        DevicePlatform.android,
      );

      await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      await endpoints.item.add(as(aliceId), list.id!, 'Bread');
      await endpoints.item.add(as(aliceId), list.id!, 'Eggs');

      // Flush directly rather than waiting out the aggregation window.
      final session = sessionBuilder.build();
      await NotificationService.flush(session, list.id!);

      expect(recorder.sent, hasLength(1));
      expect(recorder.sent.single.body, endsWith('added Milk, Bread and Eggs'));
      expect(recorder.sent.single.tokens, ['token-b']);
    });

    test(
      'ticking, unticking and editing queue no push: only additions do',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await aSharedList();
        await endpoints.notification.registerDevice(
          as(bobId),
          'token-b-tick',
          DevicePlatform.android,
        );
        final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        await endpoints.item.add(as(aliceId), list.id!, 'Bread');
        final session = sessionBuilder.build();
        await NotificationService.flush(session, list.id!);
        expect(recorder.sent, hasLength(1)); // the two adds
        recorder.sent.clear();

        // Tick, untick, then rename: none of these is an addition.
        final ticked = await endpoints.item.save(
          as(aliceId),
          milk.copyWith(isChecked: true),
        );
        final unticked = await endpoints.item.save(
          as(aliceId),
          ticked.copyWith(isChecked: false),
        );
        await endpoints.item.save(
          as(aliceId),
          unticked.copyWith(name: 'Oat milk'),
        );

        final queued = await PendingItemNotification.db.find(
          session,
          where: (t) => t.listId.equals(list.id!),
        );
        expect(queued, isEmpty);
        await NotificationService.flush(session, list.id!);
        expect(recorder.sent, isEmpty);
      },
    );

    test('flushing twice does not resend the same batch', () async {
      final recorder = RecordingPushSender();
      NotificationService.sender = recorder;
      addTearDown(() => NotificationService.sender = const LoggingPushSender());

      final list = await aSharedList();
      await endpoints.notification.registerDevice(
        as(bobId),
        'token-b2',
        DevicePlatform.android,
      );
      await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      final session = sessionBuilder.build();
      await NotificationService.flush(session, list.id!);
      await NotificationService.flush(session, list.id!);

      expect(recorder.sent, hasLength(1));
    });

    test('nothing is sent when every recipient has muted the list', () async {
      final recorder = RecordingPushSender();
      NotificationService.sender = recorder;
      addTearDown(() => NotificationService.sender = const LoggingPushSender());

      final list = await aSharedList();
      await endpoints.notification.registerDevice(
        as(bobId),
        'token-b3',
        DevicePlatform.android,
      );
      await endpoints.notification.setListMuted(as(bobId), list.id!, true);
      await endpoints.notification.setListMuted(as(carolId), list.id!, true);

      await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final session = sessionBuilder.build();
      await NotificationService.flush(session, list.id!);

      expect(recorder.sent, isEmpty);
    });

    test(
      'a recipient who turned off item-added is skipped, others still get it',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await aSharedList();
        await endpoints.notification.registerDevice(
          as(bobId),
          'token-b4',
          DevicePlatform.android,
        );
        await endpoints.notification.registerDevice(
          as(carolId),
          'token-c4',
          DevicePlatform.android,
        );
        await endpoints.notification.setItemAddedEnabled(as(bobId), false);

        await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        final session = sessionBuilder.build();
        await NotificationService.flush(session, list.id!);

        expect(recorder.sent, hasLength(1));
        expect(recorder.sent.single.tokens, ['token-c4']);
      },
    );

    test(
      'someone joining notifies by default (decision #108), but not a '
      'member who switched it off',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.notification.registerDevice(
          as(aliceId),
          'token-a5',
          DevicePlatform.android,
        );

        await endpoints.list.join(as(bobId), list.joinCode);
        expect(recorder.sent, hasLength(1));
        recorder.sent.clear();

        await endpoints.notification.setMemberJoinedEnabled(
          as(aliceId),
          false,
        );
        await endpoints.list.join(as(carolId), list.joinCode);
        expect(recorder.sent, isEmpty);
      },
    );

    test(
      'someone joining notifies an opted-in member, never the joiner',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.notification.setMemberJoinedEnabled(
          as(aliceId),
          true,
        );
        await endpoints.notification.registerDevice(
          as(aliceId),
          'token-a6',
          DevicePlatform.android,
        );
        // The joiner's own device -- must never receive "you joined."
        await endpoints.notification.registerDevice(
          as(bobId),
          'token-b6',
          DevicePlatform.android,
        );

        await endpoints.list.join(as(bobId), list.joinCode);

        expect(recorder.sent, hasLength(1));
        expect(recorder.sent.single.tokens, ['token-a6']);
      },
    );

    test(
      're-tapping an already-valid invite link does not notify again',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.notification.setMemberJoinedEnabled(as(aliceId), true);
        await endpoints.notification.registerDevice(
          as(aliceId),
          'token-a7',
          DevicePlatform.android,
        );

        await endpoints.list.join(as(bobId), list.joinCode);
        await endpoints.list.join(as(bobId), list.joinCode); // re-tap

        expect(recorder.sent, hasLength(1));
      },
    );

    test(
      'checking the last open item notifies an opted-in member, never the '
      'one who checked it',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await aSharedList();
        await endpoints.notification.setListFinishedEnabled(
          as(bobId),
          true,
        );
        await endpoints.notification.registerDevice(
          as(bobId),
          'token-b8',
          DevicePlatform.android,
        );
        // Alice both adds and checks the item -- must never receive "your
        // own list finished."
        await endpoints.notification.registerDevice(
          as(aliceId),
          'token-a8',
          DevicePlatform.android,
        );

        final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        await endpoints.item.save(
          as(aliceId),
          item.copyWith(isChecked: true),
        );

        expect(recorder.sent, hasLength(1));
        expect(recorder.sent.single.tokens, ['token-b8']);
        expect(recorder.sent.single.body, contains('All done'));
      },
    );

    test('checking one item of several open ones sends nothing', () async {
      final recorder = RecordingPushSender();
      NotificationService.sender = recorder;
      addTearDown(() => NotificationService.sender = const LoggingPushSender());

      final list = await aSharedList();
      await endpoints.notification.setListFinishedEnabled(as(bobId), true);
      await endpoints.notification.registerDevice(
        as(bobId),
        'token-b9',
        DevicePlatform.android,
      );

      final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      await endpoints.item.add(as(aliceId), list.id!, 'Bread');
      await endpoints.item.save(as(aliceId), milk.copyWith(isChecked: true));

      expect(recorder.sent, isEmpty);
    });

    test(
      'editing an already-checked item once the list is done does not '
      're-notify',
      () async {
        final recorder = RecordingPushSender();
        NotificationService.sender = recorder;
        addTearDown(
          () => NotificationService.sender = const LoggingPushSender(),
        );

        final list = await aSharedList();
        await endpoints.notification.setListFinishedEnabled(
          as(bobId),
          true,
        );
        await endpoints.notification.registerDevice(
          as(bobId),
          'token-b10',
          DevicePlatform.android,
        );

        final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        final checked = await endpoints.item.save(
          as(aliceId),
          item.copyWith(isChecked: true),
        );
        expect(recorder.sent, hasLength(1));

        // Renaming the already-checked item is not a fresh completion.
        await endpoints.item.save(
          as(aliceId),
          checked.copyWith(name: 'Whole milk'),
        );

        expect(recorder.sent, hasLength(1));
      },
    );
  });
}
