import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_screen/edit_profile_screen_state.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_profile_screen_controller.g.dart';

/// The controller for `EditProfileSheet`: the profile to show, and all
/// the changes the sheet can make.
///
/// It exists mainly for [choosePhoto], which has two steps (pick, then
/// upload). Saving flags and errors stay in the sheet itself, see
/// [EditProfileScreenState] for why.
@riverpod
class EditProfileScreenController extends _$EditProfileScreenController {
  @override
  EditProfileScreenState build() {
    final profile = ref.watch(profileControllerProvider);
    return EditProfileScreenState(
      user: profile.dataOrNull,
      loadFailure: profile.loadFailure,
    );
  }

  /// Read again every time, instead of stored in a field. A stored notifier
  /// could be disposed while we still hold it.
  ProfileController get _profile =>
      ref.read(profileControllerProvider.notifier);

  Future<Failure?> setDisplayName(String name) => _profile.setDisplayName(name);

  Future<Failure?> setAvatarColor(HexColor color) =>
      _profile.setAvatarColor(color);

  Future<Failure?> removePhoto() => _profile.clearAvatarPhoto();

  /// Lets the user pick a gallery photo and uploads it as their avatar.
  ///
  /// Returns null when it worked, and also when the user cancelled.
  /// Cancelling isn't an error, so nothing is shown.
  Future<Failure?> choosePhoto() async {
    final result = await ref.read(avatarPhotoSourceProvider).pick();
    return switch (result) {
      Err(:final failure) => failure,
      Ok(value: null) => null, // cancelled -- not an error
      Ok(value: final bytes?) => await _profile.setAvatarPhoto(bytes),
    };
  }
}
