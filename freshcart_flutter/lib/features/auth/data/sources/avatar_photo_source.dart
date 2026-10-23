import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/sources/image_picker_avatar_photo_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'avatar_photo_source.g.dart';

/// Lets the user pick a photo for their avatar, and returns its bytes.
///
/// Only picking happens here. Uploading is done by `ProfileController`.
/// Tests replace this with a fake, so they don't need a real photo gallery.
abstract interface class AvatarPhotoSource {
  /// The photo's bytes. `Ok(null)` if the user cancelled. [Err] if picking
  /// failed.
  Future<Result<Uint8List?>> pick();
}

/// Supplies the [AvatarPhotoSource]. Tests override it with a fake.
@riverpod
AvatarPhotoSource avatarPhotoSource(Ref ref) =>
    const ImagePickerAvatarPhotoSource();
