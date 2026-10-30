import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/auth/ports/local_data_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Deletes the account (GDPR Art. 17), then everything this phone keeps of
/// it.
///
/// Same order as [SignOut], for the same reason: only once the server has
/// deleted the account is the phone's copy removed. If the server didn't,
/// the account still exists and so does its data here. No push unregister
/// first: the server deletes the account's push tokens itself.
class DeleteAccount {
  /// Creates the use case.
  const DeleteAccount(this._auth, this._localData);

  final AuthRepository _auth;
  final LocalDataRepository _localData;

  /// Deletes the account. An [Err] means nothing was deleted.
  Future<Result<void>> call() async {
    final deleted = await _auth.deleteAccount();
    if (deleted.isErr) return deleted;
    await _localData.clear();
    return const Ok(null);
  }
}
