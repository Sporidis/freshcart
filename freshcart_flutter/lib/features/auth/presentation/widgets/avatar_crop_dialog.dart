import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/avatar_image_cropper.dart';

/// Opens [AvatarCropDialog] for [photo]. Answers like picking a photo
/// does: the cropped avatar, `Ok(null)` if the user cancelled, or an [Err]
/// if cropping failed.
///
/// A full-screen dialog, not a route: it's a step that hands a value back,
/// and the photo's bytes don't belong in a URL.
Future<Result<Uint8List?>> showAvatarCropDialog(
  BuildContext context,
  Uint8List photo,
) async {
  final result = await showDialog<Result<Uint8List?>>(
    context: context,
    builder: (_) => AvatarCropDialog(photo: photo),
  );
  // Closed with the back button or gesture: the same as Cancel.
  return result ?? const Ok(null);
}

/// Lets the user place their photo in the avatar circle: the circle stays
/// put, and they drag and pinch the photo underneath it.
///
/// That's the other way round from the package's default, where the photo
/// stays still and you drag the corners of a box. On a phone, moving the
/// photo itself is what people know from other apps, and it can't produce
/// a crop that isn't square.
class AvatarCropDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for [photo].
  const AvatarCropDialog({required this.photo, super.key});

  /// The picked photo, as encoded bytes (JPEG, PNG, ...).
  final Uint8List photo;

  @override
  ConsumerState<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends ConsumerState<AvatarCropDialog> {
  // Dark, whatever the app theme: a photo is judged best against black,
  // which is also what every photo editor does. So nothing on this screen
  // takes its colour from the theme: those colours are picked for the
  // app's own background, and on black, a button in them looks disabled.
  static const _background = Colors.black;
  static const _foreground = Colors.white;

  final _controller = CropController();

  // "Use photo" waits for the photo to be loaded, and is off while the
  // crop runs, so it can't be pressed twice. Cancel always works, so the
  // user can't get stuck if a photo never loads.
  CropStatus _status = CropStatus.nothing;

  void _close(Result<Uint8List?> result) => Navigator.of(context).pop(result);

  // The two callbacks below can arrive after the dialog has closed: the
  // crop runs in the background and Cancel stays enabled, and the package
  // reports back without checking. Closing then would pop whatever is
  // underneath (the profile sheet), so both ignore a closed dialog.

  void _onStatusChanged(CropStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    _close(switch (result) {
      CropSuccess(:final croppedImage) => Ok(croppedImage),
      CropFailure(:final cause) => Err(Failure.unexpected(cause)),
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final cropping = _status == CropStatus.cropping;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: _foreground,
          // Light status bar icons, or a light app theme would draw dark
          // ones on the black bar.
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(t.profile.cropTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: t.common.cancel,
            onPressed: () => _close(const Ok(null)),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _foreground,
                disabledForegroundColor: _foreground.withValues(alpha: .4),
              ),
              onPressed: _status == CropStatus.ready ? _controller.crop : null,
              child: Text(t.profile.usePhoto),
            ),
          ],
        ),
        body: Stack(
          children: [
            Crop(
              image: widget.photo,
              controller: _controller,
              onCropped: _onCropped,
              onStatusChanged: _onStatusChanged,
              imageCropper: const AvatarImageCropper(),
              // The circle stays put; the photo moves (see the class doc).
              withCircleUi: true,
              interactive: true,
              fixCropRect: true,
              baseColor: _background,
              maskColor: _background.withValues(alpha: .6),
              progressIndicator: const CircularProgressIndicator(
                color: _foreground,
              ),
            ),
            if (cropping)
              const Center(
                child: CircularProgressIndicator(color: _foreground),
              ),
          ],
        ),
      ),
    );
  }
}
