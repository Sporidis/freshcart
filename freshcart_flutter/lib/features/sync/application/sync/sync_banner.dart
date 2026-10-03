/// What the offline banner should show.
///
/// The provider decides which case it is, the widget just draws it.
/// `sealed` means the widget's `switch` must handle every case, or it won't
/// compile.
sealed class SyncBanner {
  const SyncBanner();
}

/// Online and nothing waiting to sync: no banner.
final class SyncBannerHidden extends SyncBanner {
  const SyncBannerHidden();
}

/// No internet. Changes are saved on the phone until it's back.
final class SyncBannerOffline extends SyncBanner {
  const SyncBannerOffline();
}

/// Back online, still sending [pending] saved changes to the server.
final class SyncBannerSyncing extends SyncBanner {
  const SyncBannerSyncing(this.pending);

  final int pending;
}
