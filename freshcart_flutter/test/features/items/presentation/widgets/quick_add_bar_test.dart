import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/shop_theme_reveal.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Owns the [AnimationController] a [RevealWaveScope] under test needs, and
/// rebuilds it whenever [geometry] changes -- mirrors
/// `test/core/theme/wave_themed_test.dart`'s own harness.
class _WaveHarness extends StatefulWidget {
  const _WaveHarness({
    required this.geometry,
    required this.onController,
    required this.child,
  });

  final ValueListenable<RevealWaveGeometry?> geometry;
  final ValueChanged<AnimationController> onController;
  final Widget child;

  @override
  State<_WaveHarness> createState() => _WaveHarnessState();
}

class _WaveHarnessState extends State<_WaveHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    widget.onController(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RevealWaveGeometry?>(
      valueListenable: widget.geometry,
      builder: (context, geometry, _) => RevealWaveScope(
        geometry: geometry,
        controller: controller,
        curve: Curves.linear,
        child: widget.child,
      ),
    );
  }
}

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

  group(
    'WaveThemed gating (decisions #89, local reveal per user feedback)',
    () {
      testWidgets(
        'the resting pill layers the old seed under the new one -- a real '
        'local reveal, not a single flip the instant the ambient theme '
        'changes -- and collapses back to one layer once the wave ends',
        (tester) async {
          late AnimationController controller;
          final geometry = ValueNotifier<RevealWaveGeometry?>(null);
          addTearDown(geometry.dispose);
          const oldSeed = Colors.red;
          const newSeed = Colors.blue;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                // The ambient theme is already the *new* seed throughout --
                // exactly what a real ShopThemeReveal does the instant the
                // shop filter changes. Only WaveThemed's own gating should
                // be holding any of the pill back from it.
                theme: AppTheme.light(newSeed),
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomRight,
                    child: _WaveHarness(
                      geometry: geometry,
                      onController: (c) => controller = c,
                      child: QuickAddBar(
                        listId: listId,
                        t: t,
                        onQuickAdd: (_) async => false,
                        onOpenDetails: (_) async => false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          // .toARGB32(), not the Color object itself: the pill's fill goes
          // through Color.lerp (even at t=0, to plainly land back on the
          // input), which returns a plain Color rather than preserving
          // `Colors.blue`/`Colors.red`'s own MaterialColor subtype -- same
          // pixel value, different runtime type, so `==` alone would fail on
          // a distinction that isn't visually real.
          List<int> pillColors() => tester
              .widgetList<Material>(
                find.byKey(const ValueKey('quick-add-pill')),
              )
              .map((m) => m.color!.toARGB32())
              .toList();

          final newPrimary = AppTheme.light(
            newSeed,
          ).colorScheme.primary.toARGB32();
          final oldPrimary = AppTheme.light(
            oldSeed,
          ).colorScheme.primary.toARGB32();

          // No wave at all yet: a single copy, the ambient (already-new)
          // theme applies, same as any ordinary, unwrapped widget.
          expect(pillColors(), [newPrimary]);

          // A wave starts, anchored far from the FAB -- e.g. a tap on the
          // shop filter bar at the top of the screen.
          final pillCenter = tester.getCenter(
            find.byKey(const ValueKey('quick-add-pill')).first,
          );
          final origin = pillCenter.translate(-500, -500);
          geometry.value = RevealWaveGeometry(
            globalOrigin: origin,
            maxRadius: (pillCenter - origin).distance,
            oldSeed: oldSeed,
            newSeed: newSeed,
          );
          await tester.pump();

          // Wave just started (radius ~0, nowhere near the FAB yet): both
          // layers now exist -- the old seed underneath, wherever the wave
          // hasn't swept yet, and the new seed on top, clipped to the wave's
          // still-tiny circle. Whether that clip actually reaches any given
          // pixel is `_CircleClipper`'s own geometry (plain `Path.addOval`,
          // the same shape `ShopThemeReveal`'s own punch-hole mask uses, not
          // re-verified here -- see decisions #85's own note on that math
          // having no widget-tree assertion surface). What this asserts is
          // the wiring: this is a real two-layer reveal, not a single flip.
          expect(pillColors()..sort(), [oldPrimary, newPrimary]..sort());

          // Comfortably past the FAB's own distance from the origin -- still
          // layered (the old seed stays live underneath for as long as the
          // wave itself is in flight), the point of `_CircleClipper` is that
          // its clip now geometrically covers the pill's own position.
          controller.value = 1.5;
          await tester.pump();
          expect(pillColors()..sort(), [oldPrimary, newPrimary]..sort());

          // The wave itself has finished (mirrors ShopThemeReveal's own
          // `_onRevealStatusChanged` clearing its geometry once the reveal
          // completes): back to a single copy, the ambient theme.
          geometry.value = null;
          await tester.pump();
          expect(pillColors(), [newPrimary]);
        },
      );
    },
  );
}
