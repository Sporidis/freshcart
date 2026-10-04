import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/fakes/fake_push.dart';

import 'demo_world.dart';

void main() {
  late DemoWorld world;

  setUp(() => world = DemoWorld());

  group('FakeAuth', () {
    test("a renamed display name shows in the list's members", () async {
      final list = await world.sharedList();

      await world.b.auth.setDisplayName('Anna B.');
      await world.b.auth.setAvatarColor(HexColor.fromArgb(0xFF7E9CDB));

      final seenByA = (await world.a.lists.byId(list.id)).valueOrNull!;
      final anna = seenByA.memberFor(DemoWorld.bId)!;
      expect(anna.displayName, 'Anna B.');
      expect(anna.avatarColor, HexColor.fromArgb(0xFF7E9CDB));
      expect(seenByA.memberFor(DemoWorld.aId)?.displayName, 'Nikolaos');
    });

    test('authStateChanges sends the new name', () async {
      final names = <String?>[];
      final sub = world.a.auth.authStateChanges().listen(
        (u) => names.add(u?.displayName),
      );
      await pumpEventQueue();
      await world.a.auth.setDisplayName('Niko');
      await pumpEventQueue();
      await sub.cancel();
      expect(names, ['Nikolaos', 'Niko']);
    });

    test('real-account features are blocked, sign-out included', () async {
      expect((await world.a.auth.linkGoogle()).isErr, isTrue);
      expect(
        (await world.a.auth.linkEmail(email: 'a@b.c', password: 'x')).isErr,
        isTrue,
      );
      expect((await world.a.auth.signOut()).isErr, isTrue);
      expect(world.a.auth.currentUser, isNotNull);
    });
  });

  group('FakePush', () {
    test('is never supported, but settings stick', () async {
      final push = FakePush();
      final listId = ListId('list-1');

      expect(await push.isSupported(), isFalse);
      await push.setMemberJoinedNotificationsEnabled(true);
      await push.setListMuted(listId, muted: true);

      expect(
        (await push.notificationPreferences()).valueOrNull?.memberJoined,
        isTrue,
      );
      expect(await push.isListMuted(listId), const Ok(true));
    });
  });
}
