import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_new_identity_provider.g.dart';

/// Whether this launch just created a brand-new anonymous identity, rather
/// than restoring one already on the device.
///
/// Deliberately unimplemented here and overridden at the root `ProviderScope`
/// with the answer from `AnonymousSessionBootstrap.ensureSignedIn` — same
/// DI-via-override pattern as [serverpodClientProvider], and for the same
/// reason: the answer is only known once, asynchronously, before the first
/// frame, and every consumer reading it should not have to be async.
///
/// `appRouter` reads this once to pick the initial route: a new identity has
/// never created a list, so it starts at Welcome; a restored one goes
/// straight to Lists (whose own empty state already covers "no lists left").
@Riverpod(keepAlive: true)
bool isNewIdentity(Ref ref) => throw UnimplementedError(
  'isNewIdentityProvider must be overridden in the root ProviderScope',
);
