import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_conflicts_controller.g.dart';

/// How many offline changes the server has turned down while syncing,
/// since the app started.
///
/// A queued change is turned down when someone else changed the same
/// thing first: the server's version wins (offline-sync-plan.md Phase D).
/// The change is dropped, the list re-fetches and shows what's really
/// there, and the user is told why their change didn't stick (Phase E,
/// the snackbar tier of decision #42).
///
/// A running total, not a list: the screen only needs "how many more since
/// I last looked", which is the difference between two values.
/// Kept alive, so a count isn't lost between screens.
@Riverpod(keepAlive: true)
class SyncConflictsController extends _$SyncConflictsController {
  @override
  int build() => 0;

  /// Records [count] more changes the server turned down.
  void add(int count) {
    if (count > 0) state += count;
  }
}
