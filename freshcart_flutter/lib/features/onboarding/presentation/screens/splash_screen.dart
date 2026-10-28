import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';
import 'package:go_router/go_router.dart';

/// The first screen of the app. Shown only while sign-in
/// ([needsOnboardingProvider]) is running, never longer. If sign-in is fast,
/// you barely see it.
///
/// It's a real route (not something shown before `runApp`), so the logo
/// ([BasketMark]) can fly over to the Welcome screen with a `Hero`
/// animation.
class SplashScreen extends ConsumerWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    // Runs once, when sign-in is done, and goes to the next screen.
    // (main() already started sign-in.)
    ref.listen(needsOnboardingProvider, (previous, next) {
      // A failed sign-in still opens the app, like being offline on first
      // launch: the lists screen then shows what's wrong.
      if (next.hasError) {
        context.go(Routes.lists);
        return;
      }
      final needsOnboarding = next.value;
      if (needsOnboarding == null) return; // still loading
      context.go(needsOnboarding ? Routes.welcome : Routes.lists);
    });

    // Looks like the app icon. Dark mode: dark background, light tile.
    // Light mode: the opposite.
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
                  borderRadius: BorderRadius.circular(AppRadii.appIcon),
                ),
                alignment: Alignment.center,
                // Only the logo flies to Welcome. The tile around it fades
                // out with this screen.
                child: Hero(
                  tag: BasketMark.heroTag,
                  child: BasketMark(size: 44, color: mark),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t.appName,
                style: AppTextStyles.cardTitle.copyWith(color: tile),
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

/// Three coloured dots that fade in and out (every 1.2 s), one after
/// another, so they're never all dim at the same time.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  /// How long one fade in and out takes.
  static const Duration _cycle = Duration(milliseconds: 1200);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With reduced motion, no animation: the dots just stay visible.
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

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
              // Each dot starts a third of the cycle after the one before.
              final phase = _controller.value + (index / _colors.length);
              final opacity = _controller.isAnimating
                  ? 0.35 + 0.65 * ((1 + _sine(phase)) / 2)
                  : 1.0;
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

/// A smooth up-and-down wave. [phase] 0 to 1 is one full wave.
double _sine(double phase) => math.sin(phase * 2 * math.pi);
