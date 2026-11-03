import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/avatar_image_cropper.dart';
import 'package:image/image.dart' as img;

void main() {
  const cropper = AvatarImageCropper();

  /// A [width] x [height] photo: left half red, right half blue, so a
  /// test can tell which part of it was cut out.
  img.Image photo(int width, int height) {
    final image = img.Image(width: width, height: height);
    for (final pixel in image) {
      final isLeft = pixel.x < width / 2;
      pixel
        ..r = isLeft ? 255 : 0
        ..g = 0
        ..b = isLeft ? 0 : 255;
    }
    return image;
  }

  Future<img.Image> crop(
    img.Image original,
    Offset topLeft,
    Offset bottomRight,
  ) async {
    final bytes = await cropper(
      original: original,
      topLeft: topLeft,
      bottomRight: bottomRight,
      outputFormat: ImageFormat.png,
    );
    // Always a JPEG, whatever format the photo came in.
    expect(img.JpegDecoder().isValidFile(bytes), isTrue);
    expect(bytes.length, lessThan(AuthUser.maxAvatarPhotoBytes));
    return img.decodeJpg(bytes)!;
  }

  test('a large crop is shrunk to the avatar size', () async {
    final result = await crop(
      photo(1600, 1200),
      const Offset(200, 100),
      const Offset(1200, 1100),
    );

    expect(result.width, AvatarImageCropper.size);
    expect(result.height, AvatarImageCropper.size);
  });

  test('a crop smaller than the avatar size is never blown up', () async {
    final result = await crop(
      photo(400, 400),
      const Offset(100, 100),
      const Offset(300, 300),
    );

    expect(result.width, 200);
    expect(result.height, 200);
  });

  test('a crop a pixel off square still comes out square', () async {
    // Rounding the circle's position to whole pixels can do this.
    final result = await crop(
      photo(400, 400),
      Offset.zero,
      const Offset(300, 301),
    );

    expect(result.width, 300);
    expect(result.height, 300);
  });

  test('it keeps the part the user placed in the circle', () async {
    // Only the red left half of the photo.
    final result = await crop(
      photo(1000, 500),
      Offset.zero,
      const Offset(500, 500),
    );

    final middle = result.getPixel(result.width ~/ 2, result.height ~/ 2);
    expect(middle.r, greaterThan(200));
    expect(middle.b, lessThan(50));
  });

  test('a circle crop is a programming mistake', () {
    expect(
      () => cropper.circleCropper(
        photo(100, 100),
        center: const Offset(50, 50),
        radius: 50,
        outputFormat: null,
      ),
      throwsUnsupportedError,
    );
  });
}
