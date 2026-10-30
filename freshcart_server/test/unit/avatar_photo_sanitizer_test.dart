import 'dart:typed_data';

import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/profile/business/avatar_photo_sanitizer.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// A JPEG the way a phone saves one: with where it was taken, which
/// device took it, and (optionally) a "rotate" flag instead of turned
/// pixels.
Uint8List phonePhoto({int width = 800, int height = 600, int? orientation}) {
  final photo = img.Image(width: width, height: height)
    ..exif.imageIfd.make = 'PhoneMaker'
    ..exif.imageIfd.software = 'PhoneOS 1.0'
    ..exif.imageIfd.orientation = orientation
    ..exif.gpsIfd.gpsLatitude = 51.2093
    ..exif.gpsIfd.gpsLongitude = 3.2247;
  return img.encodeJpg(photo);
}

/// Whether [bytes] still carry an EXIF block anywhere.
bool hasExif(Uint8List bytes) {
  const signature = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // "Exif\0\0"
  outer:
  for (var i = 0; i + signature.length <= bytes.length; i++) {
    for (var j = 0; j < signature.length; j++) {
      if (bytes[i + j] != signature[j]) continue outer;
    }
    return true;
  }
  return false;
}

void main() {
  group('AvatarPhotoSanitizer', () {
    test('the test photo really carries GPS and device data', () {
      // Guards the tests below: they'd pass trivially on a clean photo.
      final upload = phonePhoto();
      expect(hasExif(upload), isTrue);
      expect(img.decodeJpg(upload)!.exif.gpsIfd.gpsLatitude, isNotNull);
    });

    test('no EXIF at all leaves the server: no GPS, no device', () {
      final stored = AvatarPhotoSanitizer.sanitize(phonePhoto());

      expect(hasExif(stored), isFalse);
      final read = img.decodeJpg(stored)!;
      expect(read.exif.gpsIfd.gpsLatitude, isNull);
      expect(read.exif.imageIfd.make, isNull);
      expect(read.iccProfile, isNull);
    });

    test('a photo stored sideways comes out upright', () {
      // 6 = "turn 90° clockwise to show": stored 800 wide, shown 600 wide.
      final stored = AvatarPhotoSanitizer.sanitize(
        phonePhoto(width: 400, height: 300, orientation: 6),
      );

      final read = img.decodeJpg(stored)!;
      expect((read.width, read.height), (300, 400));
      expect(read.exif.imageIfd.orientation, isNull);
    });

    test('a big photo shrinks to the limit, keeping its shape', () {
      final wide = img.decodeJpg(
        AvatarPhotoSanitizer.sanitize(phonePhoto(width: 2000, height: 1000)),
      )!;
      final tall = img.decodeJpg(
        AvatarPhotoSanitizer.sanitize(phonePhoto(width: 1000, height: 2000)),
      )!;

      expect((wide.width, wide.height), (512, 256));
      expect((tall.width, tall.height), (256, 512));
    });

    test('a small photo keeps its size', () {
      final read = img.decodeJpg(
        AvatarPhotoSanitizer.sanitize(phonePhoto(width: 200, height: 100)),
      )!;

      expect((read.width, read.height), (200, 100));
    });

    test('bytes that are no image are refused', () {
      expect(
        () => AvatarPhotoSanitizer.sanitize(
          Uint8List.fromList('<html>not a photo</html>'.codeUnits),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a file claiming a huge image is refused before decoding', () {
      // A real 1×1 PNG whose header then claims 20000×20000 pixels.
      final png = img.encodePng(img.Image(width: 1, height: 1));
      final header = ByteData.sublistView(png);
      header
        ..setUint32(16, 20000) // IHDR width
        ..setUint32(20, 20000); // IHDR height

      expect(
        () => AvatarPhotoSanitizer.sanitize(png),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
