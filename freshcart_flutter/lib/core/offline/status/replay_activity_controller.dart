import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_activity_controller.g.dart';

/// Whether queued offline changes are being sent to the server right now.
///
/// Set by the replay coordinator around each replay, so the banner says
/// "Syncing" only while that is really happening. Being online with changes
/// waiting isn't the same: the server may still be unreachable.
@Riverpod(keepAlive: true)
class ReplayActivityController extends _$ReplayActivityController {
  @override
  bool build() => false;

  /// A replay started.
  void started() => state = true;

  /// The replay finished, whether it sent everything or not.
  void finished() => state = false;
}
