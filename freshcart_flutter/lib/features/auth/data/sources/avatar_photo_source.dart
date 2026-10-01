import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'avatar_photo_source.g.dart';

/// Supplies the bytes of a photo the user picks for their avatar.
///
/// Split out the same way as `PushTokenSource`: the only thing the platform
/// plugin is responsible for is producing bytes. Uploading them is ordinary
/// server traffic through `ProfileController`, and tests swap this source for
/// a fake instead of needing a real gallery.
abstract interface class AvatarPhotoSource {
  /// The picked photo's bytes, `Ok(null)` if the user cancelled, or an
  /// [Err] if the platform could not pick or read it at all.
  Future<Result<Uint8List?>> pick();
}

/// The [AvatarPhotoSource] backed by `image_picker`'s gallery picker.
class ImagePickerAvatarPhotoSource implements AvatarPhotoSource {
  /// Creates the source.
  const ImagePickerAvatarPhotoSource();

  @override
  Future<Result<Uint8List?>> pick() async {
    // Picking and reading can throw a platform exception (denied file
    // access, or no image_picker implementation on this platform) rather
    // than return normally -- turned into a Failure here so nothing above
    // this class needs a try/catch.
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Downsized on pick: a raw camera photo can run to several MB, far
        // more than an avatar needs -- the server's own size cap
        // (`ProfileService.maxAvatarPhotoBytes`) is a backstop for a client
        // that skipped this, not the size a normal upload is meant to reach.
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

/// The app's [AvatarPhotoSource]; overridden with a fake in tests.
@riverpod
AvatarPhotoSource avatarPhotoSource(Ref ref) =>
    const ImagePickerAvatarPhotoSource();
