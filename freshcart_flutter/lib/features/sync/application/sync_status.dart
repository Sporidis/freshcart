/// The device's connectivity state, as observed by `features/sync`.
enum SyncStatus {
  /// The device has a network interface up.
  online,

  /// The device has no network interface up.
  offline,
}
