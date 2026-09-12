import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/appearance_provider.dart';

/// The FreshCart application root.
///
/// Watches the active seed colour so that selecting a shop re-themes
/// everything, and wraps the whole app in an [AnimatedTheme] so the scheme
/// glides to the new colour instead of snapping.
class FreshCartApp extends ConsumerWidget {
  /// Creates the app root.
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(activeSeedColorProvider);
    final appearance = ref.watch(appearanceControllerProvider);
    final t = ref.watch(translationsProvider);

    return MaterialApp.router(
      title: t.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed),
      darkTheme: AppTheme.dark(seed),
      themeMode: appearance.themeMode,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AnimatedTheme(
        data: Theme.of(context),
        // The motion spec's own token table assigns "colour tint" to `quick`
        // (180ms, easeOutCubic) — the same token chip selection and row
        // strike-through already use. Re-theming the whole app on a shop
        // switch previously ran at a hardcoded 400ms/easeInOut: more than
        // twice as long, and a symmetric curve rather than the app's
        // consistent "fast in" asymmetric one — the one colour-tint moment
        // that didn't match every other colour-tint moment's rhythm.
        duration: AppMotion.durationFor(context, AppMotion.quick),
        curve: AppMotion.enter,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
