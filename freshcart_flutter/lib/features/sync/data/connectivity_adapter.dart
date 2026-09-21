import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` so nothing above `data/` depends on the plugin
class ConnectivityAdapter {
  final Connectivity connectivity;

  ConnectivityAdapter({required this.connectivity});

  /// Emits the device's online/offline state, starting with the current
  /// state and then following every change.
  Stream<bool> watchIsOnline() async* {
    final current = await connectivity.checkConnectivity();
    yield _isOnline(current);

    await for (final change in connectivity.onConnectivityChanged) {
      yield _isOnline(change);
    }
  }

  /// Returns `true` if the device is online based on the given connectivity results.
  bool _isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
}
