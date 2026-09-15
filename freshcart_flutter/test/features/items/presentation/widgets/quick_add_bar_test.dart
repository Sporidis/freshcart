import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

void main() {
  setUpAll(configurePluralResolvers);

  final t = translationsFor(AppLocale.en);
  final listId = ListId('00000000-0000-4000-8000-000000000001');

  Future<void> pump(
    WidgetTester tester, {
    required bool firstRun,
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: QuickAddBar(
                  listId: listId,
                  t: t,
                  firstRun: firstRun,
                  onQuickAdd: (_) async => false,
                  onOpenDetails: (_) async => false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double pulseScale(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(QuickAddBar.pulseKey))
      .transform
      .getMaxScaleOnAxis();

  group('QuickAddBar first-run pulse (§11)', () {
    testWidgets('firstRun: false never scales the resting button', (
      tester,
    ) async {
      await pump(tester, firstRun: false);
      expect(pulseScale(tester), 1.0);

      await tester.pump(const Duration(milliseconds: 500));
      expect(pulseScale(tester), 1.0);
    });

    testWidgets('firstRun: true pulses past 1.0, then settles back', (
      tester,
    ) async {
      await pump(tester, firstRun: true);
      expect(pulseScale(tester), 1.0);

      // Midway through the first beat's rise.
      await tester.pump(const Duration(milliseconds: 225));
      expect(pulseScale(tester), greaterThan(1.0));

      // Three beats (900ms apart, per the spec) later, it has stopped for
      // good, back at rest.
      await tester.pumpAndSettle();
      expect(pulseScale(tester), 1.0);
    });

    testWidgets('reduced motion drops the pulse entirely', (tester) async {
      await pump(tester, firstRun: true, reducedMotion: true);

      await tester.pump(const Duration(milliseconds: 225));
      expect(
        pulseScale(tester),
        1.0,
        reason:
            'the controller may still run underneath, but nothing '
            'visible should move while motion is reduced',
      );

      await tester.pumpAndSettle();
    });
  });
}
