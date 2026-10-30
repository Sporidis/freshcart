import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:image/image.dart' as img;

/// Turns an uploaded avatar photo into a clean JPEG: only its pixels, none
/// of its metadata.
///
/// Avatar photos are served publicly, and a phone photo's EXIF data often
/// says where it was taken (GPS) and on which device. The app shrinks the
/// photo first, but the server can't rely on that: any client can send the
/// original file. Re-encoding here also means only real images are stored,
/// never arbitrary bytes under a `.jpg` name.
abstract final class AvatarPhotoSanitizer {
  /// The longest side of a stored avatar, in pixels. Matches what the app
  /// sends (`maxWidth: 512`), so a well-behaved upload isn't resized again.
  static const int maxSide = 512;

  /// The most pixels an upload may claim before it is decoded. Checked on
  /// the header alone, so a small file claiming a huge image (a
  /// "decompression bomb") can't make the server allocate gigabytes.
  static const int maxPixels = 40 * 1000 * 1000;

  /// JPEG quality of the stored avatar (the app uses the same).
  static const int quality = 85;

  /// [upload] as a fresh JPEG, upright, at most [maxSide] on its longest
  /// side, with no EXIF data and no colour profile.
  ///
  /// Throws a [ValidationException] (invalid format, avatar photo) when
  /// [upload] isn't an image this server can read, or claims to be too
  /// large to decode safely.
  static Uint8List sanitize(Uint8List upload) {
    final decoded = _decode(upload);
    if (decoded == null) throw _invalid();

    // Upright first: phones often store a portrait photo sideways plus an
    // EXIF "rotate" flag. This turns the pixels and needs that flag, so it
    // must happen before the EXIF is emptied. Returns a new image.
    var image = img.bakeOrientation(decoded);

    // Shrink only when needed, along the longer side, so the proportions
    // stay and a small photo isn't blown up. Also returns a new image.
    if (image.width > maxSide || image.height > maxSide) {
      image = image.width >= image.height
          ? img.copyResize(
              image,
              width: maxSide,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              image,
              height: maxSide,
              interpolation: img.Interpolation.average,
            );
    }

    // On the image that is encoded: the encoder writes whatever is still
    // here (GPS, device, software in EXIF; device details in the profile).
    image
      ..exif = img.ExifData()
      ..iccProfile = null;
    return img.encodeJpg(image, quality: quality);
  }

  /// [upload] decoded, or null if it isn't an image we read safely.
  ///
  /// The size is checked on the header before decoding. Decoders also
  /// throw their own errors on corrupt or hostile files (bad headers,
  /// truncated data, their own size limit), and any of those means the same
  /// thing here: not a usable photo. Without catching them, such an upload
  /// would surface as a server error instead of a validation failure.
  static img.Image? _decode(Uint8List upload) {
    try {
      final decoder = img.findDecoderForData(upload);
      final info = decoder?.startDecode(upload);
      if (decoder == null || info == null) return null;
      if (info.width * info.height > maxPixels) return null;
      return decoder.decode(upload);
      // Deliberately broad: a decoder fed hostile bytes can throw more than
      // ImageException (RangeError on a short buffer, for one).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// The same error the app's own check would give for a bad photo.
  static ValidationException _invalid() {
    const issue = domain.ValidationIssue.invalidFormat(
      domain.ValidatedInput.avatarPhoto,
    );
    return ValidationException(kind: issue.kind, input: issue.input.name);
  }
}
