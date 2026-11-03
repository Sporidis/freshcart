import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/avatar_crop_dialog.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(configurePluralResolvers);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A real, decodable 800x600 photo.
  final photo = img.encodePng(img.Image(width: 800, height: 600));

  /// Opens the dialog the way the sheet does. The returned list gets what
  /// [showAvatarCropDialog] answered, once the dialog closes.
  Future<List<Result<Uint8List?>>> open(WidgetTester tester) async {
    final results = <Result<Uint8List?>>[];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    results.add(await showAvatarCropDialog(context, photo)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    return results;
  }

  /// The package decodes and crops in a real background isolate, which
  /// the test's fake clock doesn't wait for: give it real time.
  Future<void> letTheIsolateWork(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
  }

  TextButton usePhotoButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(TextButton, 'Use photo'));

  testWidgets('the close button cancels: nothing is cropped', (tester) async {
    final results = await open(tester);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(results.single.valueOrNull, isNull);
    expect(results.single.isOk, isTrue);
  });

  testWidgets('closing with the back button is a cancel too', (tester) async {
    final results = await open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(results.single.isOk, isTrue);
    expect(results.single.valueOrNull, isNull);
  });

  testWidgets('"Use photo" waits until the photo has loaded', (tester) async {
    await open(tester);
    expect(usePhotoButton(tester).onPressed, isNull);

    await letTheIsolateWork(tester);

    expect(usePhotoButton(tester).onPressed, isNotNull);
  });

  testWidgets('cancelling while the crop runs stays a cancel', (tester) async {
    final results = await open(tester);
    await letTheIsolateWork(tester);

    await tester.tap(find.text('Use photo'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    // The crop finishes after the dialog has gone. That must not close
    // anything else, or touch the dialog's dead state.
    await letTheIsolateWork(tester);
    await tester.pumpAndSettle();

    expect(results.single.isOk, isTrue);
    expect(results.single.valueOrNull, isNull);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('"Use photo" answers with a square JPEG avatar', (tester) async {
    final results = await open(tester);
    await letTheIsolateWork(tester);

    await tester.tap(find.text('Use photo'));
    await letTheIsolateWork(tester);
    await tester.pumpAndSettle();

    final cropped = results.single.valueOrNull!;
    expect(img.JpegDecoder().isValidFile(cropped), isTrue);
    final decoded = img.decodeJpg(cropped)!;
    expect(decoded.width, decoded.height);
  });
}
