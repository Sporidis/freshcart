import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/unconfigured_push_token_source.dart';

import '../../../../fakes/dto_builders.dart';
import '../../../../fakes/fake_client.dart';

/// A token source under test control.
class FakePushTokenSource implements PushTokenSource {
  FakePushTokenSource({this.supported = true, this.value = 'token-1'});

  bool supported;
  String? value;

  @override
  dto.DevicePlatform get platform => dto.DevicePlatform.android;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<String?> token() async => value;
}

void main() {
  late FakeClient client;
  late FakePushTokenSource tokens;
  late PushRepositoryImpl repository;

  setUp(() {
    client = FakeClient();
    tokens = FakePushTokenSource();
    repository = PushRepositoryImpl(client, tokens);
  });

  group('isSupported', () {
    test('reflects the token source', () async {
      expect(await repository.isSupported(), isTrue);
      tokens.supported = false;
      expect(await repository.isSupported(), isFalse);
    });
  });

  group('registerDevice', () {
    test('sends the token and platform', () async {
      // registerDevice returns a DeviceToken, and FakeClient casts to the
      // endpoint's return type, so the fake has to answer with one.
      client.handler = (_, _, _) => dto.DeviceToken(
        ownerId: userUuid,
        token: 'token-1',
        platform: dto.DevicePlatform.android,
        createdAt: testNow,
      );

      final result = await repository.registerDevice();

      expect(result.isOk, isTrue);
      final call = client.calls.single;
      expect(call.method, 'registerDevice');
      expect(call.args['token'], 'token-1');
      expect(call.args['platform'], dto.DevicePlatform.android);
    });

    test('is a no-op, not a failure, when no token is available', () async {
      // The expected state on a platform that cannot deliver push — notably an
      // EU iOS PWA install. Reporting a failure would be misleading.
      tokens.value = null;
      client.handler = (_, _, _) => null;

      final result = await repository.registerDevice();

      expect(result.isOk, isTrue);
      expect(client.calls, isEmpty);
    });

    test('surfaces a server failure', () async {
      client.handler = (_, _, _) => throw dto.ServerpodClientUnauthorized();

      expect(
        (await repository.registerDevice()).failureOrNull,
        const Failure.unauthorized(),
      );
    });
  });

  group('unregisterDevice', () {
    test('sends the token', () async {
      client.handler = (_, _, _) => null;

      await repository.unregisterDevice();

      expect(client.calls.single.method, 'unregisterDevice');
      expect(client.calls.single.args['token'], 'token-1');
    });
  });

  group('setListMuted', () {
    test('sends the list id and the flag', () async {
      client.handler = (_, _, _) => null;

      await repository.setListMuted(ListId(listUuid.uuid), muted: true);

      final call = client.calls.single;
      expect(call.method, 'setListMuted');
      expect(call.args['listId'], listUuid);
      expect(call.args['muted'], isTrue);
    });

    test('translates a non-member rejection', () async {
      client.handler = (_, _, _) => throw dto.NotAMemberException();

      expect(
        (await repository.setListMuted(
          ListId(listUuid.uuid),
          muted: true,
        )).failureOrNull,
        const Failure.unauthorized(),
      );
    });
  });

  group('isListMuted', () {
    test('reads the caller\'s mute state back', () async {
      client.handler = (_, _, _) => true;

      final result = await repository.isListMuted(ListId(listUuid.uuid));

      expect(result, const Ok<bool>(true));
      final call = client.calls.single;
      expect(call.method, 'isListMuted');
      expect(call.args['listId'], listUuid);
    });

    test('translates a non-member rejection', () async {
      client.handler = (_, _, _) => throw dto.NotAMemberException();

      expect(
        (await repository.isListMuted(ListId(listUuid.uuid))).failureOrNull,
        const Failure.unauthorized(),
      );
    });
  });

  group('UnconfiguredPushTokenSource', () {
    test('reports unsupported and yields no token', () async {
      const source = UnconfiguredPushTokenSource(dto.DevicePlatform.ios);
      expect(await source.isSupported(), isFalse);
      expect(await source.token(), isNull);
    });
  });
}
