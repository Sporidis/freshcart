import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/session/session_resume_observer.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/appearance_provider.dart';
import 'package:freshcart_flutter/core/theme/large_text_provider.dart';

/// The largest text scale "Larger list text" applies, deliberately modest —
/// the design's own note is "easier to read at arm's length," not a full
/// accessibility text-scale system (`docs/design-gap-plan.md` §7).
const _largeTextScale = TextScaler.linear(1.15);

/// The FreshCart application root.
///
/// Always themed from [AppTheme.brandSeed] — the app's chrome (drawer,
/// settings, dialogs, navigation transitions) is neutral ink-on-paper and
/// stays that way regardless of which shop is active anywhere in the app.
/// A shop's colour only ever tints the list-detail subtree that shop
/// belongs to (see `ListDetailScreen`'s own local [AnimatedTheme]), never
/// this root one.
///
/// The [AnimatedTheme] here still earns its keep for light/dark mode: it
/// glides between [theme] and [darkTheme] on an [Appearance] change or a
/// system brightness switch, rather than snapping.
class FreshCartApp extends ConsumerWidget {
  /// Creates the app root.
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defaults to system/off while each persisted choice is still loading
    // (first frame only — shared_preferences resolves fast, and both
    // defaults are exactly what an unset preference should behave like
    // anyway).
    final themeMode =
        ref.watch(appearanceControllerProvider).value?.themeMode ??
        ThemeMode.system;
    final largeText = ref.watch(largeTextControllerProvider).value ?? false;
    final t = ref.watch(translationsProvider);

    return SessionResumeObserver(
      child: MaterialApp.router(
        title: t.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(AppTheme.brandSeed),
        darkTheme: AppTheme.dark(AppTheme.brandSeed),
        themeMode: themeMode,
        routerConfig: ref.watch(appRouterProvider),
        builder: (context, child) => AnimatedTheme(
          data: Theme.of(context),
          // The motion spec's own token table assigns "colour tint" to
          // `quick` (180ms, easeOutCubic) — the same token chip selection
          // and row strike-through already use.
          duration: AppMotion.durationFor(context, AppMotion.quick),
          curve: AppMotion.enter,
          child: MediaQuery(
            // Overrides, rather than stacks onto, the ambient scaler — this
            // is an explicit in-app preference, not an addition to whatever
            // OS-level accessibility scaling the device already applies. Off
            // leaves the ambient (OS) scaler untouched.
            data: MediaQuery.of(context).copyWith(
              textScaler: largeText ? _largeTextScale : null,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
