import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';

/// Refreshes the plain, non-streamed list collection after the app comes
/// back from the background.
///
/// This used to also invalidate `itemsControllerProvider` and
/// `listByIdProvider`, to recover from Serverpod's dead-socket-after-
/// backgrounding problem: those `watchList()`/`watch()` streams died with
/// the socket and never reopened themselves (Serverpod only retries with a
/// fresh auth key on a stream's *first* open), so a resumed app was left
/// showing a stale "you don't have access" error until the user tapped
/// Retry. `ItemRealtimeSource`/`ListRealtimeSource` now handle that
/// themselves via `resilientWatch` (`docs/offline-sync-plan.md` Phase F),
/// which reconnects transparently without tearing the provider down — doing
/// it here as well was worse than redundant: invalidating
/// `itemsControllerProvider` wiped `ItemsController`'s in-memory pending-write
/// overlay, so a queued-but-unsynced item visibly vanished every time the
/// app was backgrounded and resumed while offline, until the queue drained.
/// `listsControllerProvider`'s own `build()` is a one-shot fetch, not a
/// stream, so it was never affected by the dead-socket problem and still
/// gets refreshed here to pick up changes made from another device while
/// backgrounded.
class SessionResumeObserver extends ConsumerStatefulWidget {
  /// Wraps [child], watching app lifecycle for as long as it is mounted.
  const SessionResumeObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionResumeObserver> createState() =>
      _SessionResumeObserverState();
}

class _SessionResumeObserverState extends ConsumerState<SessionResumeObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(listsControllerProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
