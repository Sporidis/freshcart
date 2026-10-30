import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/app/push_registration_providers.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/app/session/session_resume_observer.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/preferences/appearance.dart';
import 'package:freshcart_flutter/core/preferences/appearance_controller.dart';
import 'package:freshcart_flutter/core/preferences/large_text_controller.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// How much bigger text gets when "Larger list text" is on.
///
/// Kept small on purpose: it's meant to make lists easier to read, not to be a
/// full accessibility text-size setting.
const _largeTextScale = TextScaler.linear(1.15);

/// The root widget of the app.
///
/// The app always uses the neutral FreshCart brand colours. Shop colours are
/// only applied inside a list's detail screen (see `ListDetailScreen`), never
/// here.
///
/// The [AnimatedTheme] here makes switching between light and dark mode fade
/// smoothly instead of jumping.
class FreshCartApp extends ConsumerWidget {
  /// Creates the app root.
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While the saved settings are still loading (only the very first frame),
    // fall back to "follow the system" and "normal text size".
    final themeMode =
        ref.watch(appearanceControllerProvider).value?.themeMode ??
        ThemeMode.system;
    final largeText = ref.watch(largeTextControllerProvider).value ?? false;
    final t = ref.watch(translationsProvider);

    // Watching this starts the coordinator that sends queued offline changes
    // to the server when we're back online.
    ref.watch(replayQueueWhenOnlineProvider);
    // And this one registers the phone for push after every sign-in.
    ref.watch(registerPushOnSignInProvider);

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
          // Same speed as other colour changes in the app (180ms).
          duration: AppMotion.durationFor(context, AppMotion.quick),
          curve: AppMotion.enter,
          child: MediaQuery(
            // When "Larger list text" is on, use our fixed scale instead of
            // the phone's text size setting. When it's off (null), the
            // phone's setting is kept as is.
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
