import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('SetAvatarPhoto', () {
    late FakeAuthPort auth;
    late SetAvatarPhoto setAvatarPhoto;

    setUp(() {
      auth = FakeAuthPort();
      setAvatarPhoto = SetAvatarPhoto(auth);
    });

    test('uploads a non-empty photo within the size limit', () async {
      final bytes = Uint8List.fromList(List.filled(1024, 0));

      final result = await setAvatarPhoto(bytes);

      expect(result.isOk, isTrue);
      expect(auth.setAvatarPhotoCalls.single, bytes);
    });

    test('rejects an empty upload', () async {
      final result = await setAvatarPhoto(Uint8List(0));

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setAvatarPhotoCalls, isEmpty);
    });

    test('rejects a photo over the size limit', () async {
      final bytes = Uint8List(AuthUser.maxAvatarPhotoBytes + 1);

      final result = await setAvatarPhoto(bytes);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setAvatarPhotoCalls, isEmpty);
    });

    test('surfaces a port failure unchanged', () async {
      auth.setAvatarPhotoResult = const Err<AuthUser>(Failure.unauthorized());

      final result = await setAvatarPhoto(Uint8List.fromList([1, 2, 3]));

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}
