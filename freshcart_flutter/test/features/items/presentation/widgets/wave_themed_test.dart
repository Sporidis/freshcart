import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_geometry.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_scope.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/wave_themed.dart';

/// A minimal harness: owns the [AnimationController] a [RevealWaveScope]
/// under test needs, hands it back via [onController] so a test can drive
/// its value directly (without going through a real [ShopThemeReveal]), and
/// rebuilds the scope whenever [geometry] changes.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.geometry,
    required this.onController,
    required this.child,
  });

  final ValueListenable<RevealWaveGeometry?> geometry;
  final ValueChanged<AnimationController> onController;
  final Widget child;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness>
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

/// Renders the ambient theme's primary colour, so a test can tell which
/// seed a given probe is currently under.
class _Probe extends StatelessWidget {
  const _Probe({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    color: Theme.of(context).colorScheme.primary,
  );
}

void main() {
  const oldSeed = Colors.red;
  const newSeed = Colors.blue;
  final oldPrimary = AppTheme.light(oldSeed).colorScheme.primary;
  final newPrimary = AppTheme.light(newSeed).colorScheme.primary;

  Color primaryOf(WidgetTester tester, String key) =>
      Theme.of(tester.element(find.byKey(Key(key)))).colorScheme.primary;

  testWidgets(
    'a probe only switches to the new seed once the wave geometrically '
    'reaches it -- not the instant the wave exists',
    (tester) async {
      late AnimationController controller;
      final geometry = ValueNotifier<RevealWaveGeometry?>(null);
      addTearDown(geometry.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: _Harness(
            geometry: geometry,
            onController: (c) => controller = c,
            child: const Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: WaveThemed(child: _Probe(key: Key('near'))),
                ),
                Positioned(
                  left: 300,
                  top: 0,
                  child: WaveThemed(child: _Probe(key: Key('far'))),
                ),
              ],
            ),
          ),
        ),
      );

      // Positions measured from the real render tree, not hand-computed --
      // the origin is exactly the near probe's own centre, so its distance
      // from the wave is always zero; maxRadius is exactly the distance to
      // the far probe, so it's only covered once the wave has travelled the
      // whole way there.
      final origin = tester.getCenter(find.byKey(const Key('near')));
      final farCenter = tester.getCenter(find.byKey(const Key('far')));
      final maxRadius = (farCenter - origin).distance;

      geometry.value = RevealWaveGeometry(
        globalOrigin: origin,
        maxRadius: maxRadius,
        oldSeed: oldSeed,
        newSeed: newSeed,
      );
      await tester.pump();

      // The wave technically exists now (radius 0) but hasn't travelled
      // anywhere yet -- the near probe sits exactly at its origin, so it's
      // covered from the very first instant; the far one, a full maxRadius
      // away, is not.
      expect(primaryOf(tester, 'near'), newPrimary);
      expect(primaryOf(tester, 'far'), oldPrimary);

      // Halfway there: still short of the far probe.
      controller.value = 0.5;
      await tester.pump();
      expect(primaryOf(tester, 'near'), newPrimary);
      expect(primaryOf(tester, 'far'), oldPrimary);

      // Comfortably past the far probe's own distance.
      controller.value = 1.5;
      await tester.pump();
      expect(primaryOf(tester, 'near'), newPrimary);
      expect(primaryOf(tester, 'far'), newPrimary);

      // No wave in flight at all: renders whatever the ambient theme
      // already is, with no crash and no leftover override.
      geometry.value = null;
      await tester.pump();
      expect(find.byKey(const Key('near')), findsOneWidget);
      expect(find.byKey(const Key('far')), findsOneWidget);
    },
  );

  testWidgets(
    'bounce fires the instant a wave starts, even for a probe the wave '
    'never actually reaches -- it reacts to the tap, not to its own '
    'colour arriving',
    (tester) async {
      late AnimationController controller;
      final geometry = ValueNotifier<RevealWaveGeometry?>(null);
      addTearDown(geometry.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _Harness(
              geometry: geometry,
              onController: (c) => controller = c,
              child: const Center(
                child: WaveThemed(
                  bounce: true,
                  child: SizedBox(key: Key('bounced'), width: 50, height: 50),
                ),
              ),
            ),
          ),
        ),
      );

      Transform scaleWidget() => tester.widget<Transform>(
        find.ancestor(
          of: find.byKey(const Key('bounced')),
          matching: find.byType(Transform),
        ),
      );
      expect(scaleWidget().transform.getMaxScaleOnAxis(), 1.0);

      // A wave starts, anchored far enough away that this probe is never
      // covered for the rest of the test (radius stays tiny relative to
      // the distance) -- the bounce should still fire, because it's keyed
      // to the wave *starting*, not to this widget's own colour catching
      // up.
      geometry.value = RevealWaveGeometry(
        globalOrigin: tester
            .getCenter(
              find.byKey(const Key('bounced')),
            )
            .translate(-5000, -5000),
        maxRadius: 10000,
        oldSeed: Colors.red,
        newSeed: Colors.blue,
      );
      await tester.pump();
      controller.value = 0.001;
      await tester.pump(const Duration(milliseconds: 90));

      expect(scaleWidget().transform.getMaxScaleOnAxis(), greaterThan(1.0));

      await tester.pump(const Duration(milliseconds: 200));
      expect(scaleWidget().transform.getMaxScaleOnAxis(), 1.0);
    },
  );
}
