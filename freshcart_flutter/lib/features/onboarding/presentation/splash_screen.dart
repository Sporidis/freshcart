import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/features/auth/data/auth_bootstrap_provider.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';
import 'package:go_router/go_router.dart';

/// The app's first frame: on screen for exactly as long as
/// [authBootstrapProvider] takes, no longer — there is no artificial
/// minimum hold, so a fast, already-authenticated launch barely shows this
/// at all (`docs/multi-shop-shopping-list-app`, the Splash frame's own
/// note: "if the check finishes in under 400ms, skip the splash entirely
/// rather than holding it artificially").
///
/// A real route (`Routes.splash`), not a widget `main()` shows before
/// `runApp` — that is what lets [BasketMark] fly to Welcome's own mark as a
/// `Hero` instead of the screen just cutting: a route swap animates, a
/// pre-`runApp` gate does not.
class SplashScreen extends ConsumerWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    // Fires once, when the bootstrap resolves — not on every rebuild, and
    // not read eagerly here, since main() already kicked the request off.
    ref.listen(authBootstrapProvider, (previous, next) {
      final session = next.value;
      if (session == null) return; // still loading, or (rare) errored.
      context.go(session.isNewIdentity ? Routes.welcome : Routes.lists);
    });

    // Same visual system as the app icon, polarity-swapped by mode: dark
    // mode is ink behind a light tile, light mode inverts every colour —
    // never a plain-light screen with a plain-dark tile mismatched on top.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.ink : AppColors.bgLight;
    final tile = isDark ? AppColors.bgLight : AppColors.ink;
    final mark = isDark ? AppColors.ink : AppColors.bgLight;

    return Scaffold(
      backgroundColor: background,
      body: Semantics(
        label: t.splash.loading,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(21),
                ),
                alignment: Alignment.center,
                // The mark itself is the Hero; the tile around it is not —
                // it is this screen's own chrome and fades with the route.
                child: Hero(
                  tag: BasketMark.heroTag,
                  child: BasketMark(size: 44, color: mark),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t.appName,
                style: TextStyle(
                  color: tile,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 62),
              const _PulsingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The splash's only motion: three shop-coloured dots, each cycling opacity
/// on its own 1.2s loop, staggered a third of a turn apart so they never all
/// dim at once.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _colors = [
    AppColors.info,
    AppColors.swatchOrange,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, color) in _colors.indexed) ...[
          if (index > 0) const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // A third of a turn apart, each riding the same 1.2s sine.
              final phase = _controller.value + (index / _colors.length);
              final opacity = 0.35 + 0.65 * ((1 + _sine(phase)) / 2);
              return Opacity(opacity: opacity, child: child);
            },
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ],
      ],
    );
  }
}

double _sine(double phase) =>
    // 2π · phase, without importing dart:math just for one call site.
    _sin(phase * 6.283185307179586);

// A tiny Taylor-series stand-in would drift; this is dart:math's own,
// aliased so the file's only import list stays about Flutter and the app.
double _sin(double x) =>
    (x - (x * x * x) / 6 + (x * x * x * x * x) / 120).clamp(-1.0, 1.0);

@Preview(group: 'Onboarding', name: 'Splash', size: previewPhone)
Widget splashScreenPreview() => previewApp(const SplashScreen());

@Preview(group: 'Onboarding', name: 'Splash (dark)', size: previewPhone)
Widget splashScreenDarkPreview() =>
    previewApp(const SplashScreen(), brightness: Brightness.dark);
