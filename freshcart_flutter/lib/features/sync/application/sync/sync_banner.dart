/// What the offline/syncing banner should say, already decided.
///
/// Sealed so the widget's `switch` is exhaustive: it draws a case, it never
/// works out which case applies.
sealed class SyncBanner {
  const SyncBanner();
}

/// Online with nothing queued: no banner at all.
final class SyncBannerHidden extends SyncBanner {
  const SyncBannerHidden();
}

/// No network: writes are queued locally until it comes back.
final class SyncBannerOffline extends SyncBanner {
  const SyncBannerOffline();
}

/// Back online, still draining [pending] queued writes.
final class SyncBannerSyncing extends SyncBanner {
  const SyncBannerSyncing(this.pending);

  final int pending;
}
