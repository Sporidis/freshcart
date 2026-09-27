// Not a test: a one-off generator, run manually with
// `flutter test tool/generate_basket_assets.dart` whenever the basket mark's
// design changes. Kept out of test/ so the normal `flutter test` run never
// sweeps it up.
//
// Rasterizes BasketMark -- the app's own CustomPainter, the single source of
// truth for the mark's shape -- into the PNGs flutter_native_splash and
// flutter_launcher_icons need. Neither tool can consume a CustomPainter
// directly; both want real image files.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';

void main() {
  testWidgets('generate basket icon/splash assets', (tester) async {
    await tester.runAsync(() async {
      // basket_ink.png: splash's light-mode overlay and the Android
      // adaptive-icon foreground -- both transparent, ink-coloured.
      await _capture(
        tester,
        canvasSize: 1152,
        outputPath: 'assets/icon/basket_ink.png',
        content: const BasketMark(size: 900, color: AppColors.ink),
      );

      // basket_light.png: splash's dark-mode overlay and the iOS dark-icon
      // variant -- Apple's own guidance is that the dark variant stays
      // transparent, so this is reused as-is for both.
      await _capture(
        tester,
        canvasSize: 1152,
        outputPath: 'assets/icon/basket_light.png',
        content: const BasketMark(size: 900, color: AppColors.bgLight),
      );

      // app_icon_flat.png: the flattened, opaque icon Android's legacy
      // launcher and iOS's default/light icon both need -- app stores
      // reject/flatten alpha on the primary icon, so this one is
      // pre-composited rather than left transparent.
      await _capture(
        tester,
        canvasSize: 1024,
        outputPath: 'assets/icon/app_icon_flat.png',
        content: const ColoredBox(
          color: AppColors.bgLight,
          child: Center(child: BasketMark(size: 760, color: AppColors.ink)),
        ),
        opaque: true,
      );
    });
  });
}

Future<void> _capture(
  WidgetTester tester, {
  required double canvasSize,
  required String outputPath,
  required Widget content,
  bool opaque = false,
}) async {
  final size = Size(canvasSize, canvasSize);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: canvasSize,
          height: canvasSize,
          child: opaque ? content : Center(child: content),
        ),
      ),
    ),
  );

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(outputPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('Wrote $outputPath (${size.width.toInt()}x${size.height.toInt()})');
}
