import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_adapter.g.dart';

/// Wraps the `connectivity_plus` package, so the rest of the app doesn't
/// use it directly.
class ConnectivityAdapter {
  final Connectivity connectivity;

  ConnectivityAdapter({required this.connectivity});

  /// `true` when online, `false` when offline. Sends the current state
  /// first, then again every time it changes.
  Stream<bool> watchIsOnline() async* {
    final current = await connectivity.checkConnectivity();
    yield _isOnline(current);

    await for (final change in connectivity.onConnectivityChanged) {
      yield _isOnline(change);
    }
  }

  /// Online if at least one connection type isn't `none`.
  bool _isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
}

/// Supplies the [ConnectivityAdapter].
@Riverpod(keepAlive: true)
ConnectivityAdapter connectivityAdapter(Ref ref) =>
    ConnectivityAdapter(connectivity: Connectivity());
