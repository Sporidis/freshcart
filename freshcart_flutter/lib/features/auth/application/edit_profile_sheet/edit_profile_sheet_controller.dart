import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_sheet/edit_profile_sheet_state.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_profile_sheet_controller.g.dart';

/// The controller for `EditProfileSheet`: the profile to show, and all
/// the changes the sheet can make.
///
/// It exists mainly for [choosePhoto], which has three steps (pick, crop,
/// then upload). Saving flags and errors stay in the sheet itself, see
/// [EditProfileSheetState] for why.
@riverpod
class EditProfileSheetController extends _$EditProfileSheetController {
  @override
  EditProfileSheetState build() {
    final profile = ref.watch(profileControllerProvider);
    return EditProfileSheetState(
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

  /// Lets the user pick a gallery photo, place it in the avatar circle
  /// with [crop], and uploads the result as their avatar.
  ///
  /// [crop] is the crop screen, passed in by the sheet: screens stay in
  /// the widget, but the steps and their order live here. It answers like
  /// picking does: the cropped bytes, `Ok(null)` if the user cancelled, or
  /// an [Err].
  ///
  /// Returns null when it worked, and also when the user cancelled either
  /// step. Cancelling isn't an error, so nothing is shown.
  Future<Failure?> choosePhoto({
    required Future<Result<Uint8List?>> Function(Uint8List photo) crop,
  }) async {
    final Uint8List photo;
    switch (await ref.read(avatarPhotoSourceProvider).pick()) {
      case Err(:final failure):
        return failure;
      case Ok(value: null):
        return null; // cancelled -- not an error
      case Ok(value: final bytes?):
        photo = bytes;
    }
    return switch (await crop(photo)) {
      Err(:final failure) => failure,
      Ok(value: null) => null, // cancelled -- not an error
      Ok(value: final bytes?) => await _profile.setAvatarPhoto(bytes),
    };
  }
}
