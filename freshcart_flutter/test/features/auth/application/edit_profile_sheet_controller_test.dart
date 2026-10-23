import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_sheet/edit_profile_sheet_controller.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';

import '../../../fakes/fake_auth_repository.dart';

/// Answers every [pick] with a fixed [result] -- standing in for the
/// gallery, which a unit test cannot open.
class _FakePhotoSource implements AvatarPhotoSource {
  _FakePhotoSource(this.result);

  final Result<Uint8List?> result;
  int picks = 0;

  @override
  Future<Result<Uint8List?>> pick() async {
    picks++;
    return result;
  }
}

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.dispose());

  /// A container whose photo source answers with [picked], with the
  /// profile already loaded and the (auto-dispose) VM kept alive.
  Future<EditProfileSheetController> vmPicking(
    Result<Uint8List?> picked,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        avatarPhotoSourceProvider.overrideWithValue(_FakePhotoSource(picked)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      editProfileSheetControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    await container.read(profileControllerProvider.future);
    return container.read(editProfileSheetControllerProvider.notifier);
  }

  group('choosePhoto', () {
    test('uploads the picked bytes and reports success', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final vm = await vmPicking(Ok(bytes));

      expect(await vm.choosePhoto(), isNull);
      expect(auth.setAvatarPhotoCalls, [bytes]);
    });

    test('a cancelled pick is not an error and uploads nothing', () async {
      final vm = await vmPicking(const Ok(null));

      expect(await vm.choosePhoto(), isNull);
      expect(auth.setAvatarPhotoCalls, isEmpty);
    });

    test('a failed pick returns its failure and uploads nothing', () async {
      final vm = await vmPicking(const Err(Failure.unexpected()));

      expect(await vm.choosePhoto(), isA<UnexpectedFailure>());
      expect(auth.setAvatarPhotoCalls, isEmpty);
    });

    test("a photo the domain rejects returns the upload's failure", () async {
      // Empty bytes pass the picker but fail AuthUser.validateAvatarPhoto,
      // so this is the upload step's failure, not the pick's.
      final vm = await vmPicking(Ok(Uint8List(0)));

      expect(await vm.choosePhoto(), isA<ValidationFailure>());
      expect(auth.setAvatarPhotoCalls, isEmpty);
    });
  });

  test('the state follows the profile once it loads', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      editProfileSheetControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);

    await container.read(profileControllerProvider.future);

    final s = container.read(editProfileSheetControllerProvider);
    expect(s.user?.displayName, 'Nikolaos');
    expect(s.loadFailure, isNull);
  });
}
