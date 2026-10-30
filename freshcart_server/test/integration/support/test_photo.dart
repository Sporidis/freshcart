import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A tiny real JPEG, for uploads: the server only stores photos it can
/// decode (`AvatarPhotoSanitizer`), so made-up bytes are refused.
ByteData aPhoto() => ByteData.sublistView(
  img.encodeJpg(img.Image(width: 8, height: 8)),
);
