import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_screen/edit_profile_screen_state.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_profile_screen_controller.g.dart';

/// The view model behind `EditProfileScreen`: the profile it shows, and
/// every change the screen can make to it.
///
/// Earns its place through [choosePhoto], the one multi-step action (pick,
/// then upload). The screen keeps its own saving flags and errors -- see
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

  /// Fetched fresh on every use, since holding on to a notifier instance
  /// could outlive it.
  ProfileController get _profile =>
      ref.read(profileControllerProvider.notifier);

  Future<Failure?> setDisplayName(String name) => _profile.setDisplayName(name);

  Future<Failure?> setAvatarColor(HexColor color) =>
      _profile.setAvatarColor(color);

  Future<Failure?> removePhoto() => _profile.clearAvatarPhoto();

  /// Lets the user pick a gallery photo and uploads it as their avatar.
  ///
  /// Returns null on success *and* when the user cancels the picker --
  /// cancelling is not an error, so the screen shows nothing for it.
  Future<Failure?> choosePhoto() async {
    final result = await ref.read(avatarPhotoSourceProvider).pick();
    return switch (result) {
      Err(:final failure) => failure,
      Ok(value: null) => null, // cancelled -- not an error
      Ok(value: final bytes?) => await _profile.setAvatarPhoto(bytes),
    };
  }
}
