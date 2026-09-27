import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_bootstrap_provider.g.dart';

/// Signs the app in — restoring a stored session, or creating an anonymous
/// one — and reports whether the result is a brand-new identity.
///
/// A real async provider, not a value resolved before `runApp` and injected
/// through a `ProviderContainer` override: `main()` no longer awaits this at
/// all, so the first frame paints immediately and `SplashScreen` (watching
/// this provider) is what actually covers the wait — for exactly as long as
/// it takes, never artificially longer, matching the Splash frame in
/// `docs/multi-shop-shopping-list-app`. `main()` still kicks the request off
/// eagerly right after building the container (`ref.read(...future)`), so
/// the network round trip starts before the first frame even paints, rather
/// than waiting on Splash's own `build()` to ask for it.
@Riverpod(keepAlive: true)
Future<({bool authenticated, bool isNewIdentity})> authBootstrap(
  Ref ref,
) => AnonymousSessionBootstrap.ensureSignedIn(
  ref.watch(serverpodClientProvider),
);
