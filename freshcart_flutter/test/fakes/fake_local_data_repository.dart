import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [LocalDataRepository] for application/widget tests, so
/// they never open the real drift database.
class FakeLocalDataRepository implements LocalDataRepository {
  /// What [pendingChangeCount] returns.
  int pending = 0;

  /// How many times [clear] was called.
  int clearCalls = 0;

  @override
  Future<int> pendingChangeCount() async => pending;

  @override
  Future<void> clear() async => clearCalls++;
}
