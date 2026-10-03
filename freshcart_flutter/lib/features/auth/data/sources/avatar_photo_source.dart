import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:image_picker/image_picker.dart';
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

/// The real [AvatarPhotoSource], using the `image_picker` package.
class ImagePickerAvatarPhotoSource implements AvatarPhotoSource {
  /// Creates the source.
  const ImagePickerAvatarPhotoSource();

  @override
  Future<Result<Uint8List?>> pick() async {
    // Picking can throw (no permission, or not supported on this
    // platform). We turn that into a Failure here, so callers don't need a
    // try/catch.
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Make the photo smaller. Camera photos can be several MB, way too
        // big for an avatar. The server also has a size limit, but that's
        // just a safety net.
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return const Ok(null);
      return Ok(await picked.readAsBytes());
    } on Object catch (e) {
      return Err(Failure.unexpected(e));
    }
  }
}

/// Supplies the [AvatarPhotoSource]. Tests override it with a fake.
@riverpod
AvatarPhotoSource avatarPhotoSource(Ref ref) =>
    const ImagePickerAvatarPhotoSource();
