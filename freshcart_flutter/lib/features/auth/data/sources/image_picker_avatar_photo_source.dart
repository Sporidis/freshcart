import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';
import 'package:image_picker/image_picker.dart';

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
        // Smaller than a camera photo (several MB), but still big enough
        // to zoom into: the user crops next, and the crop step shrinks the
        // result to avatar size. Shrinking to 512 here already would make
        // a zoomed-in avatar blurry.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked == null) return const Ok(null);
      return Ok(await picked.readAsBytes());
    } on Object catch (e) {
      return Err(Failure.unexpected(e));
    }
  }
}
