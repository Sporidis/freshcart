import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

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
    final t = ref.watch(translationsProvider);

    return MaterialApp.router(
      title: t.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed),
      darkTheme: AppTheme.dark(seed),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AnimatedTheme(
        data: Theme.of(context),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
