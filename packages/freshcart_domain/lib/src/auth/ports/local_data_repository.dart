/// The signed-in user's data kept on this device: the offline copies of
/// their lists and items, and the changes made offline that haven't
/// reached the server yet.
///
/// Belongs to one account. Signing out must remove it, or the next person
/// on the phone sees it.
abstract interface class LocalDataRepository {
  /// How many changes made offline are still waiting to be sent.
  Future<int> pendingChangeCount();

  /// Deletes everything this device keeps for the signed-in user.
  Future<void> clear();
}
