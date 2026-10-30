/// What the offline banner should show.
///
/// The provider decides which case it is, the widget just draws it.
/// `sealed` means the widget's `switch` must handle every case, or it won't
/// compile.
sealed class SyncBannerState {
  const SyncBannerState();
}

/// Online and nothing waiting to sync: no banner.
final class SyncBannerHidden extends SyncBannerState {
  const SyncBannerHidden();
}

/// No internet. Changes are saved on the phone until it's back; [pending]
/// of them are waiting (0 if none were made offline yet).
final class SyncBannerOffline extends SyncBannerState {
  const SyncBannerOffline([this.pending = 0]);

  final int pending;
}

/// Online, with [pending] saved changes waiting, but not being sent right
/// now: the server may be unreachable. Said as "waiting", not "syncing".
final class SyncBannerWaiting extends SyncBannerState {
  const SyncBannerWaiting(this.pending);

  final int pending;
}

/// Sending [pending] saved changes to the server right now.
final class SyncBannerSyncing extends SyncBannerState {
  const SyncBannerSyncing(this.pending);

  final int pending;
}
