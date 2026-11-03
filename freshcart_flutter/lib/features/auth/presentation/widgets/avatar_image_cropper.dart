import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

/// The crop step of `AvatarCropDialog`: cuts out the square the user
/// placed in the circle, shrinks it to [size] and saves it as a JPEG, in
/// one pass.
///
/// Why not the package's default cropper: it never resizes, so a zoomed-in
/// crop of a large photo could stay over 1000px wide, and over the 1 MB
/// avatar limit (`AuthUser.maxAvatarPhotoBytes`). It also keeps the
/// input's format, while an avatar is always best as a JPEG.
///
/// Square, not circle: every photo is shown through a `CircleAvatar`,
/// which clips it round anyway. A circle crop would be a PNG with
/// transparent corners, bigger for nothing.
///
/// The `Crop` widget runs this in a background isolate (`compute`), so the
/// heavy image work never freezes the screen.
class AvatarImageCropper extends ImageCropper<img.Image> {
  /// Creates the cropper.
  const AvatarImageCropper();

  /// The width and height of the saved avatar, in pixels. Twice the
  /// biggest avatar on screen (76px) at 3x pixel density, rounded up.
  static const int size = 512;

  /// JPEG quality: no visible loss at avatar size, a fraction of the bytes.
  static const int quality = 85;

  @override
  RectValidator<img.Image> get rectValidator => defaultRectValidator;

  @override
  RectCropper<img.Image> get rectCropper => _cropShrinkAndEncode;

  @override
  CircleCropper<img.Image> get circleCropper => _noCircleCrop;
}

Uint8List _cropShrinkAndEncode(
  img.Image original, {
  required Offset topLeft,
  required Size size,
  required ImageFormat? outputFormat,
}) {
  final square = img.copyCrop(
    original,
    x: topLeft.dx.toInt(),
    y: topLeft.dy.toInt(),
    width: size.width.toInt(),
    height: size.height.toInt(),
  );
  // Only ever shrink: blowing up a small photo adds bytes, not detail.
  // Rounding to whole pixels can leave the crop a pixel off square, so
  // both sides are checked.
  final side = math.min(
    math.min(square.width, square.height),
    AvatarImageCropper.size,
  );
  final resized = square.width == side && square.height == side
      ? square
      : img.copyResize(
          square,
          width: side,
          height: side,
          interpolation: img.Interpolation.average,
        );
  return img.encodeJpg(resized, quality: AvatarImageCropper.quality);
}

/// The avatar is always cropped square (see [AvatarImageCropper]), so
/// asking for a circle is a programming mistake, not a user error.
Uint8List _noCircleCrop(
  img.Image original, {
  required Offset center,
  required double radius,
  required ImageFormat? outputFormat,
}) => throw UnsupportedError('Avatars are cropped square: call crop().');
