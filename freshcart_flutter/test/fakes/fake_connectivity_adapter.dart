import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity_adapter.dart';

/// A [ConnectivityAdapter] whose online/offline stream a test fully
/// controls, instead of touching the real `connectivity_plus` plugin (which
/// has no platform channel to answer through in a plain unit test).
class FakeConnectivityAdapter extends ConnectivityAdapter {
  /// Creates a fake backed by [stream] rather than the device's real
  /// connectivity. The `super.connectivity` is never actually used --
  /// [watchIsOnline] is overridden below -- so a throwaway [Connectivity]
  /// only needs to exist to satisfy the real constructor.
  FakeConnectivityAdapter(this._stream) : super(connectivity: Connectivity());

  final Stream<bool> _stream;

  @override
  Stream<bool> watchIsOnline() => _stream;
}
