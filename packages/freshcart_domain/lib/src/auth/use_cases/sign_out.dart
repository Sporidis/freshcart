import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/auth/ports/local_data_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/notifications/ports/notification_repository.dart';

/// Signs out, leaving nothing of the account on this device.
///
/// The order is the rule:
/// 1. Stop push to this phone while still signed in (the server needs to
///    know whose token it is). Best effort: if it fails, signing out goes
///    on, because registering the phone for the next account moves the
///    token anyway.
/// 2. Sign out on the server. If that fails, nothing else happens: the
///    user is still signed in, so their data stays.
/// 3. Only then delete what this device keeps for the account.
class SignOut {
  /// Creates the use case.
  const SignOut(this._auth, this._notifications, this._localData);

  final AuthRepository _auth;
  final NotificationRepository _notifications;
  final LocalDataRepository _localData;

  /// Signs out. An [Err] means the user is still signed in, with all their
  /// data.
  Future<Result<void>> call() async {
    await _notifications.unregisterDevice();
    final signOutResult = await _auth.signOut();
    if (signOutResult.isErr) {
      return signOutResult;
    }

    await _localData.clear();
    return const Result.ok(null);
  }
}
